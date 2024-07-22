global class B2B_AccountPBMapBuyerGroupMembBatch implements Database.Batchable<sObject>, Database.Stateful {
    /*  
        This batch class is developed for repairing the BuyerGroupMembers based on the Account Pricebook Mapping

        --------------------------------------------------------------------------
        Execution Script:
        --------------------------------------------------------------------------
        B2B_AccountPBMapBuyerGroupMembBatch b = new B2B_AccountPBMapBuyerGroupMembBatch();
        //b.whereClause = ' WHERE ERP_End_Date__c < 2024-12-18';
        //b.whereClause = ' WHERE Id = \'a1xO8000000b266IAA\'';
        ID BatchProcessId = Database.executeBatch(b,200);     
        --------------------------------------------------------------------------
    */

    global string whereClause;

    global database.querylocator start(Database.BatchableContext bc) {
        //query for pending Async_Data__c records with queue 'ESG_Link_Envelope_To_SF_Account'
        String query = 'SELECT Id FROM Account_Pricebook_Mapping__c';
        if (whereClause != null && whereClause != '') {
            query += whereClause;
        } else {
            // No where clause default
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account_Pricebook_Mapping__c> toProcess) {
        Set<Id> accountPricebookMappingIds = new Set<Id>();

        for (Account_Pricebook_Mapping__c apm : toProcess) {
            accountPricebookMappingIds.add(apm.Id);
        }

        B2B_BuyerGroupAndEntitlementHelper.adjustBuyerGroupMember(accountPricebookMappingIds);
    }

    global void finish(Database.BatchableContext BC) {
    }
}
