@isTest
public without sharing class B2B_ProductImageBatchTest {
    @TestSetup
    public static void makeData() {
        Map<String,Product2> psMap = TestData_Product2.createProducts();
        
        for(Product2 p: psMap.values()){
            p.B2B_Image_URLs__c = 'https://www.cubcadet.com/on/demandware.static/-/Sites-mtd-master-catalog/default/dw0ac56bdb/products/Equipment/Cub-Cadet_ZTXS454_8.jpg,https://www.cubcadet.com/on/demandware.static/-/Sites-mtd-master-catalog/default/dw501af9f2/products/Equipment/Cub-Cadet_ZTXS454_7.jpg,https://www.cubcadet.com/on/demandware.static/-/Sites-mtd-master-catalog/default/dw03d42e23/products/Equipment/Cub-Cadet_ZTXS454_10.jpg,https://www.cubcadet.com/on/demandware.static/-/Sites-mtd-master-catalog/default/dw6a7f023a/products/Equipment/Cub-Cadet_ZTXS454_5.jpg,https://www.cubcadet.com/on/demandware.static/-/Sites-mtd-master-catalog/default/dw1af4994f/products/Equipment/Cub-Cadet_ZTXS454_6.jpg,https://www.cubcadet.com/on/demandware.static/-/Sites-mtd-master-catalog/default/dw850484ad/products/Equipment/Cub-Cadet_ZTXS454_2.jpg,https://www.cubcadet.com/on/demandware.static/-/Sites-mtd-master-catalog/default/dwa23f320f/products/Equipment/Cub-Cadet_ZTXS454_3.jpg';
            p.B2B_Product_Type__c = 'Parts';
            p.B2B_Image_Present__c = false;
        }

        update psMap.values();
    }

    @isTest
    public static void test_B2B_ProductImageBatch() {

        Test.startTest();
        B2B_ProductImageBatch b = new B2B_ProductImageBatch();
        ID BatchProcessId = Database.executeBatch(b,200); 
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM ContentVersion].size());

    }
}