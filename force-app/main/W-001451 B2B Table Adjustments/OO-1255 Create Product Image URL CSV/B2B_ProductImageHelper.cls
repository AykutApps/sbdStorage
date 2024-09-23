public class B2B_ProductImageHelper {
    private static final Integer MAX_IMAGE_NUMBER = 9;

    // Method to generate the CSV header
    public static String generateCsvHeader() {
        String csvHeader = 'Product Name,ProductCode,Media Listing Title,Media Listing AltText,Media Listing URL';
        String mediaHeader = ',Media Standard Title {0},Media Standard AltText {0},Media Standard Url {0}';

        for (Integer i = 1; i < MAX_IMAGE_NUMBER; i++) {
            csvHeader += String.format(mediaHeader, new List<String>{ String.valueOf(i) });
        }
        csvHeader += '\n';

        return csvHeader;
    }

    // Method to create CSV rows for each product
    public static String generateCsvRows(List<Product2> products) {
        String batchCsvData = '';

        for (Product2 prod : products) {
            system.debug('xxx - product');
            system.debug(prod);
            // Skip the product if no image URLs are present
            if (String.isBlank(prod.B2B_Image_URLs__c))
                continue;

            String[] imageUrls = prod.B2B_Image_URLs__c.split(',');

            String productRow = prod.Name + ',' + prod.ProductCode + ((imageUrls.size() == 0) ? ',,,' : ',' + prod.ProductCode + ',' + prod.Name + ',' + imageUrls[0]);

            // Append media listings and standard media details
            for (Integer i = 0; i < MAX_IMAGE_NUMBER - 1; i++) {
                if (i < imageUrls.size()) {
                    productRow += ',' + prod.ProductCode + ',' + prod.Name + ',' + imageUrls[i];
                } else {
                    productRow += ',,,';
                }
            }

            system.debug('xxx - productRow');
            system.debug(productRow);

            // Add the constructed row to the batch CSV content
            batchCsvData += productRow + '\n';
        }

        return batchCsvData;
    }

    // Method to save CSV data as a ContentVersion file
    public static void saveCSVToFile(String csvData, String libraryDeveloperName, Boolean isDaily) {
        String fileName = 'B2B_Product_Image_URLs_' + String.valueOf(DateTime.now()) + ((isDaily) ? '_Daily' : '_Monthly');

        ContentVersion cv = new ContentVersion();
        ContentWorkspace[] cvps = [SELECT Id, Name, DeveloperName FROM ContentWorkspace WHERE DeveloperName = :libraryDeveloperName];

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
