global class B2B_Pricebook2RepairBatch implements Database.Batchable<sObject>, Database.Stateful {
    /*  
        This batch class is developed for repairing the BuyerGroupMembers based on the Account Pricebook Mapping

        --------------------------------------------------------------------------
        Execution Script:
        --------------------------------------------------------------------------
        B2B_Pricebook2RepairBatch b = new B2B_Pricebook2RepairBatch();
        //b.whereClause = ' WHERE CSP_End_Date__c < 2024-12-18';
        //b.whereClause = ' WHERE Id = \'01sDh000000QGlAIAW\'';
        ID BatchProcessId = Database.executeBatch(b,200);     
        --------------------------------------------------------------------------
    */

    global string whereClause;

    global database.querylocator start(Database.BatchableContext bc) {
        //query for pending Async_Data__c records with queue 'ESG_Link_Envelope_To_SF_Account'
        String query = 'SELECT Id FROM Pricebook2';
        if (whereClause != null && whereClause != '') {
            query += whereClause;
        } else {
            // No where clause default
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Pricebook2> toProcess) {
        Set<Id> pricebook2Ids = new Set<Id>();

        for (Pricebook2 pb : toProcess) {
            pricebook2Ids.add(pb.Id);
        }

        B2B_BuyerGroupAndEntitlementHelper.adjustCommerceEntitlementBuyerGroup(pricebook2Ids);
    }

    global void finish(Database.BatchableContext BC) {
    }
}
