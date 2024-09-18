@isTest
public with sharing class B2B_ProductQuantityRuleBatchTest {
    @isTest
    public static void testProductQuantityRuleBatchTest() {
        B2B_ProductQuantityRuleHelper.createPurchaseQuantityRules();
        TestData_Product2.createProducts();

        List<Product2> prs = [SELECT Id,Package_Quantity__c FROM Product2];
        Integer i = 1;
        for(Product2 pr:prs){
            pr.Package_Quantity__c = i;
            i++;
        }
        update prs;

        Test.startTest();
        B2B_ProductQuantityRuleBatch b = new B2B_ProductQuantityRuleBatch();
        ID BatchProcessId = Database.executeBatch(b, 200);
        Test.stopTest();

    }
}
