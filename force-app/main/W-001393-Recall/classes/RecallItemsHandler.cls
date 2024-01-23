public with sharing class RecallItemsHandler {
    public static String env = 'sandbox';
    public static String recallIdStatic;
    public static Recall__c recall;

    public static List<Recall_Item__c> getRecallItems(Id recallId) {
        return [
            SELECT Id, Serial_Number__c, Model__c, Dealer_Entity_Id__c, Recall__c, Recall_Account__c, Recall_Model__c
            FROM Recall_Item__c
            WHERE Recall__c = :recallId AND (Recall_Account__c = NULL OR Recall_Model__c = NULL)
        ];
    }

    public static Map<String, List<Recall_Item__c>> getDealerRecallItemMap(Recall_Item__c[] recallItems) {
        Map<String, List<Recall_Item__c>> recallItemDealerMap = new Map<String, List<Recall_Item__c>>();
        for (Recall_Item__c recallItem : recallItems) {
            if (recallItemDealerMap.get(recallItem.Dealer_Entity_Id__c) == null) {
                recallItemDealerMap.put(recallItem.Dealer_Entity_Id__c, new List<Recall_Item__c>());
            }
            recallItemDealerMap.get(recallItem.Dealer_Entity_Id__c).add(recallItem);
        }
        return recallItemDealerMap;
    }

    public static void createMissingRecallAccounts(Map<String, List<Recall_Item__c>> recallItemDealerMap) {
        List<Recall_Account__c> recallAccs = [SELECT Id, Account__c FROM Recall_Account__c WHERE Recall__c = :recall.Id];
        Set<Id> existingRecallAccIds = new Set<Id>();
        for (Recall_Account__c recallAcc : recallAccs) {
            existingRecallAccIds.add(recallAcc.Account__c);
        }
        // Create Recall Accounts
        List<Account> accs = [
            SELECT Id, Name, Entity_Id__c, BillingCity, BillingState
            FROM Account
            WHERE Entity_Id__c IN :recallItemDealerMap.keyset() AND Id NOT IN :existingRecallAccIds
        ];
        Map<String, Account> missingAccsDealerMap = new Map<String, Account>();
        for (Account acc : accs) {
            missingAccsDealerMap.put(acc.Entity_Id__c, acc);
        }

        List<Recall_Account__c> newRecallAccs = new List<Recall_Account__c>();
        for (String entityId : recallItemDealerMap.keySet()) {
            Account dealer = missingAccsDealerMap.get(entityId);
            if (dealer != null) {
                newRecallAccs.add(
                    new Recall_Account__c(
                        Name = recall.Name + ' ' + entityId + ' ' + dealer.Name + ' ' + dealer.BillingCity + ' ' + dealer.BillingState,
                        Recall__c = recall.Id,
                        Account__c = dealer.Id
                    )
                );
            }
        }
        if (newRecallAccs.size() > 0)
            insert newRecallAccs;
    }

    public static void relateRecallItemsWithAccount(Map<String, List<Recall_Item__c>> recallItemDealerMap) {
        List<Recall_Item__c> recallItemsToUpdate = new List<Recall_Item__c>();
        List<Recall_Account__c> recallAccs = [SELECT Id, Entity_ID__c FROM Recall_Account__c WHERE Recall__c = :recall.Id];
        Map<String, Recall_Account__c> recallAccEnityIdMap = new Map<String, Recall_Account__c>();

        for (Recall_Account__c recallAcc : recallAccs) {
            recallAccEnityIdMap.put(recallAcc.Entity_ID__c, recallAcc);
        }

        for (String entityId : recallItemDealerMap.keySet()) {
            List<Recall_Item__c> recallItems = recallItemDealerMap.get(entityId);
            Recall_Account__c recallAcc = recallAccEnityIdMap.get(entityId);

            for (Recall_Item__c recallItem : recallItems) {
                recallItem.Recall_Account__c = recallAcc.Id;
                recallItemsToUpdate.add(recallItem);
            }
        }

        update recallItemsToUpdate;
    }

    public static void createMissingDealerAccounts(Map<String, List<Recall_Item__c>> recallItemDealerMap) {
        List<Account> accs = [SELECT Id, Entity_Id__c FROM Account WHERE Entity_Id__c IN :recallItemDealerMap.keyset()];
        Map<String, Account> existingAccsDealerMap = new Map<String, Account>();
        Set<String> missingDealers = new Set<String>();
        for (Account acc : accs) {
            existingAccsDealerMap.put(acc.Entity_Id__c, acc);
        }

        for (String entityId : recallItemDealerMap.keySet()) {
            if (!existingAccsDealerMap.keySet().contains(entityId)) {
                missingDealers.add(entityId);
            }
        }

        //Find missing dealers
        if (missingDealers.size() > 0) {
            if (env == 'sandbox') {
                List<Account> newDealers = new List<Account>();
                for (String entityId : missingDealers) {
                    newDealers.add(new Account(Entity_Id__c = entityId, Name = entityId, recordTypeId = '012A00000019hfHIAQ'));
                }
                insert newDealers;
            } else {
                throw new CustomException('There are dealers not exists in the system' + missingDealers.toString());
            }
        }
    }

    public static void createMissingRecallModels() {
        List<Recall_Account__c> recallAccs = [
            SELECT Id, (SELECT Id, Model__c, Recall_Model__c FROM Recall_Items__r), (SELECT Id, Factory_Model_Number__c FROM Recall_Models__r)
            FROM Recall_Account__c
            WHERE Recall__c = :recall.Id
        ];

        List<Recall_Model__c> newRecallModels = new List<Recall_Model__c>();

        for (Recall_Account__c recallAcc : recallAccs) {
            Set<String> existingModels = new Set<String>();
            for (Recall_Model__c recalModel : recallAcc.Recall_Models__r) {
                existingModels.add(recalModel.Factory_Model_Number__c);
            }

            for (Recall_Item__c recallItem : recallAcc.Recall_Items__r) {
                if (!existingModels.contains(recallItem.Model__c)) {
                    newRecallModels.add(new Recall_Model__c(Recall_Account__c = recallAcc.Id, Factory_Model_Number__c = recallItem.Model__c, Recall__c = recall.Id));
                    existingModels.add(recallItem.Model__c);
                }
            }
        }

        if (newRecallModels.size() > 0)
            insert newRecallModels;
    }

    public static void relateRecallItemsWithgRecallModels() {
        List<Recall_Item__c> recallItemsUpdate = new List<Recall_Item__c>();

        List<Recall_Account__c> recallAccs = [
            SELECT Id, (SELECT Id, Model__c, Recall_Model__c, Serial_Number__c FROM Recall_Items__r), (SELECT Id, Factory_Model_Number__c FROM Recall_Models__r)
            FROM Recall_Account__c
            WHERE Recall__c = :recall.Id
        ];

        for (Recall_Account__c recallAcc : recallAccs) {
            Map<String, Recall_Model__c> recallModelsMap = new Map<String, Recall_Model__c>();
            for (Recall_Model__c recalModel : recallAcc.Recall_Models__r) {
                recallModelsMap.put(recalModel.Factory_Model_Number__c, recalModel);
            }
            for (Recall_Item__c recallItem : recallAcc.Recall_Items__r) {
                recallItem.Recall_Model__c = recallModelsMap.get(recallItem.Model__c).Id;
                recallItemsUpdate.add(recallItem);
            }
        }

        update recallItemsUpdate;
    }

    public static void sumupItemSerialNumbersonModel() {
        List<Recall_Model__c> recallModels = [
            SELECT Id, Item_Serial_Numbers__c, (SELECT Id, Serial_Number__c FROM Recall_Items__r ORDER BY Serial_Number__c)
            FROM Recall_Model__c
            WHERE Recall__c = :recall.Id
        ];
        for (Recall_Model__c recallModel : recallModels) {
            List<String> serialNumbers = new List<String>();
            for (Recall_Item__c recallItem : recallModel.Recall_Items__r) {
                serialNumbers.add(recallItem.Serial_Number__c);
            }
            recallModel.Item_Serial_Numbers__c = String.join(serialNumbers, ', ');
        }
        update recallModels;
    }

    public static void createRecallModels(String recallId) {
        recallIdStatic = recallId;
        recall = [SELECT Id, Name FROM Recall__c WHERE Id = :recallId];
        Recall_Item__c[] recallItems = getRecallItems(recallIdStatic);
        Map<String, List<Recall_Item__c>> recallItemDealerMap = getDealerRecallItemMap(recallItems);
        createMissingDealerAccounts(recallItemDealerMap);
        createMissingRecallAccounts(recallItemDealerMap);
        relateRecallItemsWithAccount(recallItemDealerMap);
        createMissingRecallModels();
        relateRecallItemsWithgRecallModels();
        sumupItemSerialNumbersonModel();
    }

    public class CustomException extends Exception {
    }
}
