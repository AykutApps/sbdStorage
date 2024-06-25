global class SYS_GenericRecordDeletionBatchScheduler implements Schedulable {
    public Integer DEFAULT_BATCH_SIZE = 2000;
    public SYS_GenericRecordDeletionBatchScheduler(String query, Integer batchSize) {
    }

    global void execute(SchedulableContext sc) {
        SYS_GenericDeleteBatchHelper.runAllDataRententionPolicyJobs(DEFAULT_BATCH_SIZE);
    }
}