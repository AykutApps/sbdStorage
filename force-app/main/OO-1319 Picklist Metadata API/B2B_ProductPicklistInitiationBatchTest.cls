@IsTest
public class B2B_ProductPicklistInitiationBatchTest {
    // Test the execute method of the batch class
    @IsTest
    static void testExecuteMethod() {
        String responseBody = '{"FullName":"Test.B2B_Filter_2_Cycle_Ratio__c","Metadata":{"valueSet":{"valueSetDefinition":{"value":[{"label":"Active","isActive":false,"valueName":"testValueName"}]}}}}';

        Test.setMock(HttpCalloutMock.class, new B2B_ProductPicklistActivationHelperTest.MockHttpResponseGenerator(responseBody, 200));
        Test.startTest();
        B2B_ProductPicklistInitiationBatch b = new B2B_ProductPicklistInitiationBatch();
        ID BatchProcessId = Database.executeBatch(b, 200);
        Test.stopTest();

        // check if any error is logged under System Log
        System.assertEquals(0, [SELECT Id FROM System_Log__c].size());
    }
}
