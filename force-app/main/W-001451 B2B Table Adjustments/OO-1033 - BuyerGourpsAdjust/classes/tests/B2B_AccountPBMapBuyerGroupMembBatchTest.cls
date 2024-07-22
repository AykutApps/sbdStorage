@isTest
public with sharing class B2B_AccountPBMapBuyerGroupMembBatchTest {
    @TestSetup
    public static void makeData() {
        B2B_BuyerGroupAndEntitlementHelperTest.makeData();
    }

    @isTest
    public static void testB2B_AccountPBMapBuyerGroupMembBatch() {
        Test.startTest();
        B2B_AccountPBMapBuyerGroupMembBatch b = new B2B_AccountPBMapBuyerGroupMembBatch();
        Id BatchProcessId = Database.executeBatch(b, 200);
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM BuyerGroupMember].size());
    }
}
