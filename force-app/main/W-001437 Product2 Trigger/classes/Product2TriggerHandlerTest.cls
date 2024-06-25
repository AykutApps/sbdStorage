/**
 * Test class for the Product2Master.trigger and Product2TriggerHandler class
 *
 * @author Scott Askegard
 * @date 3/30/2016
 */
@isTest
private class Product2TriggerHandlerTest {
    public static String delimiter = '|';

    @isTest 
    static void testInsertProduct() {
        TestData_Product2.createRetailPriceBook();
        TestData_Product2.shouldInsert = false;
        Product2 productRecord = TestData_Product2.createSingleProduct();
        productRecord.Name = '';
        
        Test.startTest();
            insert productRecord;
        Test.stopTest();

        Product2 testProductRecord = [select ID, Name, Detail_SKU__c, Composite_Key__c, Brand__c, Group__c, Category__c, Family from Product2 Limit 1];
        System.assertEquals(testProductRecord.Detail_SKU__c, testProductRecord.Name);
        System.assertEquals(testProductRecord.Composite_Key__c, testProductRecord.Brand__c + delimiter + testProductRecord.Group__c + delimiter + testProductRecord.Category__c + delimiter + testProductRecord.Family);
    }

    @isTest
    static void testUpdateProduct() {
        TestData_Product2.createRetailPriceBook();
        TestData_Product2.shouldInsert = false;

        Id standardPbeId = Test.getStandardPricebookId();
        
        Product2 productRecord = TestData_Product2.createSingleProduct();
        insert productRecord;
        List<Product2> prods = new List<Product2>{productRecord};
        TestData_Order.createStandardPricebookEntries(prods);

        productRecord.Detail_SKU__c = 'CC 40';
        productRecord.Production_Date__c = Date.today().addDays(-4);
        productRecord.Retail_Price_US__c = 15;
        
        Test.startTest();
            update productRecord;
        Test.stopTest();

        Product2 testProductRecord = [select ID, Name, Detail_SKU__c from Product2 Limit 1];
        System.assertEquals('CC 40', testProductRecord.Name);
    }

    @isTest
    static void testDeleteProduct() {
        TestData_Product2.createRetailPriceBook();
        Product2 productRecord = TestData_Product2.createSingleProduct();

        Test.startTest();
            delete productRecord;
        Test.stopTest();

        System.assert([select count() from Product2] == 0);
    }

    @isTest 
    static void createGenericProduct() {
        ID desiredRecordTypeID = RecordTypes.product_Generic.ID; 
        Decimal desiredBizDiv = 0;
        
        Product2 productRecord = new Product2();
        productRecord.RecordTypeID = desiredRecordTypeID;
        productRecord.Name = '';
        productRecord.ProductCode = 'testGeneric';
        productRecord.Detail_SKU__c = 'testGeneric';
        productRecord.Generic_Product_Category__c = 'Other';
        productRecord.Family = null;
        
        Test.startTest();
            insert productRecord;
        Test.stopTest();

        Product2 testProductRecord = [select ID, Name, Detail_SKU__c, Composite_Key__c, Brand__c, Group__c, Category__c, Family
                                      , RecordTypeID, ProductCode, Product_Code_External_ID__c, Business_Division__c, Dealer_Types__c 
                                      from Product2 where ID = :productRecord.id];
        System.assertEquals(desiredRecordTypeID,testProductRecord.RecordTypeID);
        System.assertEquals(testProductRecord.ProductCode, testProductRecord.Name);
        System.assertEquals(productRecord.ProductCode, testProductRecord.ProductCode);
        System.assertEquals(desiredBizDiv,testProductRecord.Business_Division__c);
        System.assertEquals('GEN-' + testProductRecord.ProductCode.toUpperCase(), testProductRecord.Product_Code_External_ID__c);
        System.assertEquals(true, String.isBlank(testProductRecord.Dealer_Types__c));
    }
    @isTest 
    static void createEDWManagedProduct() {
        ID desiredRecordTypeID = RecordTypes.product_FinishedGoodsFromEDW.ID; 
        Decimal desiredBizDiv = 1;
        
        Product2 productRecord = new Product2();
        productRecord.RecordTypeID = desiredRecordTypeID;
        productRecord.Name = '';
        productRecord.ProductCode = 'testEDWManaged';
        productRecord.Family = null;
        
        Test.startTest();
            insert productRecord;
        Test.stopTest();

        Product2 testProductRecord = [select ID, Name, Detail_SKU__c, Composite_Key__c, Brand__c, Group__c, Category__c, Family
                                      , RecordTypeID, ProductCode, Product_Code_External_ID__c, Business_Division__c, Dealer_Types__c 
                                      from Product2 where ID = :productRecord.id];
        System.assertEquals(desiredRecordTypeID,testProductRecord.RecordTypeID);
        System.assertEquals(testProductRecord.ProductCode, testProductRecord.Name);
        System.assertEquals(productRecord.ProductCode.toUpperCase(), testProductRecord.ProductCode);
        System.assertEquals(desiredBizDiv,testProductRecord.Business_Division__c);
        System.assertEquals(testProductRecord.ProductCode, testProductRecord.Product_Code_External_ID__c);
        System.assertEquals(true, String.isBlank(testProductRecord.Dealer_Types__c));
    }
    @isTest 
    static void createOtherProduct() {
        ID desiredRecordTypeID = RecordTypes.product_Other.ID; 
        
        Product2 productRecord = new Product2();
        productRecord.RecordTypeID = desiredRecordTypeID;
        productRecord.Name = '';
        productRecord.ProductCode = 'testOther';
        
        Test.startTest();
            insert productRecord;
        Test.stopTest();

        Product2 testProductRecord = [select ID, Name, Detail_SKU__c, Composite_Key__c, Brand__c, Group__c, Category__c, Family
                                      , RecordTypeID, ProductCode, Product_Code_External_ID__c, Business_Division__c, Dealer_Types__c 
                                      from Product2 where ID = :productRecord.id];
        System.assertEquals(desiredRecordTypeID,testProductRecord.RecordTypeID);
        System.assertEquals(testProductRecord.ProductCode, testProductRecord.Name);
        System.assertEquals(productRecord.ProductCode.toUpperCase(), testProductRecord.ProductCode);
        //Business_Division__c can be anything for "Other" products
        System.assertEquals('OTH-' + testProductRecord.ProductCode, testProductRecord.Product_Code_External_ID__c);
        System.assertEquals(true, String.isBlank(testProductRecord.Dealer_Types__c));
    }
    @isTest 
    static void createOtherProductIfNoIRFamily() {
        ID desiredRecordTypeID = RecordTypes.product_Other.ID; 

        Product2 productRecord = new Product2();
        productRecord.Name = '';
        productRecord.ProductCode = 'testOtherNoRT';
        
        Test.startTest();
            insert productRecord;
        Test.stopTest();

        Product2 testProductRecord = [select ID, Name, Detail_SKU__c, Composite_Key__c, Brand__c, Group__c, Category__c, Family
                                      , RecordTypeID, ProductCode, Product_Code_External_ID__c, Business_Division__c, Dealer_Types__c 
                                      from Product2 where ID = :productRecord.id];
        System.assertEquals(desiredRecordTypeID,testProductRecord.RecordTypeID);
        System.assertEquals(testProductRecord.ProductCode, testProductRecord.Name);
        System.assertEquals(productRecord.ProductCode.toUpperCase(), testProductRecord.ProductCode);
        //Business_Division__c can be anything for "Other" products
        System.assertEquals('OTH-' + testProductRecord.ProductCode, testProductRecord.Product_Code_External_ID__c);
        System.assertEquals(true, String.isBlank(testProductRecord.Dealer_Types__c));
    }
    @isTest 
    static void createWholeGoodIfIRFamily() {
        ID desiredRecordTypeID = RecordTypes.product_WholeGood.ID; 
        Decimal desiredBizDiv = 1;
        
        Product2 productRecord = new Product2();
        productRecord.RecordTypeID = desiredRecordTypeID; //mburr 2018-06: you must specify record-type when creating attachments due to trigger change
        productRecord.Name = '';
        productRecord.Detail_SKU__c = 'WGSKU';
        productRecord.ProductCode = 'testWG';
        productRecord.Brand__c = 'Cub';
        productRecord.Group__c = 'Core';
        productRecord.Category__c = 'Rider';
        productRecord.Family = 'Lawn Tractor';
        productRecord.Series__c = 'XT 2';
        productRecord.Engine_Type__c = 'Kohler';
        
        Test.startTest();
            insert productRecord;
        Test.stopTest();

        Product2 testProductRecord = [select ID, Name, Detail_SKU__c, Composite_Key__c, Brand__c, Group__c, Category__c, Family
                                      , RecordTypeID, ProductCode, Product_Code_External_ID__c, Business_Division__c, Dealer_Types__c 
                                      from Product2 where ID = :productRecord.id];
        System.assertEquals(desiredRecordTypeID,testProductRecord.RecordTypeID);
        System.assertEquals(testProductRecord.Detail_SKU__c, testProductRecord.Name);
        System.assertEquals(productRecord.ProductCode.toUpperCase(), testProductRecord.ProductCode);
        System.assertEquals(testProductRecord.ProductCode, testProductRecord.Product_Code_External_ID__c);
        System.assertEquals(desiredBizDiv,testProductRecord.Business_Division__c);
        System.assertEquals(false, String.isBlank(testProductRecord.Dealer_Types__c));
    }
    @isTest 
    static void createAttachmentIfIRFamilyIsAttachment() {
        ID desiredRecordTypeID = RecordTypes.product_Attachment.ID; 
        Decimal desiredBizDiv = 1;
        
        Product2 productRecord = new Product2();
        productRecord.RecordTypeID = desiredRecordTypeID; //mburr 2018-06: you must specify record-type when creating attachments due to trigger change
        productRecord.Name = '';
        productRecord.Detail_SKU__c = 'WGSKU';
        productRecord.ProductCode = 'testWG';
        productRecord.Family = 'Attachment';
        
        Test.startTest();
            insert productRecord;
        Test.stopTest();

        Product2 testProductRecord = [select ID, Name, Detail_SKU__c, Composite_Key__c, Brand__c, Group__c, Category__c, Family
                                      , RecordTypeID, ProductCode, Product_Code_External_ID__c, Business_Division__c, Dealer_Types__c 
                                      from Product2 where ID = :productRecord.id];
        System.assertEquals(desiredRecordTypeID,testProductRecord.RecordTypeID);
        System.assertEquals(testProductRecord.Detail_SKU__c, testProductRecord.Name);
        System.assertEquals(productRecord.ProductCode.toUpperCase(), testProductRecord.ProductCode);
        System.assertEquals(testProductRecord.ProductCode, testProductRecord.Product_Code_External_ID__c);
        System.assertEquals(desiredBizDiv,testProductRecord.Business_Division__c);
        System.assertEquals(false, String.isBlank(testProductRecord.Dealer_Types__c));
    }
    @isTest 
    static void testCalculatedDisplayedProductionOverrideDate() {
        Date productionDate = Date.newInstance(2018,1,26); //friday
        Date expectedDisplayedProductionDate = Date.newInstance(2018,1,30); //following Tuesday (friday + 2 biz days)
        Decimal desiredBizDiv = 1;
        
        Product2 productRecord = new Product2();
        productRecord.RecordTypeID = RecordTypes.product_WholeGood.ID;
        productRecord.Name = '';
        productRecord.Detail_SKU__c = 'WGSKU2';
        productRecord.ProductCode = 'testWG2';
        productRecord.Brand__c = 'Cub';
        productRecord.Group__c = 'Core';
        productRecord.Category__c = 'Rider';
        productRecord.Family = 'Lawn Tractor';
        productRecord.Series__c = 'XT 2';
        productRecord.Engine_Type__c = 'Kohler';
        insert productRecord;
        
        Test.startTest();
        //set production-override
        productRecord.Production_Override__c = true;
        productRecord.Production_Quantity__c = 10;
        productRecord.Production_Date__c = productionDate;
        update productRecord;
        Test.stopTest();

        Product2 testProductRecord = [select ID, Name, Detail_SKU__c, Composite_Key__c, Brand__c, Group__c, Category__c, Family
                                      , RecordTypeID, ProductCode, Product_Code_External_ID__c, Business_Division__c
                                      , Production_Date__c, Displayed_Production_Override_Date__c
                                      from Product2 where ID = :productRecord.id];
        System.assertEquals(expectedDisplayedProductionDate,testProductRecord.Displayed_Production_Override_Date__c);		
    }
    @isTest 
    static void testExternalIDForRecTypeGeneric() {
		String lowerPCode = 'aaBBccDDeeFFGEN'; //15 characters
		String expectedExternalID = 'GEN-'+lowerPCode.toUpperCase(); //19 characters with GEN- prefix
        ID genericRecTypeID = RecordTypes.product_Generic.ID; 
        
        TestData_Product2.shouldInsert = false;
        Product2 p = TestData_Product2.createGenericOtherProduct();
        p.ProductCode = lowerPCode;
        
        Test.startTest();
        insert p;
        p = [SELECT ID, ProductCode, Product_Code_External_ID__c FROM Product2 WHERE ID = :p.ID];
        System.assert(lowerPCode.equals(p.ProductCode)); //generic ProductCode s/b upper lower 
        System.assert(expectedExternalID.equals(p.Product_Code_External_ID__c));//s/b all upper case; string.equals(...) is case sensitive
    }
    @isTest 
    static void testExternalIDForRecTypeWholeGood() {
		String lowerPCode = 'aaBBccDDeeFFgWG'; //15 characters
		String expectedExternalID = lowerPCode.toUpperCase();
        ID irWholeGoodRecTypeID = RecordTypes.product_WholeGood.ID; 
        
        TestData_Product2.shouldInsert = false;
        Product2 p = TestData_Product2.createSingleProduct(irWholeGoodRecTypeID);
        p.ProductCode = lowerPCode;
        
        Test.startTest();
        insert p;
        p = [SELECT ID, ProductCode, Product_Code_External_ID__c FROM Product2 WHERE ID = :p.ID];
        System.assert(lowerPCode.toUpperCase().equals(p.ProductCode)); 
        System.assert(expectedExternalID.equals(p.Product_Code_External_ID__c));//s/b all upper case; string.equals(...) is case sensitive
    }
    @isTest 
    static void testExternalIDForRecTypeEDWFinishedGoods() {
		String lowerPCode = 'aaBBccDDeeFFEDW'; //15 characters
		String expectedExternalID = lowerPCode.toUpperCase();
        ID edwFinishedGoodsRecTypeID = RecordTypes.product_FinishedGoodsFromEDW.ID; 
        
        TestData_Product2.shouldInsert = false;
        Product2 p = TestData_Product2.createSingleProduct(edwFinishedGoodsRecTypeID);
        p.ProductCode = lowerPCode;

        Test.startTest();
        insert p;
        p = [SELECT ID, ProductCode, Product_Code_External_ID__c FROM Product2 WHERE ID = :p.ID];
        System.assert(lowerPCode.toUpperCase().equals(p.ProductCode)); 
        System.assert(expectedExternalID.equals(p.Product_Code_External_ID__c));//s/b all upper case; string.equals(...) is case sensitive
    }
    @isTest 
    static void testExternalIDForRecTypeOther() {
		String lowerPCode = 'aaBBccDDeeFFOTH'; //15 characters
		String expectedExternalID = 'OTH-'+lowerPCode.toUpperCase(); //19 characters with OTH- prefix
        ID otherRecTypeID = RecordTypes.product_Other.ID;
        
        TestData_Product2.shouldInsert = false;
        Product2 p = TestData_Product2.createSingleProduct(otherRecTypeID);
        p.ProductCode = lowerPCode;
        Test.startTest();
        insert p;
        p = [SELECT ID, ProductCode, Product_Code_External_ID__c, RecordTypeID FROM Product2 WHERE ID = :p.ID];
        System.assert(lowerPCode.toUpperCase().equals(p.ProductCode)); 
        System.assert(expectedExternalID.equals(p.Product_Code_External_ID__c));//s/b all upper case; string.equals(...) is case sensitive
    }
    @isTest 
    static void testPreventDuplicateProductConstraint() {
		//verifies that the unique constraint indirectly built against Product2.ProductCode works.  
		//A trigger sets the unique-key Product_Code_External_ID__c when ProductCodeis changed.
        String productCodeWinner = 'aaBBccDDeeDUPE'; 
		String productCodeDupe   = 'aaBBccDDeeDUPE'; 

        TestData_Product2.shouldInsert = false;
        ID irWholeGoodRecTypeID = RecordTypes.product_WholeGood.ID; 

        Product2 w = TestData_Product2.createSingleProduct(irWholeGoodRecTypeID);
        w.ProductCode = productCodeWinner;
        insert w;
        
        Product2 dupe = TestData_Product2.createSingleProduct(irWholeGoodRecTypeID);
        dupe.ProductCode = productCodeDupe;

        Test.startTest();
		boolean dupeInsertFailed = false;
        try{
            insert dupe;
        } catch (Exception ex){
            dupeInsertFailed = true;
        }
        Test.stopTest();
        
        Product2 productInDB = [SELECT ID, ProductCode FROM Product2 WHERE ProductCode = :productCodeWinner];

        System.assertEquals(w.ID,productInDB.ID);
        System.assertEquals(null,dupe.ID);
        System.assertEquals(true,dupeInsertFailed);
    }    
    @isTest 
    static void testProductCodeIsRequiredTriggerLogic() {
        TestData_Product2.shouldInsert = false;
        ID irWholeGoodRecTypeID = RecordTypes.product_WholeGood.ID; 

        Product2 w = TestData_Product2.createSingleProduct(irWholeGoodRecTypeID);
        w.ProductCode = null;

        Test.startTest();
        boolean insertFailed = false;
        try{
system.debug('xxx-w B4 INS-'+w);
            insert w;
system.debug('xxx-w AFT INS-'+w);
        } catch (Exception ex){
system.debug('xxx-ex-'+ex);
            if(ex.getMessage().contains('MTDException')){
                insertFailed = true;
            }
        }
        Test.stopTest();
        System.assertEquals(null,w.ID);
        System.assertEquals(true,insertFailed);
    }

    // When a product with no ProductRegion child records becomes inactive, return no error
    static testMethod void testProductBecomesInactive_NoChild() {
        Boolean expectedResult = false;

        Product2 testProduct = TestData_Product2.createSingleProduct();

        Test.startTest();
        testProduct.isActive = false;
        Update testProduct;
        Test.stopTest();

        Product2 resultProduct = [SELECT Id, isActive FROM Product2 WHERE Id = :testProduct.Id];
        System.assertEquals(expectedResult, resultProduct.isActive);
    }
    // When a product with an inactive ProductRegion child record becomes inactive, return no error
    static testMethod void testProductBecomesInactive_InactiveChild() {
        Boolean expectedResult = false;

        TestData_Pricebooks.shouldInsert = false;
        PriceBook2 pb = TestData_Pricebooks.createISRETAILPriceBook('canada test', 'test data setup');
        pb.CurrencyIsoCode = 'CAD';
        Upsert pb;

        Product2 testProduct = TestData_Product2.createSingleProduct();

        TestData_ProductWarehouse.createPW('44', 'CAD', 'Canada');
        
        TestData_ProductRegion.shouldInsert = false;
        Product_Region__c testProductRegion = TestData_ProductRegion.createPR(testProduct, 'CAD');
        testProductRegion.Is_Active__c = false;
        
        Insert testProductRegion;

        Test.startTest();
        testProduct.isActive = false;
        Update testProduct;
        Test.stopTest();

        Product2 resultProduct = [SELECT Id, isActive FROM Product2 WHERE Id = :testProduct.Id];
        System.assertEquals(expectedResult, resultProduct.isActive);
    }
    // When a product with an active ProductRegion child becomes inactive, return an error
    static testMethod void testProductBecomesInactive_ActiveChild() {
        Boolean expectedResult = true;

        TestData_Pricebooks.shouldInsert = false;
        PriceBook2 pb = TestData_Pricebooks.createISRETAILPriceBook('canada test', 'test data setup');
        pb.CurrencyIsoCode = 'CAD';
        Upsert pb;
        
        Product2 testProduct = TestData_Product2.createSingleProduct();

        TestData_ProductWarehouse.createPW('44', 'CAD', 'Canada');
        Product_Region__c testProductRegion = TestData_ProductRegion.createPR(testProduct, 'CAD');

        Test.startTest();
        testProduct.isActive = false;
        try {
            Update testProduct;
            System.assert(false, 'Update should throw error when a child ProductRegion has Is_Active__c set to true');
        } catch(Exception e) {}
        Test.stopTest();

        Product2 resultProduct = [SELECT Id, isActive FROM Product2 WHERE Id = :testProduct.Id];
        System.assertEquals(expectedResult, resultProduct.isActive);
    }
    
    @isTest 
    static void testFulfillFrom_insertUpdate() {
        //mburr.2024-05-07 Agora will populate text(20) field called Product2.Update_Fulfill_From_Text__c.  Trigger will set multiselect picklist Update_Fulfill_From__c
        TestData_Product2.createRetailPriceBook();
        TestData_Product2.shouldInsert = false;
        Product2 productRecord = TestData_Product2.createSingleProduct();
        productRecord.Update_Fulfill_From_Text__c = 'INFOR';
        productRecord.Name = '';
        
        Test.startTest();
            insert productRecord;
        Test.stopTest();

        Product2 testProductRecord = [select ID, Family,Update_Fulfill_From__c,Update_Fulfill_From_Text__c  from Product2 Limit 1];
    	System.assertEquals('INFOR', testProductRecord.Update_Fulfill_From__c);
        System.assertEquals(null, testProductRecord.Update_Fulfill_From_Text__c);
    }
    
    @isTest
    static void testFulfillFrom_update() {
        TestData_Product2.createRetailPriceBook();
        TestData_Product2.shouldInsert = false;
        Id standardPbeId = Test.getStandardPricebookId();
        
        Product2 productRecord = TestData_Product2.createSingleProduct();
        productRecord.Update_Fulfill_From_Text__c = 'INFOR';
        insert productRecord;
        
        productRecord.Update_Fulfill_From_Text__c = 'QAD';
        
        Test.startTest();
            update productRecord;
        Test.stopTest();

        Product2 testProductRecord = [select ID,Update_Fulfill_From__c,Update_Fulfill_From_Text__c  from Product2 Limit 1];
        System.assertEquals('INFOR;QAD', testProductRecord.Update_Fulfill_From__c );
        System.assertEquals(null, testProductRecord.Update_Fulfill_From_Text__c );
    }
}