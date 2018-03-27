@isTest
private class CreateStripeAccountControllerTest {
	static Account createTestData(Boolean isExistAccount) {
		List<RecordType> recTypes = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Franchisee_Account'];

		Account acc = new Account(
			LastName = 'Jarvis',
			FirstName = 'Aaron',
			PersonEmail = 'charmhaven@homeicecream.com.example',
			RecordTypeId = recTypes.get(0).Id,
			Stripe_Account_ID__c = (isExistAccount == true) ? 'someID' : null,
			Stripe_Account_Type__c = 'custom',
			Stripe_Application_Fee__c = null,
			Stripe_Country_Support__c = 'AU',
			Legal_Entity_Address_Line_1__c = 'Canal St.',
			Legal_Entity_Business_Name__c = 'Aaron JarvisUpdated',
			Legal_Entity_Business_Tax_ID__c = 'true',
			Legal_Entity_City__c = 'Sydney',
			Legal_Entity_Date_of_Birth_Day__c = '4',
			Legal_Entity_Date_of_Birth_Month__c = '10',
			Legal_Entity_Date_of_Birth_Year__c = '1994',
			Legal_Entity_First_Name__c = 'Test',
			Legal_Entity_Last_Name__c = 'Test',
			Legal_Entity_Postal_Code__c = '2263',
			Legal_Entity_State__c = 'New South Wales',
			Legal_Entity_Type__c = 'individual', 
			Terms_Of_Service_Acceptance_Date__c = Date.valueOf('2017-10-03'),
			Terms_Of_Service_Acceptance_IP__c = '93.84.39.145'
		);

		Map<String, String> newTouchCrSetting = new Map<String, String>();
		newTouchCrSetting.put('Name', 'Test Agent Name');
		newTouchCrSetting.put('Endpoint.ClientId', 'test');
		newTouchCrSetting.put('Endpoint.ClientSecret', 'true');
		TouchCRHelper.setSettings(newTouchCrSetting);

		Stripe_Connect__c newConnectSetting = new Stripe_Connect__c();
		newConnectSetting.Name = 'Test';
		newConnectSetting.Value__c = 'paymentagent';
		insert newConnectSetting;
		insert acc;
		return acc;
	}

	static testMethod void createStripeAccountTestSuccess(){
		Account acc = createTestData(false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock('createStripeAccount', false));
			String result = CreateStripeAccountController.createStripeAccount(acc.Id);
		Test.stopTest();

		Account acc_test = [
			SELECT Id, Stripe_Account_ID__c, Stripe_Account_Type__c, Stripe_Country_Support__c, Legal_Entity_Address_Line_1__c, Legal_Entity_Business_Name__c,
			Legal_Entity_Business_Tax_ID__c, Legal_Entity_City__c, Legal_Entity_First_Name__c, Legal_Entity_Last_Name__c, Legal_Entity_Postal_Code__c, Legal_Entity_State__c,
			Legal_Entity_Type__c, Terms_Of_Service_Acceptance_IP__c
			FROM Account
			WHERE Id = :acc.Id
		];
		System.assertEquals('acct_1BJM4lDGNuAF7VQI', acc_test.Stripe_Account_ID__c);
		System.assertEquals('custom', acc_test.Stripe_Account_Type__c);
		System.assertEquals('AU', acc_test.Stripe_Country_Support__c);
		System.assertEquals('Canal St.', acc_test.Legal_Entity_Address_Line_1__c);
		System.assertEquals('Aaron JarvisUpdated', acc_test.Legal_Entity_Business_Name__c);
		System.assertEquals('true', acc_test.Legal_Entity_Business_Tax_ID__c);
		System.assertEquals('Sydney', acc_test.Legal_Entity_City__c);
		System.assertEquals('Test', acc_test.Legal_Entity_First_Name__c);
		System.assertEquals('Test', acc_test.Legal_Entity_Last_Name__c);
		System.assertEquals('2263', acc_test.Legal_Entity_Postal_Code__c);
		System.assertEquals('New South Wales', acc_test.Legal_Entity_State__c);
		System.assertEquals('individual', acc_test.Legal_Entity_Type__c);
		System.assertEquals('93.84.39.145', acc_test.Terms_Of_Service_Acceptance_IP__c);

		Log__c log = [
			SELECT Id, Action__c, Description__c, Event_Status__c,
				Event_Type__c, Type__c
			FROM Log__c
			WHERE Account__c = :acc.Id
			LIMIT 1
		];
		System.assertEquals('Create Franchisee Account', log.Action__c);
		System.assertEquals('Franchisee Account has been created.', log.Description__c);
		System.assertEquals('OK', log.Event_Status__c);
		System.assertEquals('Request', log.Event_Type__c);
		System.assertEquals('INFO', log.Type__c);
	}

	static testMethod void createStripeAccountTestError(){
		Account acc = createTestData(false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock(400, 'Bad Request', 'error : { message : "Invalid parameters."}'));
			String result = CreateStripeAccountController.createStripeAccount(acc.Id);

		Test.stopTest();

		Account acc_test = [
			SELECT Id, Stripe_Account_ID__c
			FROM Account
			WHERE Id = :acc.Id
		];
		System.assertEquals(null, acc_test.Stripe_Account_ID__c);

		Log__c log = [
			SELECT Id, Action__c, Description__c, Event_Status__c,
				Event_Type__c, Type__c
			FROM Log__c
			WHERE Account__c = :acc.Id
			LIMIT 1
		];
		System.assertEquals('Create Franchisee Account', log.Action__c);
		System.assertEquals('Bad Request', log.Description__c);
		System.assertEquals('400', log.Event_Status__c);
		System.assertEquals('Request', log.Event_Type__c);
		System.assertEquals('ERROR', log.Type__c);
	}

	static testMethod void createStripeAccountTestErrorExistAcc(){
		Account acc = createTestData(true);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock(400, 'Bad Request', 'error : { message : "Invalid parameters."}'));
			String result = CreateStripeAccountController.createStripeAccount(acc.Id);
			System.assertEquals('Error! This Stripe Account has already been created.', result);

		Test.stopTest();
	}

	static testMethod void createStripeAccountTestException(){
		Account acc = createTestData(false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock(400, 'Exception', 'Unauthorized endpoint, please check Setup->Security->Remote site settings.'));
			String result = CreateStripeAccountController.createStripeAccount(acc.Id);

		Test.stopTest();

		Account acc_test = [
			SELECT Id, Stripe_Account_ID__c
			FROM Account
			WHERE Id = :acc.Id
		];
		System.assertEquals(null, acc_test.Stripe_Account_ID__c);

		Log__c log = [
			SELECT Id, Action__c, Description__c, Event_Status__c,
				Event_Type__c, Type__c
			FROM Log__c
			WHERE Account__c = :acc.Id
			LIMIT 1
		];
		System.assertEquals('Create Franchisee Account', log.Action__c);
		System.assertEquals('Request', log.Event_Type__c);
		System.assertEquals('ERROR', log.Type__c);
	}
}