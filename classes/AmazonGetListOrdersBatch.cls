public class AmazonGetListOrdersBatch implements Database.Batchable<AmazonOrder>, Database.Stateful, Database.AllowsCallouts {

    String nextToken;
    Boolean firstRun;

    Integer syncStep;

    String GATEWAY_ID;
    String SALES_FUNNEL;
    String API_KEY;
    String API_SECRET;
    String MERCHANT_ID;
    String BRAND;

    Map<String, String> billingCountryCodeLabelDictionary;
    Map<String, String> shippingCountryCodeLabelDictionary;
    Map<String, String> billingStateCodeLabelDictionary;
    Map<String, String> shippingStateCodeLabelDictionary;

    public AmazonGetListOrdersBatch() {
        nextToken = null;
        firstRun = true;
    }

    public AmazonGetListOrdersBatch(String amazonNextToken ) {
        nextToken = amazonNextToken;
        firstRun = false;
    }


    public Iterable<AmazonOrder> start(Database.BatchableContext BC) {

        TouchCRBase__Log__c log = new TouchCRBase__Log__c();
        log.TouchCRBase__Event_Type__c = 'Amazon AmazonGetListOrdersBatch Start';
        log.TouchCRBase__Event_Description__c = '';

        try {
            //Check availability of all necessary Custom Settings for integration
            Set<String> settingKeys = new Set<String>();
            settingKeys.add('Amazon.ApiKey');
            settingKeys.add('Amazon.ApiSecret');
            settingKeys.add('Amazon.MerchantId');
            settingKeys.add('Amazon.MarketPlaceId');
            settingKeys.add('Amazon.SyncStartDate');

            Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('allSettings');

            //check if class executing in his integration order and not scheduled whithout main process step by step
            syncStep = allSettings.containsKey('Amazon.SyncStep') ? Integer.valueOf( allSettings.get('Amazon.SyncStep') ) : -1;
            if (syncStep != 6) {
                log.TouchCRBase__Event_Status__c = 'Error';
                log.TouchCRBase__Event_Description__c += 'You can not run Amazon classes in invalid execution order.\n';

                if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
                    TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
                    TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
                    insert log;
                }
                AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getAsyncApexJobId('AmazonGetListOrdersBatch'));
                return new List<AmazonOrder>();
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
                return new List<AmazonOrder>();
            }

            if (allSettings.containsKey('Amazon.SalesFunnel')) {
                SALES_FUNNEL = allSettings.get('Amazon.SalesFunnel');
            }
            if (allSettings.containsKey('Amazon.Brand')) {
                BRAND = allSettings.get('Amazon.Brand');
            }
            if (allSettings.containsKey('D.'+BRAND)) {
                GATEWAY_ID = allSettings.get('D.'+BRAND);
            }

            API_KEY = availableSettings.get('Amazon.ApiKey');
            API_SECRET = availableSettings.get('Amazon.ApiSecret');
            MERCHANT_ID = availableSettings.get('Amazon.MerchantId');

            //Get Available Country Codes For using in Account Address information
            if (TouchCRHelper.isSCPEnabled() == TRUE) {
            Schema.DescribeFieldResult billingCountryCodeResult = Schema.sObjectType.Account.fields.getMap().get('BillingCountryCode').getDescribe();
            List<Schema.PicklistEntry> billingCountryCodeEntries = billingCountryCodeResult.getPicklistValues();

            billingCountryCodeLabelDictionary = new Map<String, String>();
            for (Schema.PicklistEntry ple : billingCountryCodeEntries) {
                if (ple.isActive()) {
                    billingCountryCodeLabelDictionary.put(ple.getValue().toLowerCase(), ple.getValue() );
                    billingCountryCodeLabelDictionary.put(ple.getLabel().toLowerCase(), ple.getValue() );
                }
            }

            Schema.DescribeFieldResult shippingCountryCodeResult = Schema.sObjectType.Account.fields.getMap().get('ShippingCountryCode').getDescribe();
            List<Schema.PicklistEntry> shippingCountryCodeEntries = shippingCountryCodeResult.getPicklistValues();

            shippingCountryCodeLabelDictionary = new Map<String, String>();
            for (Schema.PicklistEntry ple : shippingCountryCodeEntries) {
                if (ple.isActive()) {
                    shippingCountryCodeLabelDictionary.put(ple.getValue().toLowerCase() , ple.getValue());
                    shippingCountryCodeLabelDictionary.put(ple.getLabel().toLowerCase(), ple.getValue());
                }
            }

            Schema.DescribeFieldResult billingStateCodeResult = Schema.sObjectType.Account.fields.getMap().get('BillingStateCode').getDescribe();
            List<Schema.PicklistEntry> billingStateCodeEntries = billingStateCodeResult.getPicklistValues();

            billingStateCodeLabelDictionary = new Map<String, String>();
            for (Schema.PicklistEntry ple : billingStateCodeEntries) {
                if (ple.isActive()) {
                    billingStateCodeLabelDictionary.put(ple.getValue().toLowerCase(), ple.getValue() );
                    billingStateCodeLabelDictionary.put(ple.getLabel().toLowerCase(), ple.getValue() );
                }
            }

            Schema.DescribeFieldResult shippingStateCodeResult = Schema.sObjectType.Account.fields.getMap().get('ShippingStateCode').getDescribe();
            List<Schema.PicklistEntry> shippingStateCodeEntries = shippingStateCodeResult.getPicklistValues();

            shippingStateCodeLabelDictionary = new Map<String, String>();
            for (Schema.PicklistEntry ple : shippingStateCodeEntries) {
                if (ple.isActive()) {
                    shippingStateCodeLabelDictionary.put(ple.getValue().toLowerCase() , ple.getValue());
                    shippingStateCodeLabelDictionary.put(ple.getLabel().toLowerCase(), ple.getValue());
                }
            }
            }


            String responseXML;

            String lastupdateafter = availableSettings.get('Amazon.SyncStartDate') + 'T00%3A00%3A00Z';

            if (String.isBlank(nextToken) && firstRun == true) {
                responseXML = AmazonRequestHelper.ListOrders(availableSettings.get('Amazon.ApiKey'), availableSettings.get('Amazon.ApiSecret'),
                    availableSettings.get('Amazon.MerchantId'), availableSettings.get('Amazon.MarketPlaceId'), lastupdateafter);
                log.TouchCRBase__Event_Description__c += 'Amazon Request: ListOrders\n';
            }
            else if (!String.isBlank(nextToken) && firstRun == false) {
                responseXML = AmazonRequestHelper.ListOrdersByNextToken(availableSettings.get('Amazon.ApiKey'), availableSettings.get('Amazon.ApiSecret'),
                    availableSettings.get('Amazon.MerchantId'), nextToken);
                nextToken = null;
                log.TouchCRBase__Event_Description__c += 'Amazon Request: ListOrdersByNextToken\n';
            }
            else if (firstRun == false && String.isBlank(nextToken)) {
                return new List<AmazonOrder>();
            }

            Map<String, String> setting = new Map<String, String>();
            setting.put('Amazon.SyncStep', '7');
            TouchCRBase.TouchCRHelper.setSettings(setting);
            syncStep = 7;

            List<Dom.XmlNode> nodes = getXMLOrdersList(responseXML);

            System.debug('NextToken: ' + nextToken);

            List<AmazonOrder> amazonOrders = new List<AmazonOrder>();
            for (Dom.XmlNode node : nodes) {
                amazonOrders.add( processOrder(node) );
            }

            log.TouchCRBase__Event_Status__c = 'Success';
            log.TouchCRBase__Event_Description__c += 'Amazon Orders count: ' + amazonOrders.size() + '\n';
            log.TouchCRBase__Event_Description__c += 'Amazon Next Token: ' + nextToken + '\n';

            if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
                TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
                TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
                insert log;
            }
            return amazonOrders;

        }
        catch (Exception ex) {
            log.TouchCRBase__Event_Status__c += 'Error';
            log.TouchCRBase__Event_Description__c += ex.getMessage();

            if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
                TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
                TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
                insert log;
            }
            return new List<AmazonOrder>();
        }

    }

    public void execute(Database.BatchableContext BC, List<AmazonOrder> scope) {

        if (AmazonProcessingHelper.isSyncAborted()) {
            AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('Amazon ListOrdersByNextToken'));
            AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getAsyncApexJobId('AmazonGetListOrdersBatch'));
            return;
        }

        Integer ordersWithoutItemsCount = 0;

        TouchCRBase__Log__c log = new TouchCRBase__Log__c();
        log.TouchCRBase__Event_Type__c = 'Amazon Sync AmazonGetListOrdersBatch execute';
        log.TouchCRBase__Event_Description__c = '';

        try {
            log.TouchCRBase__Event_Description__c += 'Scope size: ' + scope.size() + '\n';

            Map<String, List<AmazonOrderItem> > amazonOrderListOrderItemsMap = new Map<String, List<AmazonOrderItem> >();
            Set<String> orderItemsAsins = new Set<String>();

            Set<String> orderBuyersEmails = new Set<String>();
            Map<String, AmazonOrder> buyerEmailAmzOrderMap = new Map<String, AmazonOrder>();

            List<AmazonOrder> orderList = new List<AmazonOrder>();
            for (AmazonOrder order : scope) {
                if (order.OrderStatus == 'Shipped') { //only shipped order provide customer info
                    orderList.add(order);
                }
            }

            for (AmazonOrder order : orderList) {
                amazonOrderListOrderItemsMap.put(order.AmazonOrderId, new List<AmazonOrderItem>());

                orderBuyersEmails.add(order.BuyerEmail);

                buyerEmailAmzOrderMap.put(order.BuyerEmail, order);

                String orderItemresponse = AmazonRequestHelper.ListOrderItems(API_KEY, API_SECRET, MERCHANT_ID, order.AmazonOrderId);

                List<Dom.XmlNode> xmlOrderItems = getXMLOrderItems(orderItemresponse);

                for (Dom.XmlNode orderItem : xmlOrderItems) {
                    AmazonOrderItem amzOrderItem = processOrderItem(orderItem);

                    amazonOrderListOrderItemsMap.get(order.AmazonOrderId).add(amzOrderItem);
                    orderItemsAsins.add(amzOrderItem.ASIN);
                }
            }

            Map<String, String> productAsinProductIdMap = new Map<String, String>();
            for (Product2 prod : [SELECT Id, TouchCRBase__Connected_Id__c FROM Product2 WHERE TouchCRBase__Connected_Id__c IN :orderItemsAsins]) {
                productAsinProductIdMap.put(prod.TouchCRBase__Connected_Id__c, prod.Id);
            }

            Map<String, String> emailExistingAccountMap = new Map<String, String>();
            for (Account acc : [SELECT Id, PersonEmail, AmazonAccountId__c From Account WHERE AmazonAccountId__c IN :orderBuyersEmails]) {
                emailExistingAccountMap.put(acc.AmazonAccountId__c, acc.Id);
            }

            String presonAccountRTId = [SELECT Id FROM RecordType WHERE (Name='Person Account') AND (SobjectType='Account')].Id;

            List<Account> accountsToInsert = new List<Account>();
            for (String buyerEmail : buyerEmailAmzOrderMap.keySet()) {
                if ( !emailExistingAccountMap.containsKey(buyerEmail) ) {
                    AmazonOrder order = buyerEmailAmzOrderMap.get(buyerEmail);

                    Account acc = new Account();
                    acc.RecordTypeID = presonAccountRTId;

                    List<String> name = order.BuyerName.split(' ');
                    if (name.size() > 1) {
                        acc.FirstName = name[0];
                        acc.LastName = '';
                        for (Integer i = 1; i < name.size(); i++) {
                            acc.LastName += name[i] + ' ';
                        }
                    }
                    else {
                        acc.LastName = order.BuyerName;
                    }

                    acc.AmazonAccountId__c = order.BuyerEmail;
                    acc.TouchCRBase__Brand_Assortment__c = BRAND;
                    acc.TouchCRBase__sales_funnel_name__c = SALES_FUNNEL;

                    acc.PersonMailingStreet = order.AddressLine1;
                    acc.PersonMailingPostalCode = order.PostalCode;
                    acc.PersonMailingCity = order.City;
                    // the amazon connector to NOT put the amazon email address (*markeplace.com) in the email field, it is causing downstream problems in Journey Builder
                    // acc.PersonEmail = order.BuyerEmail;
                    acc.PersonMobilePhone = order.Phone;
                    acc.PersonHomePhone = order.Phone;
                    acc.Phone = order.Phone;

                    acc.BillingStreet = order.AddressLine1;
                    acc.BillingPostalCode = order.PostalCode;
                    acc.BillingCity = order.City;
                    acc.ShippingStreet = order.AddressLine1;
                    acc.ShippingPostalCode = order.PostalCode;
                    acc.ShippingCity = order.City;

                    order.CountryCode = order.CountryCode == null ? '' : order.CountryCode;
                    order.StateOrRegion = order.StateOrRegion == null ? '' : order.StateOrRegion;

                    acc.Original_Country__c = order.CountryCode;
                    acc.Original_State__c = order.StateOrRegion;

                    Map<String, String> amazonSettings = TouchCRBase.TouchCRHelper.getSettings('Amazon.ResolveEmail');
                    if (amazonSettings.containsKey('Amazon.ResolveEmail')) {
                        acc.DF_Need_Append__c = Boolean.valueOf(amazonSettings.get('Amazon.ResolveEmail'));
                    }

                    if (TouchCRHelper.isSCPEnabled() == TRUE) {
                        /*if (billingCountryCodeLabelDictionary.containsKey(order.CountryCode.toLowerCase())) {
                            acc.BillingCountryCode = billingCountryCodeLabelDictionary.get(order.CountryCode.toLowerCase());
                        }
                        if (billingStateCodeLabelDictionary.containsKey(order.StateOrRegion.toLowerCase()) && !String.isBlank(acc.BillingCountryCode) ) {
                            acc.BillingStateCode = billingStateCodeLabelDictionary.get( order.StateOrRegion.toLowerCase() );
                        }

                        if (shippingCountryCodeLabelDictionary.containsKey(order.CountryCode.toLowerCase())) {
                            acc.ShippingCountryCode = shippingCountryCodeLabelDictionary.get(order.CountryCode.toLowerCase());
                        }
                        if(shippingStateCodeLabelDictionary.containsKey(order.StateOrRegion.toLowerCase()) && !String.isBlank(acc.ShippingCountryCode) ) {
                            acc.ShippingStateCode = shippingStateCodeLabelDictionary.get(order.StateOrRegion.toLowerCase());
                        }*/
                    }

                    accountsToInsert.add(acc);
                }
            }


            Boolean isCreateableAccount = false;
            if (TouchCRHelper.isSCPEnabled() == TRUE) {
                isCreateableAccount = (
                    Account.RecordTypeID.getDescribe().isCreateable() &&
                    Account.FirstName.getDescribe().isCreateable() &&
                    Account.LastName.getDescribe().isCreateable() &&
                    Account.TouchCRBase__Brand_Assortment__c.getDescribe().isCreateable() &&
                    Account.TouchCRBase__sales_funnel_name__c.getDescribe().isCreateable() &&
                    Account.PersonMailingStreet.getDescribe().isCreateable() &&
                    Account.PersonMailingPostalCode.getDescribe().isCreateable() &&
                    Account.PersonMailingCity.getDescribe().isCreateable() &&
                    Account.PersonEmail.getDescribe().isCreateable() &&
                    Account.PersonMobilePhone.getDescribe().isCreateable() &&
                    Account.PersonHomePhone.getDescribe().isCreateable() &&
                    Account.BillingStreet.getDescribe().isCreateable() &&
                    Account.BillingPostalCode.getDescribe().isCreateable() &&
                    Schema.sObjectType.Account.fields.getMap().get('BillingCountryCode').getDescribe().isCreateable() &&
                    Schema.sObjectType.Account.fields.getMap().get('BillingStateCode').getDescribe().isCreateable() &&
                    Account.BillingCity.getDescribe().isCreateable() &&
                    Account.Phone.getDescribe().isCreateable() &&
                    Account.ShippingStreet.getDescribe().isCreateable() &&
                    Account.ShippingPostalCode.getDescribe().isCreateable() &&
                    Schema.sObjectType.Account.fields.getMap().get('ShippingCountryCode').getDescribe().isCreateable() &&
                    Schema.sObjectType.Account.fields.getMap().get('ShippingStateCode').getDescribe().isCreateable() &&
                    Account.ShippingCity.getDescribe().isCreateable() &&
                    Account.Original_Country__c.getDescribe().isCreateable() &&
                    Account.Original_State__c.getDescribe().isCreateable() &&
                    Account.AmazonAccountId__c.getDescribe().isCreateable() &&
                    Account.DF_Need_Append__c.getDescribe().isCreateable()
                );
            }else {
                isCreateableAccount = (
                    Account.RecordTypeID.getDescribe().isCreateable() &&
                    Account.FirstName.getDescribe().isCreateable() &&
                    Account.LastName.getDescribe().isCreateable() &&
                    Account.TouchCRBase__Brand_Assortment__c.getDescribe().isCreateable() &&
                    Account.TouchCRBase__sales_funnel_name__c.getDescribe().isCreateable() &&
                    Account.PersonMailingStreet.getDescribe().isCreateable() &&
                    Account.PersonMailingPostalCode.getDescribe().isCreateable() &&
                    Account.PersonMailingCity.getDescribe().isCreateable() &&
                    Account.PersonEmail.getDescribe().isCreateable() &&
                    Account.PersonMobilePhone.getDescribe().isCreateable() &&
                    Account.PersonHomePhone.getDescribe().isCreateable() &&
                    Account.BillingStreet.getDescribe().isCreateable() &&
                    Account.BillingPostalCode.getDescribe().isCreateable() &&
                    Account.BillingCity.getDescribe().isCreateable() &&
                    Account.Phone.getDescribe().isCreateable() &&
                    Account.ShippingStreet.getDescribe().isCreateable() &&
                    Account.ShippingPostalCode.getDescribe().isCreateable() &&
                    Account.ShippingCity.getDescribe().isCreateable() &&
                    Account.Original_Country__c.getDescribe().isCreateable() &&
                    Account.Original_State__c.getDescribe().isCreateable() &&
                    Account.AmazonAccountId__c.getDescribe().isCreateable() &&
                    Account.DF_Need_Append__c.getDescribe().isCreateable()
                );
            }

            if (isCreateableAccount) {
                List<Database.SaveResult> accInRes = Database.insert(accountsToInsert, false);
            }
            else {
                throw new PrivilegesException('Privileges Exception');
            }

            for (Account acc : accountsToInsert) {
                emailExistingAccountMap.put(acc.AmazonAccountId__c, acc.Id);
            }

            List<TouchCRBase__Order__c> sfOrders = new List<TouchCRBase__Order__c>();
            Set<String> amzOrdersIds = new Set<String>();

            for (AmazonOrder order : orderList) {

                TouchCRBase__Order__c sfOrder = new TouchCRBase__Order__c();
                sfOrder.TouchCRBase__Connected_Id__c = order.AmazonOrderId;
                sfOrder.TouchCRBase__Connection_Name__c = TouchCRBase.TouchCRHelper.getSettings('Amazon.CurrentConnectionName')
                    .get('Amazon.CurrentConnectionName');
                sfOrder.TouchCRBase__Status__c = 'Complete';
                sfOrder.TouchCRBase__Date__c = order.PurchaseDate;

                sfOrder.TouchCRBase__Billing_Email__c = order.BuyerEmail;

                sfOrder.TouchCRBase__Account__c = emailExistingAccountMap.get(order.BuyerEmail);
                //sfOrder.TouchCRBase__Gateway__c = GATEWAY_ID;

                //payment details
                sfOrder.TouchCRBase__Subtotal__c = order.Amount;
                Decimal shipping = 0;
                Decimal tax = 0;
                List<AmazonOrderItem> orderItems = amazonOrderListOrderItemsMap.get(order.AmazonOrderId);
                for(AmazonOrderItem orderItem : orderItems) {
                    if (orderItem.ItemTaxAmount != null) {
                        tax += orderItem.ItemTaxAmount;
                    }
                    // FIXME
                    if (orderItem.ShippingPriceAmount != null) {
                        shipping += orderItem.ShippingPriceAmount;
                    }
                    if (orderItem.ShippingTaxAmount != null) {
                        shipping += orderItem.ShippingTaxAmount;
                    }
                }
                sfOrder.TouchCRBase__Tax__c = tax;
                sfOrder.TouchCRBase__Shipping__c = shipping;

                sfOrder.TouchCRBase__Payment_Start_Date__c = Date.newInstance(order.PurchaseDate.year() , order.PurchaseDate.month(), order.PurchaseDate.day());
                sfOrder.TouchCRBase__Payment_End_Date__c = Date.newInstance(order.PurchaseDate.year() , order.PurchaseDate.month(), order.PurchaseDate.day());

                sfOrder.TouchCRBase__Payment_Frequency__c = 'Once';

                //shipping details
                //if (order.ShippedByAmazonTFM != null) {
                //  sfOrder.Shipped_By_Amazon_TFM__c = order.ShippedByAmazonTFM;
                //}

                order.Name = order.Name == null ? '' : order.Name;

                List<String> name = order.Name.split(' ');
                if (name.size() > 1) {
                    sfOrder.TouchCRBase__Shipping_First_Name__c = name[0];
                    sfOrder.TouchCRBase__Shipping_Name__c = '';
                    for (Integer i = 1; i < name.size(); i++) {
                        sfOrder.TouchCRBase__Shipping_Name__c += name[i] + ' ';
                    }
                }
                else {
                    sfOrder.TouchCRBase__Shipping_Name__c = order.Name;
                }
                sfOrder.TouchCRBase__Shipping_Address__c = order.AddressLine1;
                sfOrder.TouchCRBase__Shipping_Address_Line_2__c = order.AddressLine2;
                sfOrder.TouchCRBase__Shipping_Phone__c = order.Phone;
                sfOrder.TouchCRBase__Shipping_Zip_Postal__c = order.PostalCode;
                sfOrder.TouchCRBase__Billing_Country__c = order.CountryCode;
                sfOrder.TouchCRBase__Shipping_State__c = order.StateOrRegion;
                sfOrder.TouchCRBase__Shipping_City__c = order.City;
				sfOrder.TouchCRBase__Brand__c = BRAND;
                sfOrder.TouchCRBase__sales_funnel_name__c = SALES_FUNNEL;

                sfOrders.add(sfOrder);
                amzOrdersIds.add(sfOrder.TouchCRBase__Connected_Id__c);
            }

            List<TouchCRBase__Order__c> existingOrders = [
                SELECT Id, TouchCRBase__Connected_Id__c, TouchCRBase__Status__c, TouchCRBase__Shipping__c
                FROM TouchCRBase__Order__c
                WHERE TouchCRBase__Connected_Id__c IN :amzOrdersIds
            ];

            Map<String, TouchCRBase__Order__c> existingOrdersMap = new Map<String, TouchCRBase__Order__c>();
            for (TouchCRBase__Order__c order : existingOrders) {
                existingOrdersMap.put(order.TouchCRBase__Connected_Id__c, order);
            }

            List<TouchCRBase__Order__c> ordersToInsert = new List<TouchCRBase__Order__c>();
            List<TouchCRBase__Order__c> ordersToUpdate = new List<TouchCRBase__Order__c>();
            for (TouchCRBase__Order__c order : sfOrders) {
                if (!existingOrdersMap.keySet().contains(order.TouchCRBase__Connected_Id__c)) {
                    ordersToInsert.add(order);
                }
                else {
                    //update existing order
                    TouchCRBase__Order__c existingSFOrder = existingOrdersMap.get(order.TouchCRBase__Connected_Id__c);
                    Boolean isOrderUpdated = false;
                    if (existingSFOrder.TouchCRBase__Status__c != order.TouchCRBase__Status__c) {
                        existingSFOrder.TouchCRBase__Status__c = order.TouchCRBase__Status__c == 'Canceled' ? 'Canceled' : order.TouchCRBase__Status__c == 'Complete' ? 'Complete' : 'Initiated';
                        isOrderUpdated = true;
                    }
                    // FIXME shipping tax
                    if (existingSFOrder.TouchCRBase__Shipping__c != order.TouchCRBase__Shipping__c) {
                        existingSFOrder.TouchCRBase__Shipping__c = order.TouchCRBase__Shipping__c;
                    }
                    if (isOrderUpdated) {
                        ordersToUpdate.add(existingSFOrder);
                    }
                }
            }

            Boolean isUpdateableTouchCRBaseOrder = (
                TouchCRBase__Order__c.TouchCRBase__Connected_Id__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Status__c.getDescribe().isUpdateable()   &&
                TouchCRBase__Order__c.TouchCRBase__Date__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Billing_Email__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Account__c.getDescribe().isUpdateable() &&
                //TouchCRBase__Order__c.TouchCRBase__Gateway__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Subtotal__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Tax__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Payment_Start_Date__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Payment_End_Date__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Payment_Frequency__c.getDescribe().isUpdateable() &&
                //TouchCRBase__Order__c.Shipped_By_Amazon_TFM__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_First_Name__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_Name__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_Address__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_Address_Line_2__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_Phone__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_Zip_Postal__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_State__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_City__c.getDescribe().isUpdateable() &&
                TouchCRBase__Order__c.TouchCRBase__sales_funnel_name__c.getDescribe().isUpdateable()
            );

            if (isUpdateableTouchCRBaseOrder) {
                List<Database.SaveResult> ordUpdRes = Database.update(ordersToUpdate, false);
            }
            else {
                throw new PrivilegesException('Privileges Exception');
            }

            Boolean isCreateableOrder = (
                TouchCRBase__Order__c.TouchCRBase__Connected_Id__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Status__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Date__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Billing_Email__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Account__c.getDescribe().isCreateable() &&
                //TouchCRBase__Order__c.TouchCRBase__Gateway__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Subtotal__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Tax__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Payment_Start_Date__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Payment_End_Date__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Payment_Frequency__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_First_Name__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_Name__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_Address__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_Phone__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_Zip_Postal__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Billing_Country__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_State__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_City__c.getDescribe().isCreateable() &&
                //TouchCRBase__Order__c.Shipped_By_Amazon_TFM__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__Shipping_Address_Line_2__c.getDescribe().isCreateable() &&
                TouchCRBase__Order__c.TouchCRBase__sales_funnel_name__c.getDescribe().isUpdateable()
            );

            if (isCreateableOrder) {
                List<Database.SaveResult> ordInRes = Database.insert(ordersToInsert, false);
            }
            else {
                throw new PrivilegesException('Privileges Exception');
            }

            existingOrders.addAll(ordersToInsert);

            List<TouchCRBase__OrderItem__c> sfOrderItems = new List<TouchCRBase__OrderItem__c>();
            Set<String> amzOrderItemsIds = new Set<String>();

            //walkthrough Orders and create OrderItems
            for (TouchCRBase__Order__c order : existingOrders) {

                List<AmazonOrderItem> amzOrderItems = amazonOrderListOrderItemsMap.get(order.TouchCRBase__Connected_Id__c);

                if (amzOrderItems.size() == 0) {
                    ordersWithoutItemsCount++;
                }

                for (AmazonOrderItem amzOrderItem : amzOrderItems) {
                    TouchCRBase__OrderItem__c sfOrderItem = new TouchCRBase__OrderItem__c();

                    sfOrderItem.TouchCRBase__Order__c = order.Id;
                    sfOrderItem.TouchCRBase__Connected_Id__c = amzOrderItem.OrderItemId;
                    sfOrderItem.TouchCRBase__Connection_Name__c = TouchCRBase.TouchCRHelper.getSettings('Amazon.CurrentConnectionName')
                        .get('Amazon.CurrentConnectionName');

                    sfOrderItem.TouchCRBase__Product__c = productAsinProductIdMap.containsKey(amzOrderItem.ASIN) ? productAsinProductIdMap.get(amzOrderItem.ASIN) : null;
                    // FIXME
                    sfOrderItem.TouchCRBase__Quantity__c = amzOrderItem.QuantityOrdered;
                    try {
                        sfOrderItem.TouchCRBase__Product_Price__c = amzOrderItem.ItemPriceAmount / amzOrderItem.QuantityOrdered;
                    }
                    catch (Exception e) {
                        sfOrderItem.TouchCRBase__Product_Price__c = 0;
                    }
                    // some other fields

                    if (sfOrderItem.TouchCRBase__Product__c != null && sfOrderItem.TouchCRBase__Product_Price__c != null) {
                        amzOrderItemsIds.add(amzOrderItem.OrderItemId);
                        sfOrderItems.add(sfOrderItem);
                    }
                    else if (sfOrderItem.TouchCRBase__Product__c != null && sfOrderItem.TouchCRBase__Product_Price__c == null) {
                        sfOrderItem.TouchCRBase__Product_Price__c = 0;

                        amzOrderItemsIds.add(amzOrderItem.OrderItemId);
                        sfOrderItems.add(sfOrderItem);
                    }
                    else {
                        log.TouchCRBase__Event_Description__c += 'Not Inserted OrderItem: ' + amzOrderItem + '\n';
                        log.TouchCRBase__Event_Description__c += 'Order without item: ' + order.Id + '\n';
                    }
                }
            }

            List<TouchCRBase__OrderItem__c> existingOrderItems = [SELECT Id, TouchCRBase__Connected_Id__c
                                                                FROM TouchCRBase__OrderItem__c
                                                                WHERE TouchCRBase__Connected_Id__c IN :amzOrderItemsIds];

            Set<String> existingOrderItemsIds = new Set<String>();
            for (TouchCRBase__OrderItem__c orderItem : existingOrderItems) {
                existingOrderItemsIds.add(orderItem.TouchCRBase__Connected_Id__c);
            }

            List<TouchCRBase__OrderItem__c> sfOrderItemsToInsert = new List<TouchCRBase__OrderItem__c>();
            for (TouchCRBase__OrderItem__c sfOrderItem : sfOrderItems) {
                if (!existingOrderItemsIds.contains(sfOrderItem.TouchCRBase__Connected_Id__c)) {
                    sfOrderItemsToInsert.add(sfOrderItem);
                }
            }

            Boolean isCreateableOrderItem = (
                TouchCRBase__OrderItem__c.TouchCRBase__Order__c.getDescribe().isCreateable() &&
                TouchCRBase__OrderItem__c.TouchCRBase__Connected_Id__c.getDescribe().isCreateable() &&
                TouchCRBase__OrderItem__c.TouchCRBase__Product__c.getDescribe().isCreateable() &&
                TouchCRBase__OrderItem__c.TouchCRBase__Product_Price__c.getDescribe().isCreateable() &&
                TouchCRBase__OrderItem__c.TouchCRBase__Quantity__c.getDescribe().isCreateable()
            );

            if (isCreateableOrderItem) {
                List<Database.SaveResult> orditINR = Database.insert(sfOrderItemsToInsert, false);
            }
            else {
                throw new PrivilegesException('Privileges Exception');
            }

            Set<String> insertedOrdersIds = new Set<String>();
            for(TouchCRBase__Order__c order : ordersToInsert) {
                insertedOrdersIds.add(order.Id);
            }

            List<TouchCRBase__Order__c> insertedOrders = [
                SELECT Id, TouchCRBase__Total__c, TouchCRBase__Shipping_First_Name__c, TouchCRBase__Shipping_Name__c,
                    TouchCRBase__Shipping_Phone__c, TouchCRBase__Shipping_Address__c, TouchCRBase__Shipping_Address_Line_2__c,
                    TouchCRBase__Shipping_Zip_Postal__c, TouchCRBase__Billing_Country__c, TouchCRBase__Shipping_State__c, TouchCRBase__Shipping_City__c,
                    TouchCRBase__Date__c
                FROM TouchCRBase__Order__c
                WHERE Id IN :insertedOrdersIds
            ];

            List<TouchCRBase__Order_Transaction__c> transactionsToInsert = new List<TouchCRBase__Order_Transaction__c>();
            for (TouchCRBase__Order__c order : insertedOrders) {
                TouchCRBase__Order_Transaction__c transact = new TouchCRBase__Order_Transaction__c();
                transact.TouchCRBase__Order__c = order.Id;
                transact.TouchCRBase__Amount__c = order.TouchCRBase__Total__c;
                //transact.TouchCRBase__Gateway__c = GATEWAY_ID;
                //transact.TouchCRBase__Gateway_ID__c = GATEWAY_ID;
                transact.TouchCRBase__Currency__c = 'US Dollars';
                transact.TouchCRBase__Type__c = 'Charge';
                transact.TouchCRBase__Response_Status__c = 'Approved';
                // TouchCRBase__Payment_Date__c DB required, get it from order.TouchCRBase__Date__c
                transact.TouchCRBase__Payment_Date__c = order.TouchCRBase__Date__c;


                //Address details
                transact.TouchCRBase__Billing_First__c = order.TouchCRBase__Shipping_First_Name__c;
                transact.TouchCRBase__Billing_Last__c = order.TouchCRBase__Shipping_Name__c;

                transact.TouchCRBase__Billing_Phone__c = order.TouchCRBase__Shipping_Phone__c;
                transact.TouchCRBase__Billing_Address__c = order.TouchCRBase__Shipping_Address__c;
                transact.TouchCRBase__Billing_Address_Line_2__c = order.TouchCRBase__Shipping_Address_Line_2__c;
                transact.TouchCRBase__Billing_Postal_Code__c = order.TouchCRBase__Shipping_Zip_Postal__c;
                transact.TouchCRBase__Billing_Country__c = order.TouchCRBase__Billing_Country__c;
                transact.TouchCRBase__Billing_State__c = order.TouchCRBase__Shipping_State__c;
                transact.TouchCRBase__Billing_City__c = order.TouchCRBase__Shipping_City__c;

                transactionsToInsert.add(transact);
            }

            Boolean isCreateableTransaction = (
                TouchCRBase__Order_Transaction__c.TouchCRBase__Order__c.getDescribe().isCreateable() &&
                TouchCRBase__Order_Transaction__c.TouchCRBase__Amount__c.getDescribe().isCreateable() &&
                //TouchCRBase__Order_Transaction__c.TouchCRBase__Gateway__c.getDescribe().isCreateable() &&
                //TouchCRBase__Order_Transaction__c.TouchCRBase__Gateway_ID__c.getDescribe().isCreateable() &&
                TouchCRBase__Order_Transaction__c.TouchCRBase__Currency__c.getDescribe().isCreateable() &&
                TouchCRBase__Order_Transaction__c.TouchCRBase__Type__c.getDescribe().isCreateable() &&
                TouchCRBase__Order_Transaction__c.TouchCRBase__Response_Status__c.getDescribe().isCreateable() &&
                TouchCRBase__Order_Transaction__c.TouchCRBase__Billing_First__c.getDescribe().isCreateable() &&
                TouchCRBase__Order_Transaction__c.TouchCRBase__Billing_Last__c.getDescribe().isCreateable() &&
                TouchCRBase__Order_Transaction__c.TouchCRBase__Billing_Phone__c.getDescribe().isCreateable() &&
                TouchCRBase__Order_Transaction__c.TouchCRBase__Billing_Address__c.getDescribe().isCreateable() &&
                TouchCRBase__Order_Transaction__c.TouchCRBase__Billing_Postal_Code__c.getDescribe().isCreateable() &&
                TouchCRBase__Order_Transaction__c.TouchCRBase__Billing_Country__c.getDescribe().isCreateable() &&
                TouchCRBase__Order_Transaction__c.TouchCRBase__Billing_State__c.getDescribe().isCreateable() &&
                TouchCRBase__Order_Transaction__c.TouchCRBase__Billing_City__c.getDescribe().isCreateable() &&
                TouchCRBase__Order_Transaction__c.TouchCRBase__Payment_Date__c.getDescribe().isCreateable() &&
                TouchCRBase__Order_Transaction__c.TouchCRBase__Billing_Address_Line_2__c.getDescribe().isCreateable()
            );

            if (isCreateableTransaction) {
                List<Database.SaveResult> trInRES = Database.insert(transactionsToInsert, false);

                for (Database.SaveResult sr : trInRES) {
                    if (!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {

                            log.TouchCRBase__Event_Description__c += err.getStatusCode() + ': ' + err.getMessage() + '\n';
                            log.TouchCRBase__Event_Description__c += 'Fields that affected this error: ' + err.getFields() + '\n';
                        }
                    }
                }


            }
            else {
                throw new PrivilegesException('Privileges Exception');
            }

            log.TouchCRBase__Event_Status__c = 'Success';
            log.TouchCRBase__Event_Description__c += 'Shipped Orders: ' + orderList.size() + '\n';
            log.TouchCRBase__Event_Description__c += 'Inserted Accounts: ' + accountsToInsert.size() + '\n';
            log.TouchCRBase__Event_Description__c += 'Inserted Orders: ' + ordersToInsert.size() + '\n';
            log.TouchCRBase__Event_Description__c += 'Updated Orders: ' + ordersToUpdate.size() + '\n';
            log.TouchCRBase__Event_Description__c += 'Inserted Order Items: ' + sfOrderItemsToInsert.size() + '\n';

            log.TouchCRBase__Event_Description__c += 'Orders without items: ' + ordersWithoutItemsCount + '\n';
            if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
                TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
                TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
                insert log;
            }

        }
        catch (Exception ex) {
            log.TouchCRBase__Event_Status__c = 'Error';
            log.TouchCRBase__Event_Description__c += ex.getMessage() + '\n';
            log.TouchCRBase__Event_Description__c += ex.getCause() + '\n';
            log.TouchCRBase__Event_Description__c += 'Line number: ' + ex.getLineNumber() + '\n';
            if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
                TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
                TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
                insert log;
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (syncStep != 7) {
            return;
        }

        TouchCRBase__Log__c log = new TouchCRBase__Log__c();
        log.TouchCRBase__Event_Type__c = 'Amazon Sync AmazonGetListOrdersBatch finish';
        log.TouchCRBase__Event_Description__c = '';

        try {

            AmazonProcessingHelper.abortJob(AmazonProcessingHelper.getCronTriggerId('Amazon ListOrdersByNextToken'));

            if (!String.isBlank(nextToken)) { //schedule in few minutes!

                AmazonGetListOrders aglo = new AmazonGetListOrders(nextToken);

                DateTime now = Datetime.now();
                now = now.addMinutes(1);
                String year = String.valueOf( now.year() );
                String month = String.valueOf( now.month() );
                String day = String.valueOf( now.day() );
                String hour = String.valueOf( now.hour() );
                String minute = String.valueOf( now.minute() );
                String sec = String.valueOf( now.second() );

                Map<String, String> setting = new Map<String, String>();
                setting.put('Amazon.SyncStep', '5');
                TouchCRBase.TouchCRHelper.setSettings(setting);

                String jobID = '';
                String sch = sec + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;
                if (!Test.isRunningTest()) {
                    jobID = System.schedule('Amazon ListOrdersByNextToken', sch, aglo);
                }

                log.TouchCRBase__Event_Description__c += 'Scheduled AmazonGetListOrders: ' + jobID + '\n';
            }
            else {
                Map<String, String> allSettings = TouchCRBase.TouchCRHelper.getSettings('Amazon.');

                String currentConnectionID = allSettings.get('Amazon.CurrentConnectionID');
                String connectionNextStartDate = allSettings.get('Amazon.NextSyncStartDate');

                List<TouchCRBase__TouchCRConnectionSetting__c> connSetsToUpdate = [SELECT TouchCRBase__Value__c
                                                        FROM TouchCRBase__TouchCRConnectionSetting__c
                                                        WHERE TouchCRBase__TouchCRConnection__c = :currentConnectionID
                                                        AND Name = 'Amazon.SyncStartDate'];

                for (TouchCRBase__TouchCRConnectionSetting__c cs : connSetsToUpdate) {
                    cs.TouchCRBase__Value__c = connectionNextStartDate;
                }

                if (TouchCRBase__TouchCRConnectionSetting__c.TouchCRBase__Value__c.getDescribe().isUpdateable()) {
                    Database.update(connSetsToUpdate, false);
                }


                Map<String, String> setting = new Map<String, String>();
                setting.put('Amazon.SyncStartDate', allSettings.get('Amazon.NextSyncStartDate'));
                setting.put('Amazon.SyncStep', '0');
                TouchCRBase.TouchCRHelper.setSettings(setting);

                log.TouchCRBase__Event_Description__c += 'Next Amazon API Sync StartDate: ' + allSettings.get('Amazon.NextSyncStartDate') + '\n';

                for (CronTrigger cron : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE '%AmazonSyncConnector%']) {
                    AmazonProcessingHelper.abortJob(cron.Id);
                }

                if (!String.isBlank( allSettings.get('Amazon.NextConnectionName') ) ) {

                    AmazonExecuteConnectorSync connectorSync = new AmazonExecuteConnectorSync(allSettings.get('Amazon.CurrentConnectionID'));
                    DateTime now = Datetime.now();
                    now = now.addSeconds(20);

                    String cronExpr = String.valueOf( now.second() ) + ' ' + String.valueOf( now.minute() ) + ' ' + String.valueOf( now.hour() ) + ' ' +
                            + String.valueOf( now.day() ) + ' ' + String.valueOf( now.month() ) + ' ' + '?' + ' ' + String.valueOf( now.year() );

                    System.schedule('AmazonSyncConnector', cronExpr, connectorSync);
                }
                // FIXME
                // if all active connection processed, check if Amazon feature is On and reschedule main entry point AmazonSyncAPIClient
                else {
                    log.TouchCRBase__Event_Description__c += '\nAmazon Sync processed all active connections';

                    Map<String, String> batchSettings = TouchCRBase.TouchCRHelper.getSettings('Batch.');
                    String selectedStateAmazon = batchSettings.get('Batch.AmazonStatus');
                    selectedStateAmazon = String.isBlank(selectedStateAmazon) ? 'Off' : selectedStateAmazon;

                    if (selectedStateAmazon == 'On') {
                        String selectedFrequencyParameterAmazon = batchSettings.get('Batch.AmazonFrequencyParameters');
                        selectedFrequencyParameterAmazon = String.isBlank(selectedFrequencyParameterAmazon) ? 'Days' : selectedFrequencyParameterAmazon;
                        String selectedExecuteHoursAmazon = batchSettings.get('Batch.AmazonHours');
                        selectedExecuteHoursAmazon = String.isBlank(selectedExecuteHoursAmazon) ? '1' : selectedExecuteHoursAmazon;
                        String selectedExecuteAmazon = batchSettings.get('Batch.AmazonTime');
                        selectedExecuteAmazon = String.isBlank(selectedExecuteAmazon) ? '0' : selectedExecuteAmazon;
                        String selectedExecuteAmazonDay = batchSettings.get('Batch.AmazonDay');
                        selectedExecuteAmazonDay = String.isBlank(selectedExecuteAmazonDay) ? '1' : selectedExecuteAmazonDay;

                        String nameCronTrigger = 'AmazonSync';
                        List<CronTrigger> scheduleInProgress = [
                            SELECT Id, NextFireTime
                            FROM CronTrigger
                            WHERE CronJobDetail.Name =: nameCronTrigger
                        ];
                        // stop monitor
                        for (CronTrigger ct : scheduleInProgress) {
                            System.abortJob(ct.Id);
                        }

                        String cronStr = selectedFrequencyParameterAmazon == 'Days' ?
                        '0 0 ' + selectedExecuteAmazon + ' 1/' + selectedExecuteAmazonDay + ' * ? *' : '0 0 ' + '0/' + selectedExecuteHoursAmazon + ' 1/1 * ? *';

                        Type newAmazonScheduler = Type.forName('TouchCRAmz', 'AmazonSyncAPIClient');
                        String ctId = System.schedule(nameCronTrigger , cronStr, (Schedulable)newAmazonScheduler.newInstance());

                        List<CronTrigger> scheduleNew = [SELECT Id, NextFireTime FROM CronTrigger WHERE Id =: ctId LIMIT 1];
                        if (![SELECT Id, NextFireTime FROM CronTrigger WHERE Id =: ctId LIMIT 1].isEmpty()) {
                            log.TouchCRBase__Event_Description__c += '\nAmazonSync next fire ' + scheduleNew[0].NextFireTime;
                        }

                    }
                    Map<String, String> amazonSettings = TouchCRBase.TouchCRHelper.getSettings('Amazon.ResolveEmail');
                    if (amazonSettings.containsKey('Amazon.ResolveEmail')) {
                        if (Boolean.valueOf(amazonSettings.get('Amazon.ResolveEmail'))) {
                            AmazonAppendBatch acab = new AmazonAppendBatch();
                            database.executebatch(acab, 1);
                        }
                    }
                }
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
            log.TouchCRBase__Event_Description__c += ex.getLineNumber() + '\n';
            if (TouchCRBase__Log__c.TouchCRBase__Event_Type__c.getDescribe().isCreateable() &&
                TouchCRBase__Log__c.TouchCRBase__Event_Description__c.getDescribe().isCreateable() &&
                TouchCRBase__Log__c.TouchCRBase__Event_Status__c.getDescribe().isCreateable()) {
                insert log;
            }
        }

    }

    public List<Dom.XmlNode> getXMLOrdersList(String xmlInput) {

        List<Dom.XmlNode> orders = new List<Dom.XmlNode>();

        Dom.Document doc = new Dom.Document();
        doc.load(xmlInput);

        Dom.XmlNode rootElement = doc.getRootElement();

        for(Dom.XmlNode node : rootElement.getChildElements()) {
            if(node.getName() == 'ListOrdersResult' || node.getName() == 'ListOrdersByNextTokenResult') {
                rootElement = node;
            }
        }

        for (Dom.XmlNode node : rootElement.getChildElements()) {
            if(node.getName() == 'Orders') {
                rootElement = node;
            }
            if(node.getName() == 'NextToken') {
                nextToken = node.getText();
            }
        }

        for(Dom.XmlNode node : rootElement.getChildElements()) {
            if(node.getName() == 'Order') {
                orders.add(node);
            }
        }
        return orders;
    }

    public AmazonOrder processOrder(Dom.XmlNode node) {

        AmazonOrder amazonOrder = new AmazonOrder();

        for (Dom.XmlNode innerNode :node.getChildElements()) {

            if (innerNode.getName() == 'LatestShipDate') {
                amazonOrder.LatestShipDate = Datetime.valueOf( innerNode.getText().replace('T', ' ').removeEnd('Z') );
                continue;
            }

            if (innerNode.getName() == 'OrderType') {
                amazonOrder.OrderType = innerNode.getText();
                continue;
            }

            if (innerNode.getName() == 'PurchaseDate') {
                amazonOrder.PurchaseDate = Datetime.valueOf( innerNode.getText().replace('T', ' ').removeEnd('Z') );
                continue;
            }

            if (innerNode.getName() == 'BuyerEmail') {
                amazonOrder.BuyerEmail = innerNode.getText();
                continue;
            }

            if (innerNode.getName() == 'AmazonOrderId') {
                amazonOrder.AmazonOrderId = innerNode.getText();
                continue;
            }

            if (innerNode.getName() == 'LastUpdateDate') {
                amazonOrder.LastUpdateDate = innerNode.getText();
                continue;
            }

            if (innerNode.getName() == 'ShipServiceLevel') {
                amazonOrder.ShipServiceLevel = innerNode.getText();
                continue;
            }

            if (innerNode.getName() == 'NumberOfItemsShipped') {
                amazonOrder.NumberOfItemsShipped = Integer.valueOf( innerNode.getText() );
                continue;
            }

            if (innerNode.getName() == 'OrderStatus') {
                amazonOrder.OrderStatus = innerNode.getText();
                continue;
            }

            if (innerNode.getName() == 'SalesChannel') {
                amazonOrder.SalesChannel = innerNode.getText();
                continue;
            }

            if (innerNode.getName() == 'ShippedByAmazonTFM') {
                amazonOrder.ShippedByAmazonTFM = Boolean.valueOf( innerNode.getText() );
                continue;
            }

            if (innerNode.getName() == 'IsBusinessOrder') {
                amazonOrder.IsBusinessOrder = Boolean.valueOf( innerNode.getText() );
                continue;
            }

            if (innerNode.getName() == 'LatestDeliveryDate') {
                amazonOrder.LatestDeliveryDate = Datetime.valueOf( innerNode.getText().replace('T', ' ').removeEnd('Z') );
                continue;
            }

            if (innerNode.getName() == 'NumberOfItemsUnshipped') {
                amazonOrder.NumberOfItemsUnshipped = Integer.valueOf( innerNode.getText() );
                continue;
            }

            if (innerNode.getName() == 'BuyerName') {
                amazonOrder.BuyerName = innerNode.getText();
                continue;
            }

            if (innerNode.getName() == 'EarliestDeliveryDate') {
                amazonOrder.EarliestDeliveryDate = Datetime.valueOf( innerNode.getText().replace('T', ' ').removeEnd('Z') );
                continue;
            }

            if (innerNode.getName() == 'OrderTotal') {
                for (Dom.XmlNode inNode : innerNode.getChildElements()) {
                    if (inNode.getName() == 'CurrencyCode') {
                        amazonOrder.CurrencyCode = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'Amount') {
                        amazonOrder.Amount = Decimal.valueOf( inNode.getText() );
                        continue;
                    }
                }
            }

            if (innerNode.getName() == 'IsPremiumOrder') {
                amazonOrder.IsPremiumOrder = Boolean.valueOf( innerNode.getText() );
                continue;
            }

            if (innerNode.getName() == 'EarliestShipDate') {
                amazonOrder.EarliestShipDate = Datetime.valueOf( innerNode.getText().replace('T', ' ').removeEnd('Z') );
                continue;
            }

            if (innerNode.getName() == 'MarketplaceId') {
                amazonOrder.MarketplaceId = innerNode.getText();
                continue;
            }

            if (innerNode.getName() == 'FulfillmentChannel') {
                amazonOrder.FulfillmentChannel = innerNode.getText();
                continue;
            }

            if (innerNode.getName() == 'PaymentMethod') {
                amazonOrder.PaymentMethod = innerNode.getText();
                continue;
            }

            if (innerNode.getName() == 'ShippingAddress') {
                for (Dom.XmlNode inNode : innerNode.getChildElements()) {
                    if (inNode.getName() == 'StateOrRegion') {
                        amazonOrder.StateOrRegion = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'City') {
                        amazonOrder.City = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'Phone') {
                        amazonOrder.Phone = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'CountryCode') {
                        amazonOrder.CountryCode = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'PostalCode') {
                        amazonOrder.PostalCode = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'Name') {
                        amazonOrder.Name = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'AddressLine1') {
                        amazonOrder.AddressLine1 = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'AddressLine2') {
                        amazonOrder.AddressLine2 = inNode.getText();
                        continue;
                    }
                }
            }

            if (innerNode.getName() == 'IsPrime') {
                amazonOrder.IsPrime = Boolean.valueOf( innerNode.getText() );
                continue;
            }

            if (innerNode.getName() == 'ShipmentServiceLevelCategory') {
                amazonOrder.ShipmentServiceLevelCategory = innerNode.getText();
                continue;
            }

        }

        return amazonOrder;
    }

    public List<Dom.XmlNode> getXMLOrderItems(String xmlInput) {

        List<Dom.XmlNode> ordersItems = new List<Dom.XmlNode>();

        Dom.Document doc = new Dom.Document();
        doc.load(xmlInput);

        Dom.XmlNode rootElement = doc.getRootElement();

        for(Dom.XmlNode node : rootElement.getChildElements()) {
            if(node.getName() == 'ListOrderItemsResult') {
                rootElement = node;
            }
        }

        for (Dom.XmlNode node : rootElement.getChildElements()) {
            if(node.getName() == 'OrderItems') {
                rootElement = node;
            }
        }

        for(Dom.XmlNode node : rootElement.getChildElements()) {
            if(node.getName() == 'OrderItem') {
                ordersItems.add(node);
            }
        }
        return ordersItems;
    }

    public AmazonOrderItem processOrderItem(Dom.XmlNode node) {
        AmazonOrderItem orderItem = new AmazonOrderItem();

        for (Dom.XmlNode innerNode :node.getChildElements()) {
            if(innerNode.getName() == 'QuantityOrdered') {
                orderItem.QuantityOrdered = Integer.valueOf( innerNode.getText() );
                continue;
            }

            if(innerNode.getName() == 'ShippingTax') {
                for (Dom.XmlNode inNode : innerNode.getChildElements()) {
                    if (inNode.getName() == 'CurrencyCode') {
                        orderItem.ShippingTaxCurrencyCode = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'Amount') {
                        orderItem.ShippingTaxAmount = Decimal.valueOf( inNode.getText() );
                        continue;
                    }
                }
            }

            if(innerNode.getName() == 'PromotionDiscount') {
                for (Dom.XmlNode inNode : innerNode.getChildElements()) {
                    if (inNode.getName() == 'CurrencyCode') {
                        orderItem.PromotionDiscountCurrencyCode = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'Amount') {
                        orderItem.PromotionDiscountAmount = Decimal.valueOf( inNode.getText() );
                        continue;
                    }
                }
            }


            if(innerNode.getName() == 'ConditionId') {
                orderItem.ConditionId = innerNode.getText();
                continue;
            }

            if(innerNode.getName() == 'ASIN') {
                orderItem.ASIN = innerNode.getText();
                continue;
            }

            if(innerNode.getName() == 'SellerSKU') {
                orderItem.SellerSKU = innerNode.getText();
                continue;
            }

            if(innerNode.getName() == 'OrderItemId') {
                orderItem.OrderItemId = innerNode.getText();
                continue;
            }

            if(innerNode.getName() == 'GiftWrapTax') {
                for (Dom.XmlNode inNode : innerNode.getChildElements()) {
                    if (inNode.getName() == 'CurrencyCode') {
                        orderItem.GiftWrapTaxCurrencyCode = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'Amount') {
                        orderItem.GiftWrapTaxAmount = Decimal.valueOf( inNode.getText() );
                        continue;
                    }
                }
            }

            if(innerNode.getName() == 'QuantityShipped') {
                orderItem.QuantityShipped = Integer.valueOf( innerNode.getText() );
                continue;
            }

            if(innerNode.getName() == 'ShippingPrice') {
                for (Dom.XmlNode inNode : innerNode.getChildElements()) {
                    if (inNode.getName() == 'CurrencyCode') {
                        orderItem.ShippingPriceCurrencyCode = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'Amount') {
                        orderItem.ShippingPriceAmount = Decimal.valueOf( inNode.getText() );
                        continue;
                    }
                }
            }

            if(innerNode.getName() == 'GiftWrapPrice') {
                for (Dom.XmlNode inNode : innerNode.getChildElements()) {
                    if (inNode.getName() == 'CurrencyCode') {
                        orderItem.GiftWrapPriceCurrencyCode = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'Amount') {
                        orderItem.GiftWrapPriceAmount = Decimal.valueOf( inNode.getText() );
                        continue;
                    }
                }
            }

            if(innerNode.getName() == 'ConditionSubtypeId') {
                orderItem.ConditionSubtypeId = innerNode.getText();
                continue;
            }

            if(innerNode.getName() == 'ItemPrice') {
                for (Dom.XmlNode inNode : innerNode.getChildElements()) {
                    if (inNode.getName() == 'CurrencyCode') {
                        orderItem.ItemPriceCurrencyCode = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'Amount') {
                        orderItem.ItemPriceAmount = Decimal.valueOf( inNode.getText() );
                        continue;
                    }
                }
            }

            if(innerNode.getName() == 'ItemTax') {
                for (Dom.XmlNode inNode : innerNode.getChildElements()) {
                    if (inNode.getName() == 'CurrencyCode') {
                        orderItem.ItemTaxCurrencyCode = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'Amount') {
                        orderItem.ItemTaxAmount = Decimal.valueOf( inNode.getText() );
                        continue;
                    }
                }
            }

            if(innerNode.getName() == 'ShippingDiscount') {
                for (Dom.XmlNode inNode : innerNode.getChildElements()) {
                    if (inNode.getName() == 'CurrencyCode') {
                        orderItem.ShippingDiscountCurrencyCode = inNode.getText();
                        continue;
                    }
                    if (inNode.getName() == 'Amount') {
                        orderItem.ShippingDiscountAmount = Decimal.valueOf( inNode.getText() );
                        continue;
                    }
                }
            }
        }

        return orderItem;
    }

    public class AmazonOrder {
        public Datetime LatestShipDate {get; set;}
        public String OrderType {get; set;}
        public Datetime PurchaseDate {get; set;}
        public String BuyerEmail {get; set;}
        public String AmazonOrderId {get; set;}
        public String LastUpdateDate {get; set;}
        public String ShipServiceLevel {get; set;}
        public Integer NumberOfItemsShipped {get; set;}
        public String OrderStatus {get; set;}
        public String SalesChannel {get; set;}
        public Boolean ShippedByAmazonTFM {get; set;}
        public Boolean IsBusinessOrder {get; set;}
        public Datetime LatestDeliveryDate {get; set;}
        public Integer NumberOfItemsUnshipped {get; set;}
        public String BuyerName {get; set;}
        public Datetime EarliestDeliveryDate {get; set;}

        //Amount details
        public String CurrencyCode {get; set;}
        public Decimal Amount {get; set;}

        public Boolean IsPremiumOrder {get; set;}
        public Datetime EarliestShipDate {get; set;}
        public String MarketplaceId {get; set;}
        public String FulfillmentChannel {get; set;}
        public String PaymentMethod {get; set;}

        //Shipment details
        public String StateOrRegion {get; set;}
        public String City {get; set;}
        public String Phone {get; set;}
        public String CountryCode {get; set;}
        public String PostalCode {get; set;}
        public String Name {get; set;}
        public String AddressLine1 {get; set;}
        public String AddressLine2 {get; set;}

        public Boolean IsPrime {get; set;}
        public String ShipmentServiceLevelCategory {get; set;}
    }

    public class AmazonOrderItem {
        public Integer QuantityOrdered {get; set;}
        public String Title {get; set;}
        public String ShippingTaxCurrencyCode {get; set;}
        public Decimal ShippingTaxAmount {get; set;}

        public String PromotionDiscountCurrencyCode {get; set;}
        public Decimal PromotionDiscountAmount {get; set;}

        public String ConditionId {get; set;}
        public String ASIN {get; set;}
        public String SellerSKU {get; set;}
        public String OrderItemId {get; set;}

        public String GiftWrapTaxCurrencyCode {get; set;}
        public Decimal GiftWrapTaxAmount {get; set;}

        public Integer QuantityShipped {get; set;}
        public String ShippingPriceCurrencyCode {get; set;}
        public Decimal ShippingPriceAmount {get; set;}

        public String GiftWrapPriceCurrencyCode {get; set;}
        public Decimal GiftWrapPriceAmount {get; set;}

        public String ConditionSubtypeId {get; set;}

        public String ItemPriceCurrencyCode {get; set;}
        public Decimal ItemPriceAmount {get; set;}

        public String ItemTaxCurrencyCode {get; set;}
        public Decimal ItemTaxAmount {get; set;}

        public String ShippingDiscountCurrencyCode {get; set;}
        public Decimal ShippingDiscountAmount {get; set;}

    }

    public class PrivilegesException extends Exception {}
}