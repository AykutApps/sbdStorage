@IsTest
private class SYS_DelegateGroupServiceHelperTest {
    // Mock class to simulate HTTP callout response
    private class MockToolingApiResponse implements HttpCalloutMock {
        private final String responseBody;
        private final Integer statusCode;

        public MockToolingApiResponse(String responseBody, Integer statusCode) {
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

    @TestSetup
    static void setup() {
        // Set up test data, if any, here
    }

    // Test method for getDelegateGroups
    @IsTest
    static void testGetDelegateGroups() {
        String mockResponse = '{"size":1,"totalSize":1,"done":true,"records":[{"Id":"02f2G000000GnJ9QAK","Name":"Test Group","DeveloperName":"TestGroup"}]}';
        Test.setMock(HttpCalloutMock.class, new MockToolingApiResponse(mockResponse, 200));

        List<SYS_DelegateGroupService.DelegateGroup> groups = SYS_DelegateGroupServiceHelper.getDelegateGroups();

        // Assert
        System.assertNotEquals(null, groups, 'Groups should not be null');
        System.assertEquals(1, groups.size(), 'Should return 1 group');
        System.assertEquals('02f2G000000GnJ9QAK', groups[0].Id, 'Group Id should match');
        System.assertEquals('Test Group', groups[0].Name, 'Group Name should match');
    }

    @IsTest
    static void testGetDelegateGroupsNoRecords() {
        String mockResponse = '{"size":0,"totalSize":0,"done":true}';
        Test.setMock(HttpCalloutMock.class, new MockToolingApiResponse(mockResponse, 200));

        List<SYS_DelegateGroupService.DelegateGroup> groups = SYS_DelegateGroupServiceHelper.getDelegateGroups();

        // Assert
        System.assertNotEquals(null, groups, 'Groups should not be null');
        System.assertEquals(0, groups.size(), 'Should return 0 group');
    }

    // Test method for getDelegateGroupMembers
    @IsTest
    static void testGetDelegateGroupMembers() {
        String mockResponse = '{"size":1,"totalSize":1,"done":true,"records":[{"Id":"02g2G000000blWNQAY","DelegateGroupId":"02f2G000000GnJ9QAK","UserOrGroupId":"005A0000007ZLe6IAG"}]}';
        Test.setMock(HttpCalloutMock.class, new MockToolingApiResponse(mockResponse, 200));

        List<SYS_DelegateGroupService.DelegateGroupMember> members = SYS_DelegateGroupServiceHelper.getDelegateGroupMembers();

        // Assert
        System.assertNotEquals(null, members, 'Members should not be null');
        System.assertEquals(1, members.size(), 'Should return 1 member');
        System.assertEquals('02g2G000000blWNQAY', members[0].Id, 'Member Id should match');
        System.assertEquals('02f2G000000GnJ9QAK', members[0].DelegateGroupId, 'DelegateGroupId should match');
    }
}
