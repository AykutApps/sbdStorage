/*
Controller handles dealer user self provisioning from the dealer community 'Business Management' context

The “/userselfservice” URL now maps to the root context of the application.
To access the base provisioning service, you will need to update your code to “callout:Ping_API/userselfservice/provision”.
The new URls will also be available (i.e. to “callout:Ping_API/userselfservice/enable”. “callout:Ping_API/userselfservice/disable”, "callout:Ping_API/userselfservice/update" ).
*/
public without sharing class UserCtl extends CmsCtlCompBase {
    @RemoteAction
    public static Map<Id, String> getPermissionSetOptions(Id accountId) {
        Account a = [SELECT eCommerce_Capable__c FROM Account WHERE Id = :accountId];
        Boolean hasECommerce = a.eCommerce_Capable__c;
        //TODO: adjust query when requirements come in
        Map<Id, String> psMap = new Map<Id, String>();
        for (PermissionSet ps : [SELECT Id, Name, Label, ProfileId, Description FROM PermissionSet WHERE Name LIKE 'IR_USA_DLR_ADD%' AND ProfileId = NULL ORDER BY Description]) {
            if (ps.Name == 'IR_USA_DLR_ADD_eDealer_Program') {
                if (hasECommerce) {
                    psMap.put(ps.Id, ps.Description);
                }
            } else {
                psMap.put(ps.Id, ps.Description);
            }
        }
        return psMap;
    }

    public static Boolean getIsDealerCommunity() {
        return CmsProperties.NETWORK_CURRENT_ID == CmsProperties.NETWORK_DEALER.Id;
    }

    public String getContactRecordType() {
        User loggedInContact = [SELECT Contact.RecordTypeId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return String.valueOf(loggedInContact.Contact.RecordTypeId);
    }

    @RemoteAction
    public static String getRolesList(List<Map<String, String>> RolesJSON) {
        Map<String, String> options = new Map<String, String>();

        for (Integer i = 0; i < RolesJSON.size(); i++) {
            options.put(RolesJSON[i].get('value'), RolesJSON[i].get('label'));
        }

        options.put('', 'Select One');

        return JSON.serialize(options);
    }

    public class AccountOption {
        public AccountOption(Id id, String name, String nameWithNumberOfUsers) {
            this.id = id;
            this.name = name;
            this.nameWithNumberOfUsers = nameWithNumberOfUsers;
        }
        public Id id { get; set; }
        public String name { get; set; }
        public String nameWithNumberOfUsers { get; set; }
    }

    public List<AccountOption> getAvailableAccounts() {
        Id accountId = UserHelper.fetchAccountID(UserInfo.getUserId());
        List<Account> accounts = AccountHelper.fetchAccountWithAuthorizedChildren(accountId);

        Map<Id, Integer> userCountMap = new Map<Id, Integer>();
        for (User u : [SELECT Contact.AccountId FROM User WHERE Contact.AccountId = :accounts]) {
            Id key = u.Contact.AccountId;
            if (userCountMap.containsKey(key)) {
                Integer temp = userCountMap.get(key) + 1;
                userCountMap.put(key, temp);
            } else {
                userCountMap.put(key, 1);
            }
        }

        List<AccountOption> options = new List<AccountOption>();

        for (Account a : accounts) {
            String formattedLabel = a.Account_Info_With_Entity_ID__c;
            if (userCountMap.containsKey(a.Id)) {
                formattedLabel += ' - ' + userCountMap.get(a.Id) + (userCountMap.get(a.Id) == 1 ? ' user' : ' users');
            }
            options.add(new AccountOption(a.Id, a.Account_Info_With_Entity_ID__c, formattedLabel));
        }

        return options;
    }

    @RemoteAction
    public static SharedModels.ResultMessage getUsers(Id accId) {
        system.debug('UserCtl: fetching users for: ' + accid);
        SharedModels.ResultMessage result = new SharedModels.ResultMessage();
        List<SharedModels.UserContactWrapper> userContactWrapperList = new List<SharedModels.UserContactWrapper>();
        List<Id> contactIdList = new List<Id>();

        try {
            List<User> userList = [
                SELECT
                    Id,
                    FederationIdentifier,
                    Name,
                    Email,
                    FirstName,
                    LastName,
                    IsActive,
                    Contact.Role_at_the_Account__c,
                    Contact.Phone,
                    Contact.MobilePhone,
                    Contact.Email,
                    (SELECT Id, PermissionSet.Name FROM PermissionSetAssignments)
                FROM User
                WHERE ContactId != NULL AND Contact.AccountId = :accId AND IsActive = TRUE
            ];
            result.payloadMap.put('userRecords', userList);

            for (User singleUser : userList) {
                SharedModels.UserContactWrapper singleUserContactWrapper = new SharedModels.UserContactWrapper();
                singleUserContactWrapper.recordId = singleUser.Id;
                singleUserContactWrapper.recordType = 'user';
                singleUserContactWrapper.firstName = singleUser.FirstName;
                singleUserContactWrapper.lastName = singleUser.LastName;
                singleUserContactWrapper.federationIdentifier = singleUser.FederationIdentifier != null ? singleUser.FederationIdentifier : '';
                singleUserContactWrapper.isActive = singleUser.IsActive;
                singleUserContactWrapper.email = singleUser.Email != null ? singleUser.Email : '';
                singleUserContactWrapper.roleAtTheAccount = '';
                userContactWrapperList.add(singleUserContactWrapper);
            }

            //Getting list of contacts that do not have a user associated with them
            /*List<User> expandedUserList = [Select ContactId From User Where Contact.AccountId = :accId];
            for (User sur: expandedUserList){
                contactIdList.add(sur.ContactId);
            }

            List<Contact> contactList = [Select Id, FirstName, LastName, Contact_Status__c, Email, Phone, MobilePhone, Role_at_the_Account__c From Contact Where AccountID = :accId AND Id NOT IN: contactIdList];

            for (Contact singleContact: contactList){
                SharedModels.UserContactWrapper singleUserContactWrapper = new SharedModels.UserContactWrapper();
                singleUserContactWrapper.recordId = singleContact.Id;
                singleUserContactWrapper.recordType = 'contact';
                singleUserContactWrapper.firstName = singleContact.FirstName;
                singleUserContactWrapper.lastName = singleContact.LastName;
                singleUserContactWrapper.federationIdentifier = 'edit user to enable login';
                singleUserContactWrapper.isActive = singleContact.Contact_Status__c == 'Active'? true: false;
                singleUserContactWrapper.email = singleContact.Email != null ? singleContact.Email : '';
                singleUserContactWrapper.phone = singleContact.Phone != null ? singleContact.Phone : '';
                singleUserContactWrapper.mobilePhone = singleContact.MobilePhone != null ? singleContact.MobilePhone : '';
                singleUserContactWrapper.roleAtTheAccount = singleContact.Role_at_the_Account__c;
                userContactWrapperList.add(singleUserContactWrapper);
            }*/

            result.payloadMap.put('userContactWrapperList', userContactWrapperList);
        } catch (Exception e) {
            result.setError(e);
            SystemLogHelper.insertSystemLog(
                'UserCtl',
                'UC-01',
                UserInfo.getUserName(),
                'Error getting user list for account ' + accId,
                e.getMessage() + ':' + e.getStackTraceString()
            );
        }
        return result;
    }

    //runs when an existing user is edited.  Always will have an associated contact.
    @RemoteAction
    public static SharedModels.ResultMessage updateUser(Contact c, Id userId, String federationIdentifier, List<Id> permissionSetsToAdd, Boolean userIsActive) {
        if (String.isNotBlank(federationIdentifier)) {
            //check for federation ID - dont call when service if it is blank
            SharedModels.ResultMessage result = new SharedModels.ResultMessage();
            try {
                User u = new User(
                    Id = userId,
                    Username = c.Email,
                    Email = c.Email,
                    LastName = c.LastName,
                    FirstName = c.FirstName,
                    Alias = c.Email.substringBefore('@'),
                    ProfileId = Profiles.dealerCommunityUser.Id,
                    LocaleSidKey = 'en_US',
                    LanguageLocaleKey = 'en_US',
                    TimeZoneSidKey = 'America/Los_Angeles',
                    EmailEncodingKey = 'UTF-8',
                    ContactId = c.Id,
                    Phone = c.Phone
                );

                if (userIsActive) {
                    c.Contact_Status__c = 'Active';

                    User existingUser = [SELECT FirstName, LastName, Email FROM User WHERE Id = :userId];
                    String firstName = c.FirstName == existingUser.FirstName ? null : c.FirstName;
                    String lastName = c.LastName == existingUser.LastName ? null : c.LastName;
                    String email = c.Email == existingUser.Email ? null : c.Email;
                    Boolean doContactUpdate = false;
                    //we only update the user when there is an actual change to one of these fields
                    //only fields not null (even '') are a part of the generated message
                    if (firstName != null || lastName != null || email != null) {
                        String userMessage = updateUserMessage(federationIdentifier, firstname, lastname, email);
                        System.debug('userMessage:' + userMessage);

                        //TODO: IMPORTANT... uncomment this code when PSCUO is enabled in DevSd
                        Exception calloutResponse = pingServiceUserCallout(userMessage, 'update');
                        if (calloutResponse != null) {
                            result.setError(calloutResponse);
                        } else {
                            doContactUpdate = true;
                        }
                    } else {
                        doContactUpdate = true;
                        System.debug('fields did not change so user was not updated');
                    }

                    //update permission sets
                    //Get the permission set names to pass to the service
                    list<string> psAssignments = new List<string>();
                    for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Id IN :permissionSetsToAdd]) {
                        psAssignments.add(ps.Name);
                    }
                    PermissionSet eBAPS = [SELECT Id FROM PermissionSet WHERE Name = 'IR_USA_DLR_BASE_Dealer_Access'];
                    psAssignments.add('IR_USA_DLR_BASE_Dealer_Access');
                    permissionSetsToAdd.add(eBAPS.Id);

                    //get the eDealer permission set Id
                    PermissionSet eDPS = [SELECT Id FROM PermissionSet WHERE Name = 'IR_USA_DLR_ADD_eDealer_Program'];

                    //get a list of the permission sets that were listed on the UI
                    Map<Id, String> psUIMap = getPermissionSetOptions(c.AccountId);
                    Set<Id> psUIIds = psUIMap.keySet();

                    //get their current permission set assignments
                    list<PermissionSetAssignment> currentPermissionSetAssignments = [
                        SELECT PermissionSetId
                        FROM PermissionSetAssignment
                        WHERE AssigneeId = :userId AND PermissionSet.ProfileId = NULL
                    ];
                    Set<Id> currentPSSet = new Set<Id>();
                    for (PermissionSetAssignment pSA : currentPermissionSetAssignments) {
                        currentPSSet.add(pSA.PermissionSetId);
                    }

                    //if the eDealer was on the UI, then move on to see if there has been any permission set changes.  if it was not on the UI, query to see if they have the eDealer permission set.  if they do then add it to the list of permission sets to add and move on to permission set changes.
                    if (!(psUIMap.keySet().contains(eDPS.Id))) {
                        // if the UI didnt containt the eDealer chekcbox but they ahd the assignment anyway, add it to the list of psAssignemnts.
                        if (currentPSSet.contains(eDPS.Id)) {
                            psAssignments.add('IR_USA_DLR_ADD_eDealer_Program');
                            permissionSetsToAdd.add(eDPS.Id);
                        }
                    }

                    //now that we have their current state straight, check to see if any changes are being made
                    //default to not updating the permission sets
                    Boolean updatePS = false;

                    //make sure all assignments were previously there
                    if (!currentPSSet.containsAll(permissionSetsToAdd)) {
                        updatePS = true;
                    }

                    Set<Id> permissionSetsToAddSet = new Set<Id>(permissionSetsToAdd);
                    //make sure no permissions got taken away
                    if (!permissionSetsToAddSet.containsAll(currentPSSet)) {
                        updatePS = true;
                    }

                    //only update the permission sets if they have changed
                    if (updatePS) {
                        String permissionSetsMessage = updatePermissionSetsMessage(psAssignments, federationIdentifier);
                        Exception psCalloutResponse = pingServiceUserCallout(permissionSetsMessage, 'provision');
                        if (psCalloutResponse != null) {
                            result.setError(psCalloutResponse);
                        }
                    }

                    //happens at end to prevent: You have uncommitted work pending. Please commit or rollback before calling out
                    if (doContactUpdate) {
                        //update the contact fields in salesforce
                        try {
                            Database.update(c, SharedHelpers.getAllowSaveDMLOptions());
                        } catch (Exception e) {
                            result.setError(e);
                        }
                    }
                } else {
                    //user will be disabled
                    c.Contact_Status__c = 'Inactive';
                    Exception calloutResponse = pingServiceUserCallout(federationIdentifier, 'disable');
                    if (calloutResponse != null) {
                        result.setError(calloutResponse);
                    } else {
                        //update the contact active status in salesforce
                        try {
                            Database.update(c, SharedHelpers.getAllowSaveDMLOptions());
                        } catch (Exception e) {
                            result.setError(e);
                        }
                    }
                }

                //TODO: IMPORTANT... remove this update then the above gets uncommented... it was for testing when service not available
                /*update  u;*/
                result.payloadMap.put('updatedUser', u);
            } catch (Exception e) {
                system.debug(e.getMessage());
                result.setError(e);
            }
            return result;
        } else {
            return null;
        }
    }

    @RemoteAction
    public static SharedModels.ResultMessage createUser(Contact c, Id userId, List<Id> permissionSetsToAdd, Boolean dupeMergeRan) {
        SharedModels.ResultMessage result = new SharedModels.ResultMessage();
        try {
            User u = new User(
                Username = c.Email,
                Email = c.Email,
                LastName = c.LastName,
                FirstName = c.FirstName,
                Alias = c.Email.substringBefore('@'),
                ProfileId = Profiles.dealerCommunityUser.Id,
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                ContactId = c.Id,
                Phone = c.Phone
            );

            string userMessage;

            // a user might already exist in the case of a merge
            String federationIdentifier = null;
            System.debug('checking for existing user on ContactId:' + c.Id);
            for (User tUser : [SELECT Id, FederationIdentifier FROM User WHERE ContactId = :c.Id]) {
                userId = tUser.Id;
                federationIdentifier = tUser.FederationIdentifier;
                System.debug('set federationIdentifier:' + federationIdentifier);
            }

            //Get the permission set names to pass to the service
            list<string> psAssignments = new List<string>();
            for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Id IN :permissionSetsToAdd]) {
                psAssignments.add(ps.Name);
            }

            psAssignments.add('IR_USA_DLR_BASE_Dealer_Access');

            userMessage = createUserMessage(c, psAssignments);
            System.debug('userMessage:' + userMessage);

            //TODO: IMPORTANT... uncomment this code when PSCUO is enabled in DevSd
            Exception calloutResponse = pingServiceUserCallout(userMessage, 'provision');
            if (calloutResponse != null) {
                if (!dupeMergeRan && String.isBlank(userId)) {
                    try {
                        delete new Contact(Id = c.Id);
                    } catch (DmlException dmlEx) {
                        //catch mixed dml exception
                        SharedHelpers.deleteRecordsFuture(new Set<Id>{ c.Id });
                    }
                }
                result.setError(calloutResponse);
            }

            //TODO: IMPORTANT... remove this isert then the above gets uncommented... it was for testing when service not available
            /*insert u;*/
            result.payloadMap.put('createdUser', u);
        } catch (Exception e) {
            system.debug(e.getMessage());
            try {
                //This signifies that the contact record existed before any steps were taken. We do not want to delete what was already there
                if (!dupeMergeRan && String.isBlank(userId)) {
                    delete new Contact(Id = c.Id);
                }
            } catch (DmlException dmlEx) {
                //catch mixed dml exception
                SharedHelpers.deleteRecordsFuture(new Set<Id>{ c.Id });
            }
            result.setError(e);
        }
        return result;
    }

    @RemoteAction
    public static SharedModels.ResultMessage createContact(Contact c, Boolean isInsert) {
        SharedModels.ResultMessage result = new SharedModels.ResultMessage();
        try {
            c.RecordTypeId = RecordTypes.contact_IRDealer.Id;
            result = updateObjects(c, isInsert);
        } catch (Exception e) {
            result.setError(e);
        }
        return result;
    }

    @RemoteAction
    public static SharedModels.ResultMessage updateContact(Contact c) {
        SharedModels.ResultMessage result = new SharedModels.ResultMessage();
        try {
            c.RecordTypeId = RecordTypes.contact_IRDealer.Id;
            Database.SaveResult sr = Database.update(c, SharedHelpers.getAllowSaveDMLOptions());
            result.payloadMap.put('updatedContact', sr);
        } catch (Exception e) {
            result.setError(e);
        }
        return result;
    }

    //When creating a new user, you must call the "provision" endpoint.
    public static string createUserMessage(Contact c, List<string> permissionSets) {
        /*example
        {{  "workflowArgs": {    "op":"create",
        "AccountLevel": "7",
        "AccountName": "Jacobi Sales, Inc.",
        "AccountNumber": "2891",
        "ContactID": "003A000001o8OeB",
        "PermissionSetList": [      "IR_USA_DLR_BASE_Dealer_Access" ,"IR_USA_DLR_ADD_Business_Management" ,"IR_USA_DLR_ADD_eDealer_Program" ,"IR_USA_DLR_ADD_Payment_Estimator" ,"IR_USA_DLR_ADD_Warranty"    ],
        "email": "annette.anost@mtdproducts.com",
        "firstname": "Amanda",
        "lastname": "Phillips",
        "role": "IR-USA-DLR-Base profile"  }}
        */
        Account a = [SELECT Id, Name, Entity_Id__c, Spring_Summer_Level__c FROM Account WHERE Id = :c.AccountId];

        // Pass true to the constructor for pretty print formatting.
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName('workflowArgs');
        gen.writeStartObject();
        gen.writeStringField('op', 'create');
        if (String.isNotBlank(a.Entity_Id__c)) {
            gen.writeStringField('AccountNumber', a.Entity_Id__c);
        }
        gen.writeStringField('firstname', c.FirstName);
        gen.writeStringField('lastname', c.LastName);
        gen.writeStringField('email', c.Email);
        gen.writeStringField('AccountName', a.Name);
        gen.writeStringField('AccountLevel', a.Spring_Summer_Level__c);
        gen.writeStringField('ContactID', c.Id);
        gen.writeStringField('role', 'IR-USA-DLR-Base profile');
        gen.writeFieldName('PermissionSetList');
        gen.writeStartArray();
        for (string ps : permissionSets) {
            gen.writeString(ps);
        }
        gen.writeEndArray();
        gen.writeEndObject();
        gen.writeEndObject();
        return gen.getAsString();
    }

    //When updating a user, you must call the "update" endpoint.
    //no permission set updates are a part of this call
    //'op' param is not used
    public static string updateUserMessage(String federationIdentifier, String firstName, String lastName, String email) {
        /*example
        {
            "workflowArgs": {
            "email": "mikeafter6@msn.com",
            "federationIdentifier": "2891.APhillips",
            "firstname": "Amanda2",
            "lastname": "Phillips2"
            }
        }*/

        // Pass true to the constructor for pretty print formatting.
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName('workflowArgs');
        gen.writeStartObject();
        gen.writeStringField('federationIdentifier', federationIdentifier);
        if (firstName != null) {
            gen.writeStringField('firstname', firstName);
        }
        if (lastName != null) {
            gen.writeStringField('lastname', lastName);
        }
        if (email != null) {
            gen.writeStringField('email', email);
        }
        gen.writeEndObject();
        gen.writeEndObject();
        return gen.getAsString();
    }

    //When updating the permission sets, you must call the "provision" endpoint.
    public static string updatePermissionSetsMessage(List<string> permissionSets, String federationIdentifier) {
        /*example
        {
            "workflowArgs": {
            "PermissionSetList": ["IR_USA_DLR_BASE_Dealer_Access"],
            "federationIdentifier": "2888.BJacobi",
            "op": "update"
            }
        }*/
        // Pass true to the constructor for pretty print formatting.
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName('workflowArgs');
        gen.writeStartObject();
        gen.writeStringField('op', 'update');
        if (String.isNotBlank(federationIdentifier)) {
            gen.writeStringField('federationIdentifier', federationIdentifier);
        }
        gen.writeFieldName('PermissionSetList');
        gen.writeStartArray();
        for (string ps : permissionSets) {
            gen.writeString(ps);
        }
        gen.writeEndArray();
        gen.writeEndObject();
        gen.writeEndObject();
        return gen.getAsString();
    }

    /*
     *
     * This method will search for existing contacts in salesforce that will trip the duplicate rules and will update those contacts.
     * If no duplicate is found it will insert the record. If a duplicate is found it will update it.
     * A Contact record is returned.
     *
     */
    public static SharedModels.ResultMessage updateObjects(Contact newContact, Boolean isInsert) {
        // START S-06570.mj :: temporarily disable the logic that identifies duplicate IR Dealers; consider re-enabling when the "ENABLE" callout is supported by the CMS/User Mgmt UI        List<SObject> insertRecords = new List<SObject>();
        List<SObject> insertRecords = new List<SObject>();
        List<SObject> updateRecords = new List<SObject>();

        if (isInsert) {
            insertRecords.add(newContact);
        } else {
            updateRecords.add(newContact);
        }
        SharedModels.ResultMessage returnContact = new SharedModels.ResultMessage();
        // END S-06570.mj
        /*      Savepoint sp = Database.setSavepoint();
        Schema.SObjectType objectType = Contact.SObjectType;

        List<SObject> insertRecords = new List<SObject>();
        List<SObject> updateRecords = new List<SObject>();

        SharedModels.ResultMessage returnContact = new SharedModels.ResultMessage();
        List<Contact> contactList = new List<Contact>(); //was valueList
        contactList.add(newContact);
        System.debug('checking new contact for duplicates');
        System.debug(newContact);

        List<Database.SaveResult> srList = Database.insert(contactList, false);
        Integer index = 0;
        Set<Id> matchRecordIds = new Set<Id>();

        //Loops through initial save results to add record id(s) of duplicates found to list
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                continue;
            }

            for (Database.Error err : sr.getErrors()) {
                if (err.getStatusCode() == StatusCode.DUPLICATES_DETECTED) {
                    Database.DuplicateError dupe = (Database.DuplicateError) err;
                    for (Datacloud.MatchResult matchedResult : dupe.getDuplicateResult().getMatchResults()) {
                        for (Datacloud.MatchRecord matchedRecord : matchedResult.getMatchRecords()) {
                            SObject tempRecord = matchedRecord.getRecord();
                            matchRecordIds.add((Id)tempRecord.get('Id'));
                        }
                    }
                }
            }
            index++;
        }

        //Map of the full duplicate records that were found
        Map<Id, SObject> matchRecordMap = new Map<Id, SObject>([select Id, RecordTypeId, AccountID from Contact where Id = :matchRecordIds]);

        //We now loop through the save results again to populate which records need to be updated due to being a duplicate
        //and which records can just be inserted
        index = 0;
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                if (objectType == Contact.SObjectType) {
                    insertRecords.add(contactList.get(index));
                    System.debug('No duplicate found');
                }
            } else {
                SObject temp = contactList.get(index).getSObjectType().newSObject();
                for (Database.Error err : sr.getErrors()) {
                    if (err.getStatusCode() == StatusCode.INVALID_FIELD_FOR_INSERT_UPDATE) {

                    }
                    if (err.getStatusCode() == StatusCode.DUPLICATES_DETECTED) {
                        Database.DuplicateError dupe = (Database.DuplicateError) err;
                        String duplicateRuleName = dupe.getDuplicateResult().getDuplicateRule();
                        System.debug('dupe detected on rule: ' + duplicateRuleName);
                        for (Datacloud.MatchResult matchedResult : dupe.getDuplicateResult().getMatchResults()) {
                            for (Datacloud.MatchRecord matchedRecord : matchedResult.getMatchRecords()) {
                                //qualify record type
                                SObject tempRecord = matchedRecord.getRecord();
                                Id tempRecordId = (Id)tempRecord.get('Id');
                                System.debug('MatchedRecord: ' + tempRecord);

                                //Only continue on if the record type is of IRDealer
                                if (objectType == Contact.SObjectType) {
                                    tempRecord = matchRecordMap.get(tempRecordId);
                                    if (tempRecord.get('RecordTypeId') != RecordTypes.contact_IRDealer.Id) {
                                        continue;
                                    }
                                }

                                //If this record is found on another account then do not treat as a duplicate...
                                //however... we do have to check if an insert was intended so we can properly
                                //create the new record on the current account if it already exists on another account
                                //The check for insertRecords size is to make sure this isn't inserted multiple times
                                //in the case that we have multiple duplicate records found on other accounts.
                                if (newContact.AccountId != (Id)tempRecord.get('AccountId')){
                                    if (isInsert){
                                        if (insertRecords.size() < 1){
                                            insertRecords.add(newContact);
                                        }
                                    }
                                    continue;
                                }

                                //Merging duplicates to existing records.
                                if (duplicateRuleName != MergeHelper.HOUSEHOLD_DUPLICATE_RULE) {
                                    temp = MergeHelper.mergeRecords(matchedRecord.getRecord(), newContact);
                                    System.debug('DESTINATIONOBJ:' + matchedRecord.getRecord());
                                    System.debug('SOURCEOBJ:' + newContact);
                                    updateRecords.add(temp);
                                }
                            }
                        }
                    }
                }
            }
            index++;
        }
        Database.rollback(sp);
*/
        //we bypass duplicate rules because there could be matches of another record type or multiple matches
        if (insertRecords != null && insertRecords.size() > 0) {
            insertRecords[0].Id = null;
            Database.insert(insertRecords, SharedHelpers.getAllowSaveDMLOptions());
            returnContact.payloadMap.put('dupeMergeRan', false);
            returnContact.payloadMap.put('record', insertRecords[0]);
        }

        if (updateRecords != null && updateRecords.size() > 0) {
            Database.update(updateRecords, SharedHelpers.getAllowSaveDMLOptions());
            returnContact.payloadMap.put('dupeMergeRan', true);
            returnContact.payloadMap.put('record', updateRecords[0]);
        }

        return returnContact;
    }

    public static Exception pingServiceUserCallout(String userMessage, String operation) {
        HttpRequest req = new HttpRequest();

        req.setEndpoint('callout:Ping_API/userselfservice/' + operation);

        req.setMethod('POST');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        req.setBody(userMessage);
        system.debug(req);
        system.debug(userMessage);

        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());

        if (res.getStatusCode() != 200) {
            System_Log__c sl = new System_Log__c();
            sl.Log_Item_Source__c = 'UserCtl';
            sl.Code_Identifier__c = 'UC-01';
            sl.Logged_In_User__c = UserInfo.getUserName();
            sl.Description__c = 'Error Creating or Updating User in SSO';
            sl.Extended_Information__c =
                'Request: ' +
                req +
                ' \n\n Request Message: ' +
                userMessage +
                ' \n\n Response: ' +
                res.getBody() +
                ' \n\n Response Code: ' +
                res.getStatusCode() +
                ' \n\n Response: ' +
                res.getStatus();

            try {
                insert sl;
            } catch (system.DmlException e) {
                system.debug(e.getMessage());
            }
            return new PingCalloutException(
                'There was a problem creating the new user. ' +
                    'MTD Dealer Support group is looking into the ' +
                    'problem. When the issue is resolved, the user ' +
                    'will get an email with information to set their password. '
            );
        } else {
            return null;
        }
    }

    public class PingCalloutException extends Exception {
    }
}
