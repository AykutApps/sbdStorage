public with sharing class GenericLWCService {
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String query) {
        return Database.query(query);
    }
}