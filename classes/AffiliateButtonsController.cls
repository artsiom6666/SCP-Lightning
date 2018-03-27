public with sharing class AffiliateButtonsController {

	public Account acc {get; set;}
	
	public AffiliateButtonsController(ApexPages.StandardController stdController) {
		if (Schema.sObjectType.Account.isAccessible()) {
			acc = (Account)stdController.getRecord();
		}
		else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Insufficient priveleges.'));
		}
	}

	public void postToAffiliateAPI() {
		try {
			HttpRequest req = new HttpRequest();
			req.setEndpoint('callout:TouchCRBase__AffiliateSiteHeroku');
			req.setMethod('POST');
			Map<String, String> accountData = new Map<String, String>{
				'accountName' => (acc.FirstName + ' ' + acc.LastName),
				'accountEmail' => acc.PersonEmail,
				'affiliateApproval' => acc.Affiliate_Approval__c
			};
			req.setHeader('Content-Type', 'application/json');
			req.setHeader('Origin', 'Salesforce');

			String requestBody = JSON.serialize(accountData);
			req.setBody(requestBody);
			Http http = new Http();
			if(!Test.isRunningTest()){
				HTTPResponse res = http.send(req);
			}
		} catch (Exception e) {}	
	}

	public PageReference setAffiliateFrozen() {
		acc = [SELECT Id, FirstName, LastName, Affiliate_Approval__c, Company_Name__c, PersonEmail FROM Account WHERE id=:acc.id LIMIT 1];
		acc.Affiliate_Approval__c = 'Frozen';
		postToAffiliateAPI();
		try {
			update acc;
			/*SFDCAccessController.UpdateWithoutSharing (
				acc,
				'AffiliateButtonsController.cls [setAffiliateFrozen]',
				new List<Schema.DescribeFieldResult> {
					Account.Affiliate_Approval__c.getDescribe()
				}
			);
		}
		catch (Exception e) {throw new SFDCAccessControlException();}*/
		} catch (Exception e) {}

		PageReference redirectPage = new PageReference('/'+acc.Id);
		redirectPage.setRedirect(true);
		return redirectPage;
	}

	public PageReference setAffiliateUnFrozen() {
		acc = [SELECT Id, FirstName, LastName, Affiliate_Approval__c, Company_Name__c, PersonEmail FROM Account WHERE id=:acc.id LIMIT 1];
		acc.Affiliate_Approval__c = 'Approved';
		postToAffiliateAPI();
		try {
			update acc;
			/*SFDCAccessController.UpdateWithoutSharing (
				acc,
				'AffiliateButtonsController.cls [setAffiliateUnFrozen]',
				new List<Schema.DescribeFieldResult> {
					Account.Affiliate_Approval__c.getDescribe()
				}
			);
		}
		catch (Exception e) {throw new SFDCAccessControlException();}*/
		} catch (Exception e) {}

		PageReference redirectPage = new PageReference('/'+acc.Id);
		redirectPage.setRedirect(true);
		return redirectPage;
	}

	public PageReference approveAccountToAffiliate() {
		acc = [SELECT Id, FirstName, LastName, Affiliate_Approval__c, Company_Name__c, PersonEmail FROM Account WHERE id=:acc.id LIMIT 1];
		if (acc.Affiliate_Approval__c == 'Waiting for Approval' && acc.Company_Name__c != null) {
			RecordType recType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Affiliate_Account' AND SobjectType = 'Account' LIMIT 1];
			acc.RecordTypeId = recType.Id;
			acc.Affiliate_Approval__c = 'Approved';
			postToAffiliateAPI();
			try {
				update acc;
				/*SFDCAccessController.UpdateWithoutSharing (
					acc,
					'AffiliateButtonsController.cls [approveAccountToAffiliate]',
					new List<Schema.DescribeFieldResult> {
						Account.Affiliate_Approval__c.getDescribe(),
						Account.RecordTypeId.getDescribe()
					}
				);
			}
			catch (Exception e) {throw new SFDCAccessControlException();}*/
			} catch (Exception e) {}
		}

		PageReference redirectPage = new PageReference('/'+acc.Id);
		redirectPage.setRedirect(true);
		return redirectPage;
	}

}