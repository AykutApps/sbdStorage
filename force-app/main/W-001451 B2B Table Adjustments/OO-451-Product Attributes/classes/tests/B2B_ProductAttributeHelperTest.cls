@isTest
public with sharing class B2B_ProductAttributeHelperTest {
    @isTest
    public static void testExtractSpecIdentifiersAndValues() {
        String jsonString = '[{"attributes":{"SPECS":[{"values":[{"sequence":0,"value":"32 oz (1 qt)"}],"identifier":"volume"},{"values":[{"sequence":0,"value":"2-Cycle Engine Oil"}],"identifier":"oil-lubricant-category"},{"values":[{"sequence":0,"value":"SAE 10W-30"}],"identifier":"viscosity"},{"values":[{"sequence":0,"value":"All Ratios"}],"identifier":"2-cycle-ratio"},{"values":[{"sequence":0,"value":"DEWALT"}],"identifier":"brand"}]}}]';
        Map<String, String> specMap = B2B_ProductAttributeHelper.extractSpecIdentifiersAndValues(jsonString);
        System.assertEquals(specMap.get('brand'), 'DEWALT');
    }

    @isTest
    public static void testUpdateProductFilterAttributes() {
        String jsonString = '[{"attributes":{"SPECS":[{"values":[{"sequence":0,"value":"32 oz (1 qt)"}],"identifier":"volume"},{"values":[{"sequence":0,"value":"2-Cycle Engine Oil"}],"identifier":"oil-lubricant-category"},{"values":[{"sequence":0,"value":"SAE 10W-30"}],"identifier":"viscosity"},{"values":[{"sequence":0,"value":"All Ratios"}],"identifier":"2-cycle-ratio"},{"values":[{"sequence":0,"value":"DEWALT"}],"identifier":"brand"}]}}]';

        Product2 p = TestData_Product2.createSingleProduct();
        p.Commerce_JSON__c = jsonString;
        update p;

        B2B_ProductAttributeHelper.updateProductFilterAttributes(new Set<Id>{ p.Id });
        Product2 p_updated = [SELECT Id, B2B_Filter_Brand__c FROM Product2 WHERE Id = :p.Id];
        System.assertEquals(p_updated.B2B_Filter_Brand__c, 'DEWALT');
    }
}
