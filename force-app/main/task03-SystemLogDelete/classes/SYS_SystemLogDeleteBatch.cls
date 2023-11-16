/**
 * @description Batch Apex class that permanently deletes System_Log__c objects created before a specified cutoff date.
 * Author: aykut.palak@sbcinc.com
 * Creation Date: 13.10.2023
 *
 * Sample Usage:
 *
 * Date cutoffStartDate = Date.newInstance(2023, 10, 16);
 * Date cutoffEndDate = Date.newInstance(2023, 10, 17);
 * SYS_SystemLogDeleteBatch batchJob = new SYS_SystemLogDeleteBatch(cutoffStartDate,cutoffEndDate);
 * Database.executeBatch(batchJob, 2000);
 */
public class SYS_SystemLogDeleteBatch implements Database.Batchable<SObject> {
    Date cutoffStartDate;
    Date cutoffEndDate;

    /**
     * @description Constructor method that sets up the initial query for the batch job.
     *
     * @param providedCutoffStartDate The provided cutoff start date.
     * @param providedCutoffEndDate The provided cutoff end date.
     */
    public SYS_SystemLogDeleteBatch(Date providedCutoffStartDate, Date providedCutoffEndDate) {
        // Define the cutoff start and end dates
        cutoffStartDate = (providedCutoffStartDate == null) ? Date.newInstance(2014, 1, 1) : providedCutoffStartDate;
        cutoffEndDate = (providedCutoffEndDate == null) ? Date.newInstance(2023, 1, 1) : providedCutoffEndDate;
    }

    /**
     * @description Start method that sets up the initial query for the batch job.
     *
     * @param context The batchable context.
     * @return A QueryLocator to retrieve System_Log__c records created between the cutoff dates
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        // Use the cutoffStartDate and cutoffEndDate in the dynamic SOQL query
        return Database.getQueryLocator(
            [
                SELECT Id, CreatedDate
                FROM System_Log__c
                WHERE CreatedDate < :cutoffEndDate AND CreatedDate > :cutoffStartDate
            ]
        );
    }

    /**
     * @description Execute method to process the retrieved System_Log__c records.
     *
     * @param context The batchable context.
     * @param scope The list of System_Log__c records to process.
     */
    public void execute(Database.BatchableContext context, List<System_Log__c> scope) {
        List<Id> recordsToDelete = new List<Id>();

        for (System_Log__c log : scope) {
            recordsToDelete.add(log.Id);
        }

        if (!recordsToDelete.isEmpty()) {
            try {
                // Use Database.emptyRecycleBin to permanently delete the records
                Database.delete(recordsToDelete);
                Database.emptyRecycleBin(recordsToDelete);
            } catch (Exception ex) {
                // Log any errors while deleting records
                SystemLogHelper.insertSystemLog('systemLogDeletionError', 'Error on deleting system log records.', ex);
            }
        }
    }

    /**
     * @description Finish method for any post-processing, if needed.
     *
     * @param context The batchable context.
     */
    public void finish(Database.BatchableContext context) {
        // Any post-processing can be performed here if needed
    }
}
