/**
 * @description Batch Apex class that permanently deletes System_Log__c objects created before a specified cutoff date.
 * Author: aykut.palak@sbcinc.com
 * CreationDate: 13.10.2023
 * ModifiedBy: aykut.parlak@sbcinc.com
 * ModifiedDate: 13.10.2023
 */
public class DeleteSystemLogBatch implements Database.Batchable<SObject> {
    Date cutoffDate;
    /**
     * @description Start method that sets up the initial query for the batch job.
     *
     * @param context The batchable context.
     * @return A QueryLocator to retrieve System_Log__c records created before the cutoff date.
     */
    public DeleteSystemLogBatch(Date providedCutoffDate) {
        cutoffDate = providedCutoffDate;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        // Define the cutoff date as January 1, 2023 if not provided
        cutoffDate = (cutoffDate == null) ? Date.newInstance(2023, 1, 1) : cutoffDate;

        // Use the cutoffDate in the dynamic SOQL query
        return Database.getQueryLocator(
            [
                SELECT Id, CreatedDate
                FROM System_Log__c
                WHERE CreatedDate < :cutoffDate
            ]
        );
    }

    /**
     * @description Execute method to process the retrieved System_Log__c records.
     *
     * @param context The batchable context.
     * @param scope   The list of System_Log__c records to process.
     */
    public void execute(Database.BatchableContext context, List<System_Log__c> scope) {
        List<Id> recordsToDelete = new List<Id>();

        for (System_Log__c log : scope) {
            recordsToDelete.add(log.Id);
        }

        if (!recordsToDelete.isEmpty()) {
            try {
                // Use Database.emptyRecycleBin to permanently delete the records
                Database.emptyRecycleBin(recordsToDelete);
            } catch (Exception e) {
                // Log any errors while deleting records
                SystemLogHelper.insertSystemLog('deleteSystemLog', 'Error deleting records: ', e);
            }
        }
    }

    /**
     * @description Finish method for any post-processing, if needed.
     *
     * @param context The batchable context.
     */
    public void finish(Database.BatchableContext context) {
        // Any post-processing cab be performed here if needed
    }
}
