/*
 This class provides REST services for handling order helper status.
 
  Endpoint: /services/apexrest/ir-erp-order-helper/status
  Method: POST
 
  Sample Request Body:
  {
      "order": {
          "sfOrderId": "801A0000000Z4cLIAS",
          "transactionId": "xx-aa123-edf",
          "customerNumber": 288801,
          "orderNumber": "1923400",
          "companyCode": 38,
          "uniqueId": "38_1923400",
          "orderDate": "2023-11-17",
          "requestedDate": "2023-11-21",
          "poNumber": "CC23-32_2",
          "externalOrderNumber": "02151179"
      }
  }
 
  Sample Response:
  {
      "status": "SUCCESS",
      "faultDescription": "",
      "data": {
          "uniqueId": "38_1923400",
          "transactionId": "xx-aa123-edf",
          "status": "complete",
          "retryCount": 1
      },
      "countryCode": "US"
  }
 */

@RestResource(urlMapping='/ir-erp-order-helper/status')
global class ORS_OrderHelperStatusRestService implements RESTHostedMTDEndpoint {
    // Member properties
    global static RESTHostedMTDEndpointHelper endpointHelper;
    private static final String PAYLOAD_TYPE = 'sbd-outdoor-json-erp-order-helper-status';
    private static final String ERROR_CODE = 'sbd-outdoor-json-erp-order-helper-status-error';
    private static final String BASE_REST_ENDPOINT = '/ir-erp-order-helper/status';
    private static final Integer MIN_PAYLOAD_SIZE = 44;
    private static final Integer MAX_PAYLOAD_FIELD_SIZE = 5000;
    private static final Integer MAX_PAYLOAD_SIZE = MAX_PAYLOAD_FIELD_SIZE;
    private static final String BASE_SOBJECT_API_NAME = 'Order';

    // Call Varaiables
    private static Response2 response = new Response2();
    private static ResponsePayload responsePayload = new ResponsePayload();
    private static OrderRequestPayload orderRequestPayload;
    private static Agora_Transaction__c agoraTransaction;
    private static List<String> errs = new List<String>();
    private static List<Exception> exps = new List<Exception>();
    private static OrderSummary orderSummary;

    // Main method
    @HTTPPost
    global static SharedModels.RESTResponse doPost() {
        //Log request
        logRequest();

        // generate response
        generateResponse();

        // log response
        logResponse();

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

    // Error Response Handlers
    //private static SharedModels.RESTResponse returnFailure(Integer htmlStatusCode, List<String> errs) {
    private static void returnFailure(Integer htmlStatusCode) {
        createErrorResponse(htmlStatusCode, 400);
    }

    //private static SharedModels.RESTResponse returnBusinessRuleFailure(Integer htmlStatusCode, List<String> errs) {
    private static void returnBusinessRuleFailure(Integer htmlStatusCode) {
        createErrorResponse(htmlStatusCode, 409);
    }

    //private static SharedModels.RESTResponse createErrorResponse(Integer htmlStatusCode, List<String> errs, Integer defaultStatusCode) {
    private static void createErrorResponse(Integer htmlStatusCode, Integer defaultStatusCode) {
        RestContext.response.statusCode = (htmlStatusCode == null || htmlStatusCode < 200 || htmlStatusCode > 503) ? defaultStatusCode : htmlStatusCode;
        response.status = SharedModels.ResponseStatus.FAILURE;
        response.faultDescription = (errs == null || errs.isEmpty()) ? '[MTD returnFailure - Error not specified]' : JSON.serialize(errs);

        Failure failure = new Failure();
        failure.relatedId = orderRequestPayload.order.sfOrderId;
        failure.objectName = 'Order';
        failure.errorCode = ERROR_CODE;
        if (exps.size() > 0) {
            failure.errorStack = exps[0].getStackTraceString();
            failure.errorMessage = exps[0].getMessage();
        }

        response.failure = failure;
    }

    // Helper methods
    private static void validateRequest() {
    }

    private static void logRequest() {
        String codeIdentifier = 'POST';
        String description = 'POST: Status Request';
        String extendedInformation = RestContext.request.requestBody.toString().left(32760);
        SystemLogHelper.insertSystemLog('ORS_OrderHelperStatusRestService', codeIdentifier, UserInfo.getUserId(), description, extendedInformation);
    }

    private static void logResponse() {
        String codeIdentifier = 'POST';
        String description = 'POST: Status Response';
        String extendedInformation = JSON.serialize(response).left(32760);
        SystemLogHelper.insertSystemLog('ORS_OrderHelperStatusRestService', codeIdentifier, UserInfo.getUserId(), description, extendedInformation);
    }

    private static String getOrderSummaryCreationStatus() {
        OrderSummary[] orderSummaries = [
            SELECT Id, (SELECT Id, Product2.Product_Code_External_ID__c FROM OrderItemSummaries)
            FROM OrderSummary
            WHERE OriginalOrderId = :orderRequestPayload.order.sfOrderId
        ];
        if (orderSummaries.size() == 0) {
            return 'Pending';
        } else {
            orderSummary = orderSummaries[0];
            return 'Complete';
        }
    }

    private static Agora_Transaction__c upsertAgoraTransaction() {
        Agora_Transaction__c[] agoraTransactions = [
            SELECT Id, Order_Summary_Process_Status__c, Retry_Count__c
            FROM Agora_Transaction__c
            WHERE Agora_Transaction_Id__c = :orderRequestPayload.order.transactionId
        ];
        String orderSumaryStatus = getOrderSummaryCreationStatus();
        if (agoraTransactions.size() == 0) {
            agoraTransaction = new Agora_Transaction__c();
            agoraTransaction.Agora_Transaction_Id__c = orderRequestPayload.order.transactionId;
            agoraTransaction.ERP_Customer_Number__c = orderRequestPayload.order.customerNumber;
            agoraTransaction.ERP_Order_Date__c = orderRequestPayload.order.orderDate;
            agoraTransaction.ERP_Order_Ref__c = orderRequestPayload.order.externalOrderNumber;
            agoraTransaction.ERP_Order_Unique_Key__c = orderRequestPayload.order.uniqueId;
            agoraTransaction.Retry_Count__c = 1;
            agoraTransaction.SF_Order_Id__c = orderRequestPayload.order.sfOrderId;
            agoraTransaction.Order_Summary_Process_Status__c = orderSumaryStatus;

            insert agoraTransaction;
        } else {
            agoraTransaction = agoraTransactions[0];
            agoraTransaction.Retry_Count__c = agoraTransaction.Retry_Count__c + 1;
            agoraTransaction.Order_Summary_Process_Status__c = (agoraTransaction.Retry_Count__c > 3) ? 'Error' : orderSumaryStatus;
            update agoraTransaction;
        }

        return agoraTransaction;
    }

    public static List<OrderItemSummary2> generateOrderItemSummaries() {
        List<OrderItemSummary2> oiss = new List<OrderItemSummary2>();
        if (orderSummary == null || orderSummary.OrderItemSummaries == null) {
            return null;
        }
        for (OrderItemSummary ois : orderSummary.OrderItemSummaries) {
            oiss.add(new OrderItemSummary2(ois));
        }
        return oiss;
    }

    private static Response2 generateResponse() {
        try {
            orderRequestPayload = (OrderRequestPayload) JSON.deserialize(RestContext.request.requestBody.toString(), OrderRequestPayload.class);
            // upsert AgoraTransaction
            agoraTransaction = upsertAgoraTransaction();

            // create Response Payload
            responsePayload.uniqueId = orderRequestPayload.order.uniqueId;
            responsePayload.transactionId = orderRequestPayload.order.transactionId;
            responsePayload.order = orderRequestPayload.order;
            responsePayload.orderSummaryId = orderSummary?.Id;
            responsePayload.orderId = orderRequestPayload.order.sfOrderId;
            responsePayload.orderItemSummaries = generateOrderItemSummaries();

            // Setup the response
            response.countryCode = 'US';
            response.status = SharedModels.ResponseStatus.SUCCESS;
            response.data = responsePayload;
            response.reTryCount = agoraTransaction.Retry_Count__c;
            response.action = agoraTransaction.Order_Summary_Process_Status__c;
        } catch (Exception ex) {
            errs.add(ex.getMessage());
            errs.add(ex.getStackTraceString());
            exps.add(ex);
        }

        if (!errs.isEmpty()) {
            returnFailure(400);
        }

        return response;
    }

    // Data Models
    public class OrderRequestPayload {
        public Order order;
    }

    public class Response2 extends SharedModels.RESTResponse {
        public Decimal reTryCount;
        public String action;
        public Failure failure;
    }

    public class ResponsePayload extends SharedModels.Data {
        public String uniqueId;
        public String transactionId;
        public String orderSummaryId;
        public String orderId;
        public List<OrderItemSummary2> orderItemSummaries;
        public Order order;
    }

    public class Order {
        public String sfOrderId;
        public String transactionId;
        public Integer customerNumber;
        public String orderNumber;
        public Integer companyCode;
        public String uniqueId;
        public Date orderDate;
        public Date requestedDate;
        public String poNumber;
        public String externalOrderNumber;
    }

    public class Failure {
        public String relatedId;
        public String objectName;
        public String errorCode;
        public String errorMessage;
        public String errorStack;
    }

    public class OrderItemSummary2 {
        public String id;
        public String itemNumber;

        public OrderItemSummary2(OrderItemSummary ois) {
            this.id = ois.Id;
            this.itemNumber = ois.Product2.Product_Code_External_ID__c;
        }
    }
}
