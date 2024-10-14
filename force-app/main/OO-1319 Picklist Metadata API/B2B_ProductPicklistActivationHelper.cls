public class B2B_ProductPicklistActivationHelper {
    // Base URL for the Metadata API
    private static final String BASE_URL = Url.getOrgDomainUrl().toExternalForm() + '/services/data/v58.0/tooling/sobjects/CustomField/';

    public static void activateInactivePicklistValues(String fieldId) {
        try {
            String picklistValuesMetadata = fetchPicklistValues(fieldId);
            String activatedAllPicklistValuesPayload = generateMetadataForAllPicklistValueActivation(picklistValuesMetadata);
            activateAllPicklistValues(fieldId, activatedAllPicklistValuesPayload);
        } catch (Exception ex) {
            SystemLogHelper.insertSystemLog(
                'B2B_ProductPicklistActivationHelper',
                'METADATA_API_PICKLIST_ACTIVATION',
                UserInfo.getUserId(),
                'Activate Picklist Method Failed',
                ex.getMessage()
            );
        }
    }

    public static void initiatePicklistValuesFromObjectDescription(String fieldId) {
        try {
            String picklistValuesMetadata = fetchPicklistValues(fieldId);
            generateCustomMetadataFoPicklistValues(picklistValuesMetadata);
        } catch (Exception ex) {
            SystemLogHelper.insertSystemLog(
                'B2B_ProductPicklistActivationHelper',
                'METADATA_API_PICKLIST_CREATION',
                UserInfo.getUserId(),
                'Create Picklist Method Failed',
                ex.getMessage()
            );
        }
    }

    // Fetch picklist values for a specific field
    public static String fetchPicklistValues(String fieldId) {
        HttpResponse response = sendHttpRequest(fieldId, 'GET', null);
        isSuccessfulResponse(response);
        return response.getBody();
    }

    // Update picklist values for a specific field
    public static void activateAllPicklistValues(String fieldId, String payload) {
        HttpResponse response = sendHttpRequest(fieldId, 'PATCH', payload);
        isSuccessfulResponse(response);
    }

    // Helper method to send HTTP request
    private static HttpResponse sendHttpRequest(String fieldId, String method, String body) {
        String endpoint = BASE_URL + fieldId;

        // Create a new HttpRequest and set headers
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);
        request.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        request.setHeader('Content-Type', 'application/json');

        if (body != null) {
            request.setBody(body);
        }

        // Send the request and return response
        Http http = new Http();
        return http.send(request);
    }

    // Helper method to determine if the response was successful
    public static Boolean isSuccessfulResponse(HttpResponse response) {
        if (response.getStatusCode() >= 200 && response.getStatusCode() <= 300) {
            return true;
        } else {
            throw new CustomException(response.getBody());
        }
    }

    // Process the metadata and set picklist values to active if needed
    public static String generateMetadataForAllPicklistValueActivation(String apiResponse) {
        // Parse the JSON response into a Map
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(apiResponse);
        String fieldName = (String) responseMap.get('FullName');
        fieldName = fieldName.split('\\.')[1];

        // Extract the Metadata node
        if (responseMap.containsKey('Metadata')) {
            Map<String, Object> metadata = (Map<String, Object>) responseMap.get('Metadata');

            B2B_Product_Filter_Picklist_Value__mdt[] picklistFields = [
                SELECT Id, Parent_Field_API_Name__c, Picklist_Value_Label__c, Picklist_Value_Name__c, Is_Active__c
                FROM B2B_Product_Filter_Picklist_Value__mdt
                WHERE Parent_Field_API_Name__c = :fieldName
            ];

            // Extract valueSet if it exists
            if (metadata.containsKey('valueSet')) {
                Map<String, Object> valueSet = (Map<String, Object>) metadata.get('valueSet');
                valueSet.put('valueSettings', new List<String>());

                // Extract valueSetDefinition if it exists
                if (valueSet.containsKey('valueSetDefinition')) {
                    Map<String, Object> valueSetDefinition = (Map<String, Object>) valueSet.get('valueSetDefinition');

                    // Extract the value array and update isActive
                    if (valueSetDefinition.containsKey('value')) {
                        List<Object> values2 = new List<Object>();

                        for (B2B_Product_Filter_Picklist_Value__mdt picklistField : picklistFields) {
                            Map<String, Object> valueItem = new Map<String, Object>();
                            valueItem.put('isActive', picklistField.Is_Active__c);
                            valueItem.put('valueName', picklistField.Picklist_Value_Name__c);
                            valueItem.put('label', picklistField.Picklist_Value_Label__c);
                            values2.add(valueItem);
                        }
                        valueSetDefinition.put('value', values2);
                    }
                }
            }

            // Serialize updated metadata
            Map<String, Object> updatedResponseMap = new Map<String, Object>();
            updatedResponseMap.put('Metadata', metadata);
            String updatedMetadata = JSON.serializePretty(updatedResponseMap);
            return updatedMetadata;
        }

        return null;
    }

    // Process the metadata and set picklist values to active if needed
    public static String generateCustomMetadataFoPicklistValues(String apiResponse) {
        // Parse the JSON response into a Map
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(apiResponse);
        String fieldName = (String) responseMap.get('FullName');
        fieldName = fieldName.split('\\.')[1];

        // Extract the Metadata node
        if (responseMap.containsKey('Metadata')) {
            Map<String, Object> metadata = (Map<String, Object>) responseMap.get('Metadata');
            String fieldDeveloperName = ((String) responseMap.get('DeveloperName')) + '__c';

            List<B2B_Product_Filter_Picklist_Value__mdt> picklistValues = new List<B2B_Product_Filter_Picklist_Value__mdt>();

            // Extract valueSet if it exists
            if (metadata.containsKey('valueSet')) {
                Map<String, Object> valueSet = (Map<String, Object>) metadata.get('valueSet');
                valueSet.put('valueSettings', new List<String>());

                // Extract valueSetDefinition if it exists
                if (valueSet.containsKey('valueSetDefinition')) {
                    Map<String, Object> valueSetDefinition = (Map<String, Object>) valueSet.get('valueSetDefinition');

                    // Extract the value array and update isActive
                    if (valueSetDefinition.containsKey('value')) {
                        List<Object> values2 = new List<Object>();

                        // Iterate over the list
                        List<Object> values = (List<Object>) valueSetDefinition.get('value');
                        for (Object valueItemObj : values) {
                            Map<String, Object> valueItem = (Map<String, Object>) valueItemObj;
                            valueItem.put('isActive', true);
                            // Create a new record of the custom metadata type
                            B2B_Product_Filter_Picklist_Value__mdt picklistValue = new B2B_Product_Filter_Picklist_Value__mdt();
                            
                            // Set field values
                            picklistValue.Parent_Field_API_Name__c = fieldDeveloperName;
                            picklistValue.DeveloperName = fieldDeveloperName + '_' + ((String) valueItem.get('valueName')).trim() ;
                            picklistValue.Label = ((String) valueItem.get('label'));
                            picklistValue.Picklist_Value_Label__c = (String) valueItem.get('label');
                            picklistValue.Picklist_Value_Name__c = (String) valueItem.get('valueName');
                            picklistValue.Is_Active__c = true;
                            picklistValues.add(picklistValue);
                        }
                    }
                }
            }

            B2B_CustomMetadataHelper.deployProduct2FilterFieldsCustomMetadata(picklistValues);
        }

        return null;
    }

    public class CustomException extends Exception {
    }
}

