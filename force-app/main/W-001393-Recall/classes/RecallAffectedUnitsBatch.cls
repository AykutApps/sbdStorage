global with sharing class RecallAffectedUnitsBatch implements Database.Batchable<SObject> {
    public String query;
    private String recallId;
    public RecallAffectedUnitsBatch(String recallId) {
        this.recallId = recallId;
        // this.query = 'SELECT Id, Serial_Number__c, Model__c, Dealer_Entity_Id__c, Recall__c, Recall_Account__c, Recall_Model__c FROM Recall_Item__c WHERE Recall__c = '+ recallId;
    }

    global Iterable<SObject> start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Serial_Number__c, Model__c, Dealer_Entity_Id__c, Recall__c, Recall_Account__c, Recall_Model__c FROM Recall_Item__c WHERE Recall__c = :this.recallId]);
        // return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> records) {
        // Create Missing Recall Accounts
        RecallHelper.createMissingRecallAccounts(this.recallId, records);
        // Relate wiht Recall Accounts
        RecallHelper.relateRecallItemsWithRecallAccounts(this.recallId, records);
        // Create Missing Recall Models
        RecallHelper.createMissingRecallModels(this.recallId, records);
        // Relate with Recall Models
        RecallHelper.relateRecallItemsWithModels(this.recallId, records);
        // Sum-Up the serial Numbers on Recall Models
        RecallHelper.sumUpRecallItemsSerialNumersToModels(this.recallId, records);
    }

    global void finish(Database.BatchableContext bc) {
    }
}
