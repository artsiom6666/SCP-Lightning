({
	deleteStripeAccount : function(component) {
        component.set('v.showSpinner', true);
        var recordId = component.get('v.recordId');
        
		var action = component.get('c.deleteStripeAccount');
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
            if (response.getReturnValue().indexOf('no') > -1) {
                component.set('v.showErrorMessage', true);
                component.set('v.responseMessage', response.getReturnValue());
                return;
            }
            response = JSON.parse(response.getReturnValue());
            if (response.error) {
                component.set('v.showErrorMessage', true);
                component.set('v.responseMessage', response.error);
            }
            else {
                component.set('v.showSuccessMessage', true);
                component.set('v.responseMessage', 'Stripe Account has been deleted!');
            }
        }
        else {
            component.set('v.showErrorMessage', true);
            component.set('v.responseMessage', response.getReturnValue());
        }
    }
})