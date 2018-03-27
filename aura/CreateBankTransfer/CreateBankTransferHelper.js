({
    getBalance : function(component, beforePayout) {
        component.set('v.showSpinner', true);
        var recordId = component.get('v.recordId');
        
		var action = component.get('c.getBalance');
        action.setParams({
            'itemId': recordId,
            'beforePayout': beforePayout
        });
        action.setCallback(this, function(response) {
            component.set('v.showSpinner', false);
            var state = response.getState();

            if (component.isValid() && state === 'SUCCESS') {
                if (response.getReturnValue().indexOf('Error') > -1) {
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
                    component.set('v.showBalance', (beforePayout) ? true : false);
                    component.set('v.pendingAmount', response.pendingAmount);
                    component.set('v.availableAmount', response.availableAmount);
                    component.set('v.transferAmount', response.transferAmount);
                }
            }
            else {
                component.set('v.showErrorMessage', true);
                component.set('v.responseMessage', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
	},
	createBankTransfer : function(component) {
        component.set('v.showSpinner', true);
        var recordId = component.get('v.recordId');
        var transferAmount = component.get('v.transferAmount');
        
		var action = component.get('c.createBankTransfer');
        action.setParams({
            'itemId': recordId,
            'transferAmount': transferAmount
        });
        action.setCallback(this, function(response) {
            this.responseHandler(component, response);
        });
        $A.enqueueAction(action);
	},
    responseHandler : function(component, response) {
        var state = response.getState();

        if (component.isValid() && state === 'SUCCESS') {
            response = JSON.parse(response.getReturnValue());
            if (response.error) {
                component.set('v.showErrorMessage', true);
                component.set('v.responseMessage', response.error);
            }
            else {
                this.getBalance(component, false);
                component.set('v.showBalance', false);
                component.set('v.showSuccessMessage', true);
                component.set('v.responseMessage', 'Transfer succeded!');
            }
        }
        else {
            component.set('v.showErrorMessage', true);
            component.set('v.responseMessage', response.getReturnValue());
        }

        component.set('v.showSpinner', false);
    }
})