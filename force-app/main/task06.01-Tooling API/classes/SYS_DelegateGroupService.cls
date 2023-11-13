/**
 * Service class for operations related to Delegate Groups and their Members.
 * Author: aykut.parlak@bsdinc.com
 * Created Date: 2023-11-12
 */
public with sharing class SYS_DelegateGroupService {
    /**
     * Retrieves a list of DelegateGroups.
     * @return List of DelegateGroup objects.
     */
    public static List<DelegateGroup> getDelegateGroups() {
        return SYS_DelegateGroupServiceHelper.getDelegateGroups();
    }

    /**
     * Retrieves a list of DelegateGroupMembers with associated DelegateGroup names.
     * @return List of DelegateGroupMember objects.
     */
    public static List<DelegateGroupMember> getDelegateGroupMembers() {
        Map<Id, DelegateGroup> delegateGroupsMap = new Map<Id, DelegateGroup>();

        List<DelegateGroup> delegateGroups = SYS_DelegateGroupServiceHelper.getDelegateGroups();
        List<DelegateGroupMember> delegateGroupMembers = SYS_DelegateGroupServiceHelper.getDelegateGroupMembers();

        // Populate the map with DelegateGroup Id and DelegateGroup
        for (DelegateGroup delegateGroup : delegateGroups) {
            delegateGroupsMap.put(delegateGroup.id, delegateGroup);
        }

        // Enrich DelegateGroupMembers with DelegateGroup name
        for (DelegateGroupMember delegateGroupMember : delegateGroupMembers) {
            DelegateGroup dg = delegateGroupsMap.get(delegateGroupMember.delegateGroupId);
            if (dg != null) {
                delegateGroupMember.delegateGroupName = dg.name;
            }
        }

        return delegateGroupMembers;
    }

    /**
     * Inner class representing a DelegateGroup.
     */
    public class DelegateGroup {
        public Id id;
        public String developerName;
        public String isLoginAccessEnabled;
        public String name;
    }

    /**
     * Inner class representing a DelegateGroupMember.
     */
    public class DelegateGroupMember {
        public Id id;
        public Id delegateGroupId;
        public Id userOrGroupId;
        public String delegateGroupName; // This is populated from DelegateGroup
    }
}
