public without sharing class B2B_ProductImageHelper {
    private static String LIBRARY_DEVELOPER_NAME = 'B2B_Storefront_Admin';
    public static String generateImageURLsCSV(String initialCsvHeader) {
        String csvContent = '';
        Integer MAX_IMAGE_NUMBER = 9;
        // Query the Product2 object for necessary fields
        List<Product2> products = [
            SELECT Id, ProductCode, Name, B2B_Image_URLs__c
            FROM Product2
            WHERE B2B_Image_Present__c = FALSE 
            AND  B2B_Product_Type__c IN ('Parts','Whole_Goods')
            // LIMIT 10
        ];

        // Initialize CSV String with headers
        String csvHeader = 'Product Name,ProductCode,Media Listing Title,Media Listing AltText,Media Listing URL';
        String mediaHeader = ',Media Standard Title {0},Media Standard AltText {0},Media Standard Url {0}';
        for (Integer i = 1; i < MAX_IMAGE_NUMBER; i++) {
            csvHeader += string.format(mediaHeader, new List<string>{ String.valueOf(i) });
        }
        csvHeader += '\n';

        for (Product2 prod : products) {
            // TODO skip the product if prod.B2B_Image_URLs__c is blank

            String[] imageUrls = (String.isBlank(prod.B2B_Image_URLs__c)) ? new List<String>() : prod.B2B_Image_URLs__c.split(',');
            // String productRow = '"' + prod.Name + '","' + prod.ProductCode + '"';
            String productRow = prod.Name + ',' + prod.ProductCode + ((imageUrls.size() == 0) ? ',,,' : ',' + prod.ProductCode + ',' + prod.Name + ',' + imageUrls[0]);

            // Append the media listings and standard media details
            for (Integer i = 0; i < MAX_IMAGE_NUMBER-1; i++) {
                if (i < imageUrls.size()) {
                    //productRow += ',"' + prod.ProductCode + '","' + prod.Name + '","' + imageUrls[i] + '"';
                    productRow += ',' + prod.ProductCode + ',' + prod.Name + ',' + imageUrls[i];
                } else {
                    // productRow += ',"","",""';
                    productRow += ',,,';
                }
            }
            // Add the constructed row to the CSV content
            csvContent += productRow + '\n';
            system.debug(productRow);
        }

        // Return the full CSV as a string
        return csvHeader + csvContent;
    }

    public static void saveCSVToFile(String csvData, String fileName) {
        if(String.isBlank(fileName)) fileName = 'B2B_Product_Image_URLs_' + String.valueOf(DateTime.now()) + '_Daily';
        ContentVersion cv = new ContentVersion();
        ContentWorkspace[] cvps = [SELECT Id, Name, DeveloperName FROM ContentWorkspace WHERE DeveloperName = :LIBRARY_DEVELOPER_NAME];
        if(!cvps.isEmpty()) cv.FirstPublishLocationId = cvps[0].Id;
        cv.Title = fileName;
        cv.PathOnClient = fileName + '.csv';
        cv.VersionData = Blob.valueOf(csvData);
        cv.Origin = 'H';
        insert cv;
    }
}
