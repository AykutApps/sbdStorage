/*  
        This batch class is developed for creating a csv file for Product Image URLs.
        --------------------------------------------------------------------------
        Execution Script:
        --------------------------------------------------------------------------
        B2B_ProductImageBatch b = new B2B_ProductImageBatch();
        // b.whereClause= 'WHERE B2B_Image_Present__c = FALSE AND B2B_Product_Type__c IN (\'Parts\', \'Whole_Goods\')'
        ID BatchProcessId = Database.executeBatch(b,B2B_ProductImageBatch.BATCH_SIZE);     
        --------------------------------------------------------------------------
*/
public without sharing class B2B_ProductImageBatch implements Database.Batchable<SObject>, Database.Stateful {
    private static final Integer BATCH_SIZE = 200;
    private static String LIBRARY_DEVELOPER_NAME = 'B2B_Storefront_Admin';

    // This will hold the CSV content across batches
    private String finalCsvData = '';

    // global where clause
    public String whereClause;
    public Boolean isDaily = true;

    // Constructor to initialize the CSV header
    public B2B_ProductImageBatch() {
        finalCsvData += B2B_ProductImageHelper.generateCsvHeader();
    }

    // The start method defines the scope of the query
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, ProductCode, Name, B2B_Image_URLs__c FROM Product2 ';
        String defaultWhereClause = 'WHERE B2B_Image_Present__c = FALSE AND B2B_Product_Type__c IN (\'Parts\', \'Whole_Goods\')';

        if (!String.isBlank(whereClause)) {
            query += whereClause;
        } else {
            query += defaultWhereClause;
        }
        return Database.getQueryLocator(query);
    }

    // The execute method processes each batch
    public void execute(Database.BatchableContext BC, List<Product2> scope) {
        finalCsvData += B2B_ProductImageHelper.generateCsvRows(scope);
    }

    // The finish method is called after all batches are processed
    public void finish(Database.BatchableContext BC) {
        B2B_ProductImageHelper.saveCSVToFile(finalCsvData, LIBRARY_DEVELOPER_NAME, isDaily);
    }
}
