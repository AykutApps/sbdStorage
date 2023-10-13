public class DeleteSystemLogBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, CreatedDate FROM System_Log__c WHERE CreatedDate < 2023-01-01T00:00:00Z');
    }

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
                System.debug('Error deleting records: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        // You can perform any post-processing here if needed
    }
}
