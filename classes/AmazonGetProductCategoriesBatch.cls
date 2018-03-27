public with sharing class AmazonGetProductCategoriesBatch implements Database.Batchable<Product2>, Database.Stateful, Database.AllowsCallouts {

	String query;
	Integer scopeSize = 0;
	Integer syncStep;

	String API_KEY;
	String API_SECRET;
	String MERCHANT_ID;
	String MARKETPLACE_ID;
	String BRAND;

	Boolean isCreateableLog;
	Boolean isCreateableCategory;
	Boolean isUpdateableCategory;
	Boolean isUpdateableProduct;
	// FIXME
	// invalid ASIN for marketplace issue, as connectedid can hold not only amz ids, we'll use connection name as 2nd filter
	public static String connName = TouchCRBase.TouchCRHelper.getSettings('Amazon.CurrentConnectionName').get('Amazon.CurrentConnectionName');

	public AmazonGetProductCategoriesBatch() {

		query = 'SELECT Id, TouchCRBase__Category__c, TouchCRBase__Connected_Id__c ' +
				'FROM Product2 ' +
				'WHERE TouchCRBase__Category__c = null ' +
				'AND TouchCRBase__Connected_Id__c != null ' +
				'AND TouchCRBase__Connection_Name__c = : connName ' +
				'LIMIT 20';

		isCreateableLog = (
			TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
			TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()
		);

		isCreateableCategory = (
			TouchCRBase__Category__c.TouchCRBase__Category_Name__c.getDescribe().isCreateable() &&
			TouchCRBase__Category__c.TouchCRBase__Connected_Id__c.getDescribe().isCreateable() &&
			TouchCRBase__Category__c.TouchCRBase__Brand__c.getDescribe().isCreateable()
		);

		isUpdateableCategory = (
			TouchCRBase__Category__c.TouchCRBase__Connected_Id__c.getDescribe().isUpdateable() &&
			TouchCRBase__Category__c.TouchCRBase__ParentCategory__c.getDescribe().isUpdateable()
		);

		isUpdateableProduct = Product2.TouchCRBase__Category__c.getDescribe().isUpdateable();
	}

	public Iterable<Product2> start(Database.BatchableContext BC) {

		TouchCRBase__Log__c log = new TouchCRBase__Log__c();
		log.TouchCRBase__Event_Type__c = 'Amazon AmazonGetProductCategoriesBatch Start';
		log.TouchCRBase__Event_Description__c = '';

		try {
			Set<String> settingKeys = new Set<String>();
			settingKeys.add('Amazon.ApiKey');
			settingKeys.add('Amazon.ApiSecret');
			settingKeys.add('Amazon.MerchantId');
			settingKeys.add('Amazon.MarketPlaceId');
			settingKeys.add('Amazon.Brand');

			Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('allSettings');

			syncStep = allSettings.containsKey('Amazon.SyncStep') ? Integer.valueOf( allSettings.get('Amazon.SyncStep') ) : -1;
			if (syncStep == 4) {
				Map<String, String> setting = new Map<String, String>();
				setting.put('Amazon.SyncStep', '5');
				TouchCRBase.TouchCRHelper.setSettings(setting);
				syncStep = 5;
			} else {
				log.TouchCRBase__Event_Status__c = 'Error';
				log.TouchCRBase__Event_Description__c += 'You can not run Amazon classes in invalid execution order.\n';

				if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
					insert log;
				}
				return new List<Product2>();
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

			if (log.TouchCRBase__Event_Status__c == 'Error') {
				if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
					TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
					insert log;
				}
				return new List<Product2>();
			}

			API_KEY = availableSettings.get('Amazon.ApiKey');
			API_SECRET = availableSettings.get('Amazon.ApiSecret');
			MERCHANT_ID = availableSettings.get('Amazon.MerchantId');
			MARKETPLACE_ID = availableSettings.get('Amazon.MarketPlaceId');
			BRAND = availableSettings.get('Amazon.Brand');

			List<Product2> products = Database.query(query);
			scopeSize = products.size();
			return products;
		}
		catch (Exception ex) {
			log.TouchCRBase__Event_Status__c = 'Error';
			log.TouchCRBase__Event_Description__c += ex.getMessage();
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
				insert log;
			}
			return new List<Product2>();
		}
	}

	public void execute(Database.BatchableContext BC, List<Product2> scope) {

		TouchCRBase__Log__c log = new TouchCRBase__Log__c();
		log.TouchCRBase__Event_Type__c = 'Amazon AmazonGetProductCategoriesBatch execute';
		log.TouchCRBase__Event_Description__c = '';
		log.TouchCRBase__Event_Description__c += 'Scope Size: ' + scope.size() + '\n';

		try {
			List<AmazonCategory> amzCategories = new List<AmazonCategory>();
			Set<String> amzCategoriesIds = new Set<String>();

			Map<String, String> productIdAmzCategoryId = new Map<String, String>();

			for (Product2 prod : scope) {

				String prodCategory = AmazonRequestHelper.GetProductCategoriesForASIN(API_KEY, API_SECRET, MERCHANT_ID, MARKETPLACE_ID, prod.TouchCRBase__Connected_Id__c);

				Dom.XmlNode self = getXMLCategories(prodCategory);
				List<AmazonCategory> categories = getAmazonCategoriesList(self);

				for (AmazonCategory cat : categories) {
					amzCategoriesIds.add(cat.categoryId);
				}

				amzCategories.addAll(categories);

				for (Dom.XmlNode node : self.getChildElements()) {
					if(node.getName() == 'ProductCategoryId') {
						productIdAmzCategoryId.put(prod.Id, node.getText());
						break;
					}
				}
			}

			List<TouchCRBase__Category__c> existingSFCategories = [SELECT Id, TouchCRBase__Connected_Id__c FROM TouchCRBase__Category__c WHERE TouchCRBase__Connected_Id__c IN :amzCategoriesIds];

			Set<String> existingSFCatrgoriesIds = new Set<String>();

			for (TouchCRBase__Category__c cat : existingSFCategories) {
				existingSFCatrgoriesIds.add(cat.TouchCRBase__Connected_Id__c);
			}


			Map<String, TouchCRBase__Category__c> amzIdSFCategoryMap = new Map<String, TouchCRBase__Category__c>();

			for (AmazonCategory cat : amzCategories) {
				if (!existingSFCatrgoriesIds.contains(cat.categoryId)) {
					TouchCRBase__Category__c sfCategory = new TouchCRBase__Category__c();
					sfCategory.TouchCRBase__Category_Name__c = cat.categoryName;
					sfCategory.TouchCRBase__Connected_Id__c = cat.categoryId;
					sfCategory.TouchCRBase__Brand__c = BRAND;
					sfCategory.TouchCRBase__Connection_Name__c = TouchCRBase.TouchCRHelper.getSettings('Amazon.CurrentConnectionName')
                    .get('Amazon.CurrentConnectionName');

					amzIdSFCategoryMap.put(sfCategory.TouchCRBase__Connected_Id__c, sfCategory);
				}
			}

			if (TouchCRBase__Category__c.TouchCRBase__Category_Name__c.getDescribe().isCreateable() &&
				TouchCRBase__Category__c.TouchCRBase__Connected_Id__c.getDescribe().isCreateable() &&
				TouchCRBase__Category__c.TouchCRBase__Brand__c.getDescribe().isCreateable()) {
				insert amzIdSFCategoryMap.values();
			}


			List<TouchCRBase__Category__c> sfCategoriesToUpdateParent = [SELECT Id, TouchCRBase__Connected_Id__c, TouchCRBase__ParentCategory__c FROM TouchCRBase__Category__c WHERE TouchCRBase__Connected_Id__c IN :amzCategoriesIds];

			Map<String, String> categoryParentCategoryMap = new Map<String, String>();
			for (AmazonCategory cat : amzCategories) {
				categoryParentCategoryMap.put(cat.categoryId, cat.categoryParentId);
			}

			Map<String, String> amzCategoryIDsfCategoryIdMap = new Map<String, String>();
			for (TouchCRBase__Category__c cat : sfCategoriesToUpdateParent) {
				amzCategoryIDsfCategoryIdMap.put(cat.TouchCRBase__Connected_Id__c, cat.Id);
			}

			for (TouchCRBase__Category__c cat : sfCategoriesToUpdateParent) {
				String amzParentId = categoryParentCategoryMap.get(cat.TouchCRBase__Connected_Id__c);
				cat.TouchCRBase__ParentCategory__c = amzCategoryIDsfCategoryIdMap.get(amzParentId);
			}

			if (TouchCRBase__Category__c.TouchCRBase__Connected_Id__c.getDescribe().isUpdateable() &&
				TouchCRBase__Category__c.TouchCRBase__ParentCategory__c.getDescribe().isUpdateable()) {
				update sfCategoriesToUpdateParent;
			}

			Map<String, String> amzCatIdsfCatId = new Map<String, String>();
			for (TouchCRBase__Category__c cat : sfCategoriesToUpdateParent) {
				amzCatIdsfCatId.put(cat.TouchCRBase__Connected_Id__c, cat.Id);
			}

			for (Product2 prod : scope) {
				String amzCatId = productIdAmzCategoryId.get(prod.Id);
				prod.TouchCRBase__Category__c = amzCatIdsfCatId.get(amzCatId);
			}

			if (Product2.TouchCRBase__Category__c.getDescribe().isUpdateable() &&
				Product2.TouchCRBase__Connected_Id__c.getDescribe().isUpdateable()) {
				update scope;
			}

			log.TouchCRBase__Event_Status__c = 'Success';
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
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
				insert log;
			}
		}
	}

	public void finish(Database.BatchableContext BC) {
		if (syncStep != 5) {
			return;
		}

		if (AmazonProcessingHelper.isSyncAborted()) {
			AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('Amazon GetProductCategories'));
			AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getAsyncApexJobId('AmazonGetProductCategoriesBatch'));
			return;
		}

		TouchCRBase__Log__c log = new TouchCRBase__Log__c();
		log.TouchCRBase__Event_Type__c = 'Amazon GetProductCategories finish';
		log.TouchCRBase__Event_Description__c = '';

		try {

			AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('Amazon GetProductCategories'));

			if (scopeSize == 20) {

				AmazonGetProductCategories agpc = new AmazonGetProductCategories();

				DateTime now = Datetime.now();
				now = now.addSeconds(105);
				String year = String.valueOf( now.year() );
				String month = String.valueOf( now.month() );
				String day = String.valueOf( now.day() );
				String hour = String.valueOf( now.hour() );
				String minute = String.valueOf( now.minute() );
				String sec = String.valueOf( now.second() );

				String sch = sec + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;

				Map<String, String> setting = new Map<String, String>();
				setting.put('Amazon.SyncStep', '3');
				TouchCRBase.TouchCRHelper.setSettings(setting);

				String jobID = '';
				if(!Test.isRunningTest()) {
					jobID = System.schedule('Amazon GetProductCategories', sch, agpc);
				}

				log.TouchCRBase__Event_Description__c += 'Amazon GetProductCategories jobID: ' + jobID;

			}
			else {
				AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('Amazon ListOrdersByNextToken'));

				AmazonGetListOrders aglo = new AmazonGetListOrders();

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
				if(!Test.isRunningTest()) {
					jobID = System.schedule('Amazon ListOrdersByNextToken', sch, aglo);
				}
				log.TouchCRBase__Event_Description__c += 'Amazon ListOrdersByNextToken jobID: ' + jobID;
			}

			log.TouchCRBase__Event_Status__c = 'Success';
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
			if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
				TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
				insert log;
			}
		}

	}

	public Dom.XmlNode getXMLCategories(String xmlInput) {

		List<Dom.XmlNode> categories = new List<Dom.XmlNode>();

		Dom.Document doc = new Dom.Document();
		doc.load(xmlInput);

		Dom.XmlNode rootElement = doc.getRootElement();

		for(Dom.XmlNode node : rootElement.getChildElements()) {
			if(node.getName() == 'GetProductCategoriesForASINResult') {
				rootElement = node;
				break;
			}
		}

		for(Dom.XmlNode node : rootElement.getChildElements()) {
			if(node.getName() == 'Self') {
				rootElement = node;
				break;
			}
		}

		return rootElement;
	}

	public List<AmazonCategory> getAmazonCategoriesList (Dom.XmlNode rootElement) {
		List<AmazonCategory> amazonCategories = new List<AmazonCategory>();

		AmazonCategory category = new AmazonCategory();
		Dom.XmlNode parentCategoryNode = null;

		for (Dom.XmlNode node : rootElement.getChildElements()) {
			if(node.getName() == 'ProductCategoryId') {
				category.categoryId = node.getText();
			}
			if(node.getName() == 'ProductCategoryName') {
				category.categoryName = node.getText();
			}
			if(node.getName() == 'Parent') {
				parentCategoryNode = node;

				for (Dom.XmlNode inNode : parentCategoryNode.getChildElements()) {
					if(inNode.getName() == 'ProductCategoryId') {
						category.categoryParentId = inNode.getText();
					}
				}
			}
		}

		if (parentCategoryNode != null) {
			amazonCategories.add(category);
			amazonCategories.addAll(getAmazonCategoriesList(parentCategoryNode));
			return  amazonCategories;
		}
		else {
			amazonCategories.add(category);
			return amazonCategories;
		}
	}

	public class AmazonCategory {
		String categoryId {get; set;}
		String categoryName {get; set;}
		String categoryParentId {get; set;}
	}

}