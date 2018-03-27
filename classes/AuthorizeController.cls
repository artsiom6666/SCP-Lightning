public with sharing class AuthorizeController {

	public Order__c order { get; set; }

	public String cardNumber { get; set; }
	public String cardExpirationYear { get; set; }
	public String cardExpirationMonth { get; set; }
	public String ccv { get; set; }
	public List<SelectOption> years { get; set; }

	public AuthorizeController (ApexPages.StandardController stdController) {
		if (Schema.sObjectType.Order__c.isAccessible()) {
			order = [
				SELECT Id, Amount_To_Charge__c
				FROM Order__c
				WHERE Id =: (Id)stdController.getId()
				LIMIT 1
			];
			this.years = getYearsValue();
		}
	}

	public static List<SelectOption> getYearsValue() {
		Integer year = Date.today().year();
		List<SelectOption> years = new List<SelectOption>();
		for (Integer i = 0; i < 7; i++) {
			years.add(new SelectOption(String.valueOf(year + i), String.valueOf(year + i)));
		}
		return years;
	}

	public PageReference authorizeOrderNow() {
		if (String.isBlank(cardNumber) || String.isBlank(ccv)) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You must enter a values in required fields'));
			return null;
		}
		else if (order.Amount_To_Charge__c < 1) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'The Amount must not be less than 1 Dollar'));
			return null;
		} else {
			Map<String,Object> creditCard = new Map<String,Object>{
				'CardNumber' => cardNumber,
				'CardCCV' => ccv,
				'CardExpirationMonth' => cardExpirationMonth,
				'CardExpirationYear' => cardExpirationYear
			};
			Map<String,Object> result = PaymentProcessor.doPayment(
				new Map<String,Object>{
					'Method' => 'Authorization',
					'OrderId' => order.Id,
					'Amount' => order.Amount_To_Charge__c,
					'CreditCard' => creditCard
				}
			);
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, (String)result.get('Status')));
			return cancel((Id)result.get('Transaction'));
		}
	}

	public PageReference cancel(Id transactionId) {
		PageReference redirectPage = new PageReference('/' + transactionId);
		redirectPage.setRedirect(true);
		return redirectPage;
	}

}