// Prod Code
public with sharing class OrderingSalesRepDealerOrderFilterCtl extends CmsCtlCompBase {
    public List<SelectOption> eventOptions { get; set; }
    public List<SelectOption> fsdOptions { get; set; }
    public List<SelectOption> slaesRepOptions { get; set; }
    public String userProfile { get; set; }
    public Map<Id, Profile> profileIdMap { get; set; }

    public static final String adminProfileName = 'System Administrator';
    public static final String dealerAdminProfileName = 'MTD IR - Dealer Admin';

    public static final String fsdProfileName = 'MTD USA - Sales Rep and Leadership'; // JDUNK 3/5/19 value was 'MTD IR - Field Sales Director'
    public static final String fsdProfileNameMFA = 'MTD USA - Sales Rep and Leadership-MFA'; // JDUNK 3/5/19 value was 'MTD IR - Field Sales Director'

    public static final String salesSupportProfileName = 'MTD IR - Sales Support';

    public static final String salesRepProfileName = 'MTD USA - Sales Rep and Leadership'; // JDUNK 3/5/19 value was 'MTD IR - Sales Rep'
    public static final String salesRepProfileNameMFA = 'MTD USA - Sales Rep and Leadership-MFA'; // MBURR 7/7/22 support new MFA version of the profile

    public boolean isAdmin { get; set; } //is DEALER admin not a SYSTEM admin
    public boolean isFSD { get; set; } // JDUNK 3/5/19 FSDs are now called RSDs
    public boolean isSalesSupport { get; set; }
    public boolean isSalesRep { get; set; }

    public OrderingSalesRepDealerOrderFilterCtl() {
        this.isAdmin = false;
        this.isFSD = false;
        this.isSalesRep = false;
        this.isSalesSupport = false;
        this.fsdOptions = new List<SelectOption>();

        this.eventOptions = getEventsByEventRecTypeId(RecordTypes.orderingEvent_PreSeason.Id);
        this.userProfile = UserInfo.getProfileId();
        this.profileIdMap = getAllProfiles();
        list<User> users = [SELECT Id, Position__c, Future_Position__c, profileId, username FROM user WHERE id = :UserInfo.getUserId() LIMIT 1];
        User u = users[0];
        String pos = u.Position__c; //tofuture add logic to support the future position; only considering RSDs current sales reps now
        string tempProfile = profileIdMap.get(u.ProfileId).Name;
        system.debug('DUNK--u-' + u);
        system.debug('DUNK--tempProfile-' + tempProfile);
        system.debug('DUNK--adminProfileName-' + adminProfileName);
        system.debug('DUNK--dealerAdminProfileName-' + dealerAdminProfileName);
        if (tempProfile.equals(adminProfileName) || tempProfile.equals(dealerAdminProfileName)) {
            isAdmin = true;
        } else if (pos == 'RSD' && (tempProfile.equals(fsdProfileName) || tempProfile.equals(fsdProfileNameMFA))) {
            isFSD = true;
        } else if (tempProfile.equals(salesRepProfileName) || tempProfile.equals(salesRepProfileNameMFA)) {
            isSalesRep = true;
        } else if (tempProfile.equals(salesSupportProfileName)) {
            isSalesSupport = true;
        }

        if (isAdmin) {
            fsdOptions.addAll(getUserOptionsByProfileId(u.ProfileId));
        } else if (isFSD) {
            fsdOptions.add(new SelectOption(UserInfo.getUserId(), UserInfo.getUserName()));
        }

        /*
        for (String profileId : profileIdMap.keySet()) {
            String tempProfile = profileIdMap.get(profileId).Name;
            if(UserInfo.getProfileId().equals(profileId)){
                if(tempProfile.equals(adminProfileName) || tempProfile.equals(dealerAdminProfileName)){
                    isAdmin = true;
                }else if(pos=='RSD' && ( tempProfile.equals(fsdProfileName) || tempProfile.equals(fsdProfileNameMFA) ) ){
                    isFSD = true;
                }else if(tempProfile.equals(salesRepProfileName) || tempProfile.equals(salesRepProfileNameMFA)){
                    isSalesRep = true;
                }else if(tempProfile.equals(salesSupportProfileName)){
                    isSalesSupport = true;
                }               
                break;
            }               
        } */
        /*
        for (String profileId : profileIdMap.keySet()) {
            String tempProfile = profileIdMap.get(profileId).Name;
            //if(tempProfile.equals(fsdProfileName)){
            if(tempProfile.equals(fsdProfileName) || tempProfile.equals(salesSupportProfileName)){
                if(isAdmin){
                    // fsdOptions = getUserOptionsByProfileId(profileId);
                    fsdOptions.addAll(getUserOptionsByProfileId(profileId));
                }else if(isFSD){
                    //fsdOptions = new List<SelectOption>();
                    fsdOptions.add(new SelectOption(UserInfo.getUserId(),UserInfo.getUserName()));
                }
            }
         }
        */
    }

    /* @RemoteAction
    public static SharedModels.ResultMessage getOrdersByEventId(Id eventID){
        SharedModels.ResultMessage result = new SharedModels.ResultMessage();
        List<OrderingModels.OrderAndAccountModel > orders = new List<OrderingModels.OrderAndAccountModel >();
        try{        
            for(Order ordr:[Select   Id, Ordering_Event__r.Name, OrderNumber, Ordering_Event_Account__r.Account__r.Region_Future__c, Ordering_Event_Account__r.Account__r.Territory_Future__c, Ordering_Event_Account__r.Account__r.Salesperson_Type_Future__c, Ordering_Event_Account__r.Account__r.Entity_ID__c,Ordering_Event_Account__r.Account__r.Name, Ship_To__r.Name, Ship_To__r.City__c, Ship_To__r.State__c, Status,TotalAmount,Freight_Amount__c,Grand_Total__c 
                        From    Order  
                        Where   Ordering_Event__c =:eventID ]){
                    orders.add(new OrderingModels.OrderAndAccountModel(ordr));          
            } 
            result.payloadMap.put('orderRecords', orders);
        }catch(Exception e){
            result.setError(e);
        }
                
        return result ;
    }*/

    //public class CustomOrderFilterException extends Exception{}

    @RemoteAction
    public static SharedModels.ResultMessage getOrdersByRequest(OrderFilterRequest request) {
        SharedModels.ResultMessage result = new SharedModels.ResultMessage();
        List<OrderingModels.OrderAndAccountModel> orders = new List<OrderingModels.OrderAndAccountModel>();
        //try{   --removed 3/12 cause its really stupid
        List<User> profileUsers = getUserByProfileName(salesRepProfileName);

        Map<Decimal, String> futurTrrtyUserMap = new Map<Decimal, String>();

        for (User tmp : profileUsers) {
            futurTrrtyUserMap.put(tmp.Territory_Future__c, tmp.Name);
        }
        OrderingModels.OrderAndAccountModel tmpModel = null;
        Decimal totalAmount = 0.0;
        if (request.userType.equals('SRep')) {
            //|| request.userType.equals('SRep')
            Id userID = Userinfo.getuserid();

            for (Order ordr : [
                SELECT
                    recordTypeId,
                    Ordering_Event__r.Territory_Alignment__c,
                    Owner.name,
                    Id,
                    Ordering_Event__r.Name,
                    OrderNumber,
                    Ordering_Event_Account__r.Account__r.Region_Future__c,
                    Ordering_Event_Account__r.Account__r.Region_Current__c,
                    Ordering_Event_Account__r.Account__r.Territory_Current__c,
                    Ordering_Event_Account__r.Account__r.Territory_Future__c,
                    Ordering_Event_Account__r.Account__r.Salesperson_Type_Future__c,
                    Ordering_Event_Account__r.Account__r.Entity_ID__c,
                    Ordering_Event_Account__r.Account__r.Name,
                    Ship_To__r.Name,
                    Ship_To__r.City__c,
                    Ship_To__r.State__c,
                    Status,
                    TotalAmount,
                    Freight_Amount__c,
                    Grand_Total__c
                FROM Order
                WHERE Ordering_Event__c = :request.eventID AND OwnerId = :userID
            ]) {
                //orders.add(new OrderingModels.OrderAndAccountModel(ordr));
                tmpModel = new OrderingModels.OrderAndAccountModel(ordr);
                //tmpModel.salesPersonTypeFuture = futurTrrtyUserMap.get(ordr.Ordering_Event_Account__r.Account__r.Territory_Future__c);
                orders.add(tmpModel);
                totalAmount = totalAmount + ordr.Grand_Total__c;
                System.debug('Sundog - ordr.Grand_Total__c : ' + ordr.Grand_Total__c);
            }
        } else if (
            request.userType.equals('SSupport') ||
            (request.userType.equals('RSD') && String.isBlank(request.repId)) ||
            (request.userType.equals('Admin') &&
            String.isBlank(request.fsdId) &&
            String.isBlank(request.repId))
        ) {
            system.debug('DUNK-----testA:' + request.eventID);

            for (Order ordr : [
                SELECT
                    recordTypeId,
                    Ordering_Event__r.Territory_Alignment__c,
                    Owner.name,
                    Id,
                    Ordering_Event__r.Name,
                    OrderNumber,
                    Ordering_Event_Account__r.Account__r.Region_Future__c,
                    Ordering_Event_Account__r.Account__r.Region_Current__c,
                    Ordering_Event_Account__r.Account__r.Territory_Current__c,
                    Ordering_Event_Account__r.Account__r.Territory_Future__c,
                    Ordering_Event_Account__r.Account__r.Salesperson_Type_Future__c,
                    Ordering_Event_Account__r.Account__r.Entity_ID__c,
                    Ordering_Event_Account__r.Account__r.Name,
                    Ship_To__r.Name,
                    Ship_To__r.City__c,
                    Ship_To__r.State__c,
                    Status,
                    TotalAmount,
                    Freight_Amount__c,
                    Grand_Total__c
                FROM Order
                WHERE Ordering_Event__c = :request.eventID
            ]) {
                //orders.add(new OrderingModels.OrderAndAccountModel(ordr));
                tmpModel = new OrderingModels.OrderAndAccountModel(ordr);
                //tmpModel.salesPersonTypeFuture = futurTrrtyUserMap.get(ordr.Ordering_Event_Account__r.Account__r.Territory_Future__c);
                orders.add(tmpModel);
                totalAmount = totalAmount + ordr.Grand_Total__c;
                System.debug('Sundog - ordr.Grand_Total__c : ' + ordr.Grand_Total__c);
            }
        } else if (((request.userType.equals('RSD') && !String.isBlank(request.repId)) || (request.userType.equals('Admin') && !String.isBlank(request.repId)))) {
            //admin + HAS repID
            system.debug('DUNK-----testB:' + request.repID);
            //User rep = [SELECT Id, Name, Region_Future__c,Territory_Future__c FROM User where IsActive = true and Id=:request.repId];
            for (Order ordr : [
                SELECT
                    recordTypeId,
                    Ordering_Event__r.Territory_Alignment__c,
                    Owner.name,
                    Id,
                    Ordering_Event__r.Name,
                    OrderNumber,
                    Ordering_Event_Account__r.Account__r.Region_Future__c,
                    Ordering_Event_Account__r.Account__r.Region_Current__c,
                    Ordering_Event_Account__r.Account__r.Territory_Current__c,
                    Ordering_Event_Account__r.Account__r.Territory_Future__c,
                    Ordering_Event_Account__r.Account__r.Salesperson_Type_Future__c,
                    Ordering_Event_Account__r.Account__r.Entity_ID__c,
                    Ordering_Event_Account__r.Account__r.Name,
                    Ship_To__r.Name,
                    Ship_To__r.City__c,
                    Ship_To__r.State__c,
                    Status,
                    TotalAmount,
                    Freight_Amount__c,
                    Grand_Total__c
                FROM Order
                //   Where   Ordering_Event__c =:request.eventID and Ordering_Event_Account__r.Account__r.Territory_Future__c = :rep.Territory_Future__c]){
                WHERE Ordering_Event__c = :request.eventID AND OwnerId = :request.repId
            ]) {
                //orders.add(new OrderingModels.OrderAndAccountModel(ordr));
                tmpModel = new OrderingModels.OrderAndAccountModel(ordr);
                //tmpModel.salesPersonTypeFuture = futurTrrtyUserMap.get(ordr.Ordering_Event_Account__r.Account__r.Territory_Future__c);
                orders.add(tmpModel);
                totalAmount = totalAmount + ordr.Grand_Total__c;
            }
        } else if (request.userType.equals('Admin') && (String.isBlank(request.repId) && !String.isBlank(request.fsdId))) {
            //admin + no repID + HAS FSID
            system.debug('DUNK-----testC:' + request.eventID);
            User fsd = [SELECT Id, Name, Region_Future__c, Region_Current__c, Territory_Future__c, Territory_Current__c FROM User WHERE IsActive = TRUE AND Id = :request.fsdId];
            Ordering_Event__c event = [SELECT Id, Territory_Alignment__c FROM Ordering_Event__c WHERE Id = :request.eventID];

            List<Order> ordrs = null;
            if (event.Territory_Alignment__c != null && event.Territory_Alignment__c.equals('Future')) {
                ordrs = [
                    SELECT
                        recordTypeId,
                        Ordering_Event__r.Territory_Alignment__c,
                        Owner.name,
                        Id,
                        Ordering_Event__r.Name,
                        OrderNumber,
                        Ordering_Event_Account__r.Account__r.Region_Future__c,
                        Ordering_Event_Account__r.Account__r.Region_Current__c,
                        Ordering_Event_Account__r.Account__r.Territory_Current__c,
                        Ordering_Event_Account__r.Account__r.Territory_Future__c,
                        Ordering_Event_Account__r.Account__r.Salesperson_Type_Future__c,
                        Ordering_Event_Account__r.Account__r.Entity_ID__c,
                        Ordering_Event_Account__r.Account__r.Name,
                        Ship_To__r.Name,
                        Ship_To__r.City__c,
                        Ship_To__r.State__c,
                        Status,
                        TotalAmount,
                        Freight_Amount__c,
                        Grand_Total__c
                    FROM Order
                    WHERE Ordering_Event__c = :request.eventID AND Ordering_Event_Account__r.Account__r.Region_Future__c = :fsd.Region_Future__c
                ];
            } else {
                ordrs = [
                    SELECT
                        recordTypeId,
                        Ordering_Event__r.Territory_Alignment__c,
                        Owner.name,
                        Id,
                        Ordering_Event__r.Name,
                        OrderNumber,
                        Ordering_Event_Account__r.Account__r.Region_Future__c,
                        Ordering_Event_Account__r.Account__r.Region_Current__c,
                        Ordering_Event_Account__r.Account__r.Territory_Current__c,
                        Ordering_Event_Account__r.Account__r.Territory_Future__c,
                        Ordering_Event_Account__r.Account__r.Salesperson_Type_Future__c,
                        Ordering_Event_Account__r.Account__r.Entity_ID__c,
                        Ordering_Event_Account__r.Account__r.Name,
                        Ship_To__r.Name,
                        Ship_To__r.City__c,
                        Ship_To__r.State__c,
                        Status,
                        TotalAmount,
                        Freight_Amount__c,
                        Grand_Total__c
                    FROM Order
                    WHERE Ordering_Event__c = :request.eventID AND Ordering_Event_Account__r.Account__r.Region_Current__c = :fsd.Region_Current__c
                ];
            }
            for (Order ordr : ordrs) {
                //orders.add(new OrderingModels.OrderAndAccountModel(ordr));
                tmpModel = new OrderingModels.OrderAndAccountModel(ordr);
                //tmpModel.salesPersonTypeFuture = futurTrrtyUserMap.get(ordr.Ordering_Event_Account__r.Account__r.Territory_Future__c);
                orders.add(tmpModel);
                totalAmount = totalAmount + ordr.Grand_Total__c;
            }
        }
        String grandTotalFormatted = SharedHelpers.formatCurrency(totalAmount);
        result.payloadMap.put('orderRecords', orders);
        result.payloadMap.put('grandTotalFormatted', grandTotalFormatted);
        /*}catch(Exception e){
            result.setError(e);
//todo system log the errors
        }*/

        return result;
    }

    @RemoteAction
    public static SharedModels.ResultMessage getEventsByEventType(String eventType) {
        List<SelectOption> eventOptions = new List<SelectOption>();
        List<CustomSelectOption> eventSlctOptions = new List<CustomSelectOption>();
        SharedModels.ResultMessage result = new SharedModels.ResultMessage();
        Id eventRecTypeId = null;

        try {
            if (eventType.equals('PreSeason')) {
                eventRecTypeId = RecordTypes.orderingEvent_PreSeason.Id;
            } else if (eventType.equals('PreSeasonFallWinter')) {
                eventRecTypeId = RecordTypes.orderingEvent_PreSeasonFallWinter.Id;
            } else if (eventType.equals('InSeason')) {
                eventRecTypeId = RecordTypes.orderingEvent_InSeason.Id;
            } else if (eventType.equals('Promotion')) {
                eventRecTypeId = RecordTypes.orderingEvent_Promotion.Id;
            }

            eventOptions = getEventsByEventRecTypeId(eventRecTypeId);
            for (SelectOption option : eventOptions) {
                eventSlctOptions.add(new CustomSelectOption(option));
            }
            result.payloadMap.put('eventOptions', eventSlctOptions);
        } catch (Exception e) {
            result.setError(e);
        }

        return result;
    }

    @RemoteAction
    public static SharedModels.ResultMessage getSalesRepsByFSDId(String fsdId) {
        List<CustomSelectOption> salesRepSlctOptions = new List<CustomSelectOption>();
        SharedModels.ResultMessage result = new SharedModels.ResultMessage();
        Id eventRecTypeId = null;

        try {
            User fsd = [SELECT Id, Name, Region_Future__c FROM User WHERE IsActive = TRUE AND Id = :fsdId];
            System.debug('Sundog - fsd :' + fsd);
            if (fsd.Region_Future__c != null) {
                salesRepSlctOptions = getUserOptionsByProfileNameAndFutureRegion(salesRepProfileName, fsd.Region_Future__c);
            } else {
                salesRepSlctOptions = getUserOptionsByProfileName(salesRepProfileName);
            }

            result.payloadMap.put('salesRepSlctOptions', salesRepSlctOptions);
        } catch (Exception e) {
            result.setError(e);
        }

        return result;
    }

    private static List<SelectOption> getEventsByEventRecTypeId(Id eventRecTypeId) {
        List<SelectOption> eventOptions = new List<SelectOption>();
        if (eventRecTypeId != null) {
            for (Ordering_Event__c e : [SELECT Id, Name FROM Ordering_Event__c WHERE Is_Active__c = TRUE AND RecordTypeId = :eventRecTypeId ORDER BY Name ASC]) {
                eventOptions.add(new SelectOption(e.Id, e.Name));
            }
        }

        return eventOptions;
    }

    private static List<SelectOption> getUserOptionsByProfileId(Id profileId) {
        List<SelectOption> userOptions = new List<SelectOption>();

        if (profileId != null) {
            for (User u : [SELECT Id, Name FROM User WHERE IsActive = TRUE AND Profile.Id = :profileId ORDER BY Name ASC]) {
                userOptions.add(new SelectOption(u.Id, u.Name));
            }
        }

        return userOptions;
    }

    private static List<User> getUserByProfileName(String profileName) {
        List<User> profileUsers = new List<User>();

        if (profileName != null) {
            Set<String> profiles = new Set<String>{ profileName };
            // mburr.2022-07-08 add MFA version of the profiles
            if (profileName == fsdProfileName)
                profiles.add(fsdProfileNameMFA);
            if (profileName == salesRepProfileName)
                profiles.add(salesRepProfileNameMFA);

            //query SF Users
            profileUsers = [SELECT Id, Name, Territory_Future__c FROM User WHERE IsActive = TRUE AND Profile.Name IN :profiles ORDER BY Name ASC];
        }

        return profileUsers;
    }

    private static List<CustomSelectOption> getUserOptionsByProfileNameAndFutureRegion(String profileName, Decimal region) {
        List<CustomSelectOption> userOptions = new List<CustomSelectOption>();

        if (profileName != null) {
            Set<String> profiles = new Set<String>{ profileName };
            // mburr.2022-07-08 add MFA version of the profiles (bandaid until SFDC's OOB Mobile CRM App supports MFA)
            if (profileName == fsdProfileName)
                profiles.add(fsdProfileNameMFA);
            if (profileName == salesRepProfileName)
                profiles.add(salesRepProfileNameMFA);

            //query SF Users
            for (User u : [SELECT Id, Name, Territory_Future__c FROM User WHERE IsActive = TRUE AND Profile.Name IN :profiles AND Region_Future__c = :region ORDER BY Name ASC]) {
                userOptions.add(new CustomSelectOption(u.Id, u.Name + ' (' + u.Territory_Future__c + ')'));
            }
        }

        return userOptions;
    }
    private static List<CustomSelectOption> getUserOptionsByProfileName(String profileName) {
        List<CustomSelectOption> userOptions = new List<CustomSelectOption>();

        if (profileName != null) {
            for (User u : getUserByProfileName(profileName)) {
                userOptions.add(new CustomSelectOption(u.Id, u.Name + ' (' + u.Territory_Future__c + ')'));
            }
        }

        return userOptions;
    }

    private static Map<Id, Profile> getAllProfiles() {
        Map<Id, Profile> profileIdMap = new Map<Id, Profile>([SELECT Id, Name FROM Profile]);
        return profileIdMap;
    }

    class CustomSelectOption {
        String Id { get; set; }
        String Name { get; set; }

        public CustomSelectOption(SelectOption slctOption) {
            this.Id = slctOption.getValue();
            this.Name = slctOption.getLabel();
        }

        public CustomSelectOption(String value, String label) {
            this.Id = value;
            this.Name = label;
        }
    }

    @TestVisible
    class OrderFilterRequest {
        String eventId { get; set; }
        String fsdId { get; set; }
        String repId { get; set; }
        String userType { get; set; }
        String eventType { get; set; }

        public OrderFilterRequest(String eId, String fId, String rId, String uType, String eType) {
            this.eventId = eId;
            this.fsdId = fId;
            this.repId = rId;
            this.userType = uType;
            this.eventType = eType;
        }
    }
}
