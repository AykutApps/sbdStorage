@isTest
public class B2B_Product2BatchJobSchedulerTest {
    // Test scheduling the batch job
    @isTest
    static void testScheduleBatchJob() {
        Test.startTest();

        // Schedule the job with the cron expression
        String cronExp = '0 0 3 * * ?';
        String jobId = System.schedule('Test_B2B_PricingBatchJobScheduler', cronExp, new B2B_Product2BatchJobScheduler());

        // Verify the job has been scheduled
        CronTrigger cronTrigger = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assertEquals(cronExp, cronTrigger.CronExpression, 'The cron expression should match.');
        System.assertEquals(0, cronTrigger.TimesTriggered, 'The job should not have been triggered yet.');

        Test.stopTest();
    }

    // Test execution of the batch job
    @isTest
    static void testExecuteBatchJob() {
        String firstJobClassName = 'B2B_InventoryLeadTimesBatch';

        // Set up test data and mock implementations of batch jobs
        Test.startTest();

        // Mocking the job chain in a test scenario
        B2B_Product2BatchJobScheduler scheduler = new B2B_Product2BatchJobScheduler();

        // Execute the job
        scheduler.execute(null);
        Test.stopTest();

        // Verify if the first job in the chain is executed
        System.assert([SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = :firstJobClassName].size() == 1, 'Ensure the runNextJob is correctly invoking the first job.');
        System.assertEquals(8, [SELECT Id FROM System_Log__c].size(), 'Ensure System Log record is created.');
    }

    // Test runNextJob method
    @isTest
    static void testRunNextJob() {
        String testClassName = 'B2B_InventoryLeadTimesBatch';
        Test.startTest();

        // Create a mock implementation for the batch jobs
        B2B_Product2BatchJobScheduler.runNextJob(new Map<String, String>{ null => testClassName }, null);

        Test.stopTest();

        // Verify that the batch job was executed
        System.assert([SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = :testClassName].size() == 1, 'Ensure the runNextJob is correctly invoking the next job.');
    }
}
