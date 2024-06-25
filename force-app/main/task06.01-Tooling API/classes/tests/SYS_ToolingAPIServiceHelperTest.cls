@IsTest
private class SYS_ToolingAPIServiceHelperTest {
    // Mock class to simulate HTTP callout response
    private class MockHttpResponse implements HttpCalloutMock {
        private final String responseBody;
        private final Integer statusCode;

        public MockHttpResponse(String responseBody, Integer statusCode) {
            this.responseBody = responseBody;
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setBody(responseBody);
            response.setStatusCode(statusCode);
            return response;
        }
    }

    // Test method for successful callout
    @IsTest
    static void testRetrieveQueryResultsSuccess() {
        // Set up mock callout response
        Test.setMock(
            HttpCalloutMock.class,
            new MockHttpResponse('{"size":1, "records":[{"Id":"02f2G000000GnJ9QAK","Name":"AU Delegated Admin","DeveloperName":"AU_Delegated_Admin"}]}', 200)
        );

        // Test
        SYS_ToolingAPIServiceHelper serviceHelper = new SYS_ToolingAPIServiceHelper();
        HttpResponse response = serviceHelper.retrieveQueryResults('SELECT Id, Name, DeveloperName FROM DelegateGroup');

        // Assert
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
        System.assertNotEquals(null, response.getBody(), 'Response body should not be null');
    }

    // Test method for failed callout
    @IsTest
    static void testRetrieveQueryResultsFailure() {
        // Set up mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse('{"size":0, "records":[]}', 500));

        // Test
        SYS_ToolingAPIServiceHelper serviceHelper = new SYS_ToolingAPIServiceHelper();
        HttpResponse response = serviceHelper.retrieveQueryResults('SELECT Id, Name, DeveloperName FROM DelegateGroup');

        // Assert
        System.assertEquals(500, response.getStatusCode(), 'Status code should be 500');
    }

    // Test method for POST callout with payload
    @IsTest
    static void testPostCallWithPayload() {
        Test.setMock(
            HttpCalloutMock.class,
            new MockHttpResponse('{"size":1, "records":[{"Id":"02f2G000000GnJ9QAK","Name":"AU Delegated Admin","DeveloperName":"AU_Delegated_Admin"}]}', 200)
        );

        // Create a payload for the POST request
        String payload = '{"name":"Test"}';

        // Instantiate the service helper and invoke the retrieveQueryResults method which uses callToolingAPI
        SYS_ToolingAPIServiceHelper serviceHelper = new SYS_ToolingAPIServiceHelper();

        HttpResponse response = serviceHelper.callToolingAPI('POST', '/customEndpoint', payload);

        // Assert
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
    }
}