/**
 * @description Generic Delete batch job to delete any records provided by SOQL
 * Author: aykut.palak@sbcinc.com
 * Creation Date: 2023-11-15
 *
 * Sample Usage 1:
 *
 * String soqlQuery = 'SELECT Id FROM System_Log__c WHERE CreatedDate < THIS_YEAR ';
 * GenericRecordDeletionBatch batch = new GenericRecordDeletionBatch(soqlQuery);
 * Database.executeBatch(batch, 2000);
 *
 * Sample Usage 2:
 *
 * GenericRecordDeletionBatch batch = new GenericRecordDeletionBatch('System_Log__c', '180');
 * Database.executeBatch(batch, 2000);
 *
 */
global class SYS_GenericDeleteBatch implements Database.Batchable<SObject> {
    public String query;

    public SYS_GenericDeleteBatch(String query) {
        this.query = query;
    }

    public SYS_GenericDeleteBatch(String objectName, String retentionDays) {
        this.query = String.format('SELECT Id FROM {0} WHERE CreatedDate < LAST_N_DAYS: {1}', new List<String>{ objectName, retentionDays });
    }

    global Iterable<SObject> start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> records) {
        Database.delete(records, false); // false for allowing partial processing (not all-or-none)
        Database.emptyRecycleBin(records);
    }

    /**
     * Executes post-processing operations, if any.
     * @param bc The BatchableContext object.
     */
    global void finish(Database.BatchableContext bc) {
    }
}
