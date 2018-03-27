public with sharing class ShopifyOrderBatch implements Database.Batchable<OrderDto>, Database.AllowsCallouts, Database.Stateful {

	public String connectionName;
	public String connectionBrand;
	public String connectionPrefix;
	public String corruptedProductPrefix;

	public Boolean hasCorruptedLineItems = false;

	public static final String EXTID_JOINER = '__';
	public static final String CORRUPTED_PRODUCTD_ID = 'corrupted_product';

	public Iterable<OrderDto> start(Database.BatchableContext BC) {

		/* Get Orders from Shopify Site */
		List<OrderDto> allFetchedOrdersList = ShopifyShoppingCart.getOrders();

		/* external ids handling */
		/* at this point getPrevConnectionId should be not null and set to current connection */
		TouchCRBase__TouchCRConnection__c curConnection = ShopifyProcessingHelper.getConnectionById(
			ShopifyProcessingHelper.getPrevConnectionId()
		);
		connectionName = curConnection.Name;
		connectionBrand = curConnection.TouchCRBase__Brand__c;
		connectionPrefix = connectionName + EXTID_JOINER;
		corruptedProductPrefix = connectionName + EXTID_JOINER + CORRUPTED_PRODUCTD_ID;

		/* Get & Update Callout Count */
		Map<String, String> shopifySettings = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
		String callOut = shopifySettings.containsKey('Shopify.orderCallOut') ? shopifySettings.get('Shopify.orderCallOut') : 'NA';

		if (callOut == 'NA') {
			TouchCRBase.TouchCRHelper.setSettings(new Map<String, String>{
				'Shopify.orderCallOut' => '0'
			});
			callOut = shopifySettings.containsKey('Shopify.orderCallOut') ? shopifySettings.get('Shopify.orderCallOut') : '0';
		}

		Integer callOutCount = 0;
		try {
			callOutCount = Integer.valueOf(callOut);
		}
		catch (Exception e) {
		}

		if (allFetchedOrdersList.size() > 0) {
			String item = String.valueOf(callOutCount + 1);
			TouchCRBase.TouchCRHelper.setSettings(new Map<String, String>{
				'Shopify.orderCallOut' => item
			});

		}
		else {
			Map<String, String> shopifyLimit = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
			String callOutLimit = shopifyLimit.containsKey('Shopify.callOut') ? shopifyLimit.get('Shopify.callOut') : '0';
			TouchCRBase.TouchCRHelper.setSettings(new Map<String, String>{
				'Shopify.orderCallOut' => callOutLimit
			});
		}

		/* add connection prefix on the fly to order and line items */
		for (OrderDto order : allFetchedOrdersList) {
			if (order != null && order.id != null) {
				order.id = connectionPrefix + order.id;
			}
			if (order.line_items != null) {
				for (OrderDto.LineItems lineItem : order.line_items) {
					if (String.isNotBlank(lineItem.id)) {
						lineItem.id = connectionPrefix + lineItem.id;
					}
					// good line item
					if (String.isNotBlank(lineItem.product_id) && lineItem.product_id != 'null') {
						lineItem.product_id = connectionPrefix + lineItem.product_id;
					}
					// check for corruption, if product_id empty but title present it will be used as a id
					else if (String.isNotBlank(lineItem.title)) {
						lineItem.title = connectionPrefix + lineItem.title;
					}

					if (String.isNotBlank(lineItem.variant_id) && lineItem.variant_id != 'null') {
						lineItem.variant_id = connectionPrefix + lineItem.variant_id;
					}
				}
			}
			if (order.customer != null) {
				if (String.isNotBlank(order.customer.id) || order.customer.id != '0') {
					order.customer.id = connectionPrefix + order.customer.id;
				}
			}
		}

		/////////////////
		List<TouchCRBase__Log__c> errorLogs = new List<TouchCRBase__Log__c>{
			new TouchCRBase__Log__c(
				TouchCRBase__Event_Type__c = 'Shopify Orders',
				TouchCRBase__Event_Status__c = 'In Progress',
				TouchCRBase__Event_Description__c = 'Number of received orders: ' + allFetchedOrdersList.size()
			)
		};

		if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable()) {
			insert errorLogs;
		}
		/////////////////

		return allFetchedOrdersList;
	}

	public void execute(Database.BatchableContext BC, List<OrderDto> ordersData) {
		List<OrderDto> allValidFetchedOrdersList = new List<OrderDto>();

		/* Get existing Shopify Coupon codes from SF */
		String couponName = 'Shopify Coupon';

		List<Product2> productCoupons;
		Boolean isAccessibleProduct = (
			Product2.Id.getDescribe().isAccessible() &&
				Product2.Name.getDescribe().isAccessible() &&
				Product2.Description.getDescribe().isAccessible()
		);
		if (isAccessibleProduct) {
			productCoupons = [SELECT Id, Name, Description FROM Product2 WHERE Name = :couponName];
		}
		else {
			throw new privilegesException('privileges Exception l131');
		}

		Map<String, String> couponMap = New Map<String, String>();
		for (Product2 productCoupon : productCoupons) {
			couponMap.put(productCoupon.Description, productCoupon.Id);
		}

		/* Update Billing email Id from customer email if not exist */
		String sinceId = '1';

		List<String> orderItemsProductIds = new List<String>();
		List<String> orderItemsIds = new List<String>();
		Map<String, String> faultyOrders = new Map<String, String>();
		List<String> emails = new List<String>();
		List<String> productIds = new List<String>();
		List<String> orderIds = new List<String>();
		List<Product2> couponProducts = new List<Product2>();
		Map<String, String> couponChackMap = new Map<String, String>();

		///
		List<OrderDto.LineItems> corruptedLineItemsToCreatePv = new List<OrderDto.LineItems>();
		///
		for (OrderDto order: ordersData) {
			Boolean productEmptyIdCheck = false;
			// customer email, fname, lname
			try {
				if (order.customer != null) {
					String myEmail = order.customer.email;
					List<String> emailSplit = myEmail.split('@');
					if (order.customer.first_name == null || order.customer.first_name == '') {
						order.customer.first_name = emailSplit[0];
					}
					if (order.customer.last_name == null || order.customer.last_name == '') {
						if (order.customer.first_name != null || order.customer.first_name != '') {
							order.customer.last_name = order.customer.first_name;
						}
						else {
							order.customer.last_name = emailSplit[0];
						}
					}
					emails.add(myEmail);
				}
				else {
					emails.add(order.email);
				}
			}
			catch (Exception e) {
			}
			// order, line items
			orderIds.add(order.id);

			/**
			 * FIXME
			 * @Rajinder
			 * while testing we saw there is order with some product ids but when we look for that product and it is not exist
			 */
			for (OrderDto.LineItems lineItem : order.line_items) {
				if (lineItem.product_id == null || lineItem.product_id == 'null') {
					faultyOrders.put(order.id, order.id);
					//productEmptyIdCheck = true;

					hasCorruptedLineItems = true;
					corruptedLineItemsToCreatePv.add(lineItem);
				}
				else {
					productIds.add(lineItem.product_id);
					orderItemsProductIds.add(lineItem.product_id);
				}
				orderItemsIds.add(lineItem.id);
			}

			// coupon codes, coupon products
			if (order.coupon_codes != null) {
				/* Add coupon products */
				for (OrderDto.CouponCodes couponCode : order.coupon_codes) {
					String myCouCode = couponCode.code;
					myCouCode = myCouCode.trim();
					myCouCode = myCouCode.toUpperCase();
					if (!couponMap.containsKey(myCouCode) && !couponChackMap.containsKey(myCouCode)) {
						couponChackMap.put(myCouCode, myCouCode);
						Boolean productStatus = true;
						Product2 couponProduct = new Product2(
							Name = couponName,
							ProductCode = myCouCode,
							Description = myCouCode,
							IsActive = productStatus
						);
						couponProducts.add(couponProduct);
					}
				}
			}
			// collect the order
			if (order.billing_address != null && productEmptyIdCheck == false) {
				if (order.billing_address.email == null && order.customer != null && order.customer.email != null) {
					order.billing_address.email = order.customer.email;
				}
				if (order.billing_address.email != null) {
					allValidFetchedOrdersList.add(order);
				}
			}
			sinceId = order.id.removeStartIgnoreCase(connectionPrefix);
		}

		/**
		 * CORRUPTED PRODUCTS
		 */
		// do this only if corrupted items present in a scope
		Product2 corruptedProduct = new Product2();
		Map<String, String> corruptedPVExternalIdToSfIdMap = new Map<String, String>();

		if (hasCorruptedLineItems) {
			List<Product2> corruptedProducts = [
				SELECT Id, Name, TouchCRBase__Connected_Id__c, TouchCRBase__Connection_Name__c, (
					SELECT Id, TouchCRBase__External_Id__c, TouchCRBase__Integration_Name__c, TouchCRBase__External_Product_Id__c
					FROM TouchCRBase__Product_Variants__r
				)
				FROM Product2
				WHERE TouchCRBase__Connected_Id__c = :corruptedProductPrefix
				AND TouchCRBase__Connection_Name__c = :connectionName
			];
			// create new product if there is none
			if (corruptedProducts.isEmpty()) {
				Product2 newCorruptedProduct = new Product2(
					Name = corruptedProductPrefix,
					ProductCode = corruptedProductPrefix,
					Description = corruptedProductPrefix,
					IsActive = true,
					TouchCRBase__Connected_Id__c = corruptedProductPrefix,
					TouchCRBase__Connection_Name__c = connectionName
				);
				corruptedProducts.add(newCorruptedProduct);
				insert corruptedProducts;
			}
			corruptedProduct = corruptedProducts.get(0);

			// create PV for corrupted product on the fly
			// ext id will be connectionPrefix + title
			// cor product has soem variants
			List<TouchCRBase__Product_Variant__c> corruptedVariants = new List<TouchCRBase__Product_Variant__c>();
			if (!corruptedProducts.get(0).TouchCRBase__Product_Variants__r.isEmpty()) {
				corruptedVariants = corruptedProducts.get(0).TouchCRBase__Product_Variants__r;
			}
			for (TouchCRBase__Product_Variant__c corVariant : corruptedVariants) {
				corruptedPVExternalIdToSfIdMap.put(corVariant.TouchCRBase__External_Id__c, corVariant.Id);
			}
			// set to prevent duplicates as we are using title as external id
			Set<TouchCRBase__Product_Variant__c> corruptedPVariantsToInsert = new Set<TouchCRBase__Product_Variant__c>();
			for (OrderDto.LineItems corruptedLineItem : corruptedLineItemsToCreatePv) {
				if (String.isNotBlank(corruptedLineItem.title) && !corruptedPVExternalIdToSfIdMap.containsKey(corruptedLineItem.title)) {
					// add PV linked to corrupted Product, with TouchCRBase__External_Id__c as title of line item product
					TouchCRBase__Product_Variant__c newPVariant = new TouchCRBase__Product_Variant__c(
						TouchCRBase__Product__c = corruptedProduct.Id,
						Name = corruptedLineItem.title.abbreviate(80),
						TouchCRBase__Product_Title__c = corruptedLineItem.title.abbreviate(100),
						TouchCRBase__sku__c = corruptedLineItem.sku,
						TouchCRBase__Price__c = corruptedLineItem.price,

						TouchCRBase__Integration_Name__c = connectionName,
						TouchCRBase__External_Id__c = corruptedLineItem.title,
						TouchCRBase__External_Product_Id__c = corruptedProductPrefix
					);
					corruptedPVariantsToInsert.add(newPVariant);
				}
			}

			if (!corruptedPVariantsToInsert.isEmpty()) {
				Database.insert(new List<TouchCRBase__Product_Variant__c>(corruptedPVariantsToInsert), false);
			}
			// retrieve old and new corrupted PV
			List<TouchCRBase__Product_Variant__c> newCorVariants = [
				SELECT Id, TouchCRBase__External_Id__c, TouchCRBase__Integration_Name__c, TouchCRBase__External_Product_Id__c
				FROM TouchCRBase__Product_Variant__c
				WHERE TouchCRBase__Product__c = :corruptedProduct.Id
			];
			for (TouchCRBase__Product_Variant__c corVariant : newCorVariants) {
				corruptedPVExternalIdToSfIdMap.put(corVariant.TouchCRBase__External_Id__c, corVariant.Id);
			}
		}
		/**
		 * CORRUPTED PRODUCTS
		 */

		/*upsert coupons 'Discounted Products'*/
		Boolean isCreateableProduct = (
			Product2.Name.getDescribe().isCreateable() &&
				Product2.ProductCode.getDescribe().isCreateable() &&
				Product2.Description.getDescribe().isCreateable() &&
				Product2.IsActive.getDescribe().isCreateable()
		);
		if (isCreateableProduct) {
			try {
				Database.UpsertResult[] bulkExcution;
				if (couponProducts.size() > 0) {
					bulkExcution = Database.upsert(couponProducts, false);
					setData(bulkExcution, 'Discounted Products');
				}
			}
			catch (DmlException e) {
			}
		}
		else {
			throw new privilegesException('privileges Exception 333');
		}

		/* Re Collect existing Shopify Coupon codes from SF */
		if (couponProducts.size() > 0) {
			productCoupons = null;
			Boolean isAccessibleProduct1 = (
				Product2.Id.getDescribe().isAccessible() &&
					Product2.Name.getDescribe().isAccessible() &&
					Product2.Description.getDescribe().isAccessible()
			);
			if (isAccessibleProduct1) {
				productCoupons = [SELECT Id, Name, Description FROM Product2 WHERE Name = :couponName];
			}
			else {
				throw new privilegesException('privileges Exception l348');
			}

			for (Product2 productCoupon : productCoupons) {
				couponMap.put(productCoupon.Description, productCoupon.Id);
			}
		}

		TouchCRBase.TouchCRHelper.setSettings(new Map<String, String>{
			'Shopify.lastOrderExternalID' => sinceId
		});

		List<Product2> disabledProducts;
		Boolean isAccessibleProduct2 = (
			Product2.Id.getDescribe().isAccessible() &&
				Product2.IsActive.getDescribe().isAccessible() &&
				Product2.TouchCRBase__Connected_Id__c.getDescribe().isAccessible()
		);
		if (isAccessibleProduct2) {
			disabledProducts = [
				SELECT Id, TouchCRBase__Connected_Id__c
				FROM Product2
				WHERE TouchCRBase__Connected_Id__c IN:productIds
				AND IsActive = false
			];
		}
		else {
			throw new privilegesException('privileges Exception l375');
		}

		Map<String, String> disabledIds = new Map<String, String>();
		for (Product2 pid : disabledProducts) {
			disabledIds.put(pid.TouchCRBase__Connected_Id__c, pid.Id);
		}

		/* Prepare Previous Orders Ids */
		List<TouchCRBase__Order__c> previousOrders;
		Boolean isAccessibleOrders = (
			TouchCRBase__Order__c.Id.getDescribe().isAccessible() &&
				TouchCRBase__Order__c.TouchCRBase__Billing_Email__c.getDescribe().isAccessible() &&
				TouchCRBase__Order__c.TouchCRBase__Connected_Id__c.getDescribe().isAccessible() &&
				TouchCRBase__Order__c.TouchCRBase__Total__c.getDescribe().isAccessible() &&
				TouchCRBase__Order__c.TouchCRBase__Account__c.getDescribe().isAccessible() &&
				TouchCRBase__Order__c.TouchCRBase__Subtotal__c.getDescribe().isAccessible()
		);
		if (isAccessibleOrders) {
			previousOrders = [
				SELECT Id, TouchCRBase__Billing_Email__c, TouchCRBase__Connected_Id__c, TouchCRBase__Total__c, TouchCRBase__Account__c, TouchCRBase__Subtotal__c
				FROM TouchCRBase__Order__c
				WHERE TouchCRBase__Connected_Id__c IN :orderIds
			];
		}
		else {
			throw new privilegesException('privileges Exception l401');
		}

		Map<String, String> previousOrderIds = new Map<String, String>();
		Map<String, String> previousOrderIdNAC = new Map<String, String>();

		List<String> oldSSFOrderIds = new List<String>();
		Map<String, Decimal> orderPrices = new Map<String, Decimal>();
		for (TouchCRBase__Order__c previousOrder : previousOrders) {
			previousOrderIds.put(previousOrder.TouchCRBase__Connected_Id__c, previousOrder.Id);
			previousOrderIdNAC.put(previousOrder.TouchCRBase__Connected_Id__c, previousOrder.TouchCRBase__Account__c);
			oldSSFOrderIds.add(previousOrder.Id);
			orderPrices.put(previousOrder.id, previousOrder.TouchCRBase__Total__c);
		}

		/* Prepare SF'id and Shopify's Product Data */
		List<Product2> productsData;
		Boolean isAccessibleProduct3 = (
			Product2.Id.getDescribe().isAccessible() &&
				Product2.TouchCRBase__Connected_Id__c.getDescribe().isAccessible() &&
				Product2.Name.getDescribe().isAccessible()
		);
		if (isAccessibleProduct3) {
			productsData = [SELECT Id, TouchCRBase__Connected_Id__c, Name FROM Product2 WHERE TouchCRBase__Connected_Id__c IN:orderItemsProductIds];
		}
		else {
			throw new privilegesException('privileges Exception l427');
		}

		Map<String, String> productIdsSF = new Map<String, String>();
		Map<String, String> productNameSF = new Map<String, String>();
		for (Product2 productSF : productsData) {
			productIdsSF.put(productSF.TouchCRBase__Connected_Id__c, productSF.Id);
			productNameSF.put(productSF.TouchCRBase__Connected_Id__c, productSF.Name);
		}

		/* Get SF existing orderItem Ids */
		List<TouchCRBase__OrderItem__c> previousOrderItems;
		Boolean isAccessibleOrdersItem = (
			TouchCRBase__OrderItem__c.Id.getDescribe().isAccessible() &&
				TouchCRBase__OrderItem__c.TouchCRBase__Connected_Id__c.getDescribe().isAccessible()
		);
		if (isAccessibleOrdersItem) {
			previousOrderItems = [SELECT Id, TouchCRBase__Connected_Id__c FROM TouchCRBase__OrderItem__c WHERE TouchCRBase__Connected_Id__c IN :orderItemsIds];
		}
		else {
			throw new privilegesException('privileges Exception l447');
		}

		Map<String, String> previousOrderItemIds = new Map<String, String>();
		for (TouchCRBase__OrderItem__c previousOrderItem : previousOrderItems) {
			previousOrderItemIds.put(previousOrderItem.TouchCRBase__Connected_Id__c, previousOrderItem.Id);
		}

		Map<String, String> myShopifySettings = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
		String discountedProductId = myShopifySettings.containsKey('Shopify.discountedProductId') ? myShopifySettings.get('Shopify.discountedProductId') : 'NA';

		/* Get order's discounted items */
		List<TouchCRBase__OrderItem__c> previousOrderDiscountedItems;
		Boolean isAccessibleOrdersItem1 = (
			TouchCRBase__OrderItem__c.Id.getDescribe().isAccessible() &&
				TouchCRBase__OrderItem__c.TouchCRBase__Order__c.getDescribe().isAccessible() &&
				TouchCRBase__OrderItem__c.TouchCRBase__Product__c.getDescribe().isAccessible()
		);
		if (isAccessibleOrdersItem1) {
			previousOrderDiscountedItems = [SELECT Id, TouchCRBase__Order__c FROM TouchCRBase__OrderItem__c WHERE TouchCRBase__Order__c IN :oldSSFOrderIds AND TouchCRBase__Product__c = :discountedProductId];
		}
		else {
			throw new privilegesException('privileges Exception l469');
		}

		Map<String, String> discountedItemMap = new Map<String, String>();
		for (TouchCRBase__OrderItem__c discountedItem : previousOrderDiscountedItems) {
			discountedItemMap.put(discountedItem.TouchCRBase__Order__c, discountedItem.Id);
		}

		List<TouchCRBase__OrderItem__c> itemToRepair = new List<TouchCRBase__OrderItem__c>();
		List<TouchCRBase__Log__c> repairLogs = new List<TouchCRBase__Log__c>();
		Map<String, Decimal> totalToUpdate = new Map<String, Decimal>();

		/*UPDATE OLD TRANSACTION AMOUNT*/
		// repair old orders items if SF has some faulty order items
		if (previousOrderIds.size() > 0) {
			List<TouchCRBase__Order_Transaction__c> oldTransections;
			Boolean isAccessibleOrdersTransaction = (
				TouchCRBase__Order_Transaction__c.Id.getDescribe().isAccessible() &&
					TouchCRBase__Order_Transaction__c.TouchCRBase__Order__c.getDescribe().isAccessible() &&
					TouchCRBase__Order_Transaction__c.TouchCRBase__Amount__c.getDescribe().isAccessible()
			);
			if (isAccessibleOrdersTransaction) {
				oldTransections = [SELECT Id, TouchCRBase__Order__c, TouchCRBase__Amount__c FROM TouchCRBase__Order_Transaction__c WHERE TouchCRBase__Order__c IN:oldSSFOrderIds];
			}
			else {
				throw new privilegesException('privileges Exception l494');
			}

			for (TouchCRBase__Order_Transaction__c oldTransection : oldTransections) {
				oldTransection.TouchCRBase__Amount__c = orderPrices.get(oldTransection.TouchCRBase__Order__c);
			}

			Boolean isUpdableOrdersTransaction = (
				TouchCRBase__Order_Transaction__c.TouchCRBase__Amount__c.getDescribe().isUpdateable()
			);
			if (isUpdableOrdersTransaction) {
				try {
					Database.UpsertResult[] bulkExcution;
					if (oldTransections.size() > 0) {
						bulkExcution = Database.upsert(oldTransections, false);
						setData(bulkExcution, 'Order Transaction');
					}
				}
				catch (DmlException e) {
				}
			}
			else {
				throw new privilegesException('privileges Exception l516');
			}

			/* main order loop*/
			for (OrderDto order : allValidFetchedOrdersList) {
				if (previousOrderIds.containsKey(order.id)) {
					/* Add discount Item if needed */
					Boolean isDiscountNeeded = (discountedProductId != 'NA'
						&& order.total_discount != null
						&& order.total_discount > 0
						&& !discountedItemMap.containsKey(previousOrderIds.get(order.id))
					);
					if (isDiscountNeeded) {
						TouchCRBase__OrderItem__c oItem = new TouchCRBase__OrderItem__c(
							TouchCRBase__Order__c = previousOrderIds.get(order.id),
							TouchCRBase__Connected_Id__c = '',
							TouchCRBase__Connection_Name__c = connectionName,
							TouchCRBase__Product__c = discountedProductId,
							TouchCRBase__Quantity__c = 1,
							TouchCRBase__Product_Price__c = -order.total_discount
						);
						itemToRepair.add(oItem);
					}
				}
				/* order item loop */
				for (OrderDto.LineItems lineItem : order.line_items) {
					totalToUpdate.put(order.id, order.subtotal);
					if (previousOrderIds.containsKey(order.id) && !previousOrderItemIds.containsKey(lineItem.id)) {
						TouchCRBase__OrderItem__c oItem = new TouchCRBase__OrderItem__c(
							TouchCRBase__Order__c = previousOrderIds.get(order.id),
							TouchCRBase__Connected_Id__c = lineItem.id,
							TouchCRBase__Connection_Name__c = connectionName,
							TouchCRBase__Product__c = productIdsSF.get(lineItem.product_id),
							TouchCRBase__Quantity__c = lineItem.quantity,
							TouchCRBase__Product_Price__c = lineItem.price
						);
						itemToRepair.add(oItem);

						repairLogs.add(new TouchCRBase__Log__c(
							TouchCRBase__Event_Type__c = 'Repair Order Items',
							TouchCRBase__Event_Status__c = 'Repaired',
							TouchCRBase__Event_Endpoint__c = 'NA',
							TouchCRBase__Event_Description__c = 'Order Item has been successfully repaired: Ited Id: ' + lineItem.id,
							TouchCRBase__Account__c = previousOrderIdNAC.get(order.id)
						));
					}
				}
			}

			for (TouchCRBase__Order__c orderToUpdate : previousOrders) {
				try {
					Decimal subtotal = totalToUpdate.get(orderToUpdate.TouchCRBase__Connected_Id__c);
					orderToUpdate.TouchCRBase__Subtotal__c = subtotal;
				}
				catch (Exception e) {
				}
			}
			Boolean isUpdateableOrders1 = (
				TouchCRBase__Order__c.TouchCRBase__Subtotal__c.getDescribe().isUpdateable()
			);

			/*order update*/
			if (isUpdateableOrders1) {
				try {
					Database.UpsertResult[] bulkExcution;
					if (previousOrders.size() > 0) {
						bulkExcution = Database.upsert(previousOrders, false);
						setData(bulkExcution, 'Orders');
					}
				}
				catch (DmlException e) {
				}
			}
			else {
				throw new privilegesException('privileges Exception l590');
			}
			/*order items update*/
			Boolean isCreateableOrdersItem = (
				TouchCRBase__OrderItem__c.TouchCRBase__Product__c.getDescribe().isCreateable() &&
					TouchCRBase__OrderItem__c.TouchCRBase__Order__c.getDescribe().isCreateable() &&
					TouchCRBase__OrderItem__c.TouchCRBase__Connection_Name__c.getDescribe().isCreateable() &&
					TouchCRBase__OrderItem__c.TouchCRBase__Connected_Id__c.getDescribe().isCreateable() &&
					TouchCRBase__OrderItem__c.TouchCRBase__Quantity__c.getDescribe().isCreateable() &&
					TouchCRBase__OrderItem__c.TouchCRBase__Product_Price__c.getDescribe().isCreateable()
			);
			if (isCreateableOrdersItem) {
				try {
					Database.UpsertResult[] bulkExcution;
					if (itemToRepair.size() > 0) {
						bulkExcution = Database.upsert(itemToRepair, false);
						setData(bulkExcution, 'OrderItems Repair');
					}
				}
				catch (DmlException e) {
				}
			}
			else {
				throw new privilegesException('privileges Exception l613');
			}

			/* Generate Log for repaired Orders  */
			Boolean isCreateableLog1 = (
				TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Endpoint__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Account__c.getDescribe().isCreateable()
			);
			if (isCreateableLog1) {
				try {
					insert repairLogs;
				}
				catch (DmlException e) {
				}
			}
			else {
				throw new privilegesException('privileges Exception l632');
			}
		}

		/* Create a List of SF Accounts */
		List<Account> accounts;
		Boolean isAccessibleAccount = (
			Account.Id.getDescribe().isAccessible() &&
				Account.PersonEmail.getDescribe().isAccessible()
		);
		if (isAccessibleAccount) {
			accounts = [SELECT Id, PersonEmail FROM Account WHERE PersonEmail IN :emails];
		}
		else {
			throw new privilegesException('privileges Exception l646');
		}

		Map<String, String> existAccount = new Map<String, String>();
		for (Account account:accounts) {
			existAccount.put(account.PersonEmail, account.Id);
		}

		/* Add new customers if customer not exist if SF */
		Map<String, String> shopifySettings = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
		String brand = shopifySettings.containsKey('Shopify.Brand') ? shopifySettings.get('Shopify.Brand') : 'test';
		String salesFunnel = shopifySettings.containsKey('Shopify.SalesFunnel') ? shopifySettings.get('Shopify.SalesFunnel') : 'test';
		List<Account> accountNeedToCreate = new List<Account>();
		List<Lead> leadNeedToCreate = new List<Lead>();
		List<String> newAccounts = new List<String>();
		Map<String, String> newAccountMap = new Map<String, String>();
		for (OrderDto order : ordersData) {
			String customerEmail, firstName, lastName, phone;
			try {
				customerEmail = order.customer.email;
				firstName = order.customer.first_name;
				lastName = order.customer.last_name;
				if (firstName == null || firstName == '') {
					firstName = '-';
				}
				if (lastName == null || lastName == '') {
					lastName = '-';
				}
			}
			catch (Exception e) {
			}

			try {
				if (customerEmail == null || customerEmail == '') {
					customerEmail = order.email;
				}
				customerEmail = customerEmail.toLowerCase();
				if (!existAccount.containsKey(customerEmail) && !newAccountMap.containsKey(customerEmail)) {
					if (order.billing_address.phone != null && order.billing_address.phone != '') {
						phone = order.billing_address.phone;
					}

					// the details of the sales funnel name and the utm parameters need to be copied from the order object to the customer contact
					// this allows us to understand at the customer contact level where the customer came from
					// set them both on Lead and Account

					Map<String, String> utmParametersFromOrderToCustomer = new Map<String, String>();
					Map<String, String> orderAddress = getAddressesFromShopifyOrder(order);

					if (order.landing_site != null) {
						utmParametersFromOrderToCustomer = getOrderUTL(String.valueOf(order.landing_site));
					}
					Lead aLead = new Lead(FirstName = firstName,
						LastName = lastName,
						Email = customerEmail,
						Status = 'Open'
					);
					if (order.customer.id == null || order.customer.id == '0') {
						order.customer.id = customerEmail;
					}
					aLead.TouchCRBase__Sales_Funnel__c = salesFunnel;
					aLead.TouchCRBase__utm_campaign__c = utmParametersFromOrderToCustomer.get('utm_campaign');
					aLead.TouchCRBase__utm_content__c = utmParametersFromOrderToCustomer.get('utm_content');
					aLead.TouchCRBase__utm_medium__c = utmParametersFromOrderToCustomer.get('utm_medium');
					aLead.TouchCRBase__utm_source__c = utmParametersFromOrderToCustomer.get('utm_source');
					aLead.TouchCRBase__utm_term__c = utmParametersFromOrderToCustomer.get('utm_term');

					Account aAccount = new Account(FirstName = firstName,
						LastName = lastName,
						Phone = phone,
						PersonEmail = customerEmail,
						TouchCRBase__Brand_Assortment__c = brand,
						ShopifyCustomerId__c = order.customer.id
					);

					aAccount.put('BillingStreet', orderAddress.get('bAddress1'));
					aAccount.put('BillingCity', orderAddress.get('bCity'));
					aAccount.put('BillingStateCode', orderAddress.get('bStateCode'));
					aAccount.put('BillingCountryCode', orderAddress.get('bCountryCode'));
					aAccount.put('BillingPostalCode', orderAddress.get('bPostCode'));

					aAccount.put('ShippingStreet', orderAddress.get('sAddress1'));
					aAccount.put('ShippingCity', orderAddress.get('sCity'));
					aAccount.put('ShippingStateCode', orderAddress.get('sStateCode'));
					aAccount.put('ShippingCountryCode', orderAddress.get('sCountryCode'));
					aAccount.put('ShippingPostalCode', orderAddress.get('sPostCode'));

					aAccount.TouchCRBase__sales_funnel_name__c = salesFunnel;
					aAccount.TouchCRBase__utm_campaign__c = utmParametersFromOrderToCustomer.get('utm_campaign');
					aAccount.TouchCRBase__utm_content__c = utmParametersFromOrderToCustomer.get('utm_content');
					aAccount.TouchCRBase__utm_medium__c = utmParametersFromOrderToCustomer.get('utm_medium');
					aAccount.TouchCRBase__utm_source__c = utmParametersFromOrderToCustomer.get('utm_source');
					aAccount.TouchCRBase__utm_term__c = utmParametersFromOrderToCustomer.get('utm_term');

					leadNeedToCreate.add(aLead);
					accountNeedToCreate.add(aAccount);
					newAccounts.add(customerEmail);
					newAccountMap.put(customerEmail, customerEmail);
				}
			}
			catch (Exception e) {
			}
		}

		/*account, leads, conversion*/
		if (accountNeedToCreate.size() > 0) {
			Boolean isCreateableAccount = (
				Account.FirstName.getDescribe().isCreateable() &&
					Account.LastName.getDescribe().isCreateable() &&
					Account.Phone.getDescribe().isCreateable() &&
					Account.PersonEmail.getDescribe().isCreateable() &&
					Account.TouchCRBase__Brand_Assortment__c.getDescribe().isCreateable() &&
					Account.TouchCRBase__sales_funnel_name__c.getDescribe().isCreateable() &&
					Account.ShopifyCustomerId__c.getDescribe().isCreateable()
			);
			if (isCreateableAccount) {
				try {
					/*Database.UpsertResult[] bulkExcution;
					bulkExcution = Database.upsert(accountNeedToCreate, false);
					setData(bulkExcution, 'Account');*/

					/////////////////
					List<Database.UpsertResult> upsertAccountresult = Database.upsert(accountNeedToCreate, false);
					List<TouchCRBase__Log__c> debugLogs = new List<TouchCRBase__Log__c>();

					for (Integer idx = 0; idx < accountNeedToCreate.size() - 1; idx++) {
						if (upsertAccountresult.get(idx).isSuccess()) {
							//pass
						}
						else {
							TouchCRBase__Log__c debugLog = new TouchCRBase__Log__c(
								TouchCRBase__Event_Type__c = 'Shopify Order Batch: Account',
								TouchCRBase__Event_Status__c = 'DEBUG',
								TouchCRBase__Event_Description__c = ''
							);
							for (Database.Error err : upsertAccountresult.get(idx).getErrors()) {
								debugLog.TouchCRBase__Event_Description__c += 'Error: ' + err.getStatusCode() + ': ' + err.getMessage() +
									'Fields: ' + err.getFields() + '\n';
							}
							Map<String, Object> fieldsToValue = accountNeedToCreate.get(idx).getPopulatedFieldsAsMap();
							for (String fieldName : fieldsToValue.keySet()) {
								debugLog.TouchCRBase__Event_Description__c += 'Name: ' + fieldName + ', Value: ' + fieldsToValue.get(fieldName);
							}
							debugLogs.add(debugLog);
						}
					}

					insert debugLogs;
					////////////////////

				}
				catch (DmlException e) {
				}
			}
			else {
				throw new privilegesException('privileges Exception l757');
			}

			Boolean isCreateableLead = (
				lead.FirstName.getDescribe().isCreateable() &&
					lead.LastName.getDescribe().isCreateable() &&
					lead.Email.getDescribe().isCreateable() &&
					lead.Status.getDescribe().isCreateable()
			);
			if (isCreateableLead) {
				try {
					Database.UpsertResult[] bulkExcution;
					bulkExcution = Database.upsert(leadNeedToCreate, false);
					setData(bulkExcution, 'Lead');
				}
				catch (DmlException e) {
				}
			}
			else {
				throw new privilegesException('privileges Exception l776');
			}

			/* recollect account records as avobe we insert some new records */
			Boolean isAccessibleAccount1 = (
				Account.Id.getDescribe().isAccessible() &&
					Account.PersonEmail.getDescribe().isAccessible()
			);
			if (isAccessibleAccount1) {
				accounts = [SELECT Id, PersonEmail FROM Account WHERE PersonEmail IN :emails];
			}
			else {
				throw new privilegesException('privileges Exception l788');
			}

			/* LEAD CONVERSION START */
			Map<String, String> newAccountToMap = new Map<String, String>();
			for (Account aAccount : accounts) {
				if (newAccountMap.containsKey(aAccount.PersonEmail)) {
					newAccountToMap.put(aAccount.PersonEmail, aAccount.Id);
				}
			}
			List<Lead> addedLeads;
			Boolean isAccessibleLead = (
				Lead.Id.getDescribe().isAccessible() &&
					Lead.Email.getDescribe().isAccessible()
			);
			if (isAccessibleLead) {
				addedLeads = [SELECT Id, Email FROM Lead WHERE Email IN :newAccounts];
			}
			else {
				throw new privilegesException('privileges Exception l807');
			}

			Map<String, String> addedLeadToMap = new Map<String, String>();
			for (Lead aLead : addedLeads) {
				addedLeadToMap.put(aLead.Email, aLead.Id);
			}
			LeadStatus convertStatus;
			Boolean isAccessibleLeadStatus = (
				LeadStatus.Id.getDescribe().isAccessible() &&
					LeadStatus.MasterLabel.getDescribe().isAccessible() &&
					LeadStatus.IsConverted.getDescribe().isAccessible()
			);
			if (isAccessibleLeadStatus) {
				convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
			}
			else {
				throw new privilegesException('privileges Exception l824');
			}

			List<Database.LeadConvert> leadConversions = new List<Database.LeadConvert>();
			Database.LeadConvert lc = new database.LeadConvert();
			for (String key : addedLeadToMap.keySet()) {
				String accountId = newAccountToMap.get(key);
				lc = new database.LeadConvert();
				lc.setLeadId(addedLeadToMap.get(key));
				lc.setAccountId(accountId);
				lc.setConvertedStatus(convertStatus.MasterLabel);
				lc.setDoNotCreateOpportunity(true);
				leadConversions.add(lc);
			}
			try {
				Database.convertLead(leadConversions);
			}
			catch (Exception e) {
			}
		}

		Map<String, String> accountIdsSF = new Map<String, String>();
		for (Account aAccount : accounts) {
			accountIdsSF.put(aAccount.PersonEmail, aAccount.Id);
		}
		/* Assign Account to Order if there is some order without Account Association */
		for (TouchCRBase__Order__c singleOrder : previousOrders) {
			if (singleOrder.TouchCRBase__Account__c == null) {
				String accountID = accountIdsSF.get(singleOrder.TouchCRBase__Billing_Email__c);
				singleOrder.TouchCRBase__Account__c = accountID;
			}
		}
		Boolean isUpdateableOrders = (
			TouchCRBase__Order__c.TouchCRBase__Account__c.getDescribe().isUpdateable()
		);

		if (isUpdateableOrders) {
			try {
				Database.UpsertResult[] bulkExcution;
				if (previousOrders.size() > 0) {
					bulkExcution = Database.upsert(previousOrders, false);
					setData(bulkExcution, 'Order');
				}
			}
			catch (DmlException e) {
			}
		}
		else {
			throw new privilegesException('privileges Exception l872');
		}

		/* Preparing order data to save orders in bulk */
		List<OrderDto.LineItems> shopifyLineItems = new List<OrderDto.LineItems>();
		List<String> shopifyOrderIds = new List<String>();
		//FIXME
		Set<String> shopifyNotPaidOrderIds = new Set<String>();
		Set<String> shopifyRefundedOrderIds = new Set<String>();

		List<String> shopifyProductIds = new List<String>();
		List<TouchCRBase__Order__c> ordersToCreate = new List<TouchCRBase__Order__c>();
		List<TouchCRBase__Log__c> accountLogList = new List<TouchCRBase__Log__c>();

		Map<String, String> shopifyFunnleSettings = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
		String shopifySalesFunnel = shopifyFunnleSettings.containsKey('Shopify.SalesFunnel') ? shopifyFunnleSettings.get('Shopify.SalesFunnel') : 'NA';

		Map<String, Account> prepareAccountData = new Map<String, Account>();
		List<String> accountIds = new List<String>();

		/*new and old accounts + orders*/
		for (OrderDto order : allValidFetchedOrdersList) {
			String status;
			Boolean HandleShipping = false;
			if (Test.isRunningTest()) {
				HandleShipping = true;
			}
			else {
				Map<String, String> shopifySettingss = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
				if (shopifySettingss.containsKey('Shopify.HandleShipping')) {
					HandleShipping = Boolean.valueOf(shopifySettingss.get('Shopify.HandleShipping'));
				}
			}
			status = HandleShipping ? 'Shipped' : 'Initiated';
			// ORDER TAXES
			if (order.total_tax == null) {
				order.total_tax = 0;
			}
			// ORDER SHIPPING
			Decimal shippingPrice = 0;
			if (order.shipping_lines != null || !order.shipping_lines.isEmpty()) {
				for (OrderDto.ShippingLines shippingLine : order.shipping_lines) {
					shippingPrice += shippingLine.price;
				}
			}
			// get Addresses map
			Map<String, String> orderAddress = getAddressesFromShopifyOrder(order);
			String currency_code = ShopifyProcessingHelper.validateAndFixCurrencyIsoCode(order.currencyType);

			String emailExistanceCheck;
			try {
				emailExistanceCheck = order.customer.email;
				if (emailExistanceCheck == null || emailExistanceCheck == '') {
					emailExistanceCheck = order.email;
				}
			}
			catch (Exception e) {
				emailExistanceCheck = order.email;
			}
			emailExistanceCheck = emailExistanceCheck.toLowerCase();
			String accountID = accountIdsSF.get(emailExistanceCheck);
			if (accountID == null) {
				TouchCRBase__Log__c accountLogItem = new TouchCRBase__Log__c(
					TouchCRBase__Event_Type__c = 'Account Does not exist',
					TouchCRBase__Event_Status__c = 'Error',
					TouchCRBase__Event_Endpoint__c = 'NA',
					TouchCRBase__Event_Description__c = 'Unable to create Account for order external id: ' + order.id + '. Customer First Name is: ' + order.customer.first_name + ', Last Name is: ' + order.customer.last_name + ' and Email id is: ' + order.customer.email
				);
				accountLogList.add(accountLogItem);
			}

			Map<String, String> parametersLandingSite = new Map<String, String>();
			if (order.landing_site != null) {
				parametersLandingSite = getOrderUTL(String.valueOf(order.landing_site));
			}

			// we fetched fresh order
			if (!previousOrderIds.containsKey(order.id)) {
				String ip = order.customer_ip;
				if (ip != null) {
					ip = ip.trim();
					if (ip.length() > 15) {
						ip = '';
					}
				}
				TouchCRBase__Order__c singleOrder = new TouchCRBase__Order__c(
					TouchCRBase__Account__c = accountID,
					TouchCRBase__Billing_Address__c = orderAddress.get('bAddress1'),
					TouchCRBase__Billing_City__c = orderAddress.get('bCity'),
					TouchCRBase__Billing_Email__c = orderAddress.get('bEmail'),
					TouchCRBase__Billing_First_Name__c = orderAddress.get('bFirstName'),
					TouchCRBase__Billing_Last_Name__c = orderAddress.get('bLastName'),
					TouchCRBase__Billing_Phone__c = orderAddress.get('bPhone'),
					TouchCRBase__Billing_State__c = orderAddress.get('bStateCode'),
					//
					TouchCRBase__Billing_Country__c = orderAddress.get('bCountryCode'),
					TouchCRBase__Billing_Zip_Postal__c = orderAddress.get('bPostCode'),
					TouchCRBase__Charge_Amount__c = order.total,
					TouchCRBase__Connected_Id__c = order.id,
					TouchCRBase__Connection_Name__c = connectionName,
					TouchCRBase__Customer_IP__c = ip,
					TouchCRBase__Date__c = order.completed_at,
					TouchCRBase__OrderNumber__c = order.order_number,
					TouchCRBase__sales_funnel_name__c = shopifySalesFunnel,
					//Shipping taxes not processed, as we didn't see real response with them
					// TouchCRBase__Shipping__c = order.total_shipping + order.shipping_tax,
					TouchCRBase__Shipping__c = shippingPrice,
					TouchCRBase__Shipping_Address__c = orderAddress.get('sAddress1'),
					TouchCRBase__Shipping_City__c = orderAddress.get('sCity'),
					TouchCRBase__Shipping_First_Name__c = orderAddress.get('sFirstName'),
					TouchCRBase__Shipping_Name__c = orderAddress.get('sLastName'),
					TouchCRBase__Shipping_Phone__c = orderAddress.get('bPhone'),
					TouchCRBase__Shipping_State__c = orderAddress.get('sStateCode'),
					TouchCRBase__Shipping_Country__c = orderAddress.get('sCountryCode'),
					TouchCRBase__Shipping_Zip_Postal__c = orderAddress.get('sPostCode'),
					TouchCRBase__Status__c = status,
					TouchCRBase__Subtotal__c = order.subtotal,
					//TouchCRBase__Tax__c = order.total_tax+order.cart_tax,
					TouchCRBase__Tax__c = order.total_tax,
					TouchCRBase__Utm_Campaign__c = parametersLandingSite.get('utm_campaign'),
					TouchCRBase__Utm_Content__c = parametersLandingSite.get('utm_content'),
					TouchCRBase__Utm_Medium__c = parametersLandingSite.get('utm_medium'),
					TouchCRBase__Utm_Source__c = parametersLandingSite.get('utm_source'),
					TouchCRBase__Utm_Term__c = parametersLandingSite.get('utm_term'),
					//
					TouchCRBase__Brand__c = connectionBrand,
					TouchCRBase__Currency__c = currency_code
				);
				// FIXME VOIDED Order
				Boolean isOrderNotEqualToPaid = (
					order.financial_status == 'voided'
				);
				Boolean isOrderEqualToRefunded = (
					order.financial_status == 'refunded'
				);
				Boolean isOrderEqualToPaid = (
					order.financial_status == 'authorized'
						|| order.financial_status == 'paid'
				);
				// enforce only one financial condition for order status
				if (isOrderNotEqualToPaid) {
					singleOrder.TouchCRBase__Status__c = 'Voided';
					shopifyNotPaidOrderIds.add(order.id);
				}
				else if (isOrderEqualToRefunded) {
					singleOrder.TouchCRBase__Status__c = 'Refunded';
					singleOrder.TouchCRBase__Payment_Received__c = 'None';
					shopifyRefundedOrderIds.add(order.Id);
				}
				else if (isOrderEqualToPaid) {
					// Payment recieved {}
					singleOrder.TouchCRBase__Payment_Received__c = 'Full';
				}

				ordersToCreate.add(singleOrder);
				shopifyOrderIds.add(order.id);


				/* Preparing Shopify products' Id list for order Items and assign Shopify order id to lineItem subclass for referancing SF Id */
				for (OrderDto.LineItems lineItem : order.line_items) {
					// FIXME
					// may contain null as it was faulty order
					if (String.isNotBlank(lineItem.product_id)) {
						shopifyProductIds.add(lineItem.product_id);
					}
					lineItem.orderId = order.id;
				}
			}
		}

		/*orders dml*/
		if (!ordersToCreate.isEmpty()) {
			//NEW ORDERS
			List<TouchCRBase__Order__c> createdOrders;
			Boolean isCreateableOrders = (
				TouchCRBase__Order__c.TouchCRBase__Account__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Connected_Id__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Status__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Date__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Charge_Amount__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Subtotal__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Tax__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Shipping__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__OrderNumber__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Customer_IP__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Billing_Email__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Billing_First_Name__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Billing_Last_Name__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Billing_Phone__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Billing_Address__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Billing_City__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Billing_State__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Billing_Zip_Postal__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Shipping_First_Name__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Shipping_Name__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Shipping_Phone__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Shipping_Address__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Shipping_City__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Shipping_State__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Shipping_Zip_Postal__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__sales_funnel_name__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Utm_Campaign__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Utm_Content__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Utm_Medium__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Utm_Source__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Utm_Term__c.getDescribe().isCreateable() &&
					TouchCRBase__Order__c.TouchCRBase__Currency__c.getDescribe().isCreateable()
			);
			if (isCreateableOrders) {
				try {
					Database.UpsertResult[] bulkExcution;
					bulkExcution = Database.upsert(ordersToCreate, false);
					setData(bulkExcution, 'Orders');
				}
				catch (DmlException e) {
				}
			}
			else {
				throw new privilegesException('privileges Exception l1251');
			}

			/* Prepare SF'id and Shopify's Order Data */
			Boolean isAccessibleOrders1 = (
				TouchCRBase__Order__c.Id.getDescribe().isAccessible() &&
					TouchCRBase__Order__c.TouchCRBase__Connected_Id__c.getDescribe().isAccessible() &&
					TouchCRBase__Order__c.TouchCRBase__Total__c.getDescribe().isAccessible() &&
					TouchCRBase__Order__c.TouchCRBase__Billing_First_Name__c.getDescribe().isAccessible() &&
					TouchCRBase__Order__c.TouchCRBase__Billing_Address__c.getDescribe().isAccessible() &&
					TouchCRBase__Order__c.TouchCRBase__Billing_City__c.getDescribe().isAccessible() &&
					TouchCRBase__Order__c.TouchCRBase__Billing_State__c.getDescribe().isAccessible() &&
					TouchCRBase__Order__c.TouchCRBase__Billing_Zip_Postal__c.getDescribe().isAccessible()
			);
			if (isAccessibleOrders1) {
				createdOrders = [
					SELECT Id, TouchCRBase__Connected_Id__c, TouchCRBase__Total__c, TouchCRBase__Billing_First_Name__c,
						TouchCRBase__Billing_Address__c, TouchCRBase__Billing_City__c, TouchCRBase__Billing_State__c, TouchCRBase__Billing_Zip_Postal__c, TouchCRBase__Date__c, TouchCRBase__Currency__c
					FROM TouchCRBase__Order__c
					WHERE TouchCRBase__Connected_Id__c IN :shopifyOrderIds
				];
			}
			else {
				throw new privilegesException('privileges Exception l1257');
			}

			//NEW TRANSACTION
			Map<String, String> createdOrderExternalIdToSfIdMap = new Map<String, String>();
			List<TouchCRBase__Order_Transaction__c> transactionToCreate = new List<TouchCRBase__Order_Transaction__c>();
			for (TouchCRBase__Order__c orderSF : createdOrders) {
				TouchCRBase__Order_Transaction__c transactionItem = new TouchCRBase__Order_Transaction__c(
					TouchCRBase__Order__c = orderSF.Id,
					TouchCRBase__Type__c = 'Charge',
					TouchCRBase__Response_Status__c = 'Approved',
					TouchCRBase__Payment_Method__c = 'Credit Card',
					TouchCRBase__Currency__c = orderSF.TouchCRBase__Currency__c,
					TouchCRBase__Amount__c = orderSF.TouchCRBase__Total__c,
					TouchCRBase__Billing_Address__c = orderSF.TouchCRBase__Billing_Address__c,
					TouchCRBase__Billing_City__c = orderSF.TouchCRBase__Billing_City__c,
					TouchCRBase__Billing_State__c = orderSF.TouchCRBase__Billing_State__c,
					TouchCRBase__Billing_Postal_Code__c = orderSF.TouchCRBase__Billing_Zip_Postal__c,
					//
					TouchCRBase__Payment_Date__c = orderSF.TouchCRBase__Date__c
				);
				// FIXME voided order
				Boolean isOrderVoided = (
					shopifyNotPaidOrderIds.contains(orderSF.TouchCRBase__Connected_Id__c)
				);
				Boolean isOrderRefunded = (
					shopifyRefundedOrderIds.contains(orderSF.TouchCRBase__Connected_Id__c)
				);
				if (isOrderVoided) {
					transactionItem.TouchCRBase__Type__c = 'Void';
					transactionItem.TouchCRBase__Response_Status__c = 'Approved';
				}
				else if (isOrderRefunded) {
					// add 2nd refund trasaction
					TouchCRBase__Order_Transaction__c refundedTransaction = new TouchCRBase__Order_Transaction__c(
						TouchCRBase__Order__c = orderSF.Id,
						TouchCRBase__Type__c = 'Refund',
						TouchCRBase__Response_Status__c = 'Approved',
						TouchCRBase__Payment_Method__c = 'Credit Card',
						TouchCRBase__Currency__c = 'US Dollars',
						TouchCRBase__Amount__c = -orderSF.TouchCRBase__Total__c,
						TouchCRBase__Billing_Address__c = orderSF.TouchCRBase__Billing_Address__c,
						TouchCRBase__Billing_City__c = orderSF.TouchCRBase__Billing_City__c,
						TouchCRBase__Billing_State__c = orderSF.TouchCRBase__Billing_State__c,
						TouchCRBase__Billing_Postal_Code__c = orderSF.TouchCRBase__Billing_Zip_Postal__c,
						TouchCRBase__Payment_Date__c = orderSF.TouchCRBase__Date__c
					);
					transactionToCreate.add(refundedTransaction);
				}

				transactionToCreate.add(transactionItem);
				createdOrderExternalIdToSfIdMap.put(orderSF.TouchCRBase__Connected_Id__c, orderSF.Id);
			}
			if (!transactionToCreate.isEmpty()) {
				Boolean isCreateableOrdersTransaction = (
					TouchCRBase__Order_Transaction__c.TouchCRBase__Order__c.getDescribe().isCreateable() &&
						TouchCRBase__Order_Transaction__c.TouchCRBase__Amount__c.getDescribe().isCreateable() &&
						TouchCRBase__Order_Transaction__c.TouchCRBase__Billing_Postal_Code__c.getDescribe().isCreateable() &&
						TouchCRBase__Order_Transaction__c.TouchCRBase__Response_Status__c.getDescribe().isCreateable() &&
						TouchCRBase__Order_Transaction__c.TouchCRBase__Billing_State__c.getDescribe().isCreateable() &&
						TouchCRBase__Order_Transaction__c.TouchCRBase__Billing_City__c.getDescribe().isCreateable() &&
						TouchCRBase__Order_Transaction__c.TouchCRBase__Billing_Address__c.getDescribe().isCreateable() &&
						TouchCRBase__Order_Transaction__c.TouchCRBase__Type__c.getDescribe().isCreateable() &&
						TouchCRBase__Order_Transaction__c.TouchCRBase__Payment_Method__c.getDescribe().isCreateable() &&
						//
						TouchCRBase__Order_Transaction__c.TouchCRBase__Payment_Date__c.getDescribe().isCreateable() &&
						//
						TouchCRBase__Order_Transaction__c.TouchCRBase__Currency__c.getDescribe().isCreateable()
				);
				if (isCreateableOrdersTransaction) {
					try {
						Database.UpsertResult[] bulkExcution;
						bulkExcution = Database.upsert(transactionToCreate, false);
						setData(bulkExcution, 'Orders Transaction');
					}
					catch (DmlException e) {
					}
				}
				else {
					throw new privilegesException('privileges Exception l1333');
				}
			}

			List<TouchCRBase__Product_Variant__c> productVariantData;
			Boolean isAccessibleProductVariantData = (
				TouchCRBase__Product_Variant__c.Id.getDescribe().isAccessible() &&
					TouchCRBase__Product_Variant__c.TouchCRBase__External_Id__c.getDescribe().isAccessible() &&
					TouchCRBase__Product_Variant__c.TouchCRBase__Product__c.getDescribe().isAccessible()
			);
			/**
			 * FIXME
			 * shopifyProductIds => shopifyProductIds.add(lineItem.product_id);
			 * BUT
			 * SELECT Id, ShopifyProductVariantID__c it is variant ids
			 * [2/8/17, 3:47:39 PM] Rajinder Kumar: as you can see we are creating 2 MAP
			 * SFVariantsIds.put(SFVariant.TouchCRShopify__ShopifyProductVariantID__c, SFVariant.Id);
			 * SFVariantsProductIds.put(SFVariant.TouchCRShopify__ShopifyProductVariantID__c, SFVariant.TouchCR__Product__c);
			 * [2/8/17, 3:47:51 PM] Rajinder Kumar: but we are not using them
			 */
			if (isAccessibleProductVariantData) {
				//productVariantData = [SELECT Id, ShopifyProductVariantID__c , TouchCRBase__Product__c FROM TouchCRBase__Product_Variant__c WHERE ShopifyProductVariantID__c IN: shopifyProductIds];
				productVariantData = [
					SELECT Id, TouchCRBase__External_Id__c, TouchCRBase__Product__c
					FROM TouchCRBase__Product_Variant__c
					WHERE TouchCRBase__External_Product_Id__c IN:shopifyProductIds
				];
			}
			else {
				throw new privilegesException('privileges Exception l1362');
			}

			Map<String, String> SFVariantsIds = new Map<String, String>();
			Map<String, String> SFVariantsProductIds = new Map<String, String>();
			for (TouchCRBase__Product_Variant__c SFVariant : productVariantData) {
				SFVariantsIds.put(SFVariant.TouchCRBase__External_Id__c, SFVariant.Id);
				SFVariantsProductIds.put(SFVariant.TouchCRBase__External_Id__c, SFVariant.TouchCRBase__Product__c);
			}

			/* Saving Order Items with Order Ids */
			List<String> oIds = new List<String>();
			List<TouchCRBase__OrderItem__c> itemToCreate = new List<TouchCRBase__OrderItem__c>();

			List<TouchCRBase__OrderItem__c> discountItems = new List<TouchCRBase__OrderItem__c>();
			Map<String, Decimal> orderWithFaultyOI = new Map<String, Decimal>();

			// valid orders => customer with email
			for (OrderDto order : allValidFetchedOrdersList) {
				for (OrderDto.LineItems lineItem : order.line_items) {
					// fetched order has line item with product from SF
					String pID = productIdsSF.get(lineItem.product_id);
					String pName = productNameSF.get(lineItem.product_id);

					//CHANGES FOR CORRUPTED LINE ITEMS
					// fetched product DISABLED at SF ? why skip it
					// fetched product DOES NOT EXIST at SF
					Boolean isFethcedOrderCreated = (
						(createdOrderExternalIdToSfIdMap.get(lineItem.orderId) != null)
					);
					Boolean isDisabledOrCoupon = (
						(disabledIds.containsKey(lineItem.product_id) || pName == couponName)
							&&
							isFethcedOrderCreated
					);
					Boolean isCorrupted = (
						(pID == null)
							&&
							isFethcedOrderCreated
					);

					if (isDisabledOrCoupon) {
						/* Related product is disabled or deleted. Prepare a list of order id to remove main order */
						oIds.add(createdOrderExternalIdToSfIdMap.get(lineItem.orderId));
						orderWithFaultyOI.put(createdOrderExternalIdToSfIdMap.get(lineItem.orderId), order.subtotal);
					}
					else if (isCorrupted && hasCorruptedLineItems) {
						TouchCRBase__OrderItem__c corruptedOI = new TouchCRBase__OrderItem__c(
							TouchCRBase__Order__c = createdOrderExternalIdToSfIdMap.get(lineItem.orderId),
							TouchCRBase__Connected_Id__c = lineItem.id,
							TouchCRBase__Connection_Name__c = connectionName,

							// corrupted order id
							TouchCRBase__Product__c = corruptedProduct.Id,
							TouchCRBase__Product_Variant__c = corruptedPVExternalIdToSfIdMap.containsKey(lineItem.title) ? corruptedPVExternalIdToSfIdMap.get(lineItem.title) : null,
							// create PV for each corrupted Product
							TouchCRBase__Quantity__c = lineItem.quantity,
							TouchCRBase__Product_Price__c = lineItem.price
						);
						itemToCreate.add(corruptedOI);

					}
					else {
						/* All data needed to place an order is validated */
						TouchCRBase__OrderItem__c oItem = new TouchCRBase__OrderItem__c(
							TouchCRBase__Order__c = createdOrderExternalIdToSfIdMap.get(lineItem.orderId),
							TouchCRBase__Connected_Id__c = lineItem.id,
							TouchCRBase__Connection_Name__c = connectionName,
							TouchCRBase__Product__c = pID,
							TouchCRBase__Quantity__c = lineItem.quantity,
							TouchCRBase__Product_Price__c = lineItem.price
						);

						if (String.isNotBlank(lineItem.variant_id)) {
							if (SFVariantsIds.containsKey(lineItem.variant_id)) {
								oItem.TouchCRBase__Product_Variant__c = SFVariantsIds.get(lineItem.variant_id);
							}
						}
						itemToCreate.add(oItem);
					}
				}
				/* Add Discounted Items in Item Line */
				if (createdOrderExternalIdToSfIdMap.containsKey(order.id)) {
					String singleOrderId = createdOrderExternalIdToSfIdMap.get(order.id);
					if (order.coupon_codes != null) {
						for (OrderDto.CouponCodes couponCode : order.coupon_codes) {
							Decimal discountAmount = (couponCode.amount != null) ? couponCode.amount : 0;
							String myCCode = couponCode.code;
							myCCode = myCCode.trim();
							myCCode = myCCode.toUpperCase();
							TouchCRBase__OrderItem__c oItem = new TouchCRBase__OrderItem__c(
								TouchCRBase__Order__c = singleOrderId,
								TouchCRBase__Product__c = couponMap.get(myCCode),
								TouchCRBase__Quantity__c = 1,
								TouchCRBase__Product_Price__c = -discountAmount
							);
							// special workaround for old corrupted data
							if (hasCorruptedLineItems && order.total_discount > 0 && discountAmount == 0) {
								oItem.TouchCRBase__Product_Price__c -= order.total_discount;
							}
							discountItems.add(oItem);
						}
					}
				}
			}

			Boolean isCreateableOrdersItem1 = (
				TouchCRBase__OrderItem__c.TouchCRBase__Product__c.getDescribe().isCreateable() &&
					TouchCRBase__OrderItem__c.TouchCRBase__Order__c.getDescribe().isCreateable() &&
					TouchCRBase__OrderItem__c.TouchCRBase__Quantity__c.getDescribe().isCreateable() &&
					TouchCRBase__OrderItem__c.TouchCRBase__Product_Price__c.getDescribe().isCreateable()
			);
			if (isCreateableOrdersItem1) {
				try {
					Database.UpsertResult[] bulkExcution;
					if (discountItems.size() > 0) {
						bulkExcution = Database.upsert(discountItems, false);
						setData(bulkExcution, 'discountItems');
					}
				}
				catch (DmlException e) {
				}
			}
			else {
				throw new privilegesException('privileges Exception l1486');
			}
			if (!itemToCreate.isEmpty()) {

				List<Database.SaveResult> insertOIresult = Database.insert(itemToCreate, false);
				List<TouchCRBase__Log__c> debugLogs = new List<TouchCRBase__Log__c>();

				for (Integer idx = 0; idx < itemToCreate.size() - 1; idx++) {
					if (insertOIresult.get(idx).isSuccess()) {
						//pass
					}
					else {
						TouchCRBase__Log__c debugLog = new TouchCRBase__Log__c(
							TouchCRBase__Event_Type__c = 'Shopify Order Batch: New Order Item',
							TouchCRBase__Event_Status__c = 'DEBUG',
							TouchCRBase__Event_Description__c = ''
						);
						for (Database.Error err : insertOIresult.get(idx).getErrors()) {
							debugLog.TouchCRBase__Event_Description__c += 'Error: ' + err.getStatusCode() + ': ' + err.getMessage() +
								'Fields: ' + err.getFields() + '\n';
						}
						Map<String, Object> fieldsToValue = itemToCreate.get(idx).getPopulatedFieldsAsMap();
						for (String fieldName : fieldsToValue.keySet()) {
							debugLog.TouchCRBase__Event_Description__c += 'Name: ' + fieldName + ', Value: ' + fieldsToValue.get(fieldName);
						}
						debugLogs.add(debugLog);
					}
				}

				insert debugLogs;
			}

			//CHANGES FOR CORRUPTED LINE ITEMS

			/*  Update Order Subtotal if order's Subtotal overwrite due to faulty order Item  */
			if (oIds.size() > 0) {
				Boolean isAccessibleOrdersWithBalance = (
					TouchCRBase__Order__c.Id.getDescribe().isAccessible() &&
						TouchCRBase__Order__c.TouchCRBase__Subtotal__c.getDescribe().isAccessible()
				);
				List<TouchCRBase__Order__c> orderWithBalance;
				if (isAccessibleOrdersWithBalance) {
					orderWithBalance = [SELECT Id, TouchCRBase__Subtotal__c FROM TouchCRBase__Order__c WHERE Id IN :oIds];
				}
				else {
					throw new privilegesException('privileges Exception l1549');
				}
				if (orderWithBalance.size() > 0) {
					for (TouchCRBase__Order__c order : orderWithBalance) {
						order.TouchCRBase__Subtotal__c = orderWithFaultyOI.get(order.Id);
					}
					Boolean isUpdateableOrders12 = (
						TouchCRBase__Order__c.TouchCRBase__Subtotal__c.getDescribe().isUpdateable()
					);
					if (isUpdateableOrders12) {
						Database.UpsertResult[] bulkOrdersExcution;
						bulkOrdersExcution = Database.upsert(orderWithBalance, false);
						setData(bulkOrdersExcution, 'Update Faulty Orders');
					}
					else {
						throw new privilegesException('privileges Exception l1564');
					}
				}
			}
		}
	}

	public void finish(Database.BatchableContext BC) {

		String callOut;
		String callOutLimit;

		Map<String, String> shopifySettings = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
		callOut = shopifySettings.containsKey('Shopify.orderCallOut') ? shopifySettings.get('Shopify.orderCallOut') : '';
		callOutLimit = shopifySettings.containsKey('Shopify.callOut') ? shopifySettings.get('Shopify.callOut') : '';

		if (callOut < callOutLimit) {
			Database.executeBatch(new ShopifyOrderBatch(), 100);
		}
		else {
			TouchCRBase.TouchCRHelper.setSettings(new Map<String, String>{
				'Shopify.orderCallOut' => '0'
			});
			if (!Test.isRunningTest()) {
				Database.executeBatch(new ShopifyScheduler());
			}
		}
	}

	private static Map<String, String> getOrderUTL(String str) {

		str = str.replace('u0026', '&');
		str = str.replace('&#38;', '&');
		str = str.replace('&amp;', '&');

		Map<String, String> result = new Map<String, String>();
		Pagereference utmParam = new Pagereference(str);
		result.put('utm_source', utmParam.getParameters().get('utm_source'));
		result.put('utm_medium', utmParam.getParameters().get('utm_medium'));
		result.put('utm_term', utmParam.getParameters().get('utm_term'));
		result.put('utm_content', utmParam.getParameters().get('utm_content'));
		result.put('utm_campaign', utmParam.getParameters().get('utm_campaign'));
		return result;
	}

	public void setData(Database.UpsertResult[] bulkExcution, String objectName) {

		String logDescription = '';
		List<TouchCRBase__Log__c> errorLogs = new List<TouchCRBase__Log__c>();
		Decimal errorCount = 0;
		for (Database.UpsertResult singleExcution : bulkExcution) {

			if (singleExcution.isSuccess()) {

				logDescription += singleExcution.getId() + '. ';
			}
			else {

				TouchCRBase__Log__c errorLog = new TouchCRBase__Log__c(
					TouchCRBase__Event_Type__c = 'Shopify Order Batch: ' + objectName,
					TouchCRBase__Event_Status__c = 'Error',
					TouchCRBase__Event_Endpoint__c = 'NA',
					TouchCRBase__Event_Description__c = ''
				);
				for (Database.Error err : singleExcution.getErrors()) {
					errorLog.TouchCRBase__Event_Description__c += 'Error: ' + String.join(err.getFields(), ', ') + ' ' +
						+err.getMessage() + ' with status code: ' + err.getStatusCode() + '.\n';
				}
				errorLog.TouchCRBase__Event_Description__c.abbreviate(32768);
				errorLogs.add(errorLog);
				errorCount++;
			}
		}

		if (errorLogs.size() > 0) {
			Boolean isCreateableLog = (
				TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Endpoint__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable()
			);
			if (isCreateableLog) {

				try {

					insert errorLogs;

				}
				catch (DmlException e) {
				}

			}
			else {
				throw new privilegesException('privileges Exception l1657');
			}
		}


		TouchCRBase__Log__c logRecord = new TouchCRBase__Log__c(
			TouchCRBase__Event_Type__c = 'Shopify Order Batch: ' + objectName,
			TouchCRBase__Event_Status__c = 'Success',
			TouchCRBase__Event_Endpoint__c = '',
			TouchCRBase__Event_Description__c = 'we processed: ' + bulkExcution.size() + ' records of ' + objectName + ' and faulty records is: ' + errorCount + ' .\n Inserted Ids are:  ' + logDescription
		);


		Boolean isCreateableLog1 = (

			TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Endpoint__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable()
		);

		if (isCreateableLog1) {

			try {
				insert logRecord;
			}
			catch (DmlException e) {
			}
		}
		else {
			throw new privilegesException('privileges Exception l1687');
		}
	}

	private Map<String, String> getAddressesFromShopifyOrder(OrderDto shOrder) {
		/* Get State code List */
		Map<String, String> result = new Map<String, String>{
			'sFirstName' => '',
			'sLastName' => '',
			'sAddress1' => '',
			'sCity' => '',
			'sStateCode' => '',
			'sCountryCode' => '',
			'sPhoneNumber' => '',
			'sPostCode' => '',
			'sPostCode' => '',

			'bFirstName' => '',
			'bLastName' => '',
			'bAddress1' => '',
			'bCity' => '',
			'bStateCode' => '',
			'bCountryCode' => '',
			'bPhone' => '',
			'bPostCode' => '',

			'bEmail' => ''
		};
		// shipping_address
		if (shOrder.shipping_address != null) {
			if (String.isNotBlank(shOrder.shipping_address.first_name)) {
				result.put('sFirstName', shOrder.shipping_address.first_name);
			}
			if (String.isNotBlank(shOrder.shipping_address.last_name)) {
				result.put('sLastName', shOrder.shipping_address.last_name);
			}
			if (String.isNotBlank(shOrder.shipping_address.address_1)) {
				result.put('sAddress1', shOrder.shipping_address.address_1);
			}
			if (String.isNotBlank(shOrder.shipping_address.city)) {
				result.put('sCity', shOrder.shipping_address.city);
			}
			// check country and state
			if (ShopifyProcessingHelper.checkCountryState(shOrder.shipping_address.country_code, shOrder.shipping_address.province_code)) {
				result.put('sCountryCode', shOrder.shipping_address.country_code);
				result.put('sStateCode', shOrder.shipping_address.province_code);
			}
			if (String.isNotBlank(shOrder.shipping_address.postcode)) {
				result.put('sPostCode', shOrder.shipping_address.postcode);
			}
			if (String.isNotBlank(shOrder.shipping_address.phone)) {
				result.put('sPhoneNumber', shOrder.shipping_address.phone);
			}
		}

		// billing_address
		if (String.isNotBlank(shOrder.email)) {
			result.put('bEmail', shOrder.email);
		}
		if (shOrder.billing_address != null) {
			if (String.isNotBlank(shOrder.billing_address.first_name)) {
				result.put('bFirstName', shOrder.billing_address.first_name);
			}
			if (String.isNotBlank(shOrder.billing_address.last_name)) {
				result.put('bLastName', shOrder.billing_address.last_name);
			}
			if (String.isNotBlank(shOrder.billing_address.address_1)) {
				result.put('bAddress1', shOrder.billing_address.address_1);
			}
			if (String.isNotBlank(shOrder.billing_address.city)) {
				result.put('bCity', shOrder.billing_address.city);
			}
			// check country and state
			if (ShopifyProcessingHelper.checkCountryState(shOrder.billing_address.country_code, shOrder.billing_address.province_code)) {
				result.put('bCountryCode', shOrder.billing_address.country_code);
				result.put('bStateCode', shOrder.billing_address.province_code);
			}
			if (String.isNotBlank(shOrder.billing_address.postcode)) {
				result.put('bPostCode', shOrder.billing_address.postcode);
			}
			if (String.isNotBlank(shOrder.billing_address.phone)) {
				result.put('bPhone', shOrder.billing_address.phone);
			}
		}
		return result;
	}

	public with sharing class privilegesException extends Exception {
	}
}