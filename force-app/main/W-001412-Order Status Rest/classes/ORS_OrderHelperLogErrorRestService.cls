/*
 This class provides REST services for handling order helper logerror.
 
  Endpoint: /services/apexrest/ir-erp-order-helper/logerror
  Method: POST
 
  Sample Request Body:
    {
        "failure": {
            "relatedId": "801A0000000Z4cLIAS",
            "ObjectName": "Order",
            "transactionId": "xx-aa123-edf",
            "uniqueId": "38_1923400",
            "errorCode": "SBD_B2B_MAX_RETRY_ERROR",
            "errorMessage": "Max re-try's reached ",
            "errorStack": null
        },
        "orders": [
            {
                "customerNumber": 288801,
                "orderNumber": "1923400",
                "companyCode": 38,
                "uniqueId": "38_1923400",
                "orderType": "PS",
                "orderDate": "2023-11-17",
                "requestedDate": "2023-11-21",
                "status": "50",
                "externalOrderNumber": "02151179",
                "poNumber": "CC23-32_2",
                "shipToAddress": {
                    "shipToCode": "00000001",
                    "name": "JACOBI SALES INC",
                    "address1": "425 MAIN ST. NE",
                    "address2": "",
                    "address3": "",
                    "address4": "",
                    "address5": "",
                    "city": "PALMYRA",
                    "state": "IN",
                    "postalCode": "47164",
                    "country": "US"
                },
                "orderAmount": 724203.00,
                "freightAmount": 0.00,
                "taxAmount": 0.00,
                "totalAmount": 724203.00,
                "currencyCode": "USD",
                "orderHeaderComments": [
                    {
                        "commentDate": "2023-11-17",
                        "commentCode": "RQ",
                        "sequenceNumber": 1
                    },
                    {
                        "commentDate": "2023-11-22",
                        "commentCode": "LS",
                        "sequenceNumber": 17
                    },
                    {
                        "commentDate": "2023-12-11",
                        "commentCode": "IC",
                        "sequenceNumber": 19
                    },
                    {
                        "commentDate": "2024-01-30",
                        "commentCode": "CI",
                        "sequenceNumber": 21
                    },
                    {
                        "commentDate": "2024-01-30",
                        "commentCode": "CO",
                        "sequenceNumber": 23
                    }
                ],
                "lineItems": [
                    {
                        "lineNumber": 1600,
                        "originalLineNumber": 1234,
                        "status": "Deleted",
                        "manufactureDueDate": "2023-11-21",
                        "customerStockLocation": "",
                        "lessThanTruckload": "N",
                        "itemSku": "",
                        "itemNumber": "53UIHTTV050",
                        "originalItemNumber": "53UIHTTV050",
                        "priorItemNumber": "",
                        "itemDescription": "MOWER:PZFL:60:HG4400:KW:700SER",
                        "originalOrderQuantity": 10.00,
                        "orderQuantity": 10.00,
                        "backorderQuantity": 0.00,
                        "customerUnitCost": 9532.000,
                        "orderLineComments": [
                            {
                                "commentDate": "2023-12-11",
                                "commentCode": "IC",
                                "sequenceNumber": 20
                            },
                            {
                                "commentDate": "2024-01-30",
                                "commentCode": "CI",
                                "sequenceNumber": 22
                            }
                        ]
                    },
                    {
                        "lineNumber": 1500,
                        "status": "History",
                        "manufactureDueDate": "2023-11-21",
                        "customerStockLocation": "",
                        "lessThanTruckload": "N",
                        "itemSku": "",
                        "itemNumber": "53RLHUUY050",
                        "originalItemNumber": "",
                        "priorItemNumber": "",
                        "itemDescription": "MOWER:PZFS:72DK:HG5400:KWEFI",
                        "originalOrderQuantity": 3.00,
                        "orderQuantity": 3.00,
                        "backorderQuantity": 0.00,
                        "customerUnitCost": 13650.000,
                        "orderLineComments": [
                            {
                                "commentDate": "2023-11-17",
                                "commentCode": "RQ",
                                "sequenceNumber": 8
                            }
                        ]
                    }
                ],
                "shipHeaders": [
                    {
                        "companyCode": 38,
                        "shipNumber": 1,
                        "shipKey": "1616128",
                        "invoiceNumber": "14399",
                        "invoiceKey": "000001",
                        "shipDate": "2023-12-14",
                        "carrierCode": "PAM",
                        "trackingInfo": [
                            {
                                "trackingNumber": ""
                            }
                        ],
                        "freightCost": 0.00,
                        "shippingItems": [
                            {
                                "itemNumber": "53RLHUUY050",
                                "quantity": 2.00,
                                "serialNumbers": [
                                    "SN1000000",
                                    "SN1000001"
                                ]
                            }
                        ]
                    },
                    {
                        "companyCode": 38,
                        "shipNumber": 2,
                        "shipKey": "1616129",
                        "invoiceNumber": "14400",
                        "invoiceKey": "000001",
                        "shipDate": "2023-12-19",
                        "carrierCode": "PAM",
                        "trackingInfo": [
                            {
                                "trackingNumber": "track001"
                            },
                            {
                                "trackingNumber": "track002"
                            }
                        ],
                        "freightCost": 0.00,
                        "shippingItems": [
                            {
                                "itemNumber": "53UIHTTV050",
                                "quantity": 5.00,
                                "serialNumbers": [
                                    "SN2000000",
                                    "SN2000001",
                                    "SN2000002",
                                    "SN2000003",
                                    "SN2000004"
                                ]
                            },
                            {
                                "itemNumber": "53RLHUUY050",
                                "quantity": 1.00,
                                "serialNumbers": [
                                    "SN1000000",
                                    "SN1000001"
                                ]
                            }
                        ]
                    }
                ]
            }
        ]
    }   
 
  Sample Response:
    {
        "status": "SUCCESS",
        "faultDescription": "",
        "data": {
            "uniqueId": "38_1923400",
            "transactionId": "xx-aa123-edf",
            "status": "Success",
            "relatedId": "XX801A0000000Z4cLIAS",
            "objectName": "Order"
        },
        "countryCode": "US"
    }
 */

@RestResource(urlMapping='/ir-erp-order-helper/logerror')
global class ORS_OrderHelperLogErrorRestService implements RESTHostedMTDEndpoint {
    // Member properties
    global static RESTHostedMTDEndpointHelper endpointHelper;
    private static final String PAYLOAD_TYPE = 'sbd-outdoor-json-erp-order-helper/logerror';
    private static final String BASE_REST_ENDPOINT = '/ir-erp-order-helper/logerror';
    private static final Integer MIN_PAYLOAD_SIZE = 44;
    private static final Integer MAX_PAYLOAD_FIELD_SIZE = 5000;
    private static final Integer MAX_PAYLOAD_SIZE = MAX_PAYLOAD_FIELD_SIZE;
    private static final String BASE_SOBJECT_API_NAME = 'Order';

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

    // Private static methods
    public static void fetchEndpointHelper() {
        if (endpointHelper == null) {
            endpointHelper = new RESTHostedMTDEndpointHelper(PAYLOAD_TYPE, BASE_REST_ENDPOINT, MIN_PAYLOAD_SIZE, MAX_PAYLOAD_SIZE, BASE_SOBJECT_API_NAME);
        }
    }

    // Error Response Handlers
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

    @HTTPPost
    global static SharedModels.RESTResponse doPost() {
        // Initial variables
        SharedModels.RESTResponse response = new SharedModels.RESTResponse();
        ResponsePayload responsePayload = new ResponsePayload();
        List<String> errs = new List<String>();
        //

        // Get request
        OrderRequestPayload orderRequestPayload = (OrderRequestPayload) JSON.deserialize(RestContext.request.requestBody.toString(), OrderRequestPayload.class);

        //System_Log__c for the request variables
        String codeIdentifier = 'ORS logerror REST';
        String description = 'POST:request ' + '- Order UniqueId:' + orderRequestPayload.failure.uniqueId;
        String extendedInformation = RestContext.request.requestBody.toString();
        SystemLogHelper.insertSystemLog(codeIdentifier, description, extendedInformation);

        // Create response payload
        responsePayload.status = 'Success';
        responsePayload.relatedId = 'XX801A0000000Z4cLIAS';
        responsePayload.objectName = 'Order';
        responsePayload.transactionId = orderRequestPayload.failure.transactionId;
        responsePayload.uniqueId = orderRequestPayload.failure.uniqueId;

        // Setup the response
        response.countryCode = 'US';
        response.status = SharedModels.ResponseStatus.SUCCESS;
        response.data = responsePayload;

        //

        //System_Log__c for the response variables

        // return response
        return response;
    }

    // Data Models
    public class ResponsePayload extends SharedModels.Data {
        public String status;
        public String relatedId;
        public String objectName;
        public String transactionId;
        public String uniqueId;
    }

    /////
    public class OrderRequestPayload {
        public Failure failure;
        public List<Order> orders;
        // public String data;
        // "transactionId": "xx-aa123-edf",
        // "uniqueId": "38_1923400",
    }

    public class Failure {
        public String relatedId;
        public String ObjectName;
        public String transactionId;
        public String uniqueId;
        public String errorCode;
        public String errorMessage;
        public String errorStack;
    }

    public class Order {
        public Integer customerNumber;
        public String orderNumber;
        public Integer companyCode;
        public String uniqueId;
        public String orderType;
        public String orderDate;
        public String requestedDate;
        public String status;
        public String externalOrderNumber;
        public String poNumber;
        public ShipToAddress shipToAddress;
        public Decimal orderAmount;
        public Decimal freightAmount;
        public Decimal taxAmount;
        public Decimal totalAmount;
        public String currencyCode;
        public List<OrderHeaderComment> orderHeaderComments;
        public List<LineItem> lineItems;
        public List<ShipHeader> shipHeaders;
    }

    public class ShipToAddress {
        public String shipToCode;
        public String name;
        public String address1;
        public String address2;
        public String address3;
        public String address4;
        public String address5;
        public String city;
        public String state;
        public String postalCode;
        public String country;
    }

    public class OrderHeaderComment {
        public String commentDate;
        public String commentCode;
        public Integer sequenceNumber;
    }

    public class LineItem {
        public Integer lineNumber;
        public Integer originalLineNumber;
        public String status;
        public String manufactureDueDate;
        public String customerStockLocation;
        public String lessThanTruckload;
        public String itemSku;
        public String itemNumber;
        public String originalItemNumber;
        public String priorItemNumber;
        public String itemDescription;
        public Decimal originalOrderQuantity;
        public Decimal orderQuantity;
        public Decimal backorderQuantity;
        public Decimal customerUnitCost;
        public List<OrderLineComment> orderLineComments;
    }

    public class OrderLineComment {
        public String commentDate;
        public String commentCode;
        public Integer sequenceNumber;
    }

    public class ShipHeader {
        public Integer companyCode;
        public Integer shipNumber;
        public String shipKey;
        public String invoiceNumber;
        public String invoiceKey;
        public String shipDate;
        public String carrierCode;
        public List<TrackingInfo> trackingInfo;
        public Decimal freightCost;
        public List<ShippingItem> shippingItems;
    }

    public class TrackingInfo {
        public String trackingNumber;
    }

    public class ShippingItem {
        public String itemNumber;
        public Decimal quantity;
        public List<String> serialNumbers;
    }
}
