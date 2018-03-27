global class CommissionEarnedScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {

		List<AsyncApexJob> jobs = [
			SELECT Id, Status, ApexClassId, ApexClass.Name
			FROM AsyncApexJob
			//WHERE ApexClass.Name IN : TouchCRConfigurationController.NAME_TO_CLASSES.get('RefundPeriod')
			WHERE ApexClass.Name = 'CommissionEarnedBatch'
			AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
		];

		if (jobs.isEmpty()) {
			CommissionEarnedBatch job = new CommissionEarnedBatch();
			database.executebatch(job, 200);
		}


	}
}