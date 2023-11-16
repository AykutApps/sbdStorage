global class SYS_GenericRecordDeletionBatchScheduler implements Schedulable {
    public Integer DEFAULT_BATCH_SIZE = 2000;
    public SYS_GenericRecordDeletionBatchScheduler(String query, Integer batchSize) {
    }

    global void execute(SchedulableContext sc) {
        List<Data_Retention_Policy__c> drps = [
            SELECT id, Name, Object__c, Deletion_Logic__c, Retention_Time_Period__c, Handler_Class_Name__c, is_Active__c
            FROM Data_Retention_Policy__c
            WHERE is_Active__c = TRUE
        ];

        SYS_GenericDeleteBatchHelper.runBatchJobs(drps, DEFAULT_BATCH_SIZE);
    }
}
