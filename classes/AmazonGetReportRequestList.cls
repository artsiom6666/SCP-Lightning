global with sharing class AmazonGetReportRequestList implements Schedulable {

	public AmazonGetReportRequestList() {
		
	}

	global void execute(SchedulableContext sc) {

		Boolean isCreateableLog = (
			TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()
		);

		TouchCRBase__Log__c log = new TouchCRBase__Log__c();
		log.TouchCRBase__Event_Type__c = 'Amazon AmazonGetReportRequestList execute';
		log.TouchCRBase__Event_Description__c = '';

		Set<String> settingKeys = new Set<String>();
		settingKeys.add('Amazon.ApiKey');
		settingKeys.add('Amazon.ApiSecret');
		settingKeys.add('Amazon.MerchantId');
		settingKeys.add('Amazon.MarketPlaceId');
		settingKeys.add('Amazon.ReportProcessingStatus');
		settingKeys.add('Amazon.ReportRequestId');

		Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('allSettings');

		Integer syncStep = allSettings.containsKey('Amazon.SyncStep') ? Integer.valueOf( allSettings.get('Amazon.SyncStep') ) : -1;
		if (syncStep != 1) {
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c += 'You can not run Amazon classes in invalid execution order.\n';

			AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('Get Amazon Report Request Status'));

			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
				insert log;
			}
			return;
		}

		Map<String, String> availableSettings = new Map<String, String>();

		for (String key : settingKeys) {
			if (allSettings.containsKey(key)) {
				availableSettings.put(key, allSettings.get(key));
			}
			else {
				log.TouchCRBase__Event_Status__c = 'Error';
				log.TouchCRBase__Event_Description__c += 'Can not find Amazon Setting: ' + key + '\n';
			}
		}

		if (String.isBlank(availableSettings.get('Amazon.ReportRequestId')) ) {
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c += 'Can not find Amazon ReportRequestId.\n';
		}

		if (log.TouchCRBase__Event_Status__c == 'Error') {
			AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('Get Amazon Report Request Status'));
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
				insert log;
			}
			return;
		}

		//Delete scheduled check report request status if scheduled
		AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('Get Amazon Report Request Status'));

		try {
			if (availableSettings.get('Amazon.ReportProcessingStatus') == '_DONE_') {

				log.TouchCRBase__Event_Status__c = 'Success';
				log.TouchCRBase__Event_Description__c += 'Amazon ReportProcessingStatus = _DONE_\n';

				//delete used sync data
				Map<String, String> setting = new Map<String, String>();
				setting.put('Amazon.SyncStep', '2');
				setting.put('Amazon.ReportProcessingStatus', '');
				setting.put('Amazon.ReportRequestId', '');
				TouchCRBase.TouchCRHelper.setSettings(setting);
				
				//get generated report

				if(!Test.isRunningTest()) {
					AmazonGetReportBatch getReportBatch = new AmazonGetReportBatch();
					Database.executeBatch(getReportBatch, 200);
				}

				if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
					insert log;
				}
			}
			else {

				//check status future method
				AmazonRequestHelper.GetReportRequestList(availableSettings.get('Amazon.ApiKey'), availableSettings.get('Amazon.ApiSecret'), 
					availableSettings.get('Amazon.MerchantId'), availableSettings.get('Amazon.MarketPlaceId'), availableSettings.get('Amazon.ReportRequestId'));

				//Schedule class to check Report Request status (_SUBMITTED_ , _IN_PROGRESS_ , _DONE_) later
				DateTime now = Datetime.now();
				now = now.addSeconds(20);
				String year = String.valueOf( now.year() );
				String month = String.valueOf( now.month() );
				String day = String.valueOf( now.day() );
				String hour = String.valueOf( now.hour() );
				String minute = String.valueOf( now.minute() );
				String sec = String.valueOf( now.second() );
				
				String sch = sec + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;
				String jobID = '';

				Map<String, String> setting = new Map<String, String>();
				setting.put('Amazon.SyncStep', '1');
				TouchCRBase.TouchCRHelper.setSettings(setting);

				if(!Test.isRunningTest()) {
					AmazonGetReportRequestList reportRequestList = new AmazonGetReportRequestList();
					jobID = System.schedule('Get Amazon Report Request Status', sch, reportRequestList);
				}

				log.TouchCRBase__Event_Status__c = 'Success';
				log.TouchCRBase__Event_Description__c += 'Amazon ReportProcessingStatus = ' + availableSettings.get('Amazon.ReportProcessingStatus') + '\n';
				log.TouchCRBase__Event_Description__c += 'Amazon GetReportRequestList jobID = ' + jobID + '\n';

				if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
					insert log;
				}

			}
		}
		catch(Exception ex) {
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c += ex.getMessage();

			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
				insert log;
			}
		}
	}
}