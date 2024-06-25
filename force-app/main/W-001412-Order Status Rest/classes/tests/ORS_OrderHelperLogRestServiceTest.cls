@isTest
public with sharing class ORS_OrderHelperLogRestServiceTest {
    @isTest
    static void testLog_post_basic() {
        String expectedStatus = 'Processed';
        ORS_OrderHelperLogRestService.OrderRequestPayload requestPayload = createPayload_basic();
        String requestBody = JSON.serialize(requestPayload);
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/log';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;
        // RestContext response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();

        SharedModels.RESTResponse response = ORS_OrderHelperLogRestService.doPost();
        ORS_OrderHelperLogRestService.getPayloadType();
        ORS_OrderHelperLogRestService.getBaseRESTEndpoint();
        ORS_OrderHelperLogRestService.getMinPayloadSize();
        ORS_OrderHelperLogRestService.getMaxPayloadFieldSize();
        ORS_OrderHelperLogRestService.getBaseSObjectAPIName();
        ORS_OrderHelperLogRestService.getMaxPayloadSize();
        Test.stopTest();

        // Assertions
        REST_Inbound_Payload__c ri = [SELECT Id, Payload_Transaction_Id__c, Payload_Unique_Id__c, Status__c FROM REST_Inbound_Payload__c];
        System.assertEquals(expectedStatus, ri.Status__c);
    }

    @isTest
    static void testLog_post_200_successLog() {
        String expectedStatus = 'Processed';
        String expectedTransactionId = 'trId01';
        String expectedUniqueId = 'uqId01';

        ORS_OrderHelperLogRestService.OrderRequestPayload requestPayload = createPayload_basic();
        String requestBody = JSON.serialize(requestPayload);
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/log';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;
        // RestContext response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        SharedModels.RESTResponse response = ORS_OrderHelperLogRestService.doPost();
        Test.stopTest();

        // Assertions
        REST_Inbound_Payload__c ri = [SELECT Id, Payload_Transaction_Id__c, Payload_Unique_Id__c, Status__c FROM REST_Inbound_Payload__c];
        System.assertEquals(expectedStatus, ri.Status__c);
        System.assertEquals(expectedTransactionId, ri.Payload_Transaction_Id__c);
        System.assertEquals(expectedUniqueId, ri.Payload_Unique_Id__c);
    }

    @isTest
    static void testLog_post_200_errorLog() {
        String expectedStatus = 'Error';
        String expectedTransactionId = 'trId01';
        String expectedUniqueId = 'uqId01';

        ORS_OrderHelperLogRestService.OrderRequestPayload requestPayload = createPayload_basic();
        requestPayload.type = 'Error';
        String requestBody = JSON.serialize(requestPayload);
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/log';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;
        // RestContext response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        SharedModels.RESTResponse response = ORS_OrderHelperLogRestService.doPost();
        Test.stopTest();

        // Assertions
        REST_Inbound_Payload__c ri = [SELECT Id, Payload_Transaction_Id__c, Payload_Unique_Id__c, Status__c FROM REST_Inbound_Payload__c];
        System.assertEquals(expectedStatus, ri.Status__c);
        System.assertEquals(expectedTransactionId, ri.Payload_Transaction_Id__c);
        System.assertEquals(expectedUniqueId, ri.Payload_Unique_Id__c);
    }

    @isTest
    static void testLog_post_400_validationError_invalidTransactionId() {
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.FAILURE;

        ORS_OrderHelperLogRestService.OrderRequestPayload requestPayload = createPayload_basic();
        requestPayload.type = 'Success';
        requestPayload.transactionId = null;

        String requestBody = JSON.serialize(requestPayload);
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/log';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;
        // RestContext response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        SharedModels.RESTResponse response = ORS_OrderHelperLogRestService.doPost();
        Test.stopTest();

        // Assertions
        System.assertEquals(expectedStatus, response.status);
    }

    @isTest
    static void testLog_post_400_validationError_invalidErrorCode() {
        SharedModels.ResponseStatus expectedStatus = SharedModels.ResponseStatus.FAILURE;

        ORS_OrderHelperLogRestService.OrderRequestPayload requestPayload = createPayload_basic();
        requestPayload.type = 'Error';
        requestPayload.failure = new ORS_OrderHelperLogRestService.Failure();
        requestPayload.failure.errorCode = '';

        String requestBody = JSON.serialize(requestPayload);
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ir-erp-order-helper/log';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        // RestContext
        RestContext.request = req;
        // RestContext response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        SharedModels.RESTResponse response = ORS_OrderHelperLogRestService.doPost();
        Test.stopTest();

        // Assertions
        System.assertEquals(expectedStatus, response.status);
    }

    public static ORS_OrderHelperLogRestService.OrderRequestPayload createPayload_basic() {
        ORS_OrderHelperLogRestService.OrderRequestPayload requestPayload = new ORS_OrderHelperLogRestService.OrderRequestPayload();
        requestPayload.type = 'Success';
        requestPayload.transactionId = 'trId01';
        requestPayload.uniqueId = 'uqId01';
        requestPayload.failure = null;
        requestPayload.data = 'sample json payload';

        return requestPayload;
    }
}