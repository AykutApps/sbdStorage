public without sharing class SYS_ToolingAPIServiceHelper {
    private static final String DEFAULT_API_VERSION = 'v58.0';
    private static final String BASE_URL = URL.getOrgDomainURL().toExternalForm() + '/services/data/';
    private String apiVersion;

    /**
     * Default constructor using the DEFAULT_API_VERSION.
     */
    public SYS_ToolingAPIServiceHelper() {
        this.apiVersion = DEFAULT_API_VERSION;
    }

    /**
     * Constructor that accepts a specific API version.
     * @param apiVersion The API version to use for the callout.
     */
    public SYS_ToolingAPIServiceHelper(String apiVersion) {
        this.apiVersion = String.isBlank(apiVersion) ? DEFAULT_API_VERSION : apiVersion;
    }

    /**
     * Method to retrieve query results from the Tooling API.
     * @param query The SOQL query to be executed.
     * @return HttpResponse The response from the Tooling API.
     */
    public HttpResponse retrieveQueryResults(String query) {
        String endpoint = '/tooling/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8');
        HttpResponse response = callToolingAPI('GET', endpoint, null);
        return response;
    }

    /**
     * Makes a callout to the Tooling API.
     * @param method The HTTP method to use.
     * @param endpoint The endpoint of the Tooling API to call.
     * @param payload The payload to send with the request (for POST methods).
     * @return HttpResponse The response from the Tooling API.
     */
    private HttpResponse callToolingAPI(String method, String endpoint, String payload) {
        String url = BASE_URL + this.apiVersion + endpoint;
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod(method);

        if ('POST'.equals(method)) {
            request.setBody(payload);
            request.setHeader('Content-Type', 'application/json');
        }

        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

        try {
            Http http = new Http();
            return http.send(request);
        } catch (Exception e) {
            // Handle exception appropriately - could log the error or throw a custom exception
            System.debug('Error in callToolingAPI: ' + e.getMessage());
            return null;
        }
    }
}
