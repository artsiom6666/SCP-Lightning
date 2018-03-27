@isTest
global class StripeConnectMock implements HttpCalloutMock{

	protected Integer code;
	protected String status;
	protected String body;
	protected Map<String, String> responseHeaders;

	private static final Integer DEFAULT_CODE = 200;
	private static final String DEFAULT_STATUS = 'OK';
	private static final String DEFAULT_BODY = '';
	private static final Map<String, String> DEFAULT_HEADERS = new Map<String, String>{'Content-Type:' => 'application/json'};

	global StripeConnectMock(Integer code, String status, String body, Map<String, String> responseHeaders) {
		this.code = code;
		this.status = status;
		this.body = body;
		this.responseHeaders = responseHeaders;
	}

	global StripeConnectMock(Integer code, String status, String body) {
		this(code, status, body, DEFAULT_HEADERS);
	}

	global StripeConnectMock(String body) {
		this(DEFAULT_CODE, DEFAULT_STATUS, body, DEFAULT_HEADERS);
	}

	global StripeConnectMock() {
		this(DEFAULT_CODE, DEFAULT_STATUS, DEFAULT_BODY, DEFAULT_HEADERS);
	}

	global StripeConnectMock(String param, Boolean defaultMode) {
		String body;
		if (!defaultMode) {
			if (param == 'createStripeBankAccount') {
				body = '{"bankAccountId":"ba_1BJNUJGhCH1rGkTK0WdXskxW","externalAccountBankName":"STRIPE TEST BANK","externalAccountObject":"bank_account","externalAccountNumber":"1116","externalAccountCountry":"AU","externalAccountCurrency":"aud","externalAccountHolderName":"Sergey Banc Acc","externalAccountHolderType":null,"externalAccountRoutingNumber":"11 0000","externalAccountRoutingStatus":"new","original":{"id":"ba_1BJNUJGhCH1rGkTK0WdXskxW","object":"bank_account","account":"acct_1BJJlkGhCH1rGkTK","account_holder_name":"Sergey Banc Acc","account_holder_type":null,"bank_name":"STRIPE TEST BANK","country":"AU","currency":"aud","default_for_currency":false,"fingerprint":"72aYAWRk3Zx1iGBc","last4":"1116","metadata":{},"routing_number":"11 0000","status":"new"}}';        
			} 
			else if (param == 'createStripeAccount') {
				body = '{"accountId":"acct_1BJM4lDGNuAF7VQI","type":"custom","country":"AU","legalEntityFirstName":"Test","legalEntityLastName":"Test","legalEntityBusinessName":"Aaron JarvisUpdated","legalEntityBusinessTaxId":true,"legalEntityType":"individual","legalEntityAddress":"Canal St.","legalEntityCity":"Sydney","legalEntityPostalCode":"2263","legalEntityState":"New South Wales","legalEntityBirthdayDay":4,"legalEntityBirthdayMonth":10,"legalEntityBirthdayYear":1994,"tosAcceptanceDate":1506988800,"tosAcceptanceIp":"93.84.39.145","original":{"id":"acct_1BJM4lDGNuAF7VQI","object":"account","business_logo":null,"business_name":"Aaron JarvisUpdated","business_url":null,"charges_enabled":true,"country":"AU","debit_negative_balances":false,"decline_charge_on":{"avs_failure":false,"cvc_failure":false},"default_currency":"aud","details_submitted":false,"display_name":null,"email":"charmhaven@homeicecream.com.example","external_accounts":{"object":"list","data":[],"has_more":false,"total_count":0,"url":"/v1/accounts/acct_1BJM4lDGNuAF7VQI/external_accounts"},"keys":{"secret":"sk_test_CkwU2cjcXIFp7KG51LZEqKar","publishable":"pk_test_hh2iPn5SXQPaVa6bJHuuVxoT"},"legal_entity":{"additional_owners":[],"address":{"city":"Sydney","country":"AU","line1":"Canal St.","line2":null,"postal_code":"2263","state":"New South Wales"},"business_name":"Aaron JarvisUpdated","business_tax_id_provided":true,"dob":{"day":4,"month":10,"year":1994},"first_name":"Test","last_name":"Test","personal_address":{"city":null,"country":"AU","line1":null,"line2":null,"postal_code":null,"state":null},"type":"individual","verification":{"details":null,"details_code":null,"document":null,"status":"unverified"}},"metadata":{},"payout_schedule":{"delay_days":2,"interval":"daily"},"payout_statement_descriptor":null,"payouts_enabled":false,"product_description":null,"statement_descriptor":"","support_email":null,"support_phone":null,"timezone":"Etc/UTC","tos_acceptance":{"date":1506988800,"ip":"93.84.39.145","user_agent":null},"type":"custom","verification":{"disabled_reason":null,"due_by":null,"fields_needed":["external_account","legal_entity.verification.document"]}}}';
			}
			else if (param == 'deleteStripeAccount'){
				body = '{"original":{"deleted":true,"id":"acct_1BGyODF70uPagwLl"}}';
			}
			else if (param == 'createBankTransfer') {
				body='{"transferId":"someId","origin":{"id":"po_1B5FQSBtLSRuiG8TXBmwB1G1","object":"payout","amount":5493,"arrival_date":1506297600,"balance_transaction":"txn_1BJIIhBtLSRuiG8T0zqzKHAg","created":1506180016,"currency":"aud","description":"STRIPE TRANSFER","destination":"ba_1ArK8ABtLSRuiG8TvI9oxUdT","failure_balance_transaction":null,"failure_code":null,"failure_message":null,"livemode":false,"metadata":{},"method":"standard","source_type":"card","statement_descriptor":null,"status":"paid","type":"bank_account"}}';
			}
			else if (param == 'verifyStripeAccount') {
				body='{"accountId":"acct_1BJM4lDGNuAF7VQI","type":"custom","country":"AU","legalEntityFirstName":"Test","legalEntityLastName":"Test","legalEntityBusinessName":"Aaron JarvisUpdated","legalEntityBusinessTaxId":true,"legalEntityType":"individual","legalEntityAddress":"Canal St.","legalEntityCity":"Sydney","legalEntityPostalCode":"2263","legalEntityState":"New South Wales","legalEntityBirthdayDay":4,"legalEntityBirthdayMonth":10,"legalEntityBirthdayYear":1994,"tosAcceptanceDate":1506988800,"tosAcceptanceIp":"93.84.39.145","original":{"id":"acct_1BJM4lDGNuAF7VQI","object":"account","business_logo":null,"business_name":"Aaron JarvisUpdated","business_url":null,"charges_enabled":true,"country":"AU","debit_negative_balances":false,"decline_charge_on":{"avs_failure":false,"cvc_failure":false},"default_currency":"aud","details_submitted":false,"display_name":null,"email":"charmhaven@homeicecream.com.example","external_accounts":{"object":"list","data":[],"has_more":false,"total_count":0,"url":"/v1/accounts/acct_1BJM4lDGNuAF7VQI/external_accounts"},"keys":{"secret":"sk_test_CkwU2cjcXIFp7KG51LZEqKar","publishable":"pk_test_hh2iPn5SXQPaVa6bJHuuVxoT"},"legal_entity":{"additional_owners":[],"address":{"city":"Sydney","country":"AU","line1":"Canal St.","line2":null,"postal_code":"2263","state":"New South Wales"},"business_name":"Aaron JarvisUpdated","business_tax_id_provided":true,"dob":{"day":4,"month":10,"year":1994},"first_name":"Test","last_name":"Test","personal_address":{"city":null,"country":"AU","line1":null,"line2":null,"postal_code":null,"state":null},"type":"individual","verification":{"details":null,"details_code":null,"document":null,"status":"unverified"}},"metadata":{},"payout_schedule":{"delay_days":2,"interval":"daily"},"payout_statement_descriptor":null,"payouts_enabled":false,"product_description":null,"statement_descriptor":"","support_email":null,"support_phone":null,"timezone":"Etc/UTC","tos_acceptance":{"date":1506988800,"ip":"93.84.39.145","user_agent":null},"type":"custom","verification":{"details":null,"details_code":null,"document":"file_1BUAOZBtLSRuiG8TdkaUMygj","status":"verified"}}}';
			}
			else if (param == 'getBalance') {
				body='{"availableAmount":"590","pendingAmount":"2647","origin":{"object": "balance","available": [{"currency": "aud","amount": 590,"source_types": {"card": 590}}],"connect_reserved": [{"currency": "aud","amount": 0}],"livemode": false,"pending": [{"currency": "aud","amount": 2647,"source_types": {"card": 2647}}]}}';
			}
			else {
				body = '';
			}
		}
		this.code = DEFAULT_CODE;
		this.status = DEFAULT_STATUS;
		this.body = body;
		this.responseHeaders = DEFAULT_HEADERS;
	}

	global HTTPResponse respond(HTTPRequest req) {
		HttpResponse res = new HttpResponse();

		if (this.status == 'Exception') {
			calloutException e = (CalloutException)CalloutException.class.newInstance();
			e.setMessage(this.body);
			throw e;
		}

		for (String key : this.responseHeaders.keySet()) {
			res.setHeader(key, this.responseHeaders.get(key));
		}

		res.setBody(this.body);
		res.setStatusCode(this.code);
		res.setStatus(this.status);
		return res;
	}
}