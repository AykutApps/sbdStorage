public with sharing class SYS_ToolingAPIService {
    public SYS_ToolingAPIService() {
    }

    public static Httpresponse getDelegateGroups() {
        SYS_ToolingAPIServiceHelper tash = new SYS_ToolingAPIServiceHelper();
        Httpresponse response = tash.retrieveQueryResults('SELECT Id, Name, DeveloperName FROM DelegateGroup');
        return response;
    }

    public static Httpresponse getDelegateGroupMembers() {
        SYS_ToolingAPIServiceHelper tash = new SYS_ToolingAPIServiceHelper();
        Httpresponse response = tash.retrieveQueryResults('SELECT Id, DelegateGroupId, UserOrGroupId FROM DelegateGroupMember');
        return response;
    }
}
