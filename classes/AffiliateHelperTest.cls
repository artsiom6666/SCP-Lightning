@isTest
private class AffiliateHelperTest {

	@isTest
	static void createCommissionsEarnedForAffiliateTest() {
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND Name = 'Affiliate Account' AND IsPersonType = true AND IsActive = true];
		Account account1 = new Account(RecordTypeId = customerRecordType.Id, LastName = 'TestLastOne', FirstName = 'Tname', PersonEmail = 'test1@gmail.com', Phone = '1234567890', Affiliate_Approval__c='Approved');
		Account account2 = new Account(RecordTypeId = customerRecordType.Id, LastName = 'TestLastTwo', FirstName = 'Tname', PersonEmail = 'test2@gmail.com', Phone = '1234567890', Affiliate_Approval__c='Approved');
		insert new List<Account> {account1,account2};

		Product2 iceCreamProduct = new Product2(Name = 'iceCreamProduct', ProductCode = 'iceCreamProductCode', IsActive = true );
		Product2 hotCreamProduct = new Product2(Name = 'hotCreamProduct', ProductCode = 'hotCreamProductCode', IsActive = true );
		Product2 notCreamProduct = new Product2(Name = 'notCreamProduct', ProductCode = 'notCreamProductCode', IsActive = true );
		Product2 yetCreamProduct = new Product2(Name = 'yetCreamProduct', ProductCode = 'yetCreamProductCode', IsActive = true );
		insert new List<Product2> {iceCreamProduct, hotCreamProduct, notCreamProduct, yetCreamProduct};

		//RecordType offerCartRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'TouchCRBase__Offer__c' AND DeveloperName = 'Cart'];
		//RecordType offerFunnelRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'TouchCRBase__Offer__c' AND DeveloperName = 'Funnel'];

		List<ApexClass> affiliateclass = [SELECT NamespacePrefix FROM ApexClass WHERE Name ='AffiliateHelperTest' LIMIT 1];
		String nameSpacePrefix= affiliateclass[0].NamespacePrefix;
		nameSpacePrefix = String.isBlank(nameSpacePrefix) ? '' : nameSpacePrefix + '__';

		RecordType offerCartRecordType = [SELECT Id FROM RecordType WHERE SobjectType =: nameSpacePrefix + 'Offer__c' AND DeveloperName = 'Cart'];
		RecordType offerFunnelRecordType = [SELECT Id FROM RecordType WHERE SobjectType =: nameSpacePrefix + 'Offer__c' AND DeveloperName = 'Funnel'];

		Offer__c testOffer1 = new Offer__c(Active__c = false, Offer_Name__c = 'TestOffer1', Commission_Payable__c = 10, Product__c = iceCreamProduct.Id, RecordTypeId = offerCartRecordType.Id );
		Offer__c testOffer2 = new Offer__c(Active__c = false, Offer_Name__c = 'TestOffer2', Commission_Payable__c = 15, Product__c = hotCreamProduct.Id, RecordTypeId = offerFunnelRecordType.Id );
		Offer__c testOffer3 = new Offer__c(Active__c = false, Offer_Name__c = 'TestOffer3', Commission_Payable__c = 20, Product__c = notCreamProduct.Id );
		insert new List<Offer__c> {testOffer1, testOffer2, testOffer3};

		testOffer1.Active__c = true;
		testOffer2.Active__c = true;
		testOffer3.Active__c = true;
		update new List<Offer__c> {testOffer1, testOffer2, testOffer3};

		Affiliate_Offer__c testAffiliateOffer1 = new Affiliate_Offer__c(Account__c = account1.id, Offer__c = testOffer1.id );
		Affiliate_Offer__c testAffiliateOffer2 = new Affiliate_Offer__c(Account__c = account1.id, Offer__c = testOffer2.id );
		Affiliate_Offer__c testAffiliateOffer3 = new Affiliate_Offer__c(Account__c = account2.id, Offer__c = testOffer3.id );
		insert new List<Affiliate_Offer__c> {testAffiliateOffer1, testAffiliateOffer2, testAffiliateOffer3};
		
		TouchCRBase__Order__c order = new TouchCRBase__Order__c(TouchCRBase__Account__c = account2.Id, TouchCRBase__Charge_Amount__c = 1, Affiliate_Id__c = account1.id, TouchCRBase__Order_Source__c = 'Cart' );
		insert order;

		TouchCRBase__OrderItem__c orderItem1 = new TouchCRBase__OrderItem__c(TouchCRBase__Product__c = iceCreamProduct.id, TouchCRBase__Product_Price__c = 100, TouchCRBase__Quantity__c = 8, TouchCRBase__Order__c = order.Id );
		TouchCRBase__OrderItem__c orderItem2 = new TouchCRBase__OrderItem__c(TouchCRBase__Product__c = iceCreamProduct.id, TouchCRBase__Product_Price__c = 150, TouchCRBase__Quantity__c = 4, TouchCRBase__Order__c = order.Id );
		TouchCRBase__OrderItem__c orderItem3 = new TouchCRBase__OrderItem__c(TouchCRBase__Product__c = iceCreamProduct.id, TouchCRBase__Product_Price__c = 200, TouchCRBase__Quantity__c = 2, TouchCRBase__Order__c = order.Id );
		TouchCRBase__OrderItem__c orderItem4 = new TouchCRBase__OrderItem__c(TouchCRBase__Product__c = iceCreamProduct.id, TouchCRBase__Product_Price__c = 250, TouchCRBase__Quantity__c = 1, TouchCRBase__Order__c = order.Id );
		insert new List<TouchCRBase__OrderItem__c> {orderItem1, orderItem2, orderItem3, orderItem4};

		String result;
		Test.startTest();
			AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
			result = controller.createCommissionsEarnedForAffiliate(order);
			System.assertEquals(true,result.contains('true'));
			System.assertEquals(15, [SELECT COUNT() FROM Commissions_Earned__c]);

			result = controller.createCommissionsEarnedForAffiliate(order);
			System.assertEquals(true,result.contains('true'));
			System.assertEquals(30, [SELECT COUNT() FROM Commissions_Earned__c]);

			account1.Affiliate_Approval__c = 'Frozen';
			update account1;
			result = controller.createCommissionsEarnedForAffiliate(order);
			System.assertEquals(true,result.contains('true'));
			System.assertEquals(30, [SELECT COUNT() FROM Commissions_Earned__c]);		
		Test.stopTest();

	}

	@isTest
	static void createRefundCommissionsTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Affiliate_Account' AND SobjectType = 'Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		Account accA = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890');
		insert accA;

		Id pricebookId = Test.getStandardPricebookId();
		Pricebook2 pricebook2 = new Pricebook2(Name = 'Standard Price Book', IsActive = true);
		insert pricebook2;
		Product2 iceCreamProduct = new Product2(Name = 'iceCreamProduct', ProductCode = 'iceCreamProductCode', IsActive = true);
		insert iceCreamProduct;
		insert new List<PricebookEntry> {
			new PricebookEntry(Product2Id = iceCreamProduct.Id, Pricebook2Id = pricebookId, UnitPrice = 100, IsActive = true),
			new PricebookEntry(Product2Id = iceCreamProduct.Id, Pricebook2Id = pricebook2.Id, UnitPrice = 100, IsActive = true)
		};

		TouchCRBase__Order__c orderA = new TouchCRBase__Order__c(TouchCRBase__Account__c = accA.Id, TouchCRBase__Charge_Amount__c = 1, TouchCRBase__Date__c = Datetime.now().addMinutes(-1));
		insert orderA;
		TouchCRBase__OrderItem__c orderItemA = new TouchCRBase__OrderItem__c(TouchCRBase__Order__c = orderA.Id, TouchCRBase__Product__c = iceCreamProduct.Id, TouchCRBase__Quantity__c = 1, TouchCRBase__Product_Price__c = 100);
		insert orderItemA;

		//logic depends on the trigger on the object Payouts__c
		Offer__c offerA = new Offer__c(Commission_Payable__c = 10, Active__c = true);
		insert offerA;
		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Commissions_Earned_for_Withdrawal__c = 10);
		insert affiliateOfferA;
		Commissions_Earned__c commissionA = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferA.id, Offer__c = offerA.Id, Commission_Earned__c = 10,
																		Type__c = 'Sales', Status__c = 'Not Available for Withdrawal', Order__c = orderA.id);
		insert commissionA;

		Test.startTest();
		AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
		String result;

		result = controller.createRefundCommissions(orderA.id);
		List<Commissions_Earned__c> testRefundCommissions = [SELECT Id, Commission_Earned__c FROM Commissions_Earned__c WHERE Type__c = 'Refund'];
		System.assertEquals(testRefundCommissions.size(), 1);
		System.assertEquals(testRefundCommissions[0].Commission_Earned__c, -10);
		Test.stopTest();

	}


	@isTest
	static void setAffiliateOfferTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Affiliate_Account' AND IsPersonType = true AND IsActive = true];
		Account acc = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'TestA@gmail.com', Phone = '1234567890');
		insert acc;

		Offer__c offer = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		insert offer;

		Map<String, String> generalData = new Map<String, String> {
			'accountId' => acc.Id,
			'offerId' => offer.Id,
			'sub2' => 'Sub Text 2',
			'sub3' => 'Sub Text 3'
		};

		Test.startTest();
			AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
			String result;
			result = controller.setAffiliateOfferRest(generalData);
			System.assertEquals(true, result.contains('success'));

			generalData = new Map<String, String> {
				'accountId' => acc.Id,
				'offerId' => offer.Id,
				'sub1' => 'Sub Text 1',
				'sub5' => 'Sub Text 5'
			};

			result = controller.setAffiliateOfferRest(generalData);
			System.assertEquals(true, result.contains('success'));
			List<Affiliate_Offer__c> affiliateOffers = [SELECT Id, Sub1__c, Sub2__c, Sub3__c, Sub4__c, Sub5__c FROM Affiliate_Offer__c WHERE Account__c =:acc.Id AND Offer__c =:offer.Id LIMIT 1];
			System.assertEquals(affiliateOffers[0].Sub1__c, 'Sub Text 1');
			System.assertEquals(affiliateOffers[0].Sub2__c, null);
			System.assertEquals(affiliateOffers[0].Sub3__c, null);
			System.assertEquals(affiliateOffers[0].Sub4__c, null);
			System.assertEquals(affiliateOffers[0].Sub5__c, 'Sub Text 5');
			System.assertEquals(affiliateOffers.size(), 1);

			generalData = new Map<String, String> {
				'offerId' => offer.Id
			};

			result = controller.setAffiliateOfferRest(generalData);
			System.assertEquals(true, result.contains('not found'));

			//Wrong IDs
			generalData = new Map<String, String> {
				'accountId' => acc.Id,
				'offerId' => offer.Id,
				'sub1' => 'Sub Text 1',
				'sub5' => 'Sub Text 5',
				'pixelsIds' => acc.Id
			};
			result = controller.setAffiliateOfferRest(generalData);
/*			System.assertEquals(true, result.contains('Wrong Pixel Id'));

			generalData = new Map<String, String> {
				'accountId' => acc.Id,
				'offerId' => acc.Id,
				'sub1' => 'Sub Text 1',
				'sub5' => 'Sub Text 5'
			};
			result = controller.setAffiliateOfferRest(generalData);
			System.assertEquals(true, result.contains('Wrong Offer Id'));

			generalData = new Map<String, String> {
				'accountId' => offer.Id,
				'offerId' => offer.Id,
				'sub1' => 'Sub Text 1',
				'sub5' => 'Sub Text 5'
			};
			result = controller.setAffiliateOfferRest(generalData);
			System.assertEquals(true, result.contains('Wrong Account Id'));
*/
		Test.stopTest();
	}

	@isTest
	static void setAffiliatePayoutTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Affiliate_Account' AND IsPersonType = true AND IsActive = true];
		Account acc = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'TestA@gmail.com', Phone = '1234567890');
		insert acc;

		Offer__c offer = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		insert offer;

		Affiliate_Offer__c affiliateOffer = new Affiliate_Offer__c(Account__c = acc.Id, Offer__c = offer.Id);
		insert affiliateOffer;

		Map<String, String> generalData = new Map<String, String> {
			'accountId' => acc.Id,
			'amountToTransfer' => '0.00',
			'payoutType' => 'Card',
			'fullName' => 'Test Test',
			'cardNumber' => '4242424242424242'
		};

		AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
		String result;
		result = controller.setAffiliatePayoutRest(generalData);
		System.assertEquals(true, result.contains('success'));

		generalData = new Map<String, String> {
			'accountId' => acc.Id,
			'amountToTransfer' => '0.00',
			'payoutType' => 'PayPal',
			'email' => 'test@test.com'
		};

		result = controller.setAffiliatePayoutRest(generalData);
		System.assertEquals(true, result.contains('success'));

		generalData = new Map<String, String> {
			'accountId' => acc.Id,
			'amountToTransfer' => '10'
		};

		result = controller.setAffiliatePayoutRest(generalData);
		System.assertEquals(true, result.contains('error'));

		generalData = new Map<String, String> {
			'amountToTransfer' => '6'
		};

		result = controller.setAffiliatePayoutRest(generalData);
		System.assertEquals(true, result.contains('not found'));
	}


	@isTest
	static void getAffiliateOffersTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Affiliate_Account' AND IsPersonType = true AND IsActive = true];
		Account accA = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', Available_Balance__c = 11.50);
		Account accB = new Account(RecordTypeId = accRT.Id, LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', Available_Balance__c = 8.50);
		Account accC = new Account(RecordTypeId = accRT.Id, LastName = 'CAccount', FirstName = 'First', PersonEmail = 'testC@gmail.com', Phone = '1234567890', Available_Balance__c = 8.50);
		insert new List<Account> {accA, accB, accC};

		Offer__c offerA = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		Offer__c offerB = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		Offer__c offerC = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		insert new List<Offer__c> {offerA, offerB, offerC};

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Sub1__c = 'Sub11', Commissions_Earned__c = 11.50);
		Affiliate_Offer__c affiliateOfferB = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerB.Id, Sub1__c = 'Sub21', Commissions_Earned__c = 8.50);
		Affiliate_Offer__c affiliateOfferC = new Affiliate_Offer__c(Account__c = accB.Id, Offer__c = offerC.Id, Sub1__c = 'Sub31', Commissions_Earned__c = 8.50);
		insert new List<Affiliate_Offer__c> {affiliateOfferA, affiliateOfferB, affiliateOfferC};

		AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
		String result;
		result = controller.getAffiliateOffersRest(new Map<String, String>{'accountId' => accA.Id});
		System.assertEquals(true, result.contains('success'));
		System.assertEquals(true, result.contains('Sub11'));
		System.assertEquals(true, result.contains('Sub21'));
		System.assertEquals(false, result.contains('Sub31'));

		result = controller.getAffiliateOffersRest(new Map<String, String>{'accountId' => accB.Id});
		System.assertEquals(true, result.contains('success'));
		System.assertEquals(true, result.contains('Sub31'));
		System.assertEquals(false, result.contains('Sub11'));
		System.assertEquals(false, result.contains('Sub21'));

		result = controller.getAffiliateOffersRest(new Map<String, String>{'accountId' => accC.Id});
		System.assertEquals(true, result.contains('error'));
	}

	@isTest
	static void setAffiliatePixelTest() {
		RecordType recTypeA = [SELECT Id FROM RecordType WHERE DeveloperName = 'Affiliate_Account' AND SobjectType = 'Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		RecordType recTypeC = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true AND IsActive = true LIMIT 1];

		Account accA = new Account(LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', RecordTypeId = recTypeA.Id);
		Account accP = new Account(LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', RecordTypeId = recTypeC.Id);
		insert new List<Account> {accA, accP};

		AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
		String result;
		result = controller.setAffiliatePixelRest(new Map<String, String>{'accountId' => accA.Id, 'pixelName' => 'pixelNameTest1', 'pixelText' => 'pixelTextTest1'});
		System.assertEquals(true, result.contains('success'));

		Pixels__c insertedPixel = [SELECT Id, Name, Account__c, Pixel_Text__c FROM Pixels__c LIMIT 1];
		System.assertEquals(insertedPixel.Name, 'pixelNameTest1');
		System.assertEquals(insertedPixel.Account__c, accA.Id);
		System.assertEquals(insertedPixel.Pixel_Text__c, 'pixelTextTest1');


		result = controller.setAffiliatePixelRest(new Map<String, String>{'accountId' => accA.Id, 'pixelName' => 'pixelNameTest2', 'pixelText' => 'pixelTextTest2', 'pixelId' => insertedPixel.Id});
		Pixels__c updatedPixel = [SELECT Id, Name, Account__c, Pixel_Text__c FROM Pixels__c LIMIT 1];
		System.assertEquals(updatedPixel.Name, 'pixelNameTest2');
		System.assertEquals(updatedPixel.Account__c, accA.Id);
		System.assertEquals(updatedPixel.Pixel_Text__c, 'pixelTextTest2');

		result = controller.setAffiliatePixelRest(new Map<String, String>{'accountId' => accP.Id, 'pixelName' => 'pixelNameTest3', 'pixelText' => 'pixelTextTest3', 'pixelId' => insertedPixel.Id});
		System.assertEquals(true, result.contains('Affiliate Account was not found'));

		result = controller.setAffiliatePixelRest(new Map<String, String>{'accountId' => accA.Id, 'pixelName' => 'pixelNameTest4', 'pixelId' => insertedPixel.Id});
		System.assertEquals(true, result.contains('Pixel Text was not found'));

		result = controller.setAffiliatePixelRest(new Map<String, String>{'accountId' => accA.Id, 'pixelText' => 'pixelTextTest5', 'pixelId' => insertedPixel.Id});
		System.assertEquals(true, result.contains('Pixel Name was not found'));

		result = controller.setAffiliatePixelRest(new Map<String, String>{'pixelName' => 'pixelNameTest3', 'pixelText' => 'pixelTextTest3', 'pixelId' => insertedPixel.Id});
		System.assertEquals(true, result.contains('Account Id was not found'));

	}

	@isTest
	static void setAffiliateOfferLinkTest() {
		RecordType recTypeA = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Affiliate_Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		RecordType recTypeC = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true AND IsActive = true LIMIT 1];

		Account accA = new Account(LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', RecordTypeId = recTypeA.Id);
		Account accB = new Account(LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', RecordTypeId = recTypeC.Id);
		insert new List<Account> {accA, accB};

		Offer__c offerA = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		Offer__c offerB = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		Offer__c offerC = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		insert new List<Offer__c> {offerA, offerB, offerC};

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Sub1__c = 'Sub11', Commissions_Earned__c = 11.50);
		Affiliate_Offer__c affiliateOfferB = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerB.Id, Sub1__c = 'Sub21', Commissions_Earned__c = 8.50);
		Affiliate_Offer__c affiliateOfferC = new Affiliate_Offer__c(Account__c = accB.Id, Offer__c = offerC.Id, Sub1__c = 'Sub31', Commissions_Earned__c = 8.50);
		insert new List<Affiliate_Offer__c> {affiliateOfferA, affiliateOfferB, affiliateOfferC};

		AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
		String result;
		result = controller.setAffiliateOfferLinkRest(new Map<String, String>{'affiliateOfferId' => affiliateOfferA.Id, 'name' => 'test'});
		System.assertEquals(true, result.contains('success'));

		Affiliate_Offer_Link__c link = [SELECT Id FROM Affiliate_Offer_Link__c WHERE Affiliate_Offer__c =:affiliateOfferA.Id LIMIT 1];

		result = controller.setAffiliateOfferLinkRest(new Map<String, String>{'affiliateOfferLinkId' => link.Id, 'name' => 'test'});
		System.assertEquals(true, result.contains('success'));

		result = controller.setAffiliateOfferLinkRest(new Map<String, String>{'affiliateOfferLinkId' => link.Id});
		System.assertEquals(true, result.contains('Name was not found'));

	}

	@isTest
	static void getAffiliateOfferTest() {
		RecordType recTypeA = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Affiliate_Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		RecordType recTypeC = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true AND IsActive = true LIMIT 1];

		Account accA = new Account(LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', RecordTypeId = recTypeA.Id);
		Account accB = new Account(LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', RecordTypeId = recTypeC.Id);
		insert new List<Account> {accA, accB};

		Offer__c offerA = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		Offer__c offerB = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		Offer__c offerC = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		insert new List<Offer__c> {offerA, offerB, offerC};

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Sub1__c = 'Sub11', Commissions_Earned__c = 11.50);
		Affiliate_Offer__c affiliateOfferB = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerB.Id, Sub1__c = 'Sub21', Commissions_Earned__c = 8.50);
		Affiliate_Offer__c affiliateOfferC = new Affiliate_Offer__c(Account__c = accB.Id, Offer__c = offerC.Id, Sub1__c = 'Sub31', Commissions_Earned__c = 8.50);
		insert new List<Affiliate_Offer__c> {affiliateOfferA, affiliateOfferB, affiliateOfferC};

		String result;
		AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
		result = controller.setAffiliateOfferLinkRest(new Map<String, String>{'affiliateOfferId' => affiliateOfferA.Id, 'name' => 'test'});
		System.assertEquals(true, result.contains('success'));

		result = controller.getAffiliateOfferRest(new Map<String, String>{'affiliateOfferId' => affiliateOfferA.Id});
		System.assertEquals(true, result.contains('success'));

		result = controller.getAffiliateOfferRest(new Map<String, String>{'affiliateOfferId' => affiliateOfferA.Id+'123'});
		System.assertEquals(true, result.contains('error'));
	}


	@isTest
	static void deleteAffiliateOfferLinkTest() {
		Affiliate_Offer_Link__c linkA = new Affiliate_Offer_Link__c (Name = 'TestLink');
		insert linkA;
		AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
		String result;
		result = controller.deleteAffiliateOfferLinkRest(new Map<String, String>{'affiliateOfferLinkId' => linkA.Id});
		System.assertEquals(true, result.contains('success'));
		result = controller.deleteAffiliateOfferLinkRest(new Map<String, String>{'affiliateOfferLinkId' => 'invalidID'});
		System.assertEquals(true, result.contains('error'));
	}


	@isTest
	static void deletePixelRestTest() {
		Pixels__c pixelA = new Pixels__c (Name = 'TestPixel');
		insert pixelA;
		AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
		String result;
		result = controller.deletePixelRest(new Map<String, String>{'pixelId' => pixelA.Id});
		System.assertEquals(true, result.contains('success'));
		result = controller.deletePixelRest(new Map<String, String>{'pixelId' => 'invalidID'});
		System.assertEquals(true, result.contains('error'));
	}

	@isTest
	static void getPixelRestTest() {
		Pixels__c pixelA = new Pixels__c (Name = 'TestPixel', Pixel_Text__c = 'Pixel Text');
		insert pixelA;
		AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
		String result;
		result = controller.getPixelRest(new Map<String, String>{'pixelId' => pixelA.Id});
		System.assertEquals(true, result.contains('success'));
		System.assertEquals(true, result.contains('Pixel Text'));
		result = controller.getPixelRest(new Map<String, String>{'pixelId' => 'invalidID'});
		System.assertEquals(true, result.contains('error'));
	}


	@isTest
	static void getPixelsTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Affiliate_Account' AND SobjectType = 'Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		Account accA = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', Affiliate_Approval__c = 'Frozen');
		Account accB = new Account(RecordTypeId = accRT.Id, LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', Affiliate_Approval__c = 'Approved');
		Account accC = new Account(RecordTypeId = accRT.Id, LastName = 'CAccount', FirstName = 'First', PersonEmail = 'testC@gmail.com', Phone = '1234567890');
		insert new List<Account> {accA, accB, accC};

		Pixels__c pixelA = new Pixels__c (Name = 'PixelNameA', Account__c = accA.Id, Pixel_Text__c = 'PixelAText');
		Pixels__c pixelB = new Pixels__c (Name = 'PixelNameB', Account__c = accA.Id, Pixel_Text__c = 'PixelBText');
		Pixels__c pixelC = new Pixels__c (Name = 'PixelNameC', Account__c = accB.Id, Pixel_Text__c = 'PixelCText');
		insert new List<Pixels__c> {pixelA, pixelB, pixelC};

		AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
		String result;
		result = controller.getPixelsRest(new Map<String, String>{'accountId' => accA.Id});
		System.assertEquals(true, result.contains('PixelAText'));
		System.assertEquals(true, result.contains('PixelBText'));
		System.assertEquals(false, result.contains('PixelCText'));

		result = controller.getPixelsRest(new Map<String, String>{'accountId' => accB.Id});
		System.assertEquals(true, result.contains('PixelCText'));
		System.assertEquals(false, result.contains('PixelBText'));
		System.assertEquals(false, result.contains('PixelAText'));

		result = controller.getPixelsRest(new Map<String, String>{'accountId' => accC.Id});
		System.assertEquals(true, result.contains('not found'));

		result = controller.getPixelsRest(new Map<String, String>{'accountId' => 'InvalidId'});
		System.assertEquals(true, result.contains('error'));
	}


	@isTest
	static void getPayoutsTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Affiliate_Account' AND SobjectType = 'Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		Account accA = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890');
		Account accB = new Account(RecordTypeId = accRT.Id, LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890');
		Account accC = new Account(RecordTypeId = accRT.Id, LastName = 'CAccount', FirstName = 'First', PersonEmail = 'testC@gmail.com', Phone = '1234567890');
		insert new List<Account> {accA, accB, accC};

		//logic depends on the trigger on the object Payouts__c
		Offer__c offerA = new Offer__c(Commission_Payable__c = 101, Active__c = true);
		Offer__c offerB = new Offer__c(Commission_Payable__c = 202, Active__c = true);
		insert new List<Offer__c> {offerA, offerB};

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Commissions_Earned_for_Withdrawal__c = 101);
		Affiliate_Offer__c affiliateOfferB = new Affiliate_Offer__c(Account__c = accB.Id, Offer__c = offerB.Id, Commissions_Earned_for_Withdrawal__c = 202);
		insert new List<Affiliate_Offer__c> {affiliateOfferA, affiliateOfferB};

		Payouts__c payoutA = new Payouts__c (Account__c = accA.Id, Amount_Transferred__c = 101, Status__c = 'Waiting For Approval');
		Payouts__c payoutB = new Payouts__c (Account__c = accB.Id, Amount_Transferred__c = 202, Status__c = 'Waiting For Approval');
		insert new List<Payouts__c> {payoutA, payoutB};

		AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
		String result;
		result = controller.getPayoutsRest(new Map<String, String>{'accountId' => accA.Id});
		System.assertEquals(true, result.contains('101'));
		System.assertEquals(false, result.contains('202'));

		result = controller.getPayoutsRest(new Map<String, String>{'accountId' => accB.Id});
		System.assertEquals(true, result.contains('202'));
		System.assertEquals(false, result.contains('101'));

		result = controller.getPayoutsRest(new Map<String, String>{'accountId' => accC.Id});
		System.assertEquals(true, result.contains('not found'));

		result = controller.getPayoutsRest(new Map<String, String>{'accountId' => 'InvalidId'});
		System.assertEquals(true, result.contains('error'));

	}

	@isTest
	static void getAffiliateOfferLinkRestTest() {
		Affiliate_Offer_Link__c linkA = new Affiliate_Offer_Link__c (Name = 'TestLink', Sub1__c = 'Sub1 Text');
		insert linkA;
		AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
		String result;
		result = controller.getAffiliateOfferLinkRest(new Map<String, String>{'affiliateOfferLinkId' => linkA.Id});
		System.assertEquals(true, result.contains('success'));
		System.assertEquals(true, result.contains('Sub1 Text'));
		result = controller.getAffiliateOfferLinkRest(new Map<String, String>{'affiliateOfferLinkId' => 'invalidID'});
		System.assertEquals(true, result.contains('error'));
	}

	@isTest
	static void getPayoutAndCommissionsEarnedTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Affiliate_Account' AND SobjectType = 'Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		Account accA = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890');
		Account accB = new Account(RecordTypeId = accRT.Id, LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890');
		insert new List<Account> {accA, accB};

		//logic depends on the trigger on the object Payouts__c
		Offer__c offerA = new Offer__c(Commission_Payable__c = 101, Active__c = true);
		Offer__c offerB = new Offer__c(Commission_Payable__c = 202, Active__c = true);
		insert new List<Offer__c> {offerA, offerB};

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Commissions_Earned_for_Withdrawal__c = 101);
		Affiliate_Offer__c affiliateOfferB = new Affiliate_Offer__c(Account__c = accB.Id, Offer__c = offerB.Id, Commissions_Earned_for_Withdrawal__c = 202);
		insert new List<Affiliate_Offer__c> {affiliateOfferA, affiliateOfferB};

		Payouts__c payoutA = new Payouts__c (Account__c = accA.Id, Amount_Transferred__c = 101, Status__c = 'Waiting For Approval');
		Payouts__c payoutB = new Payouts__c (Account__c = accB.Id, Amount_Transferred__c = 202, Status__c = 'Waiting For Approval');
		insert new List<Payouts__c> {payoutA, payoutB};

		Commissions_Earned__c commissionsA = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferA.id, Offer__c = offerA.Id, Commission_Earned__c = 50, Status__c = 'Not Available for Withdrawal', Payouts__c = payoutA.Id);
		Commissions_Earned__c commissionsB = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferA.id, Offer__c = offerA.Id, Commission_Earned__c = 51, Status__c = 'Not Available for Withdrawal', Payouts__c = payoutA.Id);
		Commissions_Earned__c commissionsC = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferB.id, Offer__c = offerB.Id, Commission_Earned__c = 62, Status__c = 'Not Available for Withdrawal', Payouts__c = payoutB.Id);
		Commissions_Earned__c commissionsD = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferB.id, Offer__c = offerB.Id, Commission_Earned__c = 140, Status__c = 'Not Available for Withdrawal', Payouts__c = payoutB.Id);
		insert new List<Commissions_Earned__c> {commissionsA, commissionsB, commissionsC, commissionsD};

		AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
		String result;
		result = controller.getPayoutRest(new Map<String, String>{'payoutId' => payoutA.Id});
		System.assertEquals(true, result.contains('101'));
		System.assertEquals(true, result.contains('50'));
		System.assertEquals(true, result.contains('51'));
		System.assertEquals(false, result.contains('202'));

		result = controller.getPayoutRest(new Map<String, String>{'payoutId' => payoutB.Id});
		System.assertEquals(true, result.contains('202'));
		System.assertEquals(true, result.contains('62'));
		System.assertEquals(true, result.contains('140'));
		System.assertEquals(false, result.contains('101'));

		result = controller.getPayoutRest(new Map<String, String>{'payoutId' => 'InvalidId'});
		System.assertEquals(true, result.contains('error'));

		result = controller.getCommissionsEarnedRest(new Map<String, String>{'accountId' => accA.Id});
		System.assertEquals(true, result.contains('50'));
		System.assertEquals(true, result.contains('51'));

		result = controller.getCommissionsEarnedRest(new Map<String, String>{'accountId' => 'InvalidId'});
		System.assertEquals(true, result.contains('error'));
	}


	@isTest
	static void getPayoutsMechanismsForAccountTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Affiliate_Account' AND SobjectType = 'Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		Account accA = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890');
		insert accA;

		Payout_Mechanisms__c mechanism = new Payout_Mechanisms__c (Full_Name__c = 'TestMech', Email__c = 'test1357@testmail.com', Account__c = accA.id);
		insert mechanism;
		AffiliateHelper.AffiliateHelperInnerClass controller = new AffiliateHelper.AffiliateHelperInnerClass();
		List<Map<String, Object>> result;
		result = controller.getPayoutsMechanismsForAccount(accA.id);
		Map<String, Object> testMechanism = result[0];
		String fullNameTest = String.valueOf(testMechanism.get('fullName'));
		System.assertEquals('TestMech', fullNameTest);
	}

}