public with sharing class USR_CompareSFUsersHelper {
    /*  Derives rows for the data-analysis-grid (e.g. PageBlockTable or DataTable) on VF Page "CompareSFUsers2"
	Each row compares 1 data element for 2 or 3 SF Users: 
	- SF User #1 is called "base"
	- SF User #2 is called "other"
	- SF User #3 is called "another" 

	The helper methods find the records and then generates 1 row for each property/field/configuration; values for each user are placed on the same row
	- deriveUserGridRows(...)          - generates 1 row for each key field on the SF User record
	- deriveGroupAndQueueGridRows(...) - finds a pool of groups and queues assigned to the SF Users and generates 1 row for each group and queue
	- derivePermissionSetGridRows(...) - finds a pool of permission sets assigned to the SF Users and generates 1 row for each permission set
*/
    //ToFuture: derivePublicGroupGridRows(...)
    //ToFuture: deriveQueueGridRows(...)
    //ToFuture: deriveLibraryGridRows(...)
    //ToFuture: deriveChatterGroupGridRows(...)
    //ToFuture: research other SF Users settings stored in another table

    public static List<MTD_CompareModels.GridRow> deriveUserGridRows(User baseUser, User otherUser, User anotherUser) {
        List<MTD_CompareModels.GridRow> out = new List<MTD_CompareModels.GridRow>();

        MTD_CompareModels.GridRow g;
        //build field comparision - SF User SObject
        string parentType = 'SObject';
        string parentLabel = 'SF User';
        string parentApi = 'User';
        string metaType = 'Field';
        //ToFuture: add alias, nickname, timezone, currency, local, User.Manager.Name, User.ManagerId, ProfileId?, UserRoleId?, other key SF IDs?
        //User.Name
        g = new MTD_CompareModels.GridRow(1, parentType, parentLabel, parentApi, metaType, 'Full Name', 'Name');
        g.populateRow(
            ((baseUser == null) ? '' : baseUser.FirstName + ' ' + baseUser.LastName),
            ((otherUser == null) ? '' : otherUser.FirstName + ' ' + otherUser.LastName),
            ((anotherUser == null) ? '' : anotherUser.FirstName + ' ' + anotherUser.LastName)
        );
        out.add(g);
        //SF User Id
        g = new MTD_CompareModels.GridRow(2, parentType, parentLabel, parentApi, metaType, 'SF User Id', 'Id');
        g.populateRow(((baseUser == null) ? null : baseUser.Id), ((otherUser == null) ? null : otherUser.Id), ((anotherUser == null) ? null : anotherUser.Id));
        g.isSFId = true;
        out.add(g);
        //User.Profile.Name
        g = new MTD_CompareModels.GridRow(3, parentType, parentLabel, parentApi, metaType, 'SF Profile', 'Profile.Name');
        g.populateRow(
            ((baseUser == null) ? '' : baseUser.Profile.Name),
            ((otherUser == null) ? '' : otherUser.Profile.Name),
            ((anotherUser == null) ? '' : anotherUser.Profile.Name)
        );
        out.add(g);
        //User.UserRole.Name
        g = new MTD_CompareModels.GridRow(4, parentType, parentLabel, parentApi, metaType, 'SF Role/Data Visibility', 'UserRole.Name');
        g.populateRow(
            ((baseUser == null) ? '' : baseUser.UserRole.Name),
            ((otherUser == null) ? '' : otherUser.UserRole.Name),
            ((anotherUser == null) ? '' : anotherUser.UserRole.Name)
        );
        out.add(g);
        //User.IsActive
        g = new MTD_CompareModels.GridRow(5, parentType, parentLabel, parentApi, metaType, 'Active', 'IsActive');
        String other3StateBoolean = '';
        if (otherUser != null)
            other3StateBoolean = (otherUser.IsActive) ? 'TRUE' : 'FALSE';
        String another3StateBoolean = '';
        if (anotherUser != null)
            another3StateBoolean = (anotherUser.IsActive) ? 'TRUE' : 'FALSE';
        g.populateRow(((baseUser != null && baseUser.IsActive) ? 'TRUE' : 'FALSE'), other3StateBoolean, another3StateBoolean);
        out.add(g);
        //User.Title
        g = new MTD_CompareModels.GridRow(6, parentType, parentLabel, parentApi, metaType, 'Job Title', 'Title');
        g.populateRow(((baseUser == null) ? '' : baseUser.Title), ((otherUser == null) ? '' : otherUser.Title), ((anotherUser == null) ? '' : anotherUser.Title));
        out.add(g);
        //User.FederationIdentifier
        g = new MTD_CompareModels.GridRow(7, parentType, parentLabel, parentApi, metaType, 'SAML Federation ID', 'FederationIdentifier');
        g.populateRow(
            ((baseUser == null) ? '' : baseUser.FederationIdentifier),
            ((otherUser == null) ? '' : otherUser.FederationIdentifier),
            ((anotherUser == null) ? '' : anotherUser.FederationIdentifier)
        );
        out.add(g);
        //User.Username
        g = new MTD_CompareModels.GridRow(8, parentType, parentLabel, parentApi, metaType, 'SF Username/Login', 'Username');
        g.populateRow(((baseUser == null) ? '' : baseUser.Username), ((otherUser == null) ? '' : otherUser.Username), ((anotherUser == null) ? '' : anotherUser.Username));
        out.add(g);
        //User.Email
        g = new MTD_CompareModels.GridRow(9, parentType, parentLabel, parentApi, metaType, 'Email', 'Email');
        g.populateRow(((baseUser == null) ? '' : baseUser.Email), ((otherUser == null) ? '' : otherUser.Email), ((anotherUser == null) ? '' : anotherUser.Email));
        out.add(g);
        //User.ContactId
        g = new MTD_CompareModels.GridRow(10, parentType, parentLabel, parentApi, metaType, 'SF Contact ID', 'ContactId');
        g.populateRow(((baseUser == null) ? '' : baseUser.ContactId), ((otherUser == null) ? '' : otherUser.ContactId), ((anotherUser == null) ? '' : anotherUser.ContactId));
        g.isSFId = true;
        out.add(g);
        //User.Contact.Name
        g = new MTD_CompareModels.GridRow(11, parentType, parentLabel, parentApi, metaType, 'SF Contact', 'Contact.Name');
        g.populateRow(
            ((baseUser == null) ? '' : baseUser.Contact.Name),
            ((otherUser == null) ? '' : otherUser.Contact.Name),
            ((anotherUser == null) ? '' : anotherUser.Contact.Name)
        );
        out.add(g);

        //FINAL STEPS
        return out;
    }

    public static List<MTD_CompareModels.GridRow> deriveGroupAndQueueGridRows(User baseUser, User otherUser, User anotherUser) {
        List<MTD_CompareModels.GridRow> out = new List<MTD_CompareModels.GridRow>();

        //PREP
        Set<Id> userIds = new Set<Id>();
        if (baseUser != null && baseUser.Id != null)
            userIds.add(baseUser.Id);
        if (otherUser != null && otherUser.Id != null)
            userIds.add(otherUser.Id);
        if (anotherUser != null && anotherUser.Id != null)
            userIds.add(anotherUser.Id);

        if (userIds.size() == 0) {
            return out;
        }

        //Add Id of all groups attatched to provided Users into a Map (groupIdToMembersMap)
        Map<Id, MTD_CompareModels.Membership> groupIdToMembersMap = new Map<Id, MTD_CompareModels.Membership>();
        for (GroupMember gm : [SELECT Id, Group.Name, Group.Type, GroupId, UserOrGroupId FROM GroupMember WHERE UserOrGroupId IN :userIds]) {
            MTD_CompareModels.Membership m;
            if (groupIdToMembersMap.containsKey(gm.GroupId)) {
                m = groupIdToMembersMap.get(gm.GroupId);
            } else {
                m = new MTD_CompareModels.Membership(gm.GroupId);
            }

            if (baseUser != null && gm.UserOrGroupId == baseUser.Id) {
                m.includesBase = true;
            }
            if (otherUser != null && gm.UserOrGroupId == otherUser.Id) {
                m.includesOther = true;
            }
            if (anotherUser != null && gm.UserOrGroupId == anotherUser.Id) {
                m.includesAnother = true;
            }

            groupIdToMembersMap.put(gm.GroupId, m);
        }

        //WORK
        MTD_CompareModels.GridRow gr;

        string parentType = 'User';
        string parentApi = 'Group';
        string metaType = 'GroupMember';

        Integer i = 200;
        if (groupIdToMembersMap.size() > 0) {
            for (Group g : [SELECT Id, Name, Type FROM Group WHERE Id IN :groupIdToMembersMap.keySet() ORDER BY Type, Name ASC]) {
                if (groupIdToMembersMap.containsKey(g.Id)) {
                    MTD_CompareModels.Membership m = groupIdToMembersMap.get(g.Id);

                    gr = new MTD_CompareModels.GridRow(i, parentType, ((g.type == 'Queue') ? g.Type : 'Group'), parentApi, metaType + ' (Direct)', g.Name, g.Name);
                    gr.populateRow(((m.includesBase) ? g.Name : ''), ((m.includesOther) ? g.Name : ''), ((m.includesAnother) ? g.Name : ''));
                    gr.populateRowApis(((m.includesBase) ? g.Name : ''), ((m.includesOther) ? g.Name : ''), ((m.includesAnother) ? g.Name : ''));
                    out.add(gr);
                    i++;
                }
            }
        }

        //Final Steps
        return out;
    }

    public static List<MTD_CompareModels.GridRow> derivePermissionSetGridRows(User baseUser, User otherUser, User anotherUser) {
        List<MTD_CompareModels.GridRow> out = new List<MTD_CompareModels.GridRow>();

        //PREP
        Set<Id> userIds = new Set<Id>();
        if (baseUser != null && baseUser.Id != null)
            userIds.add(baseUser.Id);
        if (otherUser != null && otherUser.Id != null)
            userIds.add(otherUser.Id);
        if (anotherUser != null && anotherUser.Id != null)
            userIds.add(anotherUser.Id);

        if (userIds.size() == 0) {
            return out;
        }

        //Find Permission Set Assignments by SF User
        //KEY=PermissionSet.Id  VALUE=Apex Object that represents whether (or not) the baseUser, otherUser and/or anotherUser have the permission set
        Map<Id, MTD_CompareModels.Membership> permSetIdToMembersMap = new Map<Id, MTD_CompareModels.Membership>();
        for (User u : [
            SELECT Id, (SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignments) //ToFuture: exclude perm sets linked to the profiles?
            FROM User
            WHERE Id IN :userIds
        ]) {
            List<PermissionSetAssignment> psaList = u.PermissionSetAssignments;
            for (PermissionSetAssignment psa : psaList) {
                //get membership model for this assignment's PermissionSet (if it exists)
                MTD_CompareModels.Membership m;
                if (permSetIdToMembersMap.containsKey(psa.PermissionSetId)) {
                    m = permSetIdToMembersMap.get(psa.PermissionSetId);
                } else {
                    m = new MTD_CompareModels.Membership(psa.PermissionSetId);
                }
                if (baseUser != null && u.Id == baseUser.Id) {
                    m.includesBase = true;
                }
                if (otherUser != null && u.Id == otherUser.Id) {
                    m.includesOther = true;
                }
                if (anotherUser != null && u.Id == anotherUser.Id) {
                    m.includesAnother = true;
                }
                //FINAL STEP
                permSetIdToMembersMap.put(psa.PermissionSetId, m);
            }
        }

        //WORK
        MTD_CompareModels.GridRow g;
        //build security comparision - SF Permission Set Assignments
        string parentType = 'Security';
        string parentLabel = 'Permission Sets';
        string parentApi = 'PermissionSet';
        string metaType = 'PermissionSetAssignments';

        //query parent PermissionSet with an ALPHA sort and build 1 GridRow per PermissionSet
        integer i = 100;
        if (permSetIdToMembersMap.size() > 0) {
            for (PermissionSet ps : [
                SELECT Id, Label, Name, LicenseId, NamespacePrefix
                FROM PermissionSet
                WHERE Id IN :permSetIdToMembersMap.keySet() AND IsOwnedByProfile = FALSE //mburr.2020-04-16 exclude the permission set that links to the user's SF Profile; it is ugly
                ORDER BY Label
            ]) {
                if (permSetIdToMembersMap.containsKey(ps.Id)) {
                    MTD_CompareModels.Membership m = permSetIdToMembersMap.get(ps.Id);
                    //create 1 GridRow per Permission Set
                    g = new MTD_CompareModels.GridRow(i, parentType, parentLabel, parentApi, metaType, ps.Label, ps.Name);
                    g.populateRow(((m.includesBase) ? ps.Label : ''), ((m.includesOther) ? ps.Label : ''), ((m.includesAnother) ? ps.Label : ''));
                    g.populateRowApis(((m.includesBase) ? ps.Name : ''), ((m.includesOther) ? ps.Name : ''), ((m.includesAnother) ? ps.Name : ''));
                    out.add(g);
                    i++;
                }
            }
        }

        //FINAL STEPS
        return out;
    }
}
