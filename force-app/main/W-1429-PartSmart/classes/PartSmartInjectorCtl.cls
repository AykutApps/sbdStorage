global class PartSmartInjectorCtl {
    public String scriptUrl { get; private set; }
    public String loggedInUser { get; private set; }
    
    private TokenResponse tokenResponse { get; private set; }
    private TokenResponse tokenPortalUserResponse { get; private set; }

    public static Id dealerAccountId;
    private static Webcart wc;
    private static String ownerId;
    private static String storeId;
    private static Map<String, Product2> productCodeProductMapByCartItems;
    private static PartRequest part;
    private static final String DEFAULT_CART_NAME = 'PartSmart';
    private static final String B2B_DEALER_COMMUNITY_NAME = 'B2B Dealer Community';
    private static Id loggedInUserId;

    public PartSmartInjectorCtl() {
        scriptUrl = getScriptUrl();
        loggedInUser = UserInfo.getName();
        loggedInUserId = UserInfo.getUserId();
    }

    public String getScriptUrl() {
        String authenticateResponse = authenticate();
        String scriptUrl;
        if (String.isBlank(authenticateResponse)) {
            scriptUrl = null;
        } else {
            tokenResponse = (TokenResponse) JSON.deserialize(authenticateResponse, TokenResponse.class);
            tokenPortalUserResponse = (TokenResponse) JSON.deserialize(authenticatePortalUserToken(tokenResponse), TokenResponse.class);
            scriptUrl =
                Integration_Variable__mdt.getInstance('PartSmart_Script_Base_URL').Value__c +
                '?access_token=' +
                EncodingUtil.urlEncode(tokenPortalUserResponse.access_token, 'UTF-8') +
                '&refresh_token=' +
                EncodingUtil.urlEncode(tokenPortalUserResponse.refresh_token, 'UTF-8') +
                '&expires_in=' +
                tokenPortalUserResponse.expires_in;
        }

        return scriptUrl;
    }

    public static String authenticate() {
        // Prepare HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:PartSmart_API_Auth/Account/Authenticate');
        req.setMethod('POST');
        req.setHeader('accept', 'application/json');
        req.setHeader('Content-Type', 'application/json-patch+json');

        // JSON body
        String body = '{"username": "' + '{!$Credential.Username}' + '", "password": "' + '{!$Credential.Password}' + '"}';
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

    private static String authenticatePortalUserToken(TokenResponse tokenResponse) {
        // Endpoint URL
        String endpoint = Integration_Variable__mdt.getInstance('PartSmart_User_Auth_Endpoint').Value__c;

        // Prepare HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('accept', 'application/json');
        req.setHeader('Content-Type', 'application/json-patch+json');
        req.setHeader('Authorization', 'Bearer ' + tokenResponse.access_token);

        // JSON body with the specified parameters
        User usr = [
            SELECT FirstName, LastName, Contact.Email, Contact.Account.Name,Contact.Account.BillingStreet, Contact.Account.BillingCity,
                Contact.Account.BillingPostalCode, Contact.Account.BillingCountry,Contact.Account.Entity_ID__c,
                Contact.Account.BillingState,Contact.Phone 
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        String body;

        if(usr.Contact == null ||usr.Contact.Account == null){
            body = '{"username": "' + UserInfo.getName() + '",'+
                    ' "email": "' + UserInfo.getUserEmail() + '",'+
                    ' "businessName": "Test Aykut Dealer",'+
                    ' "groupCode": "USIRX"}';
        } else {
            body = '{"username": "' + UserInfo.getName() + '",'+
                    ' "email": "' + UserInfo.getUserEmail() + '",'+
                    ' "firstName": "' +usr.FirstName + '",' +
                    ' "lastName": "' +usr.LastName + '",' +
                    ' "phone": "' +usr.Contact.Phone + '",' +
                    ' "businessName": "' +usr.Contact.Account.Name + '",' +
                    ' "streetAddress": "' +usr.Contact.Account.BillingStreet + '",' +
                    ' "city": "' +usr.Contact.Account.BillingCity + '",' +
                    ' "postalCode": "' +usr.Contact.Account.BillingPostalCode + '",' +
                    ' "stateProvince": "' +usr.Contact.Account.BillingState + '",' +
                    ' "country": "' +usr.Contact.Account.BillingCountry + '",' +
                    ' "dealerId": "' +usr.Contact.Account.Entity_ID__c + '",' +
                    ' "groupCode": "USIRX"}';
        }

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
        part = (PartRequest) System.JSON.deserialize(jsonString, PartRequest.class);
        String addToCartResult = addPartsToCart();
        return addToCartResult;
    }

    private static String addPartsToCart() {
        User owner;
        String response = '';
        loggedInUserId = UserInfo.getUserId();
        try {
            // query dealer account
            queryDealerAccountId();

            // query owner id
            queryOwnerId();

            // query owner id
            queryStoreId();

            // query or create Webcart
            queryOrCreateWebcart();

            // get product code map
            getProductCodeProductMapByCartItems();

            // insert the cart items
            addCartItems();
            
            response = 'Success';
        } catch (Exception e) {
            response = e.getMessage();
        }
        return response;
    }



    private static void queryDealerAccountId() {
        if(dealerAccountId != null) return;
        
        User[] loggedInUserDealers = [SELECT Id, Contact.Id, Contact.AccountId from User WHERE Id =:loggedInUserId];
        if(loggedInUserDealers.size() == 1){
            if(loggedInUserDealers[0].Contact.AccountId != null){
                dealerAccountId = loggedInUserDealers[0].Contact.AccountId;
            } else {
                throw new CustomException('There is no dealer account found for userId: '+ loggedInUserId);
            }
        } else {
            throw new CustomException('There is no user found for userId: '+ loggedInUserId);
        }
    }

    private static void queryOrCreateWebcart() {
        Webcart[] wcs = [SELECT Id, Is_PartSmart__c FROM Webcart WHERE Is_PartSmart__c = TRUE AND Status = 'Active' AND AccountId = :dealerAccountId LIMIT 1];

        if (!wcs.isEmpty()) {
            wc = wcs[0];
        } else {
            ConnectApi.CartInput cartInput = new ConnectApi.CartInput();
            cartInput.effectiveAccountId = dealerAccountId;
            cartInput.isSecondary = true;
            cartInput.name = DEFAULT_CART_NAME;
            cartInput.type = ConnectApi.CartType.Cart;
            ConnectApi.CartSummary cs = ConnectApi.CommerceCart.createCart(storeId, cartInput);

            if (cs != null && cs.cartId != null) {
                wc = new Webcart();
                wc.Id = cs.cartId;
                wc.Is_PartSmart__c = true;
                wc.B2B_Product_Type__c = 'Parts';
                wc.OwnerId = ownerId;
                update wc;
            } else {
                throw new CustomException('Failed to create a new cart.');
            }
        }
    }

    private static void queryOwnerId() {
        // Owner Assignment
        List<User> potentialsOwners = [
            SELECT Id
            FROM User
            WHERE isActive = TRUE AND Contact.Account.Id = :dealerAccountId
            ORDER BY Contact.Primary_Account_Contact__c DESC NULLS LAST
            LIMIT 1
        ];

        if (potentialsOwners.isEmpty()) {
            ownerId = UserInfo.getUserId();
        } else {
            ownerId = potentialsOwners[0].Id;
        }
    }

    private static void queryStoreId() {
        storeId = [SELECT Id FROM WebStore WHERE Name = :B2B_DEALER_COMMUNITY_NAME LIMIT 1]?.Id;
        if (storeId == null) {
            throw new CustomException('Deafult store is not found.');
        }
    }

    private static void getProductCodeProductMapByCartItems() {
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

        productCodeProductMapByCartItems = productMap;
    }

    private static void addCartItems() {
        String[] addCartItemErrors = new List<String>();
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
        for (Arg arg : part.params.args) {
            Product2 product = productCodeProductMapByCartItems.get(arg.sku);
            if (product == null) {
                throw new CustomException('Error: Can not add ' + arg.sku + ' to your draft order. Item can not be found in the community.');
            }
            ConnectApi.CartItemInput cartItemInput = new ConnectApi.CartItemInput();
            cartItemInput.productId = productCodeProductMapByCartItems.get(arg.sku)?.Id;
            cartItemInput.quantity = String.valueof(arg.qty);
            cartItemInput.type = ConnectApi.CartItemType.PRODUCT;
            batchInputs.add(new ConnectApi.BatchInput(cartItemInput));
        }
        system.debug('add item to cart');
        ConnectApi.BatchResult[] brs = ConnectApi.CommerceCart.addItemsToCart(storeId, dealerAccountId, wc.Id, batchInputs);
        String[] itemErrorMessages = new List<String>();
        for (ConnectApi.BatchResult br  :brs){
            system.debug(br);
            if (!br.isSuccess) {
                itemErrorMessages.add(br.getErrorMessage());
            }
        }
        if(!itemErrorMessages.isEmpty()){
            throw new CustomException(JSON.serialize(itemErrorMessages));
        }
        
    }

    public class TokenResponse {
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

        '{
            "username": "' + UserInfo.getName() + '", 
            "email": "' + UserInfo.getUserEmail() + '", 
            "businessName": "Test Aykut Dealer", 
            "groupCode": "USIR"
        }';

            @AuraEnabled(cacheable=false)
                public static List<CartItem> getWebcartItems() {
                // Query for the Account Name and Email fields
                return [SELECT Id, Name, Quantity, Product2Id, Product2.Description FROM CartItem WHERE Cart.Is_PartSmart__c = TRUE AND Cart.AccountId = :defaultTestDealerAccountId];
            }   

    */

