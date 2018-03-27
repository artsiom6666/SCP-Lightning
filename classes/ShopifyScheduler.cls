public with sharing class ShopifyScheduler implements Database.Batchable<sObject> {

	/**
	 * This is start point for each Shopify connection
	 * @return execute first batch
	 */

	public Iterable<sObject> start(Database.BatchableContext BC) {
		return new List<sObject>();
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope) {}

	public void finish(Database.BatchableContext BC) {

		String prevConnectionId = ShopifyProcessingHelper.getPrevConnectionId();

		// get already processed conections
		Set<String> processedConnections = ShopifyProcessingHelper.getPorcessedConnectionsIds();
		Set<String> allActiveConnections = ShopifyProcessingHelper.getActiveConnectionsIds();

		if (prevConnectionId != null) {
			// not first iteration
			ShopifyProcessingHelper.saveSettingsForConnection(prevConnectionId);
			processedConnections.add(prevConnectionId);

			TouchCRBase__Log__c log3 = new TouchCRBase__Log__c();
				log3.TouchCRBase__Event_Type__c = 'Shopify';
				log3.TouchCRBase__Event_Status__c = 'In Progress';
				log3.TouchCRBase__Event_Description__c = 'Saved settings for: '
					+ TouchCRBase.TouchCRHelper.getSettings('Shopify.Brand').get('Shopify.Brand') + '\n'
					+ 'prevConnectionId: ' + prevConnectionId + '\n'
					+ 'processedConnections: ' + processedConnections + '\n'
					+ 'allActiveConnections: ' + allActiveConnections + '\n'
					+ 'Shopify.lastCustomerExternalID: ' + TouchCRBase.TouchCRHelper.getSettings('Shopify.lastCustomerExternalID').get('Shopify.lastCustomerExternalID') + '\n'
					+ 'Shopify.lastOrderExternalID: ' + TouchCRBase.TouchCRHelper.getSettings('Shopify.lastOrderExternalID').get('Shopify.lastOrderExternalID') + '\n'
					+ 'Shopify.lastProductExternalID: ' + TouchCRBase.TouchCRHelper.getSettings('Shopify.lastProductExternalID').get('Shopify.lastProductExternalID');
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {
				insert log3;
			}
		}
		// unprocessed connection left?
		allActiveConnections.removeAll(processedConnections);

		if (allActiveConnections.isEmpty()) {
			TouchCRBase__Log__c log2 = new TouchCRBase__Log__c();
				log2.TouchCRBase__Event_Type__c = 'Shopify';
				log2.TouchCRBase__Event_Status__c = 'Finished';
				log2.TouchCRBase__Event_Description__c = 'Done\n' +
				+ 'prevConnectionId: ' + prevConnectionId + '\n'
				+ 'processedConnections: ' + processedConnections + '\n'
				+ 'allActiveConnections: ' + allActiveConnections;
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {
				insert log2;
			}

			ShopifyProcessingHelper.cleanConnectionSettings();
			return;
		}

		// smth left for processing
		String connectionToProcess = new List<String>(allActiveConnections).get(0);

		ShopifyProcessingHelper.setPrevConnectionId(connectionToProcess);
		ShopifyProcessingHelper.setPorcessedConnectionsIds(processedConnections);
		//
		if (ShopifyProcessingHelper.loadSettingsForConnection(connectionToProcess)) {
			TouchCRBase__Log__c log1 = new TouchCRBase__Log__c();
				log1.TouchCRBase__Event_Type__c = 'Shopify';
				log1.TouchCRBase__Event_Status__c = 'In Progress';
				log1.TouchCRBase__Event_Description__c = 'Loaded settings for: '
					+ TouchCRBase.TouchCRHelper.getSettings('Shopify.Brand').get('Shopify.Brand') + '\n'
					+ 'prevConnectionId: ' + prevConnectionId + '\n'
					+ 'processedConnections: ' + processedConnections + '\n'
					+ 'allActiveConnections: ' + allActiveConnections + '\n'
					+ 'connectionToProcess: ' + connectionToProcess + '\n'
					+ 'Shopify.lastCustomerExternalID: ' + TouchCRBase.TouchCRHelper.getSettings('Shopify.lastCustomerExternalID').get('Shopify.lastCustomerExternalID') + '\n'
					+ 'Shopify.lastOrderExternalID: ' + TouchCRBase.TouchCRHelper.getSettings('Shopify.lastOrderExternalID').get('Shopify.lastOrderExternalID') + '\n'
					+ 'Shopify.lastProductExternalID: ' + TouchCRBase.TouchCRHelper.getSettings('Shopify.lastProductExternalID').get('Shopify.lastProductExternalID');
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable() ) {
				insert log1;
			}
			// FIXME
			// skip customers
			Database.executeBatch(new ShopifyProductBatch(), 100);
		}
	}
}