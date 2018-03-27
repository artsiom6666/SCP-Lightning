public with sharing class ChargeController {

	public Order__c order { get; set; }

	public ChargeController(ApexPages.StandardController stdController) {
		if (Schema.sObjectType.Order__c.isAccessible()) {
			order = (Order__c)stdController.getRecord();
		}
	}

	public PageReference chargeOrder() {
		Map<String,Object> result = PaymentProcessor.doPayment(
			new Map<String,Object>{
				'Method' => 'Charge',
				'OrderId' => order.Id
			}
		);
		String orderId = order.Id;
		Boolean isAffiliateEnabled = TouchCRHelper.isAffiliateEnabled();
		String affiliateIdField = TouchCRHelper.isScratchOrg() ? 'Affiliate_Id__c' : ' TouchCRAff__Affiliate_Id__c';
		String affiliateFields = isAffiliateEnabled ? ' , ' + affiliateIdField + ' ' : '';
		String query = ' SELECT Id, Balance_Due__c, Order_Source__c ' + affiliateFields + ' FROM Order__c WHERE Id = :orderId ';
		List<Order__c> orderList = Database.query(query);

		if (isAffiliateEnabled && !orderList.isEmpty() && String.isNotEmpty((Id)orderList[0].get(affiliateIdField)) && orderList[0].Balance_Due__c == 0) {
			String res = ExtensionsHelperDummy.createCommissionsEarned(orderList[0]);
		}
		
		PageReference redirectPage = new PageReference('/' + result.get('Transaction'));
		redirectPage.setRedirect(true);
		return redirectPage;
	}

	private Void createCommissionEarned () {
		String result = ExtensionsHelperDummy.createCommissionsEarned(order);
	}

}