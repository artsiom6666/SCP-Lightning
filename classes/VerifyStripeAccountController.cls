public with sharing class VerifyStripeAccountController {

	@auraEnabled
	public static String verifyStripeAccount(String itemId) {

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

		String endpoint = 'callout:PaymentEndpoint/verifyAccount?v=2&gateway=Stripe';
		if (touchcrSettingsNameToValue.containsKey('Endpoint.ClientId') && touchcrSettingsNameToValue.containsKey('Endpoint.ClientSecret')) {
			endpoint += '&spApiKeyId=' + touchcrSettingsNameToValue.get('Endpoint.ClientId');
			endpoint += '&spApiKeySecret=' + touchcrSettingsNameToValue.get('Endpoint.ClientSecret');
			endpoint += '&securityKeyId=' + securityKeyId;
		}

		Account acc = getAccount(itemId);
		if (acc.Stripe_Account_ID__c == null){
			return 'Error! No Stripe Account to be verified.';
		}
		if (acc.Payout_Bank_Accounts__r.size() < 1){
			return 'Error! To verify this Stripe Account please create a Payout Bank Account first.';
		}
		
		List<ContentDocumentLink> cdLinks = [
			SELECT Id, ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId =: acc.Id
		];

		if (cdLinks.size() < 1) {
			return 'No verification document in attachments.';
		}

		List<ContentVersion> cvList = [
			SELECT Id, ContentDocumentId, VersionData
			FROM ContentVersion
			WHERE ContentDocumentId =: cdLinks[0].ContentDocumentId
			ORDER BY CreatedDate DESC
		];

		if (cvList.size() < 1) {
			return 'No verification document in attachments.';
		}

		PageReference pr = new PageReference(endpoint + '&');
		Map<String, String> parameters = getParameters(acc);

		for (String param : parameters.keySet()){
			pr.getParameters().put(param, parameters.get(param));
		}

		try {
			HTTPResponse res = Submit(pr.getUrl(), 'test.png', 'image/png', cvList[0].VersionData);
			result = res.getBody();
			if (res.getStatus() == 'OK') {
				Log__c log = new Log__c(
					Account__c = itemId,
					Action__c = 'Verify Franchisee Account',
					Description__c = 'Franchisee Account has been verified',
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
					Action__c = 'Verify Franchisee Account',
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
				Action__c = 'Verify Franchisee Account',
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

	private static HTTPResponse Submit(String url, String fileName, String fileMimeType, Blob fileBlob) {
		try {
			HttpFormBuilder builder = new HttpFormBuilder();
			String contentType = builder.GetContentType();

			//  Compose the form
			String form64 = '';

			form64 += builder.WriteBoundary();
			form64 += builder.WriteBoundary();

			WriteFileResult result = builder.WriteFile('file', fileName, fileMimeType, fileBlob);

			form64 += result.Content;
			form64 += builder.WriteBoundary(result.EndingType);

			Blob formBlob = EncodingUtil.base64Decode(form64);
			String contentLength = String.valueOf(formBlob.size());

			//  Compose the http request
			HttpRequest httpRequest = new HttpRequest();
			Http http = new Http();

			httpRequest.setBodyAsBlob(formBlob);
			httpRequest.setEndpoint(url);
			httpRequest.setHeader('Connection', 'keep-alive');
			httpRequest.setHeader('Content-Length', contentLength);
			httpRequest.setHeader('Content-Type', contentType);
			httpRequest.setMethod('POST');
			httpRequest.setTimeout(120000);

			HTTPResponse res = http.send(httpRequest);

			return res;
		} catch (Exception e) {
			return null;
		}
	}

	private static Account getAccount(String itemId) {

		List<Account> accountBankList = [
			SELECT Id, Stripe_Account_ID__c,
				(SELECT Id
				FROM Account.Payout_Bank_Accounts__r)
			FROM Account WHERE Id =: itemId LIMIT 1
		];

		return accountBankList[0];
	}

	private static Map<String, String> getParameters(Account acc) {
		return new Map<String, String>{
			'accountId' => acc.Stripe_Account_ID__c
		};
	}

	public class HttpFormBuilder {
		//  The boundary is alligned so it doesn't produce padding characters when base64 encoded.
		private String Boundary = '1ff13444ed8140c7a32fc4e6451aa76d';

		/**
			*  Returns the request's content type for multipart/form-data requests.
		*/
		public String GetContentType() {
			return 'multipart/form-data; boundary="' + Boundary + '"';
		}

		/**
			*  Pad the value with spaces until the base64 encoding is no longer padded.
		*/
		private String SafelyPad(String value, String valueCrLf64, String lineBreaks) {
			String valueCrLf = '';
			Blob valueCrLfBlob = null;

			while (valueCrLf64.endsWith('=')) {
				value += ' ';
				valueCrLf = value + lineBreaks;
				valueCrLfBlob = blob.valueOf(valueCrLf);
				valueCrLf64 = EncodingUtil.base64Encode(valueCrLfBlob);
			}

			return valueCrLf64;
		}

		/**
			*  Write a boundary between parameters to the form's body.
		*/
		public String WriteBoundary() {
			String value = '--' + Boundary + '\r\n';
			Blob valueBlob = Blob.valueOf(value);

			return EncodingUtil.base64Encode(valueBlob);
		}

		/**
			*  Write a boundary at the end of the form's body.
		*/
		public String WriteBoundary(EndingType ending) {
			String value = '';

			if (ending == EndingType.Cr) {
				//  The file's base64 was padded with a single '=',
				//  so it was replaced with '\r'. Now we have to
				//  prepend the boundary with '\n' to complete
				//  the line break.
				value += '\n';
			} else if (ending == EndingType.None) {
				//  The file's base64 was not padded at all,
				//  so we have to prepend the boundary with
				//  '\r\n' to create the line break.
				value += '\r\n';
			}
			//  Else:
			//  The file's base64 was padded with a double '=',
			//  so they were replaced with '\r\n'. We don't have to
			//  do anything to the boundary because there's a complete
			//  line break before it.

			value += '--' + Boundary + '--';

			Blob valueBlob = Blob.valueOf(value);

			return EncodingUtil.base64Encode(valueBlob);
		}

		/**
			*  Wirte a file to the form's body.
		*/
		public WriteFileResult WriteFile(String key, String value, String mimeType, Blob fileBlob) {
			EndingType ending = EndingType.None;
			String contentDisposition = 'Content-Disposition: form-data; name="' + key + '"; filename="' + value + '"';
			String contentDispositionCrLf = contentDisposition + '\r\n';
			Blob contentDispositionCrLfBlob = Blob.valueOf(contentDispositionCrLf);
			String contentDispositionCrLf64 = EncodingUtil.base64Encode(contentDispositionCrlfBlob);
			String content = SafelyPad(contentDisposition, contentDispositionCrLf64, '\r\n');
			String contentType = 'Content-Type: ' + mimeType;
			String contentTypeCrLf = contentType + '\r\n\r\n';
			Blob contentTypeCrLfBlob = Blob.valueOf(contentTypeCrLf);
			String contentTypeCrLf64 = EncodingUtil.base64Encode(contentTypeCrLfBlob);

			content += SafelyPad(contentType, contentTypeCrLf64, '\r\n\r\n');

			String file64 = EncodingUtil.base64Encode(fileBlob);
			Integer file64Length = file64.length();
			String file64Ending = file64.substring(file64Length - 3, file64Length);

			if (file64Ending.endsWith('==')) {
				file64Ending = file64Ending.substring(0, 1) + '0K';//   0K = \r\n
				file64 = file64.substring(0, file64Length - 3) + file64Ending;
				ending = EndingType.CrLf;
			} else if (file64Ending.endsWith('=')) {
				file64Ending = file64Ending.substring(0, 2) + 'N';//    N = \r
				file64 = file64.substring(0, file64Length - 3) + file64Ending;
				ending = EndingType.Cr;
			}

			content += file64;

			return new WriteFileResult(content, ending);
		}
	}
	/**
		*  Helper class containing the result of writing a file's blob to the form's body.
	*/
	public class WriteFileResult {
		public final String Content { get; private set; }
		public final EndingType EndingType { get; private set; }

		public WriteFileResult(String content, EndingType ending) {
			this.Content = content;
			this.EndingType = ending;
		}
	}

	/**
		*  Helper enum indicating how a file's base64 padding was replaced.
	*/
	public enum EndingType {
		Cr,
		CrLf,
		None
	}
}