@isTest
public with sharing class B2B_ProductCategoryHelperTest {
    @TestSetup
    public static void makeData() {
        Product2 productRecord = TestData_Product2.createSingleProduct();
        TestData_Order.createRetailPricebookEntries(new List<Product2>{ productRecord }, true);
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
    public static void testAdjustProductCategoriesParts() {
        Product2 p = [
            SELECT Id, B2B_Product_Type__c, Commerce_JSON__c, (SELECT Id, IsPrimaryCategory, ProductCategory.Name FROM ProductCategoryProducts)
            FROM Product2
            LIMIT 1
        ];
        p.Commerce_JSON__c = '[{"category":"Belts"}]';
        p.B2B_Product_Type__c = 'Parts';
        update p;

        B2B_ProductCategoryHelper.adjustProductCategories(new Set<Id>{ p.Id });

        List<ProductCategoryProduct> pcps = [SELECT Id, ProductId, ProductCategoryId FROM ProductCategoryProduct WHERE ProductId = :p.Id];
        System.assertEquals(3, pcps.size());
    }

    @isTest
    public static void testAdjustProductCategoriesPartsHandheld() {
        Product2 p = [
            SELECT Id, B2B_Product_Type__c, Commerce_JSON__c, (SELECT Id, IsPrimaryCategory, ProductCategory.Name FROM ProductCategoryProducts)
            FROM Product2
            LIMIT 1
        ];
        p.Commerce_JSON__c = '[{"category":"Handheld"}]';
        p.B2B_Product_Type__c = 'Parts';
        update p;

        B2B_ProductCategoryHelper.adjustProductCategories(new Set<Id>{ p.Id });

        List<ProductCategoryProduct> pcps = [SELECT Id, ProductId, ProductCategoryId FROM ProductCategoryProduct WHERE ProductId = :p.Id];
        System.assertEquals(2, pcps.size());
    }

    @isTest
    public static void testAdjustProductCategoriesWholeGoods() {
        Product2 p = [
            SELECT Id, B2B_Product_Type__c, Commerce_JSON__c, (SELECT Id, IsPrimaryCategory, ProductCategory.Name FROM ProductCategoryProducts)
            FROM Product2
            LIMIT 1
        ];
        p.Commerce_JSON__c = '[{"category":"Belts"}]';
        p.B2B_Product_Type__c = 'Whole Goods';
        update p;

        B2B_ProductCategoryHelper.adjustProductCategories(new Set<Id>{ p.Id });

        List<ProductCategoryProduct> pcps = [SELECT Id, ProductId, ProductCategoryId FROM ProductCategoryProduct WHERE ProductId = :p.Id];
        System.assertEquals(2, pcps.size());
    }

    @isTest
    public static void testAdjustProductCategoriesProducts() {
        Product2 p = [
            SELECT Id, B2B_Product_Type__c, Commerce_JSON__c, (SELECT Id, IsPrimaryCategory, ProductCategory.Name FROM ProductCategoryProducts)
            FROM Product2
            LIMIT 1
        ];
        p.B2B_Product_Type__c = null;
        update p;

        B2B_ProductCategoryHelper.adjustProductCategories(new Set<Id>{ p.Id });

        List<ProductCategoryProduct> pcps = [SELECT Id, ProductId, ProductCategoryId, ProductCategory.Name FROM ProductCategoryProduct WHERE ProductId = :p.Id];
        System.assertEquals(1, pcps.size());
        System.assertEquals('Products', pcps[0].ProductCategory.Name);
    }
}
