@isTest
private class EmailHelperTest {
    static testMethod void testSendSingleEmail() {
    	Account a = TestData_Account.createDealerAccount();
        //contact
        Contact c = TestData_Contact.createDealerContact(a.ID, 'Max', 'TestDefault');
        c.email = 'enforcers.deploy@mtdproducts.com';
   		c.RecordTypeID= RecordTypes.contact_MTDInternal.ID;
        c.Role_at_the_Account__c = 'Team Email Address';
        update c;

        
        string subject ='test';
        string body ='testBody';
        
        test.startTest();
        EmailHelper h = new EmailHelper(Emails.contact_enforcersDeploy.id); 
        
        system.assertEquals(true, h.sendSingleEmail(subject, body, Emails.contact_enforcersDeploy.id));
        
    }

    static testMethod void testDefaultConstructor() {
        //default constructor doesn't set the OrgWideDefaultAddress (FROM) or the senderDisplayName 

        //assumes that an SF Email Template "Map_Portal_User_To_SF_Contact_Email" already exists in the ORG 
        String template001_api = '001';
        Map<String,Comm_Template__c> commTemplateMap = TestData_CommunicationTemplate.createCommunicationTemplate();
        Comm_Template__c template001 = commTemplateMap.get(template001_api);
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
        q.Subject__c = null;
        q.Body__c = null;
        q.Comm_Template_FK__c = template001.id;
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

        EmailHelper h = new EmailHelper();
        h.sendQueuedSingleEmail(expectedRecord); //REMINDER: SFDC prevents emails from being sent from a test method
    }
    static testMethod void testOrgWideDefaultIdConstructor() {
        //test constructor that receives an SF ID for the OrgWideDefaultAddress (FROM) 

        //assumes that the OrgWideEmailAddress is pre-configured in every ORG for dealercommunitysupport@cubcadet.com
        OrgWideEmailAddress fromAddressConfig = [
                    SELECT Address,DisplayName,Id 
                    FROM OrgWideEmailAddress 
                    WHERE Address = 'dealercommunitysupport@cubcadet.com'
                    ]; 
        //assumes that an SF Email Template "Map_Portal_User_To_SF_Contact_Email" already exists in the ORG 
        String template001_api = '001';
        Map<String,Comm_Template__c> commTemplateMap = TestData_CommunicationTemplate.createCommunicationTemplate();
        Comm_Template__c template001 = commTemplateMap.get(template001_api);
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
        q.Subject__c = null;
        q.Body__c = null;
        q.Comm_Template_FK__c = template001.id;
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

        EmailHelper h = new EmailHelper(fromAddressConfig.ID);
        h.sendQueuedSingleEmail(expectedRecord); //REMINDER: SFDC prevents emails from being sent from a test method
    }
    static testMethod void testSenderDisplayNameConstructor() {
        //test constructor that receives a string for the "Sender Display Name"
        
        String senderDisplayName = 'MTD Products Support Test';
        
        //assumes that an SF Email Template "Map_Portal_User_To_SF_Contact_Email" already exists in the ORG 
        String template001_api = '001';
        Map<String,Comm_Template__c> commTemplateMap = TestData_CommunicationTemplate.createCommunicationTemplate();
        Comm_Template__c template001 = commTemplateMap.get(template001_api);
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
        q.Subject__c = null;
        q.Body__c = null;
        q.Comm_Template_FK__c = template001.id;
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

        EmailHelper h = new EmailHelper(senderDisplayName);
        h.sendQueuedSingleEmails(emails); //REMINDER: SFDC prevents emails from being sent from a test method
    }
    static testMethod void testSubjectBodyNoTemplate() {
        //if a template isn't specified, then the SUBJECT & BODY fields on the Comm_Queue__c record are used.
        
        String senderDisplayName = 'MTD Products Support Test';
        
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

        EmailHelper h = new EmailHelper(senderDisplayName);
        h.sendQueuedSingleEmails(emails); //REMINDER: SFDC prevents emails from being sent from a test method
    }
    static testMethod void testNoEmailOnContact() {
        //if contact does not have an email, then an error should occur
        
        String senderDisplayName = 'MTD Products Support Test';
        
        //dealer
        Account a = TestData_Account.createDealerAccount();
        //contact
        Contact c = TestData_Contact.createDealerContact(a.ID, 'Max', 'TestDefault');
        c.email = null;
        update c;
        //queue up a pending email to send
        Comm_Queue__c q = new Comm_Queue__c();
        q.Type__c = 'Email';
        q.Who_ID__c = c.id;
        q.What_ID__c = null;
        q.Subject__c = 'Test Subject Line - no contact email';
        q.Body__c = 'Test Body';
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

        EmailHelper h = new EmailHelper(senderDisplayName);
        h.sendQueuedSingleEmails(emails); //REMINDER: SFDC prevents emails from being sent from a test method

    }
	//Start Static Method Test Classes
	@isTest static void testReplaceCommaWithPeriodNullAddress (){
        String e = null;
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('', fixedE);
    }
    
    @isTest static void testReplaceCommaWithPeriodEmptyAddress (){
        String e = '';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('', fixedE); 
    }
    
    @isTest static void testReplaceCommaWithPeriodCommaAddress (){
        String e = 'rm,ann13@outlook.com';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('rm.ann13@outlook.com', fixedE);
    }
    
    @isTest static void testReplaceCommaWithPeriod2CommasAddress (){
        String e = 'rm,ann13@out,look.com';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('rm.ann13@out.look.com', fixedE);
    }
    
        @isTest static void testReplaceCommaWithPeriodCommaStart (){
        String e = ',rm,ann13@outlook.com';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('rm.ann13@outlook.com', fixedE);
    }

//Business Scenario: Replace duplicate characters
  
        @isTest static void testDuplicateMultiple (){
        String e = 'r--mann13@@outlook..com';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('r-mann13@outlook.com', fixedE);
    }
 
        @isTest static void testDuplicateDash (){
        String e = 'r--mann13@outlook.com';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('r-mann13@outlook.com', fixedE);
    }
		@isTest static void testDuplicatePeriod (){
        String e = 'r.mann13@outlook..com';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('r.mann13@outlook.com', fixedE);
    }
        @isTest static void testDuplicateAt (){
        String e = 'rmann13@@outlook.com';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('rmann13@outlook.com', fixedE);
    }

//Business Scenario: Replace bad characters surrounding @
    @isTest static void testReplaceBadCharAroundAtSignNullAddress (){
        String e = null;
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('', fixedE);
    }
    
    @isTest static void testReplaceBadCharAroundAtSignEmptyAddress (){
        String e = null;
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('', fixedE);
    }
    
    @isTest static void testReplaceBadCharAroundAtSignLeft (){
        String e = 'rmann13!@outlook.com';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('rmann13@outlook.com', fixedE);
    }
    
    @isTest static void testReplaceBadCharAroundAtSignRight (){
        String e = 'rmann13@!outlook.com';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('rmann13@outlook.com', fixedE); 
    }
    
    @isTest static void testReplaceBadCharAroundAtSignLeftAndRight (){
        String e = 'rmann13!@!outlook.com';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('rmann13@outlook.com', fixedE);
    }
    
    @isTest static void testReplaceBadCharAroundAtSignGoodEmail (){
        String e = 'rmann13@outlook.com';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('rmann13@outlook.com', fixedE);
    }
    
     @isTest static void testReplaceFullRun (){
        String e = 'r,m,a,n,n,1,3!@$outlook.com';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('r.m.a.n.n.1.3@outlook.com', fixedE);
    }
 
     @isTest static void testNegativeAtFailure (){
        String e = 'Jimmyoutlook.com';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('Jimmyoutlook.com', fixedE);
    }
    
    @isTest static void testStartingAtFailure (){
        String e = '@Jimmyoutlook.com';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('@Jimmyoutlook.com', fixedE);
    }
    
        @isTest static void testEndingAtFailure (){
        String e = 'Jimmyoutlook.com@';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('Jimmyoutlook.com@', fixedE);
    }
    
        @isTest static void testSixCharacterFailure (){
        String e = 'a@m.c';
        String fixedE = null;
        fixedE = EmailHelper.fixEmail(e);
        system.assertEquals('a@m.c', fixedE);
    }    
}