@isTest
private class AmazonCustomersAppendsBatchTest {

	@isTest static void AmazonCustomerAppendsTest() {
		insert new Account(
			FirstName = 'John',
			LastName = 'Doe',
			PersonEmail = 'amz@marketplace1.io',
			TouchCRBase__DF_Append_Run__c = false,
			DF_Need_Append__c = true
		);

		TouchCRBase.TouchCRHelper.setSettings(new Map<String, String>{
			'Amazon.DataFinderKey' => 'test',
			'Amazon.ResolveEmail' => 'true',
			'Proxy.isEnabled' => 'false'
		});

		Test.startTest();
			AmazonCustomersAppendsBatch acab = new AmazonCustomersAppendsBatch();
			database.executebatch(acab, 1);
		Test.stopTest();

		System.assertEquals(1, [SELECT Id FROM TouchCRBase__Log__c].size());
		System.assertEquals(true, [SELECT TouchCRBase__DF_Append_Run__c FROM Account].TouchCRBase__DF_Append_Run__c);
	}

	@isTest static void AmazonCustomersAppendsTest() {
		insert new List<Account>{
			new Account(
				LastName = 'Doe1', PersonEmail = 'amz@marketplace1.io',
				TouchCRBase__DF_Append_Run__c = false, DF_Need_Append__c = true
			),
			new Account(
				LastName = 'Doe2', PersonEmail = 'amz@marketplace2.io',
				TouchCRBase__DF_Append_Run__c = false, DF_Need_Append__c = false
			)
		};

		TouchCRBase.TouchCRHelper.setSettings(new Map<String, String>{
			'Amazon.DataFinderKey' => 'test',
			'Amazon.ResolveEmail' => 'true',
			'Proxy.isEnabled' => 'false'
		});

		Test.startTest();
			AmazonCustomersAppendsBatch acab = new AmazonCustomersAppendsBatch();
			database.executebatch(acab, 1);
		Test.stopTest();

		System.assertEquals(1, [SELECT Id FROM TouchCRBase__Log__c].size());
		System.assertEquals(1, [SELECT Id FROM Account WHERE TouchCRBase__DF_Append_Run__c = TRUE].size());
	}
}