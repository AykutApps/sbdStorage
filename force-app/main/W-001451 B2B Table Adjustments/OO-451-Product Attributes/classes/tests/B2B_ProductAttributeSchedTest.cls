@isTest
public with sharing class B2B_ProductAttributeSchedTest {
    @TestSetup
    public static void makeData() {
        String jsonString = '[{"attributes":{"SPECS":[{"values":[{"sequence":0,"value":"32 oz (1 qt)"}],"identifier":"volume"},{"values":[{"sequence":0,"value":"2-Cycle Engine Oil"}],"identifier":"oil-lubricant-category"},{"values":[{"sequence":0,"value":"SAE 10W-30"}],"identifier":"viscosity"},{"values":[{"sequence":0,"value":"All Ratios"}],"identifier":"2-cycle-ratio"},{"values":[{"sequence":0,"value":"DEWALT"}],"identifier":"brand"}]}}]';
        Map<String, Product2> pMap = TestData_Product2.createProducts();
        for (Product2 p : pMap.values()) {
            p.Commerce_JSON__c = jsonString;
        }

        update pMap.values();
    }

    @isTest
    public static void testB2B_ProductAttributeSched() {
        Test.startTest();
        B2B_ProductAttributeSched s = new B2B_ProductAttributeSched();
        s.execute(null);
        Test.stopTest();

        Product2 p_updated = [SELECT Id, B2B_Filter_Brand__c FROM Product2 LIMIT 1];
        System.assertEquals(p_updated.B2B_Filter_Brand__c, 'DEWALT');
    }
}
