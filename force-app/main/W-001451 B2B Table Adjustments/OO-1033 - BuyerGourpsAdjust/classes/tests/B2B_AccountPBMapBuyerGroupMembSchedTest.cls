@isTest
public with sharing class B2B_AccountPBMapBuyerGroupMembSchedTest {
    @TestSetup
    public static void makeData() {
        B2B_BuyerGroupAndEntitlementHelperTest.makeData();
    }

    @isTest
    public static void testB2B_AccountPBMapBuyerGroupMembSched() {
        Test.startTest();
        B2B_AccountPBMapBuyerGroupMembSched s = new B2B_AccountPBMapBuyerGroupMembSched();
        s.execute(null);
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM BuyerGroupMember].size());
    }
}
