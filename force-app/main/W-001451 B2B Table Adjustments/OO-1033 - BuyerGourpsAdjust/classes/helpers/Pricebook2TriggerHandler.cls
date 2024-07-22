public with sharing class Pricebook2TriggerHandler implements TriggerInterface {
    public void beforeInsert() {
    }

    public void beforeUpdate() {
    }

    public void beforeDelete() {
    }

    public void afterInsert() {
        B2B_BuyerGroupAndEntitlementHelper.adjustCommerceEntitlementBuyerGroupFuture(Trigger.newMap.keySet());
    }

    public void afterUpdate() {
        B2B_BuyerGroupAndEntitlementHelper.adjustCommerceEntitlementBuyerGroupFuture(Trigger.newMap.keySet());
    }

    public void afterDelete() {
    }

    public void finish() {
    }
}
