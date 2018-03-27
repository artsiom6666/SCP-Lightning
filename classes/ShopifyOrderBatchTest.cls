@isTest
private class ShopifyOrderBatchTest {

	@isTest static void test_order1() {

		String order1li2 = '{"orders":[{"id":3707624199,"email":"Alex@ymail.com","closed_at":null,"created_at":"2016-07-11T10:30:25+05:30","updated_at":"2016-07-11T10:30:25+05:30","number":1,"note":"","token":"6d628c5cd8e4895502432810c9b88314","gateway":"manual","test":false,"total_price":"21.00","subtotal_price":"21.00","total_weight":12000,"total_tax":"0.00","taxes_included":false,"currency":"INR","financial_status":"paid","confirmed":true,"total_discounts":"0.00","total_line_items_price":"21.00","cart_token":null,"buyer_accepts_marketing":false,"name":"#1001","referring_site":null,"landing_site":"/collections/shop?utm_source=marketingcloud&utm_medium=email&utm_term=button&utm_content=email1&utm_campaign=winback&opt=true","cancelled_at":null,"cancel_reason":null,"total_price_usd":"0.31","checkout_token":null,"reference":null,"user_id":90181831,"location_id":null,"source_identifier":null,"source_url":null,"processed_at":"2016-07-11T10:30:25+05:30","device_id":null,"browser_ip":null,"landing_site_ref":null,"order_number":1001,"discount_codes":[],"note_attributes":[],"payment_gateway_names":["manual"],"processing_method":"manual","checkout_id":null,"source_name":"shopify_draft_order","fulfillment_status":null,"tax_lines":[],"tags":"","contact_email":"Alex@gmail.com","order_status_url":null,"line_items":[{"id":7024711239,"variant_id":24607926151,"title":"BLUSH","quantity":1,"price":"21.00","grams":12000,"sku":"#cream-124","variant_title":"red","vendor":"testingstoredx","fulfillment_service":"manual","product_id":7765570759,"requires_shipping":true,"taxable":true,"gift_card":false,"name":"BLUSH - red","variant_inventory_management":null,"properties":[],"product_exists":true,"fulfillable_quantity":1,"total_discount":"0.00","fulfillment_status":null,"tax_lines":[]}],"shipping_lines":[],"billing_address":{"first_name":"Alex","address1":"STREET -1","phone":"9876543120","city":"deago","zip":"14741","province":"UK","country":"Guernsey","last_name":"Doren","address2":"#boran","company":"DXTESTING.LMT","latitude":null,"longitude":null,"name":"Alex Doren","country_code":"US","province_code":null},"shipping_address":{"first_name":"Alex","address1":"STREET -1","phone":"9876543120","city":"deago","zip":"14741","province":"UK","country":"Guernsey","last_name":"Doren","address2":"#boran","company":"DXTESTING.LMT","latitude":null,"longitude":null,"name":"Alex Doren","country_code":"US","province_code":"IL"},"fulfillments":[],"refunds":[],"customer":{"id":3963550535,"email":"Alex@gmail.com","accepts_marketing":false,"created_at":"2016-07-11T10:27:16+05:30","updated_at":"2016-07-11T10:30:25+05:30","first_name":"Alex","last_name":"Doren","orders_count":1,"state":"disabled","total_spent":"21.00","last_order_id":3707619911,"note":"","verified_email":true,"multipass_identifier":null,"tax_exempt":false,"tags":"","last_order_name":"#1001","default_address":{"id":4236831879,"first_name":"Alex","last_name":"Doren","company":"DXTESTING.LMT","address1":"STREET -1","address2":"#boran","city":"deago","province":"UK","country":"Guernsey","zip":"14741","phone":"9876543120","name":"Alex Doren","province_code":null,"country_code":"US","default":true}}}]}';
		Test.setMock(HttpCalloutMock.class, new ShopifyCalloutMock(order1li2));

		TouchCRBase__TouchCRConnection__c testConnection = new TouchCRBase__TouchCRConnection__c(
				Name = 'test',
				TouchCRBase__Brand__c = 'testBrand',
				TouchCRBase__Feature__c = ShopifyProcessingHelper.SHOPIFY_FEATURENAME,
				TouchCRBase__isActive__c = true
		);
		insert testConnection;

		List<TouchCRBase__TouchCRConnectionSetting__c> testSettings = new List<TouchCRBase__TouchCRConnectionSetting__c>();
		for (String aSetting : ShopifyProcessingHelper.REQUIRED_SETTINGS) {
			TouchCRBase__TouchCRConnectionSetting__c testSetting = new TouchCRBase__TouchCRConnectionSetting__c(
					Name = aSetting,
					TouchCRBase__Value__c = 'test',
					TouchCRBase__TouchCRConnection__c = testConnection.Id
			);
			testSettings.add(testSetting);
		}
		insert testSettings;

		TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.PrevConnectionId' => testConnection.Id});
		ShopifyOrderBatch testBatch = new ShopifyOrderBatch();

		Test.startTest();
		Database.executeBatch(testBatch);
		Test.stopTest();

		List<TouchCRBase__Order__c> testObj = [SELECT Id, Name FROM TouchCRBase__Order__c];
		System.assertEquals(1, testObj.size());

		String scpProp = TouchCRHelper.isSCPEnabled() == TRUE ? ', BillingCountryCode, BillingStateCode, ShippingCountryCode, ShippingStateCode' : '';
		
		String queryString = 'SELECT Id, PersonEmail, TouchCRBase__sales_funnel_name__c,' +
				'TouchCRBase__utm_campaign__c, TouchCRBase__utm_content__c, TouchCRBase__utm_medium__c, TouchCRBase__utm_source__c,' + 
				'TouchCRBase__utm_term__c' +
				scpProp +
				' FROM Account';

		List<Account> newAccs = Database.query(queryString);
		

		System.assertEquals(1, newAccs.size());
		//utm_source=marketingcloud&utm_medium=email&utm_term=button&utm_content=email1&utm_campaign=winback&opt=true
		System.assertEquals('marketingcloud', newAccs[0].TouchCRBase__utm_source__c);
		System.assertEquals('email', newAccs[0].TouchCRBase__utm_medium__c);
		System.assertEquals('button', newAccs[0].TouchCRBase__utm_term__c);
		System.assertEquals('email1', newAccs[0].TouchCRBase__utm_content__c);
		System.assertEquals('winback', newAccs[0].TouchCRBase__utm_campaign__c);

		if (TouchCRHelper.isSCPEnabled() == TRUE) { 
			System.assertEquals('US', newAccs[0].get('BillingCountryCode'));
			System.assertEquals(null, newAccs[0].get('BillingStateCode'));
			System.assertEquals('US', newAccs[0].get('ShippingCountryCode'));
			System.assertEquals('IL', newAccs[0].get('ShippingStateCode'));
		}
	}

	@isTest static void test_order0() {

		String order1li2 = '{"orders":[]}';
		Test.setMock(HttpCalloutMock.class, new ShopifyCalloutMock(order1li2));

		TouchCRBase__TouchCRConnection__c testConnection = new TouchCRBase__TouchCRConnection__c(
				Name = 'test',
				TouchCRBase__Brand__c = 'testBrand',
				TouchCRBase__Feature__c = ShopifyProcessingHelper.SHOPIFY_FEATURENAME,
				TouchCRBase__isActive__c = true
		);
		insert testConnection;

		List<TouchCRBase__TouchCRConnectionSetting__c> testSettings = new List<TouchCRBase__TouchCRConnectionSetting__c>();
		for (String aSetting : ShopifyProcessingHelper.REQUIRED_SETTINGS) {
			TouchCRBase__TouchCRConnectionSetting__c testSetting = new TouchCRBase__TouchCRConnectionSetting__c(
					Name = aSetting,
					TouchCRBase__Value__c = 'test',
					TouchCRBase__TouchCRConnection__c = testConnection.Id
			);
			testSettings.add(testSetting);
		}
		insert testSettings;

		TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.PrevConnectionId' => testConnection.Id});
		ShopifyOrderBatch testBatch = new ShopifyOrderBatch();

		Test.startTest();
		Database.executeBatch(testBatch);
		Test.stopTest();

		List<TouchCRBase__Order__c> testObj = [SELECT Id, Name FROM TouchCRBase__Order__c];
		System.assertEquals(0, testObj.size());
	}

	@isTest static void test_order_disabled() {

		String order1li2 = '{"orders":[{"id":3707624199,"email":"SHELLI@GMAIL.COM","closed_at":null,"created_at":"2016-07-11T10:31:51+05:30","updated_at":"2016-07-11T10:32:02+05:30","number":2,"note":"","token":"95074e5be031487a68ec38a56f023ca3","gateway":"manual","test":false,"total_price":"41.00","subtotal_price":"41.00","total_weight":24000,"total_tax":"0.00","taxes_included":false,"currency":"INR","financial_status":"paid","confirmed":true,"total_discounts":"0.00","total_line_items_price":"41.00","cart_token":null,"buyer_accepts_marketing":false,"name":"#1002","referring_site":null,"landing_site":null,"cancelled_at":null,"cancel_reason":null,"total_price_usd":"0.61","checkout_token":null,"reference":null,"user_id":90181831,"location_id":null,"source_identifier":null,"source_url":null,"processed_at":"2016-07-11T10:31:51+05:30","device_id":null,"browser_ip":null,"landing_site_ref":null,"order_number":1002,"discount_codes":[],"note_attributes":[],"payment_gateway_names":["manual"],"processing_method":"manual","checkout_id":null,"source_name":"shopify_draft_order","fulfillment_status":null,"tax_lines":[],"tags":"","contact_email":"SHELLI@GMAIL.COM","order_status_url":null,"line_items":[{"id":7024718343,"variant_id":24607791431,"title":"CREAM FOUNDATION","quantity":1,"price":"20.00","grams":12000,"sku":"#cream-123","variant_title":"blue","vendor":"testingstoredx","fulfillment_service":"manual","product_id":7765547463,"requires_shipping":true,"taxable":true,"gift_card":false,"name":"CREAM FOUNDATION - blue","variant_inventory_management":null,"properties":[],"product_exists":true,"fulfillable_quantity":1,"total_discount":"0.00","fulfillment_status":null,"tax_lines":[]},{"id":7024718407,"variant_id":24607791495,"title":"CREAM FOUNDATION","quantity":1,"price":"21.00","grams":12000,"sku":"#cream-124","variant_title":"red","vendor":"testingstoredx","fulfillment_service":"manual","product_id":7765547463,"requires_shipping":true,"taxable":true,"gift_card":false,"name":"CREAM FOUNDATION - red","variant_inventory_management":null,"properties":[],"product_exists":true,"fulfillable_quantity":1,"total_discount":"0.00","fulfillment_status":null,"tax_lines":[]}],"shipping_lines":[],"billing_address":{"first_name":"Shelli","address1":"street-2","phone":"987654321","city":"lebiya","zip":"147415","state":"us","country":"Hong Kong","address2":"moran","company":"DX.LMT","latitude":22.396428,"longitude":114.109497,"name":"Shelli Loren","country_code":"HK","state_code":null},"shipping_address":{"first_name":"Shelli","address1":"street-2","phone":"987654321","city":"lebiya","zip":"147415","state":"us","country":"Hong Kong","last_name":"Loren","address2":"moran","company":"DX.LMT","latitude":22.396428,"longitude":114.109497,"name":"Shelli Loren","country_code":"HK","state_code":null},"fulfillments":[],"refunds":[],"customer":{"id":3963557767,"email":"SHELLI@GMAIL.COM","accepts_marketing":false,"created_at":"2016-07-11T10:29:31+05:30","updated_at":"2016-07-11T10:32:02+05:30","first_name":"Shelli","last_name":"","orders_count":1,"state":"disabled","total_spent":"41.00","last_order_id":3707624199,"note":"","verified_email":true,"multipass_identifier":null,"tax_exempt":false,"tags":"","last_order_name":"#1002","billing_address":{"id":4236838535,"first_name":"Shelli","last_name":"Loren","company":"DX.LMT","address1":"street-2","address2":"moran","city":"lebiya","state":"us","country":"Hong Kong","zip":"147415","phone":"987654321","name":"Shelli Loren","state_code":null,"country_code":"HK","country_name":"Hong Kong","default":true},"shipping_address":{"id":4236838535,"first_name":"Shelli","last_name":"Loren","company":"DX.LMT","address1":"street-2","address2":"moran","city":"lebiya","state":"us","country":"Hong Kong","zip":"147415","phone":"987654321","name":"Shelli Loren","state_code":null,"country_code":"HK","country_name":"Hong Kong","default":true}}},{"id":3707619911,"email":"Alex@gmail.com","closed_at":null,"created_at":"2016-07-11T10:30:25+05:30","updated_at":"2016-07-11T10:30:25+05:30","number":1,"note":"","token":"6d628c5cd8e4895502432810c9b88314","gateway":"manual","test":false,"total_price":"21.00","subtotal_price":"21.00","total_weight":12000,"total_tax":"0.00","taxes_included":false,"currency":"INR","financial_status":"paid","confirmed":true,"total_discounts":"0.00","total_line_items_price":"21.00","cart_token":null,"buyer_accepts_marketing":false,"name":"#1001","referring_site":null,"landing_site":"/","cancelled_at":null,"cancel_reason":null,"total_price_usd":"0.31","checkout_token":null,"reference":null,"user_id":90181831,"location_id":null,"source_identifier":null,"source_url":null,"processed_at":"2016-07-11T10:30:25+05:30","device_id":null,"browser_ip":null,"landing_site_ref":null,"order_number":1001,"discount_codes":[],"note_attributes":[],"payment_gateway_names":["manual"],"processing_method":"manual","checkout_id":null,"source_name":"shopify_draft_order","fulfillment_status":null,"tax_lines":[],"tags":"","contact_email":"Alex@gmail.com","order_status_url":null,"line_items":[{"id":7024711239,"variant_id":24607926151,"title":"BLUSH","quantity":1,"price":"21.00","grams":12000,"sku":"#cream-124","variant_title":"red","vendor":"testingstoredx","fulfillment_service":"manual","product_id":7765570759,"requires_shipping":true,"taxable":true,"gift_card":false,"name":"BLUSH - red","variant_inventory_management":null,"properties":[],"product_exists":true,"fulfillable_quantity":1,"total_discount":"0.00","fulfillment_status":null,"tax_lines":[]}],"shipping_lines":[],"billing_address":{"first_name":"Alex","address1":"STREET -1","phone":"9876543120","city":"deago","zip":"14741","state":"UK","country":"Guernsey","last_name":"Doren","address2":"#boran","company":"DXTESTING.LMT","latitude":null,"longitude":null,"name":"Alex Doren","country_code":"GG","state_code":null},"shipping_address":{"first_name":"Alex","address1":"STREET -1","phone":"9876543120","city":"deago","zip":"14741","state":"UK","country":"Guernsey","last_name":"Doren","address2":"#boran","company":"DXTESTING.LMT","latitude":null,"longitude":null,"name":"Alex Doren","country_code":"GG","state_code":null},"fulfillments":[],"refunds":[],"customer":{"id":3963550535,"email":"Alex@gmail.com","accepts_marketing":false,"created_at":"2016-07-11T10:27:16+05:30","updated_at":"2016-07-11T10:30:25+05:30","first_name":"Alex","last_name":"Doren","orders_count":1,"state":"disabled","total_spent":"21.00","last_order_id":3707619911,"note":"","verified_email":true,"multipass_identifier":null,"tax_exempt":false,"tags":"","last_order_name":"#1001","billing_address":{"id":4236831879,"first_name":"Alex","last_name":"Doren","company":"DXTESTING.LMT","address1":"STREET -1","address2":"#boran","city":"deago","state":"UK","country":"Guernsey","zip":"14741","phone":"9876543120","name":"Alex Doren","state_code":null,"country_code":"GG","country_name":"Guernsey","default":true},"shipping_address":{"id":4236838535,"first_name":"Shelli","last_name":"Loren","company":"DX.LMT","address1":"street-2","address2":"moran","city":"lebiya","state":"us","country":"Hong Kong","zip":"147415","phone":"987654321","name":"Shelli Loren","state_code":null,"country_code":"HK","country_name":"Hong Kong","default":true}}}]}';
		Test.setMock(HttpCalloutMock.class, new ShopifyCalloutMock(order1li2));

		Product2 disabledProducts = new Product2(
				TouchCRBase__Connected_Id__c = 'test__7765570759', IsActive = true, Name = 'test'
		);
		insert disabledProducts;

		Account account = new Account(FirstName = 'Alex',
				LastName = 'Doren',
				PersonEmail ='Alex@gmail.com'
		);

		TouchCRBase__TouchCRConnection__c testConnection = new TouchCRBase__TouchCRConnection__c(
				Name = 'test',
				TouchCRBase__Brand__c = 'testBrand',
				TouchCRBase__Feature__c = ShopifyProcessingHelper.SHOPIFY_FEATURENAME,
				TouchCRBase__isActive__c = true
		);
		insert testConnection;

		List<TouchCRBase__TouchCRConnectionSetting__c> testSettings = new List<TouchCRBase__TouchCRConnectionSetting__c>();
		for (String aSetting : ShopifyProcessingHelper.REQUIRED_SETTINGS) {
			TouchCRBase__TouchCRConnectionSetting__c testSetting = new TouchCRBase__TouchCRConnectionSetting__c(
					Name = aSetting,
					TouchCRBase__Value__c = 'test',
					TouchCRBase__TouchCRConnection__c = testConnection.Id
			);
			testSettings.add(testSetting);
		}
		insert testSettings;

		TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.PrevConnectionId' => testConnection.Id});
		ShopifyOrderBatch testBatch = new ShopifyOrderBatch();

		Test.startTest();
		Database.executeBatch(testBatch);
		Test.stopTest();

		List<TouchCRBase__Order__c> testObj = [SELECT Id, Name FROM TouchCRBase__Order__c];
		System.assertEquals(2, testObj.size());
	}

	@isTest static void test_order_exist() {

		String order1li2 = '{"orders":[{"id":3707624199,"email":"SHELLI@GMAIL.COM","closed_at":null,"created_at":"2016-07-11T10:31:51+05:30","updated_at":"2016-07-11T10:32:02+05:30","number":2,"note":"","token":"95074e5be031487a68ec38a56f023ca3","gateway":"manual","test":false,"total_price":"41.00","subtotal_price":"41.00","total_weight":24000,"total_tax":"0.00","taxes_included":false,"currency":"INR","financial_status":"paid","confirmed":true,"total_discounts":"0.00","total_line_items_price":"41.00","cart_token":null,"buyer_accepts_marketing":false,"name":"#1002","referring_site":null,"landing_site":null,"cancelled_at":null,"cancel_reason":null,"total_price_usd":"0.61","checkout_token":null,"reference":null,"user_id":90181831,"location_id":null,"source_identifier":null,"source_url":null,"processed_at":"2016-07-11T10:31:51+05:30","device_id":null,"browser_ip":null,"landing_site_ref":null,"order_number":1002,"discount_codes":[],"note_attributes":[],"payment_gateway_names":["manual"],"processing_method":"manual","checkout_id":null,"source_name":"shopify_draft_order","fulfillment_status":null,"tax_lines":[],"tags":"","contact_email":"SHELLI@GMAIL.COM","order_status_url":null,"line_items":[{"id":7024718343,"variant_id":24607791431,"title":"CREAM FOUNDATION","quantity":1,"price":"20.00","grams":12000,"sku":"#cream-123","variant_title":"blue","vendor":"testingstoredx","fulfillment_service":"manual","product_id":7765547463,"requires_shipping":true,"taxable":true,"gift_card":false,"name":"CREAM FOUNDATION - blue","variant_inventory_management":null,"properties":[],"product_exists":true,"fulfillable_quantity":1,"total_discount":"0.00","fulfillment_status":null,"tax_lines":[]},{"id":7024718407,"variant_id":24607791495,"title":"CREAM FOUNDATION","quantity":1,"price":"21.00","grams":12000,"sku":"#cream-124","variant_title":"red","vendor":"testingstoredx","fulfillment_service":"manual","product_id":7765547463,"requires_shipping":true,"taxable":true,"gift_card":false,"name":"CREAM FOUNDATION - red","variant_inventory_management":null,"properties":[],"product_exists":true,"fulfillable_quantity":1,"total_discount":"0.00","fulfillment_status":null,"tax_lines":[]}],"shipping_lines":[],"billing_address":{"first_name":"Shelli","address1":"street-2","phone":"987654321","city":"lebiya","zip":"147415","state":"us","country":"Hong Kong","address2":"moran","company":"DX.LMT","latitude":22.396428,"longitude":114.109497,"name":"Shelli Loren","country_code":"HK","state_code":null},"shipping_address":{"first_name":"Shelli","address1":"street-2","phone":"987654321","city":"lebiya","zip":"147415","state":"us","country":"Hong Kong","last_name":"Loren","address2":"moran","company":"DX.LMT","latitude":22.396428,"longitude":114.109497,"name":"Shelli Loren","country_code":"HK","state_code":null},"fulfillments":[],"refunds":[],"customer":{"id":3963557767,"email":"SHELLI@GMAIL.COM","accepts_marketing":false,"created_at":"2016-07-11T10:29:31+05:30","updated_at":"2016-07-11T10:32:02+05:30","first_name":"Shelli","last_name":"","orders_count":1,"state":"disabled","total_spent":"41.00","last_order_id":3707624199,"note":"","verified_email":true,"multipass_identifier":null,"tax_exempt":false,"tags":"","last_order_name":"#1002","billing_address":{"id":4236838535,"first_name":"Shelli","last_name":"Loren","company":"DX.LMT","address1":"street-2","address2":"moran","city":"lebiya","state":"us","country":"Hong Kong","zip":"147415","phone":"987654321","name":"Shelli Loren","state_code":null,"country_code":"HK","country_name":"Hong Kong","default":true},"shipping_address":{"id":4236838535,"first_name":"Shelli","last_name":"Loren","company":"DX.LMT","address1":"street-2","address2":"moran","city":"lebiya","state":"us","country":"Hong Kong","zip":"147415","phone":"987654321","name":"Shelli Loren","state_code":null,"country_code":"HK","country_name":"Hong Kong","default":true}}},{"id":3707619911,"email":"Alex@gmail.com","closed_at":null,"created_at":"2016-07-11T10:30:25+05:30","updated_at":"2016-07-11T10:30:25+05:30","number":1,"note":"","token":"6d628c5cd8e4895502432810c9b88314","gateway":"manual","test":false,"total_price":"21.00","subtotal_price":"21.00","total_weight":12000,"total_tax":"0.00","taxes_included":false,"currency":"INR","financial_status":"paid","confirmed":true,"total_discounts":"0.00","total_line_items_price":"21.00","cart_token":null,"buyer_accepts_marketing":false,"name":"#1001","referring_site":null,"landing_site":"/","cancelled_at":null,"cancel_reason":null,"total_price_usd":"0.31","checkout_token":null,"reference":null,"user_id":90181831,"location_id":null,"source_identifier":null,"source_url":null,"processed_at":"2016-07-11T10:30:25+05:30","device_id":null,"browser_ip":null,"landing_site_ref":null,"order_number":1001,"discount_codes":[],"note_attributes":[],"payment_gateway_names":["manual"],"processing_method":"manual","checkout_id":null,"source_name":"shopify_draft_order","fulfillment_status":null,"tax_lines":[],"tags":"","contact_email":"Alex@gmail.com","order_status_url":null,"line_items":[{"id":7024711239,"variant_id":24607926151,"title":"BLUSH","quantity":1,"price":"21.00","grams":12000,"sku":"#cream-124","variant_title":"red","vendor":"testingstoredx","fulfillment_service":"manual","product_id":7765570759,"requires_shipping":true,"taxable":true,"gift_card":false,"name":"BLUSH - red","variant_inventory_management":null,"properties":[],"product_exists":true,"fulfillable_quantity":1,"total_discount":"0.00","fulfillment_status":null,"tax_lines":[]}],"shipping_lines":[],"billing_address":{"first_name":"Alex","address1":"STREET -1","phone":"9876543120","city":"deago","zip":"14741","state":"UK","country":"Guernsey","last_name":"Doren","address2":"#boran","company":"DXTESTING.LMT","latitude":null,"longitude":null,"name":"Alex Doren","country_code":"GG","state_code":null},"shipping_address":{"first_name":"Alex","address1":"STREET -1","phone":"9876543120","city":"deago","zip":"14741","state":"UK","country":"Guernsey","last_name":"Doren","address2":"#boran","company":"DXTESTING.LMT","latitude":null,"longitude":null,"name":"Alex Doren","country_code":"GG","state_code":null},"fulfillments":[],"refunds":[],"customer":{"id":3963550535,"email":"Alex@gmail.com","accepts_marketing":false,"created_at":"2016-07-11T10:27:16+05:30","updated_at":"2016-07-11T10:30:25+05:30","first_name":"Alex","last_name":"Doren","orders_count":1,"state":"disabled","total_spent":"21.00","last_order_id":3707619911,"note":"","verified_email":true,"multipass_identifier":null,"tax_exempt":false,"tags":"","last_order_name":"#1001","billing_address":{"id":4236831879,"first_name":"Alex","last_name":"Doren","company":"DXTESTING.LMT","address1":"STREET -1","address2":"#boran","city":"deago","state":"UK","country":"Guernsey","zip":"14741","phone":"9876543120","name":"Alex Doren","state_code":null,"country_code":"GG","country_name":"Guernsey","default":true},"shipping_address":{"id":4236838535,"first_name":"Shelli","last_name":"Loren","company":"DX.LMT","address1":"street-2","address2":"moran","city":"lebiya","state":"us","country":"Hong Kong","zip":"147415","phone":"987654321","name":"Shelli Loren","state_code":null,"country_code":"HK","country_name":"Hong Kong","default":true}}}]}';
		Test.setMock(HttpCalloutMock.class, new ShopifyCalloutMock(order1li2));

		Product2 disabledProducts = new Product2(
				TouchCRBase__Connected_Id__c = 'test__7765570759', IsActive = true, Name = 'test'
		);
		insert disabledProducts;

		Account testAcc = new Account(FirstName = 'Alex',
				LastName = 'Doren',
				PersonEmail = 'Alex@gmail.com'
		);
		insert testAcc;

		TouchCRBase__Order__c testOrd = new TouchCRBase__Order__c(
				TouchCRBase__Billing_Email__c = 'Alex@gmail.com',
				TouchCRBase__Connected_Id__c = 'test__3707624199',
				TouchCRBase__Account__c = testAcc.Id
		);
		insert testOrd;

		TouchCRBase__TouchCRConnection__c testConnection = new TouchCRBase__TouchCRConnection__c(
				Name = 'test',
				TouchCRBase__Brand__c = 'testBrand',
				TouchCRBase__Feature__c = ShopifyProcessingHelper.SHOPIFY_FEATURENAME,
				TouchCRBase__isActive__c = true
		);
		insert testConnection;

		List<TouchCRBase__TouchCRConnectionSetting__c> testSettings = new List<TouchCRBase__TouchCRConnectionSetting__c>();
		for (String aSetting : ShopifyProcessingHelper.REQUIRED_SETTINGS) {
			TouchCRBase__TouchCRConnectionSetting__c testSetting = new TouchCRBase__TouchCRConnectionSetting__c(
					Name = aSetting,
					TouchCRBase__Value__c = 'test',
					TouchCRBase__TouchCRConnection__c = testConnection.Id
			);
			testSettings.add(testSetting);
		}
		insert testSettings;

		TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.PrevConnectionId' => testConnection.Id});
		ShopifyOrderBatch testBatch = new ShopifyOrderBatch();

		Test.startTest();
		Database.executeBatch(testBatch);
		Test.stopTest();

		List<TouchCRBase__Order__c> testObj = [SELECT Id, Name FROM TouchCRBase__Order__c];
		System.assertEquals(2, testObj.size());
	}

	@isTest static void test_order1_pr_pv_relatation() {

		String order1li2 = '{"orders":[{"id":4814146436,"email":"smehta@mcnabbus.com","closed_at":"2017-02-13T11:30:27-06:00","created_at":"2017-02-07T12:29:41-06:00","updated_at":"2017-02-13T11:30:28-06:00","number":27,"note":null,"token":"cac83f1725c61ae8a3d466622c09f802","gateway":"firstdata_e4","test":false,"total_price":"9.35","subtotal_price":"3.99","total_weight":0,"total_tax":"0.41","taxes_included":false,"currency":"USD","financial_status":"refunded","confirmed":true,"total_discounts":"0.00","total_line_items_price":"3.99","cart_token":"f53699ac7c49a878703d1ae50e23cd0b","buyer_accepts_marketing":true,"name":"#1027","referring_site":"","landing_site":"/","cancelled_at":null,"cancel_reason":null,"total_price_usd":"9.35","checkout_token":"539906eba8e34e314607c20623819db7","reference":null,"user_id":null,"location_id":null,"source_identifier":null,"source_url":null,"processed_at":"2017-02-07T12:29:41-06:00","device_id":null,"browser_ip":"12.24.242.146","landing_site_ref":null,"order_number":1027,"discount_codes":[],"note_attributes":[],"payment_gateway_names":["firstdata_e4"],"processing_method":"direct","checkout_id":14533128324,"source_name":"web","fulfillment_status":null,"tax_lines":[{"title":"IL State Tax","price":"0.25","rate":0.0625},{"title":"Cook County Tax","price":"0.11","rate":0.0275},{"title":"Chicago Municipal Tax","price":"0.05","rate":0.0125}],"tags":"","contact_email":"smehta@mcnabbus.com","order_status_url":"https://checkout.shopify.com/16725373/checkouts/539906eba8e34e314607c20623819db7/thank_you_token?key=b1f1a4eaf69bc62bc2fb24bb528055d8","line_items":[{"id":9371904452,"variant_id":33198285060,"title":"SPF 30 Sunscreen Lip Balm","quantity":1,"price":"3.99","grams":0,"sku":"811578023601","variant_title":"","vendor":"Sunology","fulfillment_service":"manual","product_id":9664371844,"requires_shipping":true,"taxable":true,"gift_card":false,"name":"SPF 30 Sunscreen Lip Balm","variant_inventory_management":null,"properties":[],"product_exists":true,"fulfillable_quantity":1,"total_discount":"0.00","fulfillment_status":null,"tax_lines":[{"title":"IL State Tax","price":"0.25","rate":0.0625},{"title":"Cook County Tax","price":"0.11","rate":0.0275},{"title":"Chicago Municipal Tax","price":"0.05","rate":0.0125}],"origin_location":{"id":2719073668,"country_code":"US","province_code":"IL","name":"Sunology Mineral Sunscreen","address1":"1621 W. Walnut St. ","address2":"Suite 100","city":"Chicago","zip":"60612"},"destination_location":{"id":2794007236,"country_code":"US","province_code":"IL","name":"suzanne TEST","address1":"1543 west diversey parkway","address2":"1","city":"chicago","zip":"60614"}}],"shipping_lines":[{"id":3933038596,"title":"Flat Rate","price":"4.95","code":"Flat Rate","source":"shopify","phone":null,"requested_fulfillment_service_id":null,"delivery_category":null,"carrier_identifier":null,"tax_lines":[]}],"billing_address":{"first_name":"suzanne","address1":"1543 west diversey parkway","phone":"(917) 443-5090","city":"chicago","zip":"60614","province":"Illinois","country":"United States","last_name":"TEST","address2":"1","company":"","latitude":41.9322164,"longitude":-87.6676514,"name":"suzanne TEST","country_code":"US","province_code":"IL"},"shipping_address":{"first_name":"suzanne","address1":"1543 west diversey parkway","phone":"(917) 443-5090","city":"chicago","zip":"60614","province":"Illinois","country":"United States","last_name":"TEST","address2":"1","company":"","latitude":41.9322164,"longitude":-87.6676514,"name":"suzanne TEST","country_code":"US","province_code":"IL"},"fulfillments":[],"client_details":{"browser_ip":"12.24.242.146","accept_language":"en-us","user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/602.3.12 (KHTML, like Gecko) Version/10.0.2 Safari/602.3.12","session_hash":"a092ac587504bb0c2e5ff65a246e2ad3","browser_width":1250,"browser_height":671},"refunds":[{"id":195916420,"order_id":4814146436,"created_at":"2017-02-07T12:37:22-06:00","note":"test","restock":null,"user_id":111476356,"processed_at":"2017-02-07T12:37:22-06:00","refund_line_items":[],"transactions":[{"id":5313347588,"order_id":4814146436,"amount":"9.35","kind":"refund","gateway":"firstdata_e4","status":"success","message":"Transaction Normal - Accepted by E-xact","created_at":"2017-02-07T12:37:22-06:00","test":false,"authorization":"RETURN;1775932827;935","currency":"USD","location_id":null,"user_id":null,"parent_id":5313329796,"device_id":null,"receipt":{"exact_id":"C98085-01","password":"","transaction_type":"34","dollar_amount":"9.35","surcharge_amount":"","transaction_tag":"1775932827","track1":"","track2":"","pan":"","authorization_num":"RETURN","card_holders_name":"suzanne mehta","verification_str1":"","cvd_presence_ind":"0","zip_code":"","tax1_amount":"","tax1_number":"","tax2_amount":"","tax2_number":"","secure_auth_required":"","secure_auth_result":"","ecommerce_flag":"","xid":"","cavv":"","cavv_algorithm":"","reference_no":"c14533128324.1","customer_ref":"smehta@mcnabbus.com","reference_3":"","language":"","client_ip":"","client_email":"","user_name":"","transaction_error":"false","transaction_approved":"true","exact_resp_code":"00","exact_message":"Transaction Normal - Accepted by E-xact","bank_resp_code":"100","bank_message":"Accepted by E-xact","bank_resp_code_2":"","sequence_no":"0511735","avs":"","cvv2":"","retrieval_ref_no":"170207","cavv_response":"","currency":"USD","amount_requested":"0.0","partial_redemption":"false","merchant_name":"SUNOLOGY","merchant_address":"1621 W WALNUT ST","merchant_city":"CHICAGO","merchant_province":"Illinois","merchant_country":"United States","merchant_postal":"60612","merchant_url":"WWW.SUNOLOGY.COM","transarmor_token":"","card_type":"American Express","current_balance":"","previous_balance":"","ean":"","card_cost":"","virtual_card":"false","ctr":"========== TRANSACTION RECORD ==========\nSUNOLOGY\n1621 W WALNUT ST\nCHICAGO, IL 60612\nUnited States\nWWW.SUNOLOGY.COM\n\nTYPE: Refund\n\nACCT: American Express        $ 9.35 USD\n              ($ 9.35 USD was requested)\n\nCARDHOLDER NAME : suzanne mehta\nCARD NUMBER     : ###########4000\nDATE/TIME       : 07 Feb 17 12:37:22\nREFERENCE #     : 001 0511735 M\nAUTHOR. #       : RETURN\nTRANS. REF.     : c14533128324.1\n\n    Approved - Thank You 100\n\n\nPlease retain this copy for your records.\n========================================"},"error_code":null,"source_name":"web"}],"order_adjustments":[{"id":157899844,"order_id":4814146436,"refund_id":195916420,"amount":"-9.35","tax_amount":"0.00","kind":"refund_discrepancy","reason":"Refund discrepancy"}]}],"payment_details":{"credit_card_bin":"377246","avs_result_code":"2","cvv_result_code":null,"credit_card_number":"•••• •••• •••• 4000","credit_card_company":"American Express"},"customer":{"id":5292138180,"email":"smehta@mcnabbus.com","accepts_marketing":true,"created_at":"2017-02-07T12:25:12-06:00","updated_at":"2017-02-07T12:37:23-06:00","first_name":"suzanne","last_name":"TEST","orders_count":4,"state":"disabled","total_spent":"0.00","last_order_id":4814146436,"note":null,"verified_email":true,"multipass_identifier":null,"tax_exempt":false,"phone":null,"tags":"","last_order_name":"#1027","default_address":{"id":5522063108,"first_name":"suzanne","last_name":"TEST","company":"","address1":"1543 west diversey parkway","address2":"1","city":"chicago","province":"Illinois","country":"United States","zip":"60614","phone":"(917) 443-5090","name":"suzanne TEST","province_code":"IL","country_code":"US","country_name":"United States","default":true}}}]}';
		Test.setMock(HttpCalloutMock.class, new ShopifyCalloutMock(order1li2));

		Product2 testProduct = new Product2(
				TouchCRBase__Connected_Id__c = 'test__9664371844', IsActive = true, Name = 'test'
		);
		insert testProduct;

		TouchCRBase__Product_Variant__c testPv = new TouchCRBase__Product_Variant__c(
				TouchCRBase__Product__c = testProduct.Id,
				TouchCRBase__External_Id__c = 'test__33198285060',
				TouchCRBase__External_Product_Id__c = 'test__9664371844',
				TouchCRBase__Integration_Name__c = 'test',
				Name = 'testPv'
		);
		insert testPv;

		Account testAcc = new Account(FirstName = 'smehta',
				LastName = 'mcnabbus',
				PersonEmail = 'smehta@mcnabbus.com'
		);
		insert testAcc;

		TouchCRBase__TouchCRConnection__c testConnection = new TouchCRBase__TouchCRConnection__c(
				Name = 'test',
				TouchCRBase__Brand__c = 'testBrand',
				TouchCRBase__Feature__c = ShopifyProcessingHelper.SHOPIFY_FEATURENAME,
				TouchCRBase__isActive__c = true
		);
		insert testConnection;

		List<TouchCRBase__TouchCRConnectionSetting__c> testSettings = new List<TouchCRBase__TouchCRConnectionSetting__c>();
		for (String aSetting : ShopifyProcessingHelper.REQUIRED_SETTINGS) {
			TouchCRBase__TouchCRConnectionSetting__c testSetting = new TouchCRBase__TouchCRConnectionSetting__c(
					Name = aSetting,
					TouchCRBase__Value__c = 'test',
					TouchCRBase__TouchCRConnection__c = testConnection.Id
			);
			testSettings.add(testSetting);
		}
		insert testSettings;

		TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.PrevConnectionId' => testConnection.Id});
		ShopifyOrderBatch testBatch = new ShopifyOrderBatch();

		Test.startTest();
		Database.executeBatch(testBatch);
		Test.stopTest();

		List<TouchCRBase__Order__c> testObjs1 = [SELECT Id, Name, (SELECT Id FROM TouchCRBase__Order_Items__r) FROM TouchCRBase__Order__c];
		System.assertEquals(1, testObjs1.size());

		List<TouchCRBase__OrderItem__c> testObjs2 = [
				SELECT Id, TouchCRBase__Connected_Id__c, TouchCRBase__Connection_Name__c,
						TouchCRBase__Order__c, TouchCRBase__Product__c, TouchCRBase__Product_Variant__c,
						TouchCRBase__Quantity__c, TouchCRBase__Total_Price__c
				FROM TouchCRBase__OrderItem__c
		];
		System.assertEquals(1, testObjs2.size());
		System.assertEquals(testObjs1[0].Id, testObjs2[0].TouchCRBase__Order__c);
		System.assertEquals(1, testObjs2[0].TouchCRBase__Quantity__c);
		System.assertEquals(3.99, testObjs2[0].TouchCRBase__Total_Price__c);

		System.assertEquals(testProduct.Id, testObjs2[0].TouchCRBase__Product__c);
		System.assertEquals(testPv.Id, testObjs2[0].TouchCRBase__Product_Variant__c);
	}

	@isTest static void test_order1_2li_prandpvidisnull() {

		String order1li2 = '{"orders":[{"id":1603524548,"email":"fullwell@comcast.net","closed_at":"2015-10-14T11:59:40-05:00","created_at":"2015-10-13T17:22:39-05:00","updated_at":"2015-10-30T11:30:32-05:00","number":698,"note":"Original data:\n  email: fullwell@comcast.net\n\n  billing address:\n    first name: Marla\n    last name: Filipponi\n    address1: 38 Vineyard Dr.\n    phone: 4156860835\n    city: San Rafael\n    province: CA\n    country: US\n    zip: 94901\n\n  shipping address:\n    first name: Marla\n    last name: Filipponi\n    address1: 38 Vineyard Dr.\n    phone: \n    city: San Rafael\n    province: CA\n    country: US\n    zip: 94901\n","token":"0fe987f0cf3d58950a6057eaa85bd3f9","gateway":"","test":false,"total_price":"32.00","subtotal_price":"32.00","total_weight":0,"total_tax":"0.00","taxes_included":false,"currency":"USD","financial_status":"authorized","confirmed":true,"total_discounts":"0.00","total_line_items_price":"32.00","cart_token":null,"buyer_accepts_marketing":true,"name":"#1698","referring_site":null,"landing_site":null,"cancelled_at":null,"cancel_reason":null,"total_price_usd":"32.00","checkout_token":null,"reference":null,"user_id":null,"location_id":null,"source_identifier":null,"source_url":null,"processed_at":"2015-06-04T19:18:45-05:00","device_id":null,"browser_ip":null,"landing_site_ref":null,"order_number":1698,"discount_codes":[],"note_attributes":[],"payment_gateway_names":[""],"processing_method":"","checkout_id":null,"source_name":"1182999","fulfillment_status":"fulfilled","tax_lines":[],"tags":"","contact_email":"fullwell@comcast.net","order_status_url":null,"line_items":[{"id":2905643396,"variant_id":null,"title":"lip-lacquer","quantity":1,"price":"16.00","grams":0,"sku":"549","variant_title":null,"vendor":null,"fulfillment_service":"manual","product_id":null,"requires_shipping":true,"taxable":false,"gift_card":false,"name":"lip-lacquer","variant_inventory_management":null,"properties":[],"product_exists":false,"fulfillable_quantity":0,"total_discount":"0.00","fulfillment_status":"fulfilled","tax_lines":[{"title":"Tax","price":"0.00","rate":0}]},{"id":2905643460,"variant_id":null,"title":"lipstick","quantity":1,"price":"16.00","grams":0,"sku":"475","variant_title":null,"vendor":null,"fulfillment_service":"manual","product_id":null,"requires_shipping":true,"taxable":false,"gift_card":false,"name":"lipstick","variant_inventory_management":null,"properties":[],"product_exists":false,"fulfillable_quantity":0,"total_discount":"0.00","fulfillment_status":"fulfilled","tax_lines":[{"title":"Tax","price":"0.00","rate":0}]}],"shipping_lines":[{"id":1528088708,"title":"Shipping","price":"0.00","code":"Shipping","source":"shopify","phone":null,"requested_fulfillment_service_id":null,"delivery_category":null,"carrier_identifier":null,"tax_lines":[]}],"billing_address":{"first_name":"Marla","address1":"38 Vineyard Dr.","phone":"4156860835","city":"San Rafael","zip":"94901","province":"California","country":"United States","last_name":"Filipponi","address2":null,"company":null,"latitude":37.9850431,"longitude":-122.5279683,"name":"Marla Filipponi","country_code":"US","province_code":"CA"},"shipping_address":{"first_name":"Marla","address1":"38 Vineyard Dr.","phone":"1234567890","city":"San Rafael","zip":"94901","province":"California","country":"United States","last_name":"Filipponi","address2":null,"company":null,"latitude":37.9850431,"longitude":-122.5279683,"name":"Marla Filipponi","country_code":"US","province_code":"CA"},"fulfillments":[{"id":1385544068,"order_id":1603524548,"status":"success","created_at":"2015-10-13T17:22:39-05:00","service":"manual","updated_at":"2015-10-13T17:22:39-05:00","tracking_company":null,"shipment_status":null,"tracking_number":null,"tracking_numbers":[],"tracking_url":null,"tracking_urls":[],"receipt":{},"line_items":[{"id":2905643396,"variant_id":null,"title":"lip-lacquer","quantity":1,"price":"16.00","grams":0,"sku":"549","variant_title":null,"vendor":null,"fulfillment_service":"manual","product_id":null,"requires_shipping":true,"taxable":false,"gift_card":false,"name":"lip-lacquer","variant_inventory_management":null,"properties":[],"product_exists":false,"fulfillable_quantity":0,"total_discount":"0.00","fulfillment_status":"fulfilled","tax_lines":[{"title":"Tax","price":"0.00","rate":0}]},{"id":2905643460,"variant_id":null,"title":"lipstick","quantity":1,"price":"16.00","grams":0,"sku":"475","variant_title":null,"vendor":null,"fulfillment_service":"manual","product_id":null,"requires_shipping":true,"taxable":false,"gift_card":false,"name":"lipstick","variant_inventory_management":null,"properties":[],"product_exists":false,"fulfillable_quantity":0,"total_discount":"0.00","fulfillment_status":"fulfilled","tax_lines":[{"title":"Tax","price":"0.00","rate":0}]}]}],"refunds":[],"customer":{"id":1592999748,"email":"fullwell@comcast.net","accepts_marketing":true,"created_at":"2015-10-07T16:37:44-05:00","updated_at":"2017-01-12T17:36:44-06:00","first_name":"Marla","last_name":"Filipponi","orders_count":5,"state":"enabled","total_spent":"174.00","last_order_id":4669578577,"note":null,"verified_email":true,"multipass_identifier":null,"tax_exempt":false,"phone":null,"tags":"","last_order_name":"#2936","default_address":{"id":5223185681,"first_name":"Marla","last_name":"Filipponi","company":"","address1":"38 Vineyard Dr.","address2":"","city":"San Rafael","province":"California","country":"United States","zip":"94901","phone":"(415) 453-9037","name":"Marla Filipponi","province_code":"CA","country_code":"US","country_name":"United States","default":true}}}]}';
		Test.setMock(HttpCalloutMock.class, new ShopifyCalloutMock(order1li2));

		Product2 testProduct = new Product2(
				TouchCRBase__Connected_Id__c = 'test__9664371844', IsActive = true, Name = 'test'
		);
		insert testProduct;

		TouchCRBase__Product_Variant__c testPv = new TouchCRBase__Product_Variant__c(
				TouchCRBase__Product__c = testProduct.Id,
				TouchCRBase__External_Id__c = 'test__33198285060',
				TouchCRBase__External_Product_Id__c = 'test__9664371844',
				TouchCRBase__Integration_Name__c = 'test',
				Name = 'testPv'
		);
		insert testPv;

		Account testAcc = new Account(FirstName = 'fullwell',
				LastName = 'comcast',
				PersonEmail = 'fullwell@comcast.net'
		);
		insert testAcc;

		TouchCRBase__TouchCRConnection__c testConnection = new TouchCRBase__TouchCRConnection__c(
				Name = 'test',
				TouchCRBase__Brand__c = 'testBrand',
				TouchCRBase__Feature__c = ShopifyProcessingHelper.SHOPIFY_FEATURENAME,
				TouchCRBase__isActive__c = true
		);
		insert testConnection;

		List<TouchCRBase__TouchCRConnectionSetting__c> testSettings = new List<TouchCRBase__TouchCRConnectionSetting__c>();
		for (String aSetting : ShopifyProcessingHelper.REQUIRED_SETTINGS) {
			TouchCRBase__TouchCRConnectionSetting__c testSetting = new TouchCRBase__TouchCRConnectionSetting__c(
					Name = aSetting,
					TouchCRBase__Value__c = 'test',
					TouchCRBase__TouchCRConnection__c = testConnection.Id
			);
			testSettings.add(testSetting);
		}
		insert testSettings;

		TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.PrevConnectionId' => testConnection.Id});
		ShopifyOrderBatch testBatch = new ShopifyOrderBatch();

		Test.startTest();
		Database.executeBatch(testBatch);
		Test.stopTest();

		List<TouchCRBase__Order__c> testObjs1 = [SELECT Id, Name, (SELECT Id FROM TouchCRBase__Order_Items__r) FROM TouchCRBase__Order__c];
		System.assertEquals(1, testObjs1.size());

		List<TouchCRBase__OrderItem__c> testObjs2 = [
				SELECT Id, TouchCRBase__Connected_Id__c, TouchCRBase__Connection_Name__c,
						TouchCRBase__Order__c, TouchCRBase__Product__c, TouchCRBase__Product_Variant__c,
						TouchCRBase__Quantity__c, TouchCRBase__Total_Price__c
				FROM TouchCRBase__OrderItem__c
		];

		String corruptedProductPrefix = testConnection.Name + ShopifyOrderBatch.EXTID_JOINER + ShopifyOrderBatch.CORRUPTED_PRODUCTD_ID;
		String connectionName = testConnection.Name;

		Product2 corruptedProduct = new Product2();
		Map<String, String> corruptedPVExternalIdToSfIdMap = new Map<String, String>();

		List<Product2> corruptedProducts = [SELECT Id, Name, TouchCRBase__Connected_Id__c, TouchCRBase__Connection_Name__c,
		(SELECT Id, TouchCRBase__External_Id__c, TouchCRBase__Integration_Name__c, TouchCRBase__External_Product_Id__c
		FROM TouchCRBase__Product_Variants__r)
		FROM Product2
		WHERE TouchCRBase__Connected_Id__c = : corruptedProductPrefix
		AND TouchCRBase__Connection_Name__c = : connectionName
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

		for (TouchCRBase__Product_Variant__c corVariant : corruptedProduct.TouchCRBase__Product_Variants__r) {
			corruptedPVExternalIdToSfIdMap.put(corVariant.TouchCRBase__External_Id__c, corVariant.Id);
		}

		System.assertEquals(1, corruptedProducts.size());
		System.assertEquals(corruptedProductPrefix, corruptedProducts[0].TouchCRBase__Connected_Id__c);
		System.assertEquals(connectionName, corruptedProducts[0].TouchCRBase__Connection_Name__c);


		System.assertEquals(2, testObjs2.size());
		System.assertEquals(testObjs1[0].Id, testObjs2[0].TouchCRBase__Order__c);
		System.assertEquals(testObjs1[0].Id, testObjs2[1].TouchCRBase__Order__c);

		System.assertEquals(1, testObjs2[0].TouchCRBase__Quantity__c);
		System.assertEquals(16.00, testObjs2[0].TouchCRBase__Total_Price__c);

		// it should be corrupted product id and variants
		// TODO
		System.assertEquals(corruptedProducts[0].Id, testObjs2[0].TouchCRBase__Product__c);
		System.assertNotEquals(null, testObjs2[0].TouchCRBase__Product_Variant__c);
	}

	@isTest static void test_orderdto() {
		OrderDto dto = new OrderDto();
	}
}