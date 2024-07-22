public with sharing class B2B_ProductAttributeHelper {
    public static void updateProductFilterAttributes(Set<Id> product2Ids) {
        // Define the mapping
        Map<String, String> indetifierFieldMapping = new Map<String, String>{
            '2-cycle-ratio' => 'B2B_Filter_2_Cycle_Ratio__c',
            'brand' => 'B2B_Filter_Brand__c',
            'oil-lubricant-category' => 'B2B_Filter_Oil_Lubricant_Category__c',
            'viscosity' => 'B2B_Filter_Viscosity__c',
            'volume' => 'B2B_Filter_Volume__c'
        };

        List<Product2> ps = [SELECT Id, Commerce_JSON__c FROM Product2 WHERE Id IN :product2Ids];

        for (Product2 p : ps) {
            if (p.Commerce_JSON__c == null)
                continue;
            Map<String, String> specMap = B2B_ProductAttributeHelper.extractSpecIdentifiersAndValues(p.Commerce_JSON__c);
            for (String identifier : indetifierFieldMapping.keySet()) {
                if (specMap.keySet().contains(identifier)) {
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
}