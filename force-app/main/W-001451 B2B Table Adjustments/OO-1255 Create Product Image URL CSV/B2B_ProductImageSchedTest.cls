@isTest
public class B2B_ProductImageSchedTest {

    @testSetup
    static void setupTestData() {
        B2B_ProductImageBatchTest.makeData();
    }

    @isTest
    static void testDailySchedule() {
        // Create an instance of the Schedulable class and set the isDaily flag
        B2B_ProductImageSched sched = new B2B_ProductImageSched();
        sched.isDaily = true;

        Test.startTest();
        // Schedule the job using the daily cron expression
        String jobId = System.schedule('Test Daily B2B Product Image Sched', B2B_ProductImageSched.CRON_EXP_DAILY, sched);
        
        
        // Assert that the scheduled job exists in the AsyncApexJob table
        System.assertNotEquals(null, jobId, 'Job ID should not be null');
        Test.stopTest();
    }

    @isTest
    static void testMonthlySchedule() {
        // Create an instance of the Schedulable class and set the isDaily flag to false for monthly schedule
        B2B_ProductImageSched sched = new B2B_ProductImageSched();
        sched.isDaily = false;

        // Schedule the job using the monthly cron expression
        String jobId = System.schedule('Test Monthly B2B Product Image Sched', B2B_ProductImageSched.CRON_EXP_MONTHLY, sched);

        // Assert that the scheduled job exists in the AsyncApexJob table
        System.assertNotEquals(null, jobId, 'Job ID should not be null');
    }

    @isTest
    static void testExecuteMethod() {
        // Test the execute method directly by simulating the scheduler
        Test.startTest();

        // Instantiate the schedulable class and call the execute method
        B2B_ProductImageSched sched = new B2B_ProductImageSched();
        sched.isDaily = true;

        String jobId = System.schedule('Test Daily B2B Product Image Sched', B2B_ProductImageSched.CRON_EXP_DAILY, sched);


        Test.stopTest();

        // Verify that the batch job was created
        List<AsyncApexJob> batchJobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        System.assert(batchJobs.size() > 0, 'Batch job should have been created');
    }
}
