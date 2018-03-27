public with sharing class AmazonFindMergeableAccounts implements Database.Batchable<sObject> {
	
	String query;
	
	public AmazonFindMergeableAccounts() {
		
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {

		String scpProp = TouchCRHelper.isSCPEnabled() == TRUE ? ',BillingCountryCode, BillingStateCode, ShippingCountryCode, ShippingStateCode' : '';
		query = 'SELECT Id, isMergeable__c, FirstName, LastName, Original_Country__c, Original_State__c, ' +
						+ 'BillingStreet, BillingCity, BillingPostalCode,  ShippingStreet, ' +
						+ 'ShippingCity, ShippingPostalCode '+ scpProp +
				+ ' FROM Account WHERE isMergeable__c = false AND AmazonAccountId__c != null';

		return Database.getQueryLocator(query);
	}

	//every batch execute should take 1 account and try to find similar accounts in database
	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		if (!scope.isEmpty()) {
			Account mergeAcc = (Account)scope.get(0);

			String fname = mergeAcc.FirstName, lname = mergeAcc.LastName, 
				shipCountryCode = '', billCountryCode = '',
				shipStateCode = '', billStateCode = '',
				scpProp = '', helpChar = '', scpBilProp = '', scpShipProp = '',
				origCountry = mergeAcc.Original_Country__c, origState = mergeAcc.Original_State__c, 
				shipStreet = mergeAcc.ShippingStreet, billStreet = mergeAcc.BillingStreet, 
				shipCity = mergeAcc.ShippingCity, billCity = mergeAcc.BillingCity,
				shipPostalCode = mergeAcc.ShippingPostalCode, billPostalCode = mergeAcc.BillingPostalCode;
			if (TouchCRHelper.isSCPEnabled() == TRUE) {
				billCountryCode = String.valueOf(mergeAcc.get('BillingCountryCode'));
				shipStateCode = String.valueOf(mergeAcc.get('ShippingStateCode'));
				billStateCode = String.valueOf(mergeAcc.get('BillingStateCode'));
				shipCountryCode = String.valueOf(mergeAcc.get('ShippingCountryCode'));
				scpBilProp = '(BillingCountryCode LIKE :billCountryCode ' +
					'AND BillingStateCode LIKE :billStateCode) ' + 
					'OR (';
				scpShipProp = '(ShippingCountryCode LIKE :shipCountryCode ' +
					'AND ShippingStateCode LIKE :shipStateCode) ' + 
					'OR (';
				helpChar = ')';

			}

			String queryStrHigh = 'SELECT Id FROM Account ' +
				'WHERE ( FirstName LIKE :fname ' +
				'OR LastName LIKE :lname) ' +

				'AND (' + 
				scpBilProp +
				'Original_Country__c LIKE :origCountry ' +
				'AND Original_State__c LIKE :origState) ' + 
				helpChar + 

				'AND (BillingStreet LIKE :billStreet ' +
				'OR BillingCity LIKE :billCity ' + 
				'OR BillingPostalCode LIKE :billPostalCode) ' +
				'AND Id != \'' + mergeAcc.Id + '\' LIMIT 5';

			String queryStrMedium = 'SELECT Id FROM Account ' +
				'WHERE ( FirstName LIKE :fname ' +
				'OR LastName LIKE :lname) ' +
				
				'AND (' + 
				scpShipProp +
				'Original_Country__c LIKE :origCountry ' +
				'AND Original_State__c LIKE :origState) ' + 
				helpChar + 
				
				'AND (ShippingStreet LIKE :shipStreet ' +
				'OR ShippingCity LIKE :shipCity ' + 
				'OR ShippingPostalCode LIKE :shipPostalCode) ' +
				'AND Id != \'' + mergeAcc.Id + '\' LIMIT 5';

			List<Account> mergeableHigh = Database.query(queryStrHigh);
			List<Account> mergeableMedium = Database.query(queryStrMedium);

			if (mergeableHigh.size() != 0 || mergeableMedium.size() != 0) {
				mergeAcc.isMergeable__c = true;
				Boolean isUpdateableAccount = false;

				if (TouchCRHelper.isSCPEnabled() == TRUE) {
					isUpdateableAccount = (
					
					Account.FirstName.getDescribe().isUpdateable() &&
					Account.LastName.getDescribe().isUpdateable() &&
					Schema.sObjectType.Account.fields.getMap().get('BillingCountryCode').getDescribe().isUpdateable() &&
					Schema.sObjectType.Account.fields.getMap().get('BillingStateCode').getDescribe().isUpdateable() &&
					Account.Original_Country__c.getDescribe().isUpdateable() &&
					Account.Original_State__c.getDescribe().isUpdateable() &&
					Account.BillingStreet.getDescribe().isUpdateable() &&
					Account.BillingCity.getDescribe().isUpdateable() &&
					Account.BillingPostalCode.getDescribe().isUpdateable() &&
					Schema.sObjectType.Account.fields.getMap().get('ShippingCountryCode').getDescribe().isUpdateable() &&
					Schema.sObjectType.Account.fields.getMap().get('ShippingStateCode').getDescribe().isUpdateable() &&
					Account.ShippingStreet.getDescribe().isUpdateable() &&
					Account.ShippingCity.getDescribe().isUpdateable() &&
					Account.ShippingPostalCode.getDescribe().isUpdateable() &&
					Account.isMergeable__c.getDescribe().isUpdateable()
					);
				}else {
					isUpdateableAccount = (
					
					Account.FirstName.getDescribe().isUpdateable() &&
					Account.LastName.getDescribe().isUpdateable() &&
					Account.Original_Country__c.getDescribe().isUpdateable() &&
					Account.Original_State__c.getDescribe().isUpdateable() &&
					Account.BillingStreet.getDescribe().isUpdateable() &&
					Account.BillingCity.getDescribe().isUpdateable() &&
					Account.BillingPostalCode.getDescribe().isUpdateable() &&
					Account.ShippingStreet.getDescribe().isUpdateable() &&
					Account.ShippingCity.getDescribe().isUpdateable() &&
					Account.ShippingPostalCode.getDescribe().isUpdateable() &&
					Account.isMergeable__c.getDescribe().isUpdateable()
					);

				}


				if (isUpdateableAccount) {
					Database.update(mergeAcc, false);
				}
			}
		}
	}
	
	public void finish(Database.BatchableContext BC) {
		
	}
}