trigger OfferTrigger on Offer__c (before update, before insert) {

	if (Trigger.isBefore && Trigger.isInsert) {

		// method name: Before Insert
		// created: 01/29/2018
		// Author: Stanislau Yarashchuk
		// calculate commission payable for offer
		List<Id> productIdList = new List<Id>();
		List<Id> orderFormIdList = new List<Id>();
		for (Offer__c item : Trigger.new) {
			if (item.Fixed_Amount__c != NULL || item.Percent_Of_Price__c != NULL) {
				if (item.Type__c == 'Cart') {
					productIdList.add(item.Product__c);
				}
				else if (item.Type__c == 'Funnel') {
					orderFormIdList.add(item.OrderForm__c);
				}
			}
		}

		List<PricebookEntry> productList = new List<PricebookEntry>();
		if (!productIdList.isEmpty()) {
			productList = [
				SELECT Product2Id, Pricebook2.Name, UnitPrice, Product2.Id
				FROM PricebookEntry
				WHERE Product2.Id IN : productIdList
				AND Pricebook2.Name = 'Standard Price Book'
			];
		}

		Map<Id,TouchCRBase__OrderForm__c> orderFormMap = new Map<Id,TouchCRBase__OrderForm__c>([
			SELECT Id, TouchCRBase__Offer_Price__c
			FROM TouchCRBase__OrderForm__c
			WHERE Id IN : orderFormIdList
		]);

		Map<Id, PricebookEntry> offerProductMap = new Map<Id,PricebookEntry>();
		if (!productList.isEmpty()) {
			for (PricebookEntry item : productList) {
				offerProductMap.put(item.Product2.Id, item);
			}
		}

		for (Offer__c item : Trigger.new) {
			if (item.Fixed_Amount__c != NULL || item.Percent_Of_Price__c != NULL) {
				item.Commission_Payable__c = 0;
				Decimal amount = 0.00;

				if (item.Percent_Of_Price__c != NULL) {
					if (item.Type__c == 'Cart' && offerProductMap.get(item.Product__c) != NULL) {
						amount = offerProductMap.get(item.Product__c).UnitPrice;
					}
					else if (item.Type__c == 'Funnel' && orderFormMap.get(item.OrderForm__c) != NULL) {
						amount = orderFormMap.get(item.OrderForm__c).TouchCRBase__Offer_Price__c;
					}
					item.Commission_Payable__c = amount * (item.Percent_Of_Price__c / 100);
				}
				else if (item.Fixed_Amount__c != NULL) {
					item.Commission_Payable__c = item.Fixed_Amount__c;
				}
				item.Recalculate_Commission_Payable__c = FALSE;
			}
		}


	}

	if (Trigger.isBefore && Trigger.isUpdate) {

		// method name: Before Update
		// created: 01/29/2018
		// Author: Stanislau Yarashchuk
		// calculate commission payable for offer
		List<Id> productIdList = new List<Id>();
		List<Id> orderFormIdList = new List<Id>();
		for (Offer__c item : Trigger.new) {
			if (item.Fixed_Amount__c != Trigger.oldMap.get(item.Id).Fixed_Amount__c 
			|| item.Percent_Of_Price__c != Trigger.oldMap.get(item.Id).Percent_Of_Price__c
			|| item.Recalculate_Commission_Payable__c == TRUE
			|| (item.Active__c == TRUE && item.Active__c != Trigger.oldMap.get(item.Id).Active__c)
			) {
				if (item.Type__c == 'Cart') {
					productIdList.add(item.Product__c);
				}
				else if (item.Type__c == 'Funnel') {
					orderFormIdList.add(item.OrderForm__c);
				}
			}
		}

		List<PricebookEntry> productList = new List<PricebookEntry>();
		if (!productIdList.isEmpty()) {
			productList = [
				SELECT Product2Id, Pricebook2.Name, UnitPrice, Product2.Id
				FROM PricebookEntry
				WHERE Product2.Id IN : productIdList
				AND Pricebook2.Name = 'Standard Price Book'
			];
		}

		Map<Id,TouchCRBase__OrderForm__c> orderFormMap = new Map<Id,TouchCRBase__OrderForm__c>([
			SELECT Id, TouchCRBase__Offer_Price__c
			FROM TouchCRBase__OrderForm__c
			WHERE Id IN : orderFormIdList
		]);

		Map<Id, PricebookEntry> offerProductMap = new Map<Id,PricebookEntry>();
		if (!productList.isEmpty()) {
			for (PricebookEntry item : productList) {
				offerProductMap.put(item.Product2.Id, item);
			}
		}

		for (Offer__c item : Trigger.new) {
			
			if (item.Fixed_Amount__c != Trigger.oldMap.get(item.Id).Fixed_Amount__c 
				|| item.Percent_Of_Price__c != Trigger.oldMap.get(item.Id).Percent_Of_Price__c
				|| item.Recalculate_Commission_Payable__c == TRUE 
				|| (item.Active__c == TRUE && item.Active__c != Trigger.oldMap.get(item.Id).Active__c)
			) {

				item.Commission_Payable__c = 0;
				Decimal amount = 0.00;

				if (item.Percent_Of_Price__c != NULL) {
					if (item.Type__c == 'Cart' && offerProductMap.get(item.Product__c) != NULL) {
						amount = offerProductMap.get(item.Product__c).UnitPrice;
					}
					else if (item.Type__c == 'Funnel' && orderFormMap.get(item.OrderForm__c) != NULL) {
						amount = orderFormMap.get(item.OrderForm__c).TouchCRBase__Offer_Price__c;
					}
					item.Commission_Payable__c = amount * (item.Percent_Of_Price__c / 100);
				}
				else if (item.Fixed_Amount__c != NULL) {
					item.Commission_Payable__c = item.Fixed_Amount__c;
				}
				item.Recalculate_Commission_Payable__c = FALSE;

			}
		}


	}

}