@isTest
private class ORS_OrderHelperMatchRestServiceTest {
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
        ORS_OrderHelperMatchRestService.OrderRequestPayload requestPayload = createPayload_basic();
        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/match';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;

        // Call the REST service method
        Test.startTest();
        SharedModels.RESTResponse response = ORS_OrderHelperMatchRestService.doPost();
        ORS_OrderHelperMatchRestService.getPayloadType();
        ORS_OrderHelperMatchRestService.getBaseRESTEndpoint();
        ORS_OrderHelperMatchRestService.getMinPayloadSize();
        ORS_OrderHelperMatchRestService.getMaxPayloadFieldSize();
        ORS_OrderHelperMatchRestService.getBaseSObjectAPIName();
        ORS_OrderHelperMatchRestService.getMaxPayloadSize();
        Test.stopTest();

        // Assertions
        System.assertEquals(expectedCountryCode, response.countryCode);
        System.assertEquals(expectedStatus, response.status);
    }

    @isTest
    static void testMatch_post_200_matchFulfilmentOrdersBasedOnUniqueId() {
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.SUCCESS;
        String expectedCountryCode = 'US';
        String expectedNewOrdersFlag = 'no';
        Boolean expectingOrderSummary = true;
        Id expectedOrderSummaryId;
        Boolean expectingOrderId = true;
        Id expectedOrderId;
        Boolean expectingFulfillmentOrder = true;
        Id expectedFulfillmentOrderId;
        Boolean expectingOrderItemSummaries = true;
        Integer expectingOrderItemSummariesCount = 1;

        // Fetching the existing record
        FulfillmentOrder[] ffos = [
            SELECT Id, ERP_UniqueId__c, OrderId, OrderSummary.OriginalOrderId, OrderSummaryId
            FROM FulfillmentOrder
        ];

        expectedOrderSummaryId = ffos[0].OrderSummaryId;
        expectedOrderId = ffos[0].OrderSummary.OriginalOrderId;
        expectedFulfillmentOrderId = ffos[0].Id;

        // Create Payload
        ORS_OrderHelperMatchRestService.OrderRequestPayload requestPayload = createPayload_basic();
        requestPayload.order.uniqueId = erpUniqueId;

        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/match';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;

        // Call the REST service method
        Test.startTest();
        SharedModels.RESTResponse response = ORS_OrderHelperMatchRestService.doPost();
        Test.stopTest();

        // Core Assertions
        System.assertEquals(expectedStatus, response.status);
        System.assertEquals(expectedCountryCode, response.countryCode);
        System.assertEquals(expectedNewOrdersFlag, ORS_OrderHelperMatchRestService.responsePayload.newOrders);
        System.assertEquals(expectingOrderSummary, ORS_OrderHelperMatchRestService.responsePayload.orderSummaryId != null);
        System.assertEquals(expectedOrderSummaryId, ORS_OrderHelperMatchRestService.responsePayload.orderSummaryId);
        System.assertEquals(expectingOrderId, ORS_OrderHelperMatchRestService.responsePayload.orderId != null);
        System.assertEquals(expectedOrderId, ORS_OrderHelperMatchRestService.responsePayload.orderId);
        System.assertEquals(expectingFulfillmentOrder, ORS_OrderHelperMatchRestService.responsePayload.fulfillmentOrder != null);
        System.assertEquals(expectedFulfillmentOrderId, ORS_OrderHelperMatchRestService.responsePayload.fulfillmentOrderId);
        System.assertEquals(expectingOrderItemSummaries, !ORS_OrderHelperMatchRestService.responsePayload.orderItemSummaries.isEmpty());
        System.assertEquals(expectingOrderItemSummariesCount, ORS_OrderHelperMatchRestService.responsePayload.orderItemSummaries.size());
        // Extra Assertions 
    }

    @isTest
    static void testMatch_post_200_matchOrderSummaries() {
        // Expected results        
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.SUCCESS;
        String expectedCountryCode = 'US';
        String expectedNewOrdersFlag = 'no';
        Boolean expectingOrderSummary = true;
        Id expectedOrderSummaryId;
        Boolean expectingOrderId = true;
        Id expectedOrderId;
        Boolean expectingFulfillmentOrder = true;
        Id expectedFulfillmentOrderId;
        Boolean expectingOrderItemSummaries = true;
        Integer expectingOrderItemSummariesCount = 1;
        OrderSummary[] oss = [
            SELECT Id, OrderNumber, OriginalOrderId
            FROM OrderSummary
        ];
        expectedOrderSummaryId = oss[0].Id;
        expectedOrderId = oss[0].OriginalOrderId;
        expectedFulfillmentOrderId = null;


        // Create Payload
        ORS_OrderHelperMatchRestService.OrderRequestPayload requestPayload = createPayload_basic();
        requestPayload.order.uniqueId = 'invlaidId';
        requestPayload.order.externalOrderNumber = [SELECT Id, OrderNumber FROM OrderSummary][0].OrderNumber;

        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/match';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;

        // Call the REST service method
        Test.startTest();
        SharedModels.RESTResponse response = ORS_OrderHelperMatchRestService.doPost();
        Test.stopTest();
        system.debug('ORS_OrderHelperMatchRestService.responsePayload');
        system.debug(ORS_OrderHelperMatchRestService.responsePayload);

        // Core Assertions
        System.assertEquals(expectedStatus, response.status);
        System.assertEquals(expectedCountryCode, response.countryCode);
        System.assertEquals(expectedNewOrdersFlag, ORS_OrderHelperMatchRestService.responsePayload.newOrders);
        System.assertEquals(expectingOrderSummary, ORS_OrderHelperMatchRestService.responsePayload.orderSummaryId != null);
        System.assertEquals(expectedOrderSummaryId, ORS_OrderHelperMatchRestService.responsePayload.orderSummaryId);
        System.assertEquals(expectingOrderId, ORS_OrderHelperMatchRestService.responsePayload.orderId != null);
        System.assertEquals(expectedOrderId, ORS_OrderHelperMatchRestService.responsePayload.orderId);
        System.assertEquals(expectingFulfillmentOrder, ORS_OrderHelperMatchRestService.responsePayload.fulfillmentOrder == null);
        System.assertEquals(expectedFulfillmentOrderId, ORS_OrderHelperMatchRestService.responsePayload.fulfillmentOrderId);
        System.assertEquals(expectingOrderItemSummaries, !ORS_OrderHelperMatchRestService.responsePayload.orderItemSummaries.isEmpty());
        System.assertEquals(expectingOrderItemSummariesCount, ORS_OrderHelperMatchRestService.responsePayload.orderItemSummaries.size());
        // Extra Assertions 
    }

    @isTest
    static void testMatch_post_200_matchFulfilmentOrdersBasedOnExOrdNumb() {
        // Expected results        
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.SUCCESS;
        String expectedCountryCode = 'US';
        String expectedNewOrdersFlag = 'no';
        Boolean expectingOrderSummary = true;
        Id expectedOrderSummaryId;
        Boolean expectingOrderId = true;
        Id expectedOrderId;
        Boolean expectingFulfillmentOrder = true;
        Id expectedFulfillmentOrderId;
        Boolean expectingOrderItemSummaries = true;
        Integer expectingOrderItemSummariesCount = 1;
        FulfillmentOrder[] ffos = [
            SELECT Id, ERP_UniqueId__c, OrderId, OrderSummary.OriginalOrderId, OrderSummaryId
            FROM FulfillmentOrder
        ];
        expectedOrderSummaryId = ffos[0].OrderSummaryId;
        expectedOrderId = ffos[0].OrderSummary.OriginalOrderId;
        expectedFulfillmentOrderId = ffos[0].Id;

        // Create Payload
        ORS_OrderHelperMatchRestService.OrderRequestPayload requestPayload = createPayload_basic();
        requestPayload.order.uniqueId = 'invalidId';
        requestPayload.order.externalOrderNumber = erpUniqueId;

        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/match';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;

        // Call the REST service method
        Test.startTest();
        SharedModels.RESTResponse response = ORS_OrderHelperMatchRestService.doPost();
        Test.stopTest();

        // Core Assertions
        System.assertEquals(expectedStatus, response.status);
        System.assertEquals(expectedCountryCode, response.countryCode);
        System.assertEquals(expectedNewOrdersFlag, ORS_OrderHelperMatchRestService.responsePayload.newOrders);
        System.assertEquals(expectingOrderSummary, ORS_OrderHelperMatchRestService.responsePayload.orderSummaryId != null);
        System.assertEquals(expectedOrderSummaryId, ORS_OrderHelperMatchRestService.responsePayload.orderSummaryId);
        System.assertEquals(expectingOrderId, ORS_OrderHelperMatchRestService.responsePayload.orderId != null);
        System.assertEquals(expectedOrderId, ORS_OrderHelperMatchRestService.responsePayload.orderId);
        System.assertEquals(expectingFulfillmentOrder, ORS_OrderHelperMatchRestService.responsePayload.fulfillmentOrder != null);
        System.assertEquals(expectedFulfillmentOrderId, ORS_OrderHelperMatchRestService.responsePayload.fulfillmentOrderId);
        System.assertEquals(expectingOrderItemSummaries, !ORS_OrderHelperMatchRestService.responsePayload.orderItemSummaries.isEmpty());
        System.assertEquals(expectingOrderItemSummariesCount, ORS_OrderHelperMatchRestService.responsePayload.orderItemSummaries.size());
        // Extra Assertions 
    }

    @isTest
    static void testMatch_post_200_noMatch() {
        // Expected results        
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.SUCCESS;
        String expectedCountryCode = 'US';
        String expectedNewOrdersFlag = 'yes';
        Boolean expectingOrderSummary = true;
        Id expectedOrderSummaryId;
        Boolean expectingOrderId = true;
        Id expectedOrderId;
        Boolean expectingFulfillmentOrder = true;
        Id expectedFulfillmentOrderId;
        Boolean expectingOrderItemSummaries = true;
        expectedOrderSummaryId = null;
        expectedOrderId = null;
        expectedFulfillmentOrderId = null;

        // Create Payload
        ORS_OrderHelperMatchRestService.OrderRequestPayload requestPayload = createPayload_basic();
        requestPayload.order.uniqueId = 'invalidId';
        requestPayload.order.externalOrderNumber = 'invalidId';

        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/match';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;

        // Call the REST service method
        Test.startTest();
        SharedModels.RESTResponse response = ORS_OrderHelperMatchRestService.doPost();
        Test.stopTest();

        // Core Assertions
        System.assertEquals(expectedStatus, response.status);
        System.assertEquals(expectedCountryCode, response.countryCode);
        System.assertEquals(expectedNewOrdersFlag, ORS_OrderHelperMatchRestService.responsePayload.newOrders);
        System.assertEquals(expectingOrderSummary, ORS_OrderHelperMatchRestService.responsePayload.orderSummaryId == null);
        System.assertEquals(expectedOrderSummaryId, ORS_OrderHelperMatchRestService.responsePayload.orderSummaryId);
        System.assertEquals(expectingOrderId, ORS_OrderHelperMatchRestService.responsePayload.orderId == null);
        System.assertEquals(expectedOrderId, ORS_OrderHelperMatchRestService.responsePayload.orderId);
        System.assertEquals(expectingFulfillmentOrder, ORS_OrderHelperMatchRestService.responsePayload.fulfillmentOrder == null);
        System.assertEquals(expectedFulfillmentOrderId, ORS_OrderHelperMatchRestService.responsePayload.fulfillmentOrderId);
        // Extra Assertions 
    }

    @isTest
    static void testMatch_post_200_checkSystemLogsCreated() {
        // Expected results
        Boolean expectingSystemLogs = true;

        // Create Payload
        ORS_OrderHelperMatchRestService.OrderRequestPayload requestPayload = createPayload_basic();
        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/match';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;

        // Call the REST service method
        Test.startTest();
        SharedModels.RESTResponse response = ORS_OrderHelperMatchRestService.doPost();
        Test.stopTest();

        // Assertions
        System.assertEquals(expectingSystemLogs, ![SELECT Id FROM System_Log__c].isEmpty());
    }

    @isTest
    static void testMatch_post_400_validationError() {
        // Expected results
        String expectedCountryCode = 'US';
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.FAILURE;
        Id expectedOrderSummaryId = null;
        Id expectedOrderId = null;
        Id expectedFulfillmentOrderId = null;

        // Create Payload
        ORS_OrderHelperMatchRestService.OrderRequestPayload requestPayload = createPayload_basic();
        requestPayload.order.uniqueId = '';
        requestPayload.order.externalOrderNumber = '';

        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/match';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;

        // RestContext response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call the REST service method
        Test.startTest();
        SharedModels.RESTResponse response = ORS_OrderHelperMatchRestService.doPost();
        Test.stopTest();

        // Assertions
        System.assertEquals(expectedCountryCode, response.countryCode);
        System.assertEquals(expectedStatus, response.status);
        System.assertEquals(expectedOrderSummaryId, ORS_OrderHelperMatchRestService.responsePayload.orderSummaryId);
        System.assertEquals(expectedOrderId, ORS_OrderHelperMatchRestService.responsePayload.orderId);
        System.assertEquals(expectedFulfillmentOrderId, ORS_OrderHelperMatchRestService.responsePayload.fulfillmentOrderId);
    }

    @isTest
    static void testMatch_post_400_nullPayload() {
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Expected results
        String expectedCountryCode = 'US';
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.FAILURE;
        Id expectedOrderSummaryId = null;
        Id expectedOrderId = null;
        Id expectedFulfillmentOrderId = null;

        // Create Payload
        ORS_OrderHelperMatchRestService.OrderRequestPayload requestPayload = createPayload_basic();
        requestPayload.order = null;

        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/match';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;

        // Call the REST service method
        Test.startTest();
        SharedModels.RESTResponse response = ORS_OrderHelperMatchRestService.doPost();
        Test.stopTest();

        // Assertions
        System.assertEquals(expectedCountryCode, response.countryCode);
        System.assertEquals(expectedStatus, response.status);
        System.assertEquals(expectedOrderId, ORS_OrderHelperMatchRestService.responsePayload.orderId);
        System.assertEquals(expectedFulfillmentOrderId, ORS_OrderHelperMatchRestService.responsePayload.fulfillmentOrderId);
    }

    public static ORS_OrderHelperMatchRestService.OrderRequestPayload createPayload_basic() {
        ORS_OrderHelperMatchRestService.OrderRequestPayload requestPayload = new ORS_OrderHelperMatchRestService.OrderRequestPayload();
        ORS_OrderHelperMatchRestService.Order order = new ORS_OrderHelperMatchRestService.Order();
        order.customerNumber = 288801;
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