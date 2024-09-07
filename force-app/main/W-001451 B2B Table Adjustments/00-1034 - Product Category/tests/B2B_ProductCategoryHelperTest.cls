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
    public static void testAdjustProductCategoriesPartsHandheldCheckedTrue() {
        Product2 p = [
            SELECT Id, B2B_Product_Type__c, Commerce_JSON__c, (SELECT Id, IsPrimaryCategory, ProductCategory.Name FROM ProductCategoryProducts)
            FROM Product2
            LIMIT 1
        ];
        p.B2B_Product_Type__c = 'Parts';
        p.B2B_Handheld_Override__c = true;
        update p;

        B2B_ProductCategoryHelper.adjustProductCategories(new Set<Id>{ p.Id });

        List<ProductCategoryProduct> pcps = [SELECT Id, ProductId, ProductCategoryId FROM ProductCategoryProduct WHERE ProductId = :p.Id];
        // System.assertEquals(3, pcps.size());
        System.assertEquals(1, pcps.size());

    }

    @isTest
    public static void testAdjustProductCategoriesPartsHandheld_sectionIsBlank() {
        //if Product2.Section__c is blank, verify helper sets to 'Handheld'

        Product2 p = [
            SELECT Id, RecordTypeId, B2B_Product_Type__c, Section__c, Commerce_JSON__c, (SELECT Id, IsPrimaryCategory, ProductCategory.Name FROM ProductCategoryProducts)
            FROM Product2
            LIMIT 1
        ];
        p.RecordTypeId = RecordTypes.product_Part.Id;
        p.Section__c = ''; //clear value to make sure the helper sets it
        p.Commerce_JSON__c = '[{"category":"Handheld"}]';
        p.B2B_Product_Type__c = 'Parts';
        update p;

        B2B_ProductCategoryHelper.adjustProductCategories(new Set<Id>{ p.Id });

        List<ProductCategoryProduct> pcps = [SELECT Id, ProductId, ProductCategoryId FROM ProductCategoryProduct WHERE ProductId = :p.Id];
        System.assertEquals(1, pcps.size());

        //mburr.2024-07-19 verify Product2.Section__c is 'Handheld' for a Part record-type that is missing a section
        Product2 v = [SELECT Id, RecordTypeId, Section__c FROM Product2 WHERE Id = :p.Id];
        System.assertEquals('Handheld', v.Section__c);
    }

    @isTest
    public static void testAdjustProductCategoriesPartsHandheld_sectionIsNotBlank() {
        //if Product2.Section__c has a value, verify helper DOES NOT set it to 'Handheld'  #DontBreakPSO
        string expectedSection = 'DW Chainsaw';

        Product2 p = [
            SELECT Id, RecordTypeId, B2B_Product_Type__c, Section__c, Commerce_JSON__c, (SELECT Id, IsPrimaryCategory, ProductCategory.Name FROM ProductCategoryProducts)
            FROM Product2
            LIMIT 1
        ];
        p.RecordTypeId = RecordTypes.product_Part.Id;
        p.Section__c = expectedSection; //business may set the section on handhelds for the CRM PSO Order Form (Whole Goods Only)
        p.Commerce_JSON__c = '[{"category":"Handheld"}]';
        p.B2B_Product_Type__c = 'Parts';
        update p;

        B2B_ProductCategoryHelper.adjustProductCategories(new Set<Id>{ p.Id });

        List<ProductCategoryProduct> pcps = [SELECT Id, ProductId, ProductCategoryId FROM ProductCategoryProduct WHERE ProductId = :p.Id];
        System.assertEquals(1, pcps.size());

        //mburr.2024-07-19 verify Product2.Section__c is 'Handheld' for a Part record-type that is missing a section
        Product2 v = [SELECT Id, RecordTypeId, Section__c FROM Product2 WHERE Id = :p.Id];
        System.assertEquals(expectedSection, v.Section__c);
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
        // System.assertEquals(3, pcps.size());
        System.assertEquals(1, pcps.size());
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
        // System.assertEquals(2, pcps.size());
        System.assertEquals(1, pcps.size());
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
        // System.assertEquals(2, pcps.size());
        System.assertEquals(1, pcps.size());
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
        // System.assertEquals(1, pcps.size());
        System.assertEquals(0, pcps.size());
        // System.assertEquals('Products', pcps[0].ProductCategory.Name);
    }
}
