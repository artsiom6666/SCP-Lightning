public with sharing class AmazonRequestHelper {
	public AmazonRequestHelper() {
		
	}

	@future(callout=true)
	public static void RequestReport(String API_Key, String API_Secret, String MerchantID, String MarketpalceID, String StartDate, String EndDate) {

		Boolean isCreateableLog = (
			TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() 
		);

		TouchCRBase__Log__c log = new TouchCRBase__Log__c();
		log.TouchCRBase__Event_Type__c = 'Amazon AmazonRequestHelper RequestReport';
		log.TouchCRBase__Event_Description__c = '';
		try {

			Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('Amazon.');
			String credential = allSettings.get('Amazon.Credential');

			String reportEndpoint = 'callout:' + credential + '/Reports/2009-01-01';

			List<String> parameters = new List<String>();

			parameters.add('AWSAccessKeyId=' + API_Key);
			parameters.add('MarketplaceId=' + MarketpalceID);
			parameters.add('Action=RequestReport');
			// FIXME
			parameters.add('ReportType=_GET_MERCHANT_LISTINGS_ALL_DATA_');
			//parameters.add('ReportType=_GET_MERCHANT_LISTINGS_DATA_');

			parameters.add('StartDate=' + StartDate);
			parameters.add('EndDate=' + EndDate);

			parameters.add('SellerId=' + MerchantID);
			parameters.add('SignatureMethod=HmacSHA256');
			parameters.add('SignatureVersion=2');

			DateTime now = Datetime.now();
			String timestamp = 'Timestamp=' + now.formatGMT('yyyy-MM-dd') + 'T' + now.formatGmt('HH:mm:ss') + 'Z';
			timestamp = timestamp.replace(':', '%3A');
			parameters.add(timestamp);

			parameters.add('Version=2009-01-01');

			parameters.sort();

			String canonicalString = 'POST\nmws.amazonservices.com\n/Reports/2009-01-01\n';
			for (String param : parameters) {
				canonicalString += param + '&';

			}
			canonicalString = canonicalString.removeEnd('&');

			Blob blobSignature = Crypto.generateMac('HmacSHA256', Blob.valueOf(canonicalString), Blob.valueOf(API_Secret));
			String signature = 'Signature=' + EncodingUtil.urlEncode(EncodingUtil.base64Encode(blobSignature), 'UTF-8') ;

			parameters.add(signature);

			String requestURL = reportEndpoint + '?';
			for (String param : parameters) {
				requestURL += param + '&';
			}
			requestURL = requestURL.removeEnd('&');

			System.debug('RequestReport URL: ' + requestURL);
			log.TouchCRBase__Event_Description__c += 'RequestReport URL: ' + requestURL + '\n';

			Http http = new Http();
			HttpRequest req = new HttpRequest();
			req.setMethod('POST');
			req.setEndpoint(requestURL);

			HttpResponse res = http.send(req);

			if (res.getStatusCode() != 200) {
				throw new calloutException('Bad request.\n' + res.getBody());
			}

			System.debug(res.getBody());
			
			String reportProcessingStatus = parseXML(res.getBody(), 'ReportProcessingStatus');
			String reportRequestId = parseXML(res.getBody(), 'ReportRequestId');

			Map<String, String> setting = new Map<String, String>();
			setting.put('Amazon.ReportProcessingStatus', reportProcessingStatus);
			setting.put('Amazon.ReportRequestId', reportRequestId);
			TouchCRBase.TouchCRHelper.setSettings(setting);

			log.TouchCRBase__Event_Status__c = 'Success';
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {

				insert log;
			}
		}
		catch (Exception ex) {
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c += ex.getMessage();
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {

				insert log;
			}
		}		
	}

	@future(callout=true)
	public static void GetReportRequestList(String API_Key, String API_Secret, String MerchantID, String MarketpalceID, String ReportRequestId ) {

		Boolean isCreateableLog = (
			TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()  
		);

		try {

			Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('Amazon.');
			String credential = allSettings.get('Amazon.Credential');

			String reportEndpoint = 'callout:' + credential + '/Reports/2009-01-01';

			List<String> parameters = new List<String>();

			parameters.add('AWSAccessKeyId=' + API_Key);
			parameters.add('MarketplaceId=' + MarketpalceID);
			parameters.add('Action=GetReportRequestList');
			parameters.add('ReportRequestIdList.Id.1=' + ReportRequestId);
			parameters.add('SellerId=' + MerchantID);
			parameters.add('SignatureMethod=HmacSHA256');
			parameters.add('SignatureVersion=2');

			DateTime now = Datetime.now();
			String timestamp = 'Timestamp=' + now.formatGMT('yyyy-MM-dd') + 'T' + now.formatGmt('HH:mm:ss') + 'Z';
			timestamp = timestamp.replace(':', '%3A');
			parameters.add(timestamp);

			parameters.add('Version=2009-01-01');

			parameters.sort();

			String canonicalString = 'POST\nmws.amazonservices.com\n/Reports/2009-01-01\n';
			for (String param : parameters) {
				canonicalString += param + '&';

			}
			canonicalString = canonicalString.removeEnd('&');

			Blob blobSignature = Crypto.generateMac('HmacSHA256', Blob.valueOf(canonicalString), Blob.valueOf(API_Secret));
			String signature = 'Signature=' + EncodingUtil.urlEncode(EncodingUtil.base64Encode(blobSignature), 'UTF-8') ;

			parameters.add(signature);

			String requestURL = reportEndpoint + '?';
			for (String param : parameters) {
				requestURL += param + '&';
			}
			requestURL = requestURL.removeEnd('&');

			System.debug('RequestReport URL: ' + requestURL);

			Http http = new Http();
			HttpRequest req = new HttpRequest();
			req.setMethod('POST');
			req.setEndpoint(requestURL);

			HttpResponse res = http.send(req);

			if (res.getStatusCode() != 200) {
				throw new calloutException('Bad request.\n' + res.getBody());
			}

			System.debug(res.getBody());

			String reportProcessingStatus = parseXML(res.getBody(), 'ReportProcessingStatus');
			System.debug('BBBB: ' + reportProcessingStatus);

			
			Map<String, String> setting = new Map<String, String>();
			setting.put('Amazon.ReportProcessingStatus', reportProcessingStatus);

			if (reportProcessingStatus == '_DONE_') {
				setting.put('Amazon.GeneratedReportId', parseXML(res.getBody(), 'GeneratedReportId') );
			}

			TouchCRBase.TouchCRHelper.setSettings(setting);

		}
		catch (Exception ex) {
			TouchCRBase__Log__c log = new TouchCRBase__Log__c();
			log.TouchCRBase__Event_Type__c = 'Amazon AmazonRequestHelper GetReportRequestList';
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c = ex.getMessage();
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {

				insert log;
			}
		}
	}

	public static String GetReport(String API_Key, String API_Secret, String MerchantID, String MarketpalceID, String GeneratedReportId) {

		Boolean isCreateableLog = (
			TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()  
		);

		TouchCRBase__Log__c log = new TouchCRBase__Log__c();
		log.TouchCRBase__Event_Type__c = 'Amazon AmazonRequestHelper GetReport';
		log.TouchCRBase__Event_Description__c = '';

		try{

			Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('Amazon.');
			String credential = allSettings.get('Amazon.Credential');

			String reportEndpoint = 'callout:' + credential + '/Reports/2009-01-01';

			List<String> parameters = new List<String>();

			parameters.add('AWSAccessKeyId=' + API_Key);
			parameters.add('MarketplaceId=' + MarketpalceID);
			parameters.add('SellerId=' + MerchantID);
			parameters.add('Action=GetReport');
			parameters.add('ReportId=' + GeneratedReportId);
			parameters.add('SignatureMethod=HmacSHA256');
			parameters.add('SignatureVersion=2');

			DateTime now = Datetime.now();
			String timestamp = 'Timestamp=' + now.formatGMT('yyyy-MM-dd') + 'T' + now.formatGmt('HH:mm:ss') + 'Z';
			timestamp = timestamp.replace(':', '%3A');
			parameters.add(timestamp);

			parameters.add('Version=2009-01-01');

			parameters.sort();

			String canonicalString = 'POST\nmws.amazonservices.com\n/Reports/2009-01-01\n';
			for (String param : parameters) {
				canonicalString += param + '&';

			}
			canonicalString = canonicalString.removeEnd('&');

			Blob blobSignature = Crypto.generateMac('HmacSHA256', Blob.valueOf(canonicalString), Blob.valueOf(API_Secret));
			String signature = 'Signature=' + EncodingUtil.urlEncode(EncodingUtil.base64Encode(blobSignature), 'UTF-8') ;

			parameters.add(signature);

			String requestURL = reportEndpoint + '?';
			for (String param : parameters) {
				requestURL += param + '&';
			}
			requestURL = requestURL.removeEnd('&');

			System.debug('GetReport URL: ' + requestURL);
			log.TouchCRBase__Event_Description__c += 'GetReport URL: ' + requestURL + '\n';

			Http http = new Http();
			HttpRequest req = new HttpRequest();
			req.setMethod('POST');
			req.setEndpoint(requestURL);

			HttpResponse res = http.send(req);

			if (res.getStatusCode() != 200) {
				throw new calloutException('Bad request.\n' + res.getBody());
			}

			log.TouchCRBase__Event_Status__c = 'Success';
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {

				insert log;
			}
			//return Report TSV data
			return res.getBody();
		}
		catch (Exception ex) {
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c = ex.getMessage();
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {
				insert log;
			}
			return 'Error';
		}
	}

	public static String GetProductCategoriesForASIN (String API_Key, String API_Secret, String MerchantID, 
														String MarketpalceID, String productASIN) {

		Boolean isCreateableLog = (
			TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()  
		);

		TouchCRBase__Log__c log = new TouchCRBase__Log__c();
		log.TouchCRBase__Event_Type__c = 'Amazon AmazonRequestHelper GetProductCategoriesForASIN';
		log.TouchCRBase__Event_Description__c = '';

		try{

			Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('Amazon.');
			String credential = allSettings.get('Amazon.Credential');

			String reportEndpoint = 'callout:' + credential + '/Products/2011-10-01';

			List<String> parameters = new List<String>();

			parameters.add('AWSAccessKeyId=' + API_Key);
			parameters.add('MarketplaceId=' + MarketpalceID);
			parameters.add('SellerId=' + MerchantID);
			parameters.add('Action=GetProductCategoriesForASIN');			
			parameters.add('SignatureMethod=HmacSHA256');
			parameters.add('SignatureVersion=2');
			parameters.add('ASIN=' + productASIN);

			DateTime now = Datetime.now();
			String timestamp = 'Timestamp=' + now.formatGMT('yyyy-MM-dd') + 'T' + now.formatGmt('HH:mm:ss') + 'Z';
			timestamp = timestamp.replace(':', '%3A');
			parameters.add(timestamp);

			parameters.add('Version=2011-10-01');

			parameters.sort();

			String canonicalString = 'POST\nmws.amazonservices.com\n/Products/2011-10-01\n';
			for (String param : parameters) {
				canonicalString += param + '&';

			}
			canonicalString = canonicalString.removeEnd('&');

			Blob blobSignature = Crypto.generateMac('HmacSHA256', Blob.valueOf(canonicalString), Blob.valueOf(API_Secret));
			String signature = 'Signature=' + EncodingUtil.urlEncode(EncodingUtil.base64Encode(blobSignature), 'UTF-8') ;

			parameters.add(signature);

			String requestURL = reportEndpoint + '?';
			for (String param : parameters) {
				requestURL += param + '&';
			}
			requestURL = requestURL.removeEnd('&');

			log.TouchCRBase__Event_Description__c += 'GetCategory URL: ' + requestURL + '\n';

			Http http = new Http();
			HttpRequest req = new HttpRequest();
			req.setMethod('POST');
			req.setEndpoint(requestURL);

			HttpResponse res = http.send(req);

			if (res.getStatusCode() != 200) {
				throw new calloutException('Bad request.\n' + res.getBody());
			}

			//return Report TSV data
			return res.getBody();
		}
		catch (Exception ex) {
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c = ex.getMessage();
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {
				insert log;
			}
			return 'Error';
		}
	}

	public static String ListOrders(String API_Key, String API_Secret, String MerchantID, String MarketpalceID, String LastUpdatedAfter) {

		Boolean isCreateableLog = (
			TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()  
		);

		try{

			Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('Amazon.');
			String credential = allSettings.get('Amazon.Credential');

			String listOrdersEndpoint = 'callout:' + credential + '/Orders/2013-09-01';

			LastUpdatedAfter = LastUpdatedAfter.replace(':', '%3A');

			List<String> parameters = new List<String>();

			parameters.add('AWSAccessKeyId=' + API_Key);
			parameters.add('MarketplaceId.Id.1=' + MarketpalceID);
			parameters.add('SellerId=' + MerchantID);
			parameters.add('Action=ListOrders');
			parameters.add('MaxResultsPerPage=30');

			parameters.add('LastUpdatedAfter='+LastUpdatedAfter);
			
			parameters.add('SignatureMethod=HmacSHA256');
			parameters.add('SignatureVersion=2');

			DateTime now = Datetime.now();
			String timestamp = 'Timestamp=' + now.formatGMT('yyyy-MM-dd') + 'T' + now.formatGmt('HH:mm:ss') + 'Z';
			timestamp = timestamp.replace(':', '%3A');
			parameters.add(timestamp);

			parameters.add('Version=2013-09-01');

			parameters.sort();

			String canonicalString = 'POST\nmws.amazonservices.com\n/Orders/2013-09-01\n';
			for (String param : parameters) {
				canonicalString += param + '&';

			}
			canonicalString = canonicalString.removeEnd('&');

			Blob blobSignature = Crypto.generateMac('HmacSHA256', Blob.valueOf(canonicalString), Blob.valueOf(API_Secret));
			String signature = 'Signature=' + EncodingUtil.urlEncode(EncodingUtil.base64Encode(blobSignature), 'UTF-8') ;

			parameters.add(signature);


			//String requestURL = reportEndpoint + '?';
			String requestURL = listOrdersEndpoint + '?';
			for (String param : parameters) {
				requestURL += param + '&';
			}
			requestURL = requestURL.removeEnd('&');

			System.debug('ListOrders URL: ' + requestURL);

			Http http = new Http();
			HttpRequest req = new HttpRequest();
			req.setMethod('POST');
			req.setEndpoint(requestURL);

			HttpResponse res = http.send(req);

			if (res.getStatusCode() != 200) {
				throw new calloutException('Bad request.\n' + res.getBody());
			}

			return res.getBody();

		}
		catch (Exception ex) {
			TouchCRBase__Log__c log = new TouchCRBase__Log__c();
			log.TouchCRBase__Event_Type__c = 'Amazon AmazonRequestHelper ListOrders';
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c = ex.getMessage();
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {
				insert log;
			}
			return 'Error';
		}

		
	}

	public static String ListOrdersByNextToken(String API_Key, String API_Secret, String MerchantID, String nextToken) {

		Boolean isCreateableLog = (
			TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() 
		);

		try {

			Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('Amazon.');
			String credential = allSettings.get('Amazon.Credential');

			String listOrdersByNextTokenEndpoint = 'callout:' + credential + '/Orders/2013-09-01';

			List<String> parameters = new List<String>();

			parameters.add('AWSAccessKeyId=' + API_Key);
			parameters.add('SellerId=' + MerchantID);
			parameters.add('Action=ListOrdersByNextToken');
	 		
			parameters.add('NextToken=' + EncodingUtil.urlEncode(nextToken, 'UTF-8'));
			
			parameters.add('SignatureMethod=HmacSHA256');
			parameters.add('SignatureVersion=2');

			DateTime now = Datetime.now();
			String timestamp = 'Timestamp=' + now.formatGMT('yyyy-MM-dd') + 'T' + now.formatGmt('HH:mm:ss') + 'Z';
			timestamp = timestamp.replace(':', '%3A');
			parameters.add(timestamp);

			parameters.add('Version=2013-09-01');

			parameters.sort();

			String canonicalString = 'POST\nmws.amazonservices.com\n/Orders/2013-09-01\n';
			for (String param : parameters) {
				canonicalString += param + '&';

			}
			canonicalString = canonicalString.removeEnd('&');

			Blob blobSignature = Crypto.generateMac('HmacSHA256', Blob.valueOf(canonicalString), Blob.valueOf(API_Secret));
			String signature = 'Signature=' + EncodingUtil.urlEncode(EncodingUtil.base64Encode(blobSignature), 'UTF-8') ;

			parameters.add(signature);

			String requestURL = listOrdersByNextTokenEndpoint + '?';
			for (String param : parameters) {
				requestURL += param + '&';
			}
			requestURL = requestURL.removeEnd('&');

			System.debug('ListOrders URL: ' + requestURL);

			//do req
			Http http = new Http();
			HttpRequest req = new HttpRequest();
			req.setMethod('POST');
			req.setEndpoint(requestURL);

			HttpResponse res = http.send(req);

			if (res.getStatusCode() != 200) {
				throw new calloutException('Bad request.\n' + res.getBody());
			}

			//System.debug(res.getBody());

			return res.getBody();

		}
		catch (Exception ex) {
			TouchCRBase__Log__c log = new TouchCRBase__Log__c();
			log.TouchCRBase__Event_Type__c = 'Amazon AmazonRequestHelper ListOrdersByNextToken';
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c = ex.getMessage();
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {
				insert log;
			}
			return 'Error';
		}
	}

	public static String ListOrderItems(String API_Key, String API_Secret, String MerchantID, String amazonOrderId) {

		Boolean isCreateableLog = (
			TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() 
		);

		try {

			Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('Amazon.');
			String credential = allSettings.get('Amazon.Credential');

			String listOrderItemsEndpoint = 'callout:' + credential + '/Orders/2013-09-01';

			List<String> parameters = new List<String>();

			parameters.add('AWSAccessKeyId=' + API_Key);
			parameters.add('SellerId=' + MerchantID);
			parameters.add('Action=ListOrderItems');

			parameters.add('AmazonOrderId=' + amazonOrderId);
			
			parameters.add('SignatureMethod=HmacSHA256');
			parameters.add('SignatureVersion=2');

			DateTime now = Datetime.now();
			String timestamp = 'Timestamp=' + now.formatGMT('yyyy-MM-dd') + 'T' + now.formatGmt('HH:mm:ss') + 'Z';
			timestamp = timestamp.replace(':', '%3A');
			parameters.add(timestamp);

			parameters.add('Version=2013-09-01');

			parameters.sort();

			String canonicalString = 'POST\nmws.amazonservices.com\n/Orders/2013-09-01\n';
			for (String param : parameters) {
				canonicalString += param + '&';

			}
			canonicalString = canonicalString.removeEnd('&');

			Blob blobSignature = Crypto.generateMac('HmacSHA256', Blob.valueOf(canonicalString), Blob.valueOf(API_Secret));
			String signature = 'Signature=' + EncodingUtil.urlEncode(EncodingUtil.base64Encode(blobSignature), 'UTF-8') ;

			parameters.add(signature);

			String requestURL = listOrderItemsEndpoint + '?';
			for (String param : parameters) {
				requestURL += param + '&';
			}
			requestURL = requestURL.removeEnd('&');

			System.debug('ListOrders URL: ' + requestURL);

			Http http = new Http();
			HttpRequest req = new HttpRequest();
			req.setMethod('POST');
			req.setEndpoint(requestURL);

			HttpResponse res = http.send(req);

			if (res.getStatusCode() != 200) {
				throw new calloutException('Bad request.\n' + res.getBody());
			}

			return res.getBody();

		}
		catch (Exception ex) {
			TouchCRBase__Log__c log = new TouchCRBase__Log__c();
			log.TouchCRBase__Event_Type__c = 'Amazon AmazonRequestHelper ListOrdersByNextToken';
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c = ex.getMessage();
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {
				insert log;
			}
			return 'Error';
		}
	}

	public static String parseXML(String toParse, String toFind) {
		DOM.Document doc = new DOM.Document();
		try {
			doc.load(toParse);
			DOM.XMLNode root = doc.getRootElement();
			return walkThrough(root, toFind);

		} catch (System.XMLException e) {  // invalid XML
			return e.getMessage();
		}
	}

	public static String walkThrough(DOM.XMLNode node, String toFind) {
		String result = '';
		if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
			if (node.getName() == toFind) {
				if (node.getText().trim() != '') {
					result += node.getText().trim();
				}
			}
			for (Dom.XMLNode child: node.getChildElements()) {
				result += walkThrough(child, toFind);
			}
			return result;
		}
		return '';  //should never reach here 
	}

	public class calloutException extends Exception {}
}