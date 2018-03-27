public with sharing class CreateBankTransferController {
	private static Map<String, String> touchcrSettingsNameToValue;
	private static String securityKeyId;

	@auraEnabled
	public static String getBalance(String itemId, Boolean beforePayout) {

		getSettings();

		String result;

		Bank_Transfer__c transfer = getBankTransfer(itemId);

		if (transfer.Transfer_Id__c != NULL && beforePayout){
			return 'Error! This transfer was already paid out. Please create new Bank trasfer.';
		}

		String endpoint = setApiKeys('callout:PaymentEndpoint/getAccountsBalance?v=2&gateway=Stripe');
		endpoint = setBalanceParameters(endpoint, transfer);

		try {
			HTTPResponse res = sendRequest(endpoint);

			if (res.getStatus() == 'OK' && !res.getBody().contains('error')) {

				StripeBalanceWrapper balance =
						(StripeBalanceWrapper)JSON.deserialize(res.getBody(), StripeBalanceWrapper.class);

				BalanceWrapper balance2Display = new BalanceWrapper();
				balance2Display.availableAmount = Decimal.valueOf(balance.availableAmount) / 100;
				balance2Display.pendingAmount = Decimal.valueOf(balance.pendingAmount) / 100;
				balance2Display.transferAmount = transfer.Transfer_Amount__c;
				result = JSON.serialize(balance2Display);

				saveAccount(transfer.Account__r.Id, balance2Display);
			}
		}
		catch(Exception ex) {
			Log__c log = new Log__c(
				Account__c = transfer.Account__r.Id,
				Action__c = 'Get Account Balance',
				Description__c = ex.getMessage(),
				Event_Type__c = 'Request',
				Type__c = 'ERROR'
			);
			insert log;
			result = ex.getMessage();
		}
		return result;
	}

	@auraEnabled
	public static String createBankTransfer(String itemId, Decimal transferAmount) {
		
		getSettings();

		String result;

		Bank_Transfer__c transfer = getBankTransfer(itemId);

		String endpoint = setApiKeys('callout:PaymentEndpoint/createBankTransfer?v=2&gateway=Stripe');
		endpoint = setTransferParameters(endpoint, transfer, transferAmount);

		try {
			HTTPResponse res = sendRequest(endpoint);

			result = res.getBody();

			if (res.getStatus() == 'OK' && !res.getBody().contains('error')) {

				StripeTransferWrapper stripeAccount =
						(StripeTransferWrapper)JSON.deserialize(res.getBody(), StripeTransferWrapper.class);

				saveBankTransfer(transfer, stripeAccount, transferAmount);
				// Lock the Bank Transfer record
				Approval.lock(transfer, false);

				Log__c log = new Log__c(
					Account__c = transfer.Account__r.Id,
					Action__c = 'Create Bank Transfer',
					Description__c = 'Create Bank Transfer has been created.',
					Event_Description__c = res.getBody(),
					Event_Status__c = res.getStatus(),
					Event_Type__c = 'Request',
					Type__c = 'INFO'
				);
				insert log;
			} else {
				Log__c log = new Log__c(
					Account__c = transfer.Account__r.Id,
					Action__c = 'Create Bank Transfer',
					Description__c = res.getStatus(),
					Event_Description__c = res.getBody(),
					Event_Status__c = String.valueOf(res.getStatusCode()),
					Event_Type__c = 'Request',
					Type__c = 'ERROR'
				);
				insert log;
			}
		}
		catch(Exception ex) {
			Log__c log = new Log__c(
				Account__c = transfer.Account__r.Id,
				Action__c = 'Create Bank Transfer',
				Description__c = ex.getMessage(),
				Event_Type__c = 'Request',
				Type__c = 'ERROR'
			);
			insert log;
			result = ex.getMessage();
		}
		return result;
	}

	private static void getSettings() {

		List<Map<String, String>> touchcrSettings = TouchCRHelper.getCustomSettings('TouchCRBase__Touchcr_Settings__c');
		List<Map<String, String>> allPaymentAgents = TouchCRHelper.getCustomSettings('TouchCRBase__Payment_Agents__c');

		touchcrSettingsNameToValue = new Map<String, String>();

		for (Map<String, String> setting : touchcrSettings) {
			touchcrSettingsNameToValue.put(setting.get('Name'), setting.get('TouchCRBase__Value__c'));
		}

		List<Map<String, String>> stripeConnectSettings = TouchCRHelper.getCustomSettings('TouchCRBase__Stripe_Connect__c');
		String paymentAgentId;

		for (Map<String, String> stripeConnectSetting : stripeConnectSettings) {
			paymentAgentId = stripeConnectSetting.get('TouchCRBase__Value__c');

		}

		for (Map<String, String> setting : allPaymentAgents) {

			if (setting.get('Id') == paymentAgentId) {
				securityKeyId = setting.get('TouchCRBase__Security_Key__c');
				break;
			}
		}
	}

	private static String setApiKeys(String endpoint) {

		if (touchcrSettingsNameToValue.containsKey('Endpoint.ClientId') && touchcrSettingsNameToValue.containsKey('Endpoint.ClientSecret')) {
			endpoint += '&spApiKeyId=' + touchcrSettingsNameToValue.get('Endpoint.ClientId');
			endpoint += '&spApiKeySecret=' + touchcrSettingsNameToValue.get('Endpoint.ClientSecret');
			endpoint += '&securityKeyId=' + securityKeyId;
		}

		return endpoint;
	}

	private static Bank_Transfer__c getBankTransfer(String itemId) {

		List<Bank_Transfer__c> accountBankList = [
			SELECT Id, Account__r.Stripe_Account_Api_Key__c, Account__r.Id, Account__r.Stripe_Account_ID__c, Payout_Bank_Account__r.Bank_Account_Id__c,
				Payout_Bank_Account__r.Bank_Currency__c, Transfer_Amount__c, Transfer_Date_Time__c, Transfer_Id__c
			FROM Bank_Transfer__c WHERE Id =: itemId LIMIT 1
		];

		return accountBankList[0];
	}

	private static void saveBankTransfer(Bank_Transfer__c transfer2Update, StripeTransferWrapper transfer, Decimal transferAmount) {
		transfer2Update.Transfer_Id__c = transfer.transferId;
		transfer2Update.Transfer_Date_Time__c = Datetime.now();
		transfer2Update.Transfer_Amount__c = transferAmount;
		
		update transfer2Update;
	}

	private static void saveAccount(String accountId, BalanceWrapper balance) {
		Account acc2Update = new Account(
			Id = accountId,
			Available_Balance__c = balance.availableAmount,
			Pending_Balance__c = balance.pendingAmount
		);
		
		update acc2Update;
	}

	private static String setTransferParameters(String endpoint, Bank_Transfer__c transfer, Decimal transferAmount) {
		Map<String, String> parameters = new Map<String, String>{
			'bankAccountId' => transfer.Payout_Bank_Account__r.Bank_Account_Id__c,
			'amount' => String.valueOf(transferAmount),
			'securityKeyId' => transfer.Account__r.Stripe_Account_Api_Key__c,
			'currencyCode' => transfer.Payout_Bank_Account__r.Bank_Currency__c
		};

		return putParameters(endpoint, parameters);
	}

	private static String setBalanceParameters(String endpoint, Bank_Transfer__c transfer) {
		Map<String, String> parameters = new Map<String, String>{
			'accountId' => transfer.Account__r.Stripe_Account_ID__c
		};

		return putParameters(endpoint, parameters);
	}

	private static String putParameters(String endpoint, Map<String, String> parameters) {
		PageReference pr = new PageReference(endpoint + '&');

		for (String param : parameters.keySet()){
			pr.getParameters().put(param, parameters.get(param));
		}

		return pr.getUrl();
	}

	private static HTTPResponse sendRequest(String endpoint) {
		HttpRequest req = new HttpRequest();
		req.setTimeout(120000);
		req.setMethod('GET');
		req.setEndpoint(endpoint);

		Http http = new Http();

		return http.send(req);
	}

	private class BalanceWrapper {
		public Decimal availableAmount { get; set; }
		public Decimal pendingAmount { get; set; }
		public Decimal transferAmount { get; set; }
	}

	private class StripeBalanceWrapper {
		public String availableAmount { get; set; }
		public String pendingAmount { get; set; }
	}

	private class StripeTransferWrapper {
		public String transferId { get; set; }
	}

}