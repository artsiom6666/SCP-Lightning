public with sharing class CommissionEarnedBatch implements Database.Batchable<sObject> {
	
	String query;
	private static Integer COUNT_DAYS = 14;
	
	public CommissionEarnedBatch() {
		query = 'SELECT Id, CreatedDate, Status__c FROM Commissions_Earned__c WHERE Type__c = \'Sales\' AND Status__c = \'Not Available for Withdrawal\'';
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope) {

		Map<String, String> settingsMap = TouchCRBase.TouchCRHelper.getSettings('allSettings');
		Integer countDays = settingsMap != NULL && settingsMap.get('Batch.RefundPeriodValue') != NULL ? Integer.valueOf(settingsMap.get('Batch.RefundPeriodValue')) : COUNT_DAYS;

		List<Commissions_Earned__c> commissionEarnedListUpdate = new List<Commissions_Earned__c>();
		for (sObject item : scope) {
			if (item.getSObjectType() == Schema.Commissions_Earned__c.getSObjectType()) {
				Commissions_Earned__c commissionItem = (Commissions_Earned__c) item;
				if (commissionItem.CreatedDate.addDays(countDays) < System.now()) {
					commissionItem.Status__c = 'Available for Withdrawal';
					commissionEarnedListUpdate.add(commissionItem);
				}
			}
		}

		try {
			update commissionEarnedListUpdate;
			/*SFDCAccessController.UpdateWithoutSharing (
				commissionEarnedListUpdate,
				'CommissionEarnedBatch.cls [execute]',
				new List<Schema.DescribeFieldResult> {
					Commissions_Earned__c.Status__c.getDescribe()
				}
			);
		}
		catch (Exception e) {throw new SFDCAccessControlException();}*/
		} catch (Exception e) {}

	}
	
	public void finish(Database.BatchableContext BC) {
		
	}
	
}