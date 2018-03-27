trigger AffiliateOfferTrigger on Affiliate_Offer__c (before insert, before update) {

	if (Trigger.isBefore && Trigger.isUpdate) {

		// method name: Before Update
		// created: 01/24/2018
		// Author: Stanislau Yarashchuk
		// recalculate "Commissions" for Affiliate Offer

		List<Id> affiliateOferIdList = new List<Id>();
		for (Affiliate_Offer__c item : Trigger.new) {
			if (item.Recalculate_Commissions_Earned__c == TRUE) {
				affiliateOferIdList.add(item.Id);
			}
		}
		List<Commissions_Earned__c> commisionEarnedList = new List<Commissions_Earned__c>();
		if (!affiliateOferIdList.isEmpty()) {
			commisionEarnedList = [
				SELECT Commission_Earned__c, Affiliate_Offer__c, CreatedDate, Status__c, Paid__c, Type__c, Order__c, Order__r.TouchCRBase__Total__c
				FROM Commissions_Earned__c
				WHERE Affiliate_Offer__c IN : affiliateOferIdList
			];
		}

		Map<Id, List<Commissions_Earned__c>> commisionEarnedMap = new Map<Id, List<Commissions_Earned__c>>();
		if (!commisionEarnedList.isEmpty()) {
			for (Commissions_Earned__c item : commisionEarnedList) {
				List<Commissions_Earned__c> newList = commisionEarnedMap.get(item.Affiliate_Offer__c) != NULL ?  commisionEarnedMap.get(item.Affiliate_Offer__c) : new List<Commissions_Earned__c>();
				newList.add(item);
				commisionEarnedMap.put(item.Affiliate_Offer__c, newList);
			}
		}

		for (Affiliate_Offer__c item : Trigger.new) {
			if (item.Recalculate_Commissions_Earned__c == TRUE) {
				item.Commissions_Earned__c = 0;
				item.Commissions_Earned_for_Withdrawal__c = 0;
				item.Commissions_Paid__c = 0;
				item.Commissions_Refunded__c = 0;
				item.Total_Commissions__c = 0;
				item.Commissions_Paid_And_Refunded__c = 0;
				item.Commission_Not_Passed_Refund_Period__c = 0;
				item.Commissions_Pending_Withdrawal__c = 0;
				item.Total_Transactions__c = 0;
				item.Refund_Transactions__c = 0;
				item.Total_Revenue__c = 0;
				item.Average_Order_Value__c = 0;
			}
			if (item.Recalculate_Commissions_Earned__c == TRUE && commisionEarnedMap != NULL && commisionEarnedMap.get(item.Id) != NULL) {
				Set<Id> totalTransactions = new Set<Id>();
				Set<Id> refundTransactions = new Set<Id>();
				for (Commissions_Earned__c priceItem : commisionEarnedMap.get(item.Id)) {
					item.Commissions_Earned__c += priceItem.Commission_Earned__c;
					
					if (priceItem.Type__c == 'Sales') {
						item.Total_Commissions__c += priceItem.Commission_Earned__c;
					}
					if (priceItem.Type__c == 'Sales' && priceItem.Status__c == 'Available for Withdrawal') {
						item.Commissions_Earned_for_Withdrawal__c += priceItem.Commission_Earned__c;
					}
					if (priceItem.Type__c == 'Sales' && priceItem.Status__c == 'Refund') {
						item.Commissions_Refunded__c += -priceItem.Commission_Earned__c;
					}
					if (priceItem.Type__c == 'Sales' && priceItem.Status__c == 'Refund' && priceItem.Paid__c == true) {
						item.Commissions_Paid_And_Refunded__c += -priceItem.Commission_Earned__c;
					}
					if (priceItem.Type__c == 'Sales' && priceItem.Paid__c == true) {
						item.Commissions_Paid__c += priceItem.Commission_Earned__c;
					}
					if (priceItem.Type__c == 'Sales' && priceItem.Status__c == 'Not Available for Withdrawal') {
						item.Commission_Not_Passed_Refund_Period__c += priceItem.Commission_Earned__c;
					}
					if (priceItem.Type__c == 'Sales' && priceItem.Status__c == 'Pending Withdrawal') {
						item.Commissions_Pending_Withdrawal__c += priceItem.Commission_Earned__c;
					}
					if (priceItem.Order__c != NULL) {
						totalTransactions.add(priceItem.Order__c);
					}
					if (priceItem.Type__c == 'Sales' && priceItem.Status__c == 'Refund') {
						refundTransactions.add(priceItem.Order__c);
					}
					if (priceItem.Order__c !=  NULL && priceItem.Order__r.TouchCRBase__Total__c != NULL) {
						item.Total_Revenue__c += priceItem.Order__r.TouchCRBase__Total__c;
					}
				}
				item.Total_Transactions__c = totalTransactions.size();
				item.Refund_Transactions__c = refundTransactions.size();
				if (item.Total_Transactions__c != 0 && item.Total_Revenue__c != 0) {
					item.Average_Order_Value__c = item.Total_Revenue__c / item.Total_Transactions__c;
				}
			}
			item.Recalculate_Commissions_Earned__c = FALSE;
		}

	}

	if (Trigger.isBefore && Trigger.isInsert) {

		// method name: Before Insert
		// created: 01/24/2018
		// Author: Stanislau Yarashchuk
		// Check for dublicate Affiliate Offer records

		List<Id> offerIdList = new List<Id>();
		List<Id> affiliateIdList = new List<Id>();
		for (Affiliate_Offer__c item : Trigger.new) {
			offerIdList.add(item.Offer__c);
			affiliateIdList.add(item.Account__c);
		}

		List<Affiliate_Offer__c> existAffiliateOfferList = new List<Affiliate_Offer__c>();
		if (!offerIdList.isEmpty() && !affiliateIdList.isEmpty()) {
			existAffiliateOfferList = [
				SELECT Account__c, Offer__c
				FROM Affiliate_Offer__c
				WHERE Account__c IN :affiliateIdList AND Offer__c IN :offerIdList
			];
		}

		Set<String> existAffiliateOfferSet = new Set<String>();
		if (!existAffiliateOfferList.isEmpty()) {
			for (Affiliate_Offer__c item : existAffiliateOfferList) {
				existAffiliateOfferSet.add(item.Account__c+''+item.Offer__c);
			}
		}

		for (Affiliate_Offer__c item : Trigger.new) {
			if (existAffiliateOfferSet.contains(item.Account__c+''+item.Offer__c)) {
				item.addError('Duplicate record');
			}
		}

	}

}