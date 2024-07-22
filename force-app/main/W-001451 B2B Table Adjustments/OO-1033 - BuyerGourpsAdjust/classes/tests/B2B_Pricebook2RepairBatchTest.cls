@isTest
public with sharing class B2B_Pricebook2RepairBatchTest {
    @TestSetup
    public static void makeData() {
        B2B_BuyerGroupAndEntitlementHelperTest.makeData();
    }

    @isTest
    public static void testB2B_Pricebook2RepairBatch() {
        Test.startTest();
        B2B_Pricebook2RepairBatch b = new B2B_Pricebook2RepairBatch();
        Id BatchProcessId = Database.executeBatch(b, 200);
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM CommerceEntitlementBuyerGroup].size());
    }
}
