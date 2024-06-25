@IsTest
private class SYS_ToolingAPIServiceTest {
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

    // Test method for getDelegateGroups
    @IsTest
    static void testGetDelegateGroups() {
        // Set up mock callout response
        Test.setMock(
            HttpCalloutMock.class,
            new MockHttpResponse('{"size":1, "records":[{"Id":"02f2G000000GnJ9QAK","Name":"AU Delegated Admin","DeveloperName":"AU_Delegated_Admin"}]}', 200)
        );

        // Test
        HttpResponse response = SYS_ToolingAPIService.getDelegateGroups();

        // Assert
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
        System.assertNotEquals(null, response.getBody(), 'Response body should not be null');
    }

    // Test method for getDelegateGroupMembers
    @IsTest
    static void testGetDelegateGroupMembers() {
        // Set up mock callout response
        Test.setMock(
            HttpCalloutMock.class,
            new MockHttpResponse('{"size":1, "records":[{"Id":"02g2G000000blWNQAY","DelegateGroupId":"02f2G000000GnJ9QAK","UserOrGroupId":"005A0000007ZLe6IAG"}]}', 200)
        );

        // Test
        HttpResponse response = SYS_ToolingAPIService.getDelegateGroupMembers();

        // Assert
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
        System.assertNotEquals(null, response.getBody(), 'Response body should not be null');
    }
}