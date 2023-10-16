@isTest
public class SystemLogDeleteBatchTest {
    @isTest
    static void testBatchJob() {
        // Create test System_Log__c records
        List<System_Log__c> testLogs = new List<System_Log__c>();
        for (Integer i = 0; i < 10; i++) {
            System_Log__c log = new System_Log__c(CreatedDate = Date.newInstance(2022, 12, 31));
            testLogs.add(log);
        }
        insert testLogs;

        // Create an instance of the batch class
        SystemLogDeleteBatch batchJob = new SystemLogDeleteBatch(Date.today().addDays(1), Date.today().addDays(-1));

        // Start the batch job
        Test.startTest();
        Database.executeBatch(batchJob);
        Test.stopTest();

        // Verify that the records were deleted
        List<System_Log__c> remainingLogs = [SELECT Id FROM System_Log__c];
        System.assertEquals(0, remainingLogs.size(), 'All System_Log__c records should have been deleted.');
    }
}
