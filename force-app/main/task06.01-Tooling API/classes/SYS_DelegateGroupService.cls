public with sharing class SYS_DelegateGroupService {
    public SYS_DelegateGroupService() {
    }

    public static List<DelegateGroup> getDelegateGroups() {
        List<DelegateGroup> delegateGroups = SYS_DelegateGroupServiceHelper.getDelegateGroups();
        return delegateGroups;
    }

    public static List<DelegateGroupMember> getDelegateGroupMembers() {
        Map<Id, DelegateGroup> delegateGroupsMap = new Map<Id, DelegateGroup>();

        List<DelegateGroup> delegateGroups = SYS_DelegateGroupServiceHelper.getDelegateGroups();
        List<DelegateGroupMember> delegateGroupMembers = SYS_DelegateGroupServiceHelper.getDelegateGroupMembers();

        for (DelegateGroup delegateGroup : delegateGroups) {
            delegateGroupsMap.put(delegateGroup.Id, delegateGroup);
        }

        for (DelegateGroupMember delegateGroupMember : delegateGroupMembers) {
            delegateGroupMember.delegateGroupName = delegateGroupsMap.get(delegateGroupMember.delegateGroupId)?.name;
        }

        return delegateGroupMembers;
    }

    public class DelegateGroup {
        public Id id;
        public String developerName;
        public String isLoginAccessEnabled;
        public String name;
    }

    public class DelegateGroupMember {
        public Id id;
        public Id delegateGroupId;
        public Id userOrGroupId;
        public String delegateGroupName;
    }
}
