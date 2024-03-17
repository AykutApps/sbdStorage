@isTest
private class ORS_OrderHelperMatchRestServiceTest {
    @isTest
    static void testPostMethod() {
        // Test data setup
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

        String requestBody = JSON.serialize(requestPayload);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/match';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        // Call the REST service method
        Test.startTest();
        SharedModels.RESTResponse response = ORS_OrderHelperMatchRestService.doPost();
        Test.stopTest();

        // Assertions
        System.assertEquals('US', response.countryCode);
        System.assertEquals(SharedModels.ResponseStatus.SUCCESS, response.status);
        System.assertNotEquals(null, response.data);
    }
}
