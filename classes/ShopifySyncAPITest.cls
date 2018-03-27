@isTest
private class ShopifySyncAPITest {

	@isTest static void sync_readynot() {

		// not ready, active connection missing
		System.assertEquals(false, ShopifyProcessingHelper.isReadyToStart());

		Test.startTest();
			Database.executeBatch(new ShopifySyncAPIClient());
		Test.stopTest();

		List<TouchCRBase__Log__c> testObj = [SELECT Id FROM TouchCRBase__Log__c];

		System.assertEquals(1, testObj.size());
	}

	@isTest static void sync_ready() {

		// not ready, active connection missing
		System.assertEquals(false, ShopifyProcessingHelper.isReadyToStart());

		TouchCRBase__TouchCRConnection__c testConnection = new TouchCRBase__TouchCRConnection__c(
			Name = 'test',
			TouchCRBase__Brand__c = 'testBrand',
			TouchCRBase__Feature__c = 'Shopify',
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

		// ready
		System.assertEquals(true, ShopifyProcessingHelper.isReadyToStart());

		Test.startTest();
			ShopifySyncAPIClient sc = new ShopifySyncAPIClient();
			String sch = Datetime.now().addMinutes(1).format('s m H d M ? yyyy');
			System.schedule('ShopifySyncAPIClient', sch, sc);
		Test.stopTest();

		List<CronTrigger> crn = [SELECT Id
			FROM CronTrigger
			WHERE CronJobDetail.Name = 'ShopifySyncAPIClient'
		];

		List<AsyncApexJob> aaj = [SELECT Id
			FROM AsyncApexJob
			WHERE ApexClass.Name IN ('ShopifySyncAPIClient')
			AND JobType = 'BatchApex'
			AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
		];

		System.assertEquals(1, crn.size());
		System.assertEquals(1, aaj.size());
	}

}