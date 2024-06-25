@isTest
private class PostalCodeAssignmentTriggerTest {
    @isTest
    static void testPostalCodeAssignmentTrigger() {
        User us = [SELECT Id, Name FROM User WHERE IsActive = TRUE LIMIT 1];
        Postal_Code_Assignment__c pca1 = new Postal_Code_Assignment__c(Postal_Code__c = '00001', Pardot_Lead_Assignee_Name__c = us.Name);
        insert pca1;

        pca1 = [SELECT Id, Pardot_Lead_Assignee__c FROM Postal_Code_Assignment__c LIMIT 1];
        System.assertEquals(pca1.Pardot_Lead_Assignee__c, us.Id);
    }
}