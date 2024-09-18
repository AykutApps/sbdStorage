@isTest
public class B2B_ProductQuantityRuleHelperTest {

    @isTest
    public static void testUpsertProductQuantityRules_simple(){
        B2B_ProductQuantityRuleHelper.createPurchaseQuantityRules();
        TestData_Product2.createProducts();

        List<Product2> prs = [SELECT Id,Package_Quantity__c FROM Product2];
        Integer i = 2;
        for(Product2 pr:prs){
            pr.Package_Quantity__c = i;
            i++;
        }
        update prs;
        B2B_ProductQuantityRuleHelper.upsertProductQuantityRules((new Map<Id,Product2>(prs)).keyset());
        System.assertEquals(prs.size(),[SELECT Id FROM ProductQuantityRule].size());
    }

    @isTest
    public static void testUpsertProductQuantityRules_multiple(){
        B2B_ProductQuantityRuleHelper.createPurchaseQuantityRules();
        TestData_Product2.createProducts();

        List<Product2> prs = [SELECT Id,Package_Quantity__c FROM Product2];
        Integer i = 2;
        for(Product2 pr:prs){
            pr.Package_Quantity__c = i;
            i++;
        }
        update prs;
        B2B_ProductQuantityRuleHelper.upsertProductQuantityRules((new Map<Id,Product2>(prs)).keyset());
        B2B_ProductQuantityRuleHelper.upsertProductQuantityRules((new Map<Id,Product2>(prs)).keyset());
        System.assertEquals(prs.size(),[SELECT Id FROM ProductQuantityRule].size());
    }
}