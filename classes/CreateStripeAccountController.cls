public with sharing class CreateStripeAccountController {

	@auraEnabled
	public static String createStripeAccount(String itemId) {

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
		
		Account acc = getAccount(itemId);
		if (acc.Stripe_Account_ID__c != NULL){
			return 'Error! This Stripe Account has already been created.';
		}

		String endpoint = 'callout:PaymentEndpoint/' + ((acc.Stripe_Account_ID__c == null) ? 'createAccount' :  'updateAccount') + '?v=2&gateway=Stripe&' + ((acc.Stripe_Account_ID__c == null) ? '' : '&accountId=' +  acc.Stripe_Account_ID__c);
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
				saveAccount(acc, stripeAccount);
				
				Log__c log = new Log__c(
					Account__c = itemId,
					Action__c = 'Create Franchisee Account',
					Description__c = 'Franchisee Account has been created.',
					Event_Description__c = pr.getUrl() + ' | ' + res.getBody(),
					Event_Status__c = res.getStatus(),
					Event_Type__c = 'Request',
					Type__c = 'INFO'
				);
				insert log;
			} else {
				Log__c log = new Log__c(
					Account__c = itemId,
					Action__c = 'Create Franchisee Account',
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
				Account__c = itemId,
				Action__c = 'Create Franchisee Account',
				Description__c = pr.getUrl() + ' | ' + ex.getMessage(),
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
			Schema.sObjectType.Account.fields.LastName.isAccessible() &&
			Schema.sObjectType.Account.fields.FirstName.isAccessible() &&
			Schema.sObjectType.Account.fields.PersonEmail.isAccessible() &&
			Schema.sObjectType.Account.fields.Stripe_Account_ID__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Stripe_Account_Type__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Stripe_Application_Fee__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Stripe_Country_Support__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Address_Line_1__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Business_Name__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Business_Tax_ID__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Legal_Entity_City__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Date_of_Birth_Day__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Date_of_Birth_Month__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Date_of_Birth_Year__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Legal_Entity_First_Name__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Last_Name__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Postal_Code__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Legal_Entity_State__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Type__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Terms_Of_Service_Acceptance_Date__c.isAccessible() &&
			Schema.sObjectType.Account.fields.Terms_Of_Service_Acceptance_IP__c.isAccessible() &&
			Schema.sObjectType.Account.fields.SSN__c.isAccessible()
		);

		if (isAccessableAccount) {

			List<Account> accountList = [
				SELECT Id, LastName, FirstName, PersonEmail, Stripe_Account_ID__c, Stripe_Account_Type__c, Stripe_Application_Fee__c, Stripe_Country_Support__c,
						Legal_Entity_Address_Line_1__c, Legal_Entity_Business_Name__c, Legal_Entity_Business_Tax_ID__c, Legal_Entity_City__c,
						Legal_Entity_Date_of_Birth_Day__c, Legal_Entity_Date_of_Birth_Month__c, Legal_Entity_Date_of_Birth_Year__c, Legal_Entity_First_Name__c, Legal_Entity_Last_Name__c,
						Legal_Entity_Postal_Code__c, Legal_Entity_State__c, Legal_Entity_Type__c, Terms_Of_Service_Acceptance_Date__c,
						Terms_Of_Service_Acceptance_IP__c, Stripe_Account_Api_Key__c, SSN__c
				FROM Account WHERE Id =: itemId LIMIT 1
			];

			return accountList[0];
		} else {
			throw new System.NoAccessException();
			return null;
		}
	}

	private static void saveAccount(Account account2Update, StripeAccountWrapper stripeAccount) {
		//CRUD and FLS checking
		Boolean isCreateableAccount = (
			Schema.sObjectType.Account.fields.Stripe_Account_ID__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Stripe_Account_ID__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Stripe_Account_Type__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Stripe_Account_Type__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Stripe_Application_Fee__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Stripe_Application_Fee__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Stripe_Country_Support__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Stripe_Country_Support__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Address_Line_1__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Address_Line_1__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Business_Name__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Business_Name__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Business_Tax_ID__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Business_Tax_ID__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_City__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_City__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Date_of_Birth_Day__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Date_of_Birth_Month__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Date_of_Birth_Day__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Date_of_Birth_Year__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Date_of_Birth_Month__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_First_Name__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Date_of_Birth_Year__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Last_Name__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_First_Name__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Postal_Code__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Last_Name__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_State__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Postal_Code__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_State__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Type__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Legal_Entity_Type__c.isUpdateable() &&
			Schema.sObjectType.Account.fields.Terms_Of_Service_Acceptance_Date__c.isCreateable() &&
			Schema.sObjectType.Account.fields.Terms_Of_Service_Acceptance_IP__c.isUpdateable()
		);

		if (isCreateableAccount) {

			account2Update.Stripe_Account_ID__c = stripeAccount.accountId;
			account2Update.Stripe_Account_Type__c = stripeAccount.type;
			account2Update.Stripe_Country_Support__c = stripeAccount.country;
			account2Update.Legal_Entity_Address_Line_1__c = stripeAccount.legalEntityAddress;
			account2Update.Legal_Entity_Business_Name__c = stripeAccount.legalEntityBusinessName;
			account2Update.Legal_Entity_Business_Tax_ID__c = stripeAccount.legalEntityBusinessTaxId;
			account2Update.Legal_Entity_City__c = stripeAccount.legalEntityCity;
			account2Update.Legal_Entity_First_Name__c = stripeAccount.legalEntityFirstName;
			account2Update.Legal_Entity_Last_Name__c = stripeAccount.legalEntityLastName;
			account2Update.Legal_Entity_Postal_Code__c = stripeAccount.legalEntityPostalCode;
			account2Update.Legal_Entity_State__c = stripeAccount.legalEntityState;
			account2Update.Legal_Entity_Type__c = stripeAccount.legalEntityType;
			account2Update.Terms_Of_Service_Acceptance_IP__c = stripeAccount.tosAcceptanceIp;
			account2Update.Stripe_Account_Api_Key__c = stripeAccount.apiKey;
			
			update account2Update;

		} else {
			throw new System.NoAccessException();
		}
	}

	private class StripeAccountWrapper {
		public String accountId { get; set; }
		public String type { get; set; }
		public String country { get; set; }
		public String legalEntityFirstName { get; set; }
		public String legalEntityLastName { get; set; }
		public String legalEntityBusinessName { get; set; }
		public String legalEntityBusinessTaxId { get; set; }
		public String legalEntityType { get; set; }
		public String legalEntityAddress { get; set; }
		public String legalEntityCity { get; set; }
		public String legalEntityPostalCode { get; set; }
		public String legalEntityState { get; set; }
		public String tosAcceptanceIp { get; set; }
		public String apiKey { get; set; }
	}

	private static Map<String, String> getParameters(Account acc) {
		//added SSN for US
		String accountSSN = String.valueOf(acc.SSN__c);
		String accountLast4SSN = (String.isNotEmpty(accountSSN) && accountSSN.length() > 3) ? accountSSN.substring(accountSSN.length()-4) : null;

		return new Map<String, String>{
			'type' => acc.Stripe_Account_Type__c,
			'country' => acc.Stripe_Country_Support__c,
			'email' => acc.PersonEmail,
			'legalEntityFirstName' => acc.Legal_Entity_First_Name__c,
			'legalEntityLastName' => acc.Legal_Entity_Last_Name__c,
			'legalEntityBusinessName' => acc.Legal_Entity_Business_Name__c,
			'legalEntityBusinessTaxId' => acc.Legal_Entity_Business_Tax_ID__c,
			'legalEntityType' => acc.Legal_Entity_Type__c,
			'legalEntityCity' => acc.Legal_Entity_City__c,
			'legalEntityLine1' => acc.Legal_Entity_Address_Line_1__c,
			'legalEntityPostalCode' => acc.Legal_Entity_Postal_Code__c,
			'legalEntityState' => acc.Legal_Entity_State__c,
			'day' => acc.Legal_Entity_Date_of_Birth_Day__c,
			'month' => acc.Legal_Entity_Date_of_Birth_Month__c,
			'year' => acc.Legal_Entity_Date_of_Birth_Year__c,
			'tosAcceptanceDate' => String.valueOf(acc.Terms_Of_Service_Acceptance_Date__c),
			'tosAcceptanceIp' => acc.Terms_Of_Service_Acceptance_IP__c,
			'legalEntityPersonalIdNumber' => accountSSN,
			'legalEntitySsnLast4' => accountLast4SSN,
			'interval' => 'manual'
		};
	}
}