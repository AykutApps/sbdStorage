/*
    This batch class is developed for filling the B2B Product2 fiter fields
    --------------------------------------------------------------------------
    Execution Script:
    --------------------------------------------------------------------------
    B2B_ProductPicklistActivationBatch b = new B2B_ProductPicklistActivationBatch();
    ID BatchProcessId = Database.executeBatch(b,B2B_ProductPicklistActivationBatch.BATCH_SIZE);     
    --------------------------------------------------------------------------
*/

global class B2B_ProductPicklistActivationBatch implements Database.Batchable<String>, Database.AllowsCallouts {
    private List<String> picklistFieldIds = new List<String>();
    public static final Integer BATCH_SIZE = 1;

    // Start method
    global Iterable<String> start(Database.BatchableContext BC) {
        // Return the list as an iterable

        List<EntityParticle> productFilterFileds = [
            SELECT FieldDefinitionId, QualifiedApiName
            FROM EntityParticle
            WHERE EntityDefinition.QualifiedApiName = 'Product2' AND DataType = 'picklist' AND QualifiedApiName LIKE 'B2B_Filter%'
        ];
        for (EntityParticle productFilterFiled : productFilterFileds) {
            List<String> fieldDefinitionInfo = productFilterFiled.FieldDefinitionId.split('\\.');
            picklistFieldIds.add(fieldDefinitionInfo[1]);
        }

        return picklistFieldIds;
    }

    // Execute method processes batches of strings
    global void execute(Database.BatchableContext BC, List<String> scope) {
        // Business logic here
        String picklistFieldId = (String) scope[0];
        B2B_ProductPicklistActivationHelper.activateInactivePicklistValues(picklistFieldId);
    }

    // Finish method
    global void finish(Database.BatchableContext BC) {
    }
}
