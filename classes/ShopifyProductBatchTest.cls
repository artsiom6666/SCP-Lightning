@isTest
private class ShopifyProductBatchTest {

	@isTest static void test_product0() {

		String product1v1i1 = '{"products":[]}';
		Test.setMock(HttpCalloutMock.class, new ShopifyCalloutMock(product1v1i1));

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
		ShopifyProductBatch testBatch = new ShopifyProductBatch();

		Test.startTest();
			Database.executeBatch(testBatch);
		Test.stopTest();

		List<Product2> testObj = [SELECT Id, Name FROM Product2];
		System.assertEquals(0, testObj.size());
	}

	@isTest static void test_product1_exist() {

		String product1v1i1 = '{"products":[{"id":9664375876,"title":"Default","variants":[{"id":33198349892,"product_id":9664375876,"title":"Default","price":"14.99","sku":"811578024509"}],"images":[{"id":22637660676,"product_id":9664375876,"position":1,"created_at":"2017-01-09T12:48:14-06:00","updated_at":"2017-01-31T16:02:16-06:00","src":"https://cdn.shopify.com/s/files/1/1672/5373/products/EAE_product_image.png?v=1485900136","variant_ids":[]}]}]}';
		Test.setMock(HttpCalloutMock.class, new ShopifyCalloutMock(product1v1i1));

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

		//exisiting product, variant, image

		Product2 productObj = new Product2();
		productObj.Name = 'default';
		productObj.TouchCRBase__Connected_Id__c = 'test__9664375876';
		productObj.TouchCRBase__Connection_Name__c = 'test';
		insert productObj;

		TouchCRBase__Product_Variant__c varObj = new TouchCRBase__Product_Variant__c();
		varObj.Name = 'red';
		varObj.TouchCRBase__Product__c = productObj.Id;
		varObj.TouchCRBase__External_Id__c = 'test__33198349892';
		insert varObj;

		TouchCRBase__Product_Image__c imgObj = new TouchCRBase__Product_Image__c();
		imgObj.Name = 'default';
		imgObj.TouchCRBase__Product_Image_External_Id__c = 'test__22637660676';
		imgObj.TouchCRBase__Integration_Name__c = 'test';
		imgObj.TouchCRBase__Image_URL__c = 'https://img.dot.com';
		insert imgObj;


		TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.PrevConnectionId' => testConnection.Id});
		ShopifyProductBatch testBatch = new ShopifyProductBatch();

		Test.startTest();
			Database.executeBatch(testBatch);
		Test.stopTest();

		List<Product2> testObj = [SELECT Id, Name FROM Product2];
		System.assertEquals(1, testObj.size());
	}

	@isTest static void test_1product_5variants_5images_1pvimage() {

		String product1v1i1 = '{"products":[{"id":8573749585,"title":"Blush","body_html":"<p>Blush</p>","vendor":"Cate McNabb Cosmetics","product_type":"Blush","created_at":"2017-02-06T10:19:27-06:00","handle":"blush","updated_at":"2017-02-10T09:29:14-06:00","published_at":"2017-02-08T10:00:00-06:00","template_suffix":"","published_scope":"global","tags":"Blush, FACE, new line, SHOP","variants":[{"id":29396305809,"product_id":8573749585,"title":"Beach Bum","price":"19.00","sku":"811578022758","position":1,"grams":0,"inventory_policy":"deny","compare_at_price":null,"fulfillment_service":"manual","inventory_management":"shopify","option1":"Beach Bum","option2":null,"option3":null,"created_at":"2017-02-06T10:22:55-06:00","updated_at":"2017-02-10T09:29:14-06:00","taxable":true,"barcode":"","image_id":18620689809,"inventory_quantity":4,"weight":0,"weight_unit":"lb","old_inventory_quantity":4,"requires_shipping":true},{"id":29396349841,"product_id":8573749585,"title":"Sunrise Glow","price":"19.00","sku":"811578022727","position":2,"grams":0,"inventory_policy":"deny","compare_at_price":null,"fulfillment_service":"manual","inventory_management":"shopify","option1":"Sunrise Glow","option2":null,"option3":null,"created_at":"2017-02-06T10:25:09-06:00","updated_at":"2017-02-06T10:35:30-06:00","taxable":true,"barcode":"","image_id":18620695377,"inventory_quantity":34,"weight":0,"weight_unit":"lb","old_inventory_quantity":34,"requires_shipping":true},{"id":29396350097,"product_id":8573749585,"title":"Peach Coral","price":"19.00","sku":"811578022734","position":3,"grams":0,"inventory_policy":"deny","compare_at_price":null,"fulfillment_service":"manual","inventory_management":"shopify","option1":"Peach Coral","option2":null,"option3":null,"created_at":"2017-02-06T10:25:09-06:00","updated_at":"2017-02-06T10:35:30-06:00","taxable":true,"barcode":"","image_id":18620705233,"inventory_quantity":75,"weight":0,"weight_unit":"lb","old_inventory_quantity":75,"requires_shipping":true},{"id":29396350161,"product_id":8573749585,"title":"Mink","price":"19.00","sku":"811578022789","position":4,"grams":0,"inventory_policy":"deny","compare_at_price":null,"fulfillment_service":"manual","inventory_management":"shopify","option1":"Mink","option2":null,"option3":null,"created_at":"2017-02-06T10:25:09-06:00","updated_at":"2017-02-06T10:35:30-06:00","taxable":true,"barcode":"","image_id":18620708625,"inventory_quantity":96,"weight":0,"weight_unit":"lb","old_inventory_quantity":96,"requires_shipping":true},{"id":29396350033,"product_id":8573749585,"title":"Naked Peach","price":"19.00","sku":"811578022710","position":5,"grams":0,"inventory_policy":"deny","compare_at_price":null,"fulfillment_service":"manual","inventory_management":"shopify","option1":"Naked Peach","option2":null,"option3":null,"created_at":"2017-02-06T10:25:09-06:00","updated_at":"2017-02-06T10:35:30-06:00","taxable":true,"barcode":"","image_id":18620813009,"inventory_quantity":91,"weight":0,"weight_unit":"lb","old_inventory_quantity":91,"requires_shipping":true}],"options":[{"id":10304751761,"product_id":8573749585,"name":"Color","position":1,"values":["Beach Bum","Sunrise Glow","Peach Coral","Mink","Naked Peach"]}],"images":[{"id":18620689809,"product_id":8573749585,"position":1,"created_at":"2017-02-06T10:25:45-06:00","updated_at":"2017-02-06T10:34:49-06:00","src":"https://cdn.shopify.com/s/files/1/0942/9930/products/Blush_Closed_BeachBum_9b33a989-8d50-4a2d-a2c7-7742e79d288b.jpg?v=1486398889","variant_ids":[29396305809]},{"id":18620695377,"product_id":8573749585,"position":2,"created_at":"2017-02-06T10:26:23-06:00","updated_at":"2017-02-06T10:34:49-06:00","src":"https://cdn.shopify.com/s/files/1/0942/9930/products/Blush_Closed_SunriseGlow_9de76db6-c097-4bc9-b2e2-d4230a8af241.jpg?v=1486398889","variant_ids":[29396349841]},{"id":18620705233,"product_id":8573749585,"position":3,"created_at":"2017-02-06T10:27:24-06:00","updated_at":"2017-02-06T10:34:49-06:00","src":"https://cdn.shopify.com/s/files/1/0942/9930/products/Blush_Closed_PeachCoral_6aa773a1-b998-4034-9222-56e61b23070a.jpg?v=1486398889","variant_ids":[29396350097]},{"id":18620708625,"product_id":8573749585,"position":4,"created_at":"2017-02-06T10:27:49-06:00","updated_at":"2017-02-06T10:34:49-06:00","src":"https://cdn.shopify.com/s/files/1/0942/9930/products/Blush_Closed_Mink_c0401f98-08b3-433d-aea7-6fd49908b595.jpg?v=1486398889","variant_ids":[29396350161]},{"id":18620813009,"product_id":8573749585,"position":5,"created_at":"2017-02-06T10:35:15-06:00","updated_at":"2017-02-06T10:35:15-06:00","src":"https://cdn.shopify.com/s/files/1/0942/9930/products/Blush_Closed_NakedPeach_04b60296-76f9-4008-82a8-c898e76fed54.jpg?v=1486398915","variant_ids":[29396350033]}],"image":{"id":18620689809,"product_id":8573749585,"position":1,"created_at":"2017-02-06T10:25:45-06:00","updated_at":"2017-02-06T10:34:49-06:00","src":"https://cdn.shopify.com/s/files/1/0942/9930/products/Blush_Closed_BeachBum_9b33a989-8d50-4a2d-a2c7-7742e79d288b.jpg?v=1486398889","variant_ids":[29396305809]}}]}';
		Test.setMock(HttpCalloutMock.class, new ShopifyCalloutMock(product1v1i1));

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

		// existing stuff
		/*Product2 productObj = new Product2();
		productObj.Name = 'default';
		productObj.TouchCRBase__Connected_Id__c = 'test__9664375876';
		productObj.TouchCRBase__Connection_Name__c = 'test';
		insert productObj;

		TouchCRBase__Product_Variant__c varObj = new TouchCRBase__Product_Variant__c();
		varObj.Name = 'red';
		varObj.TouchCRBase__Product__c = productObj.Id;
		varObj.TouchCRBase__External_Id__c = 'test__33198349892';
		insert varObj;

		TouchCRBase__Product_Image__c imgObj = new TouchCRBase__Product_Image__c();
		imgObj.Name = 'default';
		imgObj.TouchCRBase__Product_Image_External_Id__c = 'test__22637660676';
		imgObj.TouchCRBase__Integration_Name__c = 'test';
		imgObj.TouchCRBase__Image_URL__c = 'https://img.dot.com';
		insert imgObj;*/
		// existing stuff


		TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.PrevConnectionId' => testConnection.Id});
		ShopifyProductBatch testBatch = new ShopifyProductBatch();

		Test.startTest();
			Database.executeBatch(testBatch);
		Test.stopTest();

		List<Product2> testObj = [SELECT Id, Name FROM Product2];
		System.assertEquals(1, testObj.size());
		System.assertEquals('Blush', testObj[0].Name);

		List<TouchCRBase__Product_Variant__c> testVar = [SELECT Id, Name FROM TouchCRBase__Product_Variant__c];
		System.assertEquals(5, testVar.size());

		List<TouchCRBase__Product_Image__c> testIm = [SELECT Id, Name FROM TouchCRBase__Product_Image__c];
		System.assertEquals(10, testIm.size());
	}

	@isTest static void test_productdto() {
		ProductDto dto = new ProductDto();
		dto.description = 'test';
		dto.id = 'test';
		dto.sku = 'test';
		dto.status = 'test';
		dto.title = 'test';
		
		ProductDto.Image image = new ProductDto.Image();
		image.alt = 'test';
		image.id = 'test';
		image.product_id = 'test';
		image.src = 'test';
		image.title = 'test';
		dto.images = new List<ProductDto.Image>{image};

		ProductDto.Variations var = new ProductDto.Variations();
		var.id = 'test';
		var.image_id = 'test';
		var.product_id = 'test';
		var.sku = 'test';
		var.title = 'test';
		dto.variations = new List<ProductDto.Variations> {var};

		System.assertNotEquals(null, dto);
	}

}