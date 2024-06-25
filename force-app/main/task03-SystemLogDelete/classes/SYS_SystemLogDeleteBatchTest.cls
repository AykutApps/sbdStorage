@isTest
public class SYS_SystemLogDeleteBatchTest {
    @isTest
    static void testBatchJob() {
        // Create test System_Log__c records
        List<System_Log__c> testLogs = new List<System_Log__c>();
        for (Integer i = 0; i < 2000; i++) {
            System_Log__c log = new System_Log__c(Code_Identifier__c='test',Description__c='test', Log_Item_Source__c ='test');
            testLogs.add(log);
        }
        insert testLogs;

        // Create an instance of the batch class
        SYS_SystemLogDeleteBatch batchJob = new SYS_SystemLogDeleteBatch(Date.today().addDays(-1), Date.today().addDays(1));

        // Start the batch job
        Test.startTest();
        Database.executeBatch(batchJob,2000);
        Test.stopTest();

        // Verify that the records were deleted
        List<System_Log__c> remainingLogs = [SELECT Id FROM System_Log__c];
        System.assertEquals(0, remainingLogs.size(), 'All System_Log__c records should have been deleted.');
    }
}