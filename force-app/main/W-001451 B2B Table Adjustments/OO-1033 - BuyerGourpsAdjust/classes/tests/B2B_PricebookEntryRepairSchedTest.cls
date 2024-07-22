@isTest
public with sharing class B2B_PricebookEntryRepairSchedTest {
    @TestSetup
    public static void makeData() {
        B2B_BuyerGroupAndEntitlementHelperTest.makeData();
    }

    @isTest
    public static void testB2B_PricebookEntryRepairSched() {
        Test.startTest();
        B2B_PricebookEntryRepairSched s = new B2B_PricebookEntryRepairSched();
        s.execute(null);
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM CommerceEntitlementProduct].size());
    }
}
