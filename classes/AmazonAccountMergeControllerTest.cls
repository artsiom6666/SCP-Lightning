@isTest
private class AmazonAccountMergeControllerTest
{
	@isTest
	static void itShould()
	{
		Account acc = new Account();
		acc.FirstName = 'testFirst';
		acc.LastName = 'testLast';
		acc.PersonEmail = 'testEmail@test.com';
		acc.ShippingStreet = 'str';
		acc.ShippingPostalCode = '1234';
		acc.ShippingCity = 'city';
		insert acc;

		Account acc1 = new Account();
		acc1.LastName = 'testLast';
		acc1.PersonEmail = 'test@test.com';
		acc1.ShippingStreet = 'Str';
		acc1.ShippingPostalCode = '1234';
		acc1.ShippingCity = 'CITY';
		insert acc1;

		Opportunity testOpportunity = new Opportunity(
			StageName = 'Sourcing Demand',
			CloseDate = Date.today(),
			AccountId = acc1.Id,
			Name = 'Test Opportunity'
		);
		insert testOpportunity;

		ApexPages.StandardController stdAccController = new ApexPages.StandardController(acc);
		AmazonAccountMergeController mergeController  = new AmazonAccountMergeController(stdAccController);

		mergeController.similarAccId = mergeController.mediumProbability[0].Id;

		mergeController.doMerge();

		mergeController.jsonMergedValues = JSON.serialize(mergeController.similarAccFieldsMap);

		mergeController.confirmMerge();

		mergeController.cancel();
		mergeController.cancelMerge();
		mergeController.cancelPopup();
		mergeController.showPopup();

		List<Account> accList = [SELECT ID, PersonEmail FROM Account WHERE Id = :acc.Id OR Id = :acc1.Id];
		System.assertEquals(accList.size(), 1);
		//System.assertEquals(accList[0].PersonEmail, 'test@test.com');

		List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id];
		System.assertEquals(oppList.size(), 1);
	}
}