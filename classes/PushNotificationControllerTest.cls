@isTest
private class PushNotificationControllerTest {
	public static Account acc;
	public static TouchCRBase__Push_Notification_Topic__c topic;
	public static TouchCRBase__Notification_Environment__c newEnvSiteSetting;
	public static TouchCRBase__Notification_Environment__c newEnvMobileSetting;
	public static Document icon;
	public static TouchCRBase__Notification_Click_Action__c clickAction;

	static void createTestData() {
		RecordType recType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true AND IsActive = true];

		acc = new Account(
			FirstName = 'Test',
			LastName = 'User',
			TouchCRBase__Notification_Token__c = 'Notification_Token__c',
			TouchCRBase__Mobile_Customer_Notification_Token__c = 'Mobile_Customer_Notification_Token__c',
			RecordTypeId = recType.Id
		);
		insert acc;

		topic = new TouchCRBase__Push_Notification_Topic__c(
			TouchCRBase__Title__c = 'title',
			TouchCRBase__Body__c = 'body',
			TouchCRBase__Image__c = 'icon',
			TouchCRBase__Click_Action__c = 'clickAction',
			Name = 'title'
		);
		insert PushNotificationControllerTest.topic;

		TouchCRBase__Push_Notification_Topic_Junction__c junction = new TouchCRBase__Push_Notification_Topic_Junction__c(
			TouchCRBase__Push_Notification_Topic__c = topic.Id,
			TouchCRBase__Account__c = acc.Id
		);
		insert junction;

		newEnvSiteSetting = new TouchCRBase__Notification_Environment__c();
		newEnvSiteSetting.Name = 'site';
		newEnvSiteSetting.TouchCRBase__Key__c = 'testKey';
		insert newEnvSiteSetting;

		newEnvMobileSetting = new TouchCRBase__Notification_Environment__c();
		newEnvMobileSetting.Name = 'mobile';
		newEnvMobileSetting.TouchCRBase__Key__c = 'testKey';
		insert newEnvMobileSetting;

		clickAction = new TouchCRBase__Notification_Click_Action__c();
		clickAction.Name = 'test';
		clickAction.TouchCRBase__Link__c = 'testLink';
		insert clickAction;

		icon = new Document(FolderId = UserInfo.getUserId() ,Name='Test', Body = Blob.ValueOf('TestBlob Value'));
		insert icon;
	}

	static testMethod void getAccountsByIdTest() {
		createTestData();

		Test.startTest();
		String accounts = PushNotificationController.getAccountsApex(null, null, acc.Id);
		Test.stopTest();

		List<PushNotificationController.PicklistOption> accountsDeserialized =
				(List<PushNotificationController.PicklistOption>)JSON.deserialize(accounts, List<PushNotificationController.PicklistOption>.class);
		System.assertEquals(acc.Id, accountsDeserialized[0].value);
	}

	static testMethod void getAccountsBySiteTest() {
		createTestData();

		Test.startTest();
		System.debug(newEnvSiteSetting.Name);
		String accounts = PushNotificationController.getAccountsApex(null, newEnvSiteSetting.Name, null);
		Test.stopTest();

		List<PushNotificationController.PicklistOption> accountsDeserialized =
				(List<PushNotificationController.PicklistOption>)JSON.deserialize(accounts, List<PushNotificationController.PicklistOption>.class);
		System.assertEquals(acc.Id, accountsDeserialized[0].value);
	}

	static testMethod void getAccountsByMobileTest() {
		createTestData();

		Test.startTest();
		String accounts = PushNotificationController.getAccountsApex(null, newEnvMobileSetting.Name, null);
		Test.stopTest();

		List<PushNotificationController.PicklistOption> accountsDeserialized =
				(List<PushNotificationController.PicklistOption>)JSON.deserialize(accounts, List<PushNotificationController.PicklistOption>.class);
		System.assertEquals(acc.Id, accountsDeserialized[0].value);
	}

	static testMethod void getAccountsByTopicTest() {
		createTestData();

		Test.startTest();
		String accounts = PushNotificationController.getAccountsApex(topic.Id, null, null);
		Test.stopTest();

		List<PushNotificationController.PicklistOption> accountsDeserialized =
				(List<PushNotificationController.PicklistOption>)JSON.deserialize(accounts, List<PushNotificationController.PicklistOption>.class);
		System.assertEquals(acc.Id, accountsDeserialized[0].value);
	}

	static testMethod void getTopicsTest() {
		createTestData();

		Test.startTest();
		String topics = PushNotificationController.getTopicsApex();
		Test.stopTest();

		List<PushNotificationController.PicklistOption> topicsDeserialized =
				(List<PushNotificationController.PicklistOption>)JSON.deserialize(topics, List<PushNotificationController.PicklistOption>.class);
		System.assertEquals(topic.Id, topicsDeserialized[0].value);
	}

	static testMethod void getTopicsInfoTest() {
		createTestData();

		Test.startTest();
		String topicsInfo = PushNotificationController.getTopicsInfoApex(topic.Id);
		Test.stopTest();

		PushNotificationController.TopicInfo topicsInfoDeserialized =
				(PushNotificationController.TopicInfo)JSON.deserialize(topicsInfo, PushNotificationController.TopicInfo.class);
		System.assertEquals(topic.TouchCRBase__Title__c, topicsInfoDeserialized.title);
		System.assertEquals(topic.TouchCRBase__Body__c, topicsInfoDeserialized.body);
		System.assertEquals(topic.TouchCRBase__Click_Action__c, topicsInfoDeserialized.clickAction);
		System.assertEquals(topic.TouchCRBase__Image__c, topicsInfoDeserialized.icon);
	}

	static testMethod void getEnvironmentsTest() {
		createTestData();

		Test.startTest();
		String environments = PushNotificationController.getEnvironmentsApex();
		Test.stopTest();

		List<PushNotificationController.PicklistOption> environmentsDeserialized =
				(List<PushNotificationController.PicklistOption>)JSON.deserialize(environments, List<PushNotificationController.PicklistOption>.class);
		System.assertEquals(2, environmentsDeserialized.size());
	}

	static testMethod void getIconsApexTest() {
		createTestData();

		Test.startTest();
		String icons = PushNotificationController.getIconsApex();
		Test.stopTest();

		List<PushNotificationController.PicklistOption> iconsDeserialized =
				(List<PushNotificationController.PicklistOption>)JSON.deserialize(icons, List<PushNotificationController.PicklistOption>.class);
		System.assertEquals(icon.Id, iconsDeserialized[0].value);
	}

	static testMethod void getClickActionsTest() {
		createTestData();

		Test.startTest();
		String clickActions = PushNotificationController.getClickActionsApex();
		List<PushNotificationController.PicklistOption> clickActionsDeserialized =
				(List<PushNotificationController.PicklistOption>)JSON.deserialize(clickActions, List<PushNotificationController.PicklistOption>.class);
		System.assertEquals(1, clickActionsDeserialized.size());
		Test.stopTest();
	}

	static testMethod void saveClickActionsApexTest() {
		createTestData();

		Test.startTest();
		String result = PushNotificationController.saveClickActionApex('TestName', 'TestLink');
		Test.stopTest();

		System.assertEquals('Click Action has been successfuly added!', result);
		List<Map<String, String>> clickActionSettings = TouchCRBase.TouchCRHelper.getCustomSettings('TouchCRBase__Notification_Click_Action__c');
		System.assertEquals(2, clickActionSettings.size());
	}

	static testMethod void sendNotificationWithoutTopicScTest() {
		createTestData();
		List<PushNotificationController.PicklistOption> environments = new List<PushNotificationController.PicklistOption>();
		PushNotificationController.PicklistOption environment = new PushNotificationController.PicklistOption();
		environment.label = newEnvSiteSetting.Name;
		environment.value = newEnvSiteSetting.TouchCRBase__Key__c;
		environments.add(environment);

		Test.startTest();
		Test.SetMock(HttpCallOutMock.class, new PushNotificationMock('sendNotification', false));
		String result = PushNotificationController.sendNotification(JSON.serialize(new List<String>{acc.Id}),
				'Title', 'Icon', 'ClickAction', 'Body', null, JSON.serialize(environments));
		Test.stopTest();

		System.assertEquals('The push notifications have been successfully sended!', result);
	}

	static testMethod void sendNotificationWithTopicScTest() {
		createTestData();
		List<PushNotificationController.PicklistOption> environments = new List<PushNotificationController.PicklistOption>();
		PushNotificationController.PicklistOption environment = new PushNotificationController.PicklistOption();
		environment.label = newEnvMobileSetting.Name;
		environment.value = newEnvMobileSetting.TouchCRBase__Key__c;
		environments.add(environment);

		Test.startTest();
		Test.SetMock(HttpCallOutMock.class, new PushNotificationMock('sendNotification', false));
		String result = PushNotificationController.sendNotification(JSON.serialize(new List<String>{acc.Id}),
				'Title', 'Icon', 'ClickAction', 'Body', topic.Name, JSON.serialize(environments));
		Test.stopTest();

		System.assertEquals('The push notifications have been successfully sended!', result);
	}

	static testMethod void sendNotificationWithoutTopicErrTest() {
		createTestData();
		List<PushNotificationController.PicklistOption> environments = new List<PushNotificationController.PicklistOption>();
		PushNotificationController.PicklistOption environment = new PushNotificationController.PicklistOption();
		environment.label = newEnvSiteSetting.Name;
		environment.value = newEnvSiteSetting.TouchCRBase__Key__c;
		environments.add(environment);

		Test.startTest();
		Test.SetMock(HttpCallOutMock.class, new PushNotificationMock(400, 'Bad Request', 'error : {message : "Invalid parameters."}'));
		String result = PushNotificationController.sendNotification(JSON.serialize(new List<String>{acc.Id}),
				'Title', 'Icon', 'ClickAction', 'Body', null, JSON.serialize(environments));
		Test.stopTest();

		System.assertEquals('Bad Request: error : {message : "Invalid parameters."}', result);
	}

	static testMethod void createTopicTest() {
		createTestData();
		List<PushNotificationController.PicklistOption> environments = new List<PushNotificationController.PicklistOption>();
		PushNotificationController.PicklistOption environment = new PushNotificationController.PicklistOption();
		environment.label = newEnvSiteSetting.Name;
		environment.value = newEnvSiteSetting.TouchCRBase__Key__c;
		environments.add(environment);

		Test.startTest();
		Test.SetMock(HttpCallOutMock.class, new PushNotificationMock('createTopic', false));
		String result = PushNotificationController.createTopic(JSON.serialize(environments),new List<String>{acc.Id},
				'NewTitle', 'NewTitle', 'Icon', 'ClickAction', 'Body');
		Test.stopTest();

		TouchCRBase__Push_Notification_Topic__c newTopic = [
			SELECT Id, Name, TouchCRBase__Body__c, TouchCRBase__Title__c, TouchCRBase__Click_Action__c, TouchCRBase__Image__c, TouchCRBase__Device_Type__c
			FROM TouchCRBase__Push_Notification_Topic__c
			WHERE Name = 'NewTitle'
			LIMIT 1
		];

		System.assertEquals(newTopic.Id, result);
	}

	static testMethod void deleteTopicTest() {
		createTestData();
		List<PushNotificationController.PicklistOption> environments = new List<PushNotificationController.PicklistOption>();
		PushNotificationController.PicklistOption environment = new PushNotificationController.PicklistOption();
		environment.label = newEnvSiteSetting.Name;
		environment.value = newEnvSiteSetting.TouchCRBase__Key__c;
		environments.add(environment);

		Test.startTest();
		Test.SetMock(HttpCallOutMock.class, new PushNotificationMock('createTopic', false));
		String result = PushNotificationController.deleteTopic(JSON.serialize(environments),new List<String>{acc.Id},
				'Title', topic.Id);
		Test.stopTest();

		List<TouchCRBase__Push_Notification_Topic__c> topics = [
			SELECT Id, Name, TouchCRBase__Body__c, TouchCRBase__Title__c, TouchCRBase__Click_Action__c, TouchCRBase__Image__c, TouchCRBase__Device_Type__c
			FROM TouchCRBase__Push_Notification_Topic__c
			WHERE Id =: topic.Id
		];

		System.assertEquals(0, topics.size());
		System.assertEquals('Success', result);
	}
}