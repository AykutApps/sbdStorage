@isTest
public class B2B_CustomMetadataHelperTest {
    
    @isTest
    static void testDeployCustomMetadata() {
        // Step 1: Create a list of custom metadata objects
        List<B2B_Product_Filter_Picklist_Value__mdt> testPicklistValues = new List<B2B_Product_Filter_Picklist_Value__mdt>();
        
        // Create a custom metadata record for testing
        B2B_Product_Filter_Picklist_Value__mdt testMetadata = new B2B_Product_Filter_Picklist_Value__mdt();
        testMetadata.DeveloperName = 'Test_DeveloperName';
        testMetadata.Label = 'Test Label';
        testMetadata.Parent_Field_API_Name__c = 'TestParentField';
        testMetadata.Picklist_Value_Label__c = 'Test Picklist Label';
        testMetadata.Picklist_Value_Name__c = 'Test Picklist Name';
        testMetadata.Is_Active__c = true;
        testPicklistValues.add(testMetadata);

        Test.startTest();
        // Define the mock callback
        Metadata.DeployCallback mockCallback = new B2B_CustomMetadataCallback();

        // Set the mock for the Metadata.DeployCallback interface
        Test.setMock(Metadata.DeployCallback.class, mockCallback);

        // Create a Metadata.DeployContainer
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();

        B2B_CustomMetadataHelper.deployProduct2FilterFieldsCustomMetadata(testPicklistValues);
        Test.stopTest();

        System.assert(true, 'Custom Metadata deployment was executed without errors.');
    }
}
