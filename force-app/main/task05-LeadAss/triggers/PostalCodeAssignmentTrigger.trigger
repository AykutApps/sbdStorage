/**
 * Apex Trigger for handling the assignment of a user to the Pardot_Lead_Assignee__c
 * field on the Postal_Code_Assignment__c custom object based on the provided assignee name.
 * The trigger works before the insert and update operations to ensure that the assignment
 * is done before the record is committed to the database.
 */
trigger PostalCodeAssignmentTrigger on Postal_Code_Assignment__c(before insert, before update) {
    Map<String, User> assigneeNameToUserMap = new Map<String, User>();
    for (User usr : [SELECT Id, Name FROM User]) {
        String refinedName = usr.Name.toLowercase().replaceAll(' ', '_');
        assigneeNameToUserMap.put(refinedName, usr);
    }

    // Iterate over all Postal_Code_Assignment__c records that are being inserted or updated.
    for (Postal_Code_Assignment__c assignment : Trigger.new) {
        // Check if the Pardot_Lead_Assignee_Name__c field is not blank and that it is either a new record
        // or the assignee name has changed (for updates).
        if (
            String.isNotBlank(assignment.Pardot_Lead_Assignee_Name__c) &&
            (Trigger.isInsert || (Trigger.isUpdate && assignment.Pardot_Lead_Assignee_Name__c != Trigger.oldMap.get(assignment.Id).Pardot_Lead_Assignee_Name__c))
        ) {
            User matchedUser = assigneeNameToUserMap.get(assignment.Pardot_Lead_Assignee_Name__c.toLowercase().replaceAll(' ', '_'));
            assignment.Pardot_Lead_Assignee__c = (matchedUser != null) ? matchedUser.Id : null;
        }
    }
}
