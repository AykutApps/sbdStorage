global class B2B_AdjustPBEActivationBatch implements Database.Batchable<sObject>, Database.Stateful {
    /*  
        This batch class is developed for repairing the BuyerGroupMembers based on the Account Pricebook Mapping

        --------------------------------------------------------------------------
        Execution Script:
        --------------------------------------------------------------------------
        B2B_AdjustPBEActivationBatch b = new B2B_AdjustPBEActivationBatch();
        //b.whereClause = ' WHERE Id = \'01uDh00000ByoymIAB\'';
        ID BatchProcessId = Database.executeBatch(b,200);     
        --------------------------------------------------------------------------
    */

    global string whereClause;

    global database.querylocator start(Database.BatchableContext bc) {
        //query for pending Async_Data__c records with queue 'ESG_Link_Envelope_To_SF_Account'
        String query = 'SELECT Id FROM PricebookEntry';
        if (whereClause != null && whereClause != '') {
            query += whereClause;
        } else {
            // No where clause default
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<PricebookEntry> toProcess) {
        Set<Id> pricebookEntryIds = new Set<Id>();

        for (PricebookEntry pbe : toProcess) {
            pricebookEntryIds.add(pbe.Id);
        }

        B2B_PricingHelper.adjustPricebookEntriesActivation(pricebookEntryIds);
    }

    global void finish(Database.BatchableContext BC) {
    }
}
