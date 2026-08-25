({
    doInit: function(component, event, helper) {
        // Pre-fetch logo URL from org static resource
        // Replace 'CompanyLogo' with your actual Static Resource name
        var logoUrl = '/resource/CompanyLogo';
        component.set('v.logoUrl', logoUrl);
    },

    openModal: function(component, event, helper) {
        component.set('v.showModal', true);
        component.set('v.isLoading', true);
        helper.loadData(component, event, helper);
    },

    closeModal: function(component, event, helper) {
        component.set('v.showModal', false);
        component.set('v.lineItems', []);
        component.set('v.headers', []);
        component.set('v.quoteData', null);
    },

    printDoc: function(component, event, helper) {
        window.print();
    }
})