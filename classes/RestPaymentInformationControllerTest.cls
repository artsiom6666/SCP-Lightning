@isTest
private class RestPaymentInformationControllerTest {
	
	@isTest static void test_rest_payment_information() {
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true AND IsActive = true];
		Account acc = new Account(
			RecordTypeId = customerRecordType.Id,
			LastName = 'Gerdegedi', FirstName = 'Itsig',
			PersonEmail = 'Gerdegedi.Itsig@gmail.com', Phone = '1234567890',
			BillingStreet = 'Vulture St, Woolloongabba', BillingCity = 'Brisbane',
			BillingState = 'Queensland', BillingPostalCode = '4102',
			BillingCountry = 'Australia', ShippingStreet = 'Vulture St, Woolloongabba',
			ShippingCity = 'Brisbane', ShippingState = 'Queensland',
			ShippingPostalCode = '4102', ShippingCountry = 'Australia',
			Last4__c = '4242'
		);
		insert acc;
		
		Test.startTest();
			String resultSetPayment = RestPaymentInformationController.setPaymentInformation(new Map<String, String>());
			System.assertEquals(true, resultSetPayment.contains('error'));
			resultSetPayment = RestPaymentInformationController.setPaymentInformation(new Map<String, String>{'accountId' => ''});
			System.assertEquals(true, resultSetPayment.contains('error'));
			resultSetPayment = RestPaymentInformationController.setPaymentInformation(new Map<String, String>{'accountId' => acc.Id});
			System.assertEquals(true, resultSetPayment.contains('error'));
			resultSetPayment = RestPaymentInformationController.setPaymentInformation(new Map<String, String>{'accountId' => acc.Id, 'num' => '', 'ccv' => '', 'month' => '', 'year' => ''});
			System.assertEquals(true, resultSetPayment.contains('error'));
			resultSetPayment = RestPaymentInformationController.setPaymentInformation(new Map<String, String>{'accountId' => acc.Id, 'num' => '4242424242424242', 'ccv' => '', 'month' => '', 'year' => ''});
			System.assertEquals(true, resultSetPayment.contains('error'));
			resultSetPayment = RestPaymentInformationController.setPaymentInformation(new Map<String, String>{'accountId' => acc.Id, 'num' => '4242424242424242', 'ccv' => '123', 'month' => '', 'year' => ''});
			System.assertEquals(true, resultSetPayment.contains('error'));
			resultSetPayment = RestPaymentInformationController.setPaymentInformation(new Map<String, String>{'accountId' => acc.Id, 'num' => '4242424242424242', 'ccv' => '123', 'month' => '1', 'year' => ''});
			System.assertEquals(true, resultSetPayment.contains('error'));
			resultSetPayment = RestPaymentInformationController.setPaymentInformation(new Map<String, String>{'accountId' => acc.Id, 'num' => '4242424242424242', 'ccv' => '12', 'month' => '1', 'year' => '2020'});
			System.assertEquals(true, resultSetPayment.contains('error'));
			resultSetPayment = RestPaymentInformationController.setPaymentInformation(new Map<String, String>{'accountId' => acc.Id, 'num' => '4242424242424242', 'ccv' => '123', 'month' => '1', 'year' => '20'});
			System.assertEquals(true, resultSetPayment.contains('error'));
			resultSetPayment = RestPaymentInformationController.setPaymentInformation(new Map<String, String>{'accountId' => acc.Id, 'num' => '4242424242424242', 'ccv' => '123', 'month' => '1', 'year' => '2020'});
			Map<String, String> resultMap = (Map<String, String>)JSON.deserialize(resultSetPayment, Map<String, String>.class);
			System.assertEquals('success', resultMap.get('status'));
			System.assertEquals(true, resultMap.containsKey('paymentInformation'));
			List<Payment_Information__c> paymentInformations = [
				SELECT Id, Information__c
				FROM Payment_Information__c
				WHERE Id = :resultMap.get('paymentInformation')
			];
			System.assertEquals(1, paymentInformations.size());
			resultSetPayment = RestPaymentInformationController.setPaymentInformation(new Map<String, String>{'accountId' => acc.Id, 'num' => '4242424242424242', 'ccv' => '123', 'month' => '1', 'year' => '2020'});
			resultMap = (Map<String, String>)JSON.deserialize(resultSetPayment, Map<String, String>.class);
			System.assertEquals('success', resultMap.get('status'));
			System.assertEquals(true, resultMap.containsKey('paymentInformation'));
			paymentInformations = [
				SELECT Id, Information__c
				FROM Payment_Information__c
				WHERE Account__c = :acc.Id
			];
			System.assertEquals(1, paymentInformations.size());

			resultSetPayment = RestPaymentInformationController.setPaymentInformation(new Map<String, String>{'accountId' => acc.Id, 'num' => '4111111111111111', 'ccv' => '123', 'month' => '1', 'year' => '2020'});
			resultMap = (Map<String, String>)JSON.deserialize(resultSetPayment, Map<String, String>.class);
			System.assertEquals('success', resultMap.get('status'));
			System.assertEquals(true, resultMap.containsKey('paymentInformation'));
			paymentInformations = [
				SELECT Id, Information__c
				FROM Payment_Information__c
				WHERE Account__c = :acc.Id
			];
			System.assertEquals(2, paymentInformations.size());

			String resultGetPayment = RestPaymentInformationController.getPaymentInformation(new Map<String, String>());
			System.assertEquals(true, resultGetPayment.contains('error'));
			resultGetPayment = RestPaymentInformationController.getPaymentInformation(new Map<String, String>{'paymentInformationId' => ''});
			System.assertEquals(true, resultGetPayment.contains('error'));
			resultGetPayment = RestPaymentInformationController.getPaymentInformation(new Map<String, String>{'paymentInformationId' => paymentInformations[0].Id});
			System.assertEquals(true, resultGetPayment.contains('success'));
		Test.stopTest();
	}
}