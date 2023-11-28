/**
 * @description This class provides a generic Lightning Web Component (LWC) service for retrieving records from Salesforce using a SOQL query.
 * @author aykut.parlak@sbdinc.com
 * @date 2023-11-28
 */
public with sharing class GenericLWCService {
    /**
     * @description Retrieves a list of SObjects based on the provided SOQL query.
     * @param query - The SOQL query to execute.
     * @return List<SObject> - The list of SObjects retrieved based on the query.
     */
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String query) {
        return Database.query(query);
    }
}
