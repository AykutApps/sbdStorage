public with sharing class B2B_ProductAttributeHelper {
    public static void updateProductFilterAttributes(Set<Id> product2Ids) {
        Map<String, String> indetifierFieldMapping = getIdentifierFieldMapping();

        List<Product2> ps = [SELECT Id, Commerce_JSON__c FROM Product2 WHERE Id IN :product2Ids];
        
        System.debug('DEBUG - 1 -ps');
        System.debug('indetifierFieldMapping');
        System.debug(indetifierFieldMapping); 
        System.debug('ps');
        System.debug(ps);
        for (Product2 p : ps) {
            if (p.Commerce_JSON__c == null)
                continue;
            Map<String, String> specMap = B2B_ProductAttributeHelper.extractSpecIdentifiersAndValues(p.Commerce_JSON__c);
            System.debug('specMap');
            System.debug(specMap);
            for (String identifier : indetifierFieldMapping.keySet()) {

                if (specMap.keySet().contains(identifier)) {
                    System.debug('contains identifier');
                    System.debug(identifier);
                    System.debug('field');
                    System.debug(indetifierFieldMapping.get(identifier));
                    System.debug(specMap.get(identifier));
                    
                    p.put(indetifierFieldMapping.get(identifier), specMap.get(identifier));
                }
            }
        }
        update ps;
    }

    // Helper methods
    public class Value {
        public Integer sequence { get; set; }
        public String value { get; set; }
    }

    public class Spec {
        public List<Value> values { get; set; }
        public String identifier { get; set; }
    }

    public class Attributes {
        public List<Spec> SPECS { get; set; }
    }

    public class Product {
        public Attributes attributes { get; set; }
    }

    public static Map<String, String> extractSpecIdentifiersAndValues(String jsonString) {
        Map<String, String> specMap = new Map<String, String>();
        try {
            List<Product> products = (List<Product>) JSON.deserialize(jsonString, List<Product>.class);
            for (Product product : products) {
                if (product.attributes != null && product.attributes.SPECS != null) {
                    for (Spec spec : product.attributes.SPECS) {
                        if (spec.identifier != null && !spec.values.isEmpty()) {
                            specMap.put(spec.identifier, spec.values[0].value);
                        }
                    }
                }
            }
        } catch (Exception exp) {
            System.debug(exp);
        }
        return specMap;
    }

    public static Map<String, String> getIdentifierFieldMapping() {
        Map<String, String> identifierFieldMapping = new Map<String, String>();
        List<B2B_Product_Master_Attribute__mdt> mappings = [SELECT Identifier__c, Product_Field_API_Name__c FROM B2B_Product_Master_Attribute__mdt];

        for (B2B_Product_Master_Attribute__mdt mapping : mappings) {
            identifierFieldMapping.put(mapping.Identifier__c, mapping.Product_Field_API_Name__c);
        }
        return identifierFieldMapping;
    }
}
