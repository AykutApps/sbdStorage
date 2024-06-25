global class HustlerDealerProvisioningBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{
    /*  Hustler-ONLY DEALERS (IR-USA) If an SF Account Dealer_Type__c is X1,X2,X3 and Dealer_Status__c is 'Active', then a
    special/generic contact and community user are created called an Hustler Dealer user. 

    This batch job is idempotent.  It will look at all active hustler-dealers contact; however, it will only create the generic H# user
    if its not enable as user.
    
    Also:
    - the logic will enable the SF Account as a partner-community user by setting Account.IsPartner to true
    - this batch job will place the text for the CSV file in SObject Async_CSV_File__c; copy & paste the text into a CSV and
      send to the Active Directory Team so they can load the users.

     Batch Job should run at least once daily.
     --------------------------------------------------------------------------
     Execution Script:
     --------------------------------------------------------------------------
     HustlerDealerProvisioningBatch b = new HustlerDealerProvisioningBatch();
     b.whereClause = ' WHERE id IN (\'0037A00000opCsgQAE\',\'0037A00000opCsTQAU\',\'0037A00000opCu9QAE\') ';  //Contact Ids. 
     ID BatchProcessId = Database.executeBatch(b,1);    //mburr.2022-07-19 has to be 1 - logic that creates Async_Data__c record is not bulkified; record is missing SF User ID which prevents the permission set to be assigned
     //ToFuture: Ask Dinesh Batch size can be increase?
     --------------------------------------------------------------------------
    */

    //member variables accessible from start(), execute(), finish()
    global Id csvFileId;                        //Async_CSV_File__c is created via execute() if accountsToBeProcessed has records; 1 csv-file per Apex Batch Run (not per chunk)
    global Integer csvRowNum = 1;
    global DateTime processDataCreatedBefore;
    global string whereClause;
    
    global HustlerDealerProvisioningBatch(){}
    
    global Database.QueryLocator start(Database.BatchableContext ctx){
        system.debug('xxx-Hustler batch start()');
        String logItemSource = 'HustlerDealerProvisioningBatch';
        String codeIdentifier = 'start()';
        String loggedInUser = UserInfo.getUserId();
        String description = 'batch start';
        String extendedInformation = '';
        SystemLogHelper.insertSystemLogEvent(logItemSource, codeIdentifier, loggedInUser, description, extendedInformation);
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
        system.debug('bingo1 :: '+setDealerTypeValues);
        
        string query = ' select Id, FirstName, LastName, Email, AccountId, Account.Name'
                        + ' , Account.Entity_ID__c, Account.IsPartner, Account.Cub_Care__c'
                        + ' , Account.Business_Email_Address__c '
                        + ' from Contact ';
                        
        if(string.isNotBlank(whereClause)){
            query += whereClause;
        } else {
            query += ' where Account.Dealer_Type__c in :setDealerTypeValues ';
            query += ' AND Analytics_Dashboard_User__c = true ';
            query += ' AND Contact_Status__c = \'Active\' '; 
            query += ' ORDER BY CreatedDate DESC';
        }
        system.debug('bingo query string :: '+ query);
        //final steps
        if (Test.isRunningTest())
            query += ' LIMIT 200 ';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext ctx, List<Contact> lstContacts){
        String logItemSource = 'HustlerDealerProvisioningBatch';
        String codeIdentifier = 'execute()';
        String loggedInUser = UserInfo.getUserId();

        String log = 'batch execute() - contact chunk size ' + ((lstContacts == null) ? 0 : lstContacts.size());
        system.debug('xxx-HDPB ' + log);
        String description = log;
        String extendedInformation = '';
        SystemLogHelper.insertSystemLogEvent(logItemSource, codeIdentifier, loggedInUser, description, extendedInformation);

        boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        String orgName = getEnvironmentName(isSandbox);

        //Task 1. Enable partner community for active hustler dealers (if not already activated)
        List<Account> enablePCommunity = new LIst<Account>();
        set<Id> setAccId = new set<Id>();
        for(Contact c : lstContacts){
            if(c.Account.IsPartner = false && !setAccId.contains(c.AccountId)){
                Account up = new Account(ID=c.AccountId);
                up.IsPartner = true;
                enablePCommunity.add(up);
                
                setAccId.add(c.AccountId);
            }
        }
        if(enablePCommunity.size() > 0){
            update enablePCommunity;
        }
        
        //Task 2. Create SF User for the Hustler Dealer user
        Profile CSCBaseProfile = [select id, Name from profile where name='IR-HUSTLER-DLR-Base profile']; //need to change profile IR-HUSTLER-DLR-Base
        log = 'CSC Base Profile: '+CSCBaseProfile;
        system.debug('xxx-HDPB ' + log);
        description = log;
        extendedInformation = '';
        SystemLogHelper.insertSystemLogEvent(logItemSource, codeIdentifier, loggedInUser, description, extendedInformation);
        
        List<ID> genericSUserProfileIDs = new List<ID>();
        genericSUserProfileIDs.add(CSCBaseProfile.ID);

        ID permSetID_usSvcKB = [select id, Label from PermissionSet where Name = 'IR_HUSTLER_DLR_BASE_Dealer_Access'].ID;
        ID permSetLicenseID_anWaveCloud = [SELECT Id, Status FROM PermissionSetLicense where MasterLabel='Analytics Cloud - Wave Community Users'].Id;
            
        RecordType serviceContactRecType = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' and DeveloperName = 'IR_Dealer']; 
        log = 'Hustler Contact Rec Type: '+serviceContactRecType;
        system.debug('xxx-HDPB ' + log);
        description = log;
        extendedInformation = '';
        SystemLogHelper.insertSystemLogEvent(logItemSource, codeIdentifier, loggedInUser, description, extendedInformation);
        
        List<User> lstNewUsers    = new List<User>();
        User tmpUser = null;
        
        //Query to check Contact already enable as User or not
        Map<String, User> mapContactIdUser = new Map<String, User>();
        for(User u : [SELECT Id,ContactId,Name,Email, Username, FederationIdentifier FROM User WHERE ContactId IN :lstContacts ]){
            mapContactIdUser.put(u.ContactId, u);
        }
        
        //create User record
        for(Contact con : lstContacts){
            if(!(mapContactIdUser.containsKey(con.id))){
                log = 'No User exist with this contact as, '+con.FirstName +' '+con.LastName +', so create User';
                system.debug('xxx-HDPB ' + log);
                description = log;
                extendedInformation = '';
                SystemLogHelper.insertSystemLogEvent(logItemSource, codeIdentifier, loggedInUser, description, extendedInformation);
                
                 // Create missing Service Dealer User
                tmpUser = new User();
                tmpUser = setServiceDealerUserSettings(tmpUser, con, CSCBaseProfile, orgName, isSandbox);
                tmpUser.ContactId = con.Id;
                lstNewUsers.add(tmpUser);
            }
        }
        
        if(lstNewUsers != null & lstNewUsers.size() > 0){
            try{
                if(!test.isRunningTest())
                    Database.insert(lstNewUsers);
                
                lstNewUsers = [SELECT Id, Email, Username, FirstName, LastName, ContactId, Contact.Account.Name,
                                FederationIdentifier, Contact.Account.Entity_ID__c, Initial_Password__c
                               FROM User WHERE Id = :lstNewUsers];
                //System.setPassword(u.id,passwordString);
                
                //add each missing S# user to the CSV file for the Active Directory Team
                //Set<String> sNumbersOnCSV = new Set<String>();
                if(csvFileId == null){
                    csvFileId = createCSVFile();
                }
                    
                // create CSV data-rows for each new SFDC User
                List<Async_CSV_Row__c> csvDataRows = new List<Async_CSV_Row__c>();
                for(User u :lstNewUsers){
                    Async_CSV_Row__c r = new Async_CSV_Row__c();
                    r.Async_CSV_File__c = csvFileId;
                    r.Row_Number__c = ++csvRowNum;  //csv header is 1, all data rows are 2 or higher
                    r.Column_1__c = u.Id;
                    r.Column_2__c = u.FederationIdentifier; //S# 
                    r.Column_3__c = u.Initial_Password__c; // temporary password. ---
                    
                    string strName = u.FirstName + ' ' + u.LastName; 
                    if(strName.length()>25){
                        r.Column_4__c = strName.substring(0, 25);
                    }
                    else
                        r.Column_4__c = strName;
                    
                    r.Column_5__c = 'OU=MTD-Dealers-Legacy,OU=MTD-External,DC=mtdproducts,DC=com'; //Folder in Active Directory (determines permissions for AD User)
                    r.Column_6__c = u.Contact.Account.Entity_ID__c; //S# (extension attribute 10);
                    r.Column_7__c = u.Email;
                    csvDataRows.add(r);
                }
                
                //insert Async_CSV_Row__c records with the new S# users
                if(csvDataRows.size() > 0){
                    insert csvDataRows;
                }
                
                //create Async_Data__c record for each PermissionSet that needs to be created
                //NOTE:  Inserting PermissionSetAssignment records is not allowed due to MIXED_DML... error because this batch job might need to modify an SF Contact earlier of.
                List<Async_Data__c> newPermSets = new List<Async_Data__c>();
                for(User u :lstNewUsers){
                    Async_Data__c psa = new Async_Data__c();
                    psa.Queue_API_Name__c = 'USR_Assign_Permission_Set';
                    psa.SObject_API_Name__c = 'User';
                    psa.SObject_ID__c = u.ID;
                    String sNum = u.LastName;
                    psa.Record_Reference__c = permSetID_usSvcKB;
                    psa.Record_Reference_License__c = permSetLicenseID_anWaveCloud;
                    newPermSets.add(psa);
                }
                System.debug('xxx-SDPB New Permission Sets Count: '+newPermSets);
                Database.insert(newPermSets);
            }
            catch(Exception e){
                //System.debug('xxx-SDPB SFDC User creation/insertion exception: '+e);
                log = 'SFDC User creation/insertion exception';
                system.debug('xxx-HDPB '+log + ': ' +e);
                description = log;
                SystemLogHelper.insertSystemLogEvent(logItemSource, codeIdentifier, loggedInUser, description, e);
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        system.debug('xxx-HDPB batch finish() calls USR_AsyncAssignPermissionSetBatch');

        //make sure you do not process any records created after the source batch job starts
        if(processDataCreatedBefore == null){
            processDataCreatedBefore = Datetime.now().addSeconds(1);
        }
        system.debug('xxx-HDPB batch finish() - all Async_Data__c records just created - processDataCreatedBefore=' + processDataCreatedBefore );

        //start the batch job that creates the actual PermissionSetAssignment records from the Async_Data__c records inserted during this batch job's execution phase
        USR_AsyncAssignPermissionSetBatch b2 = new USR_AsyncAssignPermissionSetBatch();
        b2.processDataCreatedBefore = processDataCreatedBefore;
        ID BatchProcessId = Database.executeBatch(b2,100);
        system.debug('xxx-finish() start batch2-'+b2);
    }
    
    public static String getEnvironmentName(boolean isSandbox){

        String envName = '';
        if(isSandbox){
            String host = URL.getSalesforceBaseUrl().getHost();
            if(host.toLowerCase().contains('--')){
                envName = host.substring(host.indexOf('--')+2,host.indexOf('.'));
            }else{
               envName = 'NA';
            }
        }
        return envName;
    }
    
    public static User setServiceDealerUserSettings(User tmpUser, Contact con, Profile CSCBaseProfile, String orgName, Boolean isSandbox){
         string EntityId=con.Account.Entity_ID__c;
         tmpUser.FirstName = con.FirstName; //drop from first name 
         tmpUser.LastName = con.LastName;
         tmpUser.Alias = (!String.isBlank(EntityId) && EntityId.length() > 4)?EntityId.substring(0, 4):EntityId;
         tmpUser.Email = con.Email;
         
         string strLastName = StringUtilities.removeNonAlphaNumeric(con.LastName, '');
         strLastName = strLastName.substring(0,1).toUpperCase()+strLastName.substring(1,strLastName.length());
        
         string strFedId = con.Account.Entity_ID__c+'.'+con.FirstName.substring(0,1).toUpperCase()+strLastName;
         system.debug('strFedId  '+ strFedId);          
         
         // retun 2888.DTestBatchApex2

         //Nickname max length=40 only. 
         string strCommNickName = strFedId;
         if(strCommNickName.length() > 40){
            strCommNickName = strCommNickName.substring(0,39);
         }
        
         tmpUser.CommunityNickname = strCommNickName;
        
         if(CSCBaseProfile != null && CSCBaseProfile.Id != null){
            tmpUser.ProfileID = CSCBaseProfile.Id;
         }
         //tmpUser.User_License__c = 'Partner Community';

        // **** Check with Dave on provisioning part of the Service Account User
        // NOTE: Checked with Dave, we don't have to make a call to provisioning service to validate the Dederation Id with an assumpion that it is already implied.
        //Only 20 character allowed in federation id field.
        //Add .opg in Federation id.
        if(strFedId.length() > 16){
            strFedId = strFedId.substring(0,16);
            strFedId = strFedId +'.opg';
        }
        else
            strFedId = strFedId +'.opg';
        
        tmpUser.FederationIdentifier = strFedId;
        
        //drop from lastname. 
         if(isSandbox){
            tmpUser.Username = strFedId+'@sbdoutdoorcommunity.com'+'.'+orgName;
         }else{
            //SFDC Username:   <FED ID> + "@sbdoutdoorcommunity.com"
            tmpUser.Username = strFedId+'@sbdoutdoorcommunity.com';
         }
        
         /* generateNewPasswordAndNotifyUserImmediately field is not exposed over API
            https://success.salesforce.com/ideaView?id=08730000000kvx1AAA
            tmpUser.generateNewPasswordAndNotifyUserImmediately =  true;
         */

         /* receiveApprovalRequestEmails is not exposed over API
         https://success.salesforce.com/ideaView?id=08730000000aIbxAAE
         tmpUser.receiveApprovalRequestEmails = 'Never';   
         */
         
         Database.DMLOptions dmo = new Database.DMLOptions();
         dmo.EmailHeader.triggerUserEmail = false;
         User newUser = new User();
         // Fill all mandatory fields
         newUser.setOptions(dmo);
         
         tmpUser.LocaleSidKey = 'en_US';
         tmpUser.LanguageLocaleKey = 'en_US';
         tmpUser.TimeZoneSidKey = 'America/Los_Angeles';
         tmpUser.EmailEncodingKey = 'UTF-8';
         tmpUser.isActive = true;
         tmpUser.UserPreferencesHideS1BrowserUI = false;
         tmpUser.UserPermissionsSFContentUser = false;
        
         string passwordString= GenerateUserPassword.passwordGenerator(7);
         
         if(passwordString.contains('L')){
             passwordString = passwordString.replace('L', '9');
         }
        
         if(passwordString.contains('I')){
             passwordString = passwordString.replace('I', '4');
         }
         passwordString = passwordString +'@2';
         tmpUser.Initial_Password__c =passwordString;
         return tmpUser;
    }
    
    public static Id createCSVFile(){
        //create record representing the csv-file and return Async_CSV_File__c.ID
        String logItemSource = 'HustlerDealerProvisioningBatch';
        String codeIdentifier = 'createCSVFile()';
        String loggedInUser = UserInfo.getUserId();

        String csvConfigApi = 'IR_USA_Hustler_Create_Partner_Community_User';
        Async_CSV_Definition__c csvConfig;
        try{
            csvConfig = [   SELECT Id, Name 
                            , (SELECT Id, Name, Data_Type__c FROM Columns__r ORDER BY Order__c)
                            FROM Async_CSV_Definition__c 
                            WHERE Definition_API__c = :csvConfigApi
                            ];
        } catch (exception ex){
            String log = 'Error. Could not find the CSV Definition record';
            system.debug('xxx-HDPB '+log + ': ' +csvConfigApi);
            String description = log;
            SystemLogHelper.insertSystemLogEvent(logItemSource, codeIdentifier, loggedInUser, description, 'Abort Generic S# Creation.  Async_CSV_Definition__c record does not exist with defintion-api: ' + csvConfigApi);
            SystemLogHelper.insertSystemLogEvent(logItemSource, codeIdentifier, loggedInUser, description, ex);
            return null;
        }
        Async_CSV_File__c f = new Async_CSV_File__c();
        f.Async_CSV_Definition__c = csvConfig.Id;
        f.As_Of_date__c = Date.Today();
        f.File_Comments__c = 'Auto generated by HustlerDealerProvisioningBatch. ToDo: Copy CSV with headers to excel.';
        insert f;

        //create header row on CSV
        if(csvConfig.Columns__r != null){
            Async_CSV_Row__c r = new Async_CSV_Row__c();
            r.Async_CSV_File__c = f.Id;
            r.Row_Number__c = 1;  //csv header s/b row #1 on a CSV file
            Integer columnCnt = 1; 
            for(Async_CSV_File_Column__c col : csvConfig.Columns__r){
                if(columnCnt == 1) r.Column_1__c = col.Name;
                if(columnCnt == 2) r.Column_2__c = col.Name;
                if(columnCnt == 3) r.Column_3__c = col.Name;
                if(columnCnt == 4) r.Column_4__c = col.Name;
                if(columnCnt == 5) r.Column_5__c = col.Name;
                if(columnCnt == 6) r.Column_6__c = col.Name;
                if(columnCnt == 7) r.Column_7__c = col.Name;

                columnCnt++;
            }
            insert r;
        }

        return f.Id;
    }
}