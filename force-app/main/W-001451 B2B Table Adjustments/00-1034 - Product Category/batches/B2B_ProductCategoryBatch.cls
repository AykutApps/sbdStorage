global class \ implements Database.Batchable<sObject>, Database.Stateful {
    /*  
        This batch class is developed for filling the B2B Product2 fiter fields
        --------------------------------------------------------------------------
        Execution Script:
        --------------------------------------------------------------------------
        B2B_ProductCategoryBatch b = new B2B_ProductCategoryBatch();
        //b.whereClause = ' WHERE Id = \'01t2G000007C8dMQAS\'';
        ID BatchProcessId = Database.executeBatch(b,200);     
        --------------------------------------------------------------------------
    */

    global string whereClause;

    global database.querylocator start(Database.BatchableContext bc) {
        //query for pending Async_Data__c records with queue 'ESG_Link_Envelope_To_SF_Account'
        String query = 'SELECT Id FROM Product2';
        if (whereClause != null && whereClause != '') {
            query += whereClause;
        } else {
            // No where clause default
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Product2> toProcess) {
        Set<Id> productIds = new Set<Id>();

        for (Product2 p : toProcess) {
            productIds.add(p.Id);
        }

        B2B_ProductCategoryHelper.adjustProductCategories(productIds);
    }

    global void finish(Database.BatchableContext BC) {
    }
}
