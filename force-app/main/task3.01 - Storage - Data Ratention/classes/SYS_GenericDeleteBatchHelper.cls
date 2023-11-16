global with sharing class SYS_GenericDeleteBatchHelper {
    webService static void runBatchJob(Id dataRetentionPolicyId) {
        Data_Retention_Policy__c drp = [
            SELECT Id, Name, Object__c, Deletion_Logic__c, Retention_Time_Period__c, Handler_Class_Name__c, is_Active__c
            FROM Data_Retention_Policy__c
            WHERE Id = :dataRetentionPolicyId
        ];
        runBatchJob(drp, 200);
    }

    public static void runBatchJobs(Data_Retention_Policy__c[] drps, Integer batchSize) {
        for (Data_Retention_Policy__c drp : drps) {
            runBatchJob(drp, batchSize);
        }
    }

    public static void runBatchJob(Data_Retention_Policy__c drp, Integer batchSize) {
        if (drp.Deletion_Logic__c == 'Standard Delete') {
            SYS_GenericDeleteBatch batch = new SYS_GenericDeleteBatch(drp.Object__c, drp.Retention_Time_Period__c);
            Database.executeBatch(batch, batchSize);
        } else {
            //  TODO run custom logic
        }
    }
}
