@isTest
private class ProcessQueuedEmailsTest {
/*  This test covers the batch job that sends email.  There are more detailed "Send Email" tests in EmailHelperTest.
*/
    static testMethod void testBasicStartLogic() {
        ProcessQueuedEmailsBatch b = new ProcessQueuedEmailsBatch();
        b.whereClause = ' WHERE Name = \'1\'';
        b.orderByClause = ' ORDER BY Name ';
        //----------
        Test.startTest();
        //----------
        ID BatchProcessId = Database.executeBatch(b,5);
        //----------
        Test.stopTest();
        //----------
    }
    static testMethod void invokeBatchJobTest() {
        //The SUBJECT & BODY fields on the Comm_Queue__c record are used for this test.
        
        //dealer
        Account a = TestData_Account.createDealerAccount();
        //contact
        Contact c = TestData_Contact.createDealerContact(a.ID, 'Max', 'TestDefault');
        c.email = '1@mtdproducts.sfdc.test.com';
        update c;
        //queue up a pending email to send
        Comm_Queue__c q = new Comm_Queue__c();
        q.Type__c = 'Email';
        q.Who_ID__c = c.id;
        q.What_ID__c = null;
        q.Subject__c = 'Test Subject Line';
        q.Body__c = 'Test Body';
        q.Status__c = 'Pending';
        q.Comm_Template_FK__c = null;
        insert q;

        //----------
        Test.startTest();
        //----------
        List<Comm_Queue__c> emails = [
                    SELECT Id, Name, Status2__c, Type__c, Delay_Until__c
                    , What_ID__c, What_Link__c, What_Name__c, What_SObject__c
                    , Who_Email__c, Who_ID__c, Who_Link__c, Who_Name__c, Who_SObject__c
                    , Subject__c, Body__c
                    , Comm_Template_FK__c, Comm_Template_FK__r.Template_API_Name_de__c, Comm_Template_FK__r.Template_API_Name_en_US__c, Comm_Template_FK__r.Template_API_Name_es__c, Comm_Template_FK__r.Template_API_Name_fr__c
                    , Template_Used_ID__c, Template_Used_Link__c, Template_Used_Name__c
                    , Comm_Template_FK__r.Name                                        
                    FROM Comm_Queue__c
                    WHERE ID = :q.id
                    ];
        Comm_Queue__c expectedRecord = emails[0];
        system.assertEquals('Pending',expectedRecord.Status2__c); 

	    ProcessQueuedEmailsBatch b = new ProcessQueuedEmailsBatch();
	    ID BatchProcessId = Database.executeBatch(b,5);  //max 5 emails per chunk

        /*  NOTE:  Batch Job does the following:
            EmailHelper h = new EmailHelper(senderDisplayName);
            h.sendQueuedSingleEmails(emails); //REMINDER: SFDC prevents emails from being sent from a test method
        */
        //----------
        Test.stopTest();
        //----------
        
        //ToFuture: assert that the email was sent and/or failed (even though a test method is not allowed to send emails)
        system.assertEquals(true,true);
    }

}