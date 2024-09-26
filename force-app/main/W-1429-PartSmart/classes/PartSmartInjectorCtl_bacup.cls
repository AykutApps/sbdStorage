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
    private static final String B2B_DEALER_COMMUNITY_NAME = 'SBD Outdoor Commerce'; // DEVONE, DEMO = B2B Dealer Community
    private static Id loggedInUserId;

    private static String response;

    // Error handling
    public enum FriendlyMessages {
        INACTIVE_ITEM,
        MISSING_ITEM,
        ITEM_NLA,
        ITEM_REPLACED,
        BASE_ITEM,
        INACTIVE_ITEM_REPLACEMENT,
        ITEM_NLA_REPLACEMENT,
        BASE_ITEM_REPLACEMENT,
        GENERAL_ERROR
    }

    private static Map<FriendlyMessages, String> messageMap = new Map<FriendlyMessages, String>{
        FriendlyMessages.INACTIVE_ITEM => 'The product is inactive: ',
        FriendlyMessages.MISSING_ITEM => 'Item cannot be found in community. Cannot add to your draft order: ',
        FriendlyMessages.ITEM_NLA => 'Please search for another part number. Item is no longer available: ',
        FriendlyMessages.ITEM_REPLACED => 'This SKU have been replaced: ',
        FriendlyMessages.BASE_ITEM => 'Please add the appropriate color/variant SKU. Cannot add BASE SKU to your draft order: ',
        FriendlyMessages.INACTIVE_ITEM_REPLACEMENT => 'The replacement product for {0} is inactive: {1}',
        // The replacement product for <OriginalProductCode> is inactive: <ReplacementProductCode>
        FriendlyMessages.ITEM_NLA_REPLACEMENT => 'Please search for another part number. Replacement for {0} is no longer available: {1}',
        FriendlyMessages.BASE_ITEM_REPLACEMENT => 'Please add the appropriate color/variant SKU. Cannot add replacement for {0} BASE SKU to your draft order: {1}',
        FriendlyMessages.GENERAL_ERROR => 'An error occurred, and item(s) cannot be added to your draft order: '
    };

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
            SELECT
                FirstName,
                LastName,
                Contact.Email,
                Contact.Account.Name,
                Contact.Account.BillingStreet,
                Contact.Account.BillingCity,
                Contact.Account.BillingPostalCode,
                Contact.Account.BillingCountry,
                Contact.Account.Entity_ID__c,
                Contact.Account.BillingState,
                Contact.Phone
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        String body;

        if (usr.Contact == null || usr.Contact.Account == null) {
            body = '{"username": "' + UserInfo.getName() + '",' + ' "email": "' + UserInfo.getUserEmail() + '",' + ' "businessName": "Test Dealer",' + ' "groupCode": "USIRX"}';
        } else {
            body =
                '{"username": "' +
                UserInfo.getName() +
                '",' +
                ' "email": "' +
                UserInfo.getUserEmail() +
                '",' +
                ' "firstName": "' +
                usr.FirstName +
                '",' +
                ' "lastName": "' +
                usr.LastName +
                '",' +
                ' "phone": "' +
                usr.Contact.Phone +
                '",' +
                ' "businessName": "' +
                usr.Contact.Account.Name +
                '",' +
                ' "streetAddress": "' +
                usr.Contact.Account.BillingStreet +
                '",' +
                ' "city": "' +
                usr.Contact.Account.BillingCity +
                '",' +
                ' "postalCode": "' +
                usr.Contact.Account.BillingPostalCode +
                '",' +
                ' "stateProvince": "' +
                usr.Contact.Account.BillingState +
                '",' +
                ' "country": "' +
                usr.Contact.Account.BillingCountry +
                '",' +
                ' "dealerId": "' +
                usr.Contact.Account.Entity_ID__c +
                '",' +
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
        try {
            part = (PartRequest) System.JSON.deserialize(jsonString, PartRequest.class);
            String addToCartResult = addPartsToCart();
            return addToCartResult;
        } catch (Exception e) {
            return e.getMessage();
        }
    }

    private static String addPartsToCart() {
        User owner;
        loggedInUserId = UserInfo.getUserId();
        response = '';
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

            response = (String.isBlank(response)) ? 'Success' : response;
        } catch (Exception e) {
            response = e.getMessage();
        }
        return response;
    }

    private static void queryDealerAccountId() {
        if (dealerAccountId != null)
            return;

        User[] loggedInUserDealers = [SELECT Id, Contact.Id, Contact.AccountId FROM User WHERE Id = :loggedInUserId];
        if (loggedInUserDealers.size() == 1) {
            if (loggedInUserDealers[0].Contact.AccountId != null) {
                dealerAccountId = loggedInUserDealers[0].Contact.AccountId;
            } else {
                throw new CustomException('There is no dealer account found for userId: ' + loggedInUserId);
            }
        } else {
            throw new CustomException('There is no user found for userId: ' + loggedInUserId);
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
            SELECT
                Id,
                ProductCode,
                Detail_SKU__c,
                Name,
                B2B_no_longer_available__c,
                Description,
                isActive,
                B2B_Replacement_Product__c,
                B2B_Replacement_Product__r.ProductCode,
                B2B_Replacement_Product__r.isActive,
                B2B_Replacement_Product__r.B2B_no_longer_available__c,
                B2B_Replacement_Product__r.Is_Base_Part__c,
                Is_Base_Part__c /* Add more fields as needed */
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
                throw new CustomException(messageMap.get(FriendlyMessages.MISSING_ITEM) + arg.sku);
            } else if (!product.isActive) {
                throw new CustomException(messageMap.get(FriendlyMessages.INACTIVE_ITEM) + arg.sku);
            } else if (product.B2B_no_longer_available__c) {
                throw new CustomException(messageMap.get(FriendlyMessages.ITEM_NLA) + arg.sku);
            } else if (product.Is_Base_Part__c == true) {
                throw new CustomException(messageMap.get(FriendlyMessages.BASE_ITEM) + arg.sku);
            } else if (product.B2B_Replacement_Product__c != null) {
                if (product.B2B_Replacement_Product__r.isActive == false) {
                    throw new CustomException(
                        String.format(
                            messageMap.get(FriendlyMessages.INACTIVE_ITEM_REPLACEMENT),
                            new List<String>{ product.ProductCode, product.B2B_Replacement_Product__r.ProductCode }
                        )
                    );
                } else if (product.B2B_Replacement_Product__r.B2B_no_longer_available__c) {
                    throw new CustomException(
                        String.format(
                            messageMap.get(FriendlyMessages.ITEM_NLA_REPLACEMENT),
                            new List<String>{ product.ProductCode, product.B2B_Replacement_Product__r.ProductCode }
                        )
                    );
                } else if (product.B2B_Replacement_Product__r.Is_Base_Part__c) {
                    throw new CustomException(
                        String.format(
                            messageMap.get(FriendlyMessages.BASE_ITEM_REPLACEMENT),
                            new List<String>{ product.ProductCode, product.B2B_Replacement_Product__r.ProductCode }
                        )
                    );
                } else {
                    response = 'Success! \n Info: ' + messageMap.get(FriendlyMessages.ITEM_REPLACED) + arg.sku + ' by ' + product.B2B_Replacement_Product__r.ProductCode;
                    ConnectApi.CartItemInput cartItemInput = new ConnectApi.CartItemInput();
                    cartItemInput.productId = product.B2B_Replacement_Product__c;
                    cartItemInput.quantity = String.valueof(arg.qty);
                    cartItemInput.type = ConnectApi.CartItemType.PRODUCT;
                    batchInputs.add(new ConnectApi.BatchInput(cartItemInput));
                }
            } else {
                ConnectApi.CartItemInput cartItemInput = new ConnectApi.CartItemInput();
                cartItemInput.productId = productCodeProductMapByCartItems.get(arg.sku)?.Id;
                cartItemInput.quantity = String.valueof(arg.qty);
                cartItemInput.type = ConnectApi.CartItemType.PRODUCT;
                batchInputs.add(new ConnectApi.BatchInput(cartItemInput));
            }
        }
        system.debug('add item to cart');
        ConnectApi.BatchResult[] brs = ConnectApi.CommerceCart.addItemsToCart(storeId, dealerAccountId, wc.Id, batchInputs);
        String[] itemErrorMessages = new List<String>();
        for (ConnectApi.BatchResult br : brs) {
            system.debug(br);
            if (!br.isSuccess) {
                itemErrorMessages.add(br.getErrorMessage());
            }
        }
        if (!itemErrorMessages.isEmpty()) {
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
