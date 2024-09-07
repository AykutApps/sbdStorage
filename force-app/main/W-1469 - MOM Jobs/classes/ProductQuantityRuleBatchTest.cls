@isTest
public with sharing class ProductQuantityRuleBatchTest {
    @isTest
    public static void testProductQuantityRuleBatchTest() {
        ProductQuantityRuleHelper.createPurchaseQuantityRules();
        TestData_Product2.createProducts();

        List<Product2> prs = [SELECT Id,Package_Quantity__c FROM Product2];
        Integer i = 1;
        for(Product2 pr:prs){
            pr.Package_Quantity__c = i;
            i++;
        }
        update prs;

        Test.startTest();
        ProductQuantityRuleBatch b = new ProductQuantityRuleBatch();
        ID BatchProcessId = Database.executeBatch(b, 200);
        Test.stopTest();

    }
}
