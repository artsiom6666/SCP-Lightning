global with sharing class AmazonGetProductCategories implements Schedulable {
	global void execute(SchedulableContext sc) {

		AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('Amazon GetProductCategories'));

		Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('allSettings');
		Integer syncStep = allSettings.containsKey('Amazon.SyncStep') ? Integer.valueOf( allSettings.get('Amazon.SyncStep') ) : -1;
		if (syncStep == 3) {
			Map<String, String> setting = new Map<String, String>();
			setting.put('Amazon.SyncStep', '4');
			TouchCRBase.TouchCRHelper.setSettings(setting);
		} else {
			return;
		}

		AmazonGetProductCategoriesBatch b = new AmazonGetProductCategoriesBatch();
		if (!AmazonProcessingHelper.isSyncAborted()) {
			database.executebatch(b, 20);
		}
	}
}