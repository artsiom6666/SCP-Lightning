@isTest
private class AmazonFindMergeableAccountsTest
{
	@isTest
	static void itShould()
	{
		Account acc = new Account();
		acc.AmazonAccountId__c = 'testID';
		acc.FirstName = 'FName';
		acc.LastName = 'LName';
		if (TouchCRHelper.isSCPEnabled() == TRUE) {
			acc.put('BillingCountryCode', 'US');
			acc.put('BillingStateCode', 'FL');
		}
		acc.BillingStreet = 'street';
		insert acc;

		Account acc1 = new Account();
		acc1.FirstName = 'fname';
		acc1.LastName = 'name';
		if (TouchCRHelper.isSCPEnabled() == TRUE) {
			acc.put('BillingCountryCode', 'US');
			acc.put('BillingStateCode', 'FL');
		}
		acc1.BillingStreet = 'street';
		insert acc1;

		AmazonFindMergeableAccountsScheduler sch = new AmazonFindMergeableAccountsScheduler();
		DateTime dt = Datetime.now().addMinutes(1);
		String cronString = '' + dt.second() + ' ' +
			dt.minute() + ' ' + dt.hour() + ' ' +
			dt.day() + ' ' + dt.month() + ' ? ' +
			dt.year();

		stopMonitor('Find Mergeable Accounts');

		Test.startTest();
		System.schedule('Find Mergeable Accounts', cronString, sch);
		AmazonFindMergeableAccounts b = new AmazonFindMergeableAccounts();
		Database.executeBatch(b, 1);
		Test.stopTest();

		List<Account> mergeableList = [SELECT ID FROM Account WHERE isMergeable__c = true];

		System.assertEquals(1, mergeableList.size());
	}

	private static void stopMonitor(String nameCronTrigger) {
		Id schJobId = getScheduleJobs(nameCronTrigger);
		if (schJobId != null) {
			System.abortJob(schJobId);
		}
	}

	private static Id getScheduleJobs(String nameCronTrigger) {
		Id result = null;
		List<CronTrigger> scheduleInProgress = [
			SELECT Id, NextFireTime
			FROM CronTrigger
			WHERE CronJobDetail.Name =: nameCronTrigger
		];
		result = (scheduleInProgress.isEmpty()) ? NULL : scheduleInProgress.get(0).Id;
		return result;
	}
}