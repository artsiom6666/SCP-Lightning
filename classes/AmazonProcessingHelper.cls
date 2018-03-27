public with sharing class AmazonProcessingHelper {

	public static void abortJob(String jobId) {
		if (!String.isBlank(jobId)) {
			System.abortJob(jobId);
		}
	}

	public static String getAsyncApexJobId(String jobName) {
		List<AsyncApexJob> jobs = [
			SELECT Id
			FROM AsyncApexJob
			WHERE ApexClass.Name = :jobName
		];
		return jobs.isEmpty() ? null : jobs.get(0).Id;
	}

	public static String getCronTriggerId(String jobName) {
		List<CronTrigger> jobs = [
			SELECT Id
			FROM CronTrigger
			WHERE CronJobDetail.Name = :jobName
		];
		return (jobs.isEmpty()) ? null : jobs.get(0).Id;
	}

	public static Boolean isSyncAborted() {
		List<CronTrigger> mainSchedulerProgress = [
			SELECT Id, NextFireTime
			FROM CronTrigger
			WHERE CronJobDetail.Name = 'AmazonSync'
		];
		return mainSchedulerProgress.isEmpty() ? true : false;
	}

	public static void abortSync() {
		Set<String> amazonBatches = new Set<String> { 'AmazonGetListOrdersBatch', 'AmazonGetProductCategoriesBatch', 'AmazonGetReportBatch'};
		Set<String> amazonSchedulers = new Set<String> {'AmazonSyncConnector', 'Get Amazon Report Request Status', 
														'Amazon GetProductCategories', 'Amazon ListOrdersByNextToken'};
		for (CronTrigger cron : [
			SELECT Id, NextFireTime
			FROM CronTrigger
			WHERE CronJobDetail.Name IN : amazonSchedulers]) {
			System.abortJob(cron.Id);
		}

		for (AsyncApexJob job : [
			SELECT Id, Status, ApexClassId, ApexClass.Name
			FROM AsyncApexJob
			WHERE ApexClass.Name IN : amazonBatches
			AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')]) {
			System.abortJob(job.Id);
		}
	}

	public static Boolean isSyncInProgress() {
		Set<String> amazonBatches = new Set<String> { 'AmazonGetListOrdersBatch', 'AmazonGetProductCategoriesBatch', 'AmazonGetReportBatch'};
		Set<String> amazonSchedulers = new Set<String> {'AmazonSyncConnector', 'Get Amazon Report Request Status', 
														'Amazon GetProductCategories', 'Amazon ListOrdersByNextToken'};

		List<CronTrigger> schedulersInProgress = [
			SELECT Id, NextFireTime
			FROM CronTrigger
			WHERE CronJobDetail.Name IN : amazonSchedulers
		];

		List<AsyncApexJob> jobsInProgress = [
			SELECT Id, Status, ApexClassId, ApexClass.Name
			FROM AsyncApexJob
			WHERE ApexClass.Name IN : amazonBatches
			AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
		];

		return !schedulersInProgress.isEmpty() || !jobsInProgress.isEmpty() ? true : false;
	}
}