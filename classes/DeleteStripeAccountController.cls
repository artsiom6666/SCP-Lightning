public with sharing class DeleteStripeAccountController {

	@auraEnabled
	public static String deleteStripeAccount(String itemId) {

		String result;

		List<Map<String, String>> touchcrSettings = TouchCRHelper.getCustomSettings('TouchCRBase__Touchcr_Settings__c');
		List<Map<String, String>> allPaymentAgents = TouchCRHelper.getCustomSettings('TouchCRBase__Payment_Agents__c');

		Map<String, String> touchcrSettingsNameToValue = new Map<String, String>();
		for (Map<String, String> setting : touchcrSettings) {
			touchcrSettingsNameToValue.put(setting.get('Name'), setting.get('TouchCRBase__Value__c'));
		}

		List<Map<String, String>> stripeConnectSettings = TouchCRHelper.getCustomSettings('TouchCRBase__Stripe_Connect__c');
		String paymentAgentId;

		for (Map<String, String> stripeConnectSetting : stripeConnectSettings) {
			paymentAgentId = stripeConnectSetting.get('TouchCRBase__Value__c');
		}

		String securityKeyId;

		for (Map<String, String> setting : allPaymentAgents) {

			if (setting.get('Id') == paymentAgentId) {
				securityKeyId = setting.get('TouchCRBase__Security_Key__c');
				break;
			}
		}

		String endpoint = 'callout:PaymentEndpoint/deleteAccount?v=2&gateway=Stripe';
		if (touchcrSettingsNameToValue.containsKey('Endpoint.ClientId') && touchcrSettingsNameToValue.containsKey('Endpoint.ClientSecret')) {
			endpoint += '&spApiKeyId=' + touchcrSettingsNameToValue.get('Endpoint.ClientId');
			endpoint += '&spApiKeySecret=' + touchcrSettingsNameToValue.get('Endpoint.ClientSecret');
			endpoint += '&securityKeyId=' + securityKeyId;
		}

		PageReference pr = new PageReference(endpoint + '&');

		HttpRequest req = new HttpRequest();
		req.setMethod('GET');

		Account acc = getAccount(itemId);
		if (acc.Stripe_Account_ID__c == NULL){
			return 'There is no Stripe Account to delete.';
		}

		Map<String, String> parameters = getParameters(acc);

		for (String param : parameters.keySet()){
			pr.getParameters().put(param, parameters.get(param));
		}

		req.setEndpoint(pr.getUrl());
		Http http = new Http();

		try {
			HTTPResponse res = http.send(req);
			result = res.getBody();
			if (res.getStatus() == 'OK') {
				saveAccount(acc);

				Log__c log = new Log__c(
					Account__c = itemId,
					Action__c = 'Delete Franchisee Account',
					Description__c = 'Franchisee Account has been deleted.',
					Event_Description__c = res.getBody(),
					Event_Endpoint__c = pr.getUrl(),
					Event_Status__c = res.getStatus(),
					Event_Type__c = 'Request',
					Type__c = 'INFO'
				);
				insert log;
			} else {
				Log__c log = new Log__c(
					Account__c = itemId,
					Action__c = 'Delete Franchisee Account',
					Description__c = res.getStatus(),
					Event_Description__c = res.getBody(),
					Event_Endpoint__c = pr.getUrl(),
					Event_Status__c = String.valueOf(res.getStatusCode()),
					Event_Type__c = 'Request',
					Type__c = 'ERROR'
				);
				insert log;
			}
		}
		catch(Exception ex) {
			Log__c log = new Log__c(
				Account__c = itemId,
				Action__c = 'Delete Franchisee Account',
				Description__c = ex.getMessage(),
				Event_Endpoint__c = pr.getUrl(),
				Event_Type__c = 'Request',
				Type__c = 'ERROR'
			);
			insert log;
			result = ex.getMessage();
		}
		return result;
	}

	private static Account getAccount(String itemId) {
		Account newAccount = new Account();
		RecordType PersonAccount = [SELECT Id, Name FROM RecordType WHERE DeveloperName = 'Franchisee_Account' LIMIT 1];

		//CRUD and FLS checking start
		Boolean isAccessableAccount = (
			Schema.sObjectType.Account.fields.Id.isAccessible() &&
			Schema.sObjectType.Account.fields.Stripe_Account_ID__c.isAccessible()
		);

		if (isAccessableAccount) {

			List<Account> accountList = [
				SELECT Id, Stripe_Account_ID__c
				FROM Account WHERE Id =: itemId LIMIT 1
			];

			return accountList[0];
		} else {
			throw new System.NoAccessException();
			return null;
		}
	}

	private static void saveAccount(Account account2Update) {
		//CRUD and FLS checking
		Boolean isCreateableAccount = (
			Schema.sObjectType.Account.fields.Stripe_Account_ID__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Stripe_Account_ID__c.isUpdateable()
		);

		if (isCreateableAccount) {

			account2Update.Stripe_Account_ID__c = null;
			
			update account2Update;

			//ADDED     Delete Bank_Account_Id__c from all Payout_Bank_Account__c of our updated Account
			Boolean isCreateableBankAccount = (
				Schema.sObjectType.Payout_Bank_Account__c.fields.Bank_Account_Id__c.isCreateable() &&
				Schema.sObjectType.Payout_Bank_Account__c.fields.Bank_Account_Id__c.isUpdateable() &&
				Schema.sObjectType.Payout_Bank_Account__c.fields.Default_Bank__c.isCreateable() &&
				Schema.sObjectType.Payout_Bank_Account__c.fields.Default_Bank__c.isUpdateable()
			);

			if (isCreateableBankAccount) {
					List<Payout_Bank_Account__c> accountPayoutBanks = [SELECT Id, Bank_Account_Id__c, Default_Bank__c FROM Payout_Bank_Account__c WHERE Account__c =:account2Update.id];
					for (Payout_Bank_Account__c bank : accountPayoutBanks) {
						bank.Bank_Account_Id__c = null;
						bank.Default_Bank__c = false;
					}
					update accountPayoutBanks;
			}
			//ADDED     Delete Bank_Account_Id__c from all Payout_Bank_Account__c of our updated Account


		} else {
			throw new System.NoAccessException();
		}
	}

	private static Map<String, String> getParameters(Account acc) {
		return new Map<String, String>{
			'accountId' => acc.Stripe_Account_ID__c
		};
	}
}