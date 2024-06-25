global class CreateCommQueueRecordsBatch implements Database.Batchable<SObject>  {
    /*  This batch job will create Communication Queue records. 

     Batch Job should run at least once daily.
     --------------------------------------------------------------------------
     Execution Script:
     --------------------------------------------------------------------------
     CreateCommQueueRecordsBatch b = new CreateCommQueueRecordsBatch();
     b.whereClause = ' WHERE id IN (\'0057A000005xFoIQAU\',\'0057A000005xFoJQAU\',\'0057A000005xFoKQAU\') ';  //User Ids. 
     ID BatchProcessId = Database.executeBatch(b, 100);    
     --------------------------------------------------------------------------
    */
    
    global string whereClause;
    
    global Database.QueryLocator start(Database.BatchableContext ctx){
        set<string> setDealerTypeValues = new set<string>();
        
        Communication_Queue_Batch_Setting__mdt batchConfig = [SELECT Dealer_Types__c 
                                                                  FROM Communication_Queue_Batch_Setting__mdt 
                                                                 WHERE DeveloperName = 'Hustler' LIMIT 1];        
        if(string.isNotBlank(batchConfig.Dealer_Types__c)){
            if(batchConfig.Dealer_Types__c.contains(',')){
                String[] values = batchConfig.Dealer_Types__c.split(',');
                for(String val:values){  
                     setDealerTypeValues.add(val.trim());
                }  
            }
            else
                setDealerTypeValues.add(batchConfig.Dealer_Types__c.trim());
        }
        system.debug('bingo Comm Queue1 :: '+setDealerTypeValues);
        
       /* return Database.getQueryLocator([select Id, FirstName, LastName, Email, ContactId,  Contact.Contact_Status__c, Contact.Welcome_Email_Comment__c
                                          from User where Contact.Account.Dealer_Type__c in :setDealerTypeValues 
                                            and Contact.Analytics_Dashboard_User__c = true and Contact.Contact_Status__c = 'Active'
                                            and Contact.Welcome_Email_Comment__c = ''
                                        ]);*/
        string query = ' select Id, FirstName, LastName, Email, ContactId, Contact.Contact_Status__c'
                        + ' , Contact.Welcome_Email_Comment__c '
                        + ' from User ';
                        
        if(string.isNotBlank(whereClause)){
            query += whereClause;
        } else {
            query += ' where Contact.Account.Dealer_Type__c in :setDealerTypeValues ';
            query += ' AND Contact.Analytics_Dashboard_User__c = true ';
            query += ' AND Contact.Contact_Status__c = \'Active\' '; 
            query += ' AND Contact.Welcome_Email_Comment__c = \'\' '; 
            query += ' ORDER BY CreatedDate DESC';
        }
        system.debug('bingo query string :: '+ query);
        //final steps
        if (Test.isRunningTest())
            query += ' LIMIT 200 ';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext ctx, List<User> lstUser){
        List<Contact> lstUpdCon = new List<Contact>();
        List<Comm_Queue__c> eMailQ = new List<Comm_Queue__c>();
        Comm_Queue__c eMailQItem = null;
        Communication_Queue_Batch_Setting__mdt batchConfig = [SELECT Communication_Template__c 
                                                                  FROM Communication_Queue_Batch_Setting__mdt 
                                                                 WHERE DeveloperName = 'Hustler' LIMIT 1];     
        for(User usr:lstUser){            
            //Create Communication Queue Records
            eMailQItem = new Comm_Queue__c();
            eMailQItem.Type__c = 'Email';
            eMailQItem.Status__c = 'Pending';
            eMailQItem.Who_ID__c = usr.ID;
            eMailQItem.Who_Email__c = usr.EMail;
            eMailQItem.Who_SObject__c = 'User';
            eMailQItem.Comm_Template_FK__c=batchConfig.Communication_Template__c;
            eMailQ.add(eMailQItem);
            
            //update Contact as True. 
            Contact con = new Contact(Id=usr.ContactId);
            con.Welcome_Email_Comment__c = 'Email Queued ' + DateTime.now(); //Email Sent DateTime.Now.
            lstUpdCon.add(con);
        }
        
        if(!eMailQ.isEmpty() && !test.isrunningtest()){
            Database.insert(eMailQ);
        }
        
        if(!lstUpdCon.isEmpty()&& !test.isrunningtest()){
            TriggerHelper.setAlreadyfired();
            update lstUpdCon;
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}