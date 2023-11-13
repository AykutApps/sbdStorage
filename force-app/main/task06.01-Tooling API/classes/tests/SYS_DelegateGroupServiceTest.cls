@IsTest
private class SYS_DelegateGroupServiceTest {
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

    @IsTest
    static void testGetDelegateGroups() {
        Test.setMock(
            HttpCalloutMock.class,
            new MockHttpResponse('{"size":1, "records":[{"Id":"02f2G000000GnJ9QAK","Name":"AU Delegated Admin","DeveloperName":"AU_Delegated_Admin"}]}', 200)
        );

        // Test the getDelegateGroups method
        List<SYS_DelegateGroupService.DelegateGroup> groups = SYS_DelegateGroupService.getDelegateGroups();

        // Assertions
        System.assertNotEquals(null, groups, 'Groups should not be null');
        System.assertEquals(1, groups.size(), 'There should be exactly one group');
    }

    @IsTest
    static void testGetDelegateGroupMembers() {
        Test.setMock(
            HttpCalloutMock.class,
            new MockHttpResponse(
                '{"size":1,"totalSize":1,"done":true,"records":[{"Id":"02g2G000000blWNQAY","DelegateGroupId":"02f2G000000GnJ9QAK","UserOrGroupId":"005A0000007ZLe6IAG"}]}',
                200
            )
        );

        // Test the getDelegateGroupMembers method
        List<SYS_DelegateGroupService.DelegateGroupMember> members = SYS_DelegateGroupService.getDelegateGroupMembers();

        // Assertions
        System.assertNotEquals(null, members, 'Members should not be null');
        System.assertEquals(1, members.size(), 'There should be exactly one member');
    }
}
