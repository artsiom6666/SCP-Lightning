@isTest
private class TouchCRAuraActionControllerTest {

	//VOID
	@isTest static void voidTestLighting() {
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];
		Account acc = new Account(
			RecordTypeId = customerRecordType.Id,
			LastName = 'Gerdegedi', FirstName = 'Itsig',
			PersonEmail = 'Gerdegedi.Itsig@gmail.com', Phone = '1234567890',
			BillingStreet = 'Vulture St, Woolloongabba', BillingCity = 'Brisbane',
			BillingState = 'Queensland', BillingPostalCode = '4102',
			BillingCountry = 'Australia', ShippingStreet = 'Vulture St, Woolloongabba',
			ShippingCity = 'Brisbane', ShippingState = 'Queensland',
			ShippingPostalCode = '4102', ShippingCountry = 'Australia'
			//Geolocation__Longitude__s = 153.062496, Geolocation__Latitude__s = -27.579233
		);
		insert acc;

		TouchCRBase__Order__c order = new TouchCRBase__Order__c(
			TouchCRBase__Charge_Amount__c = 1,
			TouchCRBase__Account__c = acc.Id
		);
		insert order;
		
		TouchCRBase__Order_Transaction__c testTrans = new TouchCRBase__Order_Transaction__c(
			TouchCRBase__Order__c = order.Id,
			TouchCRBase__Named_Agent__c = 'Test Agent Name',
			TouchCRBase__Type__c = 'Charge',
			TouchCRBase__Response_Status__c = 'Approved',
			TouchCRBase__Payment_Date__c = Datetime.now(),
			TouchCRBase__Amount__c = 1
		);
		insert testTrans;

		Decimal amount = TouchCRAuraActionController.getAmountVoid(testTrans.Id);
		System.assertEquals(1, amount);

		String resultVoid = TouchCRAuraActionController.voidNow(testTrans.Id, 1);
		System.assertEquals(true, resultVoid.containsIgnoreCase('Your transaction has been approved.'));
	}


	//CHARGE
	@isTest static void chargeTest() {
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];
		Account acc = new Account(RecordTypeId = customerRecordType.Id, LastName = 'Barack', PersonEmail = 'barack123@mail.com');
		insert acc;

		Date validBy = Date.newInstance(2021, 11, 1);

		TouchCRBase__Payment_Information__c paymentInformation = new TouchCRBase__Payment_Information__c(
			TouchCRBase__ValidBy__c = validBy, TouchCRBase__Information__c = '', TouchCRBase__Number__c = '4242', TouchCRBase__Account__c = acc.Id
		);
		insert paymentInformation;

		TouchCRBase__Payment_Option__c pO = new TouchCRBase__Payment_Option__c(
			TouchCRBase__Account__c = acc.Id, TouchCRBase__Last_4__c = '4242', TouchCRBase__Payment_Information__c = paymentInformation.Id,
			TouchCRBase__Named_Agent__c = 'TouchCRAgent', TouchCRBase__Option_Id__c = 'card_1BLxQaBtLSRuiG8TeSq0hPwu', 
			TouchCRBase__Profile_Id__c = 'cus_BjppUFrz7daGx4', TouchCRBase__Status__c = 'Active'
		);
		TouchCRBase__Payment_Option__c pO1 = new TouchCRBase__Payment_Option__c(
			TouchCRBase__Account__c = acc.Id, TouchCRBase__Last_4__c = '4242', TouchCRBase__Payment_Information__c = paymentInformation.Id,
			TouchCRBase__Named_Agent__c = 'TouchCRAgent', TouchCRBase__Option_Id__c = 'card_1BLxQaBtLSRuiG8TeSq0hPwu', 
			TouchCRBase__Profile_Id__c = 'cus_BjppUFrz7daGx4', TouchCRBase__Status__c = 'Inactive'
		); 
		insert new List<TouchCRBase__Payment_Option__c>{pO, pO1};

		TouchCRBase__Order__c testOrdCrarge = new TouchCRBase__Order__c(
			TouchCRBase__Charge_Amount__c = 2, TouchCRBase__Account__c = acc.Id, 
			TouchCRBase__Named_Agent__c = 'TouchCRAgent'
		);
		insert testOrdCrarge;

		String resultCardsAndGeneralInfo = TouchCRAuraActionController.getCardsAndGeneralInfo(testOrdCrarge.Id);
		ResultWrapper chargeDataWrapper = (ResultWrapper)JSON.deserialize(resultCardsAndGeneralInfo, ResultWrapper.class);
			
		System.assertEquals('success', chargeDataWrapper.status);
		System.assertEquals(2, chargeDataWrapper.amount);

		resultCardsAndGeneralInfo = TouchCRAuraActionController.getCardsAndGeneralInfo('');
		chargeDataWrapper = (ResultWrapper)JSON.deserialize(resultCardsAndGeneralInfo, ResultWrapper.class);
			
		System.assertEquals('error', chargeDataWrapper.status);

		Map<String, String> chargeData = new Map<String, String>{
			'amount' => '2',
			'orderId' => String.valueOf(testOrdCrarge.Id),
			'month' => '01',
			'newCard' => 'true'
		};

		String resultChargeOrderNow = TouchCRAuraActionController.chargeOrderNow(JSON.serialize(chargeData));
		ResultWrapper chargeOrderWrapper = (ResultWrapper)JSON.deserialize(resultChargeOrderNow, ResultWrapper.class);
		
		System.assertEquals('error', chargeOrderWrapper.status);    
		System.assertEquals('Data is not valid', chargeOrderWrapper.error); 

		chargeData = new Map<String, String>{
			'amount' => '2',
			'orderId' => String.valueOf(testOrdCrarge.Id),
			'newCard' => 'false'
		};

		resultChargeOrderNow = TouchCRAuraActionController.chargeOrderNow(JSON.serialize(chargeData));
		chargeOrderWrapper = (ResultWrapper)JSON.deserialize(resultChargeOrderNow, ResultWrapper.class);

		System.assertEquals('error', chargeOrderWrapper.status);    

		chargeData = new Map<String, String>{
			'orderId' => String.valueOf(testOrdCrarge.Id),
			'newCard' => 'false',
			'chosenPaymentOptionId' => String.valueOf(pO.Id)
		};

		resultChargeOrderNow = TouchCRAuraActionController.chargeOrderNow(JSON.serialize(chargeData));
		chargeOrderWrapper = (ResultWrapper)JSON.deserialize(resultChargeOrderNow, ResultWrapper.class);

		System.assertEquals('error', chargeOrderWrapper.status);    
		System.assertEquals('The Amount must not be less than 1 Dollar', chargeOrderWrapper.error); 

		chargeData = new Map<String, String>{
			'amount' => '2',
			'orderId' => String.valueOf(testOrdCrarge.Id),
			'newCard' => 'false',
			'chosenPaymentOptionId' => String.valueOf(pO1.Id)
		};

		resultChargeOrderNow = TouchCRAuraActionController.chargeOrderNow(JSON.serialize(chargeData));
		chargeOrderWrapper = (ResultWrapper)JSON.deserialize(resultChargeOrderNow, ResultWrapper.class);

		System.assertEquals('error', chargeOrderWrapper.status);
		System.assertEquals('Payment Option was not found', chargeOrderWrapper.error);
				
		chargeData = new Map<String, String>{
			'amount' => '2',
			'newCard' => 'false',
			'chosenPaymentOptionId' => String.valueOf(pO.Id)
		};

		resultChargeOrderNow = TouchCRAuraActionController.chargeOrderNow(JSON.serialize(chargeData));
		chargeOrderWrapper = (ResultWrapper)JSON.deserialize(resultChargeOrderNow, ResultWrapper.class);

		System.assertEquals('error', chargeOrderWrapper.status);    
		System.assertEquals('Order Id was not found', chargeOrderWrapper.error);    

		chargeData = new Map<String, String>{
			'amount' => '2',
			'orderId' => String.valueOf(testOrdCrarge.Id),
			'newCard' => 'true',
			'month' => '01',
			'year' => '20',
			'ccv' => '123',
			'cardNumber' => '4242424242424242'
		};

		resultChargeOrderNow = TouchCRAuraActionController.chargeOrderNow(JSON.serialize(chargeData));
		chargeOrderWrapper = (ResultWrapper)JSON.deserialize(resultChargeOrderNow, ResultWrapper.class);
		
		System.assertEquals('error', chargeOrderWrapper.status);
		//todo after add global setCustomSettings method on TouchCRHelper
		//System.assertEquals('success', chargeOrderWrapper.status);    
	}

	private class ResultWrapper {
		public String status { get; set; }
		public String error { get; set; }
		public Decimal amount { get; set; }
	}   


	//REFUND
	@isTest static void refundTestLight() {
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];
		Account acc = new Account(
			RecordTypeId = customerRecordType.Id,
			LastName = 'Gerdegedi', FirstName = 'Itsig',
			PersonEmail = 'Gerdegedi.Itsig@gmail.com', Phone = '1234567890',
			BillingStreet = 'Vulture St, Woolloongabba', BillingCity = 'Brisbane',
			BillingState = 'Queensland', BillingPostalCode = '4102',
			BillingCountry = 'Australia', ShippingStreet = 'Vulture St, Woolloongabba',
			ShippingCity = 'Brisbane', ShippingState = 'Queensland',
			ShippingPostalCode = '4102', ShippingCountry = 'Australia'
		);
		insert acc;

		TouchCRBase__Order__c order = new TouchCRBase__Order__c(
			TouchCRBase__Charge_Amount__c = 1,
			TouchCRBase__Account__c = acc.Id
		);
		insert order;

		TouchCRBase__Order_Transaction__c testTrans = new TouchCRBase__Order_Transaction__c(
			TouchCRBase__Order__c = order.Id,
			TouchCRBase__Named_Agent__c = 'Test Agent Name',
			TouchCRBase__Type__c = 'Charge',
			TouchCRBase__Response_Status__c = 'Approved',
			TouchCRBase__Payment_Date__c = Datetime.now(),
			TouchCRBase__Amount__c = 1
		);
		insert testTrans;

		Decimal amount = TouchCRAuraActionController.getAmountRefund(testTrans.Id);
		System.assertEquals(1, amount);

		String resultRefund = TouchCRAuraActionController.refund(testTrans.Id, 1);
		System.assertEquals(true, resultRefund.containsIgnoreCase('Your transaction has been approved.'));
	}

	//AUTHORIZE
	@isTest static void authorizeTest() {
		Account acc = new Account(
			LastName = 'TestLastName', FirstName = 'TestFirstName',
			PersonEmail = '1290TestEmail0921@gmail.com', Phone = '1234567890',
			BillingStreet = 'TestBStreet', BillingCity = 'TestBCity',
			BillingState = 'Ontario', BillingPostalCode = '4102',
			BillingCountry = 'Canada',
			ShippingStreet = 'TestSStreet',
			ShippingCity = 'TestSCity', ShippingState = 'Ontario',
			ShippingPostalCode = '4102', ShippingCountry = 'Canada'
		);
		insert acc;

		TouchCRBase__Order__c order = new TouchCRBase__Order__c(
			TouchCRBase__Charge_Amount__c = 2,
			TouchCRBase__Account__c = acc.Id
		);
		insert order;

		Decimal amount = TouchCRAuraActionController.getAmountAuthorize(order.Id);
		System.assertEquals(2, amount);

		Map<String, String> authorizeData = new Map<String, String>{
			'cardExpirationMonth' => '01',
			'cardExpirationYear' => '2021',
			'ccv' => '123',
			'cardNumber' => '4242424242424242',
			'recordId' => String.valueOf(order.Id),
			'amount' => String.valueOf(amount)
		};

		String resultAuthorize = TouchCRAuraActionController.authorizeOrderNow(JSON.serialize(authorizeData));
		System.assertEquals(true, resultAuthorize.containsIgnoreCase('success'));
	}


}