global class B2B_RepairExistingProduct2Batch implements Database.Batchable<sObject>, Database.Stateful {
    /*  
        This batch class is developed for filling new B2B Product2 fields on existing Product2 records.

        mburr.2024-07-28 when MJ ran this in staging, all Product2 records were process.  See MJ's email chain.
                         he backed out a few things.  What happened?  The ENV__c custom setting had the wrong 
                         value for Data_Migration_User_Id__c.   

        Should only be run once per environment.
        --------------------------------------------------------------------------
        Execution Script:
        --------------------------------------------------------------------------
        B2B_RepairExistingProduct2Batch b = new B2B_RepairExistingProduct2Batch();
        //b.whereClause = ' WHERE Id = \'01t2G000006XUX3\'';
        ID BatchProcessId = Database.executeBatch(b,200);     
        --------------------------------------------------------------------------
    */

    global string whereClause;

    global database.querylocator start(Database.BatchableContext bc) {
        //query for pending Async_Data__c records with queue 'ESG_Link_Envelope_To_SF_Account'
        String query = 'SELECT Id, RecordTypeId, StockKeepingUnit, ProductCode, IsActive, Is_Active_US__c, B2B_Product_Type__c, Update_Fulfill_From__c, Update_Fulfill_From_Text__c, CreatedById FROM Product2';
        if (whereClause != null && whereClause != '') {
            query += whereClause;
        } else {
            // No where clause default
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Product2> toProcess) {
        ENV__c env = ENV__c.getOrgDefaults(); //ignore overrides

        List<Product2> ups = new List<Product2>();

        for (Product2 p : toProcess) {
            //skip record if created by R1's data load user (i.e. santiago in STAGING)
            if ((Id) p.CreatedById == (Id) env.Data_Migration_User_Id__c) {
                continue;
            }

            boolean chg = false;
            Product2 up = new Product2(id = p.Id);

            if (p.StockKeepingUnit != p.ProductCode) {
                chg = true;
                up.StockKeepingUnit = p.ProductCode;
            }

            if (String.isBlank(p.Update_Fulfill_From__c) || !p.Update_Fulfill_From__c.contains('INFOR')) {
                chg = true;
                up.Update_Fulfill_From_Text__c = 'INFOR'; //trigger should update the multiselect picklist Update_Fulfill_From__c and clear the value in this "_Text__c" field
            }

            if (p.RecordTypeId == RecordTypes.product_WholeGood.Id || p.RecordTypeId == RecordTypes.product_Attachment.Id) {
                if (p.IsActive == true && p.Is_Active_US__c != true) {
                    //mburr.2024-07-28 added p.IsActive == true after running in STAGING.
                    chg = true;
                    up.Is_Active_US__c = true;
                }
            }

            //fix b2b-product-type
            if (p.RecordTypeId == RecordTypes.product_Part.Id) {
                if (p.B2B_Product_Type__c != 'Parts') {
                    chg = true;
                    up.B2B_Product_Type__c = 'Parts';
                }
            } else if (
                p.RecordTypeId == RecordTypes.product_FinishedGoodsFromEDW.Id ||
                p.RecordTypeId == RecordTypes.product_WholeGood.Id ||
                p.RecordTypeId == RecordTypes.product_Attachment.Id
            ) {
                if (p.B2B_Product_Type__c != 'Whole Goods') {
                    chg = true;
                    up.B2B_Product_Type__c = 'Whole Goods';
                }
            }

            //final
            if (chg = true)
                ups.add(up);
            //system.debug('xxx-up-'+up);
        }

        //system.debug('xxx-ups-'+ups);
        if (ups.size() > 0) {
            update ups;
        }
    }

    global void finish(Database.BatchableContext BC) {
    }
}
