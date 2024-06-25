public class ConsumerOrderTriggerHandler implements TriggerInterface {
    private static boolean caseCreateRan = false;
    
    public void beforeInsert(){
        processFieldsOnOrders(Trigger.new, null);
        processConsumerSend(Trigger.new, null);
    }
    public void beforeUpdate(){
        processFieldsOnOrders(Trigger.new, (Map<Id, Consumer_Order__c>)Trigger.oldMap);
        processFieldsOnOrderItems(Trigger.new);
        processConsumerSend(Trigger.new, (Map<Id, Consumer_Order__c>)Trigger.oldMap);
        processOrdersForCaseCreation(trigger.new, (Map<Id, Consumer_Order__c>)trigger.oldMap);
        addOrderSharing((Map<Id, Consumer_Order__c>)Trigger.oldMap, (Map<Id, Consumer_Order__c>)Trigger.newMap);
    }
    public void beforeDelete(){}
    public void afterInsert(){
        createDealershipMappings(Trigger.new);
        processOrdersForCaseCreation(trigger.new, (Map<Id, Consumer_Order__c>)trigger.oldMap);
        addOrderSharing(null, (Map<Id, Consumer_Order__c>)Trigger.newMap);
        updateOrderItems((Map<Id, Consumer_Order__c>)Trigger.newMap, null);
    }
    public void afterUpdate(){
        createDealershipMappings(Trigger.new);
        updateOrderItems((Map<Id, Consumer_Order__c>)Trigger.newMap, (Map<Id, Consumer_Order__c>)Trigger.oldMap);
    }
    public void afterDelete(){}

    public void finish(){}

    private void processFieldsOnOrders(List<Consumer_Order__c> orders, Map<Id, Consumer_Order__c> oldMap) {
        Set<Id> dealerAccountIds = new Set<Id>();
        Set<Id> consumerOrderIds = new Set<Id>();

        for (Consumer_Order__c o : orders) {
            dealerAccountIds.add(o.Dealer__c);
            consumerOrderIds.add(o.Id);
        }

        Map<Id, Account> dealerAccounts = OrderingDal.getAccountMapById(dealerAccountIds);
        
        for (Consumer_Order__c o : orders) {
            Id key = o.Dealer__c;

            if (dealerAccounts.containsKey(key)) {
                Account dealerAccount = dealerAccounts.get(key);
                if (dealerAccount.ParentId != null) {
                    //parent dealer will be null when Dealer__c is the parent already
                    o.Parent_Dealer__c = dealerAccount.ParentId;
                }
            }

            //set SLA start and end dates
            if (Trigger.size == 1 && o.RecordTypeId == RecordTypes.dfOrder_US.Id) { //not currently bulkified
                if (o.SLA_Accept_Start__c == null) {
                    o.SLA_Accept_Start__c = BusinessHoursBusiness.getSLAStartDate(ConsumerOrderHelper.getManagingDealerForOrder(o), o.Order_Date__c);
                }
                if (o.SLA_Accept_Deadline__c == null) {
                    o.SLA_Accept_Deadline__c = BusinessHoursBusiness.getSLAEndDate(ConsumerOrderHelper.getManagingDealerForOrder(o), o.Order_Date__c, 4);
                }
            }
        }
        
        if (oldMap != null) {
            List<Consumer_Order_Item__c> consumerOrderItems = [Select Id, Fulfillment_Inv_Request__c, Consumer_Order__c
                                                               From Consumer_Order_Item__c
                                                               where Consumer_Order__c = :consumerOrderIds];
            Map<Id, List<Consumer_Order_Item__c>> consumerOrderItemMapByOrderId = SharedHelpers.createMapFromListByForeignKey(consumerOrderItems, 'Consumer_Order__c');


            for (Consumer_Order__c o : orders) {
                Consumer_Order__c oldOrder = oldMap.get(o.Id);
                Boolean extendSLADeadLine = false;
                if (Trigger.size == 1) { //not currently bulkified
                    ConsumerOrderModels.ConsumerOrderTrackerWrapper tracker = ConsumerOrderBusiness.generateOrderTrackerValues(o.Id);
                    if (tracker.fulfillmentScheduled && o.Fulfillment_Scheduled_Date__c == null) {
                        o.Fulfillment_Scheduled_Date__c = Datetime.now();
                    }
                }

                //handle order status change actions
                if (o.Status__c == 'Accepted' && oldOrder.Status__c != 'Accepted') {
                    o.Accepted_Date__c = Datetime.now();
                    if(consumerOrderItemMapByOrderId.containsKey(o.Id)) {
                        List<Consumer_Order_Item__c> consumerOrderItemList = consumerOrderItemMapByOrderId.get(o.Id);
                        if (consumerOrderItemList.size() > 0) {
                            for (Consumer_Order_Item__c ci : consumerOrderItemList) {
                                if (ci.Fulfillment_Inv_Request__c == 'Drop Ship') {
                                    extendSLADeadLine = true;
                                }
                            }
                        }
                    }
                    if(o.RecordTypeId == RecordTypes.dfOrder_US.Id){
                        if(extendSLADeadLine){
                            o.SLA_Scheduled_Date_Entry_Deadline__c = BusinessHoursBusiness.getSLAEndDate(ConsumerOrderHelper.getManagingDealerForOrder(o), o.Accepted_Date__c, 48); //mburr.2020-10-18 should be 48 hours for drop-ship; okay to change to 4 TEMPORARILY for testing
                        } else {
                            o.SLA_Scheduled_Date_Entry_Deadline__c = BusinessHoursBusiness.getSLAEndDate(ConsumerOrderHelper.getManagingDealerForOrder(o), o.Accepted_Date__c, 16); //mburr.2020-10-18 should be 16 hours for in-stock;  okay to change to 4 TEMPORARILY for testing
                        }
                    }
                }

                if (o.Status__c == 'Delivered' && oldOrder.Status__c != 'Delivered') {
                    o.Delivery_Date__c = Datetime.now();
                }

                if (o.Status__c == 'Completed' && oldOrder.Status__c != 'Completed') {
                    o.Completed_Date__c = Datetime.now();
                }

                //MEF-309: remove delivery totals from cancelled orders MEF-341 to include Declined orders
                if ((o.Status__c == 'Cancelled' && oldOrder.Status__c != 'Cancelled') || (o.Status__c == 'Declined' && oldOrder.Status__c != 'Declined')) {
                    o.Order_Total__c = 0;
                    o.Delivery_Total__c = 0;
                }

                //handle triggered callouts
                if (o.Replace_Payment_Token__c && !oldOrder.Replace_Payment_Token__c  && o.RecordTypeId == RecordTypes.dfOrder_US.Id) {
                    replacePaymentToken(o.Id);
                }

                if (o.Attempt_Cancellation__c && !oldOrder.Attempt_Cancellation__c) {
                    cancelOrder(o.Id);
                }
            }
        }
    }

    @future(callout=true)
    private static void replacePaymentToken(Id orderId) {
        Consumer_Order__c o = [select Id, RecordTypeId, Order_Number__c, Replace_Payment_Token__c, Replace_Payment_Token_Failed__c, 
            Auth_Ref_Label__c, On_Hold__c from Consumer_Order__c where Id = :orderId];

        if(o.RecordTypeId == RecordTypes.dfOrder_US.Id){
            ConsumerOrderClientModels.ReplaceOrderPaymentTokenRequest request = new ConsumerOrderClientModels.ReplaceOrderPaymentTokenRequest();
            request.consumerOrderNumber = o.Order_Number__c;
            request.token = o.Auth_Ref_Label__c;
            String jsonResponse = ConsumerOrderClient.getReplaceCCTokenJson(request);

            //log response
            SystemLogHelper.insertSystemLog('ConsumerOrderService_v1', 'UpdateDFOrderStatusRequest', UserInfo.getUserName(), 'tokenExtensionIssue', jsonResponse);

            //process response
            ConsumerOrderClientModels.ReplaceOrderPaymentTokenResponse response = ConsumerOrderClient.convertReplaceCCTokenJsonToObject(jsonResponse);
            if (response.authorizationReplaced) {
                o.On_Hold__c = false;
                o.Auth_Ref_Label__c = response.token;
            } else {
                o.On_Hold__c = true;
                o.Replace_Payment_Token_Failed__c = true;
            }

            update o;
        }
    }

    @future(callout=true)
    private static void cancelOrder(Id orderId) {
        //we send null as the reason because internal UI has presaved values on order
        ConsumerOrderBusiness.cancelOrderAction(orderId, 'Cancelled', null, null);
    }

    private void processFieldsOnOrderItems(List<Consumer_Order__c> orders) {

        List<Consumer_Order_Item__c> cois = [select Id, Consumer_Order__c, Scheduled_Date__c from Consumer_Order_Item__c where Consumer_Order__c = :orders];
        Map<Id, List<Consumer_Order_Item__c>> orderItemMap = SharedHelpers.createMapFromListByForeignKey(cois, 'Consumer_Order__c');
        
        for (Consumer_Order__c o : orders) {
            Id key = o.Id;
            if (orderItemMap.containsKey(key)) {
                o.First_Scheduled_Delivery_Date__c = null;
                List<Consumer_Order_Item__c> orderItems = orderItemMap.get(key);
                o.First_Scheduled_Delivery_Date__c = null;

                for (Consumer_Order_Item__c coi : orderItems) {
                    //set the lowest delivery date on order from order items
                    if (coi.Scheduled_Date__c == null) {
                        continue;
                    }

                    if (o.First_Scheduled_Delivery_Date__c == null || coi.Scheduled_Date__c < o.First_Scheduled_Delivery_Date__c) {
                        o.First_Scheduled_Delivery_Date__c = coi.Scheduled_Date__c;
                    }
                }

            }
        }
    }

    private void createDealershipMappings(List<Consumer_Order__c> orders) {
        Map<Id, Id> contactToAccountIdMap = new Map<Id, Id>();
        Set<Id> consumerAccountIds = new Set<Id>();
        for (Consumer_Order__c o : orders) {
            consumerAccountIds.add(o.Consumer_Account__c);
        }

        Set<String> existingKeys = new Set<String>();
        for (Dealership_Mapping__c dm : [select Id, Dealership_Account__c, Consumer_Account__c from Dealership_Mapping__c where Consumer_Account__c = :consumerAccountIds]) {
            existingKeys.add(dm.Dealership_Account__c + '|' + dm.Consumer_Account__c);
        }

        List<Dealership_Mapping__c> toInsert = new List<Dealership_Mapping__c>();

        for (Consumer_Order__c o : orders) {
            if (o.Dealer__c == null) {
                continue;
            }
            if (consumerAccountIds.contains(o.Consumer_Account__c)) {
                Id accountId = o.Consumer_Account__c;
                String key = o.Dealer__c + '|' + accountId;
                if (!existingKeys.contains(key)) {
                    Dealership_Mapping__c dm = new Dealership_Mapping__c();
                    dm.Dealership_Account__c = o.Dealer__c;
                    dm.Consumer_Account__c = accountId;
                    toInsert.add(dm);
                } else {
                    System.debug('Dealership Mapping exists:' + key);
                }
            }
        }

        System.debug('toInsert:' + toInsert.size());
        insert toInsert;
    }

    private void processOrdersForCaseCreation(List<Consumer_Order__c> records, Map<Id, Consumer_Order__c> oldMap) {		//jreese 2021/5/20 added to replace functionality of BREeze rules
        if(!caseCreateRan) {
            caseCreateRan = true;
            
            Id contactId = null;
        
            Set<Id> accIds = new Set<Id>();
            for(Consumer_Order__c record : records) {
                accIds.add(record.Dealer__c);
            }
            Map<Id, User> userMap = new Map<Id, User>([SELECT ID, ContactId, Contact.AccountId 
                                                       FROM User 
                                                       WHERE ContactID IN (Select Id FROM Contact WHERE AccountId IN :accIds) AND isActive = true
                                                      ]);
            
            if(UserInfo.getProfileId() == Profiles.dealerCommunityUser.Id) {
                if(userMap.containsKey(UserInfo.getUserId())) {
                    contactId = userMap.get(UserInfo.getUserId()).contactId;
                }
                else {
        			contactId = [Select u.ContactId from User u where u.Id = :UserInfo.getUserId()][0].contactId;
                }
        	}
                    
            List<PermissionSetAssignment> pSets =	[SELECT AssigneeId, Id, PermissionSetId 
                                                     FROM PermissionSetAssignment 
                                                    WHERE PermissionSetId IN (SELECT Id FROM PermissionSet Where Name = 'IR_USA_DLR_ADD_eDealer_Program')
                                                    AND AssigneeId IN :userMap.keySet()
                                                    ];
            
            Map<Id, Id> accountIdToContactIdMap = new Map<Id, Id>();		//	Maps each Dealer(Account) Id to an active contact with the DF PermissionSet
            for(PermissionSetAssignment pSet : pSets) {
                User currentUser = userMap.get(pSet.AssigneeId);
                
                if(currentUser != null && currentUser.Contact != null && currentUser.Contact.AccountId != null) {
                    //	If the Dealer does not already have a contact mapped to it: add Dealer Id and the current Users' ContactId to map
                    if(!accountIdToContactIdMap.containsKey(currentUser.Contact.AccountId)) {
                        accountIdToContactIdMap.put(currentUser.Contact.AccountId, currentUser.ContactId);
                    }
                }
                if(accountIdToContactIdMap.keySet().Size() == records.Size()) {					//	TODO - MJ doesn't feel good about this
                    break;
                }
            }
                
            System.debug('xxx records: ' + records);
            List<Case> casesToInsert = new List<Case>();
            
            for(Consumer_Order__c currentOrder : records) {
                String subject = '';
                Consumer_Order__c oldOrder = (oldMap != null ? oldMap.get(currentOrder.ID) : null);
                
                subject = determineSubject(currentOrder, oldOrder);
                
                Case caseToInsert = new Case();
                if(!String.isBlank(subject)) {
                    
                    caseToInsert = createCase(currentOrder, subject, contactId);
                    if(contactId == null) {
                        caseToInsert.contactId = accountIdToContactIdMap.get(caseToInsert.AccountId);
                    }
                    casesToInsert.add(caseToInsert);
                }
            }
            
            if(!casesToInsert.isEmpty())	{
                try	{
                    System.debug('xxx amount of cases: ' + casesToInsert.Size());
                    System.debug('xxx cases: ' + casesToInsert);
                    insert casesToInsert;
                }
                catch(Exception ex)	{
                    SystemLogHelper.insertSystemLog('ConsumerOrderTriggerHandler.processOrdersForCaseCreation', 'Error on Case insert', UserInfo.getUserName(), 'Error on Case insert', ex);
                }
            }
        }
    }
    
    private void addOrderSharing(Map<Id, Consumer_Order__c> oldMap, Map<Id, Consumer_Order__c> newMap){

        Map<String, Set<Id>> accountToOrders = new Map<String, Set<Id>>();
        Map<String, Set<Id>> accountToOrdersDelete = new Map<String, Set<Id>>();
        ENV__c env = ENV__c.getInstance();
        Boolean forceOrderSharing = env.Force_Order_Sharing__c;
        forceOrderSharing = true;

        for (Id oid: newMap.keySet()) {
            Consumer_Order__c newOrder = newMap.get(oid);

            if(oldMap == null){ //insert
                if(newOrder.Dealer__c != null){
                    //insert ordershare
                    if(accountToOrders.containsKey(newOrder.Dealer__c)){
                        accountToOrders.get(newOrder.Dealer__c).add(oid);
                    }else{
                        accountToOrders.put(newOrder.Dealer__c, new Set<Id>{oid});
                    }
                }
            }else{ //update
                Consumer_Order__c oldOrder = oldMap.get(oid);

                if(newOrder.Dealer__c != oldMap.get(oid).Dealer__c || forceOrderSharing){
                    //delete ordershare
                    if(accountToOrdersDelete.containsKey(oldMap.get(oid).Dealer__c)){
                        accountToOrdersDelete.get(oldMap.get(oid).Dealer__c).add(oid);
                    }else{
                        accountToOrdersDelete.put(oldMap.get(oid).Dealer__c, new Set<Id>{oid});
                    }
                    //insert ordershare
                    if(accountToOrders.containsKey(newOrder.Dealer__c)){
                        accountToOrders.get(newOrder.Dealer__c).add(oid);
                    }else{
                        accountToOrders.put(newOrder.Dealer__c, new Set<Id>{oid});
                    }
                }
            }
        }
        if(accountToOrders.isEmpty() && accountToOrdersDelete.isEmpty()){
            return;
        }
        //deletes existing shares for everything in accountToOrders
        Map<String, Set<Id>> groupNameToOrders = new Map<String, Set<Id>>();
        Map<String, Set<Id>> groupNameToOrdersDelete = new Map<String, Set<Id>>();
        for(Account a: [Select Id, Entity_Id__c From Account Where Id IN :accountToOrders.keySet() OR Id IN :accountToOrdersDelete.keySet()]){
            if(accountToOrders.containsKey(a.Id)){
                groupNameToOrders.put('EID_'+a.Entity_ID__c, accountToOrders.get(a.Id));
            }
            if(accountToOrdersDelete.containsKey(a.Id)){
                groupNameToOrdersDelete.put('EID_'+a.Entity_ID__c, accountToOrdersDelete.get(a.Id));
            }
        }

        //deletes shares for everything in accountToOrders
        List<Consumer_Order__Share> orderSharesToInsert = new List<Consumer_Order__Share>();
        List<Consumer_Order__Share> orderSharesToDelete = new List<Consumer_Order__Share>();
        Map<Id, Id> orderToGroup = new Map<Id, Id>();
        for(Group g: [Select Id, DeveloperName From Group Where DeveloperName IN :groupNameToOrders.keySet() OR DeveloperName IN: groupNameToOrdersDelete.keySet()]){
            System.debug('GROUP: '+g);
            if(groupNameToOrders.containsKey(g.DeveloperName)){
                for(Id oid: groupNameToOrders.get(g.DeveloperName)){
                    Consumer_Order__Share os = new Consumer_Order__Share(UserOrGroupId = g.Id, ParentId = oid, AccessLevel = 'Edit');
                    orderSharesToInsert.add(os);
                }
            }
            if(groupNameToOrdersDelete.containsKey(g.DeveloperName)){
                for(Id oid: groupNameToOrdersDelete.get(g.DeveloperName)){
                    orderToGroup.put(oid, g.Id);
                }
            }
        }

        for(Consumer_Order__Share os: [Select Id, UserOrGroupId, ParentId From Consumer_Order__Share Where RowCause = 'Manual' AND ParentId IN :orderToGroup.keySet()]){
            if(orderToGroup.get(os.ParentId) == os.UserOrGroupId){
                orderSharesToDelete.add(new Consumer_Order__Share(Id = os.Id));
            }
        }

        if(!orderSharesToDelete.isEmpty()){
            delete orderSharesToDelete;
        }
        if(!orderSharesToInsert.isEmpty()){
            insert orderSharesToInsert;
        }
    }

    private void updateOrderItems(Map<Id, Consumer_Order__c> newMap, Map<Id, Consumer_Order__c> oldMap){
        List<Consumer_Order__c> orders = newMap.values();

        Set<Id> qualifiedRecords = new Set<Id>();
        Set<Id> qualifiedOrdersAccepted = new Set<Id>();
        for (Consumer_Order__c o : orders) {
            if (oldMap == null) {
                qualifiedRecords.add(o.Id);
            } else {
                Consumer_Order__c oldOrder = oldMap.get(o.Id);

                //uses item before trigger to set order Consumer_Contact to item Consumer_Contact
                if (o.Consumer_Contact__c != oldOrder.Consumer_Contact__c) {
                    qualifiedRecords.add(o.Id);
                }

                if (o.Status__c == 'Accepted' && oldOrder.Status__c != 'Accepted') {
                    qualifiedOrdersAccepted.add(o.Id);
                }
            }
        }
        if (!qualifiedRecords.isEmpty()) {
            update [select Id from Consumer_Order_Item__c where Consumer_Order__c = :qualifiedRecords];
        }

        //when order becomes accepted, pass down SLA_Scheduled_Date_Entry_Deadline__c to items
        if (!qualifiedOrdersAccepted.isEmpty()) {
            List<Consumer_Order_Item__c> orderItemsToUpdate = [select Id, Consumer_Order__c, SLA_Scheduled_Date_Entry_Deadline__c 
                from Consumer_Order_Item__c where Consumer_Order__c = :qualifiedOrdersAccepted];

            for (Consumer_Order_Item__c coi : orderItemsToUpdate) {
                Consumer_Order__c co = newMap.get(coi.Consumer_Order__c);
                coi.SLA_Scheduled_Date_Entry_Deadline__c = co.SLA_Scheduled_Date_Entry_Deadline__c;
            }

            update orderItemsToUpdate;
        }
    }

    /* COnsumer Send when:
    New Order: when Trigger.isInsert and Status__c == 'New;
    Dealer Accepted: when Status__c changes to 'Accepted'
    Delivery is Scheduled: when Fulfillment_Scheduled_Date__c changes to not null
    24 Hour Email: MC_24_Hour_Triggered_Send__c set true by ConsumerOrderInvocable
    Closed 72 Hour Email: when Status__c changes to 'Closed' (immediate, MC waits 72 hours)
    Cancelled: trigger on order and line item: when Status__c changes to 'Cancelled'
    */
    private void processConsumerSend(List<Consumer_Order__c> orders, Map<Id, Consumer_Order__c> oldMap) {

        for (Consumer_Order__c o : orders) {
            if(o.RecordTypeId == RecordTypes.dfOrder_US.Id){
                if (Trigger.isInsert && o.Status__c == 'New') {
                    o.MC_New_Order__c = true;
                }

                System.debug('oldMap:' + oldMap);
                if (oldMap != null && oldMap.containsKey(o.Id)) {
                    Consumer_Order__c oldOrder = oldMap.get(o.Id);
                    if (o.Status__c == 'Accepted' && oldOrder.Status__c != 'Accepted') {
                        o.MC_Order_Accepted__c = true;
                    } else if (o.Fulfillment_Scheduled_Date__c != null && oldOrder.Fulfillment_Scheduled_Date__c == null) {
                        o.MC_Fulfillment_Scheduled__c = true;
                    } else if (o.Status__c == 'Closed' && oldOrder.Status__c != 'Closed') {
                        //o.MC_Order_Closed__c = true; //mburr.2023-07-11 visualflow will tell Medallia AppExchange Package to send the DF Order Closed Email (aka Happy Path)
                    } else if (o.Status__c == 'Cancelled' && oldOrder.Status__c != 'Cancelled') {
                        o.MC_Order_Cancelled__c = true;
                    }
                }
            }
        }
    }
    
    private Case createCase(Consumer_Order__c order, String subject, Id contactId) {
        Case newCase = new Case();
        
        newCase.consumer_order__c = order.Id;
        
        newCase.AccountId = order.Dealer__c;  //(order.Parent_Dealer__c != null ? order.Parent_Dealer__c : order.Dealer__c);
        
        newCase.contactId = contactId;
        
        newCase.Subject = subject;
        newCase.Status = 'New';
        newCase.Origin = 'Dealer Fulfillment';
        newCase.RecordTypeId = RecordTypes.case_DFUS.Id;
        newCase.OwnerId = '00GA0000004FRGi';							//	TODO Create class 'Queues' and pattern after RecordTypes.apxc
        
        return newCase;
    }
    
    private String determineSubject(Consumer_Order__c newOrder, Consumer_Order__c oldOrder) {
        String subject = '';
        
        if(newOrder.Extend_Process_initiated__c && (oldOrder == null || newOrder.Extend_Process_initiated__c != oldOrder.Extend_Process_initiated__c)) {
			subject = 'Extend Process Initiated';
        } else if(newOrder.Replace_Payment_Token_Failed__c && (oldOrder == null || newOrder.Replace_Payment_Token_Failed__c != oldOrder.Replace_Payment_Token_Failed__c)) {
			subject = 'Hold/Replace';
        } else if(newOrder.Status__c == 'Declined' && (oldOrder == null || newOrder.Status__c != oldOrder.Status__c)) {
			subject = 'Order Declined';
        } else if(newOrder.Status__c == 'Cancelled' && (oldOrder == null || newOrder.Status__c != oldOrder.Status__c)) {
			subject = 'Order Cancelled';
        } else if(newOrder.SLA_Accept_Violation__c && (oldOrder == null || newOrder.SLA_Accept_Violation__c != oldOrder.SLA_Accept_Violation__c)) {
			subject = 'SLA Violation';
        }
        
        return subject;
    }
}