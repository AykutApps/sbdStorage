/*
    This class provides REST services for handling Fulfillment/OrderSummary match.
 
    Endpoint: /services/apexrest/ir-erp-order-helper/match
    Method: POST
    
    This endpoint covers 4 use cases.

    ------------------------ Case1: Match on fulfillment based on uniqueId  ------------------------
    Request:
        {
            "order": {
                "customerNumber": 288801,
                "orderNumber": "1923400",
                "companyCode": "38",
                "uniqueId": "admintest02",
                "orderDate": "2023-11-17",
                "requestedDate": "2023-11-21",
                "poNumber": "CC23-32_2",
                "externalOrderNumber": "02151179"
            }
        }

    Response:
        {
            "status": "SUCCESS",
            "faultDescription": "",
            "data": {
                "uniqueId": "admintest02",
                "orderSummaryId": "1Os230000004L1mCAE",
                "orderItemSummaries": [
                    {
                        "itemNumber": "13AOA1CS009",
                        "id": "10u230000004MC1AAM"
                    },
                    {
                        "itemNumber": "OTH-SHIPPING CHARGE FOR THIS DELIVERY METHOD",
                        "id": "10u230000004MC2AAM"
                    }
                ],
                "orderId": "801230000031zj9AAA",
                "newOrders": "no",
                "fulfillmentOrderId": null,
                "fulfillmentOrder": {
                    "status": "Allocated",
                    "id": "0a3Dh0000008WiHIAU",
                    "fulfillmentOrderLineItems": [
                        {
                            "quantity": 4,
                            "originalQuantity": 4,
                            "itemNumber": "13AOA1CS009",
                            "id": "0a4Dh0000008gQMIAY",
                            "externalKey": "QAD_USA_PARTS_1923401_1"
                        },
                        {
                            "quantity": 4,
                            "originalQuantity": 4,
                            "itemNumber": "13AOA1CS009",
                            "id": "0a4Dh0000008gQRIAY",
                            "externalKey": "QAD_USA_PARTS_1923401_2"
                        }
                    ],
                    "externalKey": "QAD_USA_PARTS_1923401"
                }
            },
            "countryCode": "US"
        }
    ------------------------ Case2: Match on OrderSummary based on externalOrderNumber  ------------
    Request:
        {
            "order": {
                "customerNumber": 288801,
                "orderNumber": "1923400",
                "companyCode": "38",
                "uniqueId": "notvalidId",
                "orderDate": "2023-11-17",
                "requestedDate": "2023-11-21",
                "poNumber": "CC23-32_2",
                "externalOrderNumber": "02197974"
            }
        }

    Response:
        {
            "status": "SUCCESS",
            "faultDescription": "",
            "data": {
                "uniqueId": "notvalidId",
                "orderSummaryId": "1Os230000004L8TCAU",
                "orderItemSummaries": [
                    {
                        "itemNumber": "17RIEACZ010",
                        "id": "10u230000004MIjAAM"
                    },
                    {
                        "itemNumber": "14BQA3CZ010",
                        "id": "10u230000004MIkAAM"
                    },
                    {
                        "itemNumber": "13BQA1CZ010",
                        "id": "10u230000004MIlAAM"
                    },
                    {
                        "itemNumber": "13AJA1CS010",
                        "id": "10u230000004MImAAM"
                    },
                    {
                        "itemNumber": "17RIEACO010",
                        "id": "10u230000004MInAAM"
                    },
                    {
                        "itemNumber": "14BQA3CA010",
                        "id": "10u230000004MIoAAM"
                    },
                    {
                        "itemNumber": "17RREACA010",
                        "id": "10u230000004MIpAAM"
                    },
                    {
                        "itemNumber": "17RSDGHD010",
                        "id": "10u230000004MIqAAM"
                    }
                ],
                "orderId": "8012300000322ZwAAI",
                "newOrders": "no",
                "fulfillmentOrderId": null,
                "fulfillmentOrder": null
            },
            "countryCode": "US"
        }
    
    ------------------------ Case3: Match on Fulfillment based on externalOrderNumber  ------------
    Request:
        {
            "order": {
                "customerNumber": 288801,
                "orderNumber": "1923400",
                "companyCode": "38",
                "uniqueId": "notvalidId",
                "orderDate": "2023-11-17",
                "requestedDate": "2023-11-21",
                "poNumber": "CC23-32_2",
                "externalOrderNumber": "admintest02"
            }
        }

    Response:
        {
            "status": "SUCCESS",
            "faultDescription": "",
            "data": {
                "uniqueId": "notvalidId",
                "orderSummaryId": "1Os230000004L1mCAE",
                "orderItemSummaries": [
                    {
                        "itemNumber": "13AOA1CS009",
                        "id": "10u230000004MC1AAM"
                    },
                    {
                        "itemNumber": "OTH-SHIPPING CHARGE FOR THIS DELIVERY METHOD",
                        "id": "10u230000004MC2AAM"
                    }
                ],
                "orderId": null,
                "newOrders": "no",
                "fulfillmentOrderId": null,
                "fulfillmentOrder": {
                    "status": "Allocated",
                    "id": "0a3Dh0000008WiHIAU",
                    "fulfillmentOrderLineItems": [
                        {
                            "quantity": 4,
                            "originalQuantity": 4,
                            "itemNumber": "13AOA1CS009",
                            "id": "0a4Dh0000008gQMIAY",
                            "externalKey": "QAD_USA_PARTS_1923401_1"
                        },
                        {
                            "quantity": 4,
                            "originalQuantity": 4,
                            "itemNumber": "13AOA1CS009",
                            "id": "0a4Dh0000008gQRIAY",
                            "externalKey": "QAD_USA_PARTS_1923401_2"
                        }
                    ],
                    "externalKey": "QAD_USA_PARTS_1923401"
                }
            },
            "countryCode": "US"
        }

    ------------------------ Case4: No Match  ------------------------------------------------------
    Request:
        {
            "order": {
                "customerNumber": 288801,
                "orderNumber": "1923400",
                "companyCode": "38",
                "uniqueId": "NOTValid",
                "orderDate": "2023-11-17",
                "requestedDate": "2023-11-21",
                "poNumber": "CC23-32_2",
                "externalOrderNumber": "NOTValid"
            }
        }
    
    Response:
        {
            "status": "SUCCESS",
            "faultDescription": "",
            "data": {
                "uniqueId": "NOTValid",
                "orderSummaryId": null,
                "orderItemSummaries": null,
                "orderId": null,
                "newOrders": "yes",
                "fulfillmentOrderId": null,
                "fulfillmentOrder": null
            },
            "countryCode": "US"
        }
*/

@RestResource(urlMapping='/ir-erp-order-helper/match')
global class ORS_OrderHelperMatchRestService implements RESTHostedMTDEndpoint {
    // Member properties
    global static RESTHostedMTDEndpointHelper endpointHelper;
    private static final String PAYLOAD_TYPE = 'sbd-outdoor-json-erp-order-helper-match';
    private static final String BASE_REST_ENDPOINT = '/ir-erp-order-helper/match';
    private static final Integer MIN_PAYLOAD_SIZE = 44;
    private static final Integer MAX_PAYLOAD_FIELD_SIZE = 5000;
    private static final Integer MAX_PAYLOAD_SIZE = MAX_PAYLOAD_FIELD_SIZE;
    private static final String BASE_SOBJECT_API_NAME = 'OrderSummary';

    private static List<String> errs = new List<String>();
    public static ResponsePayload responsePayload = new ResponsePayload();

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
    private static void logRequest() {
        String codeIdentifier = 'POST';
        String description = 'POST: Order Match Request';
        String extendedInformation = RestContext.request.requestBody.toString().left(32760);
        SystemLogHelper.insertSystemLog('ORS_OrderHelperMatchRestService', codeIdentifier, UserInfo.getUserId(), description, extendedInformation);
    }

    private static void logResponse(SharedModels.RESTResponse response) {
        String codeIdentifier = 'POST';
        String description = 'POST: Order Match Response';
        String extendedInformation = JSON.serialize(response).left(32760);
        SystemLogHelper.insertSystemLog('ORS_OrderHelperMatchRestService', codeIdentifier, UserInfo.getUserId(), description, extendedInformation);
    }

    private static SharedModels.RESTResponse generateResponse() {
        OrderRequestPayload orderRequestPayload = new OrderRequestPayload();
        SharedModels.RESTResponse response = new SharedModels.RESTResponse();

        try {
            orderRequestPayload = (OrderRequestPayload) JSON.deserialize(RestContext.request.requestBody.toString(), OrderRequestPayload.class);

            //validate payload
            validateRequestPayload(orderRequestPayload);

            // Response Logic
            FulfillmentOrder[] fulfilmentOrdersBasedOnUniqueId = (String.isBlank(orderRequestPayload.order.uniqueId))
                ? new List<FulfillmentOrder>()
                : [
                      SELECT
                          Id,
                          ERP_UniqueId__c,
                          OrderId,
                          OrderSummary.OriginalOrderId,
                          OrderSummaryId,
                          External_Key__c,
                          Status,
                          (
                              SELECT Id, FulfillmentOrderLineItemNumber, Quantity, OriginalQuantity, External_Key__c, Product2.Product_Code_External_ID__c
                              FROM FulfillmentOrderLineItems
                          )
                      FROM FulfillmentOrder
                      WHERE Status != 'Cancelled' AND ERP_UniqueId__c = :orderRequestPayload.order.uniqueId
                      LIMIT 1
                  ];

            OrderSummary[] orderSummaries = (String.isBlank(orderRequestPayload.order.externalOrderNumber))
                ? new List<OrderSummary>()
                : [
                      SELECT Id, OrderNumber, OriginalOrderId
                      FROM OrderSummary
                      WHERE OrderNumber = :orderRequestPayload.order.externalOrderNumber
                      LIMIT 1
                  ];

            FulfillmentOrder[] fulfilmentOrdersBasedOnExOrdNumb = (String.isBlank(orderRequestPayload.order.externalOrderNumber))
                ? new List<FulfillmentOrder>()
                : [
                      SELECT
                          Id,
                          ERP_UniqueId__c,
                          OrderId,
                          OrderSummary.OriginalOrderId,
                          OrderSummaryId,
                          External_Key__c,
                          Status,
                          (
                              SELECT Id, FulfillmentOrderLineItemNumber, Quantity, OriginalQuantity, External_Key__c, Product2.Product_Code_External_ID__c
                              FROM FulfillmentOrderLineItems
                          )
                      FROM FulfillmentOrder
                      WHERE Status != 'Cancelled' AND ERP_UniqueId__c = :orderRequestPayload.order.externalOrderNumber
                      LIMIT 1
                  ];

            OrderSummary[] orderSummariesBasedOnExternalKey = (String.isBlank(orderRequestPayload.order.uniqueId))
                ? new List<OrderSummary>()
                : [
                      SELECT Id, OrderNumber, OriginalOrderId
                      FROM OrderSummary
                      WHERE OriginalOrder.External_Key__c = :orderRequestPayload.order.uniqueId
                      LIMIT 1
                  ];

            if (!fulfilmentOrdersBasedOnUniqueId.isEmpty()) {
                responsePayload.uniqueId = orderRequestPayload.order.uniqueId;
                responsePayload.orderId = fulfilmentOrdersBasedOnUniqueId[0].OrderSummary.OriginalOrderId;
                responsePayload.orderSummaryId = fulfilmentOrdersBasedOnUniqueId[0].OrderSummaryId;
                responsePayload.orderItemSummaries = getOrderItemSummariesPayload(fulfilmentOrdersBasedOnUniqueId[0].OrderSummaryId);
                responsePayload.fulfillmentOrder = getFulfillmentPayload(fulfilmentOrdersBasedOnUniqueId[0]);
                responsePayload.fulfillmentOrderId = fulfilmentOrdersBasedOnUniqueId[0].Id;
                responsePayload.newOrders = 'no';
            } else if (!orderSummaries.isEmpty()) {
                responsePayload.uniqueId = orderRequestPayload.order.uniqueId;
                responsePayload.orderId = orderSummaries[0].OriginalOrderId;
                responsePayload.orderSummaryId = orderSummaries[0].Id;
                responsePayload.orderItemSummaries = getOrderItemSummariesPayload(orderSummaries[0].Id);
                responsePayload.fulfillmentOrderId = null;
                responsePayload.newOrders = 'no';
            } else if (!fulfilmentOrdersBasedOnExOrdNumb.isEmpty()) {
                responsePayload.uniqueId = orderRequestPayload.order.uniqueId;
                responsePayload.orderId = fulfilmentOrdersBasedOnExOrdNumb[0].OrderId;
                responsePayload.orderSummaryId = fulfilmentOrdersBasedOnExOrdNumb[0].OrderSummaryId;
                responsePayload.fulfillmentOrderId = fulfilmentOrdersBasedOnExOrdNumb[0].Id;
                responsePayload.orderItemSummaries = getOrderItemSummariesPayload(fulfilmentOrdersBasedOnExOrdNumb[0].OrderSummaryId);
                responsePayload.fulfillmentOrder = getFulfillmentPayload(fulfilmentOrdersBasedOnExOrdNumb[0]);
                responsePayload.newOrders = 'no';
            } else if (!orderSummariesBasedOnExternalKey.isEmpty()) {
                responsePayload.uniqueId = orderRequestPayload.order.uniqueId;
                responsePayload.orderId = orderSummariesBasedOnExternalKey[0].OriginalOrderId;
                responsePayload.orderSummaryId = orderSummariesBasedOnExternalKey[0].Id;
                responsePayload.orderItemSummaries = getOrderItemSummariesPayload(orderSummariesBasedOnExternalKey[0].Id);
                responsePayload.fulfillmentOrderId = null;
                responsePayload.newOrders = 'no';
            } else {
                responsePayload.orderId = null;
                responsePayload.orderSummaryId = null;
                responsePayload.fulfillmentOrderId = null;
                responsePayload.uniqueId = orderRequestPayload.order.uniqueId;
                responsePayload.newOrders = 'yes';
            }

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

    private static FulfillmentOrder2 getFulfillmentPayload(FulfillmentOrder fulfillment) {
        FulfillmentOrder2 fulfilment2 = new FulfillmentOrder2();
        fulfilment2.id = fulfillment.Id;
        fulfilment2.status = fulfillment.Status;
        fulfilment2.externalKey = fulfillment.External_Key__c;

        List<FulfillmentOrderLineItem2> fulfillmentOrderLineItems = new List<FulfillmentOrderLineItem2>();
        for (FulfillmentOrderLineItem foi : fulfillment.FulfillmentOrderLineItems) {
            fulfillmentOrderLineItems.add(new FulfillmentOrderLineItem2(foi));
        }
        fulfilment2.fulfillmentOrderLineItems = fulfillmentOrderLineItems;
        return fulfilment2;
    }

    private static List<OrderItemSummary2> getOrderItemSummariesPayload(String orderSummaryId) {
        List<OrderItemSummary2> orderItemSummaries = new List<OrderItemSummary2>();
        for (OrderItemSummary ois : [SELECT Id, Product2.Product_Code_External_ID__c FROM OrderItemSummary WHERE OrderSummaryId = :orderSummaryId]) {
            orderItemSummaries.add(new OrderItemSummary2(ois));
        }
        return orderItemSummaries;
    }

    private static void validateRequestPayload(OrderRequestPayload orderRequestPayload) {
        if (String.isBlank(orderRequestPayload.order.uniqueId) && String.isBlank(orderRequestPayload.order.externalOrderNumber)) {
            errs.add('Missing uniqueId or externalOrderNumber.');
        }

        if (orderRequestPayload.order == null) {
            errs.add('Missing payload.');
        }

        // if (!String.isBlank(orderRequestPayload.order.externalOrderNumber)) {
        //     if (Integer.valueOf(orderRequestPayload.order.externalOrderNumber) > 2900000 || Integer.valueOf(orderRequestPayload.order.externalOrderNumber) < 2000000)
        //         errs.add('externalOrderNumber must be within the range 2,000,000 and 2,900,000.');
        // }
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
        out.countryCode = 'US';
        out.data = null;
        out.faultDescription = (errs == null || errs.isEmpty()) ? '[MTD returnFailure - Error not specified]' : JSON.serialize(errs);

        return out;
    }

    public class CustomException extends Exception {
    }

    // Data Models
    public class ResponsePayload extends SharedModels.Data {
        public String uniqueId;
        public String orderSummaryId;
        public String orderId;
        public List<OrderItemSummary2> orderItemSummaries;
        public FulfillmentOrder2 fulfillmentOrder;
        public String fulfillmentOrderId;
        public String newOrders;
    }

    public class OrderItemSummary2 {
        public String id;
        public String itemNumber;

        public OrderItemSummary2(OrderItemSummary ois) {
            this.id = ois.Id;
            this.itemNumber = ois.Product2.Product_Code_External_ID__c;
        }
    }

    public class FulfillmentOrder2 {
        public String id;
        public String status;
        public String externalKey;
        public List<FulfillmentOrderLineItem2> fulfillmentOrderLineItems;
    }

    public class FulfillmentOrderLineItem2 {
        public String id;
        public String itemNumber;
        public Decimal originalQuantity;
        public Decimal quantity;
        public String externalKey;

        public FulfillmentOrderLineItem2(FulfillmentOrderLineItem foi) {
            this.id = foi.Id;
            this.itemNumber = foi.Product2.Product_Code_External_ID__c;
            this.originalQuantity = foi.Quantity;
            this.quantity = foi.OriginalQuantity;
            this.externalKey = foi.External_Key__c;
        }
    }

    public class OrderRequestPayload {
        public Order order;
    }

    public class Order {
        public Integer customerNumber;
        public String orderNumber;
        public Integer companyCode;
        public String uniqueId;
        public Date orderDate;
        public Date requestedDate;
        public String poNumber;
        public String externalOrderNumber;
    }
}
