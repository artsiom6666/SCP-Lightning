@isTest
private class VerifyStripeAccountControllerTest {

	static Account createTestData(Boolean isNoAccount, Boolean isNoBankAccoount, Boolean isNoVerification) {
		List<RecordType> recTypes = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Franchisee_Account'];

		Account acc = new Account(
			LastName = 'Jarvis',
			FirstName = 'Aaron',
			PersonEmail = 'charmhaven@homeicecream.com.example',
			RecordTypeId = recTypes.get(0).Id,
			Stripe_Account_ID__c = (isNoAccount == false) ? 'acct_1BJJlkGhCH1rGkTK' : null,
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

		if (isNoBankAccoount == false) {
			Payout_Bank_Account__c bank_acc = new Payout_Bank_Account__c(
					Account__c = acc.Id,
					Account_Holder_Name__c = 'Test',
					Account_Holder_Type__c = 'individual',
					Bank_Account_Number__c = '111111116',
					Bank_Country__c = 'AU',
					Bank_Currency__c = 'aud',
					BSB_Routing_Number__c = '110000'
			);
			insert bank_acc;
		}

		Map<String, String> newTouchCrSetting = new Map<String, String>();
		newTouchCrSetting.put('Name', 'Test Agent Name');
		newTouchCrSetting.put('Endpoint.ClientId', 'test');
		newTouchCrSetting.put('Endpoint.ClientSecret', 'true');
		TouchCRHelper.setSettings(newTouchCrSetting);

		Stripe_Connect__c newConnectSetting = new Stripe_Connect__c();
		newConnectSetting.Name = 'Test';
		newConnectSetting.Value__c = 'paymentagent';
		insert newConnectSetting;

		if (isNoVerification == false) {

			ContentVersion contentVersion = new ContentVersion(
					Title = 'Test',
					PathOnClient = 'test.jpg',
					VersionData = Blob.valueOf('Test Content'),
					IsMajorVersion = true
			);
			insert contentVersion;

			List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
			ContentDocumentLink cdl = New ContentDocumentLink(
					LinkedEntityId = acc.id,
					ContentDocumentId = documents[0].Id, shareType = 'I'
			);
			insert cdl;
		}

		return acc;
	}

	static testMethod void verifyStripeAccountTestSuccess() {
		Account acc = createTestData(false, false, false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock('verifyStripeAccount', false));
			String result = VerifyStripeAccountController.verifyStripeAccount(acc.Id);
		Test.stopTest();

		Log__c log = [
			SELECT Id, Action__c, Description__c, Event_Status__c,
				Event_Type__c, Type__c
			FROM Log__c
			WHERE Account__c = :acc.Id
			LIMIT 1
		];
		System.assertEquals('Verify Franchisee Account', log.Action__c);
		System.assertEquals('Franchisee Account has been verified', log.Description__c);
		System.assertEquals('OK', log.Event_Status__c);
		System.assertEquals('Request', log.Event_Type__c);
		System.assertEquals('INFO', log.Type__c);
	}

	static testMethod void verifyStripeAccountTestError() {
		Account acc = createTestData(false, false, false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock(400, 'Bad Request', 'error : { message : "Invalid parameters."}'));
			String result = VerifyStripeAccountController.verifyStripeAccount(acc.Id);
		Test.stopTest();

		Log__c log = [
			SELECT Id, Action__c, Description__c, Event_Status__c,
				Event_Type__c, Type__c
			FROM Log__c
			WHERE Account__c = :acc.Id
			LIMIT 1
		];
		System.assertEquals('Verify Franchisee Account', log.Action__c);
		System.assertEquals('Bad Request', log.Description__c);
		System.assertEquals('400', log.Event_Status__c);
		System.assertEquals('Request', log.Event_Type__c);
		System.assertEquals('ERROR', log.Type__c);
	}

	static testMethod void verifyStripeAccountTestErrorNoAcc() {
		Account acc = createTestData(true, false, false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock('verifyStripeAccount', false));
			String result = VerifyStripeAccountController.verifyStripeAccount(acc.Id);
		Test.stopTest();

		System.assertEquals('Error! No Stripe Account to be verified.', result);
	}

	static testMethod void verifyStripeAccountTestErrorNoBankAcc() {
		Account acc = createTestData(false, true, false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock('verifyStripeAccount', false));
			String result = VerifyStripeAccountController.verifyStripeAccount(acc.Id);
		Test.stopTest();

		System.assertEquals('Error! To verify this Stripe Account please create a Payout Bank Account first.', result);
	}

	static testMethod void verifyStripeAccountTestErrorNoVerif() {
		Account acc = createTestData(false, false, true);

		Test.startTest();
		Test.SetMock(HttpCallOutMock.class, new StripeConnectMock('verifyStripeAccount', false));
		String result = VerifyStripeAccountController.verifyStripeAccount(acc.Id);
		Test.stopTest();

		System.assertEquals('No verification document in attachments.', result);
	}

	static testMethod void verifyStripeAccountTestException() {
		Account acc = createTestData(false, false, false);

		Test.startTest();
			Test.SetMock(HttpCallOutMock.class, new StripeConnectMock(400, 'Exception', 'Unauthorized endpoint, please check Setup->Security->Remote site settings.'));
			String result = VerifyStripeAccountController.verifyStripeAccount(acc.Id);
		Test.stopTest();

		Log__c log = [
			SELECT Id, Action__c, Description__c, Event_Status__c,
				Event_Type__c, Type__c
			FROM Log__c
			WHERE Account__c = :acc.Id
			LIMIT 1
		];
		System.assertEquals('Verify Franchisee Account', log.Action__c);
		System.assertEquals('Request', log.Event_Type__c);
		System.assertEquals('ERROR', log.Type__c);
	}
}