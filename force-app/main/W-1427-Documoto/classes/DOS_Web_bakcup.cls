@RestResource(urlMapping='/documoto-support-service/create-web-order')
global class DOS_WebcardRestService implements RESTHostedMTDEndpoint {
    // Member properties
    global static RESTHostedMTDEndpointHelper endpointHelper;
    private static final String PAYLOAD_TYPE = 'documoto-support-service/create-web-order';
    private static final String BASE_REST_ENDPOINT = '/documoto-support-service/create-web-order';
    private static final Integer MIN_PAYLOAD_SIZE = 44;
    private static final Integer MAX_PAYLOAD_FIELD_SIZE = 5000;
    private static final Integer MAX_PAYLOAD_SIZE = MAX_PAYLOAD_FIELD_SIZE;
    private static final String BASE_SOBJECT_API_NAME = 'WebCart';
    // private static final String SITE_NAME = 'B2B_Dealer_Store1';
    private static final String SITE_NAME = 'SBD_Outdoor_Commerce';

    private static List<String> errs = new List<String>();
    private static List<String> missingProducts = new List<String>();
    private static Webcart wc;
    public static Response2 response;
    private static String storeId;
    private static CartItemRequest cartItemRequest;
    private static Account dealerAccount;
    private static String ownerId;
    private static String siteDomain;
    private static Boolean isPrimary = false;

    private static final String DEFAULT_CART_NAME = 'Documoto';
    // private static final String B2B_DEALER_COMMUNITY_NAME = 'B2B Dealer Community';
    private static final String B2B_DEALER_COMMUNITY_NAME = 'SBD Outdoor Commerce';

    // Error handling
    public enum FriendlyMessages {
        INACTIVE_ITEM,
        MISSING_ITEM,
        ITEM_NLA,
        ITEM_REPLACED,
        BASE_ITEM,
        GENERAL_ERROR
    }

    private static Map<FriendlyMessages, String> messageMap = new Map<FriendlyMessages, String>{
        FriendlyMessages.INACTIVE_ITEM => 'The product is inactive: ',
        FriendlyMessages.MISSING_ITEM => 'Item cannot be found in community. Cannot add to your draft order: ',
        FriendlyMessages.ITEM_NLA => 'Please search for another part number. Item is no longer available: ',
        FriendlyMessages.ITEM_REPLACED => 'This SKU have been replaced: ',
        FriendlyMessages.BASE_ITEM => 'Please add the appropriate color/variant SKU. Cannot add BASE SKU to your draft order: ',
        FriendlyMessages.GENERAL_ERROR => 'An error occurred, and item(s) cannot be added to your draft order: '
    };

    private static Set<String> inactiveItems = new Set<String>();
    private static Set<String> missingItems = new Set<String>();
    private static Set<String> nlaItems = new Set<String>();
    private static Set<String> replacedItems = new Set<String>();
    private static Set<String> baseItems = new Set<String>();

    // Implement Inmterface
    global static String getPayloadType() {
        fetchEndpointHelper();
        return endpointHelper.payloadType;
    }

    global static String getBaseRESTEndpoint() {
        fetchEndpointHelper();
        return endpointHelper.baseRESTEndpoint;
    }

    global static Integer getMinPayloadSize() {
        fetchEndpointHelper();
        return endpointHelper.minPayloadSize;
    }

    global static Integer getMaxPayloadSize() {
        fetchEndpointHelper();
        return endpointHelper.maxPayloadSize;
    }

    global static Integer getMaxPayloadFieldSize() {
        return MAX_PAYLOAD_FIELD_SIZE;
    }

    global static String getBaseSObjectAPIName() {
        fetchEndpointHelper();
        return endpointHelper.baseSObjectAPIName;
    }

    public static void fetchEndpointHelper() {
        if (endpointHelper == null) {
            endpointHelper = new RESTHostedMTDEndpointHelper(PAYLOAD_TYPE, BASE_REST_ENDPOINT, MIN_PAYLOAD_SIZE, MAX_PAYLOAD_SIZE, BASE_SOBJECT_API_NAME);
        }
    }

    // Main method
    @HTTPPost
    global static Response2 doPost() {
        handlePostRequest();
        return response;
    }

    private static Response2 handlePostRequest() {
        try {
            // Log Request
            logRequest();
            // Deserialize the request body into CartItemRequest
            parseRequest();
            // query the dealer account
            queryDealerAccount();
            // Store Id
            queryStoreId();
            // Owner Assignment
            queryOwner();
            // Query Webcart based on Name and AccountId
            queryOrCreateWebcart();
            // add cart items
            addCartItems();
            // get the site domain
            querySiteDomain();
        } catch (Exception ex) {
            errs.add(ex.getMessage());
        }

        // generate response
        generateResponse();
        // Log Response
        logResponse();
        return response;
    }

    private static void parseRequest() {
        cartItemRequest = (CartItemRequest) JSON.deserialize(RestContext.request.requestBody.toString(), CartItemRequest.class);
    }

    private static void queryDealerAccount() {
        // Declare a variable for the account number to be queried
        String accountNumber = null;

        // Determine the relevant account number based on input
        if (!String.isBlank(cartItemRequest.hustlerPartsAccountNumber)) {
            accountNumber = cartItemRequest.hustlerPartsAccountNumber;
        } else if (!String.isBlank(cartItemRequest.bigDogPartsAccountNumber)) {
            accountNumber = cartItemRequest.bigDogPartsAccountNumber;
        }

        // Throw an exception if no account number is provided
        if (accountNumber == null) {
            throw new CustomException('Account number is missing.');
        }

        // Perform the query using the determined account number
        List<Account> accounts = [
            SELECT Id
            FROM Account
            WHERE Hustler_Parts_Account__c = :accountNumber OR BigDog_Parts_Account__c = :accountNumber
            LIMIT 1
        ];

        // Check if any account was returned
        if (accounts.isEmpty()) {
            throw new CustomException('Account not found for provided number: ' + accountNumber);
        }

        // Assuming 'dealerAccount' is declared elsewhere in your class
        dealerAccount = accounts[0];
    }

    private static void queryStoreId() {
        storeId = [SELECT Id FROM WebStore WHERE Name = :B2B_DEALER_COMMUNITY_NAME LIMIT 1]?.Id;
        if (storeId == null) {
            throw new CustomException('Deafult store is not found.');
        }
    }

    private static void queryOwner() {
        List<User> potentialOwners = [
            SELECT Id
            FROM User
            WHERE isActive = TRUE AND Contact.AccountId = :dealerAccount.Id
            ORDER BY Contact.Primary_Account_Contact__c DESC NULLS LAST
            LIMIT 1
        ];
        ownerId = potentialOwners.isEmpty() ? UserInfo.getUserId() : potentialOwners[0].Id;
    }

    private static void queryOrCreateWebcart() {
        Webcart[] wcs = [SELECT Id, Documoto_Cart_Numbers__c FROM Webcart WHERE Is_Documoto__c = TRUE AND Status = 'Active' AND AccountId = :dealerAccount.Id LIMIT 1];

        if (!wcs.isEmpty()) {
            wc = wcs[0];
            wc.Documoto_Cart_Numbers__c += ', ' + cartItemRequest.cartName.replace('Documoto ', '');
            update wc;
        } else {
            ConnectApi.CartInput cartInput = new ConnectApi.CartInput();
            cartInput.effectiveAccountId = dealerAccount.Id;
            cartInput.isSecondary = true;
            cartInput.name = DEFAULT_CART_NAME;
            cartInput.type = ConnectApi.CartType.Cart;
            ConnectApi.CartSummary cs = ConnectApi.CommerceCart.createCart(storeId, cartInput);

            if (cs != null && cs.cartId != null) {
                wc = new Webcart();
                wc.Id = cs.cartId;
                wc.Is_Documoto__c = true;
                wc.B2B_Product_Type__c = 'Parts';
                wc.Documoto_Cart_Numbers__c = cartItemRequest.cartName.replace('Documoto ', '');
                wc.OwnerId = ownerId;
                update wc;
            } else {
                throw new CustomException('Failed to create a new cart.');
            }
        }
    }

    private static void addCartItems() {
        // get ProdcutCode Product Map ByCartItems
        Map<String, Product2> productCodeProductMapByCartItems = getProductCodeProductMapByCartItems(cartItemRequest.items);

        // Prepare batch inputs for adding items to the cart
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
        for (CartItem ci : cartItemRequest.items) {
            ConnectApi.CartItemInput cartItemInput = new ConnectApi.CartItemInput();

            // Set<String> missingItemsReplacement can not happen becuase B2B_Replacement_Product is a lookup field
            Set<String> inactiveItemsReplacement
            Set<String> nlaItemsReplacement
            // Set<String> replacedItemsReplacement: can not happend becuase the part warehouse always manages the final replacement
            Set<String> baseItemsReplacement

            if (productCodeProductMapByCartItems.get(ci.productCode) == null) {
                missingItems.add(ci.productCode);
            } else if (productCodeProductMapByCartItems.get(ci.productCode).IsActive == false) {
                inactiveItems.add(ci.productCode);
            } else if (productCodeProductMapByCartItems.get(ci.productCode).B2B_No_Longer_Available__c == true) {
                nlaItems.add(ci.productCode);
            } else if (productCodeProductMapByCartItems.get(ci.productCode).B2B_Replacement_Product__c != null) {
                replacedItems.add(ci.productCode + ' by ' + productCodeProductMapByCartItems.get(ci.productCode).B2B_Replacement_Product__r.ProductCode);
            } else if (productCodeProductMapByCartItems.get(ci.productCode).Is_Base_Part__c == true) {
                baseItems.add(ci.productCode);
            } else {
                cartItemInput.productId = productCodeProductMapByCartItems.get(ci.productCode)?.Id;
                cartItemInput.quantity = ci.productQuantity;
                cartItemInput.type = ConnectApi.CartItemType.PRODUCT;
                batchInputs.add(new ConnectApi.BatchInput(cartItemInput));
            }
        }

        // Add all items to the cart in bulk
        if (!batchInputs.isEmpty()) {
            String[] itemErrorMessages = new List<String>();
            ConnectApi.BatchResult[] brs = ConnectApi.CommerceCart.addItemsToCart(storeId, dealerAccount.Id, wc.Id, batchInputs);
            system.debug('ADD ITEMS');
            system.debug(brs);
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
    }

    private static void generateResponse() {
        response = new Response2();
        response.countryCode = 'US';
        if (!missingItems.isEmpty() || !inactiveItems.isEmpty() || !nlaItems.isEmpty() || !replacedItems.isEmpty() || !baseItems.isEmpty() || !errs.isEmpty()) {
            String errorMessage = '';
            if (!missingItems.isEmpty()) {
                errorMessage += messageMap.get(FriendlyMessages.MISSING_ITEM) + String.join(missingItems, ' , ') + ' . ';
            }

            if (!inactiveItems.isEmpty()) {
                errorMessage += messageMap.get(FriendlyMessages.INACTIVE_ITEM) + String.join(inactiveItems, ' , ') + ' . ';
            }

            if (!nlaItems.isEmpty()) {
                errorMessage += messageMap.get(FriendlyMessages.ITEM_NLA) + String.join(nlaItems, ' , ') + ' . ';
            }

            if (!replacedItems.isEmpty()) {
                errorMessage += messageMap.get(FriendlyMessages.ITEM_NLA) + String.join(replacedItems, ' , ') + ' . ';
            }

            if (!baseItems.isEmpty()) {
                errorMessage += messageMap.get(FriendlyMessages.BASE_ITEM) + String.join(baseItems, ' , ') + ' . ';
            }

            if (!errs.isEmpty()) {
                errorMessage += messageMap.get(FriendlyMessages.GENERAL_ERROR) + String.join(errs, ' \n');
            }

            response.faultDescription = errorMessage;
            response.status = SharedModels.ResponseStatus.FAILURE;
            RestContext.response.statusCode = 400;
        } else {
            response.status = SharedModels.ResponseStatus.SUCCESS;
            response.webCartId = wc.Id;
            response.communityRedirectLink = siteDomain + System.Label.B2B_Store_Path_for_Documoto;
        }
    }

    private static void querySiteDomain() {
        Site mySite = [SELECT Id FROM Site WHERE Name = :SITE_NAME];
        SiteDetail mySiteDetail = [SELECT SecureURL FROM SiteDetail WHERE DurableId = :mySite.Id];
        siteDomain = mySiteDetail.SecureURL;
    }

    // Method to retrieve products based on provided cart items
    public static Map<String, Product2> getProductCodeProductMapByCartItems(List<CartItem> cartItems) {
        Map<String, Product2> productMap = new Map<String, Product2>();
        List<String> productCodes = new List<String>();

        // Collect all unique product codes from the cart items
        for (CartItem item : cartItems) {
            if (String.isNotBlank(item.productCode)) {
                productCodes.add(item.productCode);
            }
        }

        // Query product records based on the collected product codes
        List<Product2> products = [
            SELECT
                Id,
                ProductCode,
                Name,
                Description,
                IsActive,
                B2B_No_Longer_Available__c,
                B2B_Replacement_Product__c,
                B2B_Replacement_Product__r.ProductCode,
                B2B_Replacement_Product__r.isActive,
                B2B_Replacement_Product__r.B2B_No_Longer_Available__c,
                Is_Base_Part__c /* Add more fields as needed */
            FROM Product2
            WHERE ProductCode IN :productCodes
        ];

        // Populate the map with product code as the key and product record as the value
        for (Product2 product : products) {
            productMap.put(product.ProductCode, product);
        }

        return productMap;
    }

    private static void logRequest() {
        String codeIdentifier = 'POST';
        String description = 'POST: Documoto Cart Submit';
        String extendedInformation = RestContext.request.requestBody.toString().left(32760);
        SystemLogHelper.insertSystemLog('DOS_WebcardRestService', codeIdentifier, UserInfo.getUserId(), description, extendedInformation);
    }

    private static void logResponse() {
        String codeIdentifier = 'POST';
        String description = 'POST: Documoto Cart Submit Response';
        String extendedInformation = JSON.serialize(response).left(32760);
        SystemLogHelper.insertSystemLog('DOS_WebcardRestService', codeIdentifier, UserInfo.getUserId(), description, extendedInformation);
    }

    // Data Structure
    public class CartItemRequest {
        public String cartName; // value must be blank or Documoto , if it is blank then the default is Documoto
        public String hustlerPartsAccountNumber; // QAD account number
        public String bigDogPartsAccountNumber; // BigDog_Parts_Account__c
        public List<CartItem> items;
    }

    public class CartItem {
        public String productCode; // itemNumber - product code?
        public String productQuantity; // quantity
    }

    global class Response2 extends SharedModels.RESTResponse {
        public String webCartId;
        public String communityRedirectLink;
    }

    public class CustomException extends Exception {
    }
}
