global class B2B_PricebookEntryRepairBatch extends B2B_BatchJobSchedulerAbstract implements Database.Batchable<sObject>, Database.Stateful {
    /*  
        This batch class is developed for repairing the BuyerGroupMembers based on the Account Pricebook Mapping

        --------------------------------------------------------------------------
        Execution Script:
        --------------------------------------------------------------------------
        B2B_PricebookEntryRepairBatch b = new B2B_PricebookEntryRepairBatch();
        //b.whereClause = ' WHERE ERP_Valid_To__c < 2024-12-18';
        //b.whereClause = ' WHERE Id = \'01uDh00000ByoymIAB\'';
        ID BatchProcessId = Database.executeBatch(b,200);     
        --------------------------------------------------------------------------
    */

    global string whereClause;

    global database.querylocator start(Database.BatchableContext bc) {
        whereClause = ' WHERE External_Key__c != NULL';
        String query = 'SELECT Id FROM PricebookEntry';
        if (whereClause != null && whereClause != '') {
            query += whereClause;
        } else {
            // No where clause default
        }

        // log Start
        B2B_PricingBatchJobScheduler.logStartBatchJob(this, whereClause);

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<PricebookEntry> toProcess) {
        Set<Id> pricebookEntryIds = new Set<Id>();

        for (PricebookEntry pbe : toProcess) {
            pricebookEntryIds.add(pbe.Id);
        }

        B2B_BuyerGroupAndEntitlementHelper.adjustCommerceEntitlementProduct(pricebookEntryIds);
    }

    global void finish(Database.BatchableContext BC) {
        // System Log for Finish
        B2B_PricingBatchJobScheduler.logAndChainStopBatchJob(this, BC);
    }
}
