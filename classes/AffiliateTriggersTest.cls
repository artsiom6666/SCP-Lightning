@isTest
private class AffiliateTriggersTest {

	// method name: checkForDublicate
	// created: 01/24/2018
	// Author: Stanislau Yarashchuk
	// Create dublicate Affiliate Offer 
	@isTest static void checkForDublicate() {

		List<RecordType> personRecordTypeList = [
			SELECT Id, Name, SobjectType, IsPersonType
			FROM RecordType
			WHERE SobjectType = 'Account' AND DeveloperName = 'Affiliate_Account' AND IsPersonType = true AND IsActive = true
		];

		System.assertEquals(!personRecordTypeList.isEmpty(), true);

		List<Account> accountList = new List<Account>();
		for (Integer i = 0; i < 200; i++) {
			accountList.add(
				new Account(
					RecordTypeId = personRecordTypeList[0].Id, LastName = 'lastName'+i, FirstName = 'FirstName'+i, PersonEmail = 'testA@gmail'+i+'.com', Phone = '123456789'+i
				)
			);
		}
		insert accountList;
		System.assertEquals(accountList.size(), 200);

		List<Offer__c> offerList = new List<Offer__c>();
		for (Integer i = 0; i < 200; i++) {
			offerList.add(
				new Offer__c(
					Active__c = true
				)
			);
		}
		insert offerList;
		System.assertEquals(offerList.size(), 200);


		List<Affiliate_Offer__c> affiliateOfferList = new List<Affiliate_Offer__c>();
		for (Integer i = 0; i < 200; i++) {
			affiliateOfferList.add(
				new Affiliate_Offer__c(
					Account__c = accountList[i].Id, Offer__c = offerList[0].Id
				)
			);
		}
		insert affiliateOfferList;
		System.assertEquals(affiliateOfferList.size(), 200);

		try {
			List<Affiliate_Offer__c> affiliateOfferNewList = new List<Affiliate_Offer__c>();
			for (Integer i = 0; i < 200; i++) {
				affiliateOfferNewList.add(
					new Affiliate_Offer__c(
						Account__c = accountList[i].Id, Offer__c = offerList[0].Id
					)
				);
			}
			insert affiliateOfferNewList;
		} catch(Exception e) {
			System.AssertEquals(e.getMessage().contains('Duplicate record'), true);
		}

	}

	// method name: checkForDublicate
	// created: 01/25/2018
	// Author: Stanislau Yarashchuk
	// Create commissions earned for calculate comissions on the Affiliate Offer record
	@isTest static void recalculateAffiliateOffer1() {

		List<RecordType> personRecordTypeList = [
			SELECT Id, Name, SobjectType, IsPersonType
			FROM RecordType
			WHERE SobjectType = 'Account' AND DeveloperName = 'Affiliate_Account' AND IsPersonType = true AND IsActive = true
		];


		List<Account> accountList = new List<Account>();
		for (Integer i = 0; i < 200; i++) {
			accountList.add(
				new Account(
					RecordTypeId = personRecordTypeList[0].Id, LastName = 'lastName'+i, FirstName = 'FirstName'+i, PersonEmail = 'testA@gmail'+i+'.com', Phone = '123456789'+i
				)
			);
		}
		insert accountList;
		System.assertEquals(accountList.size(), 200);

		List<Offer__c> offerList = new List<Offer__c>();
		for (Integer i = 0; i < 200; i++) {
			offerList.add(
				new Offer__c(
					Active__c = true
				)
			);
		}
		insert offerList;
		System.assertEquals(offerList.size(), 200);


		List<Affiliate_Offer__c> affiliateOfferList = new List<Affiliate_Offer__c>();
		for (Integer i = 0; i < 200; i++) {
			affiliateOfferList.add(
				new Affiliate_Offer__c(
					Account__c = accountList[i].Id, Offer__c = offerList[0].Id
				)
			);
		}
		insert affiliateOfferList;
		System.assertEquals(affiliateOfferList.size(), 200);

		List<TouchCRBase__Order__c> orderList = new List<TouchCRBase__Order__c>();
		for (Integer i = 0; i < 200; i++) {
			orderList.add(
				new TouchCRBase__Order__c(
					TouchCRBase__Subtotal__c = 100
				)
			);
		}
		insert orderList;
		System.assertEquals(orderList.size(), 200);

		List<Commissions_Earned__c> commissionEarnedList = new List<Commissions_Earned__c>();
		for (Integer i = 0; i < 200; i++) {
			commissionEarnedList.add(
				new Commissions_Earned__c(
					Affiliate_Offer__c = affiliateOfferList[0].Id,
					Commission_Earned__c = 10,
					Offer__c = offerList[0].Id,
					Order__c = orderList[i].Id,
					Price__c = 100,
					Status__c = 'Not Available for Withdrawal',
					Type__c = 'Sales'
				)
			);
		}
		insert commissionEarnedList;
		System.assertEquals(commissionEarnedList.size(), 200);

		List<Affiliate_Offer__c> affiliateOfferCalculated = [
			SELECT Id, Name, Commissions_Earned__c, Commissions_Earned_for_Withdrawal__c, Commissions_Paid__c, Commissions_Refunded__c,
				Total_Commissions__c, Commissions_Paid_And_Refunded__c, Commission_Not_Passed_Refund_Period__c, Commissions_Pending_Withdrawal__c, 
				Total_Transactions__c, Refund_Transactions__c, Total_Revenue__c, Average_Order_Value__c
			FROM Affiliate_Offer__c
			WHERE Id = :affiliateOfferList[0].Id
		];

		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned_for_Withdrawal__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Refunded__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Commissions__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid_And_Refunded__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commission_Not_Passed_Refund_Period__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Pending_Withdrawal__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Transactions__c, 200);
		System.assertEquals(affiliateOfferCalculated[0].Refund_Transactions__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Revenue__c, 20000);
		System.assertEquals(affiliateOfferCalculated[0].Average_Order_Value__c, 100);

		for (Commissions_Earned__c item : commissionEarnedList) {
			item.Status__c = 'Available for Withdrawal';
		}
		update commissionEarnedList;

		affiliateOfferCalculated = [
			SELECT Id, Name, Commissions_Earned__c, Commissions_Earned_for_Withdrawal__c, Commissions_Paid__c, Commissions_Refunded__c,
				Total_Commissions__c, Commissions_Paid_And_Refunded__c, Commission_Not_Passed_Refund_Period__c, Commissions_Pending_Withdrawal__c, 
				Total_Transactions__c, Refund_Transactions__c, Total_Revenue__c, Average_Order_Value__c
			FROM Affiliate_Offer__c
			WHERE Id = :affiliateOfferList[0].Id
		];

		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned_for_Withdrawal__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Refunded__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Commissions__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid_And_Refunded__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commission_Not_Passed_Refund_Period__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Pending_Withdrawal__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Transactions__c, 200);
		System.assertEquals(affiliateOfferCalculated[0].Refund_Transactions__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Revenue__c, 20000);
		System.assertEquals(affiliateOfferCalculated[0].Average_Order_Value__c, 100);


		for (Commissions_Earned__c item : commissionEarnedList) {
			item.Status__c = 'Pending Withdrawal';
		}
		update commissionEarnedList;

		affiliateOfferCalculated = [
			SELECT Id, Name, Commissions_Earned__c, Commissions_Earned_for_Withdrawal__c, Commissions_Paid__c, Commissions_Refunded__c,
				Total_Commissions__c, Commissions_Paid_And_Refunded__c, Commission_Not_Passed_Refund_Period__c, Commissions_Pending_Withdrawal__c, 
				Total_Transactions__c, Refund_Transactions__c, Total_Revenue__c, Average_Order_Value__c
			FROM Affiliate_Offer__c
			WHERE Id = :affiliateOfferList[0].Id
		];

		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned_for_Withdrawal__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Refunded__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Commissions__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid_And_Refunded__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commission_Not_Passed_Refund_Period__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Pending_Withdrawal__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Total_Transactions__c, 200);
		System.assertEquals(affiliateOfferCalculated[0].Refund_Transactions__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Revenue__c, 20000);
		System.assertEquals(affiliateOfferCalculated[0].Average_Order_Value__c, 100);

		for (Commissions_Earned__c item : commissionEarnedList) {
			item.Status__c = 'Refund';
			item.Paid__c = true;
		}
		update commissionEarnedList;

		affiliateOfferCalculated = [
			SELECT Id, Name, Commissions_Earned__c, Commissions_Earned_for_Withdrawal__c, Commissions_Paid__c, Commissions_Refunded__c,
				Total_Commissions__c, Commissions_Paid_And_Refunded__c, Commission_Not_Passed_Refund_Period__c, Commissions_Pending_Withdrawal__c, 
				Total_Transactions__c, Refund_Transactions__c, Total_Revenue__c, Average_Order_Value__c
			FROM Affiliate_Offer__c
			WHERE Id = :affiliateOfferList[0].Id
		];

		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned_for_Withdrawal__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Refunded__c, -2000);
		System.assertEquals(affiliateOfferCalculated[0].Total_Commissions__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid_And_Refunded__c, -2000);
		System.assertEquals(affiliateOfferCalculated[0].Commission_Not_Passed_Refund_Period__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Pending_Withdrawal__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Transactions__c, 200);
		System.assertEquals(affiliateOfferCalculated[0].Refund_Transactions__c, 200);
		System.assertEquals(affiliateOfferCalculated[0].Total_Revenue__c, 20000);
		System.assertEquals(affiliateOfferCalculated[0].Average_Order_Value__c, 100);
	}

	@isTest static void commissionsEarnedAndAffiliateOffer() {
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];

		Account accA = new Account(RecordTypeId = customerRecordType.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890');
		insert accA;

		Offer__c offerA = new Offer__c(Commission_Payable__c = 20, Active__c = true);
		insert offerA;

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Sub1__c = 'Sub11', Commissions_Earned__c = 15);
		insert affiliateOfferA;


		//Trigger.isAfter && Trigger.isInsert
		Commissions_Earned__c commissionsEarnedA = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferA.id, Offer__c = offerA.Id, Commission_Earned__c = 10);
		insert commissionsEarnedA;

		Affiliate_Offer__c affiliateOfferTestA = [SELECT Id, Commissions_Earned__c FROM Affiliate_Offer__c LIMIT 1];
		System.assertEquals(10, affiliateOfferTestA.Commissions_Earned__c);

		//Trigger.isAfter && Trigger.isUpdate
		commissionsEarnedA.Commission_Earned__c = 20;
		update commissionsEarnedA;
		Affiliate_Offer__c affiliateOfferTestB = [SELECT Id, Commissions_Earned__c FROM Affiliate_Offer__c LIMIT 1];
		System.assertEquals(20, affiliateOfferTestB.Commissions_Earned__c);

		//Trigger.isAfter && Trigger.isDelete
		delete commissionsEarnedA;
		Affiliate_Offer__c affiliateOfferTestC = [SELECT Id, Commissions_Earned__c FROM Affiliate_Offer__c LIMIT 1];
		System.assertEquals(0, affiliateOfferTestC.Commissions_Earned__c);

	}

	@isTest static void testPercentOfPrice() {

		Product2 iceCreamProduct = new Product2(Name = 'iceCreamProduct', ProductCode = 'iceCreamProductCode', IsActive = true);
		insert iceCreamProduct;

		Id pricebookId = Test.getStandardPricebookId();
		Pricebook2 pricebook2GoldMember = new Pricebook2(Name = 'Gold Member', IsActive = true);
		insert pricebook2GoldMember;

		PricebookEntry bookEntryStandart = new PricebookEntry (Product2Id = iceCreamProduct.Id, UnitPrice = 100, IsActive = true, Pricebook2Id = pricebookId);
		PricebookEntry bookEntryGold = new PricebookEntry (Product2Id = iceCreamProduct.Id, UnitPrice = 50, IsActive = true, Pricebook2Id = pricebook2GoldMember.Id);
		insert new List<PricebookEntry> {bookEntryStandart, bookEntryGold};

		Offer__c offerA = new Offer__c(Active__c = false, Offer_Name__c = 'offerA', Commission_Payable__c = 10, Product__c = iceCreamProduct.Id);
		insert offerA;

		offerA.Active__c = true;
		update offerA;

		Offer_Commission__c offerCommissionGold = new Offer_Commission__c (Percent_Of_Price__c = 10, Pricebook_Eligibility__c = pricebook2GoldMember.id, Offer__c = offerA.id);
		insert offerCommissionGold;
		Offer_Commission__c offerCommissionTestA = [SELECT Id, Commission_Payable__c FROM Offer_Commission__c WHERE Percent_Of_Price__c = 10 LIMIT 1];
		System.assertEquals(offerCommissionTestA.Commission_Payable__c, 5);

		offerCommissionGold.Percent_Of_Price__c = 20;
		update offerCommissionGold;
		Offer_Commission__c offerCommissionTestB = [SELECT Id, Commission_Payable__c FROM Offer_Commission__c WHERE Percent_Of_Price__c = 20 LIMIT 1];
		System.assertEquals(offerCommissionTestB.Commission_Payable__c, 10);
	}

	@isTest static void testFixedAmount() {
		Product2 iceCreamProduct = new Product2(Name = 'iceCreamProduct', ProductCode = 'iceCreamProductCode', IsActive = true );
		insert iceCreamProduct;

		Id pricebookId = Test.getStandardPricebookId();
		Pricebook2 pricebook2GoldMember = new Pricebook2(Name = 'Gold Member', IsActive = true);
		insert pricebook2GoldMember;

		PricebookEntry bookEntryStandart = new PricebookEntry (Product2Id = iceCreamProduct.Id, UnitPrice = 100, IsActive = true, Pricebook2Id = pricebookId);
		PricebookEntry bookEntryGold = new PricebookEntry (Product2Id = iceCreamProduct.Id, UnitPrice = 50, IsActive = true, Pricebook2Id = pricebook2GoldMember.Id);
		insert new List<PricebookEntry> {bookEntryStandart, bookEntryGold};

		Offer__c offerA = new Offer__c(Active__c = false, Offer_Name__c = 'offerA', Commission_Payable__c = 10, Product__c = iceCreamProduct.Id);
		insert offerA;

		offerA.Active__c = true;
		update offerA;

		Offer_Commission__c offerCommissionGold = new Offer_Commission__c (Fixed_Amount__c = 10, Pricebook_Eligibility__c = pricebook2GoldMember.id, Offer__c = offerA.id);
		insert offerCommissionGold;
		Offer_Commission__c offerCommissionTestA = [SELECT Id, Commission_Payable__c FROM Offer_Commission__c WHERE Fixed_Amount__c = 10 LIMIT 1];
		System.assertEquals(offerCommissionTestA.Commission_Payable__c, 10);

		offerCommissionGold.Fixed_Amount__c = 20;
		update offerCommissionGold;
		Offer_Commission__c offerCommissionTestB = [SELECT Id, Commission_Payable__c FROM Offer_Commission__c WHERE Fixed_Amount__c = 20 LIMIT 1];
		System.assertEquals(offerCommissionTestB.Commission_Payable__c, 20);
	}

	//OfferTrigger Test
	@isTest static void testCommissionPayable() {

		RecordType recordTypeItem = [SELECT Id FROM RecordType WHERE DeveloperName = 'Cart' LIMIT 1];

		Product2 iceCreamProduct = new Product2(Name = 'iceCreamProduct', ProductCode = 'iceCreamProductCode', IsActive = true );
		Product2 hotCreamProduct = new Product2(Name = 'hotCreamProduct', ProductCode = 'hotCreamProductCode', IsActive = true );
		insert new List<Product2> {iceCreamProduct, hotCreamProduct};

		Id pricebookId = Test.getStandardPricebookId();
		Pricebook2 pricebook2StandardName = new Pricebook2(Name = 'Standard Price Book', IsActive = true);
		insert pricebook2StandardName;

		PricebookEntry bookEntryA = new PricebookEntry (Product2Id = iceCreamProduct.Id, UnitPrice = 100, IsActive = true, Pricebook2Id = pricebookId);
		PricebookEntry bookEntryB = new PricebookEntry (Product2Id = iceCreamProduct.Id, UnitPrice = 100, IsActive = true, Pricebook2Id = pricebook2StandardName.Id);

		PricebookEntry bookEntryC = new PricebookEntry (Product2Id = hotCreamProduct.Id, UnitPrice = 200, IsActive = true, Pricebook2Id = pricebookId);
		PricebookEntry bookEntryD = new PricebookEntry (Product2Id = hotCreamProduct.Id, UnitPrice = 200, IsActive = true, Pricebook2Id = pricebook2StandardName.Id);
		insert new List<PricebookEntry> {bookEntryA, bookEntryB, bookEntryC, bookEntryD};

		Offer__c offerA = new Offer__c(Active__c = false, Offer_Name__c = 'offerA', Commission_Payable__c = 10, Percent_Of_Price__c = 20, Product__c = iceCreamProduct.Id, RecordTypeId = recordTypeItem.Id);
		Offer__c offerB = new Offer__c(Active__c = false, Offer_Name__c = 'offerB', Commission_Payable__c = 10, Product__c = hotCreamProduct.Id, RecordTypeId = recordTypeItem.Id);
		insert new List<Offer__c> {offerA, offerB};

		offerA.Active__c = true;
		update new List<Offer__c> {offerA, offerB};

		Offer__c testOfferA = [SELECT Id, Commission_Payable__c FROM Offer__c WHERE Offer_Name__c = 'offerA' LIMIT 1];
		System.assertEquals(20, testOfferA.Commission_Payable__c);
		Offer__c testOfferB = [SELECT Id, Commission_Payable__c FROM Offer__c WHERE Offer_Name__c = 'offerB' LIMIT 1];
		System.assertEquals(10, testOfferB.Commission_Payable__c);
	}

	@isTest static void testPayoutTrigger() {

		//Trigger.isBefore && Trigger.isInsert
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];

		Account accA = new Account(RecordTypeId = customerRecordType.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', Available_Balance__c = 10);
		Account accB = new Account(RecordTypeId = customerRecordType.Id, LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', Available_Balance__c = 20);
		Account accC = new Account(RecordTypeId = customerRecordType.Id, LastName = 'CAccount', FirstName = 'First', PersonEmail = 'testC@gmail.com', Phone = '1234567890', Available_Balance__c = 30);
		insert new List<Account> {accA, accB, accC};

		Offer__c offerA = new Offer__c(Commission_Payable__c = 10, Active__c = true);
		Offer__c offerB = new Offer__c(Commission_Payable__c = 20, Active__c = true);
		insert new List<Offer__c> {offerA, offerB};

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Commissions_Earned_for_Withdrawal__c = 10);
		Affiliate_Offer__c affiliateOfferB = new Affiliate_Offer__c(Account__c = accB.Id, Offer__c = offerB.Id, Commissions_Earned_for_Withdrawal__c = 20);
		insert new List<Affiliate_Offer__c> {affiliateOfferA, affiliateOfferB};

		Payouts__c payoutA = new Payouts__c (Account__c = accA.Id, Amount_Transferred__c = 10, Status__c = 'Waiting For Approval');
		insert payoutA;

		Payouts__c payoutInserted = [SELECT Id, Amount_Transferred__c FROM Payouts__c LIMIT 1];
		System.assertEquals(payoutInserted.Amount_Transferred__c, 10);


		//Trigger.isAfter && Trigger.isUpdate
		Commissions_Earned__c commissionEarnedA = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferA.Id, Commission_Earned__c = 10, Payouts__c = payoutA.Id);
		insert commissionEarnedA;

		payoutA.Status__c = 'Approved';
		update payoutA;

		Commissions_Earned__c commissionA = [SELECT Id, Status__c, Payouts__r.Status__c FROM Commissions_Earned__c WHERE Payouts__c =:payoutA.Id LIMIT 1];
		System.assertEquals(commissionA.Status__c, 'Paid');


		//Trigger.isAfter && Trigger.isInsert
		Commissions_Earned__c commissionEarnedB = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferB.Id, Commission_Earned__c = 20, Status__c = 'Available for Withdrawal', Type__c = 'Sales');
		insert commissionEarnedB;
		Payouts__c payoutB = new Payouts__c (Account__c = accB.Id, Amount_Transferred__c = 20, Status__c = 'Waiting For Approval');
		insert payoutB;
		Commissions_Earned__c commissionTest = [SELECT Id, Payouts__c, Status__c FROM Commissions_Earned__c WHERE Affiliate_Offer__c =: affiliateOfferB.Id LIMIT 1];
		System.AssertEquals(commissionTest.Status__c, 'Pending Withdrawal');


		//Trigger.isBefore && Trigger.isInsert Error
		try {
			Payouts__c payoutC = new Payouts__c (Account__c = accC.Id, Amount_Transferred__c = 10, Status__c = 'Waiting For Approval');
			insert payoutC;
		} catch (Exception e){
			Boolean expectedExceptionThrown = (e.getMessage().contains('The amount of the transfer')) ? true : false;
			System.AssertEquals(expectedExceptionThrown, true);
		}

	}

}