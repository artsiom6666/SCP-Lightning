global with sharing class AmazonGetListOrders implements Schedulable {

	String nextToken;

	public AmazonGetListOrders(String token) {
		this.nextToken = token;
	}

	public AmazonGetListOrders() {
		this.nextToken = null;
	}

	global void execute(SchedulableContext sc) {
		AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('Amazon ListOrdersByNextToken'));

		Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('allSettings');
		Integer syncStep = allSettings.containsKey('Amazon.SyncStep') ? Integer.valueOf( allSettings.get('Amazon.SyncStep') ) : -1;
		if (syncStep == 5) {
			Map<String, String> setting = new Map<String, String>();
			setting.put('Amazon.SyncStep', '6');
			TouchCRBase.TouchCRHelper.setSettings(setting);
		} else {
			return;
		}
		
		if (nextToken == null) {
			AmazonGetListOrdersBatch b = new AmazonGetListOrdersBatch();
			if (!AmazonProcessingHelper.isSyncAborted()) {
				Database.executeBatch(b, 30);
			}
		} else {			
			AmazonGetListOrdersBatch b = new AmazonGetListOrdersBatch(nextToken);
			if (!AmazonProcessingHelper.isSyncAborted()) {
				Database.executeBatch(b, 30);
			}
		}
	}
}