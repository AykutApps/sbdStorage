/*
    This class provides REST services for logging. This logs the request in the REST_Inbound_Payload__c object.

    Endpoint: /services/apexrest/ir-erp-order-helper/log
    Method: POST
    
    Sample Request:
        {
            "type": "Sucess",
            "transactionId": "xx-aa123-edf",
            "uniqueId": "38_1923400",
            "failure": {
                "relatedId": "801A0000000Z4cLIAS",
                "objectName": "Order",
                "errorCode": "SBD_B2B_MAX_RETRY_ERROR",
                "errorMessage": "Max re-try's reached ",
                "errorStack": null
            },
            "data":"<json>"
        }
    
    Sample Response:
        {
            "status": "SUCCESS",
            "faultDescription": "",
            "data": {
                "uniqueId": "38_1923400",
                "transactionId": "xx-aa123-edf",
                "status": null,
                "relatedId": "801A0000000Z4cLIAS",
                "objectName": "Order"
            },
            "countryCode": "US"
        }
*/

@RestResource(urlMapping='/ir-erp-order-helper/log')
global class ORS_OrderHelperLogRestService implements RESTHostedMTDEndpoint {
    // Member properties
    global static RESTHostedMTDEndpointHelper endpointHelper;
    private static final String PAYLOAD_TYPE = 'sbd-outdoor-json-erp-order-helper-log';
    private static final String BASE_REST_ENDPOINT = '/ir-erp-order-helper/log';
    private static final Integer MIN_PAYLOAD_SIZE = 44;
    private static final Integer MAX_PAYLOAD_FIELD_SIZE = 5000;
    private static final Integer MAX_PAYLOAD_SIZE = 131072;
    private static final String BASE_SOBJECT_API_NAME = 'OrderSummary';
    private static List<String> errs = new List<String>();

    // Main method
    @HTTPPost
    global static SharedModels.RESTResponse doPost() {
        //Log request
        logRequest();

        // generate response
        SharedModels.RESTResponse response = generateResponse();

        // log response
        logResponse(response);

        // return response
        return response;
    }

    // Implement Inmterface
    global static String getPayloadType() {
        fetchEndpointHelper();
        return endpointHelper.payloadType;
    }

    global static String getBaseRESTEndpoint() {
        fetchEndpointHelper();
        return endpointHelper.baseRESTEndpoint;
    }

    global static Integer getMinPayloadSize() {
        fetchEndpointHelper();
        return endpointHelper.minPayloadSize;
    }

    global static Integer getMaxPayloadSize() {
        fetchEndpointHelper();
        return endpointHelper.maxPayloadSize;
    }

    global static Integer getMaxPayloadFieldSize() {
        return MAX_PAYLOAD_FIELD_SIZE;
    }

    global static String getBaseSObjectAPIName() {
        fetchEndpointHelper();
        return endpointHelper.baseSObjectAPIName;
    }

    public static void fetchEndpointHelper() {
        if (endpointHelper == null) {
            endpointHelper = new RESTHostedMTDEndpointHelper(PAYLOAD_TYPE, BASE_REST_ENDPOINT, MIN_PAYLOAD_SIZE, MAX_PAYLOAD_SIZE, BASE_SOBJECT_API_NAME);
        }
    }

    // Helper methods
    private static void validateRequest(OrderRequestPayload orderRequestPayload) {
        // if (String.isBlank(orderRequestPayload.uniqueId)) {
        //     errs.add('Invalid uniqueId');
        // }
        if (String.isBlank(orderRequestPayload.transactionId)) {
            errs.add('Invalid transactionId');
        }
        if (orderRequestPayload.failure != null && String.isBlank(orderRequestPayload.failure.errorCode) && orderRequestPayload.type == 'Error') {
            errs.add('Invalid errorCode');
        }
        if (orderRequestPayload.failure != null && String.isBlank(orderRequestPayload.failure.errorMessage) && orderRequestPayload.type == 'Error') {
            errs.add('Invalid errorMessage');
        }
    }

    private static void logRequest() {
        String codeIdentifier = 'POST';
        String description = 'POST: Log Request';
        String extendedInformation = RestContext.request.requestBody.toString().left(32760);
        SystemLogHelper.insertSystemLog('ORS_OrderHelperLogRestService', codeIdentifier, UserInfo.getUserId(), description, extendedInformation);
    }

    private static void logResponse(SharedModels.RESTResponse response) {
        String codeIdentifier = 'POST';
        String description = 'POST: Log Response';
        String extendedInformation = JSON.serialize(response).left(32760);
        SystemLogHelper.insertSystemLog('ORS_OrderHelperLogRestService', codeIdentifier, UserInfo.getUserId(), description, extendedInformation);
    }

    private static void logData(OrderRequestPayload orderRequestPayload) {
        // Create a new REST Inbound Payload record
        REST_Inbound_Payload__c restInboundPayload = new REST_Inbound_Payload__c();

        // Set SObject API Name and Payload Type
        restInboundPayload.SObject_API_Name__c = (orderRequestPayload.type == 'Success') ? orderRequestPayload.objectName: orderRequestPayload.failure?.objectName;
        restInboundPayload.SObject_Label__c = orderRequestPayload.failure?.objectName;
        restInboundPayload.Payload_Type__c = PAYLOAD_TYPE;
        restInboundPayload.Status__c = (orderRequestPayload.type == 'Success') ? 'Processed' : 'Error';
        restInboundPayload.SObject_ID__c = orderRequestPayload.failure?.relatedId;
        restInboundPayload.Payload_Transaction_Id__c = orderRequestPayload.transactionId;
        restInboundPayload.Payload_Unique_Id__c = orderRequestPayload.uniqueId;
        // Code: ..., Message:... , Stack: ....
        String errorDetails =
            'Error Code: ' +
            orderRequestPayload.failure?.errorCode +
            ', Error Message: ' +
            orderRequestPayload.failure?.errorMessage +
            ', Error Stack: ' +
            orderRequestPayload.failure?.errorStack;
        restInboundPayload.Error_Dump__c = errorDetails.left(4000);

        // Calculate the total number of chunks based on payload length and maximum size
        Decimal tmp = orderRequestPayload.data.length() / Decimal.valueOf(MAX_PAYLOAD_SIZE);
        Integer totalChunks = Integer.valueOf(tmp.round(System.RoundingMode.CEILING));

        // Process each chunk of the payload
        for (Integer curChunk = totalChunks; curChunk > 0; curChunk--) {
            Integer chunkStart = (curChunk - 1) * MAX_PAYLOAD_SIZE;
            Integer chunkEnd = Math.min(chunkStart + MAX_PAYLOAD_SIZE, orderRequestPayload.data.length());

            // Set the payload field based on chunk number
            String fieldName = (String.valueOf(curChunk).leftPad(2, '0') == '01') ? 'Payload' + '__c' : 'Payload' + String.valueOf(curChunk).leftPad(2, '0') + '__c';
            restInboundPayload.put(fieldName, orderRequestPayload.data.substring(chunkStart, chunkEnd));
        }

        // Insert the REST Inbound Payload record
        insert restInboundPayload;
    }

    private static SharedModels.RESTResponse generateResponse() {
        OrderRequestPayload orderRequestPayload = new OrderRequestPayload();
        SharedModels.RESTResponse response = new SharedModels.RESTResponse();
        ResponsePayload responsePayload = new ResponsePayload();

        try {
            orderRequestPayload = (OrderRequestPayload) JSON.deserialize(RestContext.request.requestBody.toString(), OrderRequestPayload.class);

            // Response Logic
            logData(orderRequestPayload);

            // Validate Request
            validateRequest(orderRequestPayload);

            // Response Payload
            responsePayload.uniqueId = orderRequestPayload.uniqueId;
            responsePayload.transactionId = orderRequestPayload.transactionId;
            responsePayload.status = null;
            responsePayload.relatedId = orderRequestPayload.failure?.relatedId;
            responsePayload.objectName = orderRequestPayload.failure?.objectName;

            // Setup the response
            response.countryCode = 'US';
            response.status = SharedModels.ResponseStatus.SUCCESS;
            response.data = responsePayload;
        } catch (Exception ex) {
            errs.add(ex.getMessage());
        }

        if (!errs.isEmpty()) {
            response = returnFailure(400, errs);
        }

        return response;
    }

    // Error Methods
    private static SharedModels.RESTResponse returnFailure(Integer htmlStatusCode, List<String> errs) {
        return createErrorResponse(htmlStatusCode, errs, 400);
    }

    private static SharedModels.RESTResponse returnBusinessRuleFailure(Integer htmlStatusCode, List<String> errs) {
        return createErrorResponse(htmlStatusCode, errs, 409);
    }

    private static SharedModels.RESTResponse createErrorResponse(Integer htmlStatusCode, List<String> errs, Integer defaultStatusCode) {
        RestResponse resp = RestContext.response;
        resp.statusCode = (htmlStatusCode == null || htmlStatusCode < 200 || htmlStatusCode > 503) ? defaultStatusCode : htmlStatusCode;

        SharedModels.RESTResponse out = new SharedModels.RESTResponse();
        out.status = SharedModels.ResponseStatus.FAILURE;
        out.data = null;
        out.faultDescription = (errs == null || errs.isEmpty()) ? '[MTD returnFailure - Error not specified]' : JSON.serialize(errs);

        return out;
    }

    // Data Models
    public class OrderRequestPayload {
        public String type;
        public String transactionId;
        public String uniqueId;
        public Failure failure;
        public String data;
        public String objectName;
    }

    public class Failure {
        public String relatedId;
        public String objectName;
        public String errorCode;
        public String errorMessage;
        public String errorStack;
    }

    public class ResponsePayload extends SharedModels.Data {
        public String uniqueId;
        public String transactionId;
        public String status;
        public String relatedId;
        public String objectName;
    }
}