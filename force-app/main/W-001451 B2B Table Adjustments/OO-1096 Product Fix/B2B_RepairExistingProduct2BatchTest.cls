@isTest
public class B2B_RepairExistingProduct2BatchTest {
    @TestSetup
    public static void makeData() {
        Map<String, Product2> pMap = TestData_Product2.createProducts(); // creates 8 products
        Integer skuNumber = 0;
        for (Product2 p : pMap.values()) {
            p.ProductCode = 'TEST' + String.valueOf(skuNumber);
            p.StockKeepingUnit = 'TEST' + String.valueOf(skuNumber);
            skuNumber++;
        }
        update pMap.values();
    }

    @isTest
    public static void testB2B_RepairExistingProduct2Batch() {
        List<Product2> ps = [
            SELECT Id, RecordTypeId, StockKeepingUnit, ProductCode, IsActive, Is_Active_US__c, B2B_Product_Type__c, Update_Fulfill_From__c, Update_Fulfill_From_Text__c, CreatedById
            FROM Product2
        ];
        Product2 pForStockKeepingUnitTest;
        Product2 pForUpdateFulfillFromTest;
        Product2 pForIsActiveUSTest;
        Product2 pForB2BProductTypeTest;

        for (Product2 p : ps) {
            if (pForStockKeepingUnitTest == null) {
                p.StockKeepingUnit = p.ProductCode + 'XXX';
                pForStockKeepingUnitTest = p;
            } else if (pForUpdateFulfillFromTest == null) {
                //p.Update_Fulfill_From__c = null; // conflict with ProductTriggerHandler line 560
                pForUpdateFulfillFromTest = p;
            } else if (pForIsActiveUSTest == null) {
                p.RecordTypeId = RecordTypes.product_WholeGood.Id;
                p.IsActive = true;
                p.Is_Active_US__c = false;
                pForIsActiveUSTest = p;
            } else if (pForB2BProductTypeTest == null) {
                p.RecordTypeId = RecordTypes.product_Part.Id;
                p.B2B_Product_Type__c = null;
                pForB2BProductTypeTest = p;
            }
        }

        update ps;

        Test.startTest();
        B2B_RepairExistingProduct2Batch b = new B2B_RepairExistingProduct2Batch();
        Id BatchProcessId = Database.executeBatch(b, 200);
        Test.stopTest();

        ps = [
            SELECT Id, RecordTypeId, StockKeepingUnit, ProductCode, IsActive, Is_Active_US__c, B2B_Product_Type__c, Update_Fulfill_From__c, Update_Fulfill_From_Text__c, CreatedById
            FROM Product2
        ];
        for (Product2 p : ps) {
            if (p.Id == pForStockKeepingUnitTest.Id) {
                System.assertEquals(p.ProductCode, p.StockKeepingUnit);
            } else if (p.Id == pForUpdateFulfillFromTest.Id) {
                // System.assertEquals('INFOR', p.Update_Fulfill_From_Text__c);
            } else if (p.Id == pForIsActiveUSTest.Id) {
                System.assertEquals(true, p.Is_Active_US__c);
            } else if (p.Id == pForB2BProductTypeTest.Id) {
                System.assertEquals('Parts', p.B2B_Product_Type__c);
            }
        }
    }
}
