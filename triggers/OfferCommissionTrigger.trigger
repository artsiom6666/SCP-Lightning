trigger OfferCommissionTrigger on Offer_Commission__c (before insert, before update) {

	if (Trigger.isBefore && Trigger.isInsert) {

		// method name: Before Insert
		// created: 01/29/2018
		// Author: Stanislau Yarashchuk
		// calculate commission payable for offer
		List<Id> offerIdList = new List<Id>();
		for (Offer_Commission__c item : Trigger.new) {
			offerIdList.add(item.Offer__c);
		}

		Map<Id, Offer__c> offerMap = new Map<Id, Offer__c>([
			SELECT Id, Product__c
			FROM Offer__c
			Where Id IN :offerIdList
		]);

		List<PricebookEntry> productList = new List<PricebookEntry>();
		if (!offerIdList.isEmpty()) {
			productList = [
				SELECT Product2Id, Pricebook2Id, Pricebook2.Name, UnitPrice, Product2.Id
				FROM PricebookEntry
				WHERE Product2Id IN (SELECT Product__c FROM Offer__c WHERE Id IN :offerIdList)
			];
		}

		Map<String, List<PricebookEntry>> offerProductMap = new Map<String, List<PricebookEntry>>();
		if (!productList.isEmpty()) {
			for (PricebookEntry item : productList) {
				List<PricebookEntry> newList = offerProductMap.get(item.Product2.Id) != NULL ?  offerProductMap.get(item.Product2.Id) : new List<PricebookEntry>();
				newList.add(item);
				offerProductMap.put(item.Product2.Id+''+item.Pricebook2Id, newList);
			}
		}

		for (Offer_Commission__c item : Trigger.new) {
			item.Commission_Payable__c = 0;
			List<PricebookEntry> priceBookListItem = offerProductMap.get(offerMap.get(item.Offer__c).Product__c+''+item.Pricebook_Eligibility__c);
			if (priceBookListItem != NULL) {
				Decimal amount = 0.00;
				Integer countProduct = priceBookListItem.size();
				if (item.Percent_Of_Price__c != NULL) {
					for (PricebookEntry priceItem : priceBookListItem) {
						amount += priceItem.UnitPrice;
					}
					item.Commission_Payable__c = amount * (item.Percent_Of_Price__c / 100);
				}
				else if (item.Fixed_Amount__c != NULL) {
					item.Commission_Payable__c = countProduct * item.Fixed_Amount__c;
				}
			}
			item.Recalculate_Commission_Payable__c = FALSE;
		}

	}

	if (Trigger.isBefore && Trigger.isUpdate) {


		// method name: Before Update
		// created: 01/29/2018
		// Author: Stanislau Yarashchuk
		// calculate commission payable for offer
		List<Id> offerIdList = new List<Id>();
		for (Offer_Commission__c item : Trigger.new) {
			if (item.Fixed_Amount__c != Trigger.oldMap.get(item.Id).Fixed_Amount__c || item.Percent_Of_Price__c != Trigger.oldMap.get(item.Id).Percent_Of_Price__c || item.Recalculate_Commission_Payable__c == TRUE) {
				offerIdList.add(item.Offer__c);
			}
		}

		Map<Id, Offer__c> offerMap = new Map<Id, Offer__c>([
			SELECT Id, Product__c
			FROM Offer__c
			Where Id IN :offerIdList
		]);

		List<PricebookEntry> productList = new List<PricebookEntry>();
		if (!offerIdList.isEmpty()) {
			productList = [
				SELECT Product2Id, Pricebook2Id, Pricebook2.Name, UnitPrice, Product2.Id
				FROM PricebookEntry
				WHERE Product2Id IN (SELECT Product__c FROM Offer__c WHERE Id IN :offerIdList)
			];
		}

		Map<String, List<PricebookEntry>> offerProductMap = new Map<String, List<PricebookEntry>>();
		if (!productList.isEmpty()) {
			for (PricebookEntry item : productList) {
				List<PricebookEntry> newList = offerProductMap.get(item.Product2.Id) != NULL ?  offerProductMap.get(item.Product2.Id) : new List<PricebookEntry>();
				newList.add(item);
				offerProductMap.put(item.Product2.Id+''+item.Pricebook2Id, newList);
			}
		}

		for (Offer_Commission__c item : Trigger.new) {
			
			if (item.Fixed_Amount__c != Trigger.oldMap.get(item.Id).Fixed_Amount__c || item.Percent_Of_Price__c != Trigger.oldMap.get(item.Id).Percent_Of_Price__c || item.Recalculate_Commission_Payable__c == TRUE) {
				item.Commission_Payable__c = 0;
				List<PricebookEntry> priceBookListItem = offerProductMap.get(offerMap.get(item.Offer__c).Product__c+''+item.Pricebook_Eligibility__c);
				if (priceBookListItem != NULL) {
					Decimal amount = 0.00;
					Integer countProduct = priceBookListItem.size();
					if (item.Percent_Of_Price__c != NULL) {
						for (PricebookEntry priceItem : priceBookListItem) {
							amount += priceItem.UnitPrice;
						}
						item.Commission_Payable__c = amount * (item.Percent_Of_Price__c / 100);
					}
					else if (item.Fixed_Amount__c != NULL) {
						item.Commission_Payable__c = countProduct * item.Fixed_Amount__c;
					}
				}
				item.Recalculate_Commission_Payable__c = FALSE;
			}
		}

	}

}