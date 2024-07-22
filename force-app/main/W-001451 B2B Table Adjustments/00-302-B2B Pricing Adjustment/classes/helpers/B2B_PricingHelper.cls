public with sharing class B2B_PricingHelper {
    public static void inactivatePricebooks(Set<Id> pricebook2Ids) {
        Date currentDate = B2B_GlobalVariables.asOf;
        // Query for active Pricebook2 records where External_Key__c is not null and CSP_End_Date__c is past
        List<Pricebook2> pricebooksToUpdate = [
            SELECT Id, IsActive
            FROM Pricebook2
            WHERE External_Key__c != NULL AND CSP_End_Date__c < :currentDate AND IsActive = TRUE AND Id IN :pricebook2Ids
        ];

        // Iterate over the fetched records and set IsActive to false
        for (Pricebook2 pb : pricebooksToUpdate) {
            pb.IsActive = false;
        }

        // Update the records in the database
        if (!pricebooksToUpdate.isEmpty()) {
            update pricebooksToUpdate;
        }
    }

    public static void adjustPricebookEntriesActivation(Set<Id> pricebookEntryIds) {
        Date currentDate = B2B_GlobalVariables.asOf;

        // Query only necessary fields to improve query performance
        List<PricebookEntry> entriesToUpdate = [
            SELECT Id, IsActive, ERP_Valid_To__c, ERP_Future_From_Date__c, ERP_Future_Price__c, UnitPrice, ERP_Future_Thru_Date__c
            FROM PricebookEntry
            WHERE ((ERP_Valid_To__c < :currentDate AND IsActive = TRUE) OR ERP_Future_From_Date__c = :currentDate) AND Id IN :pricebookEntryIds
        ];

        // Lists to hold records for bulk update
        List<PricebookEntry> entriesToDeactivate = new List<PricebookEntry>();
        List<PricebookEntry> entriesToActivateOrUpdate = new List<PricebookEntry>();

        // Process each entry and categorize them based on conditions
        for (PricebookEntry entry : entriesToUpdate) {
            if (entry.ERP_Future_Price__c == null && entry.IsActive) {
                entry.IsActive = false;
                entriesToDeactivate.add(entry);
            } else if (entry.ERP_Future_From_Date__c > currentDate && entry.ERP_Valid_To__c < currentDate && entry.IsActive) {
                entry.IsActive = false;
                entriesToDeactivate.add(entry);
            } else if (entry.ERP_Future_From_Date__c == currentDate) {
                entry.IsActive = true;
                entry.UnitPrice = entry.ERP_Future_Price__c;
                entry.ERP_Valid_From__c = entry.ERP_Future_From_Date__c;
                entry.ERP_Valid_To__c = entry.ERP_Future_Thru_Date__c;
                entriesToActivateOrUpdate.add(entry);
            }
        }

        if (!entriesToDeactivate.isEmpty()) {
            update entriesToDeactivate;
        }
        if (!entriesToActivateOrUpdate.isEmpty()) {
            update entriesToActivateOrUpdate;
        }
    }
}
