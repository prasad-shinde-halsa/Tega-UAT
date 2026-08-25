({
	init: function (component) {
        var userId = $A.get("$SObjectType.CurrentUser.Id");
 		
        var resultdata = [];
        // Fetch User's Company
        var action = component.get("c.getCompanyFromUserBranch");
        action.setParams({ 
            currentUserId : userId
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                resultdata = response.getReturnValue();
                var returnOptions = [];
                if(resultdata){
                    resultdata.forEach(ele =>{
                        returnOptions.push({label:ele , value:ele});
                	}); 
            	}
                console.log(JSON.stringify(returnOptions));
                component.set("v.companyList", returnOptions);
        	}
        });
        $A.enqueueAction(action);
       },
    
    handleChange1: function (component, event) {
        // This will contain the string of the "value" attribute of the selected option
        var selectedCompany = event.getParam("value");
        console.log('selected company : ',selectedCompany);
        
        
        var resultdata = [];
        // Fetch User's Branch
        var action = component.get("c.getBranchFromSelectedCompany");
        action.setParams({ 
            selectedCompany : selectedCompany
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                resultdata = response.getReturnValue();
                var returnOptions = [];
                if(resultdata){
                    resultdata.forEach(ele =>{
                        returnOptions.push({label:ele , value:ele});
                	}); 
            	}
                console.log(JSON.stringify(returnOptions));
                component.set("v.branchList", returnOptions);
                component.set("v.isCompanyFilled", false);
            	component.set("v.companyValue",selectedCompany);
        	}
        });
        $A.enqueueAction(action);
        
        var selectedBranch = component.get("v.branchValue");
        var selectedTenure = component.get("v.tenureValue");
        
        
        if(selectedBranch != '' && selectedCompany != '' && selectedTenure != ''){
    		component.set("v.isAllFilled", true);        
        }else{
            component.set("v.isAllFilled", false);   
        }
    },
    
    handleChange2 : function(component,event){
    	var selectedBranch = event.getParam("value");
        component.set("v.branchValue",selectedBranch);
        
        var selectedCompany = component.get("v.companyValue");
        var selectedTenure = component.get("v.tenureValue");
        
        if(selectedBranch != '' && selectedCompany != '' && selectedTenure != ''){
    		component.set("v.isAllFilled", true);        
        }else{
            component.set("v.isAllFilled", false);   
        }
    },
    handleChange3 : function(component,event){
    	var selectedBranch = component.get("v.branchValue");
        var selectedCompany  = component.get("v.companyValue");
        var selectedTenure = event.getParam("value");
        if(selectedBranch != '' && selectedCompany != '' && selectedTenure != ''){
    		component.set("v.isAllFilled", true);        
        }else{
            component.set("v.isAllFilled", false);   
        }
        component.set("v.tenureValue",selectedTenure);
    },
    
    handleClick : function(component,event){
        console.log('Save Button Pressed');
        var company = component.get("v.companyValue");
        console.log('company',company);
        var branch = component.get("v.branchValue");
        console.log('branch',branch);
        var tenure = component.get("v.tenureValue");
        console.log('tenure',tenure);
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        console.log('userId',userId);
        var action = component.get("c.createUserBudgetRecord");
        action.setParams({ 
            selectedCompany : company,
            selectedBranch : branch,
            selectedTenure : tenure,
            currentUserId : userId
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('state',state);
                var resultId = response.getReturnValue();
                console.log('resultId',resultId);
                if(resultId){
                    console.log('calling toast');
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": resultId,
                        "slideDevName": "related"
                    });
                    navEvt.fire();
                }
            }
        });
        $A.enqueueAction(action);
    },
})