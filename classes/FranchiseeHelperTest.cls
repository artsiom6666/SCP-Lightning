@isTest
private with sharing class FranchiseeHelperTest {

    static testMethod void testUpdateAccount() {
        RecordType franchiseeRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Franchisee_Account' AND IsPersonType = true];
        Account acc = new Account(RecordTypeId = franchiseeRecordType.Id, LastName = 'TestLast', FirstName = 'TestFirst', PersonEmail = '1357TestTest7531@gmail.com' );
        insert acc;

        Test.startTest();
            FranchiseeHelper.FranchiseeHelperInnerClass controller = new FranchiseeHelper.FranchiseeHelperInnerClass();
            String result;
            result = controller.setFranchiseeRest(new Map<String, String>{});
            System.assertEquals(true, result.contains('error'));
            result = controller.setFranchiseeRest(new Map<String, String>{'id' => 'invalidId'});
            System.assertEquals(true, result.contains('error'));
            result = controller.setFranchiseeRest(new Map<String, String>{'id' => acc.Id});
            System.assertEquals(true, result.contains('success'));

            result = controller.setFranchiseeRest(new Map<String, String>{'id' => acc.Id,'lastName' => 'TestLastTwo'});
            System.assertEquals(true, result.contains('success'));
            result = controller.setFranchiseeRest(new Map<String, String>{'id' => acc.Id, 'firstName' => 'TestFirstTwo'});
            System.assertEquals(true, result.contains('success'));
            result = controller.setFranchiseeRest(new Map<String, String>{'id' => acc.Id, 'personEmail' => 'testtest@gmail.com'});
            System.assertEquals(true, result.contains('success'));
            result = controller.setFranchiseeRest(new Map<String, String>{'id' => acc.Id, 'phone' => '1234567890'});
            System.assertEquals(true, result.contains('success'));
            result = controller.setFranchiseeRest(new Map<String, String>{'id' => acc.Id,
                                                                                          'billingStreet' => 'BStreet',
                                                                                          'billingCity' => 'BCity',
                                                                                          'billingState' => 'Ontario',
                                                                                          'billingStateCode' => 'ON',
                                                                                          'billingPostalCode' => '4102',
                                                                                          'billingCountry' => 'Canada',
                                                                                          'billingCountryCode' => 'CA'});
            System.assertEquals(true, result.contains('success'));
            result = controller.setFranchiseeRest(new Map<String, String>{'id' => acc.Id, 'shippingStreet' => 'SStreet'});
            System.assertEquals(true, result.contains('success'));
            result = controller.setFranchiseeRest(new Map<String, String>{'id' => acc.Id, 'shippingCity' => 'SCity'});
            System.assertEquals(true, result.contains('success'));
            result = controller.setFranchiseeRest(new Map<String, String>{'id' => acc.Id, 'shippingPostalCode' => '4102'});
            System.assertEquals(true, result.contains('success'));
            result = controller.setFranchiseeRest(new Map<String, String>{'id' => acc.Id, 'shippingCountryCode' => 'CA'});
            System.assertEquals(true, result.contains('success'));
            result = controller.setFranchiseeRest(new Map<String, String>{'id' => acc.Id, 'shippingCountry' => 'Canada'});
            System.assertEquals(true, result.contains('success'));
            result = controller.setFranchiseeRest(new Map<String, String>{'id' => acc.Id, 'shippingStateCode' => 'ON'});
            System.assertEquals(true, result.contains('success'));
            result = controller.setFranchiseeRest(new Map<String, String>{'id' => acc.Id, 'shippingState' => 'Ontario'});
            System.assertEquals(true, result.contains('success'));


            String codeFields = TouchCRHelper.isSCPEnabled() == TRUE ? ' BillingCountryCode, ShippingCountryCode, BillingStateCode, ShippingStateCode, ' : '';
            String query = 'SELECT Id, FirstName, LastName, PersonEmail, Phone, BillingStreet, BillingAddress, ' + codeFields + 
                                  'BillingCity, BillingState, BillingPostalCode, BillingCountry, ' +
                                  'ShippingStreet, ShippingCity, ShippingState, ' +
                                  'ShippingPostalCode, ShippingCountry ' +
                                  'FROM Account ';
            List<Account> accs = Database.query(query);

            System.assertEquals('TestLastTwo', accs[0].LastName);
            System.assertEquals('TestFirstTwo', accs[0].FirstName);
            System.assertEquals('testtest@gmail.com', accs[0].PersonEmail);
            System.assertEquals('1234567890', accs[0].Phone);
            System.assertEquals('BStreet', accs[0].BillingStreet);
            System.assertEquals('BCity', accs[0].BillingCity);
            System.assertEquals(TouchCRHelper.isSCPEnabled() == TRUE ? 'ON' : '', TouchCRHelper.isSCPEnabled() == TRUE ? accs[0].get('BillingStateCode') : '');
            System.assertEquals(TouchCRHelper.isSCPEnabled() == TRUE ? 'CA' : '', TouchCRHelper.isSCPEnabled() == TRUE ? accs[0].get('BillingCountryCode') : '');
            System.assertEquals('Ontario', accs[0].BillingState);
            System.assertEquals('4102', accs[0].BillingPostalCode);
            System.assertEquals('Canada', accs[0].BillingCountry);
            System.assertEquals('SStreet', accs[0].ShippingStreet);
            System.assertEquals('SCity', accs[0].ShippingCity);
            System.assertEquals('Ontario', accs[0].ShippingState);
            System.assertEquals('4102', accs[0].ShippingPostalCode);
            System.assertEquals('Canada', accs[0].ShippingCountry);
            System.assertEquals(TouchCRHelper.isSCPEnabled() == TRUE ? 'ON' : '', TouchCRHelper.isSCPEnabled() == TRUE ? accs[0].get('ShippingStateCode') : '');
            System.assertEquals(TouchCRHelper.isSCPEnabled() == TRUE ? 'CA' : '', TouchCRHelper.isSCPEnabled() == TRUE ? accs[0].get('ShippingCountryCode') : '');
            System.assertEquals(1, accs.size());

        Test.stopTest();
    }

    static testMethod void testError() {
        //no lastName
        Map<String, String> generalData = new Map<String, String>{
            'firstName' => 'TestFirst',
            'personEmail' => 'testtest@gmail.com',
            'phone' => '1234567890'
        };

        Test.startTest();
            FranchiseeHelper.FranchiseeHelperInnerClass controller = new FranchiseeHelper.FranchiseeHelperInnerClass();
            String result = controller.setFranchiseeRest(generalData);
            List<Account> accs = [SELECT Id, Phone FROM Account];
            System.assertEquals(true, result.contains('error'));
            System.assertEquals(0, accs.size());
        Test.stopTest();
    }

    static testMethod void testGetAccount() {
        List<RecordType> recordTypeCustomer = [SELECT Id FROM RecordType WHERE DeveloperName = 'Customer_Account' LIMIT 1];
        List<RecordType> recordTypeFranchisee = [SELECT Id FROM RecordType WHERE DeveloperName = 'Franchisee_Account' LIMIT 1];
        Account accA = new Account(LastName = 'Last13579', FirstName = 'First13579', PersonEmail = 'email13579@gmail.com', RecordTypeId = recordTypeCustomer[0].Id);
        Account accF = new Account(LastName = 'Last97531', FirstName = 'First97531', PersonEmail = 'email97531@gmail.com', RecordTypeId = recordTypeFranchisee[0].Id);
        insert new List<Account> {accA, accF};

        Test.startTest();
            FranchiseeHelper.FranchiseeHelperInnerClass controller = new FranchiseeHelper.FranchiseeHelperInnerClass();
            String result;
            result = controller.getFranchiseeRest(new Map<String, String>{});
            System.assertEquals(true, result.contains('error'));
            result = controller.getFranchiseeRest(new Map<String, String>{'personEmail' => 'invalidId'});
            System.assertEquals(true, result.contains('error'));

            //not Franchisee_Account
            result = controller.getFranchiseeRest(new Map<String, String>{'personEmail' => 'email13579@gmail.com'});
            System.assertEquals(true, result.contains('error'));

            result = controller.getFranchiseeRest(new Map<String, String>{'personEmail' => 'email97531@gmail.com'});
            System.assertEquals(true, result.contains('success'));
        Test.stopTest();
    }

    // StripeConnectSettings
	static testMethod void test_StripeConnectSettingsController() {
        FranchiseeHelper.FranchiseeHelperInnerClass controller = new FranchiseeHelper.FranchiseeHelperInnerClass();

		String settings = controller.getPaymentConnectSettingsExt();
		StripeConnectWrapper settingsDesirialized = (StripeConnectWrapper)System.JSON.deserialize(settings, StripeConnectWrapper.class);
		System.assertEquals(null, settingsDesirialized.paymentAgentId);

		StripeConnectWrapper newSetting = new StripeConnectWrapper();
		newSetting.paymentAgentId = 'test';

		String saveResult = controller.saveStripeConnectExt(JSON.serialize(newSetting));
		System.assertEquals('Organization has been successfully saved!', saveResult);
		String savedSettings = controller.getPaymentConnectSettingsExt();
		StripeConnectWrapper savedSettingDes = (StripeConnectWrapper)System.JSON.deserialize(savedSettings, StripeConnectWrapper.class);
		System.assertEquals('test', savedSettingDes.paymentAgentId);
	}

	public class StripeConnectWrapper {
		protected String paymentAgentId { get; set; }
	}


}