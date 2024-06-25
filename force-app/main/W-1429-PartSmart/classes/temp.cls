global class PartSmartInjectorCtl {
    public String scriptUrl { get; private set; }
    public String loggedInUser { get; private set; }
    private Id loggedInUserId;
    public tokenIntegrationUserResponse tokenIntegrationUserResponse { get; private set; }
    public tokenIntegrationUserResponse tokenPortalUserResponse { get; private set; }

    public PartSmartInjectorCtl() {
        scriptUrl = getScriptUrl();
        loggedInUser = UserInfo.getName();
        loggedInUserId = UserInfo.getUserId();
    }

    public static String getScriptUrl() {
        String authenticateResponse = authenticate();
        String scriptUrl;
        if (String.isBlank(authenticateResponse)) {
            scriptUrl = null;
        } else {
            tokenIntegrationUserResponse = (tokenIntegrationUserResponse) JSON.deserialize(authenticateResponse, tokenIntegrationUserResponse.class);
            tokenPortalUserResponse = (tokenIntegrationUserResponse) JSON.deserialize(
                authenticatePortalUserToken(tokenIntegrationUserResponse),
                tokenIntegrationUserResponse.class
            );
            scriptUrl =
                Integration_Variable__mdt.getInstance('PartSmart_Script_Base_URL').Value__c +
                '?access_token=' +
                EncodingUtil.urlEncode(tokenIntegrationUserResponse.access_token, 'UTF-8') +
                '&refresh_token=' +
                EncodingUtil.urlEncode(tokenIntegrationUserResponse.refresh_token, 'UTF-8') +
                '&expires_in=' +
                tokenIntegrationUserResponse.expires_in;
        }
        return scriptUrl;
    }

    private static String authenticate() {
        // Endpoint URL
        String endpoint = Integration_Variable__mdt.getInstance('PartSmart_Authentication_Endpoint').Value__c;

        // Prepare HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('accept', 'application/json');
        req.setHeader('Content-Type', 'application/json-patch+json');

        // JSON body
        String body =
            '{"username": "' +
            Integration_Variable__mdt.getInstance('PartSmart_Username').Value__c +
            '", "password": "' +
            Integration_Variable__mdt.getInstance('PartSmart_Password').Value__c +
            '"}';
        req.setBody(body);

        // Send HTTP request
        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);

            // Check for a successful response
            if (res.getStatusCode() == 200) {
                // Process the response body as needed
                return res.getBody();
            } else {
                // Handle errors or unsuccessful responses
                System.debug('Error from PartSmart API: ' + res.getBody());
                return null;
            }
        } catch (Exception e) {
            System.debug('Error calling PartSmart API: ' + e.getMessage());
            return null;
        }
    }

    private static String authenticatePortalUserToken(tokenIntegrationUserResponse tokenIntegrationUserResponse) {
        // Endpoint URL
        String endpoint = Integration_Variable__mdt.getInstance('PartSmart_User_Auth_Endpoint').Value__c;

        // Prepare HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('accept', 'application/json');
        req.setHeader('Content-Type', 'application/json-patch+json');
        req.setHeader('Authorization', 'Bearer ' + tokenIntegrationUserResponse.access_token);

        // JSON body with the specified parameters
        String body = '{"username": "' + UserInfo.getName() + '", "email": "' + UserInfo.getUserEmail() + '", "businessName": "Test Aykut Dealer", "groupCode": "USIR"}';
        req.setBody(body);

        // Send HTTP request
        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);

            // Check for a successful response
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                // Process the response body as needed
                return res.getBody();
            } else {
                // Handle errors or unsuccessful responses
                System.debug('Error from PartSmart Portal User API: ' + res.getBody());
                return null;
            }
        } catch (Exception e) {
            // Handle connection or other errors
            System.debug('Error from PartSmart Portal User API:' + e.getMessage());
            return null;
        }
    }

    @RemoteAction
    global static String addToCart(String jsonString) {
        PartRequest part = (PartRequest) System.JSON.deserialize(jsonString, PartRequest.class);
        String addToCartResult = addPartsToCart(part);
        return addToCartResult;
    }

    private static String addPartsToCart(PartRequest part) {
        Id accountId = '001Dh00001JoOEIIA3'; // Defualt Account Id
        String storeId;
        Webcart wc;
        User owner;
        String ownerId;
        String defaultCartName = 'PartSmart';
        Boolean isPrimary = false;
        String cartName = 'PartSmart POC';
        String response = '';
        try {
            Account acc = [SELECT Id FROM Account WHERE Id = :accountId];

            // Query Webcart based on Name and AccountId
            Webcart[] wcs = [SELECT Id FROM Webcart WHERE Is_PartSmart__c = TRUE AND Status = 'Active' AND AccountId = :acc.Id];

            // Store Id
            storeId = [SELECT Id FROM WebStore LIMIT 1].Id; // name = 'B2B Dealer Community'

            // Owner Assignment
            List<User> potentialsOwners = [
                SELECT Id
                FROM User
                WHERE isActive = TRUE AND Contact.Account.Id = :accountId
                ORDER BY Contact.Primary_Account_Contact__c DESC NULLS LAST
                LIMIT 1
            ];

            if (potentialsOwners.isEmpty()) {
                ownerId = UserInfo.getUserId();
            } else {
                ownerId = potentialsOwners[0].Id;
            }

            if (wcs.size() > 0) {
                wc = wcs[0];
            } else {
                // Create a new cart if it doesn't exist
                ConnectApi.CartInput cartInput = new ConnectApi.CartInput();
                cartInput.effectiveAccountId = acc.Id;
                cartInput.isSecondary = !isPrimary; // Siva to ask, Diane wants to become active card
                cartInput.name = cartName; // Documoto is default
                cartInput.type = ConnectApi.CartType.Cart;
                ConnectApi.CartSummary cs = ConnectApi.CommerceCart.createCart(storeId, cartInput);
                // wc = [SELECT Id FROM Webcart WHERE Name = :cartItemRequest.name AND Is_Documoto__c =  true AND AccountId = :acc.Id LIMIT 1];
                wc = [SELECT Id, Name FROM Webcart WHERE Id = :cs.cartId];
                wc.Is_PartSmart__c = true;
                wc.OwnerId = ownerId;
                update wc;
            }

            Map<String, Product2> productCodeProductMapByCartItems = getProductCodeProductMapByCartItems(part);

            // Prepare batch inputs for adding items to the cart
            List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
            for (Arg arg : part.params.args) {
                Product2 product = productCodeProductMapByCartItems.get(arg.sku);
                if (product == null) {
                    throw new CustomException('There is no prodcut with the sku: ' + arg.sku);
                }
                ConnectApi.CartItemInput cartItemInput = new ConnectApi.CartItemInput();
                cartItemInput.productId = productCodeProductMapByCartItems.get(arg.sku)?.Id;
                cartItemInput.quantity = String.valueof(arg.qty);
                cartItemInput.type = ConnectApi.CartItemType.PRODUCT;
                batchInputs.add(new ConnectApi.BatchInput(cartItemInput));
            }
            ConnectApi.CommerceCart.addItemsToCart(storeId, acc.Id, wc.Id, batchInputs);
            response = 'Success';
        } catch (Exception e) {
            response = 'Error: ' + e.getMessage();
        }
        return response;
    }

    private static Map<String, Product2> getProductCodeProductMapByCartItems(PartRequest part) {
        Map<String, Product2> productMap = new Map<String, Product2>();
        List<String> productCodes = new List<String>();

        // Collect all unique product codes from the cart items
        for (Arg arg : part.params.args) {
            if (String.isNotBlank(arg.sku)) {
                productCodes.add(arg.sku);
            }
        }

        // Query product records based on the collected product codes
        List<Product2> products = [
            SELECT Id, ProductCode, Detail_SKU__c, Name, Description /* Add more fields as needed */
            FROM Product2
            WHERE ProductCode IN :productCodes
        ];

        // Populate the map with product code as the key and product record as the value
        for (Product2 product : products) {
            productMap.put(product.ProductCode, product);
        }

        return productMap;
    }

    @AuraEnabled(cacheable=false)
    public static List<CartItem> getWebcartItems() {
        // Query for the Account Name and Email fields
        return [SELECT Id, Name, Quantity FROM CartItem WHERE Cart.Is_PartSmart__c = TRUE];
    }

    public class tokenIntegrationUserResponse {
        public String access_token;
        public String refresh_token;
        public Integer expires_in;
    }

    public class PartRequest {
        public Integer id;
        public String method;
        public Params params;
    }

    public class Params {
        public String method;
        public List<Arg> args;
    }

    public class Arg {
        public String sku;
        public String brandCode;
        public String brandName;
        public Integer qty;
        public String userName;
        public String langCode;
        public String catalogLang;
    }

    public class CustomException extends Exception {
    }
}

/*
{"Username":"06005","Email":"rvi.dealer@mtdproducts.com","BusinessName":"RVI TEST DEALER","GroupCode":"CAMTDX","FirstName":"RVI","LastName":"TEST DEALER","Phone":"3305587400","StreetAddress":"5903 GRAFTON RD.","City":"VALLEY CITY","StateProvince":"OH","PostalCode":"44280","Country":"US","DealerId":""}
Username: where to get it
GroupCode: CAMTDX
*/

/*
        {
            "username": "string",
            "email": "user@example.com",
            "businessName": "string",
            "groupCode": "string",
            "firstName": "string",
            "lastName": "string",
            "phone": "string",
            "streetAddress": "string",
            "city": "string",
            "stateProvince": "string",
            "postalCode": "string",
            "country": "string",
            "dealerId": "string"
        }
    */

