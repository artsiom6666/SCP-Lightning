public with sharing class AmazonExecuteConnectorSync implements Schedulable {

	String newCurrentConnectionId;
	String newConnectionBrand;
	Boolean isSettingsFailed;

	public AmazonExecuteConnectorSync() {
		isSettingsFailed = false;
	}

	public AmazonExecuteConnectorSync(String usedConnectionId) {
		isSettingsFailed = false;

		TouchCRBase__Log__c log = new TouchCRBase__Log__c();
		log.TouchCRBase__Event_Type__c = 'AmazonExecuteConnectorSync';
		log.TouchCRBase__Event_Description__c = 'Used ConnectionId: ' + usedConnectionId + '\n';

		Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('Amazon.');		
		String newCurrentConnectionId = allSettings.get('Amazon.NextConnectionId');
		String newCurrentConnectionName = allSettings.get('Amazon.NextConnectionName');

		log.TouchCRBase__Event_Status__c += newCurrentConnectionName;

		String connectionsIdsSettings = allSettings.get('Amazon.ConnectionsIDs');
		List<String> connectionsIds = connectionsIdsSettings.split(';');

		String newAvailableConnectionsIds = '';
		String nextConnectionId;		

		for (String connId : connectionsIds) {
			if (connId != usedConnectionId) {
				newAvailableConnectionsIds += connId + ';';

				nextConnectionId = connId != newCurrentConnectionId ? connId : nextConnectionId;
			}
		}
		
		for (TouchCRBase__TouchCRConnection__c conn : [SELECT TouchCRBase__Brand__c FROM TouchCRBase__TouchCRConnection__c WHERE Id = :newCurrentConnectionId]) {
				newConnectionBrand = conn.TouchCRBase__Brand__c;
		}

		String nextConnectionName;
		for (TouchCRBase__TouchCRConnection__c conn : [SELECT Name FROM TouchCRBase__TouchCRConnection__c WHERE Id = :nextConnectionId]) {
				nextConnectionName = conn.Name;
		}		


		log.TouchCRBase__Event_Description__c += 'Current Connection: ' + newCurrentConnectionId + ' ' + newCurrentConnectionName + '\n';


		Map<String, String> newSettingsMap = new Map<String, String>();
		for (TouchCRBase__TouchCRConnectionSetting__c connSet : [SELECT TouchCRBase__TouchCRConnection__c, Name, TouchCRBase__Value__c 
												FROM TouchCRBase__TouchCRConnectionSetting__c 
												WHERE TouchCRBase__TouchCRConnection__c = :newCurrentConnectionId]) {
			newSettingsMap.put(connSet.Name, connSet.TouchCRBase__Value__c);
		}

		if (!newSettingsMap.containsKey('Amazon.SyncStartDate')) {
			newSettingsMap.put('Amazon.SyncStartDate', '2016-01-01');

			TouchCRBase__TouchCRConnectionSetting__c cs = new TouchCRBase__TouchCRConnectionSetting__c();
			cs.Name = 'Amazon.SyncStartDate';
			cs.TouchCRBase__Value__c = '2016-01-01';
			cs.TouchCRBase__TouchCRConnection__c = newCurrentConnectionId;

			if (TouchCRBase__TouchCRConnectionSetting__c.Name.getDescribe().isCreateable() &&
				TouchCRBase__TouchCRConnectionSetting__c.TouchCRBase__Value__c.getDescribe().isCreateable() && 
				TouchCRBase__TouchCRConnectionSetting__c.TouchCRBase__TouchCRConnection__c.getDescribe().isCreateable() ) {
				insert cs;
			}
		}

		if (!newSettingsMap.containsKey('Amazon.SalesFunnel')) {
			newSettingsMap.put('Amazon.SalesFunnel', 'Amazon');

			TouchCRBase__TouchCRConnectionSetting__c cs = new TouchCRBase__TouchCRConnectionSetting__c();
			cs.Name = 'Amazon.SalesFunnel';
			cs.TouchCRBase__Value__c = 'Amazon';
			cs.TouchCRBase__TouchCRConnection__c = newCurrentConnectionId;

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
			if (!newSettingsMap.containsKey(setting)) {
				log.TouchCRBase__Event_Status__c = 'Error';
				log.TouchCRBase__Event_Description__c += 'Not all required settings are provided to Connection: ' + setting + '\n';

				isSettingsFailed = true;

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

		//Current connection values
		setting.put('Amazon.CurrentConnectionID', newCurrentConnectionId);
		setting.put('Amazon.CurrentConnectionName', newCurrentConnectionName);

		//all available connections
		setting.put('Amazon.ConnectionsIDs', newAvailableConnectionsIds);

		//next connection values
		setting.put('Amazon.NextConnectionId', nextConnectionId);
		setting.put('Amazon.NextConnectionName', nextConnectionName);

		//current connection settings
		setting.put('Amazon.ApiKey', newSettingsMap.get('Amazon.ApiKey'));
		setting.put('Amazon.ApiSecret', newSettingsMap.get('Amazon.ApiSecret'));
		setting.put('Amazon.MerchantId', newSettingsMap.get('Amazon.MerchantId'));
		setting.put('Amazon.MarketPlaceId', newSettingsMap.get('Amazon.MarketPlaceId'));
		setting.put('Amazon.SyncStartDate', newSettingsMap.get('Amazon.SyncStartDate'));
		setting.put('Amazon.Brand', newConnectionBrand);
		setting.put('Amazon.SalesFunnel', newSettingsMap.get('Amazon.SalesFunnel'));
		setting.put('Amazon.Credential', newSettingsMap.get('Amazon.Credential'));
		TouchCRBase.TouchCRHelper.setSettings(setting);

		log.TouchCRBase__Event_Status__c = 'Success';
		if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {
			insert log;
		}
	}

	public void execute(SchedulableContext sc) {

		TouchCRBase__Log__c log = new TouchCRBase__Log__c();
		log.TouchCRBase__Event_Type__c = 'Amazon AmazonSyncExecuteConnector execute';
		log.TouchCRBase__Event_Description__c = '';


		try {

			Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('Amazon.');

			AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('AmazonSyncConnector'));
			// Check if previous Sync run still in progress
			if (AmazonProcessingHelper.isSyncInProgress()) {
				log.TouchCRBase__Event_Status__c = 'Warning';
				log.TouchCRBase__Event_Description__c = 'Amazon Sync is already in progress.\n';

				if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {

					insert log;
				}
				return;
			}

			// Check if all settings are provided
			if (isSettingsFailed) {
				return;
			}

			//Request New Amazon Report
			String startDate = allSettings.get('Amazon.SyncStartDate');
			startDate += 'T00%3A00%3A00Z';

			Date today = Date.today();
			String tDay =  String.valueof(today.day());
			String tMonth =  String.valueof(today.month());
			String tYear =  String.valueof(today.year());

			tDay = (tDay.length() == 1) ? '0' + tDay : tDay;
			tMonth = (tMonth.length() == 1) ? '0' + tMonth : tMonth;

			Map<String, String> setting = new Map<String, String>();
			setting.put('Amazon.SyncStep', '1');
			setting.put('Amazon.NextSyncStartDate', tYear + '-' + tMonth + '-' + tDay);
			TouchCRBase.TouchCRHelper.setSettings(setting);

			Date reportStartDate30 = Date.today().addDays(-29);
			String rStartDay = String.valueof(reportStartDate30.day());
			String rStartMonth = String.valueof(reportStartDate30.month());
			rStartDay = (rStartDay.length() == 1) ? '0' + rStartDay : rStartDay;
			rStartMonth = (rStartMonth.length() == 1) ? '0' + rStartMonth : rStartMonth;

			String reportStartDate = reportStartDate30.year() + '-' + rStartMonth + '-' +  rStartDay + 'T00%3A00%3A00Z';

			String endDate = tYear + '-' + tMonth + '-' + tDay + 'T00%3A00%3A00Z';
			

			AmazonRequestHelper.RequestReport(allSettings.get('Amazon.ApiKey'), allSettings.get('Amazon.ApiSecret'),
				allSettings.get('Amazon.MerchantId'), allSettings.get('Amazon.MarketPlaceId'), reportStartDate, endDate);


			//Schedule check Report Request status (_SUBMITTED_ , _IN_PROGRESS_ , _DONE_)			
			AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('Get Amazon Report Request Status'));

			DateTime now = Datetime.now();
			now = now.addSeconds(20);
			String year = String.valueOf( now.year() );
			String month = String.valueOf( now.month() );
			String day = String.valueOf( now.day() );
			String hour = String.valueOf( now.hour() );
			String minute = String.valueOf( now.minute() );
			String sec = String.valueOf( now.second() );
			
			String sch = sec + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;

			if (!Test.isRunningTest()) {
				AmazonGetReportRequestList reportRequestList = new AmazonGetReportRequestList();
				String jobID = System.schedule('Get Amazon Report Request Status', sch, reportRequestList);
			}
			
			log.TouchCRBase__Event_Status__c = 'Success';
			log.TouchCRBase__Event_Description__c += 'Sync Start Date: ' + startDate + '\n';

			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {

				insert log;
			}

			AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('AmazonSyncConnector'));
		}
		catch (Exception ex) {
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c += ex.getMessage() + '\n';
			log.TouchCRBase__Event_Description__c += ex.getCause() + '\n';
			log.TouchCRBase__Event_Description__c += ex.getLineNumber() + '\n';

			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {

				insert log;
			}			
		}
	}
}