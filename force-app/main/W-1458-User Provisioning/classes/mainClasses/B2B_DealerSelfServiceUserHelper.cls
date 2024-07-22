public with sharing class B2B_DealerSelfServiceUserHelper {
    // Static map to cache Permission Set IDs
    private static Map<String, Id> permissionSetIdMap;

    // Pre-defined permission set names as constants
    private static String partsOrderingPermissionSetName = 'IR_USA_DLR_ADD_Parts_Ordering';
    private static String dealerOrderingPermissionSetName = 'IR_USA_DLR_ADD_Dealer_Ordering';

    public static void adjustPermissionsBasedOnContactFields(Set<Id> contactIds) {
        // Retrieve necessary contact fields and related user data in one query
        Map<Id, User> userIdMap = new Map<Id, User>([SELECT Id, (SELECT Id, PermissionSet.Name FROM PermissionSetAssignments) FROM User WHERE contactId IN :contactIds]);
        List<Contact> contacts = [SELECT Id, B2B_Parts_Active__c, B2B_Whole_Goods_Active__c, (SELECT Id FROM Users) FROM Contact WHERE Id IN :contactIds];

        List<PermissionSetAssignment> psaToInsert = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> psaToDelete = new List<PermissionSetAssignment>();

        // Iterate through each contact and adjust permission sets accordingly
        for (Contact contact : contacts) {
            for (User cuser : contact.Users) {
                User user = userIdMap.get(cuser.Id);

                PermissionSetAssignment existingPsaPartPermission;
                PermissionSetAssignment existingPsaWGPermission;

                // Check existing permission sets
                for (PermissionSetAssignment psa : user.PermissionSetAssignments) {
                    if (psa.PermissionSet.Name == partsOrderingPermissionSetName) {
                        existingPsaPartPermission = psa;
                    }
                    if (psa.PermissionSet.Name == dealerOrderingPermissionSetName) {
                        existingPsaWGPermission = psa;
                    }
                }

                // Add necessary permissions if not found
                if (contact.B2B_Parts_Active__c && existingPsaPartPermission == null) {
                    psaToInsert.add(new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = retrievePermissionSetId(partsOrderingPermissionSetName)));
                } else if (!contact.B2B_Parts_Active__c && existingPsaPartPermission != null) {
                    psaToDelete.add(existingPsaPartPermission);
                }

                if (contact.B2B_Whole_Goods_Active__c && existingPsaWGPermission == null) {
                    psaToInsert.add(new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = retrievePermissionSetId(dealerOrderingPermissionSetName)));
                } else if (!contact.B2B_Whole_Goods_Active__c && existingPsaWGPermission != null) {
                    psaToDelete.add(existingPsaWGPermission);
                }
            }
        }

        // Perform DML operations outside the loop
        insert psaToInsert;
        delete psaToDelete;
    }

    public static Id retrievePermissionSetId(String permissionSetName) {
        // Initialize the map only once
        if (permissionSetIdMap == null) {
            permissionSetIdMap = new Map<String, Id>();
            // Query all relevant permission sets at once
            for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :new List<String>{ partsOrderingPermissionSetName, dealerOrderingPermissionSetName }]) {
                permissionSetIdMap.put(ps.Name, ps.Id);
            }
        }

        // Return the cached Permission Set ID or null if not found
        return permissionSetIdMap.get(permissionSetName);
    }
}
