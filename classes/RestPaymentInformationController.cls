public with sharing class RestPaymentInformationController {

    public static String setPaymentInformation(Map<String, String> generalData) {
        try{
            Id accountId = generalData.containsKey('accountId') ? Id.valueOf(generalData.get('accountId')) : null;
            Decimal num = generalData.containsKey('num') ? Decimal.valueOf(generalData.get('num')) : null;
            Integer ccv = generalData.containsKey('ccv') ? Integer.valueOf(generalData.get('ccv')) : null;
            Integer month = generalData.containsKey('month') ? Integer.valueOf(generalData.get('month')) : null;
            Integer year = generalData.containsKey('year') ? Integer.valueOf(generalData.get('year')) : null;
            //Validation of data
            if (accountId == null || num == null || String.valueOf(num).length() != 16 || ccv == null || String.valueOf(ccv).length() != 3 || 
                month == null || String.valueOf(month).length() > 2 || year == null || String.valueOf(year).length() != 4) { return JSON.serialize(new Map<String, String>{'status' => 'error', 'error' => 'invalid value'}); }
            //get last number
            String last = String.valueOf(num).right(4);
            
            //define a valid date
            Boolean isLastMonth = month == 12;
            Integer monthValidBy = isLastMonth ? 1 : month + 1;
            Integer yearValidBy = isLastMonth ? year + 1 : year;
            Date validBy = Date.newInstance(yearValidBy, monthValidBy, 1);
            //data for encryption
            RestPaymentInformationController.PaymentInformation pI = new RestPaymentInformationController.PaymentInformation();
            pI.num = String.valueOf(num); 
            pI.ccv = ccv; 
            pI.month = month; 
            pI.year = year;
            //if the card exists in the system, return it Id
            List<Payment_Information__c> paymentInformations = [
                SELECT Id, Information__c
                FROM Payment_Information__c
                WHERE Account__c = :accountId
                AND ValidBy__c = :validBy
                AND Number__c = :last
            ];
            
            for (Payment_Information__c item : paymentInformations) {
                String decrypte = TouchCRHelper.getDecrypted(item.Information__c);
                //data on Payment Information
                RestPaymentInformationController.PaymentInformation oldPaymentInformation = (RestPaymentInformationController.PaymentInformation)JSON.deserialize(decrypte, RestPaymentInformationController.PaymentInformation.class);
                //compare card data
                Boolean isOldPaymentInformation = oldPaymentInformation.num == pI.num;
                isOldPaymentInformation = oldPaymentInformation.ccv == pI.ccv && isOldPaymentInformation;
                isOldPaymentInformation = oldPaymentInformation.month == pI.month && isOldPaymentInformation;
                isOldPaymentInformation = oldPaymentInformation.year == pI.year && isOldPaymentInformation;
                //if the card already exists
                if (isOldPaymentInformation) { return JSON.serialize(new Map<String, String>{'status' => 'success', 'paymentInformation' => paymentInformations[0].Id}); }
            }
            
            //encrypt information
            String paymentInformationJSON = JSON.serialize(pI);
            String encode = TouchCRHelper.getEncoded(paymentInformationJSON);
            //add new payment
            Payment_Information__c newPaymentInformation = new Payment_Information__c(
                ValidBy__c = validBy, Information__c = encode, Number__c = last, Account__c = accountId
            );
            insert newPaymentInformation;
            return JSON.serialize(new Map<String, String>{'status' => 'success', 'paymentInformation' => newPaymentInformation.Id});
        } catch (Exception ex) {
            return JSON.serialize(new Map<String, String>{'status' => 'error', 'error' => ex.getMessage()});
        }
    }

    public static String getPaymentInformation(Map<String, String> generalData) {
        try{
            Id paymentInformationId = generalData.containsKey('paymentInformationId') ? Id.valueOf(generalData.get('paymentInformationId')) : null;
            if (paymentInformationId == null) { JSON.serialize(new Map<String, String>{'status' => 'error', 'error' => 'invalid value'}); }
            Payment_Information__c pI = [SELECT Id, Information__c FROM Payment_Information__c WHERE Id =: paymentInformationId LIMIT 1];
            if (pI == null) { JSON.serialize(new Map<String, String>{'status' => 'error', 'error' => 'not found'}); }
            //decrypt information
            String decrypte = TouchCRHelper.getDecrypted(pI.Information__c);
            //data on Payment Information
            RestPaymentInformationController.PaymentInformation paymentInformationJSON = (RestPaymentInformationController.PaymentInformation)JSON.deserialize(decrypte, RestPaymentInformationController.PaymentInformation.class);
            return JSON.serialize(new Map<String, Object>{'status' => 'success', 'information' => paymentInformationJSON});
        } catch (Exception ex) {
            return JSON.serialize(new Map<String, String>{'status' => 'error', 'error' => ex.getMessage()});
        }
    }

    public class PaymentInformation {
        public String num { get; set; }
        public Integer ccv { get; set; }
        public Integer month { get; set; }
        public Integer year { get; set; }

        public PaymentInformation() {}
    }

}