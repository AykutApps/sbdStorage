@isTest
public with sharing class B2B_ProductQuantityRuleSchedTest {
    @isTest
    public static void testProductQuantityRuleSchedTest() {
        Test.startTest();
        B2B_ProductQuantityRuleSched s = new B2B_ProductQuantityRuleSched();
        s.execute(null);
        Test.stopTest();
    }
}