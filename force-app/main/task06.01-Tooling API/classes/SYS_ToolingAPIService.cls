/**
 * SYS_ToolingAPIService class to handle operations related to Tooling API.
 * Author: aykut.parlak@bsdinc.com
 * Created Date: 2023-11-12
 */
public with sharing class SYS_ToolingAPIService {
    /**
     * Retrieves DelegateGroups from the Tooling API.
     * @return HttpResponse containing the response from the Tooling API.
     */
    public static HttpResponse getDelegateGroups() {
        SYS_ToolingAPIServiceHelper tash = new SYS_ToolingAPIServiceHelper();
        HttpResponse response = tash.retrieveQueryResults('SELECT Id, Name, DeveloperName FROM DelegateGroup');
        return response;
    }

    /**
     * Retrieves DelegateGroupMembers from the Tooling API.
     * @return HttpResponse containing the response from the Tooling API.
     */
    public static HttpResponse getDelegateGroupMembers() {
        SYS_ToolingAPIServiceHelper tash = new SYS_ToolingAPIServiceHelper();
        HttpResponse response = tash.retrieveQueryResults('SELECT Id, DelegateGroupId, UserOrGroupId FROM DelegateGroupMember');
        return response;
    }
}
