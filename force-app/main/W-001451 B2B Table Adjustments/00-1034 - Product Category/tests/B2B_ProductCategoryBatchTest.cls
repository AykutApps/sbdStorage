@isTest
public with sharing class B2B_ProductCategoryBatchTest {
    @TestSetup
    public static void makeData() {
        Product2 productRecord1 = TestData_Product2.createSingleProduct();
        TestData_Order.createRetailPricebookEntries(new List<Product2>{ productRecord1 }, true);

        ProductCatalog c = new ProductCatalog(Name = 'B2B Dealer Community Catalog');
        insert c;

        insert new List<ProductCategory>{
            new ProductCategory(Name = 'Parts', CatalogId = c.Id),
            new ProductCategory(Name = 'Products', CatalogId = c.Id),
            new ProductCategory(Name = 'Whole Goods', CatalogId = c.Id),
            new ProductCategory(Name = 'Belts', CatalogId = c.Id),
            new ProductCategory(Name = 'Handheld', CatalogId = c.Id)
        };
    }

    @isTest
    public static void testB2B_ProductCategoryBatch() {
        Product2 p = [
            SELECT Id, B2B_Product_Type__c, Commerce_JSON__c, (SELECT Id, IsPrimaryCategory, ProductCategory.Name FROM ProductCategoryProducts)
            FROM Product2
            LIMIT 1
        ];
        p.Commerce_JSON__c = '[{"category":"Belts"}]';
        p.B2B_Product_Type__c = 'Parts';
        update p;

        Test.startTest();
        B2B_ProductCategoryBatch b = new B2B_ProductCategoryBatch();
        Id BatchProcessId = Database.executeBatch(b, 200);
        Test.stopTest();

        List<ProductCategoryProduct> pcps = [SELECT Id, ProductId, ProductCategoryId FROM ProductCategoryProduct WHERE ProductId = :p.Id];
        System.assertEquals(1, pcps.size());
    }
}
