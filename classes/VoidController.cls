public with sharing class VoidController {

	public Id orderTransactionId { get; set; }

	public VoidController(ApexPages.StandardController stdController) {
		if (Schema.sObjectType.Order_Transaction__c.isAccessible()) {
			orderTransactionId = (Id)stdController.getId();
		}
	}

	public PageReference voidTransactionNow() {
		Map<String,Object> result = PaymentProcessor.doPayment(
			new Map<String,Object>{
				'Method' => 'Void',
				'Transaction' => orderTransactionId
			}
		);

		Id transactionId = (Id)result.get('Transaction');

		List<Order_Transaction__c> currentTransaction = [
			SELECT Id, Order__c, Response_Status__c, Type__c
			FROM Order_Transaction__c
			WHERE Id = :transactionId
		];

		if (!currentTransaction.isEmpty() && currentTransaction[0].Response_Status__c == 'Approved' && currentTransaction[0].Type__c == 'Void') {
			ExtensionsHelperDummy.createRefundCommissionsEarned(currentTransaction[0].Order__c);
		}

		PageReference redirectPage = new PageReference('/' + result.get('Transaction'));
		redirectPage.setRedirect(true);
		return redirectPage;
	}

}