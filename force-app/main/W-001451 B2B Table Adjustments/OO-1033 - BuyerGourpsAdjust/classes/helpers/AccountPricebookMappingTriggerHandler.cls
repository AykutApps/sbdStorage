public class AccountPricebookMappingTriggerHandler implements TriggerInterface {
    public void beforeInsert() {
        setAccountIdsByEntityId(Trigger.new);
    }

    public void beforeUpdate() {
        setAccountIdsByEntityId(Trigger.new);
    }

    public void beforeDelete() {
    }

    public void afterInsert() {
        // adjustBuyerGroupMember();
    }

    public void afterUpdate() {
        // adjustBuyerGroupMember();
    }

    public void afterDelete() {
    }

    public void finish() {
    }

    private void setAccountIdsByEntityId(List<Account_Pricebook_Mapping__c> accountPricebookMappings) {
        Set<String> entityIds = new Set<String>();
        for (Account_Pricebook_Mapping__c s : accountPricebookMappings) {
            System.debug(getEntityIdFromCustomerNumber(s.Customer_Number__c));
            entityIds.add(getEntityIdFromCustomerNumber(s.Customer_Number__c));
        }

        Map<String, Id> accountMapByEntityId = new Map<String, Id>();
        for (Account a : [SELECT Id, Entity_Id__c FROM Account WHERE Entity_Id__c = :entityIds]) {
            accountMapByEntityId.put(a.Entity_Id__c, a.Id);
        }

        for (Account_Pricebook_Mapping__c s : accountPricebookMappings) {
            String entityId = getEntityIdFromCustomerNumber(s.Customer_Number__c);
            if (accountMapByEntityId.containsKey(entityId)) {
                s.Account__c = accountMapByEntityId.get(entityId);
            }
        }
    }

    private String getEntityIdFromCustomerNumber(String customerNumberStr) {
        //String customerNumberStr = String.valueOf((Integer) customerNumber);
        return customerNumberStr.left(customerNumberStr.length() - 2);
    }

    private void adjustBuyerGroupMember() {
        // B2B_BuyerGroupAndEntitlementHelper.adjustBuyerGroupMemberFuture(Trigger.newMap.keySet());
    }
}
