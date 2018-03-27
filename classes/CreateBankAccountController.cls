public with sharing class CreateBankAccountController {

	
	@auraEnabled
	public static String createStripeBankAccount(String itemId) {

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

		HttpRequest req = new HttpRequest();
		req.setTimeout(120000);
		req.setMethod('GET');
		
		Payout_Bank_Account__c acc = getBankAccount(itemId);

		if (acc.Bank_Account_Id__c != NULL){
			return 'Error! This Bank Account has already been created. Please create new Payout Bank Account record.';
		}

		String endpoint = 'callout:PaymentEndpoint/createExternalAccount?v=2&gateway=Stripe';
		if (touchcrSettingsNameToValue.containsKey('Endpoint.ClientId') && touchcrSettingsNameToValue.containsKey('Endpoint.ClientSecret')) {
			endpoint += '&spApiKeyId=' + touchcrSettingsNameToValue.get('Endpoint.ClientId');
			endpoint += '&spApiKeySecret=' + touchcrSettingsNameToValue.get('Endpoint.ClientSecret');
			endpoint += '&securityKeyId=' + securityKeyId;
		}

		PageReference pr = new PageReference(endpoint + '&');
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
				StripeAccountWrapper stripeAccount = (StripeAccountWrapper)JSON.deserialize(res.getBody(), StripeAccountWrapper.class);
				saveBankAccount(acc, stripeAccount);
				// Lock the Bank Account record
				Approval.lock(acc, false);

				Log__c log = new Log__c(
					Account__c = acc.Account__r.Id,
					Action__c = 'Create Bank Account',
					Description__c = 'Bank Account has been created.',
					Event_Description__c = pr.getUrl() + ' | ' + res.getBody(),
					Event_Status__c = res.getStatus(),
					Event_Type__c = 'Request',
					Type__c = 'INFO'
				);
				insert log;
			} else {
				Log__c log = new Log__c(
					Account__c = acc.Account__r.Id,
					Action__c = 'Create Bank Account',
					Description__c = res.getStatus(),
					Event_Description__c = pr.getUrl() + ' | ' + res.getBody(),
					Event_Status__c = String.valueOf(res.getStatusCode()),
					Event_Type__c = 'Request',
					Type__c = 'ERROR'
				);
				insert log;
			}
		}
		catch(Exception ex) {
			Log__c log = new Log__c(
				Account__c = acc.Account__r.Id,
				Action__c = 'Create Bank Account',
				Description__c = pr.getUrl() + ' | ' + ex.getMessage(),
				Event_Type__c = 'Request',
				Type__c = 'ERROR'
			);
			insert log;
			result = ex.getMessage();
		}
		System.debug(result);
		return result;
	}

	private static Payout_Bank_Account__c getBankAccount(String itemId) {

		List<Payout_Bank_Account__c> accountBankList = [
			SELECT Id, Account__r.Stripe_Account_ID__c, Account__r.Id, Account_Holder_Name__c, Account_Holder_Type__c, Bank_Account_Number__c, Bank_Country__c, Bank_Currency__c, Bank_Name__c, BSB_Routing_Number__c,
					Verification_Status__c, Bank_Account_Id__c
			FROM Payout_Bank_Account__c WHERE Id =: itemId LIMIT 1
		];

		return accountBankList[0];
	}

	private static void saveBankAccount(Payout_Bank_Account__c account2Update, StripeAccountWrapper stripeAccount) {

		account2Update.Bank_Account_Id__c = stripeAccount.bankAccountId;
		account2Update.Bank_Name__c = stripeAccount.externalAccountBankName;
		account2Update.Verification_Status__c = stripeAccount.externalAccountRoutingStatus;
		
		update account2Update;
	}

	private class StripeAccountWrapper {
		public String bankAccountId { get; set; }
		public String externalAccountBankName { get; set; }
		public String externalAccountRoutingStatus { get; set; }
	}

	private static Map<String, String> getParameters(Payout_Bank_Account__c acc) {
		return new Map<String, String>{
			'accountId' => acc.Account__r.Stripe_Account_ID__c,
			'externalAccountObject' => 'bank_account',
			'externalAccountNumber' => acc.Bank_Account_Number__c,
			'externalAccountCountry' => acc.Bank_Country__c,
			'externalAccountCurrency' => acc.Bank_Currency__c,
			'externalAccountHolderName' => acc.Account_Holder_Name__c,
			'externalAccountHolderType' => acc.Account_Holder_Type__c,
			'externalAccountRoutingNumber' => acc.BSB_Routing_Number__c
		};
	}
}