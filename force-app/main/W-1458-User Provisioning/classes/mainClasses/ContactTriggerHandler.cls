public class ContactTriggerHandler implements TriggerInterface {
    public static integer triggerCycleCount = 1;

    public void beforeInsert() {
        setCommunityPermissionForNewContacts(Trigger.new);
    }
    public void beforeUpdate() {
        setCommunityPermissionForNewContacts(Trigger.new);
    }
    public void beforeDelete() {
    }
    public void afterInsert() {
        createConsumerAccounts(Trigger.new);
        rebuildCommunicationPreferenceRelations(Trigger.new);
    }
    public void afterUpdate() {
        rebuildCommunicationPreferenceRelations(Trigger.new);
        updateRelatedUserData(Trigger.new);
        //updateUserPermissionSetAssignments(Trigger.new);
    }
    public void afterDelete() {
    }
    public void finish() {
        if (Trigger.isAfter) {
            triggerCycleCount++;
            system.debug('xxx-CTH-F-01-' + triggerCycleCount + ':switch to triggerCycleCount-' + triggerCycleCount);
        }
    }

    private void createConsumerAccounts(List<Contact> contacts) {
        system.debug('xxx-CTH-CCA-01-' + triggerCycleCount + ':contacts.size-' + contacts.size());
        //GATEWAY
        ID consumerRecTypeID = RecordTypes.contact_Consumer.ID;
        ID consumerAURecTypeID = RecordTypes.contact_AUConsumer.ID;
        ID consumerCARecTypeID = RecordTypes.contact_CAConsumer.ID;
        ID consumerAccRecTypeID = RecordTypes.account_Consumer.ID;
        ID consumerAUAccRecTypeID = RecordTypes.account_AUConsumer.ID;
        ID consumerCAAccRecTypeID = RecordTypes.account_CAConsumer.ID;
        //get a set of Ids for all the contact record types that have "consumer" in the name
        List<RecordType> consumerRecordTypes = [SELECT Id, Name FROM RecordType WHERE Name LIKE '%consumer%' AND SobjectType = 'Contact'];
        Set<Id> consumerRecordIds = (new Map<Id, SObject>(consumerRecordTypes)).keySet();

        List<Contact> qualifiedRecords = new List<Contact>();
        Set<ID> accIDs = new Set<ID>();
        for (Contact c : contacts) {
            system.debug('thecontact: ' + c);
            //changed logic to make any record with "Consumer" in the record type be qualified for creating a household account
            //if(Trigger.isInsert && c.RecordTypeID == consumerRecTypeID && c.AccountId == null) {
            if (Trigger.isInsert && consumerRecordIds.contains(c.RecordTypeID) && c.AccountId == null) {
                qualifiedRecords.add(c);
                if (c.AccountID != null)
                    accIDs.add(c.AccountID);
            }
        }

        //PREP MAPS TO HELP

        //WORK
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Map<ID, Account> conIdConsumerAccountMap = new Map<ID, Account>(); //KEY=Contact.ID for consumer  VALUE=consumer Account that needs to be inserted
        if (qualifiedRecords.size() > 0) {
            List<Contact> updateContacts = new List<Contact>();
            //is an account needed for this consumer contact
            for (Contact c : qualifiedRecords) {
                String accName = 'Household: ';
                accName += (String.isBlank(c.FirstName) ? 'No First Name' : c.FirstName);
                accName += ' ' + (String.isBlank(c.LastName) ? 'No Last Name' : c.LastName);
                Account acc = new Account();
                //each time a new consumer type is created, a new account type will need to be created and accounted for in this if.  If not it will default to consumer
                if (c.RecordTypeId == consumerAURecTypeID) {
                    acc.RecordTypeID = consumerAUAccRecTypeID;
                } else if (c.RecordTypeId == consumerCARecTypeID) {
                    acc.RecordTypeID = consumerCAAccRecTypeID;
                } else {
                    acc.RecordTypeID = consumerAccRecTypeID;
                }
                acc.Name = accName;
                acc.BillingStreet = c.MailingStreet;
                acc.BillingCity = c.MailingCity;
                acc.BillingState = c.MailingState;
                acc.BillingPostalCode = c.MailingPostalCode;
                acc.BillingCountry = c.MailingCountry;
                conIdConsumerAccountMap.put(c.id, acc);
            }
            system.debug('xxx-CTH-CCA-10-' + triggerCycleCount + ':conIdConsumerAccountMap.size-' + conIdConsumerAccountMap.size());

            //create Consumer Account & link to respective consumer contact records
            if (conIdConsumerAccountMap.size() > 0) {
                Database.insert(conIdConsumerAccountMap.values(), dml);
                system.debug('xxx-CTH-CCA-11-' + triggerCycleCount + ':Limits.getDMLRows()-' + Limits.getDMLRows());
                system.debug('xxx-CTH-CCA-12-' + triggerCycleCount + ':Limits.getLimitDMLRows()-' + Limits.getLimitDMLRows());

                //link each account to its contact
                for (Contact c : qualifiedRecords) {
                    Account tmp = conIdConsumerAccountMap.get(c.id);
                    Contact n = new Contact(ID = c.id);
                    n.AccountID = tmp.ID;
                    updateContacts.add(n);
                }
                system.debug('xxx-CTH-CCA-20-' + triggerCycleCount + ':updateContacts.size-' + updateContacts.size());
            }
            //update contacts
            Database.update(updateContacts, dml);
            system.debug('xxx-CTH-CCA-21-' + triggerCycleCount + ':Limits.getDMLRows()-' + Limits.getDMLRows());
            system.debug('xxx-CTH-CCA-22-' + triggerCycleCount + ':Limits.getLimitDMLRows()-' + Limits.getLimitDMLRows());
        }
        system.debug('xxx-CTH-CCA-99-' + triggerCycleCount + ':contacts.size-' + contacts.size());
    }

    private void rebuildCommunicationPreferenceRelations(List<Contact> contacts) {
        system.debug('xxx-CTH-RCPR-01-' + triggerCycleCount + ':contacts.size-' + contacts.size());

        Set<Id> qualifiedContactIds = new Set<Id>();
        List<Contact> qualifiedContacts = new List<Contact>();
        Set<String> emailAddresses = new Set<String>();

        for (Contact c : contacts) {
            //TO FUTURE: maybe we should throw in a validation on the email format here? - Jake
            if (c.RecordTypeId == RecordTypes.contact_Consumer.Id && String.isNotBlank(c.Email)) {
                qualifiedContactIds.add(c.Id);
                qualifiedContacts.add(c);
                emailAddresses.add(c.Email);
            }
        }

        if (!qualifiedContactIds.isEmpty()) {
            delete [SELECT Id FROM Communication_Preference_Relation__c WHERE Contact__c = :qualifiedContactIds];
            system.debug('xxx-CTH-RCPR-02-' + triggerCycleCount + ':Limits.getDMLRows()-' + Limits.getDMLRows());
            system.debug('xxx-CTH-RCPR-03-' + triggerCycleCount + ':Limits.getLimitDMLRows()-' + Limits.getLimitDMLRows());

            Map<String, List<Contact>> emailToContacts = SharedHelpers.createMapFromListByForeignKeyString(qualifiedContacts, 'Email');
            system.debug('xxx-CTH-RCPR-04-' + triggerCycleCount + ':emailToContacts.keyset()-' + emailToContacts.keyset());

            List<Communication_Preference_Relation__c> newRelations = new List<Communication_Preference_Relation__c>();
            for (Communication_Preference__c cp : [SELECT Id, Email__c FROM Communication_Preference__c WHERE Email__c = :emailAddresses]) {
                String key = cp.Email__c;
                if (emailToContacts.containsKey(key)) {
                    for (Contact c : emailToContacts.get(key)) {
                        newRelations.add(new Communication_Preference_Relation__c(Communication_Preference__c = cp.Id, Contact__c = c.Id));
                    }
                }
            }
            system.debug('xxx-CTH-RCPR-10-' + triggerCycleCount + ':AFT Comm Pref newRelations.size()-' + newRelations.size());

            insert newRelations;
            system.debug('xxx-CTH-RCPR-97-' + triggerCycleCount + ':Limits.getDMLRows()-' + Limits.getDMLRows());
            system.debug('xxx-CTH-RCPR-98-' + triggerCycleCount + ':Limits.getLimitDMLRows()-' + Limits.getLimitDMLRows());
            system.debug('xxx-CTH-RCPR-99-' + triggerCycleCount + ':newRelations.size-' + newRelations.size());
        }
        system.debug('xxx-CTH-RCPR-99-' + triggerCycleCount + ':contacts.size-' + contacts.size());
    }

    private void updateRelatedUserData(List<Contact> contacts) {
        //if certain fields are changed on the SF Contact, then update the associated fields on any active Community Users

        //SELECTIVITY: Only contact record-types that have SF User Community Users
        Set<ID> conRecTypeIDs = new Set<ID>();
        conRecTypeIDs.add(RecordTypes.contact_IRDealer.ID);
        conRecTypeIDs.add(RecordTypes.contact_IRDealerCanada.ID);
        conRecTypeIDs.add(RecordTypes.contact_IRDealerAPAC.ID);
        conRecTypeIDs.add(RecordTypes.contact_ServiceDealer.ID);

        List<ID> conIDsWithPossibleUser = new List<ID>();
        Map<ID, Contact> conMap = new Map<ID, Contact>();
        for (Contact c : contacts) {
            if (conRecTypeIDs.contains(c.RecordTypeID) && c.Role_at_the_Account__c != 'MTD System Contact') {
                conIDsWithPossibleUser.add(c.ID);
                conMap.put(c.ID, c);
            }
        }
        //-- ---------------------
        //-- START SELECTIVE WORK
        //-- ---------------------
        if (conIDsWithPossibleUser.size() > 0) {
            //PREP HELPER MAPS
            Map<ID, User> activeUserMap = new Map<ID, User>(
                [
                    SELECT ID, Firstname, LastName, Email, ContactID
                    FROM User
                    WHERE ContactID IN :conIDsWithPossibleUser AND IsActive = TRUE AND UserType = 'PowerPartner'
                ]
            );

            //WORK
            List<User> updates = new List<User>();
            for (User u : activeUserMap.values()) {
                if (conMap.containsKey(u.ContactID)) {
                    Boolean updateUser = false;
                    Contact c = conMap.get(u.ContactID);
                    User up = new User(ID = u.ID);
                    if (c.FirstName != null && c.FirstName != u.FirstName) {
                        up.FirstName = c.FirstName;
                        updateUser = true;
                    }
                    if (c.LastName != null && c.LastName != u.LastName) {
                        up.LastName = c.LastName;
                        updateUser = true;
                    }
                    if (c.Email != null && c.Email != u.Email) {
                        up.Email = c.Email;
                        updateUser = true;
                    }
                    if (updateUser) {
                        updates.add(up);
                    }
                }
            }

            if (updates.size() > 0) {
                if (!TriggerHelper.hasAlreadyfired()) {
                    TriggerHelper.setAlreadyfired();
                    Boolean suppressApexObjectNulls = true;
                    UserHelper.updateUsersAsync(JSON.serialize(updates, suppressApexObjectNulls));
                }
            }
        }
        //-- ---------------------
        //-- END SELECTIVE WORK
        //-- ---------------------
    }
    /* Commenting this out as it doesn't appear to be in use anywhere - Chuck 10/24/28
    private void updateUserPermissionSetAssignments(List<Contact> contacts) {

        Map<Id, SObject> oldCommunityPermissionsMap = new Map<Id, SObject>();
        Set<Id> oldCommunityPermissionIds = new Set<Id>();
        Set<Id> communityPermissionIds = new Set<Id>();
        Set<Id> removeContactCommunityPermissionIds = new Set<Id>();
        for (Contact c : contacts){
            Contact oldContact = (Contact)Trigger.oldMap.get(c.ID);
            if(c.Community_Permissions__c !=  oldContact.Community_Permissions__c && c.Community_Permissions__c != null){
                communityPermissionIds.add(c.Community_Permissions__c);
                oldCommunityPermissionIds.add(oldContact.Community_Permissions__c);
            }
            else if (c.Community_Permissions__c !=  oldContact.Community_Permissions__c && c.Community_Permissions__c == null){
                communityPermissionIds.add(oldContact.Community_Permissions__c);
                removeContactCommunityPermissionIds.add(c.Id);
            }
        }

        if(communityPermissionIds.size() > 0 || oldCommunityPermissionIds.size() > 0) {
            //communityPermissionsAdded
            List<Community_Permissions__c> communityPermissionsList = [
                    Select Id, Name, ADD_Business_Management__c,
                            ADD_Invoicing__c, ADD_Einstein_Dashboard__c,
                            ADD_MAC_Financing__c, ADD_Parts_Ordering__c, ADD_Warranty__c
                    From Community_Permissions__c
                    Where Id IN :communityPermissionIds
            ];

            //communityPermissionsChanged
            if (oldCommunityPermissionIds != null) {
                Map<Id, Community_Permissions__c> oldCommunityPermissionsList = new Map<Id, Community_Permissions__c>([
                        Select Id, Name, ADD_Business_Management__c,
                                ADD_Invoicing__c, ADD_Einstein_Dashboard__c,
                                ADD_MAC_Financing__c, ADD_Parts_Ordering__c, ADD_Warranty__c
                        From Community_Permissions__c
                        Where Id IN :oldCommunityPermissionIds
                ]);
                PermissionSetAssignmentHelper.setPermissionSetAssignment(communityPermissionsList, oldCommunityPermissionsList, false);
            } else {
                PermissionSetAssignmentHelper.setPermissionSetAssignment(communityPermissionsList, false, removeContactCommunityPermissionIds);
            }
        }
    }
	*/
    private void setCommunityPermissionForNewContacts(List<Contact> contacts) {
        //This method populates a blank Community_Preference__c record on CA Dealer Contacts without one.

        //Add the record types for any dealers that require Community Permissions assignments.
        Set<ID> conRecTypeIDs = new Set<ID>();
        conRecTypeIDs.add(RecordTypes.contact_IRDealerCanada.ID);

        map<Contact, Community_Permissions__c> contactCPMap = new Map<Contact, Community_Permissions__c>();
        for (Contact c : contacts) {
            if (conRecTypeIDs.contains(c.RecordTypeID)) {
                if (c.Community_Permissions__c == null) {
                    Community_Permissions__c cp = new Community_Permissions__c();
                    contactCPMap.put(c, cp);
                }
            }
        }
        if (contactCPMap.values().size() > 0) {
            insert contactCPMap.values();
            for (Contact c : contactCPMap.keySet()) {
                c.Community_Permissions__c = contactCPMap.get(c).Id;
            }
        }
    }
}
