public class B2B_CustomMetadataHelper {
    public static void deployProduct2FilterFieldsCustomMetadata(List<B2B_Product_Filter_Picklist_Value__mdt> picklistValues) {

        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        for(B2B_Product_Filter_Picklist_Value__mdt picklistValue :picklistValues){
            // Set up custom metadata to be created in the subscriber org.
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            // customMetadata.fullName = 'B2B_Product_Filter_Picklist_Value.Not_Found_Code';
            customMetadata.fullName = 'B2B_Product_Filter_Picklist_Value.'+picklistValue.DeveloperName.replaceAll('[^a-zA-Z0-9\\s+]', '').replaceAll('\\s+', '').left(40);
            customMetadata.label = picklistValue.Label;

            Metadata.CustomMetadataValue customField0 = new Metadata.CustomMetadataValue();
            customField0.field = 'Parent_Field_API_Name__c';
            customField0.value = picklistValue.Parent_Field_API_Name__c;
            customMetadata.values.add(customField0);

            Metadata.CustomMetadataValue customField1 = new Metadata.CustomMetadataValue();
            customField1.field = 'Picklist_Value_Label__c';
            customField1.value = picklistValue.Picklist_Value_Label__c;
            customMetadata.values.add(customField1);

            Metadata.CustomMetadataValue customField2 = new Metadata.CustomMetadataValue();
            customField2.field = 'Picklist_Value_Name__c';
            customField2.value = picklistValue.Picklist_Value_Name__c;
            customMetadata.values.add(customField2);

            Metadata.CustomMetadataValue customField3 = new Metadata.CustomMetadataValue();
            customField3.field = 'Is_Active__c';
            customField3.value = picklistValue.Is_Active__c;
            customMetadata.values.add(customField3);

            mdContainer.addMetadata(customMetadata);
        }
        
        B2B_CustomMetadataCallback callback = new B2B_CustomMetadataCallback();

        // Enqueue custom metadata deployment if the test is not runnig
        if (!Test.isRunningTest()){
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }
    }
}
