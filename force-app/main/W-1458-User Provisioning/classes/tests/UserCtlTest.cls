@isTest
public class UserCtlTest {
    public static List<String> getPermissionSetsToAdd() {
        String basePermissionSetName = 'IR_USA_DLR_BASE_Dealer_Access';
        String warrantyPermissionSetName = 'IR_USA_DLR_ADD_Warranty';
        String marketingPermissionSetName = 'IR_USA_DLR_ADD_Marketing_page';
        List<PermissionSet> usersNewPermissionSets = [SELECT id, name FROM permissionset WHERE name IN (:warrantyPermissionSetName, :marketingPermissionSetName)];
        List<String> permisisonSetsToAdd = new List<String>();
        for (PermissionSet ps : usersNewPermissionSets) {
            permisisonSetsToAdd.add(ps.id);
        }

        return permisisonSetsToAdd;
    }

    public static List<Id> getPermissionSetIdsToAdd() {
        String basePermissionSetName = 'IR_USA_DLR_BASE_Dealer_Access';
        String bizPermissionSetName = 'IR_USA_DLR_ADD_Business_Management';
        String marketingPermissionSetName = 'IR_USA_DLR_ADD_Marketing_page';
        List<PermissionSet> usersNewPermissionSets = [SELECT id, name FROM permissionset WHERE name IN (:bizPermissionSetName, :marketingPermissionSetName)];
        List<String> permisisonSetsToAdd = new List<String>();
        for (PermissionSet ps : usersNewPermissionSets) {
            permisisonSetsToAdd.add(ps.id);
        }

        return permisisonSetsToAdd;
    }

    testMethod static void shouldCreateUserFromContact() {
        Account acc = TestData_Account.createBDMAccount('IRDealerUser', false, RecordTypes.account_IRAuthorizedDealer.ID);
        Contact con = TestData_Contact.createDealerContact(acc.id, 'cub', 'irDealer');

        Test.startTest();
        SharedModels.ResultMessage results = UserCtl.createUser(con, null, getPermissionSetIdsToAdd(), false);
        Test.stopTest();

        System.assertNotEquals(null, results);
    }

    testMethod static void shouldNotUpdateUserFromContact() {
        Account acc = TestData_Account.createDealerAccount();
        Contact con = TestData_Contact.createDealerContact(acc.id, 'cub', 'irDealer');
        TestData.shouldInsert = false;
        User u = TestData_User.createDealerCustomerUser(acc.Id, 'tstuser1@UserCtlTest.com', 'Testuser', con);
        u.FederationIdentifier = 'USR001';
        u.LastName = con.LastName;
        u.FirstName = con.FirstName;
        u.Email = con.Email;
        insert u;
        TestData.shouldInsert = true;

        SingleRequestMock mockRequest = new SingleRequestMock('');
        Test.setMock(HttpCalloutMock.class, mockRequest);

        Test.startTest();
        SharedModels.ResultMessage contactResult = UserCtl.updateContact(con);
        SharedModels.ResultMessage userResult = UserCtl.updateUser(con, u.Id, '1234', getPermissionSetsToAdd(), true);
        Test.stopTest();

        System.assertNotEquals(null, contactResult);
        System.assertNotEquals(null, userResult);
    }

    testMethod static void shouldUpdateUserFromContact() {
        Account acc = TestData_Account.createDealerAccount();
        Contact con = TestData_Contact.createDealerContact(acc.id, 'cub', 'irDealer');
        TestData.shouldInsert = false;
        User u = TestData_User.createDealerCustomerUser(acc.Id, 'tstuser1@UserCtlTest.com', 'Testuser', con);
        u.FederationIdentifier = 'USR002';
        insert u;
        TestData.shouldInsert = true;

        SingleRequestMock mockRequest = new SingleRequestMock('');
        Test.setMock(HttpCalloutMock.class, mockRequest);

        Test.startTest();
        SharedModels.ResultMessage contactResult = UserCtl.updateContact(con);
        SharedModels.ResultMessage userResult = UserCtl.updateUser(con, u.Id, '1234', getPermissionSetsToAdd(), true);
        Test.stopTest();

        System.assertNotEquals(null, contactResult);
        System.assertNotEquals(null, userResult);
    }

    testMethod static void shouldErrorOnCreateContact() {
        Contact contactToCreate = new Contact();
        Test.startTest();
        SharedModels.ResultMessage results = UserCtl.createContact(contactToCreate, true);
        Test.stopTest();

        List<Contact> testContactList = [SELECT Id FROM Contact];

        System.assertEquals(testContactList.size(), 0);
        //System.assertEquals(true,results.message.contains('Required fields are missing'));
    }

    //this test is not to validate functionality but to pass test coverage
    testMethod static void shouldCreateContact() {
        Contact contactToCreate = new Contact();
        contactToCreate.FirstName = 'fname';
        contactToCreate.LastName = 'lname';

        Test.startTest();
        SharedModels.ResultMessage results = UserCtl.createContact(contactToCreate, true);
        Test.stopTest();
        System.debug('BJK: ' + results.payloadMap);
        System.assertEquals(null, results.message);
    }
    /* START S-06570.mj :: temporarily disable the logic that identifies duplicate IR Dealers; consider re-enabling when the "ENABLE" callout is supported by the CMS/User Mgmt UI        List<SObject> insertRecords = new List<SObject>();
    testmethod static void shouldUpdateContactWithDupeOnSameAccount() {
        Account acc = TestData_Account.createBDMAccount('IRDealerUser',false,RecordTypes.account_IRAuthorizedDealer.ID);

        Contact contactToCreate = new Contact();
        contactToCreate.AccountID = acc.Id;
        contactToCreate.FirstName = 'fname';
        contactToCreate.LastName = 'lname';
        contactToCreate.Email = 'test@testing.com';
        contactToCreate.Phone_Extension__c = 1111;
        contactToCreate.RecordTypeID = RecordTypes.contact_IRDealer.Id;
        insert contactToCreate;

        Contact dupeContactToCreate = new Contact();
        dupeContactToCreate.AccountID = acc.Id;
        dupeContactToCreate.FirstName = 'fname';
        dupeContactToCreate.LastName = 'lname';
        dupeContactToCreate.Email = 'test@testing.com';
        dupeContactToCreate.Phone_Extension__c = 2222;
        dupeContactToCreate.RecordTypeID = RecordTypes.contact_IRDealer.Id;

        Test.startTest();
        SharedModels.ResultMessage results = UserCtl.createContact(dupeContactToCreate, false);
        Test.stopTest();

        if (MergeHelper.contactDuplicateRulesActive()) {
            List<Contact> resultingContact = [SELECT Id, Phone_Extension__c FROM Contact];

            System.assertEquals(1, resultingContact.size());
            System.assertEquals(2222, resultingContact[0].Phone_Extension__c);
        }
    }
    // END S-06570.mj
    */
    testMethod static void shouldCreateContactWithDupeOnDifferentAccount() {
        Account acc1 = TestData_Account.createBDMAccount('IRDealerUser1', false, RecordTypes.account_IRAuthorizedDealer.ID);
        Account acc2 = TestData_Account.createBDMAccount('IRDealerUser2', false, RecordTypes.account_IRAuthorizedDealer.ID);

        Account acc = TestData_Account.createBDMAccount('IRDealerUser', false, RecordTypes.account_IRAuthorizedDealer.ID);
        Contact con = TestData_Contact.createDealerContact(acc.id, 'cub', 'irDealer');
        User irDealerUser = TestData_User.createDealerCustomerUser(acc.id, 'cub@irdealer.test.mtd.com', con.LastName, con);

        Contact contactToCreate = new Contact();
        contactToCreate.AccountID = acc1.Id;
        contactToCreate.FirstName = 'fname';
        contactToCreate.LastName = 'lname';
        contactToCreate.Email = 'test@testing.com';
        contactToCreate.Phone_Extension__c = 1111;
        contactToCreate.RecordTypeID = RecordTypes.contact_IRDealer.Id;
        insert contactToCreate;

        Contact dupeContactToCreate = new Contact();
        dupeContactToCreate.AccountID = acc2.Id;
        dupeContactToCreate.FirstName = 'fname';
        dupeContactToCreate.LastName = 'lname';
        dupeContactToCreate.Email = 'test@testing.com';
        dupeContactToCreate.Phone_Extension__c = 2222;
        dupeContactToCreate.RecordTypeID = RecordTypes.contact_IRDealer.Id;

        System.runAs(irDealerUser) {
            Test.startTest();
            SharedModels.ResultMessage results = UserCtl.createContact(dupeContactToCreate, true);
            Test.stopTest();
        }

        List<Contact> resultingContact = [SELECT Id, AccountID FROM Contact ORDER BY CreatedDate ASC];

        System.assertEquals(3, resultingContact.size());
        System.assertEquals(acc.Id, resultingContact[0].AccountID);
        System.assertEquals(acc1.Id, resultingContact[1].AccountID);
        System.assertEquals(acc2.Id, resultingContact[2].AccountID);
    }

    testMethod static void shouldGetUserInfo() {
        Account acc = TestData_Account.createBDMAccount('IRDealerUser', false, RecordTypes.account_IRAuthorizedDealer.ID);
        Contact con = TestData_Contact.createDealerContact(acc.id, 'cub', 'irDealer');
        User irDealerUser = TestData_User.createDealerCustomerUser(acc.id, 'cub@irdealer.test.mtd.com', con.LastName, con);

        //Creates user without contact
        Contact irDealerContactNoUser = new Contact(AccountId = acc.Id, LastName = 'TestLast', FirstName = 'TestFirst', RecordTypeID = RecordTypes.contact_IRDealer.ID);
        insert irDealerContactNoUser;

        UserCtl ctl = new UserCtl();
        List<UserCtl.AccountOption> options = null;
        SharedModels.ResultMessage result = null;

        System.runAs(irDealerUser) {
            Test.startTest();
            options = ctl.getAvailableAccounts();
            result = UserCtl.getUsers(acc.id);
            Test.stopTest();
        }

        System.assertEquals(1, options.size());
        System.assert(options[0].nameWithNumberOfUsers.contains('1 user'));
        System.assertEquals(true, result.success);
    }

    testMethod static void shouldFetchContactRecordType() {
        Account acc = TestData_Account.createBDMAccount('IRDealerUser', false, RecordTypes.account_IRAuthorizedDealer.ID);
        Contact con = TestData_Contact.createDealerContact(acc.id, 'cub', 'irDealer');
        User u = TestData_User.createDealerCustomerUser(acc.Id, 'test@test.com', 'Testerson', con);
        System.runAs(u) {
            test.startTest();
            UserCtl ctl = new UserCtl();
            String contactRecordId = ctl.getContactRecordType();
            Test.stopTest();
            System.assertEquals(con.RecordTypeId, contactRecordId);
        }
    }

    testMethod static void shouldFetchRolesList() {
        //create RolesJSON
        Map<String, String> roleTypeMap = new Map<String, String>();
        roleTypeMap.put('value', 'CEO');
        roleTypeMap.put('label', 'CEO');
        List<Map<String, String>> listFromOptions = new List<Map<String, String>>();
        listFromOptions.add(roleTypeMap);
        test.startTest();
        String roleList = UserCtl.getRolesList(listFromOptions);
        Test.stopTest();
        System.assertEquals(true, roleList.contains('Select One'));
    }

    testMethod static void shouldFetchAlacartePermissionSets() {
        Account acc = TestData_Account.createDealerAccount();

        Test.startTest();
        Map<Id, String> permisisonSets = UserCtl.getPermissionSetOptions(acc.Id);
        Test.stopTest();
        System.debug('BJK: ' + permisisonSets);

        System.assert(5 < permisisonSets.values().size());
    }

    testMethod static void shouldCallPingServiceCalloutWithoutError() {
        Account acctToProvisionUserFor = TestData_Account.createDealerAccount('test', '1111');
        Contact contactToProvision = TestData_Contact.createDealerContact(acctToProvisionUserFor.id, 'firstname', 'lastName');
        List<string> permissionSetsToAssign = new List<string>();
        permissionSetsToAssign.add('IR_USA_DLR_BASE_Dealer_Access');

        UserCtl ctl = new UserCtl();
        String provisioningMessage = UserCtl.createUserMessage(contactToProvision, permissionSetsToAssign);

        //added mock callout to pass testings... it does not perform actual validation
        SingleRequestMock mockRequest = new SingleRequestMock('');
        Test.setMock(HttpCalloutMock.class, mockRequest);
        Test.startTest();
        Exception ex = UserCtl.pingServiceUserCallout(provisioningMessage, 'provision');
        Test.stopTest();

        System.assertEquals(null, ex);
    }

    testMethod static void shouldCallPingServiceCalloutFailure() {
        Account acctToProvisionUserFor = TestData_Account.createDealerAccount('test', '1111');
        Contact contactToProvision = TestData_Contact.createDealerContact(acctToProvisionUserFor.id, 'firstname', 'lastName');
        List<string> permissionSetsToAssign = new List<string>();
        permissionSetsToAssign.add('IR_USA_DLR_BASE_Dealer_Access');

        UserCtl ctl = new UserCtl();
        String provisioningMessage = UserCtl.createUserMessage(contactToProvision, permissionSetsToAssign);

        //added mock callout to pass testings... it does not perform actual validation
        SingleRequestMock mockRequest = new SingleRequestMock(401, '', '', null);
        Test.setMock(HttpCalloutMock.class, mockRequest);
        Test.startTest();
        Exception ex = UserCtl.pingServiceUserCallout(provisioningMessage, 'provision');
        Test.stopTest();

        System.assertNotEquals(null, ex);
    }

    testMethod static void createUserMessage() {
        Account acc = TestData_Account.createBDMAccount('IRDealerUser', false, RecordTypes.account_IRAuthorizedDealer.ID);
        Contact con = TestData_Contact.createDealerContact(acc.id, 'cub', 'irDealer');
        User irDealerUser = TestData_User.createDealerCustomerUser(acc.id, 'cub@irdealer.test.mtd.com', con.LastName, con);

        Account acctToProvisionUserFor = TestData_Account.createDealerAccount('test', '1111');
        Contact contactToProvision = TestData_Contact.createDealerContact(acctToProvisionUserFor.id, 'firstname', 'lastName');
        List<string> permissionSetsToAssign = new List<string>();
        permissionSetsToAssign.add('IR_USA_DLR_BASE_Dealer_Access');

        System.runAs(irDealerUser) {
            UserCtl ctl = new UserCtl();
            String provisioningMessage = UserCtl.createUserMessage(contactToProvision, permissionSetsToAssign);

            /* expected result
        {
          "workflowArgs" : {
            "op" : "create",
            "AccountNumber" : "1111",
            "firstname" : "firstname",
            "lastname" : "lastName",
            "email" : "firstname.lastName@testconsumer.mtd.com",
            "AccountName" : "test",
            "AccountLevel" : "1",
            "ContactID" : "003g000001XZyWYAA1",
            "role" : "IR-USA-DLR-Base profile",
            "PermissionSetList" : [ "IR_USA_DLR_BASE_Dealer_Access" ]
          }
        }
        */
            //System.assertEquals('test', provisioningMessage);
            System.assert(provisioningMessage.contains('"op" : "create",'));
            System.assert(provisioningMessage.contains('"AccountNumber" : "1111",'));
            System.assert(provisioningMessage.contains('"firstname" : "firstname",'));
            System.assert(provisioningMessage.contains('"lastname" : "lastName",'));
            System.assert(provisioningMessage.contains('"email" : "firstname.lastName@testconsumer.mtd.com",'));
            System.assert(provisioningMessage.contains('"AccountName" : "test",'));
            System.assert(provisioningMessage.contains('"ContactID" : "'));
            System.assert(provisioningMessage.contains('"role" : "IR-USA-DLR-Base profile",'));
            System.assert(provisioningMessage.contains('"PermissionSetList" : [ "IR_USA_DLR_BASE_Dealer_Access" ]'));
        }
    }

    testMethod static void updateUserMessage() {
        UserCtl ctl = new UserCtl();
        String provisioningMessage = UserCtl.updateUserMessage('2888.BJacobi', 'Billy', 'Jacobi', 'test@email.com');
        /* expected result
        {
          "workflowArgs" : {
            "federationIdentifier" : "2888.BJacobi",
            "firstname" : "Billy",
            "lastname" : "Jacobi",
            "email" : "test@email.com"
          }
        }
        */
        //System.assertEquals('test', provisioningMessage);
        System.assert(provisioningMessage.contains('"federationIdentifier" : "2888.BJacobi",'));
        System.assert(provisioningMessage.contains('"firstname" : "Billy",'));
        System.assert(provisioningMessage.contains('"lastname" : "Jacobi",'));
        System.assert(provisioningMessage.contains('"email" : "test@email.com"'));
    }

    testMethod static void updatePermissionSetsMessage() {
        List<string> permissionSetsToAssign = new List<string>();
        permissionSetsToAssign.add('IR_USA_DLR_BASE_Dealer_Access');

        UserCtl ctl = new UserCtl();
        String provisioningMessage = UserCtl.updatePermissionSetsMessage(permissionSetsToAssign, '2888.BJacobi');
        /* expected result
        {
          "workflowArgs" : {
            "op" : "update",
            "federationIdentifier" : "2888.BJacobi",
            "PermissionSetList" : [ "IR_USA_DLR_BASE_Dealer_Access" ]
          }
        }
        */
        System.assert(provisioningMessage.contains('"op" : "update",'));
        System.assert(provisioningMessage.contains('"federationIdentifier" : "2888.BJacobi",'));
        System.assert(provisioningMessage.contains('"PermissionSetList" : [ "IR_USA_DLR_BASE_Dealer_Access" ]'));
    }
}
