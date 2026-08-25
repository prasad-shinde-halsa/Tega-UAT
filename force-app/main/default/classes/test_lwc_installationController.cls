@isTest
public class test_lwc_installationController {
        @isTest
    static void testGetInstallationData() {
        // Create test data
        Account customer = new Account(Name = 'Test Customer');
        insert customer;
        
        Customer_Equipments__c equipment = new 	Customer_Equipments__c(Customer__c=customer.Id,Equipment_Type__c='Ball Mill');

        Part_List__c partList = new Part_List__c(Name = 'Test Part List',Customer__c=customer.Id);
        insert partList;

        Order salesOrder = new Order(Name = 'Test SO', Status = 'Draft', AccountId = customer.Id,EffectiveDate=Date.parse('12/15/24'));
        insert salesOrder;

        Installation__c installation = new Installation__c(
            Customer__c = customer.Id,
            Part_List__c = partList.Id,
            SO_Number__c = salesOrder.Id,
            Equipment_Installed_At__c=equipment.Id,
            Type__c='Installation'
        );
        insert installation;

        Test.startTest();
        Installation__c result = lwc_installationController.getInstallationData(installation.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(installation.Id, result.Id);
    }

    @isTest
    static void testGetSoNumber() {
        Account customer = new Account(Name = 'Test Customer');
        insert customer;
        
        Order salesOrder = new Order(Name = 'Test SO', Status = 'Draft',AccountId=customer.Id,EffectiveDate=Date.today());
        insert salesOrder;
        
        Customer_Equipments__c equipment = new 	Customer_Equipments__c(Customer__c=customer.Id,Equipment_Type__c='Ball Mill');

        Installation__c installation = new Installation__c(
            Customer__c = customer.Id,
            SO_Number__c = salesOrder.Id,
            //Equipment_Installed_At__c=equipment.Id,
            Type__c='Installation'
        );
        insert installation;

        Test.startTest();
        String soNumber = lwc_installationController.getSoNumber(installation.Id);
        Test.stopTest();

        System.assertNotEquals(null, soNumber);
        System.assertEquals(salesOrder.Id, soNumber);
    }

    @isTest
    static void testGetSoDescriptions() {
        Account customer = new Account(Name = 'Test Customer');
        insert customer;
        
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        // Execute an update DML on the Pricebook2 record to make IsStandard true
        update standardPricebook;
        standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        // It should return true
        System.assertEquals(true, standardPricebook.IsStandard);
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.id,
            Product2Id = product.Id,
            UnitPrice = 10000, 
            IsActive = true
        );
        insert pbe;
        
        pbe = [SELECT Id, Pricebook2.IsStandard FROM PricebookEntry];
        // It should return true
        System.assertEquals(true, pbe.Pricebook2.IsStandard);
        
        Pricebook2 customPB = new Pricebook2(Name = 'Custom Pricebook', isActive = true);
        insert customPB;
        
        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPB.Id, 
            Product2Id = product.Id,
            UnitPrice = 12000, 
            IsActive = true
        );
        insert customPrice;
        
        Order salesOrder = new Order(
            Name = 'Test SO', 
            Status = 'Draft',
            AccountId = customer.Id,
            EffectiveDate = Date.today(),
            PriceBook2Id = Test.getStandardPricebookId()
        );
        insert salesOrder;
        
        OrderItem orderItem = new OrderItem(
            OrderId = salesOrder.Id,
            Product2Id = product.Id,
            Quantity = 2,
            ListPrice = 10000.00, // Match PricebookEntry UnitPrice
            UnitPrice = 10000.00,
            PricebookEntryId = pbe.Id
        );
        insert orderItem;
        
        Test.startTest();
        List<Map<String, String>> descriptions = lwc_installationController.getSoDescriptions(salesOrder.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, descriptions);
        System.assertEquals(1, descriptions.size());
        System.assertEquals(product.Name, descriptions[0].get('ItemCode'));
    }


    @isTest
    static void testGetPartDescriptions() {
        Account customer = new Account(Name = 'Test Customer');
        insert customer;
        
        Part_List__c partList = new Part_List__c(Name = 'Test Part List',Customer__c=customer.Id);
        insert partList;

        Product2 product = new Product2(Name = 'Test Product', Part_List__c = partList.Id, IsActive = true);
        insert product;

        L2_L3_Product__c l3Product = new L2_L3_Product__c(
            Part_List__c = partList.Id,
            Product_L2__c = product.Id,
            Quantity__c = 5
        );
        insert l3Product;

        Test.startTest();
        List<Map<String, String>> descriptions = lwc_installationController.getPartDescriptions(partList.Id);
        Test.stopTest();

        System.assertNotEquals(null, descriptions);
        //System.assertTrue(descriptions.size() > 0);
    }

    @isTest
    static void testSaveInstallationLineItems() {
        Account customer = new Account(Name = 'Test Customer');
        insert customer;
        
       // Customer_Equipments__c equipment = new 	Customer_Equipments__c(Customer__c='001C500000BkBuCIAV',Equipment_Type__c='Ball Mill');

        Part_List__c partList = new Part_List__c(Name = 'Test Part List',Customer__c='001C500000BkBuCIAV');
        insert partList;
        Installation__c installation = new Installation__c(Name = 'Test Installation',Customer__c='001C500000BkBuCIAV');
        insert installation;

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
        Map<String, Object> lineItem = new Map<String, Object>();
        lineItem.put('Installation__c', installation.Id);
        lineItem.put('Customer__c', customer.Id);
        lineItem.put('Item_Description__c', 'Test Item Description');
        lineItem.put('Installed_Quantity__c', '2');
        lineItem.put('Problem__c', false);
        lineItems.add(lineItem);

        Test.startTest();
        lwc_installationController.saveInstallationLineItems(lineItems);
        Test.stopTest();

        List<Installation_Line_Items__c> savedItems = [SELECT Id FROM Installation_Line_Items__c WHERE Installation__c = :installation.Id];
        System.assertEquals(1, savedItems.size());
    }
    
    @isTest
    static void testSaveSoInstallationLineItems() {
        Account customer = new Account(Name = 'Test Customer');
        insert customer;
        
        
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        // Execute an update DML on the Pricebook2 record to make IsStandard true
        update standardPricebook;
        standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        // It should return true
        System.assertEquals(true, standardPricebook.IsStandard);
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.id,
            Product2Id = product.Id,
            UnitPrice = 10000, 
            IsActive = true
        );
        insert pbe;
        
        pbe = [SELECT Id, Pricebook2.IsStandard FROM PricebookEntry];
        // It should return true
        System.assertEquals(true, pbe.Pricebook2.IsStandard);
        
        Pricebook2 customPB = new Pricebook2(Name = 'Custom Pricebook', isActive = true);
        insert customPB;
        
        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPB.Id, 
            Product2Id = product.Id,
            UnitPrice = 12000, 
            IsActive = true
        );
        insert customPrice;
        
        Order salesOrder = new Order(
            Name = 'Test SO', 
            Status = 'Draft',
            AccountId = customer.Id,
            EffectiveDate = Date.today(),
            PriceBook2Id = Test.getStandardPricebookId()
        );
        insert salesOrder;
        
        OrderItem orderItem = new OrderItem(
            OrderId = salesOrder.Id,
            Product2Id = product.Id,
            Quantity = 2,
            ListPrice = 10000.00, // Match PricebookEntry UnitPrice
            UnitPrice = 10000.00,
            PricebookEntryId = pbe.Id
        );
        insert orderItem;
        
        Installation__c installation = new Installation__c(Name = 'Test Installation',Customer__c='001C500000BkBuCIAV');
        insert installation;
        
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
        Map<String, Object> lineItem = new Map<String, Object>();
        lineItem.put('Installation__c', installation.Id);
        lineItem.put('Customer__c', customer.Id);
        lineItem.put('Item_Description__c', 'Test Item Description');
        lineItem.put('Installed_Quantity__c', '2');
        lineItem.put('Problem__c', false);
        lineItems.add(lineItem);

        Test.startTest();
        lwc_installationController.saveInstallationLineItemsSo(lineItems);
        Test.stopTest();

        List<Installation_Line_Items__c> savedItems = [SELECT Id FROM Installation_Line_Items__c WHERE Installation__c = :installation.Id];
        System.assertEquals(1, savedItems.size());
    }

    @isTest
    static void testCheckFilledData() {
        Installation__c installation = new Installation__c(Name = 'Test Installation',Customer__c='001C500000BkBuCIAV');
        insert installation;

        Test.startTest();
        Integer result = lwc_installationController.checkFilledData(installation.Id);
        Test.stopTest();

        System.assertEquals(4, result);
    }

}