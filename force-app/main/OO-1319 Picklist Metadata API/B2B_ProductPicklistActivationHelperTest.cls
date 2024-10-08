@IsTest
public class B2B_ProductPicklistActivationHelperTest {
    // Helper method to simulate a successful HTTP response
    private static HttpResponse createMockResponse(String body, Integer statusCode) {
        HttpResponse res = new HttpResponse();
        res.setBody(body);
        res.setStatusCode(statusCode);
        return res;
    }

    // Mock class to simulate HTTP callouts
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private String responseBody;
        private Integer statusCode;

        public MockHttpResponseGenerator(String responseBody, Integer statusCode) {
            this.responseBody = responseBody;
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            return createMockResponse(responseBody, statusCode);
        }
    }

    @IsTest
    static void testActivateInactivePicklistValues_Success() {
        String responseBody = '{"FullName":"Test.B2B_Filter_2_Cycle_Ratio__c","Metadata":{"valueSet":{"valueSetDefinition":{"value":[{"label":"Active","isActive":false}]}}}}';

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));

        Test.startTest();
        B2B_ProductPicklistActivationHelper.activateInactivePicklistValues('TestFieldId');
        Test.stopTest();
    }

    @IsTest
    static void testActivateInactivePicklistValues_ExceptionCaught() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"error":"bad request"}', 400));

        Test.startTest();
        // Method to test
        B2B_ProductPicklistActivationHelper.activateInactivePicklistValues('TestFieldId');
        Test.stopTest();
    }

    @IsTest
    static void testFetchPicklistValues_Success() {
        String expectedResponse = '{"success":true}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(expectedResponse, 200));

        Test.startTest();
        String result = B2B_ProductPicklistActivationHelper.fetchPicklistValues('TestFieldId');
        Test.stopTest();

        System.assertEquals(expectedResponse, result, 'The response should match the mock response.');
    }

    @IsTest
    static void testFetchPicklistValues_Failure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('Failure', 500));

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            B2B_ProductPicklistActivationHelper.fetchPicklistValues('TestFieldId');
        } catch (B2B_ProductPicklistActivationHelper.CustomException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'A custom exception should be thrown for HTTP failures.');
    }

    @IsTest
    static void testIsSuccessfulResponse_Success() {
        HttpResponse res = createMockResponse('Success', 200);

        Boolean isSuccess = B2B_ProductPicklistActivationHelper.isSuccessfulResponse(res);
        System.assert(isSuccess, 'The response should be successful for status code 200.');
    }

    @IsTest
    static void testIsSuccessfulResponse_Failure() {
        HttpResponse res = createMockResponse('Error', 404);

        Boolean exceptionThrown = false;
        try {
            B2B_ProductPicklistActivationHelper.isSuccessfulResponse(res);
        } catch (B2B_ProductPicklistActivationHelper.CustomException e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'A custom exception should be thrown for unsuccessful responses.');
    }
}
