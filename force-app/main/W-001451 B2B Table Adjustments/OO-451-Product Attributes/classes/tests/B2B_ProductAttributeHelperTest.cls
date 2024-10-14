@isTest
public with sharing class B2B_ProductAttributeHelperTest {
    
    @isTest
    public static void testExtractSpecIdentifiersAndValues(){
        String jsonString = '[{"attributes":{"SPECS":[{"values":[{"sequence":0,"value":"32 oz (1 qt)"}],"identifier":"volume"},{"values":[{"sequence":0,"value":"2-Cycle Engine Oil"}],"identifier":"oil-lubricant-category"},{"values":[{"sequence":0,"value":"SAE 10W-30"}],"identifier":"viscosity"},{"values":[{"sequence":0,"value":"All Ratios"}],"identifier":"2-cycle-ratio"},{"values":[{"sequence":0,"value":"DEWALT"}],"identifier":"brand"}]}}]';
        Map<String, String> specMap = B2B_ProductAttributeHelper.extractSpecIdentifiersAndValues(jsonString);
        System.assertEquals('DEWALT', specMap.get('brand'));
    }

    @isTest
    public static void testUpdateProductFilterAttributes(){
        String jsonString = '[{"attributes":{"SPECS":[{"values":[{"sequence":0,"value":"32 oz (1 qt)"}],"identifier":"volume"},{"values":[{"sequence":0,"value":"2-Cycle Engine Oil"}],"identifier":"oil-lubricant-category"},{"values":[{"sequence":0,"value":"SAE 10W-30"}],"identifier":"viscosity"},{"values":[{"sequence":0,"value":"All Ratios"}],"identifier":"2-cycle-ratio"},{"values":[{"sequence":0,"value":"DEWALT"}],"identifier":"brand"}]}}]';

        Product2 p=TestData_Product2.createSingleProduct();
        p.Commerce_JSON__c  = jsonString; 		
        update p;

        Test.startTest();
        B2B_ProductAttributeHelper.updateProductFilterAttributes(new Set<Id>{p.Id});
        Test.stopTest();

        Product2 p_updated = [SELECT Id,B2B_Filter_Brand__c FROM Product2 WHERE Id =:p.Id];
        System.assertEquals('DEWALT', p_updated.B2B_Filter_Brand__c);
    }
}