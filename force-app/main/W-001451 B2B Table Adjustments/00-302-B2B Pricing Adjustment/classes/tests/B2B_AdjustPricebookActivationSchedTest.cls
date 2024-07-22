@isTest
public with sharing class B2B_AdjustPricebookActivationSchedTest {
    @TestSetup
    public static void makeData() {
        Map<String, Product2> pMap = TestData_Product2.createProducts();
        TestData_Product2.createPricebooksForProducts(pMap);
    }

    @isTest
    public static void testB2B_AdjustPBEActivationSchedTest() {
        Pricebook2 pb = [SELECT Id, External_Key__c, CSP_End_Date__c, IsActive FROM Pricebook2 LIMIT 1];
        pb.External_Key__c = 'pb1';
        pb.CSP_End_Date__c = Date.today().addDays(-1);
        pb.IsActive = true;
        update pb;

        Test.startTest();
        B2B_AdjustPricebookActivationSched s = new B2B_AdjustPricebookActivationSched();
        s.execute(null);
        Test.stopTest();

        pb = [SELECT Id, External_Key__c, CSP_End_Date__c, IsActive FROM Pricebook2 WHERE Id = :pb.Id];
        System.assertEquals(false, pb.IsActive);
    }
}
