global class B2B_ProductQuantityRuleBatch implements Database.Batchable<sObject>, Database.Stateful {
    /*  
        --------------------------------------------------------------------------
        Execution Script:
        --------------------------------------------------------------------------
        B2B_ProductQuantityRuleBatch b = new B2B_ProductQuantityRuleBatch();
        //b.whereClause = ' WHERE Package_Quantity__c > 0';
        ID BatchProcessId = Database.executeBatch(b,200);     
        --------------------------------------------------------------------------
    */

    global string whereClause;

    global database.querylocator start(Database.BatchableContext bc) {
        //query for pending Async_Data__c records with queue 'ESG_Link_Envelope_To_SF_Account'
        String baseQuery = 'SELECT Id FROM Product2';
        String defaultWhereClause = ' WHERE Package_Quantity__c > 1';

        if (!String.isBlank(whereClause)) {
            baseQuery += whereClause;
        } else {
            baseQuery += defaultWhereClause;
        }

        return Database.getQueryLocator(baseQuery);
    }

    global void execute(Database.BatchableContext BC, List<Product2> toProcess) {
        Set<Id> productIds = new Set<Id>();

        for (Product2 product : toProcess) {
            productIds.add(product.Id);
        }

        B2B_ProductQuantityRuleHelper.upsertProductQuantityRules(productIds);
    }

    global void finish(Database.BatchableContext BC) {
    }
}
