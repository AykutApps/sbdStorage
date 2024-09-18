public with sharing class B2B_BuyerGroupAndEntitlementHelper {
    public static void adjustBuyerGroupMember(Set<Id> accountPricebookMappingIds) {
        // Step 1: Query and prepare data
        Map<String, Account_Pricebook_Mapping__c> externalKeyAPMMap = queryAccountPricebookMappings(accountPricebookMappingIds);
        Set<String> ampPriceboookExternalKeys = extractPricebookExternalKeys(externalKeyAPMMap);
        Map<String, BuyerGroup> externalKeyBuyerGroupMap = queryBuyerGroups(ampPriceboookExternalKeys);
        Map<String, BuyerGroupMember> existingBgmMap = queryExistingBuyerGroupMembers(externalKeyAPMMap);

        // Step 2: Process the mappings
        processMappings(externalKeyAPMMap, externalKeyBuyerGroupMap, existingBgmMap);
    }

    public static void adjustCommerceEntitlementBuyerGroup(Set<Id> pricebook2Ids) {
        // Step 1: Query and prepare data
        //query Pricebook2 with externalKey
        Map<String, Pricebook2> externalKeyPb2Map = queryPricebook2(pricebook2Ids);
        // existing CommerceEntitlementBuyerGroup
        Map<String, CommerceEntitlementBuyerGroup> existingExternalKeyCebgMap = queryExistingCommerceEntitlementBuyerGroup(externalKeyPb2Map);
        // query Buyer Groups with externalKey
        Map<String, BuyerGroup> externalKeyBuyerGroupMap = queryBuyerGroups(externalKeyPb2Map.keySet());
        // query Policies with externalKey
        Map<String, CommerceEntitlementPolicy> externalKeyPolicyMap = queryPolicies(externalKeyPb2Map.keySet());

        // Step 2: Process Pricebook2s
        processPricebook2s(externalKeyPb2Map, existingExternalKeyCebgMap, externalKeyBuyerGroupMap, externalKeyPolicyMap);
    }

    public static void adjustCommerceEntitlementProduct(Set<Id> pricebookEntryIds) {
        // Step 1: Query and prepare data
        //query Pricebook2 with externalKey
        Map<String, PricebookEntry> externalKeyPbeMap = queryPricebookEntries(pricebookEntryIds);
        // existing CommerceEntitlementProducts
        Map<String, CommerceEntitlementProduct> existingExternalKeyCepMap = queryExistingCommerceEntitlementProducts(externalKeyPbeMap);
        // get pricebook external key set
        Set<String> pricebookExternalKeys = extractPbExternalKeys(externalKeyPbeMap);
        // query Commerce Entitlement Policy with externalKey
        Map<String, CommerceEntitlementPolicy> externalKeyPolicyMap = queryPolicies(pricebookExternalKeys);

        system.debug('xxx-adjustCommerceEntitlementProduct');
        system.debug(externalKeyPbeMap);
        system.debug(existingExternalKeyCepMap);
        system.debug(externalKeyPolicyMap);

        // Step 2: Process Pricebook2s
        processPricebookEntries(externalKeyPbeMap, existingExternalKeyCepMap, externalKeyPolicyMap);
    }

    // helper methods ////////////////////////////////////////////////////////////////

    // Pricebook Entiries Methods
    private static Map<String, PricebookEntry> queryPricebookEntries(Set<Id> pricebookEntryIds) {
        Map<String, PricebookEntry> externalKeyPbeMap = new Map<String, PricebookEntry>();

        List<PricebookEntry> pbes = [
            SELECT Id, External_Key__c, ERP_Valid_From__c, ERP_Valid_To__c, Product2Id, Pricebook2.External_Key__c
            FROM PricebookEntry
            WHERE Id IN :pricebookEntryIds AND External_Key__c != NULL
        ];

        for (PricebookEntry pbe : pbes) {
            externalKeyPbeMap.put(pbe.External_Key__c, pbe);
        }

        return externalKeyPbeMap;
    }

    private static Map<String, CommerceEntitlementProduct> queryExistingCommerceEntitlementProducts(Map<String, PricebookEntry> externalKeyPbeMap) {
        Map<String, CommerceEntitlementProduct> existingCepgMap = new Map<String, CommerceEntitlementProduct>();

        if (!externalKeyPbeMap.isEmpty()) {
            List<CommerceEntitlementProduct> existingCeps = [
                SELECT Id, External_Key__c
                FROM CommerceEntitlementProduct
                WHERE External_Key__c IN :externalKeyPbeMap.keySet()
            ];
            for (CommerceEntitlementProduct cep : existingCeps) {
                existingCepgMap.put(cep.External_Key__c, cep);
            }
        }

        return existingCepgMap;
    }

    private static void processPricebookEntries(
        Map<String, PricebookEntry> externalKeyPbeMap,
        Map<String, CommerceEntitlementProduct> existingExternalKeyCepMap,
        Map<String, CommerceEntitlementPolicy> externalKeyPolicyMap
    ) {
        Date currentDate = B2B_GlobalVariables.asOf;
        List<CommerceEntitlementProduct> recordsToInsert = new List<CommerceEntitlementProduct>();
        List<CommerceEntitlementProduct> recordsToDelete = new List<CommerceEntitlementProduct>();

        for (String externalKey : externalKeyPbeMap.keySet()) {
            PricebookEntry pbe = externalKeyPbeMap.get(externalKey);
            if (pbe.ERP_Valid_From__c <= currentDate && currentDate <= pbe.ERP_Valid_To__c) {
                // Check if BuyerGroupMember exists
                if (!existingExternalKeyCepMap.containsKey(pbe.External_Key__c)) {
                    CommerceEntitlementPolicy policy = externalKeyPolicyMap.get(pbe.Pricebook2.External_Key__c);
                    if (policy == null) {
                        continue;
                    }

                    CommerceEntitlementProduct newCep = new CommerceEntitlementProduct(External_Key__c = pbe.External_Key__c, ProductId = pbe.Product2Id, PolicyId = policy.Id);
                    recordsToInsert.add(newCep);
                }
            } else if (currentDate > pbe.ERP_Valid_To__c) {
                // Check if BuyerGroupMember exists
                if (existingExternalKeyCepMap.containsKey(pbe.External_Key__c)) {
                    // Delete the existing BuyerGroupMember record
                    recordsToDelete.add(existingExternalKeyCepMap.get(pbe.External_Key__c));
                }
            }
        }

        // Perform DML operations outside the loop
        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }

        if (!recordsToDelete.isEmpty()) {
            delete recordsToDelete;
        }
    }

    private static Set<String> extractPbExternalKeys(Map<String, PricebookEntry> externalKeyPbeMap) {
        Set<String> pricebookExternalKeys = new Set<String>();
        for (PricebookEntry pbe : externalKeyPbeMap.values()) {
            pricebookExternalKeys.add(pbe.Pricebook2.External_Key__c);
        }

        return pricebookExternalKeys;
    }

    // Pricebook2 Methods
    @future
    public static void adjustCommerceEntitlementBuyerGroupFuture(Set<Id> pricebook2Ids) {
        adjustCommerceEntitlementBuyerGroup(pricebook2Ids);
    }

    private static Map<String, Pricebook2> queryPricebook2(Set<Id> pricebook2Ids) {
        Map<String, Pricebook2> externalKeyPb2Map = new Map<String, Pricebook2>();

        List<Pricebook2> pricebook2s = [
            SELECT Id, External_Key__c, CSP_Start_Date__c, CSP_End_Date__c
            FROM Pricebook2
            WHERE Id IN :pricebook2Ids AND External_Key__c != NULL
        ];

        for (Pricebook2 pb2 : pricebook2s) {
            externalKeyPb2Map.put(pb2.External_Key__c, pb2);
        }

        return externalKeyPb2Map;
    }

    private static Map<String, CommerceEntitlementBuyerGroup> queryExistingCommerceEntitlementBuyerGroup(Map<String, Pricebook2> externalKeyPb2Map) {
        Map<String, CommerceEntitlementBuyerGroup> existingCebgMap = new Map<String, CommerceEntitlementBuyerGroup>();

        if (!externalKeyPb2Map.isEmpty()) {
            List<CommerceEntitlementBuyerGroup> existingCebgs = [
                SELECT Id, External_Key__c
                FROM CommerceEntitlementBuyerGroup
                WHERE External_Key__c IN :externalKeyPb2Map.keySet()
            ];
            for (CommerceEntitlementBuyerGroup cebg : existingCebgs) {
                existingCebgMap.put(cebg.External_Key__c, cebg);
            }
        }

        return existingCebgMap;
    }

    private static Map<String, CommerceEntitlementPolicy> queryPolicies(Set<String> externalKeyPb2MapKeySet) {
        Map<String, CommerceEntitlementPolicy> externalKeyPolicyMap = new Map<String, CommerceEntitlementPolicy>();

        for (CommerceEntitlementPolicy pl : [
            SELECT Id, External_Key__c
            FROM CommerceEntitlementPolicy
            WHERE External_Key__c IN :externalKeyPb2MapKeySet
        ]) {
            externalKeyPolicyMap.put(pl.External_Key__c, pl);
        }

        return externalKeyPolicyMap;
    }

    private static void processPricebook2s(
        Map<String, Pricebook2> externalKeyPb2Map,
        Map<String, CommerceEntitlementBuyerGroup> existingExternalKeyCebgMap,
        Map<String, BuyerGroup> externalKeyBuyerGroupMap,
        Map<String, CommerceEntitlementPolicy> externalKeyPolicyMap
    ) {
        Date currentDate = B2B_GlobalVariables.asOf;
        List<CommerceEntitlementBuyerGroup> recordsToInsert = new List<CommerceEntitlementBuyerGroup>();
        List<CommerceEntitlementBuyerGroup> recordsToDelete = new List<CommerceEntitlementBuyerGroup>();

        for (String externalKey : externalKeyPb2Map.keySet()) {
            Pricebook2 pb2 = externalKeyPb2Map.get(externalKey);
            system.debug('xxx-CommerceEntitlementBuyerGroup ADJUSTMENT PB');
            system.debug(pb2);
            if (pb2.CSP_Start_Date__c <= currentDate && currentDate <= pb2.CSP_End_Date__c) {
                system.debug('xxx-CommerceEntitlementBuyerGroup IN IF ');
                // Check if BuyerGroupMember exists
                if (!existingExternalKeyCebgMap.containsKey(pb2.External_Key__c)) {
                    // Create new BuyerGroupMember record
                    BuyerGroup buyerGroup = externalKeyBuyerGroupMap.get(pb2.External_Key__c);
                    if (buyerGroup == null) {
                        continue;
                    }

                    CommerceEntitlementPolicy policy = externalKeyPolicyMap.get(pb2.External_Key__c);
                    if (policy == null) {
                        continue;
                    }

                    CommerceEntitlementBuyerGroup newCebg = new CommerceEntitlementBuyerGroup(
                        External_Key__c = pb2.External_Key__c,
                        BuyerGroupId = buyerGroup.Id,
                        PolicyId = policy.Id
                    );
                    system.debug('xxx-CommerceEntitlementBuyerGroup NEW newCebg');
                    system.debug(newCebg);
                    recordsToInsert.add(newCebg);
                }
            } else if (currentDate > pb2.CSP_End_Date__c) {
                // Check if BuyerGroupMember exists
                if (existingExternalKeyCebgMap.containsKey(pb2.External_Key__c)) {
                    // Delete the existing BuyerGroupMember record
                    recordsToDelete.add(existingExternalKeyCebgMap.get(pb2.External_Key__c));
                }
            }
        }

        // Perform DML operations outside the loop
        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }

        if (!recordsToDelete.isEmpty()) {
            delete recordsToDelete;
        }
    }

    // Account Price Book Methods
    @future
    public static void adjustBuyerGroupMemberFuture(Set<Id> accountPricebookMappingIds) {
        adjustBuyerGroupMember(accountPricebookMappingIds);
    }

    private static Map<String, Account_Pricebook_Mapping__c> queryAccountPricebookMappings(Set<Id> accountPricebookMappingIds) {
        Map<String, Account_Pricebook_Mapping__c> externalKeyAPMMap = new Map<String, Account_Pricebook_Mapping__c>();

        List<Account_Pricebook_Mapping__c> accountPricebookMappings = [
            SELECT Id, External_Key__c, ERP_Start_Date__c, ERP_End_Date__c, Account__c, Account__r.Entity_ID__c, Price_Book__r.External_Key__c, CSP_Start_Date__c, CSP_End_Date__c
            FROM Account_Pricebook_Mapping__c
            WHERE Id IN :accountPricebookMappingIds AND External_Key__c != NULL
        ];

        for (Account_Pricebook_Mapping__c apm : accountPricebookMappings) {
            externalKeyAPMMap.put(apm.External_Key__c, apm);
        }

        return externalKeyAPMMap;
    }

    private static Set<String> extractPricebookExternalKeys(Map<String, Account_Pricebook_Mapping__c> externalKeyAPMMap) {
        Set<String> ampPriceboookExternalKeys = new Set<String>();

        for (Account_Pricebook_Mapping__c apm : externalKeyAPMMap.values()) {
            if (!String.isBlank(apm.Price_Book__r?.External_Key__c)) {
                ampPriceboookExternalKeys.add(apm.Price_Book__r.External_Key__c);
            }
        }

        return ampPriceboookExternalKeys;
    }

    private static Map<String, BuyerGroup> queryBuyerGroups(Set<String> ampPriceboookExternalKeys) {
        Map<String, BuyerGroup> externalKeyBuyerGroupMap = new Map<String, BuyerGroup>();

        for (BuyerGroup bg : [
            SELECT Id, External_Key__c
            FROM BuyerGroup
            WHERE External_Key__c IN :ampPriceboookExternalKeys
        ]) {
            externalKeyBuyerGroupMap.put(bg.External_Key__c, bg);
        }

        return externalKeyBuyerGroupMap;
    }

    private static Map<String, BuyerGroupMember> queryExistingBuyerGroupMembers(Map<String, Account_Pricebook_Mapping__c> externalKeyAPMMap) {
        Map<String, BuyerGroupMember> existingBgmMap = new Map<String, BuyerGroupMember>();

        if (!externalKeyAPMMap.isEmpty()) {
            List<BuyerGroupMember> existingBgms = [
                SELECT Id, External_Key__c, BuyerGroupId, BuyerId
                FROM BuyerGroupMember
                WHERE External_Key__c IN :externalKeyAPMMap.keySet()
            ];
            for (BuyerGroupMember bgm : existingBgms) {
                existingBgmMap.put(bgm.External_Key__c, bgm);
            }
        }

        return existingBgmMap;
    }

    private static void processMappings(
        Map<String, Account_Pricebook_Mapping__c> externalKeyAPMMap,
        Map<String, BuyerGroup> externalKeyBuyerGroupMap,
        Map<String, BuyerGroupMember> existingBgmMap
    ) {
        Date currentDate = B2B_GlobalVariables.asOf;
        List<BuyerGroupMember> recordsToInsert = new List<BuyerGroupMember>();
        List<BuyerGroupMember> recordsToDelete = new List<BuyerGroupMember>();

        for (String externalKey : externalKeyAPMMap.keySet()) {
            Account_Pricebook_Mapping__c apm = externalKeyAPMMap.get(externalKey);
            // if (apm.ERP_Start_Date__c <= currentDate && currentDate <= apm.ERP_End_Date__c) {
            if (apm.CSP_Start_Date__c <= currentDate && currentDate <= apm.CSP_End_Date__c) {
                // Check if BuyerGroupMember exists
                if (!existingBgmMap.containsKey(apm.External_Key__c)) {
                    // Create new BuyerGroupMember record
                    BuyerGroup buyerGroup = externalKeyBuyerGroupMap.get(apm.Price_Book__r.External_Key__c);
                    if (buyerGroup == null) {
                        continue;
                    }

                    BuyerGroupMember newBgm = new BuyerGroupMember(External_Key__c = apm.External_Key__c, BuyerGroupId = buyerGroup.Id, BuyerId = apm.Account__c);
                    recordsToInsert.add(newBgm);
                }
            } else if (currentDate > apm.ERP_End_Date__c) {
                // Check if BuyerGroupMember exists
                if (existingBgmMap.containsKey(apm.External_Key__c)) {
                    // Delete the existing BuyerGroupMember record
                    recordsToDelete.add(existingBgmMap.get(apm.External_Key__c));
                }
            }
        }

        // Perform DML operations outside the loop
        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }

        if (!recordsToDelete.isEmpty()) {
            delete recordsToDelete;
        }
    }
}
