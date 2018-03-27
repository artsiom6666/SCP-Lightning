global with sharing class FranchiseeHelper {

    global class FranchiseeHelperInnerClass implements ExtensionsHelperDummy.FranchiseeInterface {

        global String setFranchiseeRest(Map<String, String> generalData) {
            try {
                Id franchiseeId = generalData.containsKey('id') ? Id.valueOf(generalData.get('id')) : null;
                String lastName = generalData.containsKey('lastName') ? generalData.get('lastName') : null;
                String firstName = generalData.containsKey('firstName') ? generalData.get('firstName') : null;
                String email = generalData.containsKey('personEmail') ? generalData.get('personEmail') : null;
                String phone = generalData.containsKey('phone') ? generalData.get('phone') : null;
                String personMobilePhone = generalData.containsKey('personMobilePhone') ? generalData.get('personMobilePhone') : null;

                String billingStreet = generalData.containsKey('billingStreet') ? generalData.get('billingStreet') : null;
                String billingCity = generalData.containsKey('billingCity') ? generalData.get('billingCity') : null;
                String billingPostalCode = generalData.containsKey('billingPostalCode') ? generalData.get('billingPostalCode') : null;
                String billingStateCode = generalData.containsKey('billingStateCode') ? generalData.get('billingStateCode') : null;
                String billingState = generalData.containsKey('billingState') ? generalData.get('billingState') : null;
                String billingCountryCode = generalData.containsKey('billingCountryCode') ? generalData.get('billingCountryCode') : null;
                String billingCountry = generalData.containsKey('billingCountry') ? generalData.get('billingCountry') : null;

                String shippingStreet = generalData.containsKey('shippingStreet') ? generalData.get('shippingStreet') : null;
                String shippingCity = generalData.containsKey('shippingCity') ? generalData.get('shippingCity') : null;
                String shippingPostalCode = generalData.containsKey('shippingPostalCode') ? generalData.get('shippingPostalCode') : null;
                String shippingStateCode = generalData.containsKey('shippingStateCode') ? generalData.get('shippingStateCode') : null;
                String shippingState = generalData.containsKey('shippingState') ? generalData.get('shippingState') : null;
                String shippingCountryCode = generalData.containsKey('shippingCountryCode') ? generalData.get('shippingCountryCode') : null;
                String shippingCountry = generalData.containsKey('shippingCountry') ? generalData.get('shippingCountry') : null;

                String franchiseeApproval = generalData.containsKey('franchiseeApproval') ? generalData.get('franchiseeApproval') : null;
                String legalEntityFirstName = generalData.containsKey('legalEntityFirstName') ? generalData.get('legalEntityFirstName') : null;
                String legalEntityLastName = generalData.containsKey('legalEntityLastName') ? generalData.get('legalEntityLastName') : null;
                String legalEntityDateOfBirthDay = generalData.containsKey('legalEntityDateOfBirthDay') ? generalData.get('legalEntityDateOfBirthDay') : null;
                String legalEntityDateOfBirthMonth = generalData.containsKey('legalEntityDateOfBirthMonth') ? generalData.get('legalEntityDateOfBirthMonth') : null;
                String legalEntityDateOfBirthYear = generalData.containsKey('legalEntityDateOfBirthYear') ? generalData.get('legalEntityDateOfBirthYear') : null;

                Decimal longitude = generalData.containsKey('longitude') ? Decimal.valueOf(generalData.get('longitude')) : null;
                Decimal latitude = generalData.containsKey('latitude') ? Decimal.valueOf(generalData.get('latitude')) : null;

                RecordType recType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Franchisee_Account' AND SobjectType = 'Account' LIMIT 1];

                //getting information from an existing Account
                String codeFields = TouchCRHelper.isSCPEnabled() == TRUE ? ' BillingStateCode, ShippingStateCode, BillingCountryCode, ShippingCountryCode, ' : '';

                String accountQueryString = 'SELECT Id, LastName, FirstName, BillingStreet, BillingCity, BillingState, ' + codeFields + 
                        'BillingPostalCode, BillingCountry, ' +
                        'ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ' +
                        'Phone, Fax, PersonContactId, RecordTypeId, ' +
                        'PersonEmail, Geolocation__Longitude__s, Geolocation__Latitude__s, PersonMobilePhone, Franchisee_Approval__c, ' +
                        'Legal_Entity_First_Name__c, Legal_Entity_Last_Name__c, Legal_Entity_Date_of_Birth_Day__c, Legal_Entity_Date_of_Birth_Month__c, Legal_Entity_Date_of_Birth_Year__c ' +
                    'FROM Account ';
    
                //if franchiseeId exists we search for Account with Id, otherwise we use email
                accountQueryString += String.isBlank(franchiseeId) ? ' WHERE PersonEmail =: email' : ' WHERE Id =: franchiseeId';
                List<Account> accountToFranchisee = Database.query(accountQueryString);

                Account accountItem = accountToFranchisee.isEmpty() ? new Account() : accountToFranchisee[0];

                accountItem.RecordTypeId = accountItem.RecordTypeId != null ? accountItem.RecordTypeId : recType.Id;
                accountItem.LastName = String.isNotBlank(lastName) ? lastName : accountItem.LastName;
                accountItem.FirstName = String.isNotBlank(firstName) ? firstName : accountItem.FirstName;
                accountItem.PersonEmail  = String.isNotBlank(email) ? email : accountItem.PersonEmail;
                accountItem.Phone = String.isNotBlank(phone) ? phone : accountItem.Phone;
                accountItem.PersonMobilePhone = String.isNotBlank(personMobilePhone) ? personMobilePhone : accountItem.PersonMobilePhone;

                accountItem.ShippingStreet = String.isNotBlank(shippingStreet) ? shippingStreet : accountItem.ShippingStreet;
                accountItem.ShippingCity = String.isNotBlank(shippingCity) ? shippingCity : accountItem.ShippingCity;
                accountItem.ShippingPostalCode = String.isNotBlank(shippingPostalCode) ? shippingPostalCode : accountItem.ShippingPostalCode;
                //if Billing Address is Blank, we use Shipping Address
                accountItem.BillingStreet = String.isNotBlank(billingStreet) ? billingStreet : (String.isNotBlank(accountItem.BillingStreet) ? accountItem.BillingStreet : accountItem.ShippingStreet);
                accountItem.BillingCity = String.isNotBlank(billingCity) ? billingCity : (String.isNotBlank(accountItem.BillingCity) ? accountItem.BillingCity : accountItem.ShippingCity);
                accountItem.BillingPostalCode = String.isNotBlank(billingPostalCode) ? billingPostalCode : (String.isNotBlank(accountItem.BillingPostalCode) ? accountItem.BillingPostalCode : accountItem.ShippingPostalCode);

                accountItem.ShippingState = String.isNotBlank(shippingState) ? shippingState : accountItem.ShippingState;
                accountItem.ShippingCountry = String.isNotBlank(shippingCountry) ? shippingCountry : accountItem.ShippingCountry;

                if (TouchCRHelper.isSCPEnabled()) {
                    accountItem.put('BillingStateCode', String.isNotBlank(billingStateCode) ? billingStateCode : (String)accountItem.get('BillingStateCode'));
                    accountItem.put('BillingStateCode', (String.isNotBlank((String)accountItem.get('BillingStateCode'))) ? (String)accountItem.get('BillingStateCode') : (String)accountItem.get('ShippingStateCode'));
                } else {
                    accountItem.BillingState = (String.isNotBlank(billingState)) ? billingState : (String.isNotBlank(accountItem.BillingState) ? accountItem.BillingState : accountItem.ShippingState);
                }

                if (TouchCRHelper.isSCPEnabled()) {
                    accountItem.put('BillingCountryCode', String.isNotBlank(billingCountryCode) ? billingCountryCode : (String)accountItem.get('BillingCountryCode'));
                    accountItem.put('BillingCountryCode', (String.isNotBlank((String)accountItem.get('BillingCountryCode'))) ? (String)accountItem.get('BillingCountryCode') : (String)accountItem.get('ShippingCountryCode'));
                } else {
                    accountItem.BillingCountry = (String.isNotBlank(billingCountry)) ? billingCountry : (String.isNotBlank(accountItem.BillingCountry) ? accountItem.BillingCountry : accountItem.ShippingCountry);
                }

                accountItem.Franchisee_Approval__c = String.isNotBlank(franchiseeApproval) ? franchiseeApproval : accountItem.Franchisee_Approval__c;			
                accountItem.Legal_Entity_First_Name__c = String.isNotBlank(legalEntityFirstName) ? legalEntityFirstName : accountItem.Legal_Entity_First_Name__c;
                accountItem.Legal_Entity_Last_Name__c = String.isNotBlank(legalEntityLastName) ? legalEntityLastName : accountItem.Legal_Entity_Last_Name__c;
                accountItem.Legal_Entity_Date_of_Birth_Day__c = String.isNotBlank(legalEntityDateOfBirthDay) ? legalEntityDateOfBirthDay : accountItem.Legal_Entity_Date_of_Birth_Day__c;
                accountItem.Legal_Entity_Date_of_Birth_Month__c = String.isNotBlank(legalEntityDateOfBirthMonth) ? legalEntityDateOfBirthMonth : accountItem.Legal_Entity_Date_of_Birth_Month__c;
                accountItem.Legal_Entity_Date_of_Birth_Year__c = String.isNotBlank(legalEntityDateOfBirthYear) ? legalEntityDateOfBirthYear : accountItem.Legal_Entity_Date_of_Birth_Year__c;

                try {
                    SFDCAccessController.UpsertWithoutSharing (
                        accountItem,
                        'RestFranchiseeController.cls [setFranchisee]',
                        new List<Schema.DescribeFieldResult>{
                            Account.RecordTypeId.getDescribe(), Account.LastName.getDescribe(),
                            Account.FirstName.getDescribe(), Account.PersonEmail.getDescribe(),
                            Account.Phone.getDescribe(), Account.PersonMobilePhone.getDescribe(),
                            Account.ShippingCity.getDescribe(), Account.ShippingPostalCode.getDescribe(),
                            Account.ShippingState.getDescribe(), Account.ShippingCountry.getDescribe(),
                            Account.BillingStreet.getDescribe(), Account.BillingCity.getDescribe(),
                            Account.BillingPostalCode.getDescribe(), Account.BillingState.getDescribe(),
                            Account.BillingCountry.getDescribe(), Account.Franchisee_Approval__c.getDescribe(),
                            Account.Legal_Entity_First_Name__c.getDescribe(), Account.Legal_Entity_Last_Name__c.getDescribe(),
                            Account.Legal_Entity_Date_of_Birth_Day__c.getDescribe(), Account.Legal_Entity_Date_of_Birth_Month__c.getDescribe(),
                            Account.Legal_Entity_Date_of_Birth_Year__c.getDescribe()
                        }
                    );
                } catch (SFDCAccessControlException e) { return  '{"error":"' + e.ExceptionMessage + '","message":"error"}'; }


                return '{"accountId":"' + accountItem.Id + '","message":"success"}';
            } catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}';}
        }

        global String getFranchiseeRest(Map<String, String> generalData) {
            try{
                Id userId = generalData.containsKey('userId') ? generalData.get('userId') : null;
                String email = generalData.containsKey('personEmail') ? generalData.get('personEmail') : null;
                //verification of input data
                if (userId == null && email == null) { return '{"error":"User Id or Person Email was not found","message":"error"}'; }

                Id accountId;
                String queryFilter, userPhoto;

                if (userId != null) {
                List<User> userToAccount = [SELECT Id, Account.Id, MediumPhotoUrl FROM User WHERE Id =: userId AND AccountId != null];

                    if (userToAccount.isEmpty()) { return '{"error":"Account not found","message":"error"}'; }
                    accountId = userToAccount[0].Account.Id;
                    userPhoto = userToAccount[0].MediumPhotoUrl;
                    queryFilter = 'AND Id=:accountId';
                } else {
                    queryFilter = 'AND PersonEmail=:email';
                }

                String codeFields = TouchCRHelper.isSCPEnabled() == TRUE ? ' BillingStateCode, BillingCountryCode, ShippingStateCode, ShippingCountryCode, ' : '';
                String recordTypeDeveloperName = 'Franchisee_Account';
                String accountQueryString = 'SELECT Id, Name, FirstName, LastName, Phone, PersonEmail, RecordType.DeveloperName, ' + codeFields +
                                'BillingCountry, BillingStreet, BillingCity, BillingState, BillingPostalCode, ' +
                                'ShippingCountry, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ' +
                                'PersonMobilePhone, Blacklist__c, Franchisee_Approval__c, Geolocation__Longitude__s, Geolocation__Latitude__s, ' +
                                'Legal_Entity_First_Name__c, Legal_Entity_Last_Name__c, Legal_Entity_Date_of_Birth_Day__c, ' +
                                'Legal_Entity_Date_of_Birth_Month__c, Legal_Entity_Date_of_Birth_Year__c ' +
                                'FROM Account ' +
                                'WHERE RecordType.DeveloperName = \'' + recordTypeDeveloperName + '\'' +
                                queryFilter;

                List<Account> selectedAccounts = Database.query(accountQueryString);

                if (selectedAccounts.isEmpty()) { return '{"error":"Franchisee not found","message":"error"}'; }

                String billingStateCode = TouchCRHelper.isSCPEnabled() == TRUE ? (String)selectedAccounts[0].get('BillingStateCode') : '';
                String billingCountryCode = TouchCRHelper.isSCPEnabled() == TRUE ? (String)selectedAccounts[0].get('BillingCountryCode') : '';
                String shippingStateCode = TouchCRHelper.isSCPEnabled() == TRUE ? (String)selectedAccounts[0].get('ShippingStateCode') : '';
                String shippingCountryCode = TouchCRHelper.isSCPEnabled() == TRUE ? (String)selectedAccounts[0].get('ShippingCountryCode') : '';

                Map<String, Object> accountDetail = new Map<String, Object>{
                    'id' => selectedAccounts[0].Id,
                    'name' => selectedAccounts[0].Name,
                    'firstName' => selectedAccounts[0].FirstName,
                    'lastName' => selectedAccounts[0].LastName,
                    'phone' => selectedAccounts[0].Phone,
                    'personMobilePhone' => selectedAccounts[0].PersonMobilePhone,
                    'personEmail' => selectedAccounts[0].PersonEmail,
                    'billingStreet' => selectedAccounts[0].BillingStreet,
                    'billingCity' => selectedAccounts[0].BillingCity,
                    'billingState' => selectedAccounts[0].BillingState,
                    'billingStateCode' => billingStateCode,
                    'billingCountry' => selectedAccounts[0].BillingCountry,
                    'billingCountryCode' => billingCountryCode,
                    'billingPostalCode' => selectedAccounts[0].BillingPostalCode,
                    'shippingStreet' => selectedAccounts[0].ShippingStreet,
                    'shippingCity' => selectedAccounts[0].ShippingCity,
                    'shippingState' => selectedAccounts[0].ShippingState,
                    'shippingStateCode' => shippingStateCode,
                    'shippingCountry' => selectedAccounts[0].ShippingCountry,
                    'shippingCountryCode' => shippingCountryCode,
                    'shippingPostalCode' => selectedAccounts[0].ShippingPostalCode,
                    'franchiseeApproval' => selectedAccounts[0].Franchisee_Approval__c,
                    'legalEntityFirstName' => selectedAccounts[0].Legal_Entity_First_Name__c,
                    'legalEntityLastName' => selectedAccounts[0].Legal_Entity_Last_Name__c,
                    'legalEntityDateOfBirthDay' => selectedAccounts[0].Legal_Entity_Date_of_Birth_Day__c,
                    'legalEntityDateOfBirthMonth' => selectedAccounts[0].Legal_Entity_Date_of_Birth_Month__c,
                    'legalEntityDateOfBirthYear' => selectedAccounts[0].Legal_Entity_Date_of_Birth_Year__c,
                    'url' => userPhoto,
                    'longitude' => String.valueOf(selectedAccounts[0].Geolocation__Longitude__s),
                    'latitude' => String.valueOf(selectedAccounts[0].Geolocation__Latitude__s),
                    'recordType' => selectedAccounts[0].RecordType.DeveloperName	//value 'Franchisee_Account'
                };

                Map<String, Object> result = new Map<String, Object>{
                    'message' => 'success',
                    'account' => accountDetail
                };

                return JSON.serialize(result);

            } catch (Exception e) { return '{"error":"' +  e.getMessage() + '","message":"error"}'; }
        }

            //method return information about franchisee for current customer
        global String getFranchiseeInfoRest(Map<String, String> generalData) {
            try{
                Id userFranchiseeId = generalData.containsKey('userFranchiseeId') ? Id.valueOf(generalData.get('userFranchiseeId')) : null;
                //verification of input data
                if (userFranchiseeId == null) { return '{"error":"Franchisee Id was not found","message":"error"}'; }

                List<User> userToFranchisee = [
                    SELECT Id, TimeZoneSidKey, AccountId, MediumPhotoUrl
                    FROM User
                    WHERE Id =: userFranchiseeId
                ];
                //stop work if user or account is not found
                if (userToFranchisee.isEmpty() || userToFranchisee[0].AccountId == null) { return '{"error":"User not found","message":"error"}'; }


                String codeFields = TouchCRHelper.isSCPEnabled() == TRUE ? ' BillingStateCode, ShippingStateCode, BillingCountryCode, ShippingCountryCode, ' : '';

                //todo user id
                String accountQueryString = 
                    'SELECT Id, FirstName, LastName, Phone, Name, PersonEmail, PersonMobilePhone, Depot__c, Geolocation__Longitude__s, Geolocation__Latitude__s, ' +
                        'BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Territory__c, ' + codeFields + 
                        'ShippingStreet, ShippingCity, ShippingState, ShippingCountry, ShippingPostalCode, ' +
                        '( ' +
                            'SELECT Id, FirstName, LastName, Phone, Name, PersonEmail, ' +
                                'PersonMobilePhone, Last4__c, Geolocation__Longitude__s, Geolocation__Latitude__s, ' + codeFields + 
                                'BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, ' +
                                'ShippingStreet, ShippingCity, ShippingState, ShippingCountry, ShippingPostalCode ' +
                            'FROM Customers__r ' +
                        '), ' +
                        '( ' +
                            'SELECT Id, Franchisee__c ' +
                            'FROM Territories__r ' +
                        ') ' +
                    'FROM Account ' +
                    'WHERE Id =: userToFranchisee[0].AccountId ';
                List<Account> franchisee = Database.query(accountQueryString);

                //stop work if franchisee is not found
                if (franchisee.isEmpty()) { return '{"error":"Franchisee not found","message":"error"}'; }

                Set<Id> territoriesId = new Set<Id>();
                for (Territory__c terrItem : franchisee[0].Territories__r) {
                    territoriesId.add(terrItem.Id);
                }

                List<Map<String, String>> customers = new List<Map<String, String>>();
                for (Account accItem : franchisee[0].Customers__r) {
                    String billingStateCode = TouchCRHelper.isSCPEnabled() == TRUE ? (String)accItem.get('BillingStateCode') : '';
                    String shippingStateCode = TouchCRHelper.isSCPEnabled() == TRUE ? (String)accItem.get('ShippingStateCode') : '';

                    customers.add(new Map<String, String>{
                        'id' => accItem.Id,
                        'name' => accItem.Name,
                        'firstName' => accItem.FirstName,
                        'lastName' => accItem.LastName,
                        'phone' => accItem.Phone,
                        'personMobilePhone' => accItem.PersonMobilePhone,
                        'personEmail' => accItem.PersonEmail,
                        'billingCountry' => accItem.BillingCountry,
                        'billingStreet' => accItem.BillingStreet,
                        'billingCity' => accItem.BillingCity,
                        'billingState' => accItem.BillingState,
                        'billingStateCode' => billingStateCode,
                        'billingPostalCode' => accItem.BillingPostalCode,
                        'shippingCountry' => accItem.ShippingCountry,
                        'shippingStreet' => accItem.ShippingStreet,
                        'shippingCity' => accItem.ShippingCity,
                        'shippingState' => accItem.ShippingState,
                        'shippingStateCode' => shippingStateCode,
                        'shippingPostalCode' => accItem.ShippingPostalCode,
                        'last4' => accItem.Last4__c,
                        'longitude' => String.valueOf(accItem.Geolocation__Longitude__s),
                        'latitude' => String.valueOf(accItem.Geolocation__Latitude__s)
                    });
                }
                
                Set<String> availableStatus = new Set<String>{'Initiated', 'Completed'};
            
                List<Order__c> allOrdersToFranchisee = [
                    SELECT Id, Name, Date__c, Status__c, Territory__c, Territory__r.Franchisee__c,
                        Tax__c, Total__c,  
                        Geolocation__Longitude__s, Geolocation__Latitude__s,
                        Shipping_City__c, Shipping_State__c, Shipping_Address__c,
                        Shipping_Zip_Postal__c, Shipment_Full_Name__c, Shipping_Phone__c,
                        Account__r.PersonMobilePhone,
                        (
                            SELECT Id, Name, Order__c, Quantity__c, Total_Price__c,
                                Product__c, Product_Price__c
                            FROM Order_Items__r
                            WHERE Product_Price__c != 0
                        )
                    FROM Order__c
                    WHERE Territory__c IN: territoriesId
                    AND Balance_Due__c  = 0
                    AND Status__c IN: availableStatus
                ];

                List<Map<String, Object>> orders = new List<Map<String, Object>>();
                for (Order__c order : allOrdersToFranchisee) {
                    List<Map<String, Object>> orderItems = new List<Map<String, Object>>();

                    for (OrderItem__c orderItem : order.Order_Items__r) {
                        orderItems.add(new Map<String, Object>{
                            'id' => orderItem.Id,
                            'orderId' => orderItem.Order__c,
                            'quantity' => orderItem.Quantity__c,
                            'totalPrice' => orderItem.Total_Price__c,
                            'productId' => orderItem.Product__c,
                        //  'productPriceTotal' => orderItem.Product_Price_Total__c,
                        //  'productGST' => orderItem.Product_GST__c,
                        //  'totalGST' => orderItem.Total_GST__c,
                            'productPrice' => orderItem.Product_Price__c
                        });
                    }
    
                    orders.add(new Map<String, Object>{
                        'id' => order.Id,
                        'name' => order.Name,
                        'date' =>  order.Date__c != null ? String.valueOf(order.Date__c.format('EEE dd/MM/yyyy HH:mm')) : '',
                        'status' => order.Status__c,
                        'tax' => order.Tax__c,
                        'total' => order.Total__c,
                    //  'deliveryType' => order.Delivery_Type__c,
                    //  'deliveryStatus' => String.isNotBlank(order.Delivery_Status__c) ? order.Delivery_Status__c : 'Undelivered',
                    //  'deliveryDate' => order.Delivery_Date__c,
                    //  'actualDeliveryDate' => order.Actual_Delivery_Date__c != null ? String.valueOf(order.Actual_Delivery_Date__c.format('EEE dd/MM/yyyy HH:mm')) : '',
                    //  'timeStart' => String.isNotEmpty(String.valueOf(order.Time_Start__c)) ? String.valueOf(order.Time_Start__c.format('HH:mm')) : '00:00',
                    //  'timeEnd' => String.isNotEmpty(String.valueOf(order.Time_End__c)) ? String.valueOf(order.Time_End__c.format('HH:mm')) : '00:00',
                        'longitude' => order.Geolocation__Longitude__s,
                        'latitude' => order.Geolocation__Latitude__s,
                    //  'upsell' => order.Upsell__c,
                        'shippingFullName' => order.Shipment_Full_Name__c,
                        'shippingPhone' => order.Shipping_Phone__c,
                        'shippingCity' => order.Shipping_City__c,
                        'shippingState' => order.Shipping_State__c,
                        'shippingAddress' => order.Shipping_Address__c,
                        'shippingZipPostal' => order.Shipping_Zip_Postal__c,
                        'personMobilePhone' => order.Account__r.PersonMobilePhone,
                        'territoryId' => order.Territory__c,
                    //  'deliveryInstructions' => order.TouchCRBase__Account__r.Delivery_Instructions__c,
                    //  'pets' => order.TouchCRBase__Account__r.Pets__c,
                        'orderItems' => orderItems
                    });
                }

                String billingStateCode = TouchCRHelper.isSCPEnabled() == TRUE ? (String)franchisee[0].get('BillingStateCode') : '';
                String shippingStateCode = TouchCRHelper.isSCPEnabled() == TRUE ? (String)franchisee[0].get('ShippingStateCode') : '';

                return JSON.serialize(new Map<String, Object>{
                    'message' => 'success',
                    'franchisee' => new Map<String, Object>{
                        'id' => franchisee[0].Id,
                        'name' => franchisee[0].Name,
                        'firstName' => franchisee[0].FirstName,
                        'lastName' => franchisee[0].LastName,
                        'phone' => franchisee[0].Phone,
                        'personMobilePhone' => franchisee[0].PersonMobilePhone,
                        'personEmail' => franchisee[0].PersonEmail,
                        'billingCountry' => franchisee[0].BillingCountry,
                        'billingStreet' => franchisee[0].BillingStreet,
                        'billingCity' => franchisee[0].BillingCity,
                        'billingState' => franchisee[0].BillingState,
                        'billingStateCode' => billingStateCode,
                        'billingPostalCode' => franchisee[0].BillingPostalCode,
                        'shippingCountry' => franchisee[0].ShippingCountry,
                        'shippingStreet' => franchisee[0].ShippingStreet,
                        'shippingCity' => franchisee[0].ShippingCity,
                        'shippingState' => franchisee[0].ShippingState,
                        'shippingStateCode' => shippingStateCode,
                        'shippingPostalCode' => franchisee[0].ShippingPostalCode,
                        'longitude' => String.valueOf(franchisee[0].Geolocation__Longitude__s),
                        'latitude' => String.valueOf(franchisee[0].Geolocation__Latitude__s),
                        'depotId' => franchisee[0].Depot__c,
                        'url' => userToFranchisee[0].MediumPhotoUrl,
                        'customers' => customers,
                        'orders' => orders
                    }
                });
            } catch (Exception e) { return '{"error":"' +  e.getMessage() + '","message":"error"}'; }
        }

        global String getFranchiseeForTerritoryRest(Map<String, String> generalData) {
            try {
                String numberTerritory = generalData.containsKey('numberTerritory') ? generalData.get('numberTerritory') : null;

                List<Account> franchisee = [
                    SELECT Id, Name, FirstName, LastName, Van_Type__c,
                        Phone, PersonEmail, BillingCountry, Depot__c,
                        BillingStreet, BillingCity, BillingState,
                        //BillingStateCode,
                        Geolocation__Longitude__s,
                        Geolocation__Latitude__s, PersonMobilePhone
                    FROM Account
                    WHERE Id IN (
                            SELECT Franchisee__c
                            FROM Territory__c
                            WHERE Name =: numberTerritory
                            AND isActive__c = true
                        )
                    LIMIT 1
                ];

                if (franchisee.isEmpty()) {
                    return '{"error":"Franchisee not found","message":"error"}';
                } else {
                    return JSON.serialize(new Map<String, Object>{
                        'message' => 'success',
                        'franchisee' => new Map<String, String>{
                            'id' => franchisee[0].Id,
                            'name' => franchisee[0].Name,
                            'firstName' => franchisee[0].FirstName,
                            'lastName' => franchisee[0].LastName,
                            'phone' => franchisee[0].Phone,
                            'personMobilePhone' => franchisee[0].PersonMobilePhone,
                            'personEmail' => franchisee[0].PersonEmail,
                            'vanType' => franchisee[0].Van_Type__c,
                            'depotId' => franchisee[0].Depot__c,
                            'billingCountry' => franchisee[0].BillingCountry,
                            'billingStreet' => franchisee[0].BillingStreet,
                            'billingCity' => franchisee[0].BillingCity,
                            'billingState' => franchisee[0].BillingState,
                            //'billingStateCode' => franchisee[0].BillingStateCode,
                            'longitude' => String.valueOf(franchisee[0].Geolocation__Longitude__s),
                            'latitude' => String.valueOf(franchisee[0].Geolocation__Latitude__s)
                        }
                    });
                }
            } catch (Exception e) {return '{"error":"' +  e.getMessage() + '","message":"error"}';}
        }

        global String getPaymentConnectSettingsExt() {

            StripeConnectWrapper stripeConnect = new StripeConnectWrapper();
            List<Map<String, String>> stripeConnectSettings = TouchCRHelper.getCustomSettings('TouchCRBase__Stripe_Connect__c');

            for (Map<String, String> stripeConnectSetting : stripeConnectSettings) {
                stripeConnect.paymentAgentId = stripeConnectSetting.get('TouchCRBase__Value__c');

            }

            return JSON.serialize(stripeConnect);

        }

        global String saveStripeConnectExt(String settings) {

            StripeConnectWrapper settingsDeserialized = (StripeConnectWrapper)JSON.deserialize(settings, StripeConnectWrapper.class);
            List<Map<String, String>> stripeConnectSettings = TouchCRHelper.getCustomSettings('TouchCRBase__Stripe_Connect__c');
            String Id;

            for (Map<String, String> stripeConnectSetting : stripeConnectSettings) {
                Id = stripeConnectSetting.get('Id');
            }

            Stripe_Connect__c connectSettings = new Stripe_Connect__c(
                    Id = Id,
                    Name = 'StripeConnect',
                    Value__c = settingsDeserialized.paymentAgentId
            );
            upsert connectSettings;
            return 'Organization has been successfully saved!';
        }

    }


	public class StripeConnectWrapper {
		protected String paymentAgentId { get; set; }
	}


}