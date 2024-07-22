@isTest
public with sharing class B2B_Pricebook2RepairSchedTest {
    @TestSetup
    public static void makeData() {
        B2B_BuyerGroupAndEntitlementHelperTest.makeData();
    }

    @isTest
    public static void testB2B_Pricebook2RepairBatchTest() {
        Test.startTest();
        B2B_Pricebook2RepairSched s = new B2B_Pricebook2RepairSched();
        s.execute(null);
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM CommerceEntitlementBuyerGroup].size());
    }
}
