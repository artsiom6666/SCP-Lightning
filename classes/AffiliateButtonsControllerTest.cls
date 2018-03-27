@isTest
private class AffiliateButtonsControllerTest {
	
	@isTest
	static void setAffiliateFrozenUnFrozenTest() {
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];
		Account accA = new Account(RecordTypeId = customerRecordType.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', Affiliate_Approval__c = 'Approved');
		insert accA;

		ApexPages.StandardController sc = new ApexPages.standardController(accA);
		AffiliateButtonsController ext = new AffiliateButtonsController(sc);
		ext.setAffiliateFrozen();
 		System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Affiliate_Approval__c = 'Frozen']);
		sc = new ApexPages.standardController(accA);
		ext = new AffiliateButtonsController(sc);
		ext.setAffiliateUnFrozen();
		ext.postToAffiliateAPI();
		System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Affiliate_Approval__c = 'Approved']);
	}

	@isTest
	static void approveAccountToAffiliateTest() {
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];
		Account accA = new Account(RecordTypeId = customerRecordType.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', Company_Name__c = 'testCompany', Affiliate_Approval__c = 'Approved');
		Account accB = new Account(RecordTypeId = customerRecordType.Id, LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', Company_Name__c = 'testCompany', Affiliate_Approval__c = 'Waiting for Approval');
		insert new List<Account> {accA, accB};
		ApexPages.StandardController sc = new ApexPages.standardController(accB);
		AffiliateButtonsController ext = new AffiliateButtonsController(sc);

		ext.approveAccountToAffiliate();
		System.assertEquals(2, [SELECT COUNT() FROM Account WHERE Affiliate_Approval__c = 'Approved']);
	}
}