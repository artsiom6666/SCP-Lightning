public with sharing class AmazonGetReportBatch implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts {

	String reportHeader;
	String productFamily;

	Integer totalSize;
	Integer syncStep;

	Boolean isCreateableLog;
	Boolean isUpdateableProduct;
	Boolean isCreateableProduct;
	Boolean isUpdateablePricebookEntry;
	Boolean isCreateablePricebookEntry;

	public AmazonGetReportBatch() {
		isCreateableLog = (
			Schema.sObjectType.TouchCRBase__Log__c.fields.TouchCRBase__Event_Type__c.isCreateable() &&
			Schema.sObjectType.TouchCRBase__Log__c.fields.TouchCRBase__Event_Description__c.isCreateable() &&
			Schema.sObjectType.TouchCRBase__Log__c.fields.TouchCRBase__Event_Status__c.isCreateable()
		);

		isUpdateableProduct = (
			Schema.sObjectType.Product2.fields.Name.isUpdateable() &&
			Schema.sObjectType.Product2.fields.Description.isUpdateable() &&
			Schema.sObjectType.Product2.fields.TouchCRBase__Connected_Id__c.isUpdateable() &&
			Schema.sObjectType.Product2.fields.IsActive.isUpdateable()
		);

		isCreateableProduct = (
			Schema.sObjectType.Product2.fields.Name.isCreateable() &&
			Schema.sObjectType.Product2.fields.Description.isCreateable() &&
			Schema.sObjectType.Product2.fields.TouchCRBase__Connected_Id__c.isCreateable() &&
			Schema.sObjectType.Product2.fields.IsActive.isCreateable() &&
			Schema.sObjectType.Product2.fields.Family.isCreateable()
		);

		isUpdateablePricebookEntry = Schema.sObjectType.PricebookEntry.fields.UnitPrice.isUpdateable();

		isCreateablePricebookEntry = (
			Schema.sObjectType.PricebookEntry.fields.Product2ID.isCreateable() &&
			Schema.sObjectType.PricebookEntry.fields.Pricebook2ID.isCreateable() &&
			Schema.sObjectType.PricebookEntry.fields.UnitPrice.isCreateable() &&
			Schema.sObjectType.PricebookEntry.fields.IsActive.isCreateable()
		);
	}

	public Iterable<String> start(Database.BatchableContext BC) {

		TouchCRBase__Log__c log = new TouchCRBase__Log__c();
		log.TouchCRBase__Event_Type__c = 'Amazon AmazonGetReportBatch Start';
		log.TouchCRBase__Event_Description__c = '';

		Set<String> settingKeys = new Set<String>();
		settingKeys.add('Amazon.ApiKey');
		settingKeys.add('Amazon.ApiSecret');
		settingKeys.add('Amazon.MerchantId');
		settingKeys.add('Amazon.MarketPlaceId');
		settingKeys.add('Amazon.GeneratedReportId');
		settingKeys.add('Amazon.Brand');

		Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('allSettings');
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

		if (String.isBlank(availableSettings.get('Amazon.GeneratedReportId')) ) {
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c += 'Can not find Amazon GeneratedReportId.\n';
		}

		if (log.TouchCRBase__Event_Status__c == 'Error') {
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
				insert log;
			}
			return new List<String>();
		}


		try {
			productFamily = availableSettings.get('Amazon.Brand');

			String amazonReportTSV = AmazonRequestHelper.GetReport(availableSettings.get('Amazon.ApiKey'), availableSettings.get('Amazon.ApiSecret'),
				availableSettings.get('Amazon.MerchantId'), availableSettings.get('Amazon.MarketPlaceId'), availableSettings.get('Amazon.GeneratedReportId'));

			syncStep = allSettings.containsKey('Amazon.SyncStep') ? Integer.valueOf( allSettings.get('Amazon.SyncStep') ) : -1;
			if (syncStep == 2) {
				Map<String, String> setting = new Map<String, String>();
				setting.put('Amazon.SyncStep', '3');
				TouchCRBase.TouchCRHelper.setSettings(setting);
				syncStep = 3;
			} else {
				log.TouchCRBase__Event_Status__c = 'Error';
				log.TouchCRBase__Event_Description__c += 'You can not run Amazon classes in invalid execution order.\n';

				if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
					insert log;
				}
				return new List<String>();
			}

			totalSize = 0;
			List<String> tsvStrings = amazonReportTSV.split('[\n\r]+');
			system.debug('REPORT DATA: ' + tsvStrings.size());
			reportHeader = tsvStrings.remove(0);

			log.TouchCRBase__Event_Status__c = 'Success';
			log.TouchCRBase__Event_Description__c += 'AmazonGetReportBatch Start.\nProducts count: ' + tsvStrings.size();

			//Delete used sync data
			Map<String, String> setting = new Map<String, String>();
			setting.put('Amazon.GeneratedReportId', '');
			TouchCRBase.TouchCRHelper.setSettings(setting);

			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()){
				insert log;
			}

			return tsvStrings;
		}
		catch (Exception ex) {
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c += ex.getMessage();

			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
				insert log;
			}

			return new List<String>();
		}
	}

	public void execute(Database.BatchableContext BC, List<String> scope) {

		TouchCRBase__Log__c log = new TouchCRBase__Log__c();
		log.TouchCRBase__Event_Type__c = 'Amazon Sync GetReportBatch execute';
		log.TouchCRBase__Event_Description__c = 'Iteration Scope Size: ' + scope.size() + '\n';


		try {
			List<String> header = reportHeader.split('\t');

			Integer namePos = -1;
			Integer descriptionPos = -1;
			Integer pricePos = -1;
			Integer quantityPos = -1;
			Integer skuPos = -1;
			Integer asinPos = -1;

			for (Integer i = 0; i < header.size(); i++) {
				if (header[i] == 'item-name') {
					namePos = i;
				}
				if (header[i] == 'item-description') {
					descriptionPos = i;
				}
				if (header[i] == 'price') {
					pricePos = i;
				}
				if (header[i] == 'quantity') {
					quantityPos = i;
				}
				if (header[i] == 'asin1') {
					asinPos = i;
				}
				if (header[i] == 'seller-sku') {
					skuPos = i;
				}
			}

			List<Product2> productList = new List<Product2>();

			Map<String, Product2> asinProductMap = new Map<String, Product2>();
			Integer duplicationsInReport = 0;

			Map<String, Decimal> asinPriceMap = new Map<String, Decimal>();

			for (String productStr : scope) {
				List<String> productInfo = productStr.split('\t');

				String productName = productInfo.get(namePos);
				String productDescription = productInfo.get(descriptionPos);
				String productPrice = productInfo.get(pricePos);
				String productQuantity = productInfo.get(quantityPos);
				String productASIN = productInfo.get(asinPos);
				String productSKU = productInfo.get(skuPos);

				Product2 prod = new Product2();
				prod.Name = productName;
				prod.Description = productDescription;
				prod.TouchCRBase__Connected_Id__c = productASIN;
				prod.IsActive = true;
				prod.Family = productFamily;
				//some more fields
				prod.TouchCRBase__Connection_Name__c = TouchCRBase.TouchCRHelper.getSettings('Amazon.CurrentConnectionName')
					.get('Amazon.CurrentConnectionName');


				// FIXME
				// skip products without a price
				try {
					asinPriceMap.put(productASIN, Decimal.valueOf(productPrice));

					productList.add(prod);
					if (!asinProductMap.containsKey(prod.TouchCRBase__Connected_Id__c)) {
						asinProductMap.put(prod.TouchCRBase__Connected_Id__c, prod);
					} else {
						duplicationsInReport++;
					}
				}
				catch (Exception e) {
					continue;
				}

			}

			Set<String> incomingASINs = asinProductMap.keySet();

			List<Product2> existingProducts = [SELECT Id, Name, Description, IsActive, TouchCRBase__Connected_Id__c FROM Product2 WHERE TouchCRBase__Connected_Id__c IN :incomingASINs];
			Set<String> existingProductsIDs = new Set<String>();
			for (Product2 prod : existingProducts) {
				if (asinProductMap.containsKey(prod.TouchCRBase__Connected_Id__c)) {
					Product2 pr = asinProductMap.get(prod.TouchCRBase__Connected_Id__c);
					prod.Name = pr.Name;
					prod.Description = pr.Description;
					prod.IsActive = true;
					//some more fields

					existingProductsIDs.add(prod.Id);
					asinProductMap.remove(prod.TouchCRBase__Connected_Id__c);
				}
			}

			if (Product2.Name.getDescribe().isUpdateable() &&
					Product2.Description.getDescribe().isUpdateable() &&
					Product2.TouchCRBase__Connected_Id__c.getDescribe().isUpdateable() &&
					Product2.IsActive.getDescribe().isUpdateable() &&
					Product2.Family.getDescribe().isUpdateable()) {

				update existingProducts;
			}
			else {
				return;
			}




			String standardPBid;

			if (Test.isRunningTest()) {
				standardPBid = Test.getStandardPricebookId();
			}
			else {
				Pricebook2 standardPB = [SELECT Id, Name from Pricebook2 WHERE isStandard=true LIMIT 1];
				standardPBid = standardPB.Id;
			}

			List<PricebookEntry> existingProductsPrices = [SELECT Id, UnitPrice, Product2ID
															FROM PricebookEntry
															WHERE Product2ID IN :existingProductsIDs AND Pricebook2ID = :standardPBid];

			Map<String, PricebookEntry> exProdPBEmap = new Map<String, PricebookEntry>();
			for (PricebookEntry pbe : existingProductsPrices) {
				exProdPBEmap.put(pbe.Product2ID, pbe);
			}

			for (Product2 prod : existingProducts) {
				if (exProdPBEmap.containsKey(prod.Id)) {
					exProdPBEmap.get(prod.Id).UnitPrice = asinPriceMap.get(prod.TouchCRBase__Connected_Id__c);
				}
			}

			if (PricebookEntry.UnitPrice.getDescribe().isUpdateable() &&
				PricebookEntry.Product2ID.getDescribe().isUpdateable() ) {
				update exProdPBEmap.values();
			}


			System.debug('Products To Update Size: ' + existingProducts.size());

			System.debug('Products To Insert Size: ' + asinProductMap.values().size());

			if (Product2.Name.getDescribe().isCreateable() &&
				Product2.Description.getDescribe().isCreateable() &&
				Product2.TouchCRBase__Connected_Id__c.getDescribe().isCreateable() &&
				Product2.IsActive.getDescribe().isCreateable() &&
				Product2.Family.getDescribe().isCreateable() ) {
				insert asinProductMap.values();
			}

			List<PricebookEntry> pbEntries = new List<PricebookEntry>();
			for (String asin : asinPriceMap.keySet()) {
				if (asinProductMap.containsKey(asin)) {
					Product2 prod = asinProductMap.get(asin);
					PricebookEntry pbe = new PricebookEntry (Product2ID=prod.Id, Pricebook2ID=standardPBid,UnitPrice=asinPriceMap.get(asin), IsActive = true);
					pbEntries.add(pbe);
				}
			}

			if (PricebookEntry.Product2ID.getDescribe().isCreateable() &&
				PricebookEntry.Pricebook2ID.getDescribe().isCreateable() &&
				PricebookEntry.UnitPrice.getDescribe().isCreateable() &&
				PricebookEntry.IsActive.getDescribe().isCreateable()) {
				insert pbEntries;
			}

			log.TouchCRBase__Event_Status__c = 'Success';
			log.TouchCRBase__Event_Description__c += 'Inserted products count: ' + asinProductMap.values().size() + '\n';
			log.TouchCRBase__Event_Description__c += 'Updated products count: ' + existingProducts.size() + '\n';
			log.TouchCRBase__Event_Description__c += 'Duplications in report count: ' + duplicationsInReport + '\n';
			log.TouchCRBase__Event_Description__c += 'Inserted PricebookEntries: ' + pbEntries.size() + '\n';
			log.TouchCRBase__Event_Description__c += 'Updated PricebookEntries: ' + exProdPBEmap.values().size() + '\n';

			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
				insert log;
			}
		}
		catch (Exception ex) {
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c += ex.getMessage() + '\n';
			log.TouchCRBase__Event_Description__c += 'Line number: ' + ex.getLineNumber() + '\n';
			log.TouchCRBase__Event_Description__c += 'Cause: ' + ex.getCause() + '\n';
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
				insert log;
			}
		}
	}

	public void finish(Database.BatchableContext BC) {

		if (AmazonProcessingHelper.isSyncAborted() || syncStep != 3) {
			AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getAsyncApexJobId('AmazonGetReportBatch'));
			return;
		}

		TouchCRBase__Log__c log = new TouchCRBase__Log__c();
		log.TouchCRBase__Event_Type__c = 'Amazon AmazonGetReportBatch finish';
		log.TouchCRBase__Event_Description__c = 'Schedule AmazonGetProductCategories\n';

		try {

			AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('Amazon GetProductCategories'));

			DateTime now = Datetime.now();
			now = now.addSeconds(10);
			String year = String.valueOf( now.year() );
			String month = String.valueOf( now.month() );
			String day = String.valueOf( now.day() );
			String hour = String.valueOf( now.hour() );
			String minute = String.valueOf( now.minute() );
			String sec = String.valueOf( now.second() );

			String sch = sec + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;

			String jobID = '';
			if (!Test.isRunningTest()) {
				AmazonGetProductCategories agpc = new AmazonGetProductCategories();
				jobID = System.schedule('Amazon GetProductCategories', sch, agpc);
			}


			log.TouchCRBase__Event_Status__c = 'Success';
			log.TouchCRBase__Event_Description__c += 'jobID: ' + jobID;

			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
				insert log;
			}
		}
		catch (Exception ex) {
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