public with sharing class ShopifyProductBatch implements Database.Batchable<ProductDto>, Database.AllowsCallouts, Database.Stateful {

	public String connectionName;
	public String connectionPrefix;

	public static final String EXTID_JOINER = '__';

	public Iterable<ProductDto> start(Database.BatchableContext BC) {

		/* Get products from Shopify Site */
		List<ProductDto> externalProductsData = ShopifyShoppingCart.getProducts();

		/* external ids handling */
		/* at this point getPrevConnectionId should be not null and set to current connection */
		TouchCRBase__TouchCRConnection__c curConnection = ShopifyProcessingHelper.getConnectionById(
			ShopifyProcessingHelper.getPrevConnectionId()
		);
		connectionName = curConnection.Name;
		connectionPrefix = connectionName + EXTID_JOINER;

		/*Below code for update Product callout according product quantity -- Start*/
		Map<String, String> shopifySettings = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
		String callOut = shopifySettings.containsKey('Shopify.productCallOut') ? shopifySettings.get('Shopify.productCallOut') : 'NA';
		if (callOut == 'NA') {
			TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.productCallOut' => '0' });
			callOut = shopifySettings.containsKey('Shopify.productCallOut') ? shopifySettings.get('Shopify.productCallOut') : '0';
		}
		/* Update Callout Count */
		Integer callOutCount = 0;
		try {
			callOutCount = Integer.valueOf(callOut);
		}
		catch (Exception e) {}

		if (externalProductsData.size() > 0) {
			String item = String.valueOf(callOutCount + 1);
			TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.productCallOut' => item });
		}
		else {
			Map<String, String> shopifyLimit = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
			String callOutLimit = shopifyLimit.containsKey('Shopify.callOut') ? shopifyLimit.get('Shopify.callOut') : '0';
			TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.productCallOut' => callOutLimit });
		}

		/* add connection prefix on the fly to all scope product, varint, image */
		/* iterate over external products, collecting ids and date for products, variants, images */

		for (ProductDto externalProduct : externalProductsData) {
			/* product id */
			externalProduct.id = connectionPrefix + externalProduct.id;
			/* product variant id */
			for (ProductDto.Variations externalVariant : externalProduct.variations) {
				externalVariant.id = connectionPrefix + externalVariant.id;
				externalVariant.product_id = connectionPrefix + externalVariant.product_id;
				externalVariant.image_id = connectionPrefix + externalVariant.image_id;
			}
			for (ProductDto.Image image : externalProduct.images) {
				image.id = connectionPrefix + image.id;
				if (String.isNotBlank(image.product_id)) {
					image.product_id = connectionPrefix + image.product_id;
				}
				List<String> pvIdWithConnection = new List<String>();
				for (String pvId : image.variant_ids) {
					pvIdWithConnection.add(connectionPrefix + pvId);
				}
				image.variant_ids = pvIdWithConnection;
			}
		}
		/////////////////
		List<TouchCRBase__Log__c> errorLogs = new List<TouchCRBase__Log__c>{
			new TouchCRBase__Log__c(
				TouchCRBase__Event_Type__c = 'Shopify Products',
				TouchCRBase__Event_Status__c = 'In Progress',
				TouchCRBase__Event_Description__c = 'Number of received products: ' + externalProductsData.size()
			)
		};

		if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable()) {
			insert errorLogs;
		}
		/////////////////

		return externalProductsData;
	}

	public void execute(Database.BatchableContext BC, List<ProductDto> externalProductsData) {

		/* collection of new and existing products */
		List<ProductDto> productsList = new List<ProductDto>();
		/* ??? */
		Map<String, String> priceBookData = new Map<String, String>();
		/* product external ids */
		List<String> productsExternalIds = new List<String>();
		/* pvariant external ids */
		List<String> pVariantsExternalIds = new List<String>();
		/* pimage external ids */
		List<String> pImagesExternalIds = new List<String>();

		String since_id = '1';

		/* iterate over external products, collecting ids and date for products, variants, images */
		for (ProductDto externalProduct : externalProductsData) {
			Map<String, String> pVariantPriceToVariantId = new Map<String, String>();

			/*PV*/
			for (ProductDto.Variations externalVariant : externalProduct.variations) {
				// collect pv ext id
				pVariantsExternalIds.add(externalVariant.id);
				// get pv price
				String variantPrice = String.valueOf(externalVariant.price);
				if (!pVariantPriceToVariantId.containsKey(variantPrice)) {
					Integer productPriceKeyCount = pVariantPriceToVariantId.size();
					String extProductId = externalProduct.id;
					if (productPriceKeyCount != 0) {
						extProductId = externalProduct.id + '-' + productPriceKeyCount;
					}
					pVariantPriceToVariantId.put(variantPrice, extProductId);
					productsExternalIds.add(extProductId);
					priceBookData.put(extProductId, variantPrice);
				}
			}
			/*PI*/
			for (ProductDto.Image image : externalProduct.images) {
				pImagesExternalIds.add(image.id);
			}
			// add ext product
			productsList.add(externalProduct);
			// SAVE ORIGINAL EXTERNAL ID FOR FETCHING
			since_id = externalProduct.id.removeStartIgnoreCase(connectionPrefix);
		}

		/* Update last Product external Id */
		TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.lastProductExternalID' => since_id });

		/* Check and fetch if some product already exist in SF */
		List<String> existingProductsIds = new List<String>();
		List<Product2> existingProducts;

		/* external product id => product id */
		/* product id to external prodcut id */
		Map<String, String> productExtIdToProductId = new Map<String, String>();
		Map<String, String> prodcutIdtoProductExtId = new Map<String, String>();

		/* product image ext id to product image id
		product variant ext id to product image id */
		Map<String, String> pImageExtIdToProductImageId = new Map<String, String>();
		Map<String, String> pVariantExtIdToProductImageId = new Map<String, String>();

		List<TouchCRBase__Product_Image__c> existingImages;

		/* get existing PRODUCTS*/
		Boolean isAccessibleProduct = (
			Product2.Id.getDescribe().isAccessible() &&
			Product2.TouchCRBase__Connected_Id__c.getDescribe().isAccessible()
		);
		if (isAccessibleProduct) {
			existingProducts = [SELECT Id, TouchCRBase__Connected_Id__c
				FROM Product2
				WHERE TouchCRBase__Connection_Name__c = : connectionName
				AND TouchCRBase__Connected_Id__c IN : productsExternalIds];
		}
		else { throw new privilegesException('privileges Exception'); }

		/* get existing IMAGES */
		Boolean isAccessibleTouchCRProductImage = (
			TouchCRBase__Product_Image__c.Id.getDescribe().isAccessible() &&
			TouchCRBase__Product_Image__c.TouchCRBase__Product_Image_External_Id__c.getDescribe().isAccessible() &&
			TouchCRBase__Product_Image__c.TouchCRBase__Variant_Image_External_Id__c.getDescribe().isAccessible() &&
			TouchCRBase__Product_Image__c.TouchCRBase__Integration_Name__c.getDescribe().isAccessible()
		);
		if (isAccessibleTouchCRProductImage) {
			existingImages = [
				SELECT Id, TouchCRBase__Product_Image_External_Id__c, TouchCRBase__Variant_Image_External_Id__c
				FROM TouchCRBase__Product_Image__c
				WHERE (TouchCRBase__Product_Image_External_Id__c IN: pImagesExternalIds OR TouchCRBase__Variant_Image_External_Id__c IN: pImagesExternalIds )
				AND TouchCRBase__Integration_Name__c =: connectionName
			];
		}
		else { throw new privilegesException('privileges Exception'); }

		/* collect product image OR product variant external ids to exisitng image id */
		for (TouchCRBase__Product_Image__c existingImage : existingImages) {
			if (existingImage.TouchCRBase__Product_Image_External_Id__c != null) {
				pImageExtIdToProductImageId.put(existingImage.TouchCRBase__Product_Image_External_Id__c, existingImage.Id);
			}
			if (existingImage.TouchCRBase__Variant_Image_External_Id__c != null) {
				pVariantExtIdToProductImageId.put(existingImage.TouchCRBase__Variant_Image_External_Id__c, existingImage.Id);
			}
		}
		/* collect product id to external product id maps */
		for (Product2 existingProduct : existingProducts) {
			// fill map extPr id to prId
			productExtIdToProductId.put(existingProduct.TouchCRBase__Connected_Id__c, existingProduct.Id);
			// fill map prId to ext id
			prodcutIdtoProductExtId.put(existingProduct.Id, existingProduct.TouchCRBase__Connected_Id__c);

			existingProductsIds.add(existingProduct.Id);
		}

		/* Price book prepare to update */
		/* get PBE for exisitng products */
		List<PricebookEntry> pbeForExistingProducts;
		Boolean isAccessiblePricebookEntry = (
			PricebookEntry.Id.getDescribe().isAccessible() &&
			PricebookEntry.Product2Id.getDescribe().isAccessible()
		);
		if (isAccessiblePricebookEntry) {
			pbeForExistingProducts = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2Id IN: existingProductsIds];
		}
		else { throw new privilegesException('privileges Exception'); }

		/* Preparing next data and inserting new products into SF */
		for (PricebookEntry pbe : pbeForExistingProducts) {
			String externalShopifyId = prodcutIdtoProductExtId.get(pbe.Product2Id);
			Decimal newPrice = Decimal.valueOf(priceBookData.get(externalShopifyId));
			pbe.UnitPrice = newPrice;
		}
		Boolean isUpdateablePricebookEntry = (
			PricebookEntry.UnitPrice.getDescribe().isUpdateable()
		);
		if (isUpdateablePricebookEntry) {
			try {
				Database.UpsertResult[] bulkExcution;
				if (pbeForExistingProducts.size() > 0) {
					bulkExcution = Database.upsert(pbeForExistingProducts, false);
					setData(bulkExcution , 'PriceBook Update');
				}
			} catch (DmlException e) {} } else {throw new privilegesException('privileges Exception');
		}

		Map<String, String> newProduct = new Map<String, String>();
		Map<String, String> productVariantIdWithProductId = new Map<String, String>();
		Product2[] productItems = new Product2[]{};
		Map<String, Product2> productToUpdate = new Map<String, Product2>();

		/**
		 * PRODUCTS
		 */
		for (ProductDto product : productsList) {
			Boolean status = false;
			if (product.status == 'publish' || product.status == null ) {
				status = true;
			}

			Map<String, String> productPriceWithId = new Map<String, String>();
			List<ProductDto.Variations> variants = product.variations;
			Integer cnt = variants.size();

			/* Prepare products data which has not any variants */
			if (cnt == 0) {
				String description = product.description;
				description = description.replaceAll('\\<.*?\\>', '');

				Integer productPriceKeyCount = productPriceWithId.size();
				String productId = product.id;
				if (productPriceKeyCount != 0) {
					productId = product.id + '-' + productPriceKeyCount;
				}

				if (!productExtIdToProductId.containsKey(product.id)) {
					newProduct.put(product.id, product.title);
					Product2 SFProduct = new Product2(
						Name = product.title,
						Description = description,
						ProductCode = product.sku,
						IsActive = status,
						TouchCRBase__Connected_Id__c = productId,
						TouchCRBase__Connection_Name__c = connectionName
					);
					productItems.add(SFProduct);
				}
				else {
					Product2 toProduct = new Product2(
						Name = product.title,
						Description = description,
						ProductCode = product.sku,
						IsActive = status,
						TouchCRBase__Connected_Id__c = productId,
						TouchCRBase__Connection_Name__c = connectionName
					);
					productToUpdate.put(productExtIdToProductId.get(productId), toProduct);
				}
			}

			/* Prepare products data which has some variants */
			for (ProductDto.Variations variant : product.variations) {
				String variantPrice = String.valueOf(variant.price);

				if (productPriceWithId.containsKey(variantPrice)) {
					String lastProductId = productPriceWithId.get(variantPrice);
					productVariantIdWithProductId.put(variant.id, lastProductId);
				}
				else {
					/* Preparing Product external Ids */
					Integer productPriceKeyCount = productPriceWithId.size();
					String productId = product.id;
					if (productPriceKeyCount != 0) {
						productId = product.id + '-' + productPriceKeyCount;
					}

					String description = product.description;
					if (description != null) {
						description = description.replaceAll('\\<.*?\\>', '');
					}

					if (!productExtIdToProductId.containsKey(productId)) {
						newProduct.put(product.id, product.title);
						Product2 SFProduct = new Product2(
							Name = product.title,
							Description = description,
							ProductCode = product.sku,
							IsActive = status,
							TouchCRBase__Connected_Id__c = productId,
							TouchCRBase__Connection_Name__c = connectionName
						);
						productItems.add(SFProduct);

						productPriceWithId.put(variantPrice, productId);
						productsExternalIds.add(productId);
						productVariantIdWithProductId.put(variant.id, productId);
					}
					else {
						Product2 toProduct = new Product2(
							Name = product.title,
							Description = description,
							ProductCode = product.sku,
							IsActive = status,
							TouchCRBase__Connected_Id__c = productId,
							TouchCRBase__Connection_Name__c = connectionName
							);
						productToUpdate.put(productExtIdToProductId.get(productId), toProduct);
						productPriceWithId.put(variantPrice, productId);
					}
				}
			}
		}

		Boolean isCreateableProduct = (
			Product2.Name.getDescribe().isCreateable() &&
			Product2.Description.getDescribe().isCreateable() &&
			Product2.ProductCode.getDescribe().isCreateable() &&
			Product2.IsActive.getDescribe().isCreateable() &&
			Product2.TouchCRBase__Connected_Id__c.getDescribe().isCreateable() &&
			Product2.TouchCRBase__Connection_Name__c.getDescribe().isCreateable()
		);
		if (isCreateableProduct) {
			try {
				Database.UpsertResult[] bulkExcution;
				if (productItems.size() > 0) {
					bulkExcution = Database.upsert(productItems, false);
					setData(bulkExcution, 'ProductDto');
				}
			} catch(DmlException e){}
		} else { throw new privilegesException('privileges Exception'); }

		/* Update Existing products */
		for (Product2 singleProduct : existingProducts) {
			try {
				Product2 productFromShopify                     = productToUpdate.get(singleProduct.Id);
				singleProduct.Name                              = productFromShopify.Name;
				singleProduct.Description                       = productFromShopify.Description;
				singleProduct.ProductCode                       = productFromShopify.ProductCode;
				singleProduct.IsActive                          = productFromShopify.IsActive;
				singleProduct.TouchCRBase__Connected_Id__c      = productFromShopify.TouchCRBase__Connected_Id__c;
				singleProduct.TouchCRBase__Connection_Name__c   = productFromShopify.TouchCRBase__Connection_Name__c;
			} catch(Exception e) {}
		}

		Boolean isUpdateableProduct = (
			Product2.Name.getDescribe().isUpdateable() &&
			Product2.Description.getDescribe().isUpdateable() &&
			Product2.ProductCode.getDescribe().isUpdateable() &&
			Product2.IsActive.getDescribe().isUpdateable() &&
			Product2.TouchCRBase__Connected_Id__c.getDescribe().isUpdateable() &&
			Product2.TouchCRBase__Connection_Name__c.getDescribe().isUpdateable()
		);
		if (isUpdateableProduct) {
			Database.upsert(existingProducts, false);
		}
		else { throw new privilegesException('privileges Exception'); }

		if (productItems.size() > 0) {
			Boolean isAccessibleProduct1 = (
				Product2.Id.getDescribe().isAccessible() &&
				Product2.TouchCRBase__Connected_Id__c.getDescribe().isAccessible() &&
				Product2.TouchCRBase__Connection_Name__c.getDescribe().isAccessible()
			);
			if (isAccessibleProduct1){
				existingProducts = [SELECT Id, TouchCRBase__Connected_Id__c FROM Product2 WHERE TouchCRBase__Connected_Id__c IN: productsExternalIds];
			}
			else { throw new privilegesException('privileges Exception'); }
		}

		Map<String, String> allProductIds = new Map<String, String>();
		for (Product2 singleProduct : existingProducts) {
			allProductIds.put(singleProduct.TouchCRBase__Connected_Id__c, singleProduct.Id);
		}

		Id pBookId;
		if (!Test.isRunningTest()) {
			Boolean isAccessiblePriceBook = (
				PriceBook2.Id.getDescribe().isAccessible() &&
				PriceBook2.Name.getDescribe().isAccessible()
			);
			if (isAccessiblePriceBook) {
				String priceBookName = 'Standard Price Book';
				pBookId = [SELECT Id FROM PriceBook2 WHERE Name = :priceBookName].Id;
			}
			else { throw new privilegesException('privileges Exception'); }
		}

		/* DML OPERATIONS */
		/* inserting all product related data into SF  */
		List<PricebookEntry> priceToadd = new List<PricebookEntry>();
		List<TouchCRBase__Product_Image__c> imagesToadd = new List<TouchCRBase__Product_Image__c>();
		List<TouchCRBase__Product_Variant__c> variantToadd = new List<TouchCRBase__Product_Variant__c>();
		List<TouchCRBase__Product_Variant__c> variantToUpdate = new List<TouchCRBase__Product_Variant__c>();
		List<String> variantIds = new List<String>();

		/* add new Price book */
		for (string key : priceBookData.keySet()) {
			String shopifyProductPrice = priceBookData.get(key);
			String SfProductId = allProductIds.get(key);
			if (!prodcutIdtoProductExtId.containsKey(SfProductId)) {
				PricebookEntry pBook = new PricebookEntry(UnitPrice = Decimal.valueOf(shopifyProductPrice), Product2Id = SfProductId, Pricebook2Id = pBookId, IsActive = true);
				priceToadd.add(pBook);
			}
		}

		Boolean isCreateablePricebookEntry = (
			PricebookEntry.UnitPrice.getDescribe().isCreateable() &&
			PricebookEntry.Pricebook2Id.getDescribe().isCreateable() &&
			PricebookEntry.IsActive.getDescribe().isCreateable() &&
			PricebookEntry.Product2Id.getDescribe().isCreateable()
		);
		if (isCreateablePricebookEntry) {
			try {
				Database.UpsertResult[] bulkExcution;
				if (priceToadd.size()>0) {
					bulkExcution = Database.upsert(priceToadd, false);
					setData(bulkExcution, 'PriceBook');
				}
			}
			catch(DmlException e){}
		}
		else { throw new privilegesException('privileges Exception'); }

		/**
		 * PRODUCT VARIANTS
		 */
		Boolean isAccessibleTouchCRProductVariant = (
			TouchCRBase__Product_Variant__c.Id.getDescribe().isAccessible() &&
			//TouchCRBase__Product_Variant__c.ShopifyProductVariantID__c.getDescribe().isAccessible() &&
			TouchCRBase__Product_Variant__c.TouchCRBase__External_Id__c.getDescribe().isAccessible()
		);

		List<TouchCRBase__Product_Variant__c> pVariants;
		if (isAccessibleTouchCRProductVariant) {
			pVariants = [SELECT Id, TouchCRBase__External_Id__c FROM TouchCRBase__Product_Variant__c WHERE TouchCRBase__External_Id__c IN :pVariantsExternalIds];
		}
		else { throw new privilegesException('privileges Exception'); }

		/**
		 * PRODUCT IMAGE
		 * PRODUCT VARIANT
		 */
		for (ProductDto product : productsList) {
			String pId = allProductIds.get(product.id);
			if (newProduct.containsKey(product.id)) {
				// add Product Images
				for (ProductDto.Image image : product.images) {
					if (!pImageExtIdToProductImageId.containsKey(image.id)) {
						TouchCRBase__Product_Image__c pImages = new TouchCRBase__Product_Image__c(
							TouchCRBase__Product_Lookup__c = pId,
							TouchCRBase__Image_URL__c = image.src,
							TouchCRBase__Product_Alt_Tag__c = image.alt,
							TouchCRBase__Product_Image_Description__c = image.title,
							TouchCRBase__Product_Image_External_Id__c = image.id,
							TouchCRBase__Integration_Name__c = connectionName,
							TouchCRBase__Display_Order__c = image.position
						);
						imagesToadd.add(pImages);
					}
				}
				// add Product Variant & dummy product images
				for (ProductDto.Variations variant : product.variations) {
					String productId;
					if (productVariantIdWithProductId.containsKey(variant.id)) {
						productId = productVariantIdWithProductId.get(variant.id);
						pId = allProductIds.get(productId);
						List<string> ls1 = productId.split('-');
						if (ls1.size() > 1) {
							for (ProductDto.Image image : product.images) {
								if (!pImageExtIdToProductImageId.containsKey(image.id)) {
									TouchCRBase__Product_Image__c pImages = new TouchCRBase__Product_Image__c(
										TouchCRBase__Product_Lookup__c = pId,
										TouchCRBase__Image_URL__c = image.src,
										TouchCRBase__Product_Alt_Tag__c = image.alt,
										TouchCRBase__Product_Image_Description__c = image.title,
										TouchCRBase__Product_Image_External_Id__c = image.id,
										TouchCRBase__Integration_Name__c = connectionName,
										TouchCRBase__Display_Order__c = image.position
									);
									imagesToadd.add(pImages);
								}
							}
						}
					}

					TouchCRBase__Product_Variant__c pVariant = new TouchCRBase__Product_Variant__c(
						TouchCRBase__Product__c = pId,
						Name = variant.title.abbreviate(80),
						TouchCRBase__Product_Title__c = variant.title.abbreviate(100),
						TouchCRBase__sku__c = variant.sku,
						TouchCRBase__Price__c = variant.price,

						TouchCRBase__Integration_Name__c = connectionName,
						TouchCRBase__External_Id__c = variant.id,
						TouchCRBase__External_Product_Id__c = variant.product_id,

						TouchCRBase__Position__c = variant.position,
						TouchCRBase__Taxable__c = variant.taxable
					);
					variantIds.add(variant.id);
					variantToadd.add(pVariant);
				}
			}
			else {
				// Repair Product's variants
				Map<String, String> pVariantsMap = new Map<String, String>();
				for (TouchCRBase__Product_Variant__c pv : pVariants) {
					pVariantsMap.put(pv.TouchCRBase__External_Id__c, pv.Id);
				}
				Map<String, ProductDto.Variations> updateVatiantList = new  Map<String, ProductDto.Variations>();
				for (ProductDto.Variations variant : product.variations) {
					if (!pVariantsMap.containsKey(variant.id)) {
						TouchCRBase__Product_Variant__c pVariant = new TouchCRBase__Product_Variant__c(
							TouchCRBase__Product__c = pId,
							Name = variant.title.abbreviate(80),
							TouchCRBase__Product_Title__c = variant.title.abbreviate(100),
							TouchCRBase__sku__c = variant.sku,
							TouchCRBase__Price__c = variant.price,

							TouchCRBase__Integration_Name__c = connectionName,
							TouchCRBase__External_Id__c = variant.id,
							TouchCRBase__External_Product_Id__c = variant.product_id,

							TouchCRBase__Position__c = variant.position,
							TouchCRBase__Taxable__c = variant.taxable
						);
						variantToUpdate.add(pVariant);
						variantIds.add(variant.id);
					}
					updateVatiantList.put(variant.id, variant);
				}

				for (TouchCRBase__Product_Variant__c oldVariants : pVariants) {
					if (updateVatiantList.containsKey(oldVariants.TouchCRBase__External_Id__c)) {
						ProductDto.Variations singleV = updateVatiantList.get(oldVariants.TouchCRBase__External_Id__c);
						oldVariants.TouchCRBase__sku__c = singleV.sku;
						oldVariants.TouchCRBase__Price__c = singleV.price;
					}
				}
			}
		}

		if (variantToUpdate.size() > 0) {
			Boolean isCreateableTouchCRProductVariant  =(
				TouchCRBase__Product_Variant__c.TouchCRBase__Product__c.getDescribe().isCreateable() &&
				TouchCRBase__Product_Variant__c.TouchCRBase__sku__c.getDescribe().isCreateable() &&
				TouchCRBase__Product_Variant__c.TouchCRBase__Price__c.getDescribe().isCreateable()&&
				TouchCRBase__Product_Variant__c.TouchCRBase__External_Id__c.getDescribe().isCreateable() &&
				TouchCRBase__Product_Variant__c.TouchCRBase__Integration_Name__c.getDescribe().isCreateable()
			);
			if (isCreateableTouchCRProductVariant) {
				try {
					Database.UpsertResult[] bulkExcution;
					bulkExcution = Database.upsert(variantToUpdate, false);
					setData(bulkExcution, 'Update Variants');
				}
				catch (DmlException e){}
			}
			else { throw new privilegesException('privileges Exception'); }
		}

		Boolean isUpdateableTouchCRProductVariant = (
			TouchCRBase__Product_Variant__c.TouchCRBase__Product__c.getDescribe().isUpdateable () &&
			TouchCRBase__Product_Variant__c.TouchCRBase__sku__c.getDescribe().isUpdateable () &&
			TouchCRBase__Product_Variant__c.TouchCRBase__Price__c.getDescribe().isUpdateable ()&&
			TouchCRBase__Product_Variant__c.TouchCRBase__External_Id__c.getDescribe().isUpdateable () &&
			TouchCRBase__Product_Variant__c.TouchCRBase__Integration_Name__c.getDescribe().isUpdateable ()
		);
		if (isUpdateableTouchCRProductVariant) {
			try {
				Database.UpsertResult[] bulkExcution;
				if (pVariants.size() > 0) {
					bulkExcution = Database.upsert(pVariants, false);
					setData(bulkExcution, 'Update Variants');
				}
			}
			catch (DmlException e){}
		}
		else { throw new privilegesException('privileges Exception'); }

		Boolean isCreateableTouchCRProductImage = (
			TouchCRBase__Product_Image__c.TouchCRBase__Product_Alt_Tag__c.getDescribe().isCreateable() &&
			TouchCRBase__Product_Image__c.TouchCRBase__Product_Lookup__c.getDescribe().isCreateable() &&
			TouchCRBase__Product_Image__c.TouchCRBase__Product_Image_Description__c.getDescribe().isCreateable()&&
			TouchCRBase__Product_Image__c.TouchCRBase__Product_Image_External_Id__c.getDescribe().isCreateable() &&
			TouchCRBase__Product_Image__c.TouchCRBase__Image_URL__c.getDescribe().isCreateable() &&
			TouchCRBase__Product_Image__c.TouchCRBase__Variant_Image_External_Id__c.getDescribe().isCreateable() &&
			TouchCRBase__Product_Image__c.TouchCRBase__Integration_Name__c.getDescribe().isCreateable()
		);

		if (isCreateableTouchCRProductImage) {
			try {
				Database.UpsertResult[] bulkExcution;
				if (imagesToadd.size() > 0) {
					bulkExcution = Database.upsert(imagesToadd, false);
					setData(bulkExcution, 'Images');
				}
			}
			catch (DmlException e) {}
		}
		else { throw new privilegesException('privileges Exception'); }

		//  insert priceToadd;
		Boolean isCreateableProduct2 = (
			Product2.Name.getDescribe().isCreateable() &&
			Product2.Description.getDescribe().isCreateable() &&
			Product2.ProductCode.getDescribe().isCreateable() &&
			Product2.IsActive.getDescribe().isCreateable() &&
			Product2.TouchCRBase__Connected_Id__c.getDescribe().isCreateable() &&
			Product2.TouchCRBase__Connection_Name__c.getDescribe().isCreateable()
		);

		if (isCreateableProduct2) {
			try {
				Database.UpsertResult[] bulkExcution;
				if (productItems.size() > 0) {
					bulkExcution = Database.upsert(productItems, false);
					setData(bulkExcution, 'ProductDto');
				}
			} catch(DmlException e) {}
		}
		else { throw new privilegesException('privileges Exception'); }

		// insert variantToadd;
		Boolean isCreateableTouchCRProductVariant = (
			TouchCRBase__Product_Variant__c.TouchCRBase__Product__c.getDescribe().isCreateable() &&
			TouchCRBase__Product_Variant__c.TouchCRBase__sku__c.getDescribe().isCreateable() &&
			TouchCRBase__Product_Variant__c.TouchCRBase__Price__c.getDescribe().isCreateable()&&
			TouchCRBase__Product_Variant__c.TouchCRBase__External_Id__c.getDescribe().isCreateable() &&
			TouchCRBase__Product_Variant__c.TouchCRBase__Integration_Name__c.getDescribe().isCreateable()
		);

		if (isCreateableTouchCRProductVariant) {
			try {
				Database.UpsertResult[] bulkExcution;
				if (variantToadd.size() > 0) {
					bulkExcution = Database.upsert(variantToadd, false);
					setData(bulkExcution, 'Variant');
				}
			}
			catch(DmlException e) {}
		}
		else { throw new privilegesException('privileges Exception'); }

		List<TouchCRBase__Product_Variant__c> variantData;
		Map<String, String> allVariantIds = new Map<String, String>();

		Boolean isAccessibleTouchCRProductVariant1 = (
			TouchCRBase__Product_Variant__c.Id.getDescribe().isAccessible() &&
			TouchCRBase__Product_Variant__c.TouchCRBase__External_Id__c.getDescribe().isAccessible() &&
			TouchCRBase__Product_Variant__c.TouchCRBase__Integration_Name__c.getDescribe().isAccessible()
		);
		if (isAccessibleTouchCRProductVariant1) {
			variantData = [SELECT Id, TouchCRBase__External_Id__c FROM TouchCRBase__Product_Variant__c WHERE TouchCRBase__External_Id__c IN: variantIds];
		}
		else { throw new privilegesException('privileges Exception'); }

		for (TouchCRBase__Product_Variant__c singleVariant : variantData) {
			allVariantIds.put(singleVariant.TouchCRBase__External_Id__c, singleVariant.Id);
		}

		/*ADD IMAGES TO PV*/
		List<TouchCRBase__Product_Image__c> vImagesToadd = new List<TouchCRBase__Product_Image__c>();
		for (ProductDto product : productsList) {
			String pId = allProductIds.get(product.id);
			for (ProductDto.Variations variant : product.variations) {
				String variantImage;
				String variantImageId;
				String variantImageAlt;
				String variantImageTitle;
				Integer position;
				for (ProductDto.Image image : product.images) {
					String variantsIds = String.join(image.variant_ids, ',');
					if (variantsIds.contains(variant.id)) {
						variantImage = image.src;
						variantImageId = image.id;
						variantImageAlt = image.alt;
						variantImageTitle = image.title;
						position = image.position;
					}
				}
				// Add Variants Images
				String vId = allVariantIds.get(variant.id);
				if (variantImage != null && !pVariantExtIdToProductImageId.containsKey(variantImageId)) {
					TouchCRBase__Product_Image__c vImage = new TouchCRBase__Product_Image__c(
						TouchCRBase__Product_Variant_Lookup__c = vId,
						TouchCRBase__Image_URL__c = variantImage,
						TouchCRBase__Product_Alt_Tag__c = variantImageAlt,
						TouchCRBase__Product_Image_Description__c = variantImageTitle,
						TouchCRBase__Variant_Image_External_Id__c = variantImageId,
						TouchCRBase__Integration_Name__c = connectionName,
						TouchCRBase__Display_Order__c = position
					);
					vImagesToadd.add(vImage);
				}
			}
		}

		Boolean isCreateableTouchCRProductImage3 = (
			TouchCRBase__Product_Image__c.TouchCRBase__Product_Alt_Tag__c.getDescribe().isCreateable() &&
			TouchCRBase__Product_Image__c.TouchCRBase__Product_Variant_Lookup__c.getDescribe().isCreateable() &&
			TouchCRBase__Product_Image__c.TouchCRBase__Product_Image_Description__c.getDescribe().isCreateable()&&
			TouchCRBase__Product_Image__c.TouchCRBase__Image_URL__c.getDescribe().isCreateable() &&
			TouchCRBase__Product_Image__c.TouchCRBase__Variant_Image_External_Id__c.getDescribe().isCreateable() &&
			TouchCRBase__Product_Image__c.TouchCRBase__Integration_Name__c.getDescribe().isCreateable()
		);
		if (isCreateableTouchCRProductImage3) {
			try {
				Database.UpsertResult[] bulkExcution;
				if (vImagesToadd.size() > 0) {
					bulkExcution = Database.upsert(vImagesToadd, false);
					setData(bulkExcution, 'VariantImages');
				}
			}
			catch (DmlException e) {}
		}
		else { throw new privilegesException('privileges Exception'); }
	}

	public void finish(Database.BatchableContext BC) {
		String callOut;
		String callOutLimit;
		Map<String, String> shopifySettings = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
		callOut = shopifySettings.containsKey('Shopify.productCallOut') ? shopifySettings.get('Shopify.productCallOut') : '';
		callOutLimit = shopifySettings.containsKey('Shopify.callOut') ? shopifySettings.get('Shopify.callOut') : '';
		if (callOut < callOutLimit) {
			Database.executeBatch(new ShopifyProductBatch(), 100);
		}
		else {
			TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.productCallOut' => '0' });
			/**
			* If all batch executions finished, i.e. callout limit reached, execute next batch in chain
			*/
			if (!Test.isRunningTest()) {
				Database.executeBatch(new ShopifyOrderBatch(), 100);
			}
		}
	}

	public void setData(Database.UpsertResult[] bulkExcution, String objectName){
		String logDescription = '';
		List<TouchCRBase__Log__c> errorLogs = new List<TouchCRBase__Log__c>();
		Decimal errorCount = 0;
		for (Database.UpsertResult singleExcution : bulkExcution) {
			if (singleExcution.isSuccess()) {
				logDescription += singleExcution.getId() + '. ';
			}
			else {
				for (Database.Error err : singleExcution.getErrors()) {
					TouchCRBase__Log__c errorLog = new TouchCRBase__Log__c(
						TouchCRBase__Event_Type__c = 'Shopify Product Batch: '+objectName,
						TouchCRBase__Event_Status__c = 'Error',
						TouchCRBase__Event_Endpoint__c = 'NA',
						TouchCRBase__Event_Description__c = 'Error: '+ err.getMessage() +' with status code: '+err.getStatusCode()+'.'
					);
					errorLogs.add(errorLog);
					errorCount++;
				}
			}
		}

		if (errorLogs.size() > 0) {
			Boolean isCreateableLog = (
				TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable()&&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()&&
				TouchCRBase__Log__c.TouchCRBase__Event_Endpoint__c.getDescribe().isCreateable()&&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable()
			);
			if (isCreateableLog) {
				try {
					insert errorLogs;
				}
				catch(DmlException e) {}
			}
			else { throw new privilegesException('privileges Exception'); }
		}

		TouchCRBase__Log__c logRecord = new TouchCRBase__Log__c(
			TouchCRBase__Event_Type__c = 'Shopify Product Batch: ' + objectName,
			TouchCRBase__Event_Status__c = 'Success',
			TouchCRBase__Event_Endpoint__c = 'NA',
			TouchCRBase__Event_Description__c = 'we processed: ' + bulkExcution.size() + ' records of ' + objectName + ' and faulty records is: ' + errorCount + ' .\n Inserted Ids are:  ' + logDescription
		);

		Boolean isCreateableLog1 = (
			TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable()&&
			TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()&&
			TouchCRBase__Log__c.TouchCRBase__Event_Endpoint__c.getDescribe().isCreateable()&&
			TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable()
		);
		if (isCreateableLog1) {
			try{
				insert logRecord;
			}
			catch(DmlException e) {}
		}
		else { throw new privilegesException('privileges Exception'); }
	}

	public void notAccessible(String title, String description, String accountId){
		TouchCRBase__Log__c errorLog = new TouchCRBase__Log__c(
			TouchCRBase__Event_Type__c = title,
			TouchCRBase__Event_Status__c = 'Error',
			TouchCRBase__Event_Endpoint__c = 'NA',
			TouchCRBase__Event_Description__c = description,
			TouchCRBase__Account__c = accountId
		);
		Boolean isCreateableLog = (
			TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable()&&
			TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()&&
			TouchCRBase__Log__c.TouchCRBase__Event_Endpoint__c.getDescribe().isCreateable()&&
			TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable()&&
			TouchCRBase__Log__c.TouchCRBase__Account__c.getDescribe().isCreateable()
		);
		if (isCreateableLog) {
			insert errorLog;
		}
		else { throw new privilegesException('privileges Exception'); }
	}

	public with sharing class privilegesException extends Exception {}
}