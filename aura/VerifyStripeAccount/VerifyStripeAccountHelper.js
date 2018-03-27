({
	verifyStripeAccount : function(component) {
        component.set('v.showSpinner', true);
        var recordId = component.get('v.recordId');
        
		var action = component.get('c.verifyStripeAccount');
        action.setParams({
            'itemId': recordId
        });
        action.setCallback(this, function(response) {
            this.responseHandler(component, response);
        });
        $A.enqueueAction(action);
	},
    responseHandler : function(component, response) {
        var state = response.getState();
        component.set('v.showSpinner', false);

        if (component.isValid() && state === 'SUCCESS') {
            if (response.getReturnValue().indexOf('error') > -1) {
                component.set('v.showErrorMessage', true);
                component.set('v.responseMessage', response.getReturnValue());
                return;
            }
            response = JSON.parse(response.getReturnValue());

            if (response.original.verification.fields_needed &&
                response.original.verification.fields_needed.length > 0) {
                var requiredFields = 'Please fill out next fields: ';
                response.original.verification.fields_needed.forEach(function (currentValue) {
                    requiredFields += currentValue;
                });

                component.set('v.showErrorMessage', true);
                component.set('v.responseMessage', requiredFields);
            }
            else {
                component.set('v.showSuccessMessage', true);
                component.set('v.responseMessage', 'Stripe Account has been verified!');
            }
        }
        else {
            component.set('v.showErrorMessage', true);
            component.set('v.responseMessage', response.getReturnValue());
        }
    }
})