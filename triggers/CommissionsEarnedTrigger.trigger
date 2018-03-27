trigger CommissionsEarnedTrigger on Commissions_Earned__c (after insert, after update, after delete) {

	if (Trigger.isAfter && Trigger.isInsert) {

		List<Id> commissionsEarnedIdList = new List<Id>();
		for (Commissions_Earned__c item : Trigger.new) {
			if (item.Affiliate_Offer__c != NULL) {
				commissionsEarnedIdList.add(item.Affiliate_Offer__c);
			}
		}

		if (!commissionsEarnedIdList.isEmpty()) {
			List<Affiliate_Offer__c> affiliateOfferList = [
				SELECT Recalculate_Commissions_Earned__c
				FROM Affiliate_Offer__c
				WHERE Id IN : commissionsEarnedIdList
			];
			for (Affiliate_Offer__c item : affiliateOfferList) {
				item.Recalculate_Commissions_Earned__c = TRUE;
			}
			update affiliateOfferList;
		}
	}

	if (Trigger.isAfter && Trigger.isUpdate) {

		List<Id> commissionsEarnedIdList = new List<Id>();
		for (Commissions_Earned__c item : Trigger.new) {
			if (item.Affiliate_Offer__c != NULL) {
				commissionsEarnedIdList.add(item.Affiliate_Offer__c);
			}
			if (Trigger.oldMap.get(item.Id) != NULL && Trigger.oldMap.get(item.Id).Affiliate_Offer__c != NULL) {
				commissionsEarnedIdList.add(Trigger.oldMap.get(item.Id).Affiliate_Offer__c);
			}
		}

		if (!commissionsEarnedIdList.isEmpty()) {
			List<Affiliate_Offer__c> affiliateOfferList = [
				SELECT Recalculate_Commissions_Earned__c
				FROM Affiliate_Offer__c
				WHERE Id IN : commissionsEarnedIdList
			];
			for (Affiliate_Offer__c item : affiliateOfferList) {
				item.Recalculate_Commissions_Earned__c = TRUE;
			}
			update affiliateOfferList;
		}
	}

	if (Trigger.isAfter && Trigger.isDelete) {

		List<Id> commissionsEarnedIdList = new List<Id>();
		for (Commissions_Earned__c item : Trigger.old) {
			if (item.Affiliate_Offer__c != NULL) {
				commissionsEarnedIdList.add(item.Affiliate_Offer__c);
			}
		}

		if (!commissionsEarnedIdList.isEmpty()) {
			List<Affiliate_Offer__c> affiliateOfferList = [
				SELECT Recalculate_Commissions_Earned__c
				FROM Affiliate_Offer__c
				WHERE Id IN : commissionsEarnedIdList
			];
			for (Affiliate_Offer__c item : affiliateOfferList) {
				item.Recalculate_Commissions_Earned__c = TRUE;
			}
			update affiliateOfferList;
		}
	}
}