trigger PayoutTrigger on Payouts__c (before insert, before update, after update, after insert) {

    //after changing the logic, check the work of the test class AffiliateHelperTest
    if (Trigger.isBefore && Trigger.isInsert) {

        List<Id> accountIdList = new List<Id>();
        for (Payouts__c item : Trigger.new) {
            accountIdList.add(item.Account__c);
        }

        Map<Id, Account> accountMap = new Map<Id, Account> ([
            SELECT id, Balance_Due__c, Available_Balance_for_Withdrawal__c
            FROM Account
            WHERE Id IN :accountIdList
        ]);

        for (Payouts__c item : Trigger.new) {
            if (accountMap.get(item.Account__c) != NULL && accountMap.get(item.Account__c).Available_Balance_for_Withdrawal__c != item.Amount_Transferred__c) {
                item.addError('The amount of the transfer must be equals the amount of the Available Balance.');
            }
        }

    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        for (Payouts__c item : Trigger.new) {
            if (item.Status__c == 'Approved' &&  Trigger.oldMap.get(item.Id).Status__c != 'Approved') {
                item.Payout_Date__c = System.now();
            }
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        List<Id> payoutsId = new List<Id>();
        for (Payouts__c item : Trigger.new) {
            if (item.Status__c == 'Approved' &&  Trigger.oldMap.get(item.Id).Status__c != 'Approved') {
                payoutsId.add(item.Id);
            }
        }

        List<Commissions_Earned__c> commissionsList = new List<Commissions_Earned__c>();
        if (!payoutsId.isEmpty()) {
            commissionsList = [
                SELECT Id, Status__c, Payouts__r.Status__c
                FROM Commissions_Earned__c
                WHERE Payouts__c IN :payoutsId
            ];
        }

        for (Commissions_Earned__c item : commissionsList) {
            if (item.Payouts__r.Status__c == 'Approved') {
                item.Status__c = 'Paid';
                item.Paid__c = true;
                item.Payout_Date__c = System.now();
            }
        }
        update commissionsList;

    }


    if (Trigger.isAfter && Trigger.isInsert) {
        Map<Id, Id> accountIdToPayoutId = new Map<Id, Id>();
        for (Payouts__c item : Trigger.new) {
            accountIdToPayoutId.put(item.Account__c, item.Id);
        }
        List<Commissions_Earned__c> commissionEarnedList = [
            SELECT Id, Commission_Earned__c, Payouts__c, Affiliate_Offer__r.Account__c
            FROM Commissions_Earned__c
            WHERE Affiliate_Offer__r.Account__c IN: accountIdToPayoutId.keySet()
            AND Status__c = 'Available for Withdrawal' AND Type__c = 'Sales'
        ];

        for (Commissions_Earned__c item : commissionEarnedList) {
            item.Payouts__c = accountIdToPayoutId.get(item.Affiliate_Offer__r.Account__c);
            item.Status__c = 'Pending Withdrawal';
        }
        update commissionEarnedList;

    }

}