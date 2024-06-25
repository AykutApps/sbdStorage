global with sharing class RecallAffectedUnitsEmailSendBatch implements Database.Batchable<SObject> {
    public String query;
    private String recallId;
    
    public RecallAffectedUnitsEmailSendBatch(String recallId) {
        this.recallId = recallId;
    }

    global Iterable<SObject> start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM Recall_Account__c WHERE Recall__c = :this.recallId]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> records) {
        RecallHelper.sendRecallAffectedUnitsEmail(records[0].Id);
    }

    global void finish(Database.BatchableContext bc) {
    }
}