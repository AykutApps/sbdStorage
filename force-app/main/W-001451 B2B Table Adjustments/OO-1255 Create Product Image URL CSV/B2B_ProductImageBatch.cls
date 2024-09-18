/*  
        This batch class is developed for creating a csv file for Product Image URLs.
        --------------------------------------------------------------------------
        Execution Script:
        --------------------------------------------------------------------------
        B2B_ProductImageBatch b = new B2B_ProductImageBatch();
        // b.whereClause= 'WHERE B2B_Image_Present__c = FALSE AND B2B_Product_Type__c IN (\'Parts\', \'Whole_Goods\')'
        ID BatchProcessId = Database.executeBatch(b,200);     
        --------------------------------------------------------------------------
*/

public without sharing class B2B_ProductImageBatch implements Database.Batchable<SObject>, Database.Stateful {
    private static final Integer BATCH_SIZE = 200;
    private static String LIBRARY_DEVELOPER_NAME = 'B2B_Storefront_Admin';

    // global file name
    public Boolean isDaily = true;

    // This will hold the CSV content across batches
    private String finalCsvData = '';

    // global where clause
    public String whereClause;

    // Constructor to initialize the CSV header
    public B2B_ProductImageBatch() {
        finalCsvData += generateCsvHeader();
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
        String batchCsvData = '';

        Integer MAX_IMAGE_NUMBER = 9;

        for (Product2 prod : scope) {
            // Skip the product if prod.B2B_Image_URLs__c is blank
            if (String.isBlank(prod.B2B_Image_URLs__c))
                continue;

            String[] imageUrls = prod.B2B_Image_URLs__c.split(',');

            String productRow = prod.Name + ',' + prod.ProductCode + ((imageUrls.size() == 0) ? ',,,' : ',' + prod.ProductCode + ',' + prod.Name + ',' + imageUrls[0]);

            // Append the media listings and standard media details
            for (Integer i = 0; i < MAX_IMAGE_NUMBER - 1; i++) {
                if (i < imageUrls.size()) {
                    productRow += ',' + prod.ProductCode + ',' + prod.Name + ',' + imageUrls[i];
                } else {
                    productRow += ',,,';
                }
            }

            // Add the constructed row to the batch CSV content
            batchCsvData += productRow + '\n';
        }

        // Append batch data to the final CSV data
        finalCsvData += batchCsvData;
    }

    // The finish method is called after all batches are processed
    public void finish(Database.BatchableContext BC) {
        // Save the final CSV content to a file
        saveCSVToFile(finalCsvData);
    }

    // Helper method to generate the CSV header
    private String generateCsvHeader() {
        Integer MAX_IMAGE_NUMBER = 9;
        String csvHeader = 'Product Name,ProductCode,Media Listing Title,Media Listing AltText,Media Listing URL';
        String mediaHeader = ',Media Standard Title {0},Media Standard AltText {0},Media Standard Url {0}';

        for (Integer i = 1; i < MAX_IMAGE_NUMBER; i++) {
            csvHeader += String.format(mediaHeader, new List<String>{ String.valueOf(i) });
        }
        csvHeader += '\n';

        return csvHeader;
    }

    // Method to save the CSV data as a file in ContentVersion
    public void saveCSVToFile(String csvData) {
        String fileName;

        fileName = 'B2B_Product_Image_URLs_' + String.valueOf(DateTime.now()) + ((isDaily)? '_Daily': '_Monthly');

        ContentVersion cv = new ContentVersion();
        ContentWorkspace[] cvps = [SELECT Id, Name, DeveloperName FROM ContentWorkspace WHERE DeveloperName = :LIBRARY_DEVELOPER_NAME];

        if (!cvps.isEmpty()) {
            cv.FirstPublishLocationId = cvps[0].Id;
        }

        cv.Title = fileName;
        cv.PathOnClient = fileName + '.csv';
        cv.VersionData = Blob.valueOf(csvData);
        cv.Origin = 'H';
        insert cv;
    }
}
