@isTest
private class ShopifySchedulerTest {

	@isTest static void sync_start_1sttime() {

		// not ready, active connection missing
		System.assertEquals(false, ShopifyProcessingHelper.isReadyToStart());

		// Connection #1
		TouchCRBase__TouchCRConnection__c testConnection1 = new TouchCRBase__TouchCRConnection__c(
			Name = 'test',
			TouchCRBase__Brand__c = 'testBrand',
			TouchCRBase__Feature__c = 'Shopify',
			TouchCRBase__isActive__c = true
		);
		insert testConnection1;

		List<TouchCRBase__TouchCRConnectionSetting__c> testSettings1 = new List<TouchCRBase__TouchCRConnectionSetting__c>();

		for (String aSetting : ShopifyProcessingHelper.REQUIRED_SETTINGS) {
			TouchCRBase__TouchCRConnectionSetting__c testSetting = new TouchCRBase__TouchCRConnectionSetting__c(
				Name = aSetting,
				TouchCRBase__Value__c = 'test',
				TouchCRBase__TouchCRConnection__c = testConnection1.Id
			);
			testSettings1.add(testSetting);
		}
		insert testSettings1;

		ShopifyProcessingHelper.cleanConnectionSettings();
		ShopifyProcessingHelper.loadSettingsForConnection(testConnection1.Id);
		ShopifyProcessingHelper.saveSettingsForConnection(testConnection1.Id);

		// settings this, means its not first connection processing
		//TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.PrevConnectionId' => testConnection1.Id});

		// ready
		System.assertEquals(true, ShopifyProcessingHelper.isReadyToStart());

		Test.startTest();
			for (String shopifySchName : ShopifyProcessingHelper.SHOPIFY_SCHEDULERS) {
				System.scheduleBatch(new ShopifyScheduler(), shopifySchName, 1);
			}
		Test.stopTest();

		List<CronTrigger> crn = [SELECT Id
			FROM CronTrigger
			WHERE CronJobDetail.Name IN : ShopifyProcessingHelper.SHOPIFY_SCHEDULERS
		];

		List<AsyncApexJob> aaj = [SELECT Id
			FROM AsyncApexJob
			WHERE ApexClass.Name IN : ShopifyProcessingHelper.SHOPIFY_SCHEDULERS
			AND JobType = 'BatchApex'
			AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
		];

		System.assertEquals(1, crn.size());
		System.assertEquals(1, aaj.size());
	}

	@isTest static void sync_start_2ndtime() {

		// not ready, active connection missing
		System.assertEquals(false, ShopifyProcessingHelper.isReadyToStart());

		// Connection #1
		TouchCRBase__TouchCRConnection__c testConnection1 = new TouchCRBase__TouchCRConnection__c(
			Name = 'test',
			TouchCRBase__Brand__c = 'testBrand',
			TouchCRBase__Feature__c = 'Shopify',
			TouchCRBase__isActive__c = true
		);
		insert testConnection1;

		List<TouchCRBase__TouchCRConnectionSetting__c> testSettings1 = new List<TouchCRBase__TouchCRConnectionSetting__c>();

		for (String aSetting : ShopifyProcessingHelper.REQUIRED_SETTINGS) {
			TouchCRBase__TouchCRConnectionSetting__c testSetting = new TouchCRBase__TouchCRConnectionSetting__c(
				Name = aSetting,
				TouchCRBase__Value__c = 'test',
				TouchCRBase__TouchCRConnection__c = testConnection1.Id
			);
			testSettings1.add(testSetting);
		}
		insert testSettings1;

		ShopifyProcessingHelper.cleanConnectionSettings();
		ShopifyProcessingHelper.loadSettingsForConnection(testConnection1.Id);
		ShopifyProcessingHelper.saveSettingsForConnection(testConnection1.Id);

		TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.PrevConnectionId' => testConnection1.Id});

		// ready
		System.assertEquals(true, ShopifyProcessingHelper.isReadyToStart());

		Test.startTest();
			for (String shopifySchName : ShopifyProcessingHelper.SHOPIFY_SCHEDULERS) {
				System.scheduleBatch(new ShopifyScheduler(), shopifySchName, 1);
			}
		Test.stopTest();

		List<CronTrigger> crn = [SELECT Id
			FROM CronTrigger
			WHERE CronJobDetail.Name IN : ShopifyProcessingHelper.SHOPIFY_SCHEDULERS
		];

		List<AsyncApexJob> aaj = [SELECT Id
			FROM AsyncApexJob
			WHERE ApexClass.Name IN : ShopifyProcessingHelper.SHOPIFY_SCHEDULERS
			AND JobType = 'BatchApex'
			AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
		];

		System.assertEquals(1, crn.size());
		System.assertEquals(1, aaj.size());
	}
}