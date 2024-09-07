public with sharing class ProductQuantityRuleHelper {
    public static Integer MAX_MOM_NUMBER = 45;

    public static void createPurchaseQuantityRules() {
        List<PurchaseQuantityRule> pqrsToInsert = new List<PurchaseQuantityRule>();

        Map<Decimal, PurchaseQuantityRule> pqrMap = getPqrMap();

        for (Integer i = 2; i <= MAX_MOM_NUMBER; i++) {
            if (pqrMap.get(i) == null) {
                PurchaseQuantityRule pqr = new PurchaseQuantityRule();
                pqr.Name = 'MOM-' + String.valueOf(i) + '-' + String.valueOf(i);
                pqr.Minimum = i;
                pqr.Increment = i;
                pqr.Maximum = ((10000) / i) * i;
                pqrsToInsert.add(pqr);
            }
        }

        insert pqrsToInsert;
    }

    public static void upsertProductQuantityRules(Set<Id> productIds) {
        ProductQuantityRule[] pqrsToInsert = new List<ProductQuantityRule>();
        List<Product2> prs = [
            SELECT Id, Package_Quantity__c, (SELECT Id, PurchaseQuantityRule.Minimum FROM ProductQuantityRules)
            FROM Product2
            WHERE Package_Quantity__c > 1 AND Id IN :productIds
        ];
        Map<Decimal, PurchaseQuantityRule> pqrMap = getPqrMap();
        for (Product2 pr : prs) {
            Boolean isThereRelatedPqr = false;
            Decimal packageQuantity = pr.Package_Quantity__c;
            for (ProductQuantityRule pqr : pr.ProductQuantityRules) {
                if (pqr.PurchaseQuantityRule.Minimum == packageQuantity) {
                    isThereRelatedPqr = true;
                    break;
                }
            }

            if (!isThereRelatedPqr) {
                PurchaseQuantityRule pqr = pqrMap.get(packageQuantity);
                pqrsToInsert.add(new ProductQuantityRule(ProductId = pr.Id, PurchaseQuantityRuleId = pqr.Id));
            }
        }

        insert pqrsToInsert;
    }

    public static Map<Decimal, PurchaseQuantityRule> getPqrMap() {
        Map<Decimal, PurchaseQuantityRule> pqrMap = new Map<Decimal, PurchaseQuantityRule>();
        PurchaseQuantityRule[] pqrs = [SELECT Id, Name, Minimum, Increment, Maximum FROM PurchaseQuantityRule];
        for (PurchaseQuantityRule pqr : pqrs) {
            pqrMap.put(Integer.valueOf(pqr.Minimum), pqr);
        }
        return pqrMap;
    }
}
