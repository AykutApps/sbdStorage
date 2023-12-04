//test coverage from TestClass_MassTaskRequestCtl
public without sharing class MassTaskRequestHelper {
    /*
     */

    //---------------------
    //CORE PUBLIC GETTERS/SETTERS                           // instance variables only; use { get; set} syntax without code blocks
    //---------------------
    public ID requestID { get; private set; }
    public Mass_Task_Request__c request { get; private set; }

    //Public Mass_Task_Request__c request                     { get; set; }

    //---------------------
    //CONSTRUCTORS                                          // optional constructor for helper class
    //---------------------
    public MassTaskRequestHelper(String requestID) {
        this.requestID = requestID;
    }

    public MassTaskRequestHelper(Mass_Task_Request__c request) {
        this.request = request;
    }

    //---------------------
    //NON-CORE PUBLIC GETTERS                               // use getAttribute java syntax (e.g. getFullAccountName(){} )
    //---------------------

    //---------------------
    //PUBLIC INSTANCE METHODS                               // do not pass visual-flow specific variables; helper needs to support VISUAL-FLOW and non-VISUAL-FLOW consumers
    //---------------------

    //---------------------
    //PUBLIC STATIC METHODS                                 // do not pass visual-flow specific variables; helper needs to support VISUAL-FLOW and non-VISUAL-FLOW consumers
    //---------------------

    public static List<Mass_Task_Result__c> getSearchResults(Mass_Task_Request__c request) {
        String actionStatus = 'SUCCESSFUL';
        List<Mass_Task_Result__c> resultsList = new List<Mass_Task_Result__c>();

        try {
            List<Account> accounts = performAccountSearch(request);

            if (accounts != null) {
                resultsList = constructMassTaskResults(accounts, request);
            } else {
                actionStatus = 'INVALID_SEARCH';
            }
        } catch (Exception exc) {
            actionStatus = 'EXCEPTION';
            System.debug('********** MassTaskRequestHelper --> getSearchResults --> Action Status: ' + actionStatus);
            System.debug('********** MassTaskRequestHelper --> getSearchResults --> Exception: ' + exc);
        }

        return resultsList;
    }

    public static List<Mass_Task_Result__c> getMassSalesSearchResults(Mass_Task_Request__c request) {
        String actionStatus = 'SUCCESSFUL';
        List<Mass_Task_Result__c> resultsList = new List<Mass_Task_Result__c>();

        try {
            List<Account> accounts = performMassSalesAccountSearch(request);

            if (accounts != null) {
                resultsList = constructMSMassTaskResults(accounts, request);
            } else {
                actionStatus = 'INVALID_SEARCH';
            }
        } catch (Exception exc) {
            actionStatus = 'EXCEPTION';
            System.debug('********** MassTaskRequestHelper --> getMassSalesSearchResults --> Action Status: ' + actionStatus);
            System.debug('********** MassTaskRequestHelper --> getMassSalesSearchResults --> Exception: ' + exc);
        }

        return resultsList;
    }

    public static List<Mass_Task_Result__c> getAPACSearchResults(Mass_Task_Request__c request) {
        String actionStatus = 'SUCCESSFUL';
        List<Mass_Task_Result__c> resultsList = new List<Mass_Task_Result__c>();

        try {
            List<Account> accounts = performAPACAccountSearch(request);

            if (accounts != null) {
                resultsList = constructMassTaskResults(accounts, request);
            } else {
                actionStatus = 'INVALID_SEARCH';
            }
        } catch (Exception exc) {
            actionStatus = 'EXCEPTION';
            System.debug('********** MassTaskRequestHelper --> getAPACSearchResults --> Action Status: ' + actionStatus);
            System.debug('********** MassTaskRequestHelper --> getAPACSearchResults --> Exception: ' + exc);
        }

        return resultsList;
    }

    private static List<Mass_Task_Result__c> constructMassTaskResults(List<Account> accounts, Mass_Task_Request__c request) {
        List<Mass_Task_Result__c> resultsList = new List<Mass_Task_Result__c>();
        Service_Parts_Sales_Manager__c settings = null;
        String servicePartsSalesManager = null;
        String servicePartsSalesManagerID = null;

        for (Account account : accounts) {
            servicePartsSalesManager = (!String.isBlank(account.Service_Parts_Sales_Manager__c)) ? account.Service_Parts_Sales_Manager__c : '';
            settings = Service_Parts_Sales_Manager__c.getInstance(servicePartsSalesManager);
            if (settings != null) {
                servicePartsSalesManagerID = settings.SF_User_ID__c;
            }
            Mass_Task_Result__c tempObj = new Mass_Task_Result__c();
            tempObj.Result_Label__c = account.Name;
            tempObj.Result_Obj_Id__c = account.Id;
            tempObj.Result_Obj_Owner_Id__c = account.OwnerId;
            tempObj.Result_Obj_User_Id__c = account.FSD_Current__c;
            tempObj.Search_Source_Id__c = request.Id;
            tempObj.Entity_ID__c = account.Entity_ID__c;
            tempObj.PEID__c = account.PEID__c;
            tempObj.Account_Billing_City__c = account.BillingCity;
            tempObj.Account_Billing_State__c = account.BillingState;
            tempObj.Account_Site_Name__c = account.Site;
            tempObj.Service_Parts_Sales_Manager__c = servicePartsSalesManagerID;
            tempObj.Int_Ops_Support__c = account.Internal_Operations_Support__c;

            resultsList.add(tempObj);
        }

        return resultsList;
    }

    private static List<Mass_Task_Result__c> constructMSMassTaskResults(List<Account> accounts, Mass_Task_Request__c request) {
        List<Mass_Task_Result__c> resultsList = new List<Mass_Task_Result__c>();
        //Id, Name, OwnerId , Type, Store_Category__c, Snow_Stocking__c, Rider_Stocking__c, District_Manager__c, Mass_District__c, Dealer_Status__c, BillingState, BillingCity
        for (Account account : accounts) {
            Mass_Task_Result__c tempObj = new Mass_Task_Result__c();
            tempObj.Result_Obj_Id__c = account.Id;
            tempObj.Result_Obj_Owner_Id__c = account.OwnerId;
            tempObj.Search_Source_Id__c = request.Id;
            tempObj.Result_Label__c = account.Name;
            tempObj.Store_Number__c = account.Store_Number__c;
            tempObj.Store__c = account.Type;
            tempObj.Location_Type__c = account.Location_Type__c;
            tempObj.Store_Category__c = account.Store_Category__c;
            tempObj.Snow_Stocking__c = account.Snow_Stocking__c;
            tempObj.Account_Billing_City__c = account.BillingCity;
            tempObj.Account_Billing_State__c = account.BillingState;
            tempObj.Area_Managers__c = account.District_Manager__c;
            tempObj.District__c = (account.Mass_District__c != null) ? account.Mass_District__c.format() : '';

            resultsList.add(tempObj);
        }

        return resultsList;
    }

    public static void flagMassTaskSelectedFlag(ID requestID, boolean flag) {
        List<Mass_Task_Result__c> searchResults = [
            SELECT Selected__c, Search_Source_Id__c, Result_Obj_Id__c, Result_Label__c, IsDeleted, Id
            FROM Mass_Task_Result__c
            WHERE Search_Source_Id__c = :requestID
        ];

        for (Mass_Task_Result__c resultItem : searchResults) {
            resultItem.Selected__c = flag;
        }

        update searchResults;
    }

    public static void flagMassTaskSelectedFlag(List<Mass_Task_Result__c> searchResults, boolean flag) {
        if (!searchResults.isEmpty()) {
            for (Mass_Task_Result__c resultItem : searchResults) {
                resultItem.Selected__c = flag;
            }
            update searchResults;
        }
    }

    public static id createMassTasks(Mass_Task_Request__c request) {
        integer selectedCount;

        List<Mass_Task_Result__c> results = [
            SELECT
                Selected__c,
                Search_Source_Id__c,
                Result_Obj_Id__c,
                Result_Label__c,
                Result_Obj_Owner_Id__c,
                Result_Obj_User_Id__c,
                Service_Parts_Sales_Manager__c,
                Int_Ops_Support__c,
                IsDeleted,
                Id
            FROM Mass_Task_Result__c
            WHERE Selected__c = TRUE AND Search_Source_Id__c = :request.ID
        ];
        system.debug('dunk-results.size: ' + results.size());
        selectedCount = results.size();

        system.debug('xxx-selectedCount:' + selectedCount);
        if (selectedCount > 100) {
            system.debug('dunk-BATCH IT ' + results.size());
            system.debug('dunk-' + request.id);
            BulkTaskCreateSFTasksBatch b = new BulkTaskCreateSFTasksBatch();
            b.requestId = request.id;
            system.debug('xxx-b:' + b);
            ID BatchProcessId = Database.executeBatch(b, 50);
            return BatchProcessId;
        } else {
            system.debug('dunk-RUN IT NOW ' + results.size());
            //run it now
            createAssignmentsAndTasks(results, request.Id);
            return null;
        }
    }

    public static void batchEMailNotification(Mass_Task_Request__c request, Integer batchSize) {
        // *** My preference would be encapsulating the whole batch e-mail functionality in a helper class, this can be reused later.
        /*
         * 1. Query Aggregate of Tasks and associated users
         *    1.1 Fetch Task Owner Name, E-Mail Details
         *    1.2 Construct collection of 'Comm_Queue__c' objects based on the 'requet' and task metadata
         * 2. Insert 'Comm_Queue__c' collection
         * 3. Batch the e-mail operation
         */
        // (Request **Salesforce Support to enable "Polymorphic SOQL" in your organization)
        //List<AggregateResult> aggs = [SELECT Subject,Who.FirstName,Who.LastName,Who.Email FROM Task WHERE Mass_Task_Request__c = :request.ID GROUP BY OwnerID];

        List<AggregateResult> aggs = [SELECT OwnerID, count(Id) total_tasks FROM Task WHERE Mass_Task_Request__c = :request.ID GROUP BY OwnerID];
        Map<String, String> userIdTaskTotalMap = new Map<String, String>();

        for (AggregateResult agr : aggs) {
            userIdTaskTotalMap.put(String.valueOf(agr.get('OwnerID')), String.valueOf(agr.get('total_tasks')));
        }

        System.debug('********** MassTaskRequestHelper --> batchEMailNotification --> Agg Result Count: ' + userIdTaskTotalMap.size());

        List<Comm_Queue__c> eMailQ = new List<Comm_Queue__c>();
        List<User> users = [SELECT ID, Name, EMail FROM User WHERE ID IN :userIdTaskTotalMap.keySet()];

        Comm_Queue__c eMailQItem = null;

        for (User usr : users) {
            eMailQItem = new Comm_Queue__c();

            eMailQItem.Type__c = 'Email';
            eMailQItem.Status__c = 'Pending';
            eMailQItem.Who_ID__c = usr.ID;
            eMailQItem.Who_Email__c = usr.EMail;
            eMailQItem.What_ID__c = request.ID;
            eMailQItem.Subject__c = request.Task_Subject__c;
            eMailQItem.Body__c =
                'Dear ' +
                usr.Name +
                ', ' +
                userIdTaskTotalMap.get(usr.ID) +
                ' Mass Tasks with Subject, \'' +
                request.Task_Subject__c +
                '\' have been assigned to you. All tasks are viewable on your Salesforce home page.';
            eMailQ.add(eMailQItem);
        }

        if (!eMailQ.isEmpty()) {
            Database.insert(eMailQ);
            Id batchprocessID = Database.executeBatch(new MassTaskEMailBatch(request.ID), batchSize);
            System.debug('********** MassTaskRequestHelper --> batchEMailNotification --> Batchprocess ID: ' + batchprocessID);
        }
    }

    //---------------------
    //PRIVATE METHODS - FOR NON-STATIC METHODS              // do not pass visual-flow specific variables; helper needs to support VISUAL-FLOW and non-VISUAL-FLOW consumers
    //---------------------
    private void init() {
    }

    //search for Mass Retailers inc. Home Depot, Lowes, Tractor Supply Corp (TSC)
    private static List<Account> performMassSalesAccountSearch(Mass_Task_Request__c request) {
        List<Account> accounts = new List<Account>();
        String varAccRecTypeId = request.Account_Record_Type_ID__c;

        String sqlQuery = null;
        String baseQuery =
            'SELECT Id, Name, Store_Number__c, OwnerId , Type, Location_Type__c, Store_Category__c, Snow_Stocking__c, Rider_Stocking__c ' +
            ' , District_Manager__c, Mass_District__c, Dealer_Status__c, BillingState, BillingCity ' +
            ' FROM Account ';

        if (!String.isBlank(varAccRecTypeId)) {
            List<String> stores = String.isBlank(request.Store__c) ? null : request.Store__c.split(';');
            List<String> storeCtgris = String.isBlank(request.Store_Category__c) ? null : request.Store_Category__c.split(';');

            List<String> stockings = String.isBlank(request.Stocking__c) ? null : request.Stocking__c.split(';');
            List<String> areaManagers = String.isBlank(request.Area_Managers__c) ? null : request.Area_Managers__c.split(',');

            List<String> varDistricts = (!String.isBlank(request.District__c)) ? request.District__c.split(';') : null;
            System.debug('@@@@@@ Store: ' + request.Store__c);
            System.debug('@@@@@@ Stores: ' + stores);
            System.debug('@@@@@@ varDistricts: ' + varDistricts);
            /* String varDealer_Status                = request.Dealer_Status__c; 
String locationType = request.Location_Type__c ;
List <String> locationTypes= (!String.isBlank(request.Location_Type__c))? request.Location_Type__c.split(';'): null;    */

            String varBillingState = request.Billing_State__c;

            sqlQuery = baseQuery + ' WHERE RecordTypeId = \'' + varAccRecTypeId + '\'';

            if (stores != null) {
                sqlQuery += ' and Type IN :stores';
            }

            if (storeCtgris != null) {
                sqlQuery += ' and Store_Category__c IN :storeCtgris';
            }

            if (stockings != null) {
                for (String stocking : stockings) {
                    if (stocking.equals('Snow')) {
                        sqlQuery += ' and Snow_Stocking__c = true';
                    } else if (stocking.equals('Rider')) {
                        sqlQuery += ' and Rider_Stocking__c = true';
                    }
                }
            }

            if (areaManagers != null) {
                sqlQuery += ' and Owner.Id IN :areaManagers';
            }

            /* if (locationTypes != null){
sqlQuery+= ' and Location_Type__c IN :locationTypes';
}

if (varDealer_Status != null){
sqlQuery+= ' and Dealer_Status__c = \''+varDealer_Status+'\'';
}
*/
            List<Integer> districtList = convertStrListToIntList(varDistricts);
            if (!districtList.isEmpty()) {
                sqlQuery += ' and Mass_District__c IN :districtList';
            }

            if (!String.isBlank(varBillingState)) {
                sqlQuery += ' and BillingState = \'' + varBillingState + '\'';
            }

            sqlQuery += ' ORDER BY Name, BillingState, BillingCity ';
            accounts = Database.query(sqlQuery);
        } else {
            List<Id> allowedRecTypeIds = new List<Id>();
            allowedRecTypeIds.add(RecordTypes.account_MSProspectiveAccount.Id);
            allowedRecTypeIds.add(RecordTypes.account_MSAuthorizedAccount.Id);
            allowedRecTypeIds.add(RecordTypes.account_MSTerminatedAccount.Id);
            System.debug('********** Global Task Account Search Store_Numbers__c: ' + request.Store_Numbers__c);
            List<String> entityIdList = String.isBlank(request.Store_Numbers__c) ? null : request.Store_Numbers__c.split('\r\n');
            if (!entityIdList.isEmpty()) {
                system.debug('xxx-entityidList: ' + entityIdList);
                sqlQuery = baseQuery + ' WHERE RecordTypeId in :allowedRecTypeIds ';
                sqlQuery += ' AND Store_Number__c IN:entityIdList ';
                sqlQuery += ' ORDER BY Store_Number__c, Name, Site, BillingState, BillingCity ';
                system.debug('xxx-sqlQuery: ' + sqlQuery);
                accounts = Database.query(sqlQuery);
            }
        }

        System.debug('********** Global Task Account Search QUERY: ' + sqlQuery);

        return accounts;
    }

    //search for IR-USA Dealers
    private static List<Account> performAccountSearch(Mass_Task_Request__c request) {
        List<Account> accounts = new List<Account>();
        String varAccRecTypeId = request.Account_Record_Type_ID__c;

        String sqlQuery = null;
        String baseQuery =
            'SELECT Id, Name, OwnerId , FSD_Current__c, Service_Parts_Sales_Manager__c, Internal_Operations_Support__c ' +
            ' , Entity_ID__c, PEID__c, Site, BillingState, BillingCity ' +
            ' FROM Account ';

        if (!String.isBlank(varAccRecTypeId)) {
            List<String> varSpringSummerLevel = String.isBlank(request.Current_Spring_Summer_Level__c) ? null : request.Current_Spring_Summer_Level__c.split(';');
            List<String> varFutureSpringSummerLevel = String.isBlank(request.Future_Spring_Summer_Level__c) ? null : request.Future_Spring_Summer_Level__c.split(';');

            List<String> varSnowLevel = String.isBlank(request.Snow_Level__c) ? null : request.Snow_Level__c.split(';');
            List<String> varSalesperson_Type = String.isBlank(request.Salesperson_Type__c) ? null : request.Salesperson_Type__c.split(';');
            List<String> varCurrent_Regions = String.isBlank(request.Current_Region__c) ? null : request.Current_Region__c.split(';');
            System.debug('********** MassTaskRequestHelper --> performAccountSearch --> request.Current_Territories__c: ' + request.Current_Territories__c);
            //List <String> varCurrent_Territories= String.isBlank(request.Current_Territories__c)?null:request.Current_Territories__c.split(';');
            //List <String> varCurrent_Territories= (!String.isBlank(request.Current_Territories__c))? request.Current_Territories__c.replace('[', '').replace(']', '').split(', '): null;
            List<String> varCurrent_Territories = (!String.isBlank(request.Current_Territories__c)) ? request.Current_Territories__c.split(',') : null;
            String varDealer_Status = request.Dealer_Status__c;
            String varBillingState = request.Billing_State__c;
            String varService_Parts_Sales_Manager = request.Service_Parts_Sales_Manager__c;
            boolean varCurrentlyOnDealerPanel = request.Currently_on_Dealer_Panel__c;
            String dealerType = request.Dealer_Type__c;
            List<String> dealerTypes = (!String.isBlank(request.Dealer_Type__c)) ? request.Dealer_Type__c.split(';') : null;

            sqlQuery = baseQuery + ' WHERE RecordTypeId = \'' + varAccRecTypeId + '\'';

            if (varSpringSummerLevel != null) {
                sqlQuery += ' and Spring_Summer_Level__c IN :varSpringSummerLevel';
            }

            if (varFutureSpringSummerLevel != null) {
                sqlQuery += ' and Future_Spring_Summer_Level__c IN :varFutureSpringSummerLevel';
            }

            if (varSnowLevel != null) {
                sqlQuery += ' and Snow_Level__c IN :varSnowLevel';
            }

            if (!String.isBlank(dealerType)) {
                sqlQuery += ' and Dealer_Type__c IN :dealerTypes ';
            }
            if (varSalesperson_Type != null) {
                sqlQuery += ' and Salesperson_Type__c IN :varSalesperson_Type';
            }
            System.debug('********** varCurrent_Regions: ' + varCurrent_Regions);
            List<Decimal> regList = convertStrListToDecList(varCurrent_Regions);
            if (!regList.isEmpty()) {
                sqlQuery += ' and Region_Current__c IN :regList';
            }

            List<Integer> tertyList = convertStrListToIntList(varCurrent_Territories);
            if (!tertyList.isEmpty()) {
                sqlQuery += ' and Territory_Current__c IN :tertyList';
            }

            if (varDealer_Status != null) {
                sqlQuery += ' and Dealer_Status__c = \'' + varDealer_Status + '\'';
            }

            if (!String.isBlank(varBillingState)) {
                sqlQuery += ' and BillingState = \'' + varBillingState + '\'';
            }

            if (!String.isBlank(varService_Parts_Sales_Manager)) {
                sqlQuery += ' and Service_Parts_Sales_Manager__c = \'' + varService_Parts_Sales_Manager + '\'';
            }

            if (varCurrentlyOnDealerPanel) {
                sqlQuery += ' and Currently_on_Dealer_Panel__c = true ';
            }

            sqlQuery += ' ORDER BY Name, Site, BillingState, BillingCity, Entity_ID__c ';
            accounts = Database.query(sqlQuery);
        } else {
            List<Id> allowedRecTypeIds = new List<Id>();
            allowedRecTypeIds.add(RecordTypes.account_IRProspectiveDealer.Id);
            allowedRecTypeIds.add(RecordTypes.account_IRAuthorizedDealer.Id);
            allowedRecTypeIds.add(RecordTypes.account_IRTerminatedDealer.Id);
            System.debug('********** Global Task Account Search Entity_IDs__c: ' + request.Entity_IDs__c);
            List<String> entityIdList = String.isBlank(request.Entity_IDs__c) ? null : request.Entity_IDs__c.split('\r\n');
            if (!entityIdList.isEmpty()) {
                sqlQuery = baseQuery + ' WHERE RecordTypeId in :allowedRecTypeIds ';
                sqlQuery += ' AND Entity_ID__c IN :entityIdList ';
                sqlQuery += ' ORDER BY Name, Site, BillingState, BillingCity, Entity_ID__c ';
                accounts = Database.query(sqlQuery);
            }
        }
        System.debug('********** Global Task Account Search QUERY: ' + sqlQuery);

        return accounts;
    }

    //search for IR-APAC dealers
    private static List<Account> performAPACAccountSearch(Mass_Task_Request__c request) {
        List<Account> accounts = new List<Account>();
        String varAccRecTypeId = request.Account_Record_Type_ID__c;

        String sqlQuery = null;
        String baseQuery =
            'SELECT Id, Name, OwnerId , FSD_Current__c, Service_Parts_Sales_Manager__c, Internal_Operations_Support__c ' +
            ' , Entity_ID__c, PEID__c, Site, BillingState, BillingCity ' +
            ' FROM Account ';

        if (!String.isBlank(varAccRecTypeId)) {
            String varDealer_Status = request.Dealer_Status__c;
            String dealerType = request.Dealer_Type__c;
            List<String> dealerTypes = (!String.isBlank(request.Dealer_Type__c)) ? request.Dealer_Type__c.split(';') : null;
            String typeAPAC = request.Type__c;
            String classAPAC = request.CLASS__c;
            List<String> classAPACs = (!String.isBlank(request.CLASS__c)) ? request.CLASS__c.split(';') : null;

            List<String> businessTerriotory = String.isBlank(request.Business_Territory__c) ? null : request.Business_Territory__c.split(';');
            boolean varMarketingPartner = request.Marketing_Partner__c;
            boolean varAUStocklist = request.Australia_Stockist__c;

            sqlQuery = baseQuery + ' WHERE RecordTypeId = \'' + varAccRecTypeId + '\'';

            if (varDealer_Status != null) {
                sqlQuery += ' and Dealer_Status__c = \'' + varDealer_Status + '\'';
            }

            if (!String.isBlank(dealerType)) {
                sqlQuery += ' and Dealer_Type__c IN :dealerTypes ';
            }

            if (!String.isBlank(typeAPAC)) {
                sqlQuery += ' and Type =:typeAPAC';
            }

            if (!String.isBlank(classAPAC)) {
                sqlQuery += ' and CLASS__c INCLUDES :classAPACs ';
            }

            if (businessTerriotory != null) {
                sqlQuery += ' and Business_Territory__c IN :businessTerriotory';
            }

            if (varMarketingPartner) {
                sqlQuery += ' and Marketing_Partner__c = true ';
            }

            if (varAUStocklist) {
                sqlQuery += ' and Australia_Stockist__c = true ';
            }

            sqlQuery += ' ORDER BY Name, Site, BillingState, BillingCity, Entity_ID__c ';

            accounts = Database.query(sqlQuery);
        } else {
            List<Id> allowedRecTypeIds = new List<Id>();
            allowedRecTypeIds.add(RecordTypes.account_APACProspectiveAccount.Id);
            allowedRecTypeIds.add(RecordTypes.account_APACAuthorizedAccount.Id);
            allowedRecTypeIds.add(RecordTypes.account_APACTerminatedAccount.Id);
            System.debug('********** Global Task APAC Account Search Entity_IDs__c: ' + request.Entity_IDs__c);
            List<String> entityIdList = String.isBlank(request.Entity_IDs__c) ? null : request.Entity_IDs__c.split('\r\n');
            if (!entityIdList.isEmpty()) {
                sqlQuery = baseQuery + ' WHERE RecordTypeId in :allowedRecTypeIds ';
                sqlQuery = ' AND Entity_ID__c IN :entityIdList ';
                sqlQuery += ' ORDER BY Name, Site, BillingState, BillingCity, Entity_ID__c ';
                accounts = Database.query(sqlQuery);
            }
        }

        System.debug('********** Global Task APAC Account Search QUERY: ' + sqlQuery);

        return accounts;
    }

    public static List<Decimal> convertStrListToDecList(List<String> strList) {
        List<Decimal> decList = new List<Decimal>();

        if (strList != null) {
            for (String region : strList) {
                if (!String.isBlank(region)) {
                    decList.add(Integer.valueOf(region));
                }
            }
        }

        return decList;
    }

    public static List<Integer> convertStrListToIntList(List<String> strList) {
        List<Integer> decList = new List<Integer>();

        if (strList != null) {
            for (String region : strList) {
                if (!String.isBlank(region)) {
                    decList.add(Integer.valueOf(region));
                }
            }
        }

        return decList;
    }
    public static void createAssignmentsAndTasks(List<Mass_Task_Result__c> toProcess, ID requestId) {
        system.debug('dunk-toprocess count:' + toProcess.size());
        List<Task> taskList = new List<Task>();

        List<Bulk_Task_Assignment__c> assignList = new List<Bulk_Task_Assignment__c>();

        List<Business_Log_Table__c> logExceptions = new List<Business_Log_Table__c>();
        Business_Log_Table__c logItem = null;

        String logdinUserId = UserInfo.getUserId();
        system.debug('dunk-logdinUserId:' + logdinUserId);
        String ownerID;

        Mass_Task_Request__c request = [
            SELECT
                Id,
                Task_Owner__c,
                Task_Subject__c,
                Task_Priority__c,
                Given_Due_Date__c,
                Task_Record_Type_ID__c,
                Expected_Results__c,
                Task_Main_Category__c,
                Task_Secondary_Category__c,
                Photo_Needed__c,
                Task_Comments__c
            FROM Mass_Task_Request__c
            WHERE Id = :requestid
        ];
        system.debug('dunk-request:' + request);
        map<Id, Id> resultIdToAccountIdMap = new Map<Id, Id>(); //key=result.id  value=account.id
        for (Mass_Task_Result__c result : toProcess) {
            //loop through all resuilts aka 1 for each account on the Bulk Task Admin
            //create Assignments
            Bulk_Task_Assignment__c assignment = new Bulk_Task_Assignment__c();
            //set fields

            assignment.Bulk_Task_Admin__c = requestId;
            assignment.Account__c = result.Result_Obj_Id__c;
            //system.debug('dunk-assignment:'+assignment);
            assignList.add(assignment);
            resultIdToAccountIdMap.put(result.id, result.Result_Obj_Id__c);
        }
        system.debug('dunk-assignList:' + assignList);
        system.debug('dunk-resultIdToAccountIdMap:' + resultIdToAccountIdMap);
        system.debug('dunk-assignList.size:' + assignList.size());
        system.debug('dunk-resultIdToAccountIdMap.size:' + resultIdToAccountIdMap.size());
        if (!assignList.isEmpty()) {
            system.debug('dunk-isEmpty FALSE');
            //Database.DMLOptions dmo = new Database.DMLOptions();
            //dmo.EmailHeader.triggerUserEmail = false;
            try {
                Boolean allOrNone = false;
                List<Database.SaveResult> srs = Database.insert(assignList, allOrNone);
                for (Database.SaveResult sr : srs) {
                    system.debug('MJ-sr: ' + sr);
                    //if sr was successful, then do nothing.
                    //if not successfull, create a record for each failure via the system log helper
                }
                //insert assignList;
                for (Bulk_Task_Assignment__c bta : assignList) {
                    system.debug('MJ-bta: ' + bta.id);
                }
            } catch (Exception exc) {
                //system.debug('dunk-insert exception:' + exc.getMessage());     //convert to system log helper
            }
        }
        //prep map for task creation

        List<Bulk_Task_Assignment__c> assigns = new List<Bulk_Task_Assignment__c>();
        assigns = [SELECT ID, Account__c FROM Bulk_Task_Assignment__c WHERE Bulk_Task_Admin__c = :requestID];
        system.debug('dunk-assigns:' + assigns);
        system.debug('dunk-assigns.size:' + assigns.size());
        map<Id, Id> accountIdToAssignIdMap = new Map<Id, Id>(); //key account id, value assignment id
        for (Bulk_Task_Assignment__c ass : assigns) {
            accountIdToAssignIdMap.put(ass.account__c, ass.id);
        }
        system.debug('dunk-accountIdToAssignIdMap:' + accountIdToAssignIdMap);
        system.debug('dunk-accountIdToAssignIdMap.size:' + accountIdToAssignIdMap.size());
        //task creation -----

        for (Mass_Task_Result__c result : toProcess) {
            //loop through all resuilts aka 1 for each account on the Bulk Task Admin

            //create Tasks
            Task task = new Task();

            if (!(String.isBlank(request.Task_Owner__c)) && request.Task_Owner__c.equals('Self')) {
                ownerID = logdinUserId;
            } else if (!(String.isBlank(request.Task_Owner__c)) && request.Task_Owner__c.equals('Account Owner')) {
                ownerID = result.Result_Obj_Owner_Id__c;
            } else if (!(String.isBlank(request.Task_Owner__c)) && request.Task_Owner__c.equals('FSD')) {
                if (!(String.isBlank(result.Result_Obj_User_Id__c))) {
                    ownerID = result.Result_Obj_User_Id__c;
                } else {
                    ownerID = logdinUserId;

                    logItem = new Business_Log_Table__c();
                    logItem.Entity_ID__c = result.Result_Obj_Id__c;
                    logItem.Subject__c = 'Mass Task Subject, ' + request.Task_Subject__c;
                    logItem.Body__c = 'FSD is missing on the Account, ' + result.Result_Label__c + '. So the task has been assigned to Task creator, ' + UserInfo.getName();

                    logExceptions.add(logItem);
                }
            } else if (!(String.isBlank(request.Task_Owner__c)) && request.Task_Owner__c.equals('Internal Operations Support')) {
                if (!(String.isBlank(result.Int_Ops_Support__c))) {
                    ownerID = result.Int_Ops_Support__c;
                } else {
                    ownerID = logdinUserId;

                    logItem = new Business_Log_Table__c();
                    logItem.Entity_ID__c = result.Result_Obj_Id__c;
                    logItem.Subject__c = 'Mass Task Subject, ' + request.Task_Subject__c;
                    logItem.Body__c =
                        'Internal Operations Support user is missing on the Account, ' +
                        result.Result_Label__c +
                        '. So the task has been assigned to Task creator, ' +
                        UserInfo.getName();

                    logExceptions.add(logItem);
                }
            } else if (!(String.isBlank(request.Task_Owner__c)) && request.Task_Owner__c.equals('Service Parts Sales Manager')) {
                if (!(String.isBlank(result.Service_Parts_Sales_Manager__c))) {
                    ownerID = result.Service_Parts_Sales_Manager__c;
                } else {
                    ownerID = logdinUserId;

                    logItem = new Business_Log_Table__c();
                    logItem.Entity_ID__c = result.Result_Obj_Id__c;
                    logItem.Subject__c = 'Mass Task Subject, ' + request.Task_Subject__c;
                    logItem.Body__c =
                        'Service Parts Sales Manager is missing on the Account, ' +
                        result.Result_Label__c +
                        '. So the task has been assigned to Task creator, ' +
                        UserInfo.getName();

                    logExceptions.add(logItem);
                }
            }
            //system.debug('dunk-ownerID:'+ownerID);
            if (accountIdToAssignIdMap.containsKey(result.Result_Obj_Id__c)) {
                id assignId = accountIdToAssignIdMap.get(result.Result_Obj_Id__c);

                if (assignId != null) {
                    task.Bulk_Task_Assignment__c = assignId;
                    task.WhatId = result.Result_Obj_Id__c; //mburr.2020-09-29 what-id needs to be the account so that it looks nice on the task list on the rep's home page
                    task.Account__c = result.Result_Obj_Id__c;
                    task.OwnerId = ownerID;
                    task.Subject = request.Task_Subject__c;
                    task.Priority = request.Task_Priority__c;
                    task.ActivityDate = request.Given_Due_Date__c;
                    task.Mass_Task_Request__c = request.ID;
                    task.RecordTypeId = request.Task_Record_Type_ID__c;
                    task.Expected_Results__c = request.Expected_Results__c;
                    task.Main_Category__c = request.Task_Main_Category__c;
                    task.Secondary_Category__c = request.Task_Secondary_Category__c;
                    task.Photos_Needed__c = (request.Photo_Needed__c) ? 'Yes' : null;
                    task.Description = request.Task_Comments__c;

                    taskList.add(task);
                }
            }
        }
        system.debug('xxx-taskList:' + taskList);
        system.debug('xxx-taskList.size:' + taskList.size());
        //last steps
        if (!taskList.isEmpty()) {
            System.debug('xxx-tasks:' + taskList);
            //Database.DMLOptions dmo = new Database.DMLOptions();
            //dmo.EmailHeader.triggerUserEmail = false;
            try {
                system.debug('xxx-taskList B4: ' + taskList);
                insert taskList;
                system.debug('xxx-taskList AFT: ' + taskList);
                //Database.insert(taskList,dmo); //6000
            } catch (Exception exc) {
                system.debug('dunk-insert task failed: ' + exc.getCause());
            }
        }

        system.debug('dunk-logExceptions: ' + logExceptions);
        if (!logExceptions.isEmpty()) {
            Database.insert(logExceptions);
        }
    }
}
