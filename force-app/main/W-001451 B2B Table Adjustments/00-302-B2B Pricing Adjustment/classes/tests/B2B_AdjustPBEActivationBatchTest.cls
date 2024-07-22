@isTest
public with sharing class B2B_AdjustPBEActivationBatchTest {
    @TestSetup
    public static void makeData() {
        Map<String, Product2> pMap = TestData_Product2.createProducts();
        TestData_Product2.createPricebooksForProducts(pMap);
    }

    @isTest
    public static void testB2B_AdjustPBEActivationBatch() {
        PricebookEntry pbe = [SELECT Id, ERP_Valid_To__c, IsActive, ERP_Future_From_Date__c FROM PricebookEntry LIMIT 1];
        pbe.ERP_Valid_To__c = Date.today().addDays(-1);
        pbe.IsActive = true;
        pbe.ERP_Future_Price__c = null;
        update pbe;

        Test.startTest();
        B2B_AdjustPBEActivationBatch b = new B2B_AdjustPBEActivationBatch();
        ID BatchProcessId = Database.executeBatch(b, 200);
        Test.stopTest();

        pbe = [SELECT Id, ERP_Valid_To__c, IsActive, ERP_Future_From_Date__c FROM PricebookEntry WHERE Id = :pbe.Id];
        System.assertEquals(false, pbe.IsActive);
    }
}