/**
 * Helper class for operations related to Delegate Groups and their Members.
 * Author: aykut.parlak@bsdinc.com
 * Created Date: 2023-11-12
 */
public with sharing class SYS_DelegateGroupServiceHelper {
    /**
     * Retrieves a list of DelegateGroups.
     * @return List of DelegateGroup objects or null if an error occurs.
     */
    public static List<SYS_DelegateGroupService.DelegateGroup> getDelegateGroups() {
        List<SYS_DelegateGroupService.DelegateGroup> dgs = new List<SYS_DelegateGroupService.DelegateGroup>();

        HttpResponse response = SYS_ToolingAPIService.getDelegateGroups();
        if (response != null && response.getStatusCode() == 200) {
            String responseBody = response.getBody();
            DelegateGroupResponse dgr = (DelegateGroupResponse) JSON.deserialize(responseBody, DelegateGroupResponse.class);
            if (dgr.records != null && !dgr.records.isEmpty()) {
                dgs = dgr.records;
            }
        }

        return dgs;
    }

    /**
     * Retrieves a list of DelegateGroupMembers.
     * @return List of DelegateGroupMember objects or null if an error occurs.
     */
    public static List<SYS_DelegateGroupService.DelegateGroupMember> getDelegateGroupMembers() {
        List<SYS_DelegateGroupService.DelegateGroupMember> dgms = new List<SYS_DelegateGroupService.DelegateGroupMember>();
        HttpResponse response = SYS_ToolingAPIService.getDelegateGroupMembers();

        if (response != null && response.getStatusCode() == 200) {
            String responseBody = response.getBody();
            DelegateGroupMemberResponse dgmr = (DelegateGroupMemberResponse) JSON.deserialize(responseBody, DelegateGroupMemberResponse.class);
            if (dgmr.records != null && !dgmr.records.isEmpty()) {
                dgms = dgmr.records;
            }
        }

        return dgms;
    }

    /**
     * Inner class to deserialize response for DelegateGroups.
     */
    public class DelegateGroupResponse {
        public Integer size;
        public Integer totalSize;
        public Boolean done;
        public String queryLocator;
        public String entityTypeName;
        public List<SYS_DelegateGroupService.DelegateGroup> records;
    }

    /**
     * Inner class to deserialize response for DelegateGroupMembers.
     */
    public class DelegateGroupMemberResponse {
        public Integer size;
        public Integer totalSize;
        public Boolean done;
        public String queryLocator;
        public String entityTypeName;
        public List<SYS_DelegateGroupService.DelegateGroupMember> records;
    }
}
