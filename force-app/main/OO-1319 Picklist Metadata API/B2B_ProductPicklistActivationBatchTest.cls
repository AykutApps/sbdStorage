@IsTest
public class B2B_ProductPicklistActivationBatchTest {
    // Test the execute method of the batch class
    @IsTest
    static void testExecuteMethod() {
        String responseBody = '{"FullName":"Test.B2B_Filter_2_Cycle_Ratio__c","Metadata":{"valueSet":{"valueSetDefinition":{"value":[{"label":"Active","isActive":false}]}}}}';
        Test.setMock(HttpCalloutMock.class, new B2B_ProductPicklistActivationHelperTest.MockHttpResponseGenerator(responseBody, 200));
        Database.BatchableContext bc = (Database.BatchableContext) Test.createStub(Database.BatchableContext.class);

        Test.startTest();
        B2B_ProductPicklistActivationBatch b = new B2B_ProductPicklistActivationBatch();
        b.start();
        Test.stopTest();
    }
}
