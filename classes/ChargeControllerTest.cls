@isTest
private class ChargeControllerTest {

	@isTest
	static void chargeAuthorizationTransaction() {
		Payment_Agents__c newPaymentAgents = new Payment_Agents__c(
			Name = 'Test Agent Name', Security_Key__c = 'test', Active__c = true,
			Type__c = 'Stripe', Merchant_ID__c = 'test'
		);
		insert newPaymentAgents;

		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];
		Account testAcc = new Account(
			RecordTypeId = customerRecordType.Id,
			FirstName = 'Test FName', LastName = 'Test LName',
			PersonEmail = 'test@example.com'
		);
		insert testAcc;

		Order__c order = new Order__c(
			Account__c = testAcc.Id, Subtotal__c = 1000, Named_Agent__c = 'Test Agent Name',
			Subscription__c = true, Subscription_Charge_Amount__c = 100
		);
		insert order;

		Order_Transaction__c transection = new Order_Transaction__c(
			Order__c = order.Id, Type__c = 'Authorization',
			Response_Status__c = 'Approved', Response_Message__c = 'Message',
			Payment_Response_Body__c = 'original', Payment_Profile__c = 'cus_7cBFHD6iiBaTUU',
			Named_Agent__c = 'Test Agent Name', Card_Last_4__c = '4242',
			Payment_Entity_Id__c = 'ch_19dfhSCF2TV51fDnaXu3lB1J', Payment_Date__c = Datetime.now().addDays(-1),
			Payment_Method__c = 'Credit Card', Currency__c = 'US Dollars',
			Amount__c = 11
		);
		insert transection;

		ApexPages.StandardController sc = new ApexPages.standardController(order);

		Test.startTest();
			ChargeController cc = new ChargeController(sc);
			cc.chargeOrder();
		Test.stopTest();

		List<Order_Transaction__c> resultTransactions = [
			SELECT Id, Response_Status__c, Type__c, Amount__c
			FROM Order_Transaction__c
		];

		System.assertEquals(1, resultTransactions.size());
		System.assertEquals('Approved', resultTransactions[0].Response_Status__c);
		System.assertEquals('Charge', resultTransactions[0].Type__c);
		System.assertEquals(11, resultTransactions[0].Amount__c);
	}

	@isTest
	static void chargeTransaction() {
		Payment_Agents__c newPaymentAgents = new Payment_Agents__c(
			Name = 'Test Agent Name', Security_Key__c = 'test', Active__c = true,
			Type__c = 'Stripe', Merchant_ID__c = 'test'
		);
		insert newPaymentAgents;

		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];
		Account testAcc = new Account(
			RecordTypeId = customerRecordType.Id,
			FirstName = 'Test FName', LastName = 'Test LName',
			PersonEmail = 'test@example.com'
		);
		insert testAcc;

		Order__c order = new Order__c(
			Account__c = testAcc.Id, Subtotal__c = 1000, Named_Agent__c = 'Test Agent Name',
			Subscription__c = true, Subscription_Charge_Amount__c = 100
		);
		insert order;

		Order_Transaction__c transection = new Order_Transaction__c(
			Order__c = order.Id, Type__c = 'Charge',
			Response_Status__c = 'Approved', Response_Message__c = 'Message',
			Payment_Response_Body__c = 'original', Payment_Profile__c = 'cus_7cBFHD6iiBaTUU',
			Named_Agent__c = 'Test Agent Name', Card_Last_4__c = '4242',
			Payment_Entity_Id__c = 'ch_19dfhSCF2TV51fDnaXu3lB1J', Payment_Date__c = Datetime.now().addDays(-1),
			Payment_Method__c = 'Credit Card', Currency__c = 'US Dollars',
			Amount__c = 11
		);
		insert transection;

		ApexPages.StandardController sc = new ApexPages.standardController(order);

		Test.startTest();
			ChargeController cc = new ChargeController(sc);
			cc.chargeOrder();
		Test.stopTest();

		List<Order_Transaction__c> resultTransactions = [
			SELECT Id, Response_Status__c, Type__c, Amount__c
			FROM Order_Transaction__c
		];

		System.assertEquals(2, resultTransactions.size());
	}

}