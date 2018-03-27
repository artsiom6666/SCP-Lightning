@isTest
private class AmazonSyncAPITest {

	public static void makeTestData() {

		AmazonProcessingHelper.abortSync();

		TouchCRBase__TouchCRConnection__c conn = new TouchCRBase__TouchCRConnection__c();
		conn.TouchCRBase__Brand__c = 'Brand';
		conn.TouchCRBase__Feature__c = 'Amazon';
		conn.Name = 'Connection';
		conn.TouchCRBase__isActive__c = true;
		insert conn;

		TouchCRBase__TouchCRConnectionSetting__c connSet = new TouchCRBase__TouchCRConnectionSetting__c ();
		connSet.Name = 'Amazon.ApiKey';
		connSet.TouchCRBase__Value__c = 'test';
		connSet.TouchCRBase__TouchCRConnection__c = conn.Id;
		insert connSet;

		TouchCRBase__TouchCRConnectionSetting__c connSet1 = new TouchCRBase__TouchCRConnectionSetting__c ();
		connSet1.Name = 'Amazon.ApiSecret';
		connSet1.TouchCRBase__Value__c = 'test';
		connSet1.TouchCRBase__TouchCRConnection__c = conn.Id;
		insert connSet1;

		TouchCRBase__TouchCRConnectionSetting__c connSet2 = new TouchCRBase__TouchCRConnectionSetting__c ();
		connSet2.Name = 'Amazon.MerchantId';
		connSet2.TouchCRBase__Value__c = 'test';
		connSet2.TouchCRBase__TouchCRConnection__c = conn.Id;
		insert connSet2;

		TouchCRBase__TouchCRConnectionSetting__c connSet3 = new TouchCRBase__TouchCRConnectionSetting__c ();
		connSet3.Name = 'Amazon.MarketPlaceId';
		connSet3.TouchCRBase__Value__c = 'test';
		connSet3.TouchCRBase__TouchCRConnection__c = conn.Id;
		insert connSet3;

		TouchCRBase__TouchCRConnectionSetting__c connSet4 = new TouchCRBase__TouchCRConnectionSetting__c ();
		connSet4.Name = 'Amazon.Brand';
		connSet4.TouchCRBase__Value__c = 'test';
		connSet4.TouchCRBase__TouchCRConnection__c = conn.Id;
		insert connSet4;

		TouchCRBase__TouchCRConnectionSetting__c connSet5 = new TouchCRBase__TouchCRConnectionSetting__c ();
		connSet5.Name = 'Amazon.Credential';
		connSet5.TouchCRBase__Value__c = 'test';
		connSet5.TouchCRBase__TouchCRConnection__c = conn.Id;
		insert connSet5;
	}

	public static void makeNotFullTestData() {

		AmazonProcessingHelper.abortSync();

		TouchCRBase__TouchCRConnection__c conn = new TouchCRBase__TouchCRConnection__c();
		conn.TouchCRBase__Brand__c = 'Brand';
		conn.TouchCRBase__Feature__c = 'Amazon';
		conn.Name = 'Connection';
		conn.TouchCRBase__isActive__c = true;
		insert conn;

		TouchCRBase__TouchCRConnection__c conn1 = new TouchCRBase__TouchCRConnection__c();
		conn1.TouchCRBase__Brand__c = 'Brand2';
		conn1.TouchCRBase__Feature__c = 'Amazon';
		conn1.Name = 'Connection2';
		conn1.TouchCRBase__isActive__c = true;
		insert conn1;
	}

	@isTest static void startAmazonSync1() {
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		makeTestData();

		Test.startTest();
		AmazonSyncAPIClient requestList = new AmazonSyncAPIClient();

		AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('AmazonSync'));

		DateTime now = Datetime.now();
		now = now.addSeconds(20);
		String year = String.valueOf( now.year() );
		String month = String.valueOf( now.month() );
		String day = String.valueOf( now.day() );
		String hour = String.valueOf( now.hour() );
		String minute = String.valueOf( now.minute() );
		String sec = String.valueOf( now.second() );

		String sch = sec + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;
		String jobID = System.schedule('AmazonSync', sch, requestList);

		Test.stopTest();

		List<CronTrigger> ct = [select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where CronJobDetail.Name = 'AmazonSync'];
		System.assertEquals(1, ct.size());
	}

	@isTest static void startAmazonSync2() {
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		makeNotFullTestData();

		Test.startTest();
		AmazonSyncAPIClient requestList = new AmazonSyncAPIClient();

		AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('AmazonSync'));

		DateTime now = Datetime.now();
		now = now.addSeconds(20);
		String year = String.valueOf( now.year() );
		String month = String.valueOf( now.month() );
		String day = String.valueOf( now.day() );
		String hour = String.valueOf( now.hour() );
		String minute = String.valueOf( now.minute() );
		String sec = String.valueOf( now.second() );

		String sch = sec + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;
		String jobID = System.schedule('AmazonSync', sch, requestList);

		Test.stopTest();

		List<CronTrigger> ct = [select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where CronJobDetail.Name = 'AmazonSync'];
		System.assertEquals(1, ct.size());
	}

	@isTest static void AmazonExecuteConnectorSyncTest1() {
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		AmazonProcessingHelper.abortSync();

		TouchCRBase__TouchCRConnection__c conn = new TouchCRBase__TouchCRConnection__c();
		conn.TouchCRBase__Brand__c = 'Brand';
		conn.TouchCRBase__Feature__c = 'Amazon';
		conn.Name = 'Connection';
		conn.TouchCRBase__isActive__c = true;
		insert conn;

		TouchCRBase__TouchCRConnectionSetting__c connSet = new TouchCRBase__TouchCRConnectionSetting__c ();
		connSet.Name = 'Amazon.ApiKey';
		connSet.TouchCRBase__Value__c = 'test';
		connSet.TouchCRBase__TouchCRConnection__c = conn.Id;
		insert connSet;

		TouchCRBase__TouchCRConnectionSetting__c connSet1 = new TouchCRBase__TouchCRConnectionSetting__c ();
		connSet1.Name = 'Amazon.ApiSecret';
		connSet1.TouchCRBase__Value__c = 'test';
		connSet1.TouchCRBase__TouchCRConnection__c = conn.Id;
		insert connSet1;

		TouchCRBase__TouchCRConnectionSetting__c connSet2 = new TouchCRBase__TouchCRConnectionSetting__c ();
		connSet2.Name = 'Amazon.MerchantId';
		connSet2.TouchCRBase__Value__c = 'test';
		connSet2.TouchCRBase__TouchCRConnection__c = conn.Id;
		insert connSet2;

		TouchCRBase__TouchCRConnectionSetting__c connSet3 = new TouchCRBase__TouchCRConnectionSetting__c ();
		connSet3.Name = 'Amazon.MarketPlaceId';
		connSet3.TouchCRBase__Value__c = 'test';
		connSet3.TouchCRBase__TouchCRConnection__c = conn.Id;
		insert connSet3;

		TouchCRBase__TouchCRConnectionSetting__c connSet4 = new TouchCRBase__TouchCRConnectionSetting__c ();
		connSet4.Name = 'Amazon.Brand';
		connSet4.TouchCRBase__Value__c = 'test';
		connSet4.TouchCRBase__TouchCRConnection__c = conn.Id;
		insert connSet4;

		TouchCRBase__TouchCRConnectionSetting__c connSet5 = new TouchCRBase__TouchCRConnectionSetting__c ();
		connSet5.Name = 'Amazon.Credential';
		connSet5.TouchCRBase__Value__c = 'test';
		connSet5.TouchCRBase__TouchCRConnection__c = conn.Id;
		insert connSet5;

		TouchCRBase__TouchCRConnection__c conn1 = new TouchCRBase__TouchCRConnection__c();
		conn1.TouchCRBase__Brand__c = 'Brand1';
		conn1.TouchCRBase__Feature__c = 'Amazon';
		conn1.Name = 'Connection1';
		conn1.TouchCRBase__isActive__c = true;
		insert conn1;

		String connections = conn1.Id + ';' + conn.Id + ';';
		Map<String, String> setting = new Map<String, String>();
		setting.put('Amazon.ConnectionsIDs', connections);
		setting.put('Amazon.NextConnectionId', conn.Id);
		setting.put('Amazon.NextConnectionName', conn.Name);
		TouchCRBase.TouchCRHelper.setSettings(setting);

		AmazonExecuteConnectorSync exConn = new AmazonExecuteConnectorSync();
		exConn = new AmazonExecuteConnectorSync(conn1.Id);

		DateTime now = Datetime.now();
		now = now.addSeconds(20);
		String year = String.valueOf( now.year() );
		String month = String.valueOf( now.month() );
		String day = String.valueOf( now.day() );
		String hour = String.valueOf( now.hour() );
		String minute = String.valueOf( now.minute() );
		String sec = String.valueOf( now.second() );

		Test.startTest();
		String sch = sec + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;
		String jobID = System.schedule('AmazonSyncConnector', sch, exConn);
		Test.stopTest();


		Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('Amazon.');
		System.assertEquals( allSettings.get('Amazon.CurrentConnectionName'), 'Connection');
	}

	@isTest static void AmazonExecuteConnectorSyncTest2() {
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		AmazonProcessingHelper.abortSync();

		TouchCRBase__TouchCRConnection__c conn = new TouchCRBase__TouchCRConnection__c();
		conn.TouchCRBase__Brand__c = 'Brand';
		conn.TouchCRBase__Feature__c = 'Amazon';
		conn.Name = 'Connection';
		conn.TouchCRBase__isActive__c = true;
		insert conn;

		TouchCRBase__TouchCRConnection__c conn1 = new TouchCRBase__TouchCRConnection__c();
		conn1.TouchCRBase__Brand__c = 'Brand1';
		conn1.TouchCRBase__Feature__c = 'Amazon';
		conn1.Name = 'Connection1';
		conn1.TouchCRBase__isActive__c = true;
		insert conn1;

		String connections = conn1.Id + ';' + conn.Id;
		Map<String, String> setting = new Map<String, String>();
		setting.put('Amazon.ConnectionsIDs', connections);
		setting.put('Amazon.NextConnectionId', conn.Id);
		setting.put('Amazon.NextConnectionName', conn.Name);
		setting.put('Amazon.CurrentConnectionName', conn1.Name);
		TouchCRBase.TouchCRHelper.setSettings(setting);

		AmazonExecuteConnectorSync exConn = new AmazonExecuteConnectorSync(conn1.Id);

		DateTime now = Datetime.now();
		now = now.addSeconds(20);
		String year = String.valueOf( now.year() );
		String month = String.valueOf( now.month() );
		String day = String.valueOf( now.day() );
		String hour = String.valueOf( now.hour() );
		String minute = String.valueOf( now.minute() );
		String sec = String.valueOf( now.second() );

		Test.startTest();
		String sch = sec + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;
		String jobID = System.schedule('AmazonSyncConnector', sch, exConn);
		Test.stopTest();

		Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('Amazon.');
		System.assertEquals( allSettings.get('Amazon.CurrentConnectionName'), 'Connection1');
	}


	@isTest static void AmazonGetReportRequestList1() {
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		Map<String, String> setting = new Map<String, String>();
		setting.put('Amazon.ApiKey', 'testAPIkey');
		setting.put('Amazon.ApiSecret', 'testSecretkey');
		setting.put('Amazon.MerchantId', 'testMerchantId');
		setting.put('Amazon.MarketPlaceId', 'testMarketplaceId');
		setting.put('Amazon.SyncStartDate', '2016-08-19');
		setting.put('Amazon.Brand', 'testBrand');
		setting.put('Amazon.SyncStep', '1');
		setting.put('Amazon.ReportProcessingStatus', '_SUBMITTED_');
		setting.put('Amazon.ReportRequestId', 'testRequestId');
		//setting.put('Amazon.GeneratedReportId', 'GeneratedReportId');
		TouchCRBase.TouchCRHelper.setSettings(setting);

		List<CronTrigger> scheduledJobs = new List<CronTrigger>();
		scheduledJobs= [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Get Amazon Report Request Status'];
		if (scheduledJobs.size() > 0) {
			System.abortJob(scheduledJobs[0].Id);
		}

		Test.startTest();
		AmazonGetReportRequestList reportRequestList = new AmazonGetReportRequestList();

		DateTime now = Datetime.now();
		now = now.addSeconds(20);
		String year = String.valueOf( now.year() );
		String month = String.valueOf( now.month() );
		String day = String.valueOf( now.day() );
		String hour = String.valueOf( now.hour() );
		String minute = String.valueOf( now.minute() );
		String sec = String.valueOf( now.second() );

		String sch = sec + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;

		String jobID = System.schedule('Get Amazon Report Request Status', sch, reportRequestList);
		Test.stopTest();

		List<CronTrigger> ct = new List<CronTrigger>();
		ct = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Get Amazon Report Request Status'];
		System.assertEquals(0, ct.size());
	}

	@isTest static void AmazonGetReportRequestList2() {
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		Map<String, String> setting = new Map<String, String>();
		setting.put('Amazon.ApiKey', 'testAPIkey');
		TouchCRBase.TouchCRHelper.setSettings(setting);

		List<CronTrigger> scheduledJobs = new List<CronTrigger>();
		scheduledJobs= [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Get Amazon Report Request Status'];
		if (scheduledJobs.size() > 0) {
			System.abortJob(scheduledJobs[0].Id);
		}

		Test.startTest();
		AmazonGetReportRequestList reportRequestList = new AmazonGetReportRequestList();

		DateTime now = Datetime.now();
		now = now.addSeconds(20);
		String year = String.valueOf( now.year() );
		String month = String.valueOf( now.month() );
		String day = String.valueOf( now.day() );
		String hour = String.valueOf( now.hour() );
		String minute = String.valueOf( now.minute() );
		String sec = String.valueOf( now.second() );

		String sch = sec + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;

		String jobID = System.schedule('Get Amazon Report Request Status', sch, reportRequestList);
		Test.stopTest();

		List<CronTrigger> ct = new List<CronTrigger>();
		ct = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Get Amazon Report Request Status'];
		System.assertEquals(0, ct.size());
	}

	@isTest static void AmazonGetReportRequestList3() {
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		Map<String, String> setting = new Map<String, String>();
		setting.put('Amazon.ApiKey', 'testAPIkey');
		setting.put('Amazon.ApiSecret', 'testSecretkey');
		setting.put('Amazon.MerchantId', 'testMerchantId');
		setting.put('Amazon.MarketPlaceId', 'testMarketplaceId');
		setting.put('Amazon.SyncStartDate', '2016-08-19');
		setting.put('Amazon.Brand', 'testBrand');
		setting.put('Amazon.SyncStep', '1');
		setting.put('Amazon.ReportProcessingStatus', '_DONE_');
		setting.put('Amazon.ReportRequestId', 'testRequestId');
		//setting.put('Amazon.GeneratedReportId', 'GeneratedReportId');
		TouchCRBase.TouchCRHelper.setSettings(setting);

		List<CronTrigger> scheduledJobs = new List<CronTrigger>();
		scheduledJobs= [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Get Amazon Report Request Status'];
		if (scheduledJobs.size() > 0) {
			System.abortJob(scheduledJobs[0].Id);
		}

		Test.startTest();
		AmazonGetReportRequestList reportRequestList = new AmazonGetReportRequestList();

		DateTime now = Datetime.now();
		now = now.addSeconds(20);
		String year = String.valueOf( now.year() );
		String month = String.valueOf( now.month() );
		String day = String.valueOf( now.day() );
		String hour = String.valueOf( now.hour() );
		String minute = String.valueOf( now.minute() );
		String sec = String.valueOf( now.second() );

		String sch = sec + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;

		String jobID = System.schedule('Get Amazon Report Request Status', sch, reportRequestList);
		Test.stopTest();

		List<CronTrigger> ct = new List<CronTrigger>();
		ct = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Get Amazon Report Request Status'];
		System.assertEquals(0, ct.size());
	}

	@isTest static void AmazonGetReportRequestList4() {
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		Map<String, String> setting = new Map<String, String>();
		setting.put('Amazon.ApiKey', 'testAPIkey');
		setting.put('Amazon.SyncStep', '1');
		TouchCRBase.TouchCRHelper.setSettings(setting);

		List<CronTrigger> scheduledJobs = new List<CronTrigger>();
		scheduledJobs= [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Get Amazon Report Request Status'];
		if (scheduledJobs.size() > 0) {
			System.abortJob(scheduledJobs[0].Id);
		}

		Test.startTest();
		AmazonGetReportRequestList reportRequestList = new AmazonGetReportRequestList();

		DateTime now = Datetime.now();
		now = now.addSeconds(20);
		String year = String.valueOf( now.year() );
		String month = String.valueOf( now.month() );
		String day = String.valueOf( now.day() );
		String hour = String.valueOf( now.hour() );
		String minute = String.valueOf( now.minute() );
		String sec = String.valueOf( now.second() );

		String sch = sec + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;

		String jobID = System.schedule('Get Amazon Report Request Status', sch, reportRequestList);
		Test.stopTest();

		List<CronTrigger> ct = new List<CronTrigger>();
		ct = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Get Amazon Report Request Status'];
		System.assertEquals(0, ct.size());
	}

	@isTest static void AmazonGetReport1() {
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		String sch = '0 0 ' + Datetime.now().addHours(1).hour() + ' * * ? *';
		AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('AmazonSync'));
		System.schedule('AmazonSync', sch, new AmazonSyncAPIClient());

		Map<String, String> setting = new Map<String, String>();
		setting.put('Amazon.ApiKey', 'testAPIkey');
		setting.put('Amazon.ApiSecret', 'testSecretkey');
		setting.put('Amazon.MerchantId', 'testMerchantId');
		setting.put('Amazon.MarketPlaceId', 'testMarketplaceId');
		setting.put('Amazon.Brand', 'testBrand');
		setting.put('Amazon.SyncStep', '2');
		setting.put('Amazon.GeneratedReportId', 'testReportId');
		TouchCRBase.TouchCRHelper.setSettings(setting);

		Product2 prod = new Product2();
		prod.Name = 'productName';
		prod.Description = 'productDescription';
		prod.TouchCRBase__Connected_Id__c = 'B00K1IXOCC';
		prod.IsActive = true;
		prod.Family = 'Brand';
		insert prod;

		Test.startTest();
		AmazonGetReportBatch getReportBatch = new AmazonGetReportBatch();
		Database.executeBatch(getReportBatch, 200);
		Test.stopTest();

		List<Product2> products = [SELECT Id FROM Product2 WHERE TouchCRBase__Connected_Id__c != null];
		System.assertEquals(products.size(), 6);

	}

	@isTest static void AmazonGetReport2() {
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		Map<String, String> setting = new Map<String, String>();
		setting.put('Amazon.SyncStep', '2');
		setting.put('Amazon.ApiKey', 'testAPIkey');
		TouchCRBase.TouchCRHelper.setSettings(setting);

		Test.startTest();
		AmazonGetReportBatch getReportBatch = new AmazonGetReportBatch();
		Database.executeBatch(getReportBatch, 200);
		Test.stopTest();

		List<Product2> prods = [SELECT Id FROM Product2];
		System.assertEquals(0, prods.size());
	}

	@isTest static void GetProductCategories1() {
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		String sch = '0 0 ' + Datetime.now().addHours(1).hour() + ' * * ? *';
		AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('AmazonSync'));
		System.schedule('AmazonSync', sch, new AmazonSyncAPIClient());

		Map<String, String> setting = new Map<String, String>();
		setting.put('Amazon.ApiKey', 'testAPIkey');
		setting.put('Amazon.ApiSecret', 'testSecretkey');
		setting.put('Amazon.MerchantId', 'testMerchantId');
		setting.put('Amazon.MarketPlaceId', 'testMarketplaceId');
		setting.put('Amazon.Brand', 'testBrand');
		setting.put('Amazon.SyncStep', '3');
		TouchCRBase.TouchCRHelper.setSettings(setting);

		List<Product2> products = new List<Product2>();
		for (Integer i = 0; i < 30; i++) {
			Product2 prod = new Product2();
			prod.Name = 'productName';
			prod.Description = 'productDescription';
			prod.TouchCRBase__Connected_Id__c = String.valueOf(i);
			prod.IsActive = true;
			prod.Family = 'Brand';
			products.add(prod);
		}
		insert products;

		List<CronTrigger> scheduledJobs = new List<CronTrigger>();
		scheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Amazon GetProductCategories'];
		if (scheduledJobs.size() > 0) {
			System.abortJob(scheduledJobs[0].Id);
		}

		Test.startTest();
		AmazonGetProductCategories agpc = new AmazonGetProductCategories();
		String jobID = System.schedule('Amazon GetProductCategories', sch, agpc);
		Test.stopTest();

		List<TouchCRBase__Category__c> cat = [SELECT Id FROM TouchCRBase__Category__c];
		System.assertEquals(0, cat.size());
	}


	@isTest static void GetProductCategories2() {
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		String sch = '0 0 ' + Datetime.now().addHours(1).hour() + ' * * ? *';
		AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('AmazonSync'));
		System.schedule('AmazonSync', sch, new AmazonSyncAPIClient());

		Map<String, String> setting = new Map<String, String>();
		setting.put('Amazon.ApiKey', 'testAPIkey');
		setting.put('Amazon.ApiSecret', 'testSecretkey');
		setting.put('Amazon.MerchantId', 'testMerchantId');
		setting.put('Amazon.MarketPlaceId', 'testMarketplaceId');
		setting.put('Amazon.Brand', 'testBrand');
		setting.put('Amazon.SyncStep', '3');
		TouchCRBase.TouchCRHelper.setSettings(setting);

		List<Product2> products = new List<Product2>();
		for (Integer i = 0; i < 10; i++) {
			Product2 prod = new Product2();
			prod.Name = 'productName';
			prod.Description = 'productDescription';
			prod.TouchCRBase__Connected_Id__c = String.valueOf(i);
			prod.IsActive = true;
			prod.Family = 'Brand';
			products.add(prod);
		}
		insert products;

		List<CronTrigger> scheduledJobs = new List<CronTrigger>();
		scheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Amazon GetProductCategories'];
		if (scheduledJobs.size() > 0) {
			System.abortJob(scheduledJobs[0].Id);
		}

		Test.startTest();
		AmazonGetProductCategories agpc = new AmazonGetProductCategories();
		String jobID = System.schedule('Amazon GetProductCategories', sch, agpc);
		Test.stopTest();

		List<TouchCRBase__Category__c> cat = [SELECT Id FROM TouchCRBase__Category__c];
		System.assertEquals(0, cat.size());
	}

	@isTest static void GetOrders() {
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		String sch = '0 0 ' + Datetime.now().addHours(1).hour() + ' * * ? *';
		AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('AmazonSync'));
		System.schedule('AmazonSync', sch, new AmazonSyncAPIClient());

		Map<String, String> setting = new Map<String, String>();
		setting.put('Amazon.ApiKey', 'testAPIkey');
		setting.put('Amazon.ApiSecret', 'testSecretkey');
		setting.put('Amazon.MerchantId', 'testMerchantId');
		setting.put('Amazon.MarketPlaceId', 'testMarketplaceId');
		setting.put('Amazon.Brand', 'testBrand');
		setting.put('Amazon.SalesFunnel', 'Amazon');
		setting.put('Amazon.SyncStartDate', '2016-08-19');
		setting.put('Amazon.SyncStep', '5');
		TouchCRBase.TouchCRHelper.setSettings(setting);

		List<CronTrigger> scheduledJobs = new List<CronTrigger>();
		scheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Amazon ListOrdersByNextToken'];
		if (scheduledJobs.size() > 0) {
			System.abortJob(scheduledJobs[0].Id);
		}

		AmazonGetListOrders aglo = new AmazonGetListOrders();


		Test.startTest();
		String jobID = System.schedule('Amazon ListOrdersByNextToken', sch, aglo);
		Test.stopTest();

		scheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Amazon ListOrdersByNextToken'];
		System.assertEquals(true, scheduledJobs.isEmpty());
	}

	@isTest static void GetOrdersByToken() {
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		String sch = '0 0 ' + Datetime.now().addHours(1).hour() + ' * * ? *';
		AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('AmazonSync'));
		System.schedule('AmazonSync', sch, new AmazonSyncAPIClient());

		Map<String, String> setting = new Map<String, String>();
		setting.put('Amazon.ApiKey', 'testAPIkey');
		setting.put('Amazon.ApiSecret', 'testSecretkey');
		setting.put('Amazon.MerchantId', 'testMerchantId');
		setting.put('Amazon.MarketPlaceId', 'testMarketplaceId');
		setting.put('Amazon.Brand', 'testBrand');
		setting.put('Amazon.SalesFunnel', 'Amazon');
		setting.put('Amazon.SyncStartDate', '2016-08-19');
		setting.put('Amazon.SyncStep', '5');
		TouchCRBase.TouchCRHelper.setSettings(setting);

		List<CronTrigger> scheduledJobs = new List<CronTrigger>();
		scheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Amazon ListOrdersByNextToken'];
		if (scheduledJobs.size() > 0) {
			System.abortJob(scheduledJobs[0].Id);
		}

		AmazonGetListOrders aglo = new AmazonGetListOrders('testToken');

		Test.startTest();
		String jobID = System.schedule('Amazon ListOrdersByNextToken', sch, aglo);
		Test.stopTest();

		scheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Amazon ListOrdersByNextToken'];
		System.assertEquals(true, scheduledJobs.isEmpty());
	}

	@isTest static void TestBrand() {
		// Mock
		Test.setMock(HttpCalloutMock.class, new AmazonSyncAPIMock());

		String sch = '0 0 ' + Datetime.now().addHours(1).hour() + ' * * ? *';
		AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('AmazonSync'));
		System.schedule('AmazonSync', sch, new AmazonSyncAPIClient());

		// Test data
		Account acc = new Account();
		acc.FirstName = 'TestFirstName';
		acc.LastName = 'TestLastName';
        acc.AmazonAccountId__c = 'm98by0kytny4zn3@marketplace.amazon.com';
        acc.TouchCRBase__Brand_Assortment__c = 'AccBrand1';
        insert acc;

        TouchCRBase__Order__c ord = new TouchCRBase__Order__c();
        ord.TouchCRBase__Brand__c = 'OrderBrand1';
        ord.TouchCRBase__Connected_Id__c = 'm98by0kytny4zn3@marketplace.amazon.com';
        ord.TouchCRBase__Account__c = acc.Id;
        insert ord;
   
		// Settings
		Map<String, String> setting = new Map<String, String>();
		setting.put('Amazon.BuyerEmail', 'm98by0kytny4zn3@marketplace.amazon.com');
		setting.put('Amazon.ApiKey', 'testAPIkey');
		setting.put('Amazon.ApiSecret', 'testSecretkey');
		setting.put('Amazon.MerchantId', 'testMerchantId');
		setting.put('Amazon.MarketPlaceId', 'testMarketPlace');
		setting.put('Amazon.Brand', 'OrderBrand2');
		setting.put('Amazon.SalesFunnel', 'Amazon');
		setting.put('Amazon.SyncStartDate', '2016-08-19');
		setting.put('Amazon.SyncStep', '6');		
		TouchCRBase.TouchCRHelper.setSettings(setting);

		// Batch
		AmazonGetListOrdersBatch b = new AmazonGetListOrdersBatch();

		Test.startTest();
		Database.executeBatch(b, 30);
		Test.stopTest();

		// Check
		List<Account> testAcc = [SELECT Id, (SELECT TouchCRBase__Connected_Id__c, TouchCRBase__Brand__c FROM TouchCRBase__Orders__r) FROM Account];

		System.assertEquals(testAcc.size(), 1);
		System.assertEquals(testAcc[0].TouchCRBase__Orders__r.size(), 2);
		System.assertNotEquals(testAcc[0].TouchCRBase__Orders__r[0].TouchCRBase__Brand__c, testAcc[0].TouchCRBase__Orders__r[1].TouchCRBase__Brand__c);
	}	
}