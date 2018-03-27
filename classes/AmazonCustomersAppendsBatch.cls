public class AmazonCustomersAppendsBatch implements Database.Batchable<sObject>,  Database.Stateful, Database.AllowsCallouts {

	private String dataFinderKey;
	private Boolean isProxyEnabled = false;

	public AmazonCustomersAppendsBatch () {
		Map<String, String> amazonSettings = TouchCRBase.TouchCRHelper.getSettings('');
		// Proxy
		System.debug('Proxy');
		if (amazonSettings.containsKey('Proxy.isEnabled')) {
			this.isProxyEnabled = Boolean.valueOf(amazonSettings.get('Proxy.isEnabled'));
		}

		if (amazonSettings.containsKey('Amazon.DataFinderKey')) {
			this.dataFinderKey = amazonSettings.get('Amazon.DataFinderKey');
		}
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String scpProp = TouchCRHelper.isSCPEnabled() == TRUE ? ' , BillingStateCode' : '';
		String soqlStr = 'SELECT Id, FirstName, LastName, BillingStreet, BillingCity' + scpProp + ',BillingPostalCode, Phone ' +
		' FROM Account WHERE TouchCRBase__DF_Append_Run__c = FALSE AND DF_Need_Append__c = TRUE';
		return Database.getQueryLocator(soqlStr);
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		if (scope.size() > 0) {
			Account sObj = (Account)scope[0];

			TouchCRBase.DataFinderApi api = (isProxyEnabled) ? new TouchCRBase.DataFinderApi('callout:TouchCRBase__SecureProxy/person') : new TouchCRBase.DataFinderApi();
			api.setConfKey(this.dataFinderKey);
			api.setSObject(sObj);
			if (!Test.isRunningTest()) {
				api.doGetData();
				api.doAppend();
			}
			else {
				sObj.TouchCRBase__DF_Append_Run__c = true;
			}

			Database.insert(api.getLogs());
			Database.update(sObj);
		}
	}

	public void finish(Database.BatchableContext BC) {
	}
}