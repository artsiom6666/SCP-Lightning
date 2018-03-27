({
	init: function (component, event, helper) {
        helper.getBalance(component, true);
    },
    transfer: function (component, event, helper) {
        helper.createBankTransfer(component);
    },
})