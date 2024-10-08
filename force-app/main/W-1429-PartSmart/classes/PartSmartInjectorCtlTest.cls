@isTest
public with sharing class PartSmartInjectorCtlTest {
    static void makeData() {
        Account dealerAccount = TestData_Account.createDealerAccount(RecordTypes.account_CAAuthorizedAccount.Id, 'Test', 'DOCU001');
        dealerAccount.Hustler_Parts_Account__c = '12345';
        update dealerAccount;

        BuyerAccount buyerAccount = new BuyerAccount();
        buyerAccount.BuyerId = dealerAccount.Id;
        buyerAccount.Name = 'Test Buyer)';
        buyerAccount.IsActive = true;
        insert buyerAccount;

        User dealerUser = OrderControllerTest.createDealerUser(dealerAccount.Id);
        Ordering_Event__c orderingEvent = TestData_Ordering_Event.createOrderingEvent();

        PriceBook2 testPricebook = new PriceBook2();
        testPricebook.Name = OrderController.CANADA_PRICEBOOK_NAME;
        testPricebook.Is_Retail__c = true;
        testPricebook.IsActive = true;
        testPricebook.Level__c = '1';
        insert testPricebook;

        Id testPricebookId = testPricebook.Id;

        Order order = new Order();
        order.RecordTypeId = RecordTypes.order_PreSeason.Id;
        order.AccountId = dealerAccount.Id;
        order.Pricebook2Id = testPricebookId;
        order.Ordering_Event__c = orderingEvent.Id;
        order.Status = 'Draft';
        order.EffectiveDate = Date.today();
        order.PO_Number__c = '1000';
        insert order;

        Product2 product = new Product2();
        product.Name = 'Test';
        product.ProductCode = 'TESTPRODUCTCODE';
        product.IsActive = true;
        product.B2B_No_Longer_Available__c = false;
        insert product;

        PriceBook2 retailPricebook = new PriceBook2();
        retailPricebook.Name = 'Retail';
        retailPricebook.Is_Retail__c = true;
        retailPricebook.IsActive = true;
        insert retailPricebook;

        PricebookEntry retailPricebookEntry = new PricebookEntry();
        retailPricebookEntry.Product2Id = product.Id;
        retailPricebookEntry.Pricebook2Id = retailPricebook.Id;
        retailPricebookEntry.UnitPrice = 100;
        retailPricebookEntry.IsActive = true;
        insert retailPricebookEntry;

        PricebookEntry pricebookEntry = new PricebookEntry();
        pricebookEntry.Product2Id = product.Id;
        pricebookEntry.Pricebook2Id = testPricebookId;
        pricebookEntry.UnitPrice = 100;
        pricebookEntry.IsActive = true;
        insert pricebookEntry;

        system.debug('Web Stores 0');
        system.debug([SELECT id, Name FROM Webstore]);

        // Create test data
        WebStore webStore;
        WebStore[] webStores = [SELECT Id FROM Webstore];
        if (webStores.size() == 0) {
            WebStore webStoreInsert = new WebStore();
            webStoreInsert.Name = 'B2B Dealer Community';
            insert webStoreInsert;
            webStore = webStoreInsert;
        } else {
            webStore = webStores[0];
        }

        system.debug('Web Stores 1');
        system.debug([SELECT id, Name FROM Webstore]);

        BuyerGroup buyerGroup = new BuyerGroup();
        buyerGroup.Name = 'Test Buyer Group';
        insert buyerGroup;

        BuyerGroupMember buyerGroupMember = new BuyerGroupMember();
        buyerGroupMember.buyerId = dealerAccount.Id;
        buyerGroupMember.BuyerGroupId = buyerGroup.Id;
        insert buyerGroupMember;

        WebStoreBuyerGroup webStoreBuyerGroup = new WebStoreBuyerGroup();
        webStoreBuyerGroup.BuyerGroupId = buyerGroup.Id;
        webStoreBuyerGroup.WebStoreId = webStore.Id;
        insert webStoreBuyerGroup;

        CommerceEntitlementPolicy commerceEntPolicy = new CommerceEntitlementPolicy(
            CanViewPrice = true,
            CanViewProduct = true,
            IsActive = true,
            Name = 'Test _ All Products and Prices'
        );
        insert commerceEntPolicy;

        CommerceEntitlementBuyerGroup cebg = new CommerceEntitlementBuyerGroup(BuyerGroupId = buyerGroup.Id, PolicyId = commerceEntPolicy.Id);
        insert cebg;
        BuyerGroupPricebook bgpb = new BuyerGroupPricebook(BuyerGroupId = buyerGroup.Id, Pricebook2Id = testPricebookId, IsActive = true);
        insert bgpb;

        WebStorePricebook wspb = new WebStorePricebook(Pricebook2Id = testPricebookId, WebStoreId = webStore.Id, IsActive = true);
        insert wspb;

        // Product Category Creation

        WebStoreCatalog catalog = [
            SELECT Id, ProductCatalogId
            FROM WebStoreCatalog
            WHERE SalesStoreId = :webStore.Id
            LIMIT 1
        ];

        List<ProductCategoryProduct> productCategories = new List<ProductCategoryProduct>();

        ProductCategory parentCategory = new ProductCategory(Name = 'Parent Category', CatalogId = catalog.ProductCatalogId);
        insert parentCategory;

        List<ProductCategory> childCategories = new List<ProductCategory>();
        for (Integer i = 0; i < 7; i++) {
            ProductCategory cat = new ProductCategory(ParentCategoryId = parentCategory.Id, Name = 'Child Category ' + (i + 1), CatalogId = catalog.ProductCatalogId);
            childCategories.add(cat);
        }

        insert childCategories;

        for (ProductCategory child : childCategories) {
            productCategories.add(new ProductCategoryProduct(ProductId = product.Id, ProductCategoryId = child.Id));
        }

        insert productCategories;

        //#region Create product categories and assign products to category and entitlement policy
        ProductCategory prodCategory = new ProductCategory(Name = 'Test Category', IsNavigational = true, CatalogId = catalog.ProductCatalogId);
        insert prodCategory;
        List<CommerceEntitlementProduct> cep = new List<CommerceEntitlementProduct>();

        cep.add(new CommerceEntitlementProduct(PolicyId = commerceEntPolicy.Id, ProductId = product.Id));

        insert cep;

        system.debug('dealerAccount');
        system.debug(dealerAccount);

        system.debug('store');
        system.debug(webStore);

        system.debug('buyerGroupMember');
        system.debug(buyerGroupMember);

        system.debug('WebstoreBuyerGroup');
        system.debug([SELECT id, WebStoreId, BuyerGroupId, BuyerGroup.Name FROM WebstoreBuyerGroup]);

        system.debug('Web Stores');
        system.debug([SELECT id, Name FROM Webstore]);
    }

    private class MockHttpCallout implements HttpCalloutMock {
        private Integer code;
        private String body;

        // Constructor to set the desired mock response characteristics
        MockHttpCallout(Integer statusCode, String responseBody) {
            this.code = statusCode;
            this.body = responseBody;
        }

        // Implement the respond method to return a custom response
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(code);
            response.setBody(body);
            return response;
        }
    }

    @isTest(SeeAllData=true)
    static void testCreate_cart_item_add_basic() {
        makeData();
        String jsonRequest = '{"id":565421,"method":"convergence::execute","params":{"method":"addPartToCart","args":[{"sku":"TESTPRODUCTCODE","brandCode":"cut","brandName":"Cub Cadet","desc":"DECAL, HOT","qty":1,"userName":"Aykut Parlak","langCode":"en","catalogLang":"en"}]}}';
        PartSmartInjectorCtl.dealerAccountId = [SELECT Id FROM Account WHERE Name = 'Test'][0].Id;

        Test.startTest();
        String response = PartSmartInjectorCtl.addToCart(jsonRequest);
        Test.stopTest();

        System.assertEquals('Success', response);
    }

    @isTest(SeeAllData=true)
    static void testCreate_cart_item_add_replacement_product_error() {
        makeData();
        String jsonRequest = '{"id":565421,"method":"convergence::execute","params":{"method":"addPartToCart","args":[{"sku":"TESTPRODUCTCODE","brandCode":"cut","brandName":"Cub Cadet","desc":"DECAL, HOT","qty":1,"userName":"Aykut Parlak","langCode":"en","catalogLang":"en"}]}}';
        PartSmartInjectorCtl.dealerAccountId = [SELECT Id FROM Account WHERE Name = 'Test'][0].Id;

        Product2 prd = [SELECT Id FROM Product2 WHERE ProductCode = 'TESTPRODUCTCODE'];

        Product2 prdReplacement = new Product2();
        prdReplacement.Name = 'Test';
        prdReplacement.ProductCode = 'TESTPRODUCTCODEREPLACEMENT';
        prdReplacement.IsActive = true;
        prdReplacement.Is_Base_Part__c = true;
        insert prdReplacement;

        prd.B2B_Replacement_Product__c = prdReplacement.Id;
        update prd;

        Test.startTest();
        String response = PartSmartInjectorCtl.addToCart(jsonRequest);
        Test.stopTest();

        System.Assert(!response.contains('Success'));
    }

    @isTest(SeeAllData=true)
    static void testCreate_cart_item_add_replacement_product_success() {
        makeData();
        String jsonRequest = '{"id":565421,"method":"convergence::execute","params":{"method":"addPartToCart","args":[{"sku":"TESTPRODUCTCODEREPLACEMENT","brandCode":"cut","brandName":"Cub Cadet","desc":"DECAL, HOT","qty":1,"userName":"Aykut Parlak","langCode":"en","catalogLang":"en"}]}}';
        PartSmartInjectorCtl.dealerAccountId = [SELECT Id FROM Account WHERE Name = 'Test'][0].Id;

        Product2 prdReplacement = [SELECT Id FROM Product2 WHERE ProductCode = 'TESTPRODUCTCODE'];

        Product2 prd = new Product2();
        prd.Name = 'Test';
        prd.ProductCode = 'TESTPRODUCTCODEREPLACEMENT';
        prd.IsActive = true;
        prd.Is_Base_Part__c = false;
        prd.B2B_No_Longer_Available__c = false;
        prd.B2B_Replacement_Product__c = prdReplacement.Id;
        insert prd;

        Test.startTest();
        String response = PartSmartInjectorCtl.addToCart(jsonRequest);
        Test.stopTest();

        System.Assert(response.contains('Info'));
    }

    @isTest
    static void testAuthenticateSuccess() {
        // Set up the mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, '{"token": "abc123"}'));

        // Call the method to test
        Test.startTest();
        String result = PartSmartInjectorCtl.authenticate();
        Test.stopTest();

        // Verify the method returns the correct response
        System.assertEquals('{"token": "abc123"}', result, 'The method should return the authentication token.');
    }

    @isTest
    static void testAuthenticateFailure() {
        // Set up the mock HTTP response for a failure case
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(401, 'Unauthorized'));

        // Call the method to test
        Test.startTest();
        String result = PartSmartInjectorCtl.authenticate();
        Test.stopTest();

        // Verify the method handles failures appropriately
        System.assert(result == null, 'The method should return null on failure.');
        // Optionally, check for specific debug logs or error messages if needed
    }

    @isTest
    static void testGet_script_url() {
        // Set up the mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, '{"access_token": "abc123","refresh_token":"abc234","expires_in":"1080"}'));

        // Call the method to test
        Test.startTest();
        PartSmartInjectorCtl pc = new PartSmartInjectorCtl();
        Test.stopTest();

        // Verify the method returns the correct response
        System.assertEquals(
            'https://www.partsmart.net/stream.js?access_token=abc123&refresh_token=abc234&expires_in=1080',
            pc.scriptUrl,
            'Script URL ccreation not working correct'
        );
    }
}
