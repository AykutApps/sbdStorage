global class B2B_CommunityUserBatch implements Database.Batchable<sObject>, Database.Stateful {
    /*  
        --------------------------------------------------------------------------
        Execution Script:
        --------------------------------------------------------------------------
        B2B_CommunityUserBatch b = new B2B_CommunityUserBatch();
        //b.whereClause = ' WHERE Id = \'0032300000cZtr1AAC\'';
        ID BatchProcessId = Database.executeBatch(b,200);     
        --------------------------------------------------------------------------
    */

    global string whereClause;

    global database.querylocator start(Database.BatchableContext bc) {
        //query for pending Async_Data__c records with queue 'ESG_Link_Envelope_To_SF_Account'
        String baseQuery = 'SELECT Id, ' + '(SELECT Id FROM Users WHERE IsActive = TRUE AND Profile.Name LIKE \'%Community User%\') ' + 'FROM Contact';
        String defaultWhereClause =
            ' WHERE RecordType.DeveloperName = \'IR_Dealer\' ' +
            'AND Contact_Status__c = \'Active\' ' +
            'AND Account_Record_Type_API__c = \'IR_Authorized_Dealer\' ' +
            'AND Account.Dealer_Status__c = \'Active\'';

        if (!String.isBlank(whereClause)) {
            baseQuery += whereClause;
        } else {
            baseQuery += defaultWhereClause;
        }

        return Database.getQueryLocator(baseQuery);
    }

    global void execute(Database.BatchableContext BC, List<Contact> toProcess) {
        Set<Id> contactIds = new Set<Id>();

        for (Contact contact : toProcess) {
            if (contact.Users.size() > 0) {
                contactIds.add(contact.Id);
            }
        }

        B2B_CommunityUserHelper.adjustUserPermissionsBasedOnContactFields(contactIds);
    }

    global void finish(Database.BatchableContext BC) {
    }
}
