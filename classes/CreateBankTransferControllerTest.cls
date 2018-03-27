@isTest
private class CreateBankTransferControllerTest {
	static Bank_Transfer__c createTestData(Boolean isTransferExist, Boolean isNoAccount) {
		List<RecordType> recTypes = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Franchisee_Account'];

		Account acc = new Account(
				LastName = 'Jarvis',
				FirstName = 'Aaron',
				PersonEmail = 'charmhaven@homeicecream.com.example',
				RecordTypeId = recTypes.get(0).Id,
				Stripe_Account_ID__c = 'acct_1BJJlkGhCH1rGkTK',
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
		insert acc;

		Payout_Bank_Account__c bank_acc = new Payout_Bank_Account__c(
			Account__c = acc.Id,
			Account_Holder_Name__c = 'Test',
			Account_Holder_Type__c = 'individual',
			Bank_Account_Number__c = '111111116',
			Bank_Country__c = 'AU',
			Bank_Currency__c = 'aud',
			Bank_Name__c = 'TEST BANK',
			BSB_Routing_Number__c = '110000',
			Verification_Status__c = 'new',
			Bank_Account_Id__c = 'ba_1BGyQdF70uPagwLlDIstBlAT');
		insert bank_acc;

		Bank_Transfer__c bt = new Bank_Transfer__c(
			Name = 'Test',
			Account__c = (isNoAccount == false) ? acc.Id : null,
			Payout_Bank_Account__c = bank_acc.Id,
			Transfer_Id__c	= (isTransferExist == false) ? null : 'someID',
			Transfer_Amount__c = 1
		);
		insert bt;

		Map<String, String> newTouchCrSetting = new Map<String, String>();
		newTouchCrSetting.put('Name', 'Test Agent Name');
		newTouchCrSetting.put('Endpoint.ClientId', 'test');
		newTouchCrSetting.put('Endpoint.ClientSecret', 'true');
		TouchCRHelper.setSettings(newTouchCrSetting);

		Stripe_Connect__c newConnectSetting = new Stripe_Connect__c();
		newConnectSetting.Name = 'Test';
		newConnectSetting.Value__c = 'paymentagent';
		insert newConnectSetting;

		return bt;
	}

	static testMethod void getBalanceSuccess() {
		Bank_Transfer__c bt = createTestData(false, false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock('getBalance', false));
			String result = CreateBankTransferController.getBalance(bt.Id, true);
		Test.stopTest();

		Account acc = [SELECT Id, Name, Available_Balance__c, Pending_Balance__c FROM Account WHERE Id = :bt.Account__c];
		System.assertEquals(5.90, acc.Available_Balance__c);
		System.assertEquals(26.47, acc.Pending_Balance__c);

	}

	static testMethod void getBalanceError() {
		Bank_Transfer__c bt = createTestData(true, false);

		Test.startTest();
		Test.SetMock(HttpCallOutMock.class, new StripeConnectMock('getBalance', false));
		String result = CreateBankTransferController.getBalance(bt.Id, true);
		Test.stopTest();
		System.assertEquals('Error! This transfer was already paid out. Please create new Bank trasfer.', result);

		Account acc = [SELECT Id, Name, Available_Balance__c, Pending_Balance__c FROM Account WHERE Id = :bt.Account__c];
		System.assertEquals(null, acc.Available_Balance__c);
		System.assertEquals(null, acc.Pending_Balance__c);

	}

	static testMethod void getBalanceException() {
		Bank_Transfer__c bt = createTestData(false, true);

		Test.startTest();
		Test.SetMock(HttpCallOutMock.class, new StripeConnectMock('getBalance', false));
		String result = CreateBankTransferController.getBalance(bt.Id, true);
		Test.stopTest();

		Log__c log = [
			SELECT Id, Action__c, Description__c, Event_Status__c,
			Event_Type__c, Type__c
			FROM Log__c
			WHERE Account__c = :bt.Account__c
			LIMIT 1
		];
		System.assertEquals('Get Account Balance', log.Action__c);
		System.assertEquals('Request', log.Event_Type__c);
		System.assertEquals('ERROR', log.Type__c);

	}

	static testMethod void createBankTransferTestSuccess() {
		Bank_Transfer__c bt = createTestData(false, false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock('createBankTransfer', false));
			String result = CreateBankTransferController.createBankTransfer(bt.Id, 1);
		Test.stopTest();

		Bank_Transfer__c bt_test = [SELECT Id, Name, Transfer_Id__c, Account__r.Id FROM Bank_Transfer__c WHERE ID=:bt.Id];
		System.assertEquals('Test', bt_test.Name);
		System.assertEquals('someId', bt_test.Transfer_Id__c);

		Log__c log = [
			SELECT Id, Action__c, Description__c, Event_Status__c,
				Event_Type__c, Type__c
			FROM Log__c
			WHERE Account__c = :bt_test.Account__r.Id
			LIMIT 1
		];
		System.assertEquals('Create Bank Transfer', log.Action__c);
		System.assertEquals('Create Bank Transfer has been created.', log.Description__c);
		System.assertEquals('OK', log.Event_Status__c);
		System.assertEquals('Request', log.Event_Type__c);
		System.assertEquals('INFO', log.Type__c);
	}

	static testMethod void createBankTransferTestError() {
		Bank_Transfer__c bt = createTestData(false, false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock(400, 'Bad Request', 'error : { message : "Invalid parameters."}'));
			String result = CreateBankTransferController.createBankTransfer(bt.Id, 1);
		Test.stopTest();

		Bank_Transfer__c bt_test = [SELECT Id, Name, Transfer_Id__c, Account__r.Id  FROM Bank_Transfer__c WHERE Id = :bt.Id];
		System.assertEquals(null, bt_test.Transfer_Id__c);

		Log__c log = [
			SELECT Id, Action__c, Description__c, Event_Status__c,
				Event_Type__c, Type__c
			FROM Log__c
			WHERE Account__c = :bt_test.Account__r.Id
			LIMIT 1
		];
		System.assertEquals('Create Bank Transfer', log.Action__c);
		System.assertEquals('Bad Request', log.Description__c);
		System.assertEquals('400', log.Event_Status__c);
		System.assertEquals('Request', log.Event_Type__c);
		System.assertEquals('ERROR', log.Type__c);
	}

	static testMethod void createBankTransferTestException() {
		Bank_Transfer__c bt = createTestData(false, false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock(400, 'Exception', 'Unauthorized endpoint, please check Setup->Security->Remote site settings.'));
			String result = CreateBankTransferController.createBankTransfer(bt.Id, 1);
		Test.stopTest();

		Bank_Transfer__c bt_test = [SELECT Id, Name, Transfer_Id__c, Account__r.Id  FROM Bank_Transfer__c WHERE Id = :bt.Id];
		System.assertEquals(null, bt_test.Transfer_Id__c);

		Log__c log = [
			SELECT Id, Action__c, Description__c, Event_Status__c,
				Event_Type__c, Type__c
			FROM Log__c
			WHERE Account__c = :bt_test.Account__r.Id
			LIMIT 1
		];
		System.assertEquals('Create Bank Transfer', log.Action__c);
		System.assertEquals('Request', log.Event_Type__c);
		System.assertEquals('ERROR', log.Type__c);
	}
}