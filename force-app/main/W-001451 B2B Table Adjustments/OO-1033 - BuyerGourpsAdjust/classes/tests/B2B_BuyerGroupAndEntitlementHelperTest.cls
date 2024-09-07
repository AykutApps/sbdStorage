@isTest
public with sharing class B2B_BuyerGroupAndEntitlementHelperTest {
    @TestSetup
    public static void makeData() {
        Product2 p = TestData_Product2.createSingleProduct();
        TestData_Order.createRetailPricebookEntries(new List<Product2>{ p }, true);
        Account a = TestData_Account.createDealerAccount();

        BuyerAccount buyerAccount = new BuyerAccount();
        buyerAccount.BuyerId = a.Id;
        buyerAccount.Name = 'Test Buyer)';
        buyerAccount.IsActive = true;
        insert buyerAccount;

        Pricebook2 pb = [SELECT Id FROM Pricebook2 LIMIT 1];
        pb.External_Key__c = 'ek1';
        pb.CSP_Number__c = 1;
        pb.CSP_Start_Date__c = Date.today().addDays(-1);
        pb.CSP_End_Date__c = Date.today().addDays(1);
        pb.CSP_Number__c = 1;
        update pb;

        List<Pricebook2> pbs = new List<PriceBook2>{ pb };

        // adjust Price Book Entiries for testing
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Pricebook2.Id =:pb.Id LIMIT 1];
        pbe.External_Key__c = 'ek1';
        pbe.ERP_Valid_From__c = Date.today().addDays(-1);
        pbe.ERP_Valid_To__c = Date.today().addDays(1);
        update pbe;

        // create Account Group Mappings
        TestData_Order.createAccountPriceBookMappings(a.Entity_Id__c, pbs, true);

        Account_Pricebook_Mapping__c apm = [
            SELECT Id, External_Key__c, ERP_Start_Date__c, ERP_End_Date__c, Account__c, Account__r.Entity_ID__c, Price_Book__r.External_Key__c
            FROM Account_Pricebook_Mapping__c
            LIMIT 1
        ];
        apm.External_Key__c = 'ek1';
        apm.ERP_Start_Date__c = Date.today().addDays(-1);
        apm.ERP_End_Date__c = Date.today().addDays(1);
        update apm;

        // insert Buyer Group
        BuyerGroup buyerGroup = new BuyerGroup();
        buyerGroup.Name = 'Test Buyer Group';
        buyerGroup.External_Key__c = 'ek1';
        insert buyerGroup;

        insert new CommerceEntitlementPolicy(Name = 'name1', External_Key__c = 'ek1');
    }

    @isTest
    public static void testAdjustBuyerGroupMember() {
        Set<Id> accountPricebookMappingIds = new Map<Id, Account_Pricebook_Mapping__c>([SELECT Id FROM Account_Pricebook_Mapping__c]).keySet();
        B2B_BuyerGroupAndEntitlementHelper.adjustBuyerGroupMember(accountPricebookMappingIds);
        System.assertEquals(1, [SELECT Id FROM BuyerGroupMember].size());
    }

    @isTest
    public static void testAdjustBuyerGroupMemberWithDeletion() {
        Account_Pricebook_Mapping__c apm = [SELECT Id FROM Account_Pricebook_Mapping__c LIMIT 1];
        B2B_BuyerGroupAndEntitlementHelper.adjustBuyerGroupMember(new Set<Id>{apm.Id});
        System.assertEquals(1, [SELECT Id FROM BuyerGroupMember].size());

        apm.ERP_Start_Date__c = Date.today().addDays(-3);
        apm.ERP_End_Date__c = Date.today().addDays(-1);
        update apm;

        B2B_BuyerGroupAndEntitlementHelper.adjustBuyerGroupMember(new Set<Id>{apm.Id});
        System.assertEquals(0, [SELECT Id FROM BuyerGroupMember].size());
    }

    @isTest
    public static void testAdjustCommerceEntitlementBuyerGroup() {
        Set<Id> pbIds = new Map<Id, Pricebook2>([SELECT Id FROM Pricebook2]).keySet();
        B2B_BuyerGroupAndEntitlementHelper.adjustCommerceEntitlementBuyerGroup(pbIds);
        System.assertEquals(1, [SELECT Id FROM CommerceEntitlementBuyerGroup].size());
    }

    @isTest
    public static void testAdjustCommerceEntitlementProduct() {
        Set<Id> pbeIds = new Map<Id, PricebookEntry>([SELECT Id FROM PricebookEntry]).keySet();
        B2B_BuyerGroupAndEntitlementHelper.adjustCommerceEntitlementProduct(pbeIds);
        System.assertEquals(1, [SELECT Id FROM CommerceEntitlementProduct].size());
    }
}