@isTest
public with sharing class ORS_OrderHelperStatusRestServiceTest {
    private static String erpUniqueId = 'uid1';
    private static String fulfillmentExternalKey = 'ek01';

    @TestSetup
    static void makeData() {
        Account dealerAccount = OrderControllerTest.createDealerAccount('Test', 'ACC081');
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

        Order order2 = new Order();
        order2.RecordTypeId = RecordTypes.order_PreSeason.Id;
        order2.AccountId = dealerAccount.Id;
        order2.Pricebook2Id = testPricebookId;
        order2.Ordering_Event__c = orderingEvent.Id;
        order2.Status = 'Draft';
        order2.EffectiveDate = Date.today();
        order2.PO_Number__c = '1000';
        insert order2;

        Product2 product = new Product2();
        product.Name = 'Test';
        product.ProductCode = 'Test';
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

        OrderDeliveryMethod orderDeliveryMethod = new OrderDeliveryMethod(Name = 'software-shipping', ProductId = product.Id);
        insert orderDeliveryMethod;

        OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup(
            DeliverToName = 'Buyer USer',
            DeliverToStreet = 'test Street',
            DeliverToCity = 'Minneapolis',
            DeliverToState = 'MN',
            DeliverToPostalCode = '55402',
            DeliverToCountry = 'US',
            OrderDeliveryMethodId = orderDeliveryMethod.Id,
            OrderId = order.Id
        );
        insert orderDeliveryGroup;

        OrderItem orderItem = new OrderItem();
        orderItem.OrderId = order.Id;
        orderItem.PriceBookEntryId = pricebookEntry.Id;
        orderItem.Quantity = 1;
        orderItem.OrderDeliveryGroupId = orderDeliveryGroup.Id;
        orderItem.TotalLineAmount = 200;
        insert orderItem;

        order.Status = 'Activated';
        update order;

        OrderSummary os = [SELECT Id FROM OrderSummary LIMIT 1];

        FulfillmentOrder ffo = new FulfillmentOrder();
        ffo.ERP_UniqueId__c = erpUniqueId;
        ffo.OrderId = order.Id;
        ffo.OrderSummaryId = os.Id;
        ffo.External_Key__c = fulfillmentExternalKey;
        ffo.Status = 'Allocated';
        ffo.FulfilledToName = 'testName';
        insert ffo;

        FulfillmentOrderLineItem ffoli = new FulfillmentOrderLineItem();
        ffoli.Product2Id = product.Id;
        ffoli.Quantity = 2;
        ffoli.OriginalQuantity = 2;
        ffoli.External_Key__c = 'exkey2';
        ffoli.FulfillmentOrderId = ffo.Id;
        ffoli.Type = 'Order Product';
        ffoli.TypeCode = 'Product';
        insert ffoli;
    }

    @isTest
    static void testMatch_post_basic() {
        // Expected results
        String expectedCountryCode = 'US';
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.SUCCESS;

        // Create Payload
        ORS_OrderHelperStatusRestService.OrderRequestPayload requestPayload = createPayload_basic();
        Order order = [SELECT Id FROM Order WHERE Status = 'Draft' LIMIT 1];
        requestPayload.order.sfOrderId = order.Id;
        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/status';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;
        // RestContext response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call the REST service method
        Test.startTest();

        SharedModels.RESTResponse response = ORS_OrderHelperStatusRestService.doPost();
        ORS_OrderHelperStatusRestService.getPayloadType();
        ORS_OrderHelperStatusRestService.getBaseRESTEndpoint();
        ORS_OrderHelperStatusRestService.getMinPayloadSize();
        ORS_OrderHelperStatusRestService.getMaxPayloadFieldSize();
        ORS_OrderHelperStatusRestService.getBaseSObjectAPIName();
        ORS_OrderHelperStatusRestService.getMaxPayloadSize();
        Test.stopTest();

        // Assertions
        System.assertEquals(expectedCountryCode, response.countryCode);
        System.assertEquals(expectedStatus, response.status);
    }

    @isTest
    static void testMatch_post_200_actionPending() {
        // Expected results
        String expectedCountryCode = 'US';
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.SUCCESS;
        String expectedAction = 'Pending';

        // Create Payload
        ORS_OrderHelperStatusRestService.OrderRequestPayload requestPayload = createPayload_basic();
        Order order = [SELECT Id FROM Order WHERE Status = 'Draft' LIMIT 1];
        requestPayload.order.sfOrderId = order.Id;
        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/log';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;

        // Call the REST service method
        Test.startTest();
        RestResponse res = new RestResponse();
        RestContext.response = res;
        ORS_OrderHelperStatusRestService.doPost();
        Test.stopTest();

        // Assertions
        System.assertEquals(expectedCountryCode, ORS_OrderHelperStatusRestService.response.countryCode);
        System.assertEquals(expectedStatus, ORS_OrderHelperStatusRestService.response.status);
        System.assertEquals(expectedAction, ORS_OrderHelperStatusRestService.response.action);
    }

    @isTest
    static void testMatch_post_200_actionComplete() {
        // Expected results
        String expectedCountryCode = 'US';
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.SUCCESS;
        String expectedAction = 'Complete';

        // Create Payload
        ORS_OrderHelperStatusRestService.OrderRequestPayload requestPayload = createPayload_basic();
        OrderSummary[] orderSummaries = [
            SELECT Id, OriginalOrderId
            FROM OrderSummary
        ];
        requestPayload.order.sfOrderId = orderSummaries[0].OriginalOrderId;

        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/log';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;

        // Call the REST service method
        Test.startTest();
        ORS_OrderHelperStatusRestService.doPost();
        Test.stopTest();

        // Assertions
        System.assertEquals(expectedCountryCode, ORS_OrderHelperStatusRestService.response.countryCode);
        System.assertEquals(expectedStatus, ORS_OrderHelperStatusRestService.response.status);
        System.assertEquals(expectedAction, ORS_OrderHelperStatusRestService.response.action);
    }

    @isTest
    static void testMatch_post_400_actionError_retryCount() {
        // Expected results
        String expectedCountryCode = 'US';
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.FAILURE;
        String expectedAction = 'Error';
        Integer maxRetry = 3;

        // Create Payload
        ORS_OrderHelperStatusRestService.OrderRequestPayload requestPayload = createPayload_basic();
        OrderSummary[] orderSummaries = [
            SELECT Id, OriginalOrderId
            FROM OrderSummary
        ];
        requestPayload.order.sfOrderId = orderSummaries[0].OriginalOrderId;

        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/log';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;

        // Call the REST service method
        Test.startTest();
        RestResponse res = new RestResponse();
        RestContext.response = res;
        for (Integer i = 0; i <= maxRetry; i++) {
            ORS_OrderHelperStatusRestService.doPost();
            ORS_OrderHelperStatusRestService.doPost();
            ORS_OrderHelperStatusRestService.doPost();
            ORS_OrderHelperStatusRestService.doPost();
        }

        Test.stopTest();

        // Assertions
        System.assertEquals(expectedCountryCode, ORS_OrderHelperStatusRestService.response.countryCode);
        System.assertEquals(expectedStatus, ORS_OrderHelperStatusRestService.response.status);
        System.assertEquals(expectedAction, ORS_OrderHelperStatusRestService.response.action);
    }

    @isTest
    static void testMatch_post_400_actionError_payloadValidation_emptySfOrderId() {
        // Expected results
        String expectedCountryCode = 'US';
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.FAILURE;
        String expectedAction = 'Error';

        // Create Payload
        ORS_OrderHelperStatusRestService.OrderRequestPayload requestPayload = createPayload_basic();
        requestPayload.order.sfOrderId = '';
        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/log';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;

        // Call the REST service method
        Test.startTest();
        RestResponse res = new RestResponse();
        RestContext.response = res;
        ORS_OrderHelperStatusRestService.doPost();
        ORS_OrderHelperStatusRestService.doPost();
        ORS_OrderHelperStatusRestService.doPost();
        ORS_OrderHelperStatusRestService.doPost();
        Test.stopTest();

        // Assertions
        System.assertEquals(expectedCountryCode, ORS_OrderHelperStatusRestService.response.countryCode);
        System.assertEquals(expectedStatus, ORS_OrderHelperStatusRestService.response.status);
        System.assertEquals(expectedAction, ORS_OrderHelperStatusRestService.response.action);
    }

    @isTest
    static void testMatch_post_400_actionError_payloadValidation_notValidSfOrderId() {
        // Expected results
        String expectedCountryCode = 'US';
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.FAILURE;
        String expectedAction = 'Error';

        // Create Payload
        ORS_OrderHelperStatusRestService.OrderRequestPayload requestPayload = createPayload_basic();

        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/log';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;

        // Call the REST service method
        Test.startTest();
        RestResponse res = new RestResponse();
        RestContext.response = res;
        ORS_OrderHelperStatusRestService.doPost();
        ORS_OrderHelperStatusRestService.doPost();
        ORS_OrderHelperStatusRestService.doPost();
        ORS_OrderHelperStatusRestService.doPost();
        Test.stopTest();

        // Assertions
        System.assertEquals(expectedCountryCode, ORS_OrderHelperStatusRestService.response.countryCode);
        System.assertEquals(expectedStatus, ORS_OrderHelperStatusRestService.response.status);
        System.assertEquals(expectedAction, ORS_OrderHelperStatusRestService.response.action);
    }

    public static ORS_OrderHelperStatusRestService.OrderRequestPayload createPayload_basic() {
        ORS_OrderHelperStatusRestService.OrderRequestPayload requestPayload = new ORS_OrderHelperStatusRestService.OrderRequestPayload();
        ORS_OrderHelperStatusRestService.Order order = new ORS_OrderHelperStatusRestService.Order();
        order.customerNumber = 288801;
        order.sfOrderId = '1923400';
        order.transactionId = '1923400';
        order.orderNumber = '1923400';
        order.companyCode = 38;
        order.uniqueId = '38_1923400';
        order.orderDate = Date.valueOf('2023-11-17');
        order.requestedDate = Date.valueOf('2023-11-21');
        order.poNumber = 'CC23-32_2';
        order.externalOrderNumber = '02151179';
        requestPayload.order = order;
        return requestPayload;
    }
}