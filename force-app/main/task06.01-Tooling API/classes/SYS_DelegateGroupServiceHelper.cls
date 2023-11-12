public with sharing class SYS_DelegateGroupServiceHelper {
    public SYS_DelegateGroupServiceHelper() {
    }

    public static List<SYS_DelegateGroupService.delegateGroup> getDelegateGroups() {
        Httpresponse response = SYS_ToolingAPIService.getDelegateGroups();
        if (response.getStatusCode() == 200) {
            String responseBody = response.getbody();
            DelegateGroupResponse dgr = (DelegateGroupResponse) JSON.deserialize(responseBody, DelegateGroupResponse.class);
            return dgr.records;
        } else {
            return null;
        }
    }

    public static List<SYS_DelegateGroupService.DelegateGroupMember> getDelegateGroupMembers() {
        Httpresponse response = SYS_ToolingAPIService.getDelegateGroupMembers();
        if (response.getStatusCode() == 200) {
            String responseBody = response.getbody();
            DelegateGroupMemberResponse dgmr = (DelegateGroupMemberResponse) JSON.deserialize(responseBody, DelegateGroupMemberResponse.class);
            return dgmr.records;
        } else {
            return null;
        }
    }

    public class DelegateGroupResponse {
        public Integer size;
        public Integer totalSize;
        public Boolean done;
        public String queryLocator;
        public String entityTypeName;
        public List<SYS_DelegateGroupService.DelegateGroup> records;
    }

    public class DelegateGroupMemberResponse {
        public Integer size;
        public Integer totalSize;
        public Boolean done;
        public String queryLocator;
        public String entityTypeName;
        public List<SYS_DelegateGroupService.DelegateGroupMember> records;
    }
}
