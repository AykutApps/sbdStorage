/**
 * Helper class for making callouts to the Salesforce Tooling API.
 * Author: aykut.parlak@bsdinc.com
 * Created Date: 2023-11-12
 */
public without sharing class SYS_ToolingAPIServiceHelper {
    private static final String DEFAULT_API_VERSION = 'v58.0';
    private static final String BASE_URL = URL.getOrgDomainURL().toExternalForm() + '/services/data/';
    private final String apiVersion;

    /**
     * Constructor using the default or specified API version.
     * @param apiVersion Optional API version to use for the callout. Uses default if not specified.
     */
    public SYS_ToolingAPIServiceHelper(String apiVersion) {
        this.apiVersion = String.isBlank(apiVersion) ? DEFAULT_API_VERSION : apiVersion;
    }

    /**
     * Overloaded constructor using the DEFAULT_API_VERSION.
     */
    public SYS_ToolingAPIServiceHelper() {
        this(null);
    }

    /**
     * Retrieves query results from the Tooling API.
     * @param query The SOQL query to be executed.
     * @return HttpResponse The response from the Tooling API.
     */
    public HttpResponse retrieveQueryResults(String query) {
        String endpoint = '/tooling/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8');
        return callToolingAPI('GET', endpoint, null);
    }

    /**
     * Makes a callout to the Tooling API.
     * @param method The HTTP method to use.
     * @param endpoint The endpoint of the Tooling API to call.
     * @param payload The payload to send with the request (for POST methods).
     * @return HttpResponse The response from the Tooling API or null in case of an exception.
     */
    public HttpResponse callToolingAPI(String method, String endpoint, String payload) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(BASE_URL + this.apiVersion + endpoint);
        request.setMethod(method);

        if ('POST'.equals(method) && payload != null) {
            request.setBody(payload);
            request.setHeader('Content-Type', 'application/json');
        }

        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

        try {
            Http http = new Http();
            return http.send(request);
        } catch (Exception e) {
            SystemLogHelper.insertSystemLog('SYS_ToolingAPIServiceHelper', 'Error on Tooling API Call!', e);
            return null;
        }
    }
}
