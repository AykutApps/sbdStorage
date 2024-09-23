@isTest
public class B2B_ProductImageHelperTest {
    @testSetup
    static void setupTestData() {
        // Create test products with and without image URLs
        List<Product2> products = new List<Product2>();

        products.add(new Product2(Name = 'P001', ProductCode = 'P001', B2B_Image_URLs__c = 'http://example.com/image1.jpg,http://example.com/image2.jpg'));
        products.add(new Product2(Name = 'P002', ProductCode = 'P002', B2B_Image_URLs__c = 'http://example.com/image3.jpg'));
        products.add(new Product2(Name = 'P003', ProductCode = 'P003', B2B_Image_URLs__c = null)); // No images

        insert products;
    }

    @isTest
    static void testGenerateCsvHeader() {
        // Call the method to generate the CSV header
        String expectedHeader = 'Product Name,ProductCode,Media Listing Title,Media Listing AltText,Media Listing URL';
        for (Integer i = 1; i < 9; i++) {
            expectedHeader += ',Media Standard Title ' + i + ',Media Standard AltText ' + i + ',Media Standard Url ' + i;
        }
        expectedHeader += '\n';

        Test.startTest();
        String header = B2B_ProductImageHelper.generateCsvHeader();
        Test.stopTest();

        system.debug('expectedHeader');
        system.debug(expectedHeader);

        system.debug('header');
        system.debug(header);

        // Verify the CSV header matches the expected structure
        System.assertEquals(expectedHeader, header, 'The CSV header generated is incorrect.');
    }

    @isTest
    static void testGenerateCsvRows() {
        // Fetch test products
        List<Product2> products = [SELECT Id, Name, ProductCode, B2B_Image_URLs__c FROM Product2];

        Test.startTest();
        // Call the method to generate CSV rows
        String csvData = B2B_ProductImageHelper.generateCsvRows(products);
        Test.stopTest();

        system.debug('csvData');
        system.debug(csvData);
        system.debug(csvData.contains('P001,P001,P001,P001,http://example.com/image1.jpg'));

        // Verify that the CSV contains data only for products with image URLs
        System.assert(csvData.contains('P001,P001,P001,P001,http://example.com/image1.jpg'), 'Test Product 1 CSV data is incorrect.');
        // P001,P001,P001,P001,http://example.com/image1.jpg,P001,P001,http://example.com/image1.jpg,P001,P001,http://example.com/image2.jpg,,,,,,,,,,,,,,,,,,
        System.assert(csvData.contains('P002,P002,P002,P002,http://example.com/image3.jpg'), 'Test Product 2 CSV data is incorrect.');
        System.assert(!csvData.contains('P003'), 'Test Product 3 should not be included in the CSV data.');
    }

    @isTest
    static void testSaveCSVToFile() {
        // Create dummy CSV data
        String csvData =
            'Product Name,ProductCode,Media Listing Title,Media Listing AltText,Media Listing URL\n' + 'Test Product 1,P001,P001,Test Product 1,http://example.com/image1.jpg\n';

        Test.startTest();
        // Call the method to save the CSV to a file
        B2B_ProductImageHelper.saveCSVToFile(csvData, 'B2B_Storefront_Admin', true);
        Test.stopTest();

        // Verify the file was saved as a ContentVersion
        ContentVersion[] contentVersions = [SELECT Id, Title, VersionData FROM ContentVersion WHERE Title LIKE 'B2B_Product_Image_URLs_%'];
        System.assert(contentVersions.size() > 0, 'ContentVersion file was not created.');
        System.assert(contentVersions[0].Title.contains('B2B_Product_Image_URLs'), 'File name is incorrect.');
    }
}
