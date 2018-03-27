@isTest
private class CreateBankAccountControllerTest {
	static Payout_Bank_Account__c createTestData(Boolean isExistBankAccount) {
		Account acc = new Account(
			Name = 'Test User',
			Stripe_Account_ID__c = 'acct_1BJJlkGhCH1rGkTK'
		);
		insert acc;

		Map<String, String> newTouchCrSetting = new Map<String, String>();
		newTouchCrSetting.put('Name', 'Test Agent Name');
		newTouchCrSetting.put('Endpoint.ClientId', 'test');
		newTouchCrSetting.put('Endpoint.ClientSecret', 'true');
		TouchCRHelper.setSettings(newTouchCrSetting);

		Payout_Bank_Account__c bank_acc = new Payout_Bank_Account__c(
			Account__r = acc,
			Account_Holder_Name__c = 'Test',
			Account_Holder_Type__c = 'individual',
			Bank_Account_Number__c = '111111116',
			Bank_Country__c = 'AU',
			Bank_Currency__c = 'aud',
			BSB_Routing_Number__c = '110000',
			Bank_Account_Id__c = (isExistBankAccount == false) ? null : 'someID'
		);
		insert bank_acc;

		Stripe_Connect__c newConnectSetting = new Stripe_Connect__c();
		newConnectSetting.Name = 'Test';
		newConnectSetting.Value__c = 'paymentagent';
		insert newConnectSetting;

		return bank_acc;
	}

	static testMethod void createStripeBankAccountTestSuccess(){
		Payout_Bank_Account__c bank_acc = createTestData(false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock('createStripeBankAccount', false));
			String result = CreateBankAccountController.createStripeBankAccount(bank_acc.Id);
		Test.stopTest();

		Payout_Bank_Account__c bankAccTest = [SELECT Id, Bank_Account_Id__c, Bank_Name__c, Verification_Status__c, Account__r.Id FROM Payout_Bank_Account__c WHERE Id = :bank_acc.Id];
		System.assertEquals('ba_1BJNUJGhCH1rGkTK0WdXskxW', bankAccTest.Bank_Account_Id__c);
		System.assertEquals('STRIPE TEST BANK', bankAccTest.Bank_Name__c);
		System.assertEquals('new', bankAccTest.Verification_Status__c);

		Log__c log = [
			SELECT Id, Action__c, Description__c, Event_Status__c,
				Event_Type__c, Type__c
			FROM Log__c
			WHERE Account__c = :bankAccTest.Account__r.Id
			LIMIT 1
		];
		System.assertEquals('Create Bank Account', log.Action__c);
		System.assertEquals('Bank Account has been created.', log.Description__c);
		System.assertEquals('OK', log.Event_Status__c);
		System.assertEquals('Request', log.Event_Type__c);
		System.assertEquals('INFO', log.Type__c);
	}

	static testMethod void createStripeBankAccountTestError(){
		Payout_Bank_Account__c bank_acc = createTestData(false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock(400, 'Bad Request', 'error : { message : "Invalid parameters."}'));
			String result = CreateBankAccountController.createStripeBankAccount(bank_acc.Id);
		Test.stopTest();

		Payout_Bank_Account__c bankAccTest = [SELECT Id, Bank_Account_Id__c, Bank_Name__c, Verification_Status__c, Account__r.Id FROM Payout_Bank_Account__c WHERE Id = :bank_acc.Id];
		System.assertEquals(null, bankAccTest.Bank_Account_Id__c);
		System.assertEquals(null, bankAccTest.Bank_Name__c);

		Log__c log = [
			SELECT Id, Action__c, Description__c, Event_Status__c,
				Event_Type__c, Type__c
			FROM Log__c
			WHERE Account__c = :bankAccTest.Account__r.Id
			LIMIT 1
		];
		System.assertEquals('Create Bank Account', log.Action__c);
		System.assertEquals('Bad Request', log.Description__c);
		System.assertEquals('400', log.Event_Status__c);
		System.assertEquals('Request', log.Event_Type__c);
		System.assertEquals('ERROR', log.Type__c);
	}

	static testMethod void createStripeBankAccountTestErrorExistAcc(){
		Payout_Bank_Account__c bank_acc = createTestData(true);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock(400, 'Bad Request', 'error : { message : "Invalid parameters."}'));
			String result = CreateBankAccountController.createStripeBankAccount(bank_acc.Id);
		Test.stopTest();

		System.assertEquals('Error! This Bank Account has already been created. Please create new Payout Bank Account record.', result);
	}

	static testMethod void createStripeBankAccountTestException(){
		Payout_Bank_Account__c bank_acc = createTestData(false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock(400, 'Exception', 'Unauthorized endpoint, please check Setup->Security->Remote site settings.'));
			String result = CreateBankAccountController.createStripeBankAccount(bank_acc.Id);
		Test.stopTest();

		Payout_Bank_Account__c bankAccTest = [SELECT Id, Bank_Account_Id__c, Bank_Name__c, Verification_Status__c, Account__r.Id FROM Payout_Bank_Account__c WHERE Id = :bank_acc.Id];
		System.assertEquals(null, bankAccTest.Bank_Account_Id__c);
		System.assertEquals(null, bankAccTest.Bank_Name__c);

		Log__c log = [
			SELECT Id, Action__c, Description__c, Event_Status__c,
				Event_Type__c, Type__c
			FROM Log__c
			WHERE Account__c = :bankAccTest.Account__r.Id
			LIMIT 1
		];
		System.assertEquals('Create Bank Account', log.Action__c);
		System.assertEquals('Request', log.Event_Type__c);
		System.assertEquals('ERROR', log.Type__c);
	}
}