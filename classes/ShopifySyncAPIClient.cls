global class ShopifySyncAPIClient implements Schedulable, Database.Batchable<sObject> {

	/**
	 * Global Shopify connector manager
	 * This is entry point for Shopify
	 *
	 * It is scheduled on conf page
	 */

	public void execute(SchedulableContext sc) {
		if (ShopifyProcessingHelper.isReadyToStart()) {
			ShopifySyncAPIClient b = new ShopifySyncAPIClient();
			database.executebatch(b);
		}
	}

	public Iterable<sObject> start(Database.BatchableContext BC) {
		return new List<sObject>();
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope) {}

	public void finish(Database.BatchableContext BC) {

		// solution, to execute as a batch
		// possible as execute now functionality

		if (ShopifyProcessingHelper.isReadyToStart()) {

			TouchCRBase__Log__c log = new TouchCRBase__Log__c();
				log.TouchCRBase__Event_Type__c = 'Shopify';
				log.TouchCRBase__Event_Status__c = 'Success';
				log.TouchCRBase__Event_Description__c = 'Shopify Sync is ready to start.';

			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
				insert log;
			}

			/* in case smth went wrong, and we are going to start connector, clean prev settings */
			ShopifyProcessingHelper.cleanConnectionSettings();

			for (String shopifySchName : ShopifyProcessingHelper.SHOPIFY_SCHEDULERS) {
				System.scheduleBatch(new ShopifyScheduler(), shopifySchName, 1);
			}
		}
		else {

			TouchCRBase__Log__c log = new TouchCRBase__Log__c();
				log.TouchCRBase__Event_Type__c = 'Shopify';
				log.TouchCRBase__Event_Status__c = 'Warning';
				log.TouchCRBase__Event_Description__c = 'Shopify Sync is not ready to start.\nShopify active connection missing OR Sync already in progress.';

			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {
				insert log;
			}
		}
	}
}