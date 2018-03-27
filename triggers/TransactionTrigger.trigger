trigger TransactionTrigger on Order_Transaction__c (after update, after insert) {

	Set<Id> TransactionsIds = new Set<Id>();
	for (Order_Transaction__c tr : Trigger.new) {
		TransactionsIds.add(tr.Order__c);
	}
	List<Order_Transaction__c> transactions = [
		SELECT Id, Order__c, Response_Status__c
		FROM Order_Transaction__c
		WHERE Order__c IN :TransactionsIds
	];
	Set<Id> orderId = new Set<Id>();
	for (Order_Transaction__c ids : transactions ) {
		orderId.add(ids.Order__c);
	}
	List<Order__c> Orders = [
		SELECT Id, Account__c
		FROM Order__c
		WHERE Id iN : orderId
	];
	Integer Alltransactions = [
		SELECT count()
		FROM Order_Transaction__c
		WHERE Order__c IN: orderId
		AND (
			Response_Status__c = 'refund'
			OR Response_Status__c = 'failed'
		)
	];
	Set<Id> accId = new Set<Id>();
	for (Order__c ids : Orders ) {
		accId.add(Ids.Account__c);
	}

	List<Account> accList = [SELECT Id, Blacklist__c FROM Account WHERE Id IN : accId];

	List<Order__c> ordersToUpdate = new List<Order__c>();

	Set<Id> setAcc = new Set<Id>();
	List<Account> ListAcc = new List<Account>();

	for (Order_Transaction__c trans: transactions) {
		if ('charge back'.equalsIgnoreCase(trans.Response_Status__c)) {
			for (Order__c orderList: Orders) {
				if (orderList.Id == trans.Order__c) {
					ordersToUpdate.add(orderList);
				}
			}
		}

		if ('refund'.equalsIgnoreCase(trans.Response_Status__c) ||
			'failed'.equalsIgnoreCase(trans.Response_Status__c)) {

			for(Order__c orderList: Orders) {
				if (orderList.Id == trans.Order__c && Alltransactions > 2) {
					ordersToUpdate.add(orderList);
				}
			}
		}
	}

	for (Order__c orderTo : ordersToUpdate) {
		for(Account a : accList) {
			if(a.Id == orderTo.Account__c) {
				a.Blacklist__c = 'True';
				if (setAcc.add(a.Id)) {
					ListAcc.add(a);
				}
			}
		}
	}

	if (!ListAcc.isEmpty()) {
		update ListAcc;
	}

	Set<Id> transactionsToPaymentAttempts = new Set<Id>();
	Set<Id> transactionsError = new Set<Id>();
	Set<Id> transactionsApproved = new Set<Id>();

	if (Trigger.isAfter && Trigger.isInsert) {
		for (Order_Transaction__c orderTransaction : Trigger.new) {
			if (orderTransaction.Payment_Attempt__c != null && orderTransaction.Subscription__c == true) {
				transactionsToPaymentAttempts.add(orderTransaction.Payment_Attempt__c);
				if (orderTransaction.Response_Status__c == 'Error') {
					transactionsError.add(orderTransaction.Payment_Attempt__c);
				}
				if (orderTransaction.Response_Status__c == 'Approved') {
					transactionsApproved.add(orderTransaction.Payment_Attempt__c);
				}
			}
		}

		List<Order__c> ordersForUpdated = new List<Order__c>();
		List<Payment_Attempt__c> paymentAttemptsReadyToPayment = new List<Payment_Attempt__c>();

		for (Payment_Attempt__c pA : [SELECT Id, Order__c, Amount__c, Order__r.Shipping_On__c, Order__r.Subscription_Remains_Amount__c, Order__r.Shipping_Status__c, Ready_To_Payment__c, Status__c, Remaining_Retries__c FROM Payment_Attempt__c WHERE Id IN: transactionsToPaymentAttempts]) {
			if (transactionsError.contains(pA.Id)) {
				if (pA.Remaining_Retries__c == 0) {
					pA.Status__c = 'Error';
					ordersForUpdated.add(new Order__c(
						Id = pA.Order__c, Status__c = 'Error'
					));
				}
				else if (pA.Remaining_Retries__c >= 1) {
					pA.Status__c = 'Retry';
					pA.Remaining_Retries__c = pA.Remaining_Retries__c - 1;
				}
			}
			if (transactionsApproved.contains(pA.Id)) {
				pA.Status__c = 'Completed';
				if (pA.Order__r.Shipping_On__c == 'First') {
					if (pA.Order__r.Shipping_Status__c == 'Not Ready') {
						ordersForUpdated.add(new Order__c(
							Id = pA.Order__c, Shipping_Status__c = 'Ready for Shipping'
						));
					}
				}
				else if (pA.Order__r.Shipping_On__c == 'Full Payment') {
					if (pa.Order__r.Subscription_Remains_Amount__c - pA.Amount__c == 0) {
						ordersForUpdated.add(new Order__c(
							Id = pA.Order__c, Shipping_Status__c = 'Ready for Shipping'
						));
					}
				}
			}
			if (pA.Ready_To_Payment__c == false) {
				pA.Ready_To_Payment__c = true;
			}
			paymentAttemptsReadyToPayment.add(pA);
		}

		if (!paymentAttemptsReadyToPayment.isEmpty()) {
			update paymentAttemptsReadyToPayment;
		}
		if (!ordersForUpdated.isEmpty()) {
			update ordersForUpdated;
		}
	}

}