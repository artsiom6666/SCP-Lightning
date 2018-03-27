@isTest
private class CommissionEarnedBatchTest {

	@isTest
	static void CommissionEarnedBatchTest() {
		Date currentdate = Date.today();

		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];
		Account accA = new Account(RecordTypeId = customerRecordType.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890');
		insert accA;

		Offer__c offerA = new Offer__c(Commission_Payable__c = 20, Active__c = true);
		Offer__c offerB = new Offer__c(Commission_Payable__c = 30, Active__c = true);
		insert new List<Offer__c> {offerA, offerB};

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Sub1__c = 'Sub11', Commissions_Earned__c = 100);
		Affiliate_Offer__c affiliateOfferB = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerB.Id, Sub1__c = 'Sub21', Commissions_Earned__c = 150);
		insert new List<Affiliate_Offer__c> {affiliateOfferA, affiliateOfferB};

		Commissions_Earned__c commissionsA = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferA.id, Offer__c = offerA.Id, Commission_Earned__c = 10, Type__c = 'Sales', Status__c = 'Not Available for Withdrawal');
		Commissions_Earned__c commissionsB = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferA.id, Offer__c = offerB.Id, Commission_Earned__c = 15, Type__c = 'Sales', Status__c = 'Not Available for Withdrawal');
		insert new List<Commissions_Earned__c> {commissionsA, commissionsB};

		Datetime testdate;
		testdate = Datetime.now().addDays(-2);
		Test.setCreatedDate(commissionsA.Id, testdate);
		testdate = Datetime.now().addDays(-22);
		Test.setCreatedDate(commissionsB.Id, testdate);

		TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Batch.RefundPeriodValue' => '20'});

		Test.startTest();
		Database.executeBatch(new CommissionEarnedBatch());
		Test.stopTest();

		System.assertEquals('Not Available for Withdrawal',  [SELECT Id, Status__c FROM Commissions_Earned__c WHERE Id =: commissionsA.Id].Status__c);
		System.assertEquals('Available for Withdrawal',  [SELECT Id, Status__c FROM Commissions_Earned__c WHERE Id =: commissionsB.Id].Status__c);
	}


	@isTest
	static void CommissionEarnedSchedulerTest() {
		Test.startTest();
			CommissionEarnedScheduler scheduler = new CommissionEarnedScheduler();
			String cronStr = '0 0 1 * * ?';
			System.schedule('CommissionEarned Test', cronStr, scheduler);
		Test.stopTest();

		List<CronTrigger> scheduleInProgress = [
			SELECT Id, NextFireTime
			FROM CronTrigger
			WHERE CronJobDetail.Name = 'CommissionEarned Test'
		];

		System.assertEquals(scheduleInProgress.size(), 1);
	}
}