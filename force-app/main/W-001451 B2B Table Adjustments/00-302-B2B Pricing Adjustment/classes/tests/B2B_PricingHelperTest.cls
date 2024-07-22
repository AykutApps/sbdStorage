@isTest
public with sharing class B2B_PricingHelperTest {
    @TestSetup
    public static void makeData() {
        Product2 productRecord = TestData_Product2.createSingleProduct();
        TestData_Order.createRetailPricebookEntries(new List<Product2>{ productRecord }, true);
    }

    @isTest
    public static void testInactivatePricebooks() {
        Pricebook2 pb = [SELECT Id, External_Key__c, CSP_End_Date__c, IsActive FROM Pricebook2 LIMIT 1];
        pb.External_Key__c = 'pb1';
        pb.CSP_End_Date__c = Date.today().addDays(-1);
        pb.IsActive = true;
        update pb;

        B2B_PricingHelper.inactivatePricebooks(new Set<Id>{ pb.Id });
        pb = [SELECT Id, External_Key__c, CSP_End_Date__c, IsActive FROM Pricebook2 LIMIT 1];
        System.assertEquals(false, pb.IsActive);
    }

    @isTest
    public static void testAdjustPricebookEntriesActivation1() {
        PricebookEntry pbe = [SELECT Id, ERP_Valid_To__c, IsActive, ERP_Future_From_Date__c FROM PricebookEntry LIMIT 1];
        pbe.ERP_Valid_To__c = Date.today().addDays(-1);
        pbe.IsActive = true;
        pbe.ERP_Future_Price__c = null;
        update pbe;

        B2B_PricingHelper.adjustPricebookEntriesActivation(new Set<Id>{ pbe.Id });
        pbe = [SELECT Id, ERP_Valid_To__c, IsActive, ERP_Future_From_Date__c FROM PricebookEntry LIMIT 1];
        System.assertEquals(false, pbe.IsActive);
    }

    @isTest
    public static void testAdjustPricebookEntriesActivation2() {
        PricebookEntry pbe = [SELECT Id, ERP_Valid_To__c, IsActive, ERP_Future_From_Date__c FROM PricebookEntry LIMIT 1];
        pbe.ERP_Valid_To__c = Date.today().addDays(-1);
        pbe.IsActive = false;
        pbe.ERP_Future_Price__c = 2;
        pbe.ERP_Future_From_Date__c = Date.today();
        update pbe;

        B2B_PricingHelper.adjustPricebookEntriesActivation(new Set<Id>{ pbe.Id });
        pbe = [SELECT Id, ERP_Valid_To__c, IsActive, ERP_Future_From_Date__c FROM PricebookEntry LIMIT 1];
        System.assertEquals(true, pbe.IsActive);
    }
}
