@isTest
public class Product2HelperTest {
    public static testMethod void shouldReturnProductByFactoryNumber() {
        TestData_Pricebooks.createISRETAILPriceBook();
        Product2 expectedProduct = TestData_Product2.createSingleProduct();
        //13A226JD010
		String factoryNumberToSearchFor = expectedProduct.ProductCode;
        
        Test.startTest();
        Product2Helper ph = new Product2Helper();
        Product2 foundProduct = ph.findProductByFactoryNumber(factoryNumberToSearchFor);
        
        system.assertEquals(expectedProduct.id,foundProduct.id);
        system.assertEquals(expectedProduct.ProductCode,foundProduct.productCode);
        system.assertEquals(expectedProduct.Detail_SKU__c,foundProduct.Detail_SKU__c);
    }
    
    public static testMethod void shouldReturnNullWhenProductNotFound() {
        String factoryNumberToSearchFor = '123 ABC - TEST';
        
        Test.startTest();
        Product2Helper ph = new Product2Helper();
        Product2 foundProduct = ph.findProductByFactoryNumber(factoryNumberToSearchFor);
        system.assertEquals(null,foundProduct);
    }

    public static testMethod void testIsCaliforniaOnlyProduct() {
        TestData_Product2.shouldInsert = false;
        Product2 pCal = TestData_Product2.createSingleProduct();
        pCal.California_Standard__c = 'California Only';
        pCal.Name = 'Test1';
        pCal.ProductCode = '111111';
        pCal.Master_SKU__c = '111111';
        pCal.Detail_SKU__c = '111111';
        pCal.Item_Hierarchy_Id__c = 111;
        insert pCal;

        Product2 pOther = TestData_Product2.createSingleProduct();
        pOther.California_Standard__c = 'TEST';
        pCal.Name = 'Test2';
        pCal.ProductCode = '222222';
        pCal.Master_SKU__c = '222222';
        pCal.Detail_SKU__c = '222222';
        pCal.Item_Hierarchy_Id__c = 222;
        insert pOther;

        System.assertEquals(true, Product2Helper.isCaliforniaOnlyProduct(pCal));
        System.assertEquals(false, Product2Helper.isCaliforniaOnlyProduct(pOther));
    }

    public static testMethod void testSearchProductsByModelNumber(){

        Product2 pCal = TestData_Product2.createSingleProduct();

        Product2Helper p2H = new Product2Helper();

        List<ProductByProductCodeSearchResult> searchResult = p2H.searchProductsByModelNumber('13A226JD010', null, null);

        system.assertEquals(1,searchResult.size());

    }

    public static testMethod void shouldReturnValidFactoryNumber() {
        TestData_Pricebooks.createISRETAILPriceBook();
        Product2 expectedProduct = TestData_Product2.createSingleProduct();
        //13A226JD010
        String factoryNumberToSearchFor = expectedProduct.ProductCode;

        Test.startTest();
        Product2Helper ph = new Product2Helper();
        Boolean foundProduct = ph.isValidFactoryModelNumber(factoryNumberToSearchFor);

        system.assertEquals(true,foundProduct);
    }

    public static testMethod void testGetSGMDataForProducts() {
        Map<String, Product2> productMap = TestData_Product2.createProducts();
        TestData_Product2.createPricebooksForProducts(productMap);

        Set<Id> prodIds = New Set<Id>();
        for(String prodCode : productMap.keySet()){
            Product2 p = productMap.get(prodCode);
            prodIds.add(p.Id);
        }

        Product2Helper.SGMData sgm = Product2Helper.getSGMDataForProducts(prodIds);
        System.debug('sgm ' + sgm);
        System.assertEquals(2, sgm.levelToPricebook.size());

    }

    public static testMethod void testGenericOtherProductId() {
        TestData_Product2.createGenericOtherProduct();
        
        Product2 p = [  SELECT Id 
                        FROM Product2 
                        WHERE RecordTypeId = :RecordTypes.product_Generic.Id
                          AND Detail_SKU__c = 'Other'
                          AND ProductCode = 'Other'
                          AND Generic_Product_Category__c = 'Other'
                          ]; 
        
        Test.startTest();
        Id verifyPId = Product2Helper.getGenericOtherProductId();
        system.assertEquals(p.id, verifyPId);
        system.assertEquals(false, Product2Helper.isTrueProduct(verifyPId));
    }

    public static testMethod void verifyRetailPriceCheck() {
        Decimal retailMax;
        Decimal retailMin;
        Decimal retailPrice;
        
        Test.startTest();
        system.assertEquals(true, Product2Helper.retailPriceCheck(retailMax, retailMin, retailPrice)); //ToFuture: why would this assert to true if there are any null values?

        retailMin = 7000; retailMax = 10000; retailPrice = 8000;
        system.assertEquals(true, Product2Helper.retailPriceCheck(retailMax, retailMin, retailPrice));

        retailMin = 7000; retailMax = 10000; retailPrice = 500;
        system.assertEquals(false, Product2Helper.retailPriceCheck(retailMax, retailMin, retailPrice));
    }
    @isTest static void coverToCover_sgmBatchFamilyTest() {
        //mburr.2021-07-13 copied from SimplifiedGrossMarginTriggerHandlerTest
        List<Pricebook2> pricebooks = new List<Pricebook2>();
        for(Integer i=1;i<=7;i++){
            Pricebook2 pb = new Pricebook2(Level__c = String.valueOf(i), IsActive = true, Name = 'Level '+i);
            pricebooks.add(pb);
        }
        for(Integer i=1;i<=5;i++){
            Pricebook2 pb = new Pricebook2(Tier__c = String.valueOf(i), IsActive = true, Name = 'Tier '+i);
            pricebooks.add(pb);
        }
        pricebooks.add(new Pricebook2(Is_Retail__c = true, IsActive = true, Name = 'Retail Pricebook'));
        insert pricebooks;
        Simplified_Gross_Margin__c sgmFam = new Simplified_Gross_Margin__c(Brand__c = 'Cub', Level_1_Gross_Margin__c = 10, Level_2_Gross_Margin__c = 20, Level_3_Gross_Margin__c = 30, 
            Level_4_Gross_Margin__c = 40, Level_5_Gross_Margin__c = 50, Level_6_Gross_Margin__c = 60, 
            Level_7_Gross_Margin__c = 70, Family__c = 'Zero Turn', RecordTypeId = RecordTypes.sgm_Level.Id);
        insert sgmFam;
        
        List<Product2> products = TestData_Order.createProducts(200, false);  //Can only run one batch in a test.  Will fail at 201
        Set<Id> productIds = new Set<Id>();
        for(Product2 p: products){
            productIds.add(p.Id);
            p.Brand__c = 'Cub';
            p.Family = 'Zero Turn';
            p.Retail_Price_US__c = 100.0;
        }
        Test.startTest();
        insert products;
        Test.stopTest();
        List<PricebookEntry> level1PBEs = [Select Id From PricebookEntry Where Pricebook2.Level__c = '1'];
        System.assertEquals(200, level1PBEs.size());
        Map<Id, Decimal> prodToRetail = new Map<Id, Decimal>();
        for(PricebookEntry pbe: [Select Id, UnitPrice, Product2Id From PricebookEntry Where Pricebook2.Is_Retail__c = true and Product2Id IN :productIds]){
            prodToRetail.put(pbe.Product2Id, pbe.UnitPrice);
        }

        for(PricebookEntry pbe: [Select Id, UnitPrice, Product2Id From PricebookEntry Where Pricebook2.Level__c = '1'  and Product2Id IN :productIds]){
            Decimal retailPrice = prodToRetail.get(pbe.Product2Id);
            System.assertEquals(retailPrice * 0.9, pbe.UnitPrice);
        }
    }

    @isTest static void coverToCover_sgmUpdateTest() {
        //mburr.2021-07-13 copied from SimplifiedGrossMarginTriggerHandlerTest
        List<Pricebook2> pricebooks = new List<Pricebook2>();
        for(Integer i=1;i<=7;i++){
            Pricebook2 pb = new Pricebook2(Level__c = String.valueOf(i), IsActive = true, Name = 'Level '+i);
            pricebooks.add(pb);
        }
        for(Integer i=1;i<=5;i++){
            Pricebook2 pb = new Pricebook2(Tier__c = String.valueOf(i), IsActive = true, Name = 'Tier '+i);
            pricebooks.add(pb);
        }
        pricebooks.add(new Pricebook2(Is_Retail__c = true, IsActive = true, Name = 'Retail Pricebook'));
        insert pricebooks;
        Simplified_Gross_Margin__c sgmCat = new Simplified_Gross_Margin__c(Brand__c = 'Cub', Level_1_Gross_Margin__c = 10, Level_2_Gross_Margin__c = 20, Level_3_Gross_Margin__c = 30, 
                Level_4_Gross_Margin__c = 40, Level_5_Gross_Margin__c = 50, Level_6_Gross_Margin__c = 60, 
                Level_7_Gross_Margin__c = 70, Category__c = 'Chore', RecordTypeId = RecordTypes.sgm_Level.Id);
        insert sgmCat;
        
        List<Product2> products = TestData_Order.createProducts(200, false);
        Set<Id> productIds = new Set<Id>();
        Integer i = 0;
        for(Product2 p: products){
            i++;
            productIds.add(p.Id);
            p.Brand__c = 'Cub';
            p.Category__c = 'Chore';
            p.Retail_Price_US__c = 100.0 + i;
        }
        Test.startTest();
        insert products;
        Test.stopTest();//batch is running

        Map<Id, Decimal> prodToRetail = new Map<Id, Decimal>();
        for(PricebookEntry pbe: [Select Id, UnitPrice, Product2Id From PricebookEntry Where Pricebook2.Is_Retail__c = true and Product2Id IN :productIds]){
            prodToRetail.put(pbe.Product2Id, pbe.UnitPrice);
        }

        for(PricebookEntry pbe: [Select Id, UnitPrice, Product2Id From PricebookEntry Where Pricebook2.Level__c = '1'  and Product2Id IN :productIds]){
            Decimal retailPrice = prodToRetail.get(pbe.Product2Id);
            System.assertEquals(retailPrice * 0.9, pbe.UnitPrice);
        }

        sgmCat.Level_1_Gross_Margin__c = 20;
        update sgmCat;

        Map<Id, Decimal> prodToRetailAfter = new Map<Id, Decimal>();
        for(PricebookEntry pbe: [Select Id, UnitPrice, Product2Id From PricebookEntry Where Pricebook2.Is_Retail__c = true and Product2Id IN :productIds]){
            prodToRetailAfter.put(pbe.Product2Id, pbe.UnitPrice);
        }

        for(PricebookEntry pbe: [Select Id, UnitPrice, Product2Id From PricebookEntry Where Pricebook2.Level__c = '1'  and Product2Id IN :productIds]){
            Decimal retailPrice = prodToRetailAfter.get(pbe.Product2Id);
            System.assertEquals(retailPrice * 0.8, pbe.UnitPrice);
        }
    }
}