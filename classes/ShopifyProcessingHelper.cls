public with sharing class ShopifyProcessingHelper {

	public static final Set<String> SHOPIFY_SCHEDULERS = new Set<String>{
		'ShopifyScheduler'
	};
	public static final Set<String> SHOPIFY_BATCHES = new Set<String>{
		'ShopifyProductBatch', 'ShopifyOrderBatch'
	};
	public static final String SHOPIFY_FEATURENAME = 'Shopify';
	public static final Set<String> REQUIRED_SETTINGS = new Set<String>{
		'Shopify.SalesFunnel',
		'Shopify.lastCustomerExternalID',
		'Shopify.lastOrderExternalID',
		'Shopify.lastProductExternalID',
		'Shopify.HandleShipping',
		'Shopify.ApiKey',
		'Shopify.Password',
		'Shopify.Credential',
		'Shopify.discountedProductId'
	};

	// BOOLEAN
	public static Boolean isSyncInProgress() {

		List<CronTrigger> schedulersInProgress = [
			SELECT Id, NextFireTime
			FROM CronTrigger
			WHERE CronJobDetail.Name IN :SHOPIFY_SCHEDULERS
		];

		List<AsyncApexJob> batchesInProgress = [
			SELECT Id, Status, ApexClassId, ApexClass.Name
			FROM AsyncApexJob
			WHERE ApexClass.Name IN :SHOPIFY_BATCHES
			AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
		];

		return !schedulersInProgress.isEmpty() || !batchesInProgress.isEmpty() ? true : false;
	}

	public static Boolean hasActiveConnections() {
		return !getActiveConnectionsIds().isEmpty();
	}

	public static Boolean isReadyToStart() {
		return (!ShopifyProcessingHelper.isSyncInProgress() && ShopifyProcessingHelper.hasActiveConnections());
	}

	//SAVE 'N LOAD
	public static Boolean loadSettingsForConnection(String connectionId) {
		// get persisted settings from connection
		TouchCRBase__TouchCRConnection__c persistedConnection = getConnectionById(connectionId);

		if (persistedConnection == null) {
			return false;
		}

		// collect persisted settings
		Map<String, String> connectionSettingsMap = new Map<String, String>();
		for (TouchCRBase__TouchCRConnectionSetting__c connSet : persistedConnection.TouchCRBase__TouchCRConnectionSettings__r) {
			connectionSettingsMap.put(connSet.Name, connSet.TouchCRBase__Value__c);
		}

		// prepare settings to load
		Map<String, String> setting = new Map<String, String>();
		// add settings from top level coonection
		setting.put('Shopify.Brand', persistedConnection.TouchCRBase__Brand__c);
		// add required settings from related connection settings
		for (String aSetting : REQUIRED_SETTINGS) {
			//check if all required settings are available
			if (connectionSettingsMap.containsKey(aSetting)) {
				setting.put(aSetting, connectionSettingsMap.get(aSetting));
			}
			else {
				return false;
			}
		}

		TouchCRBase.TouchCRHelper.setSettings(setting);

		return true;
	}

	public static Boolean saveSettingsForConnection(String connectionId) {
		// get persisted settings from connection
		TouchCRBase__TouchCRConnection__c persistedConnection = getConnectionById(connectionId);
		// get settings
		Map<String, String> currentSettings = TouchCRBase.TouchCRHelper.getSettings('Shopify.');

		if (persistedConnection == null) {
			return false;
		}

		List<TouchCRBase__TouchCRConnectionSetting__c> settingsToUpdate = new List<TouchCRBase__TouchCRConnectionSetting__c>();

		// hold ids for connsettings for update
		Map<String, TouchCRBase__TouchCRConnectionSetting__c> connectionSettingsMap = new Map<String, TouchCRBase__TouchCRConnectionSetting__c>();
		for (TouchCRBase__TouchCRConnectionSetting__c connSet : persistedConnection.TouchCRBase__TouchCRConnectionSettings__r) {
			connectionSettingsMap.put(connSet.Name, connSet);
		}

		//check if all required settings are available
		for (String aSetting : REQUIRED_SETTINGS) {
			if (connectionSettingsMap.containsKey(aSetting)) {
				TouchCRBase__TouchCRConnectionSetting__c updatedSetting = connectionSettingsMap.get(aSetting);
				updatedSetting.TouchCRBase__Value__c = currentSettings.get(aSetting);
				settingsToUpdate.add(updatedSetting);
			}
			else {
				return false;
			}
		}
		Boolean isSettingsUpdateable = (
			TouchCRBase__TouchCRConnection__c.getSObjectType().getDescribe().isUpdateable() && // master object
				TouchCRBase__TouchCRConnectionSetting__c.getSObjectType().getDescribe().isUpdateable() && // detail object
				TouchCRBase__TouchCRConnectionSetting__c.TouchCRBase__Value__c.getDescribe().isUpdateable() && // detail object field
				TouchCRBase__TouchCRConnectionSetting__c.Name.getDescribe().isUpdateable() // detail object field
		);

		if (isSettingsUpdateable) {
			Database.update(settingsToUpdate, true);
			return true;
		}
		else {
			throw new PrivilegesException('Privileges Exception');
		}

		return false;
	}

	// GETTERS
	public static TouchCRBase__TouchCRConnection__c getConnectionById(String connectionId) {
		TouchCRBase__TouchCRConnection__c persistedConnection = [
			SELECT Name, TouchCRBase__Feature__c, TouchCRBase__Brand__c, (SELECT Id, Name, TouchCRBase__Value__c FROM TouchCRBase__TouchCRConnectionSettings__r)
			FROM TouchCRBase__TouchCRConnection__c
			WHERE Id = :connectionId
		];
		return (persistedConnection == null || persistedConnection.TouchCRBase__TouchCRConnectionSettings__r.isEmpty()) ? null : persistedConnection;
	}

	public static Set<String> getActiveConnectionsIds() {
		return new Map<String, TouchCRBase__TouchCRConnection__c>([
			SELECT Id
			FROM TouchCRBase__TouchCRConnection__c
			WHERE TouchCRBase__Feature__c = :SHOPIFY_FEATURENAME
			AND TouchCRBase__isActive__c = true
			ORDER BY TouchCRBase__Order__c ASC NULLS LAST, TouchCRBase__Brand__c ASC
		]).keySet();
	}

	public static String getPrevConnectionId() {
		return TouchCRBase.TouchCRHelper.getSettings('Shopify.PrevConnectionId').get('Shopify.PrevConnectionId');
	}

	public static Set<String> getPorcessedConnectionsIds() {
		String result = TouchCRBase.TouchCRHelper.getSettings('Shopify.PorcessedConnectionsIds').get('Shopify.PorcessedConnectionsIds');
		return (result != null) ? new Set<String>(result.split(';')) : new Set<String>();
	}

	// SETTERS
	public static void cleanConnectionSettings() {
		TouchCRBase.TouchCRHelper.setSettings(
			new Map<String, String>{
				'Shopify.PrevConnectionId' => null,
				'Shopify.PorcessedConnectionsIds' => null
			}
		);
	}

	public static void setPrevConnectionId(String prevConnectionId) {
		TouchCRBase.TouchCRHelper.setSettings(
			new Map<String, String>{
				'Shopify.PrevConnectionId' => prevConnectionId
			}
		);
	}

	public static void setPorcessedConnectionsIds(Set<String> processedConnections) {
		TouchCRBase.TouchCRHelper.setSettings(
			new Map<String, String>{
				'Shopify.PorcessedConnectionsIds' => String.join(new List<String>(processedConnections), ';')
			}
		);
	}


	// TODO duplicate code from base package
	// Method returns the available CurrencyIsoCode from String
	public static String validateAndFixCurrencyIsoCode(String currencyCodeString) {
		return (getAllAvailableCurrencyCodes().contains(currencyCodeString)) ? currencyCodeString : getUserAvailableCurrencyCode();
	}

	public static Set<String> getAllAvailableCurrencyCodes() {
		Set<String> result = new Set<String>();

		if (UserInfo.isMultiCurrencyOrganization()) {
			Schema.DescribeSObjectResult describeCurrencyTypeResult = Schema.getGlobalDescribe().get('CurrencyType').getDescribe();
			Schema.DescribeFieldResult isoCodeFieldResult = describeCurrencyTypeResult.Fields.getMap().get('IsoCode').getDescribe();
			List<Schema.PicklistEntry> isoCodePickVals = isoCodeFieldResult.getPicklistValues();

			for (Schema.PicklistEntry f : isoCodePickVals) {
				result.add(f.getValue());
			}
		}
		else {
			result.add(UserInfo.getDefaultCurrency());
		}

		return result;
	}

	public static String getUserAvailableCurrencyCode() {
		return UserInfo.getDefaultCurrency();
	}

	private static String existingCountriesStatesStringCached { get; set; }
	public static String existingCountriesStatesString {
		get {
			if (existingCountriesStatesStringCached == null) {
				if (Test.isRunningTest()) {
					existingCountriesStatesStringCached = '{"US":{"value":"US","states":{"WY":"Wyoming","WI":"Wisconsin","WV":"West+Virginia","WA":"Washington","VA":"Virginia","VT":"Vermont","UT":"Utah","TX":"Texas","TN":"Tennessee","SD":"South+Dakota","SC":"South+Carolina","RI":"Rhode+Island","PA":"Pennsylvania","OR":"Oregon","OK":"Oklahoma","OH":"Ohio","ND":"North+Dakota","NC":"North+Carolina","NY":"New+York","NM":"New+Mexico","NJ":"New+Jersey","NH":"New+Hampshire","NV":"Nevada","NE":"Nebraska","MT":"Montana","MO":"Missouri","MS":"Mississippi","MN":"Minnesota","MI":"Michigan","MA":"Massachusetts","MD":"Maryland","ME":"Maine","LA":"Louisiana","KY":"Kentucky","KS":"Kansas","IA":"Iowa","IN":"Indiana","IL":"Illinois","ID":"Idaho","HI":"Hawaii","GA":"Georgia","FL":"Florida","DC":"District+of+Columbia","DE":"Delaware","CT":"Connecticut","CO":"Colorado","CA":"California","AR":"Arkansas","AZ":"Arizona","AK":"Alaska","AL":"Alabama"},"label":"United+States"}}';
				}
				else {
					existingCountriesStatesStringCached = TouchCRBase.RestCallsV2.doGet('getscp');
				}
			}
			return existingCountriesStatesStringCached;
		}
	}
	public static Boolean checkCountryState(String country, String state) {
		Map<String, PicklistEntryWrapper> existingCountriesStates = (Map<String, PicklistEntryWrapper>) JSON.deserialize(ShopifyProcessingHelper.existingCountriesStatesString, Map<String, PicklistEntryWrapper>.class);
		Boolean isCountryExist = false;
		Boolean isStateExist = false;

		country = (country != null) ? country.toUpperCase() : country;
		state = (state != null) ? state.toUpperCase() : state;

		for (String key : existingCountriesStates.keySet()) {
			PicklistEntryWrapper existingCountryStates = existingCountriesStates.get(key);
			if (existingCountryStates.label.contains(country) ||
				existingCountryStates.value.contains(country)) {
				isCountryExist = true;
				Set<String> existingStateValues = new Set<String>();
				existingStateValues.addAll(existingCountryStates.states.values());

				// empty state for multi state counteries is valid
				if (String.isBlank(state) && existingStateValues.size() > 0) {
					isStateExist = true;
				}
				// empty state for stateless coutries is valid
				else if (String.isBlank(state) && existingStateValues.size() < 1) {
					isStateExist = true;
				}
				// nonempty state for stateless countries is invalid
				else if (String.isNotBlank(state) && existingStateValues.size() < 1) {
					isStateExist = false;
				}
				// non empty state for multi state countries should be checked
				else if (String.isNotBlank(state) && existingStateValues.size() > 0) {
					if (existingCountryStates.states.keySet().contains(state) || existingStateValues.contains(state)) {
						isStateExist = true;
					}
				}
				break;
			}
		}
		return isCountryExist && isStateExist;
	}

	public class PicklistEntryWrapper {
		protected String label { get; set; }
		protected String value { get; set; }
		protected Map<String, String> states { get; set; }
	}

	public with sharing class PrivilegesException extends Exception {
	}

}