global with sharing class AmazonSyncAPIClient implements Schedulable, Database.AllowsCallouts {

	String currentConnectionID;
	String currentConnectionName;
	String currentConnectionBrand;

	String nextConnectionId;
	String nextConnectionName;

	global AmazonSyncAPIClient() {
	}

	global void execute(SchedulableContext sc) {

		if (AmazonProcessingHelper.isSyncInProgress()) {			

			TouchCRBase__Log__c log = new TouchCRBase__Log__c();
			log.TouchCRBase__Event_Type__c = 'AmazonSyncAPIClient';
			log.TouchCRBase__Event_Status__c = 'Warning';
			log.TouchCRBase__Event_Description__c = 'Amazon Sync is already in progress.\n';

			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {

				insert log;
			}

			return;
		}

		String availableConnectionsIds = '';

		for(TouchCRBase__TouchCRConnection__c conn : [SELECT Id, Name, TouchCRBase__Feature__c, TouchCRBase__Brand__c 
										FROM TouchCRBase__TouchCRConnection__c 
										WHERE TouchCRBase__Feature__c = 'Amazon' AND TouchCRBase__isActive__c = true ORDER BY Name ASC]) {

			availableConnectionsIds += conn.Id + ';';

			if (String.isBlank(currentConnectionID)) {
				currentConnectionID = conn.Id;
				currentConnectionName = conn.Name;
				currentConnectionBrand = conn.TouchCRBase__Brand__c;
			}

			if (currentConnectionID != conn.Id) {
				nextConnectionId = conn.Id;
				nextConnectionName = conn.Name;
			}
		}

		if (String.isBlank(currentConnectionID)) {
			TouchCRBase__Log__c log = new TouchCRBase__Log__c();
			log.TouchCRBase__Event_Type__c = 'AmazonSyncAPIClient';
			log.TouchCRBase__Event_Status__c = 'Warning';
			log.TouchCRBase__Event_Description__c = 'Amazon has no available connections.\n';

			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {

				insert log;
			}
			return;
		}

		Map<String, String> connectionSettingsMap = new Map<String, String>();

		for (TouchCRBase__TouchCRConnectionSetting__c connSet : [SELECT TouchCRBase__TouchCRConnection__c, Name, TouchCRBase__Value__c 
													FROM TouchCRBase__TouchCRConnectionSetting__c 
													WHERE TouchCRBase__TouchCRConnection__c = :currentConnectionID]) {

			connectionSettingsMap.put(connSet.Name, connSet.TouchCRBase__Value__c);
		}

		if (!connectionSettingsMap.containsKey('Amazon.SyncStartDate')) {
			connectionSettingsMap.put('Amazon.SyncStartDate', '2016-01-01');

			TouchCRBase__TouchCRConnectionSetting__c cs = new TouchCRBase__TouchCRConnectionSetting__c();
			cs.Name = 'Amazon.SyncStartDate';
			cs.TouchCRBase__Value__c = '2016-01-01';
			cs.TouchCRBase__TouchCRConnection__c = currentConnectionID;

			if (TouchCRBase__TouchCRConnectionSetting__c.Name.getDescribe().isCreateable() &&
				TouchCRBase__TouchCRConnectionSetting__c.TouchCRBase__Value__c.getDescribe().isCreateable() && 
				TouchCRBase__TouchCRConnectionSetting__c.TouchCRBase__TouchCRConnection__c.getDescribe().isCreateable() ) {
				insert cs;
			}
		}
		if (!connectionSettingsMap.containsKey('Amazon.SalesFunnel')) {
			connectionSettingsMap.put('Amazon.SalesFunnel', 'Amazon');

			TouchCRBase__TouchCRConnectionSetting__c cs = new TouchCRBase__TouchCRConnectionSetting__c();
			cs.Name = 'Amazon.SalesFunnel';
			cs.TouchCRBase__Value__c = 'Amazon';
			cs.TouchCRBase__TouchCRConnection__c = currentConnectionID;

			if (TouchCRBase__TouchCRConnectionSetting__c.Name.getDescribe().isCreateable() &&
				TouchCRBase__TouchCRConnectionSetting__c.TouchCRBase__Value__c.getDescribe().isCreateable() && 
				TouchCRBase__TouchCRConnectionSetting__c.TouchCRBase__TouchCRConnection__c.getDescribe().isCreateable() ) {
				insert cs;
			}
		}

		Set<String> requiredSettings = new Set<String>();
		requiredSettings.add('Amazon.ApiKey');
		requiredSettings.add('Amazon.ApiSecret');
		requiredSettings.add('Amazon.MerchantId');
		requiredSettings.add('Amazon.MarketPlaceId');
		requiredSettings.add('Amazon.SyncStartDate');
		requiredSettings.add('Amazon.Credential');
		requiredSettings.add('Amazon.SalesFunnel');

		//check if all required settings are available
		for (String setting : requiredSettings) {
			if (!connectionSettingsMap.containsKey(setting)) {
				TouchCRBase__Log__c log = new TouchCRBase__Log__c();
				log.TouchCRBase__Event_Type__c = 'AmazonSyncAPIClient';
				log.TouchCRBase__Event_Status__c = 'Error';
				log.TouchCRBase__Event_Description__c = 'Amazon connection has no all required settings.\n';
				log.TouchCRBase__Event_Description__c += 'Amazon connection: '+ currentConnectionID + ' ' + currentConnectionName + '\n';

				if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {

					insert log;
				}
				return;
			}
		}


		Map<String, String> setting = new Map<String, String>();
		//Clear Integration old requested data
		setting.put('Amazon.ReportProcessingStatus', '');
		setting.put('Amazon.ReportRequestId', '');
		setting.put('Amazon.GeneratedReportId', '');

		//Set new settings values

		//current connection data
		setting.put('Amazon.CurrentConnectionID', currentConnectionID);
		setting.put('Amazon.CurrentConnectionName', currentConnectionName);

		//all available Amazon Connections IDs
		setting.put('Amazon.ConnectionsIDs', availableConnectionsIds);

		//next connection data
		setting.put('Amazon.NextConnectionId', nextConnectionId);
		setting.put('Amazon.NextConnectionName', nextConnectionName);

		//Current connection Settings
		setting.put('Amazon.Brand', currentConnectionBrand);
		setting.put('Amazon.ApiKey', connectionSettingsMap.get('Amazon.ApiKey'));
		setting.put('Amazon.ApiSecret', connectionSettingsMap.get('Amazon.ApiSecret'));
		setting.put('Amazon.MerchantId', connectionSettingsMap.get('Amazon.MerchantId'));
		setting.put('Amazon.MarketPlaceId', connectionSettingsMap.get('Amazon.MarketPlaceId'));
		setting.put('Amazon.SyncStartDate', connectionSettingsMap.get('Amazon.SyncStartDate'));
		setting.put('Amazon.SalesFunnel', connectionSettingsMap.get('Amazon.SalesFunnel'));
		setting.put('Amazon.Credential', connectionSettingsMap.get('Amazon.Credential'));
		TouchCRBase.TouchCRHelper.setSettings(setting);


		AmazonExecuteConnectorSync connectorSync = new AmazonExecuteConnectorSync();
		DateTime now = Datetime.now();
		now = now.addSeconds(10);

		String cronExpr = String.valueOf( now.second() ) + ' ' + String.valueOf( now.minute() ) + ' ' + String.valueOf( now.hour() ) + ' ' +
				+ String.valueOf( now.day() ) + ' ' + String.valueOf( now.month() ) + ' ' + '?' + ' ' + String.valueOf( now.year() );

		System.schedule('AmazonSyncConnector', cronExpr, connectorSync);

		TouchCRBase__Log__c log = new TouchCRBase__Log__c();
		log.TouchCRBase__Event_Type__c = 'AmazonSyncAPIClient';
		log.TouchCRBase__Event_Status__c = 'Success';
		log.TouchCRBase__Event_Description__c = 'AmazonSyncConnector has been scheduled for ' + currentConnectionName + ' connector.\n';

		if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {

			insert log;
		}

	}
}