@isTest
public with sharing class B2B_PricebookEntryRepairBatchTest {
    @TestSetup
    public static void makeData() {
        B2B_BuyerGroupAndEntitlementHelperTest.makeData();
    }

    @isTest
    public static void testB2B_PricebookEntryRepairBatch() {
        Test.startTest();
        B2B_PricebookEntryRepairBatch b = new B2B_PricebookEntryRepairBatch();
        Id BatchProcessId = Database.executeBatch(b, 200);
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM CommerceEntitlementProduct].size());
    }
}
