({
    handleConfirmDialogNo: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    offerUpdate: function(component, event, helper) {
        console.log('Called controller');
        helper.offerFinal(component, event, helper);
    },

    doInit: function(component, event, helper) {
        var action = component.get("c.customLabelItem");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == 'SUCCESS') {
                var result = response.getReturnValue();
                component.set("v.customLablVal", result);
            }
        });
        $A.enqueueAction(action);
    },

    offerFinal: function(component, event, helper) {
        var labelsAction = component.get("c.getErrorLabels");
        labelsAction.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var labels = response.getReturnValue();
                var offerId = component.get("v.recordId");
                var action = component.get("c.checkCurrencies");
                action.setParams({ quoteId: offerId });

                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var result = response.getReturnValue();
                        if (result === "MISSING") {
                            helper.showToast("Error", "Error", labels.missing);
                        } else if (result === "MISMATCH") {
                            helper.showToast("Error", "Error", labels.mismatch);
                        } else if (result === "DIV_MISSING") {
                            helper.showToast("Error", "Error", labels.divMissing);
                        } 
                        else if (result === "DIV_NOT_MATCHING") {
                            helper.showToast("Error", "Error", labels.divnotMatching);
                        } 
                        else if (result === "MATCH") {
                            helper.callFinalize(component, labels);
                        }
                    } else {
                        helper.showToast("Error", "Error", labels.genericError);
                    }
                });
                $A.enqueueAction(action);
            }
        });
        $A.enqueueAction(labelsAction);
    },

    callFinalize: function(component, labels) {
        var offerId = component.get("v.recordId");
        var action = component.get("c.finalOffer");
        action.setParams({ offerId: offerId });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                this.showToast("Success", "Success", labels.finalizeSuccess);
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            } else if (state === "ERROR") {
                var errors = response.getError();
                let validationMessagestart = errors[0].message.indexOf('VALIDATION_EXCEPTION');
                this.showToast("Error", "Error", errors[0].message.substring(validationMessagestart + 21, errors[0].message.length - 4));
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            }
        }.bind(this));
        $A.enqueueAction(action);
    },

    showToast: function(title, type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }
})