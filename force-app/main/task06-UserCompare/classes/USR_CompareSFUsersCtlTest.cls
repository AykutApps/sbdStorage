@isTest
private class USR_CompareSFUsersCtlTest {
    /*	verify the simple controller for a Visualforce Wizard
	- wizard page 1 - ask user to provide User.Username values for the compare; base user is populated by query-string-param Id; use an SF User Id
	- wizard page 2 - displays settings for each user in columns - 1 row per setting/property/field/configurations
                      - Column 1 is for the "base" user, Column 2 is for the "other" user, Column 3 is for the "another" user
                      - Columns 2 and 3 have analysis flags based on values for the "base" user
                        - analysis flags are "same", "different", "missing" & "extra"
                        - CSS will change the look of each cell in column 2 (other) & column 3 (another) based on the analysis flags
*/
    //ToFuture: cover saveAsPDF() action when it is developed
    //ToFuture: cover saveAsSheet() action when it is developed
    static testMethod void navigationTest() {
        //COLUMN 1 - Base User
        User base = [
            SELECT
                Id,
                FirstName,
                LastName,
                Title,
                FederationIdentifier,
                UserName,
                Email,
                IsActive,
                ProfileId,
                Profile.Name,
                UserRoleId,
                UserRole.Name,
                ContactId,
                Contact.Name,
                Contact.AccountId,
                Contact.Account.Entity_Id__c,
                Contact.Account.PEID__c,
                Contact.Account.ShippingCity,
                Contact.Account.ShippingState
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        //COLUMN 2 - IR Sales Support User
        Profile irProfile = [SELECT ID FROM Profile WHERE Name = 'Dealer Fulfillment Coordinator'];
        User other = [
            SELECT
                Id,
                FirstName,
                LastName,
                Title,
                FederationIdentifier,
                UserName,
                Email,
                IsActive,
                ProfileId,
                Profile.Name,
                UserRoleId,
                UserRole.Name,
                ContactId,
                Contact.Name,
                Contact.AccountId,
                Contact.Account.Entity_Id__c,
                Contact.Account.PEID__c,
                Contact.Account.ShippingCity,
                Contact.Account.ShippingState
            FROM User
            WHERE ProfileId = :irProfile.Id
            LIMIT 1
        ];
        //COLUMN 3 - IR-USA Dealer Community User
        Profile dlrProfile = [SELECT ID FROM Profile WHERE Name = 'IR-USA-DLR-Base profile'];
        User another = [
            SELECT
                Id,
                FirstName,
                LastName,
                Title,
                FederationIdentifier,
                UserName,
                Email,
                IsActive,
                ProfileId,
                Profile.Name,
                UserRoleId,
                UserRole.Name,
                ContactId,
                Contact.Name,
                Contact.AccountId,
                Contact.Account.Entity_Id__c,
                Contact.Account.PEID__c,
                Contact.Account.ShippingCity,
                Contact.Account.ShippingState
            FROM User
            WHERE ProfileId = :dlrProfile.Id
            LIMIT 1
        ];

        Test.startTest();

        USR_CompareSFUsersCtl ctl;
        PageReference curPg;
        PageReference nextPg;

        //load the first page of the wizard in memory
        curPg = new PageReference('/apex/USR_CompareSFUsersCtl?Id=' + base.Id);
        Test.setCurrentPage(curPg);
        ctl = new USR_CompareSFUsersCtl();

        //verify initial state of the page
        system.assertEquals(false, ctl.testMode); //on page load, it should be FALSE in SIT, UAT & PROD
        system.assertEquals(false, ctl.showAnalysis);
        system.assertEquals(1, ctl.curPage); //should start on page 1 of the wizard
        system.assertEquals(base.Id, ctl.baseUser.Id);
        system.assertEquals(null, ctl.otherUser); //on page load, the 2nd user (other) will not be set
        system.assertEquals(null, ctl.anotherUser); //on page load, the 3rd user (another) will not be set

        //on the VF page, populate the other & another input fields
        ctl.otherUsername = other.Username;
        ctl.anotherUsername = another.Username;
        ctl.compareUser2 = other;
        ctl.compareUser3 = another;

        // dynamic search test
        ctl.searchString = 'Mic';
        ctl.dynamicSearch();
        system.Assert(ctl.users.size() > 0);

        //click the COMPARE button
        curPg = ctl.compareUsers();
        system.assertEquals(2, ctl.curPage);

        // test permission set upate
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Type = 'Regular' LIMIT 1];
        USR_CompareSFUsersCtl.updatePermission(ps.Id, base.Id);
        system.Assert([SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :ps.Id AND AssigneeId = :base.Id].size() > 0);

        //verify the input fields were populated & the other/another users were loaded
        system.assertEquals(other.Username, ctl.otherUsername);
        system.assertEquals(other.Id, ctl.otherUser.Id);

        system.assertEquals(another.Username, ctl.anotherUsername);
        system.assertEquals(another.Id, ctl.anotherUser.Id);

        //verify there are more than 2 grid-rows
        system.assertEquals(true, ctl.rows.size() > 2);

        //return back to page 1 to remove the "another" user from the comparison
        ctl.chooseUsers();
        system.assertEquals(1, ctl.curPage);
        ctl.anotherUsername = null;
        ctl.compareUser3 = null;

        //go back to the analysis
        curPg = ctl.compareUsers();
        system.assertEquals(2, ctl.curPage);

        //verify the input fields now: other should be populated; another should not be populated
        system.assertEquals(other.Username, ctl.otherUsername);
        system.assertEquals(other.Id, ctl.otherUser.Id);

        system.assertEquals('', ctl.anotherUsername);
        system.assertEquals(null, ctl.anotherUser);

        //toggle the analysis-flag columns
        curPg = ctl.toggleAnalysis();

        //cover future actions
        curPg = ctl.refresh();
        curPg = ctl.swapUsers();
        curPg = ctl.saveAsPDF();
        curPg = ctl.saveAsSheet();
    }
    static testMethod void verifyTestMode() {
        //access test-mode by setting the query-string-param "testMode" to 1
        //COLUMN 1 - Base User
        User base = [
            SELECT
                Id,
                FirstName,
                LastName,
                Title,
                FederationIdentifier,
                UserName,
                Email,
                IsActive,
                ProfileId,
                Profile.Name,
                UserRoleId,
                UserRole.Name,
                ContactId,
                Contact.Name,
                Contact.AccountId,
                Contact.Account.Entity_Id__c,
                Contact.Account.PEID__c,
                Contact.Account.ShippingCity,
                Contact.Account.ShippingState
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        Test.startTest();

        USR_CompareSFUsersCtl ctl;
        PageReference curPg;
        PageReference nextPg;

        //load the first page of the wizard in memory
        curPg = new PageReference('/apex/USR_CompareSFUsersCtl?Id=' + base.Id + '&testMode=1'); //make sure testMode query-string-param is set here
        Test.setCurrentPage(curPg);
        ctl = new USR_CompareSFUsersCtl();

        //verify initial state of the page
        system.assertEquals(true, ctl.testMode); //on page load, the query-string-param should set testMode to TRUE
    }
    static testMethod void verifyNoDataState() {
        //if no base Id is provided via the "Id" query-string-param, the page should load the SF User running this test

        //no data to stage for the "no data state"

        Test.startTest();

        USR_CompareSFUsersCtl ctl;
        PageReference curPg;
        PageReference nextPg;

        //load the first page of the wizard in memory
        curPg = new PageReference('/apex/USR_CompareSFUsersCtl'); //no query-string-params
        Test.setCurrentPage(curPg);
        ctl = new USR_CompareSFUsersCtl();

        //verify no data state loads the current, logged in user
        system.assertEquals(UserInfo.getUserId(), ctl.baseUser.Id);
    }
}
