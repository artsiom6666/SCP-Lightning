public with sharing class ShopifyShoppingAPIClient {

	public Static String products{ get;set; }
	public Static String orders{ get;set; }

	/*
	This is used to retrieve customers
	*/
	public static String get_customers() {
		Map<String, String> shopifyLimit = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
		String sinceId = shopifyLimit.containsKey('Shopify.lastCustomerExternalID') ? shopifyLimit.get('Shopify.lastCustomerExternalID') : '1';
		return make_api_call('', 'customers', sinceId);
	}

	/*
	This is used to retrieve all products
	*/
	public static String get_products() {
		Map<String, String> shopifyLimit = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
		String APIMode = shopifyLimit.containsKey('Shopify.APIMode') ? shopifyLimit.get('Shopify.APIMode') : '0';
		if (APIMode == '0') {
			String sinceId = shopifyLimit.containsKey('Shopify.lastProductExternalID') ? shopifyLimit.get('Shopify.lastProductExternalID') : '1';
			products = make_api_call( '', 'products', sinceId);
			TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.APIMode' => '1' });
		}
		else {
			products = make_api_call_by_date( '', 'products', '');
			TouchCRBase.TouchCRHelper.setSettings(new Map<String, String> {'Shopify.APIMode' => '0' });
		}

		return products;
	}

	/*
	This is used to retrieve All orders
	*/
	public static String get_orders() {
		Map<String, String> shopifySettings = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
		String sinceId = shopifySettings.containsKey('Shopify.lastOrderExternalID') ? shopifySettings.get('Shopify.lastOrderExternalID') : '1';
		orders = make_api_call( '', 'orders', sinceId);
		return orders;
	}

	/*
	This is used to make api call
	$param      -This is used to pass id.
	$endpoint   - This is used to redirect page to particular endpoint like orders,products.etc.
	*/
	public static String make_api_call(String param, String endpoint, String conditions){

		String result;
		Map<String, String> ShopifySettings = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
		String apikey = ShopifySettings.containsKey('Shopify.ApiKey') ? ShopifySettings.get('Shopify.ApiKey') : 'test';
		String api_url = ShopifySettings.containsKey('Shopify.ApiURL') ? ShopifySettings.get('Shopify.ApiURL') : 'https://test.myshopify.com';
		String password = ShopifySettings.containsKey('Shopify.Password') ? ShopifySettings.get('Shopify.Password') : 'test';
		String namedCredential = ShopifySettings.containsKey('Shopify.Credential') ? ShopifySettings.get('Shopify.Credential') : 'test';

		String url;
		if (param != '') {
			url = '/admin/' + endpoint + '/' + param + '.json';
		}
		else if (conditions != '0') {
			String page = conditions;
			if (endpoint == 'orders') {
				url = '/admin/' + endpoint + '.json?since_id=' + conditions + '&limit=200&status=any';
			}
			else {
				url = '/admin/' + endpoint + '.json?since_id=' + conditions + '&limit=200';
			}
		}
		else {
			url = '/admin/' + endpoint + '.json';
		}
		TouchCRBase__Log__c logRecord = new TouchCRBase__Log__c();
		logRecord.TouchCRBase__Event_Type__c = 'Shopify API Callout ' + endpoint.toUpperCase();
		logRecord.TouchCRBase__Event_Description__c = url + '\n';
		try {
			HttpRequest SFRequest = new HttpRequest();
			Http api = new Http();
			Blob headerValue = Blob.valueOf(apikey + ':' + password);
			String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
			SFRequest.setHeader('Authorization', authorizationHeader);
			SFRequest.setMethod('GET');
			SFRequest.setEndpoint('callout:' + namedCredential + url);
			SFRequest.setHeader('Content-Type', 'application/json');
			SFRequest.setTimeout(60000);
			HttpResponse res = api.send(SFRequest);
			if (res.getStatusCode() == 200) {
				logRecord.TouchCRBase__Event_Status__c = 'Success';
				logRecord.TouchCRBase__Event_Description__c +=  'Callout Completed';
			}
			else {
				logRecord.TouchCRBase__Event_Status__c = 'Error';
				logRecord.TouchCRBase__Event_Description__c +=  res.getStatus() +' Status code: '+res.getStatusCode();
			}
			DOM.Document xmlDOC = new DOM.Document();
			result = res.getBody();
		}
		catch(Exception e){
			logRecord.TouchCRBase__Event_Status__c = 'Error';
			logRecord.TouchCRBase__Event_Description__c +=  e.getMessage() + ' on line number: ' + e.getLineNumber();
		}

		Boolean isCreateableTouchCRLogc = (
			TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Endpoint__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Account__c.getDescribe().isCreateable()
		);
		if (isCreateableTouchCRLogc) {
			try {
				insert logRecord;
			}
			catch(DmlException e){}
		}
		else { throw new privilegesException('privileges Exception'); }

		if (param == 'count') {
			return result;
		}
		else {
			return JSON.serialize(result);
		}
	}

	/*
	This is used to make api call
	$param      -This is used to pass id.
	$endpoint   - This is used to redirect page to particular endpoint like orders,products.etc.
	*/
	public static String make_api_call_by_date(String param, String endpoint, String conditions){

		String result;
		Map<String, String> ShopifySettings = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
		String apikey = ShopifySettings.containsKey('Shopify.ApiKey') ? ShopifySettings.get('Shopify.ApiKey') : 'test';
		String api_url = ShopifySettings.containsKey('Shopify.ApiURL') ? ShopifySettings.get('Shopify.ApiURL') : 'https://test@dxtestingstore.myshopify.com';
		String password = ShopifySettings.containsKey('Shopify.Password') ? ShopifySettings.get('Shopify.Password') : 'test';
		String namedCredential = ShopifySettings.containsKey('Shopify.Credential') ? ShopifySettings.get('Shopify.Credential') : 'test';

		String url;
		if (param != '') {
			url = '/admin/' + endpoint + '/' + param + '.json';
		}
		else if (conditions != '0') {
			String page = conditions;
			if (endpoint == 'orders') {
				url = '/admin/' + endpoint + '.json?since_id=' + conditions + '&limit=200&status=any';
			}
			else {
				Datetime today = Datetime.now().addMinutes(-1450);
				String updatedDate = today.format('Y-M-d') + 'T' + today.format('H') + ':' + today.format('m') + ':' + today.format('s') + '-05:00';
				/* This custom setting only used for testing */
				Map<String, String> shopifyUpdateDate = TouchCRBase.TouchCRHelper.getSettings('Shopify.');
				String shopifyUpdatedDate = shopifyUpdateDate.containsKey('Shopify.UpdateDate') ? shopifyUpdateDate.get('Shopify.UpdateDate') : '';
				if (shopifyUpdatedDate == '' || shopifyUpdatedDate == null) {
					shopifyUpdatedDate = updatedDate;
				}
				url = '/admin/' + endpoint + '.json?updated_at_min=' + shopifyUpdatedDate + '&created_at_max=' + shopifyUpdatedDate + '&limit=200';
			}
		}
		else {
			url = '/admin/' + endpoint + '.json';
		}
		TouchCRBase__Log__c logRecord = new TouchCRBase__Log__c();
		logRecord.TouchCRBase__Event_Description__c = url + '\n';
		logRecord.TouchCRBase__Event_Type__c = 'Shopify API Callout ' + endpoint.toUpperCase();
		try {
			HttpRequest SFRequest = new HttpRequest();
			Http api = new Http();
			Blob headerValue = Blob.valueOf(apikey + ':' + password);
			String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
			SFRequest.setHeader('Authorization', authorizationHeader);
			SFRequest.setMethod('GET');
			SFRequest.setEndpoint('callout:' + namedCredential + url);
			SFRequest.setTimeout(90000);
			SFRequest.setHeader('Content-Type', 'application/json');
			HttpResponse res = api.send(SFRequest);
			if (res.getStatusCode() == 200) {
				logRecord.TouchCRBase__Event_Status__c = 'Success';
				logRecord.TouchCRBase__Event_Description__c += 'Callout Completed';
				DOM.Document xmlDOC = new DOM.Document();
				result = res.getBody();
			}
			else {
				logRecord.TouchCRBase__Event_Status__c = 'Error';
				logRecord.TouchCRBase__Event_Description__c +=  res.getStatus() + ' Status code: ' + res.getStatusCode();
			}
		}
		catch(Exception e) {
			logRecord.TouchCRBase__Event_Status__c = 'Error';
			logRecord.TouchCRBase__Event_Description__c += e.getMessage() + ' on line number: ' + e.getLineNumber();
		}

		Boolean isCreateableTouchCRLogc1 = (
			TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Endpoint__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Account__c.getDescribe().isCreateable()
		);
		if (isCreateableTouchCRLogc1) {
			try {
				insert logRecord;
			}
			catch(DmlException e) {}
		}
		else { throw new privilegesException('privileges Exception'); }

		if (param == 'count') {
			return result;
		}
		else {
			return JSON.serialize(result);
		}
	}

	public with sharing class privilegesException extends Exception {}
}