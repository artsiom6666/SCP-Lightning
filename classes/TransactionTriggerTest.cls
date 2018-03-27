@isTest(seeAllData = false)
private class TransactionTriggerTest {

	public static testMethod void test_TransactionStatusOpt_bulk_negative() {

		Account testAcc = new Account(Name = 'test');
		insert testAcc;

		Order__c testOrd = new Order__c();
		testOrd.Account__c = testAcc.Id;
		insert testOrd;

		List<Order_Transaction__c> testTransList = new List<Order_Transaction__c>();

		for (Integer idx = 0; idx < 10; idx++) {
			Order_Transaction__c testTrans = new Order_Transaction__c();
			testTrans.Order__c = testOrd.Id;
			testTrans.Named_Agent__c = 'Authorize.net';
			testTrans.Type__c = 'Charge';
			testTrans.Payment_Date__c = Datetime.now();
			testTrans.Response_Status__c = 'Approved';
			testTransList.add(testTrans);
		}

		insert testTransList;

		Test.startTest();
			for (Order_Transaction__c trans : testTransList) {
				trans.Response_Status__c = 'refund';
			}
			testTransList[0].Response_Status__c = 'failed';
			testTransList[1].Response_Status__c = 'charge back';

			update testTransList;

		Test.stopTest();

		List<Account> testObj = [select Blacklist__c from Account where id = :testAcc.Id];
		System.assertEquals('True', testObj[0].Blacklist__c);
	}

	public static testMethod void test_TransactionStatusOpt_bulk_positive() {

		Account testAcc = new Account(Name = 'test');
		insert testAcc;

		Order__c testOrd = new Order__c();
		testOrd.Account__c = testAcc.Id;
		insert testOrd;

		List<Order_Transaction__c> testTransList = new List<Order_Transaction__c>();

		for (Integer idx = 0; idx < 10; idx++) {
			Order_Transaction__c testTrans = new Order_Transaction__c();
			testTrans.Order__c = testOrd.Id;
			testTrans.Named_Agent__c = 'Authorize.net';
			testTrans.Type__c = 'Charge';
			testTrans.Payment_Date__c = Datetime.now();
			testTrans.Response_Status__c = 'Approved';
			testTransList.add(testTrans);
		}

		insert testTransList;

		Test.startTest();
			for (Order_Transaction__c trans : testTransList) {
				trans.Response_Status__c = 'Charged';
			}
			update testTransList;

		Test.stopTest();

		List<Account> testObj = [select Blacklist__c from Account where id = :testAcc.Id];
		System.assertNotEquals('True', testObj[0].Blacklist__c);
	}

	public static testMethod void test_TransactionPaymentAttempt_bulk() {

		Account testAcc = new Account(Name = 'test');
		insert testAcc;

		Order__c testOrd = new Order__c();
		testOrd.Account__c = testAcc.Id;
		insert testOrd;

		List<Payment_Attempt__c> testPaymentsList = new List<Payment_Attempt__c>();
		for (Integer idx = 0; idx < 10; idx++) {
			testPaymentsList.add(new Payment_Attempt__c(
				Amount__c = 1, Date__c = Date.today(),
				Order__c = testOrd.Id, Status__c = 'Scheduled',
				Remaining_Retries__c = 3, Ready_To_Payment__c = false
			));
		}
		insert testPaymentsList;

		List<Order_Transaction__c> testTransList = new List<Order_Transaction__c>();
		for (Integer idx = 0; idx < 10; idx++) {
			testTransList.add(new Order_Transaction__c(
				Order__c = testOrd.Id, Named_Agent__c = 'Authorize.net',
				Type__c = 'Charge', Payment_Date__c = Datetime.now(), Subscription__c = true,
				Response_Status__c = 'Approved', Payment_Attempt__c = testPaymentsList[idx].Id
			));
		}
		insert testTransList;

		for (Payment_Attempt__c paymentAttempt : [SELECT Id, Ready_To_Payment__c FROM Payment_Attempt__c]) {
			System.assertEquals(true, paymentAttempt.Ready_To_Payment__c);
		}
	}

	public static testMethod void test_TransactionPaymentAttempt_OrderError() {

		Account testAcc = new Account(Name = 'test');
		insert testAcc;

		Order__c testOrd = new Order__c(
			Account__c = testAcc.Id,
			Status__c = 'Initiated'
		);
		insert testOrd;

		Payment_Attempt__c testPayment = new Payment_Attempt__c(
			Amount__c = 1, Date__c = Date.today(),
			Order__c = testOrd.Id, Status__c = 'Scheduled',
			Remaining_Retries__c = 0, Ready_To_Payment__c = false
		);
		Payment_Attempt__c testPayment1 = new Payment_Attempt__c(
			Amount__c = 1, Date__c = Date.today(),
			Order__c = testOrd.Id, Status__c = 'Scheduled',
			Remaining_Retries__c = 1, Ready_To_Payment__c = false
		);
		Payment_Attempt__c testPayment2 = new Payment_Attempt__c(
			Amount__c = 1, Date__c = Date.today(),
			Order__c = testOrd.Id, Status__c = 'Scheduled',
			Remaining_Retries__c = 2, Ready_To_Payment__c = false
		);
		Payment_Attempt__c testPayment3 = new Payment_Attempt__c(
			Amount__c = 1, Date__c = Date.today(),
			Order__c = testOrd.Id, Status__c = 'Scheduled',
			Remaining_Retries__c = 3, Ready_To_Payment__c = false
		);
		insert new List<Payment_Attempt__c>{testPayment, testPayment1, testPayment2, testPayment3};

		Test.startTest();
			Order_Transaction__c testTrans = new Order_Transaction__c(
				Order__c = testOrd.Id, Named_Agent__c = 'Authorize.net',
				Type__c = 'Charge', Payment_Date__c = Datetime.now(), Subscription__c = true,
				Response_Status__c = 'Error', Payment_Attempt__c = testPayment.Id
			);
			Order_Transaction__c testTrans1 = new Order_Transaction__c(
				Order__c = testOrd.Id, Named_Agent__c = 'Authorize.net',
				Type__c = 'Charge', Payment_Date__c = Datetime.now(), Subscription__c = true,
				Response_Status__c = 'Error', Payment_Attempt__c = testPayment1.Id
			);
			Order_Transaction__c testTrans2 = new Order_Transaction__c(
				Order__c = testOrd.Id, Named_Agent__c = 'Authorize.net',
				Type__c = 'Charge', Payment_Date__c = Datetime.now(), Subscription__c = true,
				Response_Status__c = 'Error', Payment_Attempt__c = testPayment2.Id
			);
			Order_Transaction__c testTrans3 = new Order_Transaction__c(
				Order__c = testOrd.Id, Named_Agent__c = 'Authorize.net',
				Type__c = 'Charge', Payment_Date__c = Datetime.now(), Subscription__c = true,
				Response_Status__c = 'Error', Payment_Attempt__c = testPayment3.Id
			);
			insert new List<Order_Transaction__c>{testTrans, testTrans1, testTrans2, testTrans3};

		Test.stopTest();

		Map<Id, Payment_Attempt__c> payments = new Map<Id, Payment_Attempt__c>([SELECT Id, Status__c, Remaining_Retries__c FROM Payment_Attempt__c]);
		System.assertEquals(0, payments.get(testPayment1.Id).Remaining_Retries__c);
		System.assertEquals(1, payments.get(testPayment2.Id).Remaining_Retries__c);
		System.assertEquals(2, payments.get(testPayment3.Id).Remaining_Retries__c);
		System.assertEquals('Error', payments.get(testPayment.Id).Status__c);

		Order__c order = [SELECT Id, Status__c FROM Order__c WHERE Id =: testOrd.Id LIMIT 1];
		System.assertEquals('Error', order.Status__c);
	}
}