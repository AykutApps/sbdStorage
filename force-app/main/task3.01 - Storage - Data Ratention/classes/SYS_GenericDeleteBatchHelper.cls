global with sharing class SYS_GenericDeleteBatchHelper {
    public static String JOB_EXECUTE_PERMISSION_NAME = 'Data_Retention_Batch_Job_Run';

    // These variables are used for UI initiated jobs
    public Id dataRetentionPolicyId { get; set; }
    public Data_Retention_Policy__c dataRetentionPolicy { get; set; }

    //constructor to get the recordId from UI
    public SYS_GenericDeleteBatchHelper(ApexPages.StandardController controller) {
        dataRetentionPolicy = (Data_Retention_Policy__c) controller.getRecord();
        dataRetentionPolicyId = dataRetentionPolicy.Id;
    }

    // the code can be executed from UI
    public PageReference runBatchJobFromUI() {
        system.debug('runBatchJobFromUI WORKS');
        runBatchJob(dataRetentionPolicyId);
        PageReference pageRef = new PageReference('/' + dataRetentionPolicyId);
        pageRef.setRedirect(true);
        return pageRef; //Returns to the case page
    }

    webService static void runBatchJob(Id dataRetentionPolicyId) {
        Data_Retention_Policy__c drp = [
            SELECT Id, Name, Object__c, Deletion_Logic__c, Retention_Time_Period__c, Handler_Class_Name__c, is_Active__c
            FROM Data_Retention_Policy__c
            WHERE Id = :dataRetentionPolicyId
        ];
        system.debug('runBatchJob works');
        runBatchJob(drp, 200);
    }

    public static void runAllDataRententionPolicyJobs(Integer batchSize) {
        List<Data_Retention_Policy__c> drps = [
            SELECT id, Name, Object__c, Deletion_Logic__c, Retention_Time_Period__c, Handler_Class_Name__c, is_Active__c
            FROM Data_Retention_Policy__c
            WHERE is_Active__c = TRUE
        ];
        runBatchJobs(drps, batchSize);
    }

    public static void runBatchJobs(Data_Retention_Policy__c[] drps, Integer batchSize) {
        for (Data_Retention_Policy__c drp : drps) {
            runBatchJob(drp, batchSize);
        }
    }

    public static void runBatchJob(Data_Retention_Policy__c drp, Integer batchSize) {
        if (!FeatureManagement.checkPermission(JOB_EXECUTE_PERMISSION_NAME)) {
            throw new CustomException('You do not have permission to execute this job');
        }

        if (drp.Deletion_Logic__c == 'Standard Delete') {
            SYS_GenericDeleteBatch batch = new SYS_GenericDeleteBatch(drp.Object__c, drp.Retention_Time_Period__c);
            Database.executeBatch(batch, batchSize);
            system.debug('DELETION BATCH JOB SET');
        } else {
            //  TODO run custom logic
        }
    }

    public class CustomException extends Exception {
    }
}
