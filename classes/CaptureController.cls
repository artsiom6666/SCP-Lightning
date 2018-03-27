public with sharing class CaptureController {

	public Id orderTransactionId { get; set; }

	public CaptureController(ApexPages.StandardController stdController) {
		if (Schema.sObjectType.Order_Transaction__c.isAccessible()) {
			orderTransactionId = (Id)stdController.getId();
		}
	}

	public PageReference captureNow() {
		Map<String,Object> result = PaymentProcessor.doPayment(
			new Map<String,Object>{
				'Method' => 'Charge',
				'Transaction' => orderTransactionId
			}
		);

		Boolean isAffiliateEnabled = TouchCRHelper.isAffiliateEnabled();
		String affiliateIdField = TouchCRHelper.isScratchOrg() ? 'Affiliate_Id__c' : ' TouchCRAff__Affiliate_Id__c';
		String affiliateFields = isAffiliateEnabled ? ' ' + affiliateIdField + ',  ' : '';

		String query = ' SELECT Id, ' + affiliateFields + ' Balance_Due__c, Order_Source__c '
						+ ' FROM Order__c ' 
						+ ' WHERE Id IN (SELECT Order__c FROM Order_Transaction__c WHERE Id = :orderTransactionId) ';
		List<Order__c> orderTrList = Database.query(query);

		if (isAffiliateEnabled && !orderTrList.isEmpty() && String.isNotEmpty((Id)orderTrList[0].get(affiliateIdField)) && orderTrList[0].Balance_Due__c == 0) {
			String res = ExtensionsHelperDummy.createCommissionsEarned(orderTrList[0]);
		}

		PageReference redirectPage = new PageReference('/' + result.get('Transaction'));
		redirectPage.setRedirect(true);
		return redirectPage;
	}
}