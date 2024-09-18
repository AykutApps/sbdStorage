@isTest
public with sharing class DOS_WebcardRestServiceTest {
    static void makeData() {
        Account dealerAccount = OrderControllerTest.createDealerAccount('Test', 'ACC081');
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

    @isTest(SeeAllData=true)
    static void testCreate_cart_post_basic() {
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.SUCCESS;
        makeData();
        String requestBody = '{"cartName":"Documoto 201756","hustlerPartsAccountNumber":"12345","items":[{"productCode":"TESTPRODUCTCODE","productQuantity":"3"}]}';
        RestRequest req = new RestRequest();
        req.requestURI = '/documoto-support-service/create-web-order';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        DOS_WebcardRestService.Response2 response = DOS_WebcardRestService.doPost();
        system.debug(response);
        Test.stopTest();

        System.assertEquals(expectedStatus, response.status);
    }

    @isTest(SeeAllData=true)
    static void testInterfaceMethods() {
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.SUCCESS;
        makeData();
        String requestBody = '{"cartName":"Documoto 201756","hustlerPartsAccountNumber":"12345","items":[{"productCode":"TESTPRODUCTCODE","productQuantity":"3"}]}';
        RestRequest req = new RestRequest();
        req.requestURI = '/documoto-support-service/create-web-order';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        DOS_WebcardRestService.Response2 response = DOS_WebcardRestService.doPost();
        DOS_WebcardRestService.getPayloadType();
        DOS_WebcardRestService.getBaseRESTEndpoint();
        DOS_WebcardRestService.getMinPayloadSize();
        DOS_WebcardRestService.getMaxPayloadSize();
        DOS_WebcardRestService.getMaxPayloadFieldSize();
        DOS_WebcardRestService.getBaseSObjectAPIName();
        DOS_WebcardRestService.fetchEndpointHelper();
        Test.stopTest();

        System.assertEquals(expectedStatus, response.status);
    }

    @isTest(SeeAllData=true)
    static void testCreate_cart_one_cart() {
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.SUCCESS;
        makeData();
        String requestBody = '{"cartName":"Documoto 201756","hustlerPartsAccountNumber":"12345","items":[{"productCode":"TESTPRODUCTCODE","productQuantity":"3"}]}';
        RestRequest req = new RestRequest();
        req.requestURI = '/documoto-support-service/create-web-order';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        DOS_WebcardRestService.Response2 response = DOS_WebcardRestService.doPost();
        DOS_WebcardRestService.Response2 response2 = DOS_WebcardRestService.doPost();
        system.debug(response2);
        Test.stopTest();
        System.assertEquals(expectedStatus, response2.status);
        System.assertEquals(
            1,
            [SELECT Id FROM WebCart WHERE Is_Documoto__c = TRUE AND Status = 'Active' AND AccountId IN (SELECT Id FROM Account WHERE Hustler_Parts_Account__c = '12345')].size()
        );
    }

    @isTest(SeeAllData=true)
    static void testMissign_account_number() {
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.FAILURE;
        makeData();
        String requestBody = '{"cartName":"Documoto 201756","hustlerPartsAccountNumber":"","items":[{"productCode":"TESTPRODUCTCODE","productQuantity":"3"}]}';
        RestRequest req = new RestRequest();
        req.requestURI = '/documoto-support-service/create-web-order';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        DOS_WebcardRestService.Response2 response = DOS_WebcardRestService.doPost();
        DOS_WebcardRestService.Response2 response2 = DOS_WebcardRestService.doPost();
        system.debug(response2);
        Test.stopTest();
        System.assertEquals(expectedStatus, response2.status);
    }

    @isTest(SeeAllData=true)
    static void testMissign_product_code() {
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.FAILURE;
        makeData();
        String requestBody = '{"cartName":"Documoto 201756","hustlerPartsAccountNumber":"12345","items":[{"productCode":"XXX","productQuantity":"3"}]}';
        RestRequest req = new RestRequest();
        req.requestURI = '/documoto-support-service/create-web-order';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        DOS_WebcardRestService.Response2 response = DOS_WebcardRestService.doPost();
        DOS_WebcardRestService.Response2 response2 = DOS_WebcardRestService.doPost();
        system.debug(response2);
        Test.stopTest();
        System.assertEquals(expectedStatus, response2.status);
    }
}
