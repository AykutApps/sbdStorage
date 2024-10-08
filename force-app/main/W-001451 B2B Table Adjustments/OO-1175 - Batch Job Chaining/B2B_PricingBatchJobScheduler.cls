global with sharing class B2B_PricingBatchJobScheduler implements Schedulable {
    /* Run everyhour.
    --------------------------------------------------------------------------
    Scheduling Script   (copy & paste into execute anonymous window to schedule batch job)
    --------------------------------------------------------------------------
    System.schedule('B2B_PricingBatchJobScheduler', B2B_PricingBatchJobScheduler.CRON_EXP, new B2B_PricingBatchJobScheduler());
    --------------------------------------------------------------------------
    */

    // every day at 3 a.m. to run the job
    public static String CRON_EXP = '0 0 3 * * ?';

    public Map<String, String> pricingJobsChain = new Map<String, String>{
        null => 'B2B_AdjustPricebookActivationBatch',
        'B2B_AdjustPricebookActivationBatch' => 'B2B_Pricebook2RepairBatch',
        'B2B_Pricebook2RepairBatch' => 'B2B_AccountPBMapBuyerGroupMembBatch',
        'B2B_AccountPBMapBuyerGroupMembBatch' => 'B2B_AdjustPBEActivationBatch',
        'B2B_AdjustPBEActivationBatch' => 'B2B_PricebookEntryRepairBatch',
        'B2B_PricebookEntryRepairBatch' => null
    };

    global void execute(SchedulableContext ctx) {
        runNextJob(pricingJobsChain, null);
    }

    public static void runNextJob(Map<String, String> jobsChain, String finishedJobClassName) {
        String nextJobClassName = jobsChain?.get(finishedJobClassName);
        if (nextJobClassName == null)
            return;

        Type newJobBatchClassType = Type.forName(nextJobClassName);
        B2B_BatchJobSchedulerAbstract nextJobBatchInstance = (B2B_BatchJobSchedulerAbstract) newJobBatchClassType.newInstance();
        nextJobBatchInstance.jobsChain = jobsChain;
        // Database.Batchable<Object> nextJobBatchInstance = (Database.Batchable<Object>)newJobBatchClassType.newInstance();
        Database.executeBatch((Database.Batchable<Object>) nextJobBatchInstance, 200);
    }

    public static void logStartBatchJob(B2B_BatchJobSchedulerAbstract batchJob, String whereClause) {
        // System Log for Start
        String className = String.valueOf(batchJob).substring(0, String.valueOf(batchJob).indexOf(':'));
        SystemLogHelper.insertSystemLog(
            className,
            'BATCH_JOB',
            UserInfo.getUserId(),
            'Start Batch Job: ' + className,
            'Batch job staterted with where clause: ' + whereClause + ' and jobs chain: ' + String.valueof(batchJob.jobsChain)
        );
    }

    public static void logAndChainStopBatchJob(B2B_BatchJobSchedulerAbstract batchJob, Database.BatchableContext BC) {
        // System Log for Finish
        // Query the AsyncApexJob to get details about the job

        AsyncApexJob job = [
            SELECT Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :BC.getJobId()
        ];

        String className = String.valueOf(batchJob).substring(0, String.valueOf(batchJob).indexOf(':'));
        SystemLogHelper.insertSystemLog(
            className,
            'BATCH_JOB',
            UserInfo.getUserId(),
            'Stop Batch Job: ' + className + ((job.NumberOfErrors == 0) ? ' SUCCESS' : ' ERROR'),
            'Batch job ' +
                BC.getJobId() +
                ' completed with status: ' +
                ((job.NumberOfErrors == 0) ? ' SUCCESS' : ' ERROR' + ' and Number of Errors: ' + String.valueof(job.NumberOfErrors) + ', Error Detail: ' + job.ExtendedStatus)
        );

        // Chain the next job
        if (batchJob.jobsChain != null) {
            B2B_PricingBatchJobScheduler.runNextJob(batchJob.jobsChain, className);
        }
    }
}
