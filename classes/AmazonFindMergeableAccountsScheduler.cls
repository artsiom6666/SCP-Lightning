global with sharing class AmazonFindMergeableAccountsScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		AmazonFindMergeableAccounts b = new AmazonFindMergeableAccounts();
		database.executebatch(b, 1);
	}
}