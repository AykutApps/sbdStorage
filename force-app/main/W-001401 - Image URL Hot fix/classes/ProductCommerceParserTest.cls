@IsTest
public class ProductCommerceParserTest {
    static testMethod void testMapModelToDomain_nullModel() {
        //setup
        Product2 p = TestData_Product2.createSingleProduct();
        p.Get_Commerce_Data__c = true;

        update p;

        ProductCommerceParser pcp = new ProductCommerceParser(p);

        //test
        test.startTest();

        pcp.mapModelToDomain(p);

        test.stopTest();
        //asserts
        system.assertEquals('h', p.Image_Primary__c);
    }
    static testMethod void testMapModelToDomain_EmptyJSON() {
        //setup
        Product2 p = TestData_Product2.createSingleProduct();
        p.Get_Commerce_Data__c = true;
        p.Commerce_JSON__c = ProductCommerceParserJSONPayloads.emptyJSON();
        update p;

        ProductCommerceParser pcp = new ProductCommerceParser(p);

        //test
        test.startTest();

        pcp.mapModelToDomain(p);

        test.stopTest();
        //asserts
        system.assertEquals('h', p.Image_Primary__c);
    }

    static testMethod void testMapModelToDomain_WholeGood() {
        //setup
        Product2 p = TestData_Product2.createSingleProduct();
        p.Get_Commerce_Data__c = true;
        p.Commerce_JSON__c = ProductCommerceParserJSONPayloads.wholeGood();
        update p;

        ProductCommerceParser pcp = new ProductCommerceParser(p);

        //test
        test.startTest();

        pcp.mapModelToDomain(p);

        test.stopTest();
        //asserts
        system.assertEquals('https://www.cubcadet.com/wcpics/CubCadet/products/31AM5BTR710_product_detail.png', p.Image_Primary__c);
    }
    static testMethod void testMapModelToDomain_WholeGood_Large() {
        //setup
        Product2 p = TestData_Product2.createSingleProduct();
        p.Get_Commerce_Data__c = true;
        p.Commerce_JSON__c = ProductCommerceParserJSONPayloads.wholeGoodLarge();
        update p;

        ProductCommerceParser pcp = new ProductCommerceParser(p);

        //test
        test.startTest();

        pcp.mapModelToDomain(p);

        test.stopTest();
        //asserts
        system.assertEquals('https://www.cubcadet.com/wcpics/CubCadet/products/31AM5BTR710_product_detail_large.png', p.Image_Primary__c);
    }
    static testMethod void testMapModelToDomain_WholeGood_Zoom() {
        //setup
        Product2 p = TestData_Product2.createSingleProduct();
        p.Get_Commerce_Data__c = true;
        p.Commerce_JSON__c = ProductCommerceParserJSONPayloads.wholeGoodZoom();
        update p;

        ProductCommerceParser pcp = new ProductCommerceParser(p);

        //test
        test.startTest();

        pcp.mapModelToDomain(p);

        test.stopTest();
        //asserts
        system.assertEquals('https://www.cubcadet.com/wcpics/CubCadet/products/31AM5BTR710_product_detail_zoom.png', p.Image_Primary__c);
    }
    static testMethod void testMapModelToDomain_Attachment() {
        //setup
        Product2 p = TestData_Product2.createSingleProduct(RecordTypes.product_Attachment.id);
        p.Get_Commerce_Data__c = true;
        p.Commerce_JSON__c = ProductCommerceParserJSONPayloads.attachment();
        update p;

        ProductCommerceParser pcp = new ProductCommerceParser(p);

        //test
        test.startTest();

        pcp.mapModelToDomain(p);

        test.stopTest();
        //asserts
        system.assertEquals('https://www.cubcadet.com/wcpics/CubCadet/products/31AM5BTR710_product_detail.png', p.Image_Primary__c);
    }
    static testMethod void testMapModelToDomain_EmptyImages() {
        //setup
        Product2 p = TestData_Product2.createSingleProduct();
        p.Get_Commerce_Data__c = true;
        p.Commerce_JSON__c = ProductCommerceParserJSONPayloads.wholeGoodEmptyImages();
        update p;

        ProductCommerceParser pcp = new ProductCommerceParser(p);

        //test
        test.startTest();

        pcp.mapModelToDomain(p);

        test.stopTest();
        //asserts
        system.assertEquals(null, p.Image_Primary__c);
    }
    static testMethod void testMapModelToDomain_NullImages() {
        //setup
        Product2 p = TestData_Product2.createSingleProduct();
        p.Get_Commerce_Data__c = true;
        p.Commerce_JSON__c = ProductCommerceParserJSONPayloads.wholeGoodNullImages();
        update p;

        ProductCommerceParser pcp = new ProductCommerceParser(p);

        //test
        test.startTest();

        pcp.mapModelToDomain(p);

        test.stopTest();
        //asserts
        system.assertEquals(null, p.Image_Primary__c);
    }
    static testMethod void testMapModelToDomain_SingleImage() {
        //setup
        Product2 p = TestData_Product2.createSingleProduct();
        //p.Get_Commerce_Data__c = true;
        system.debug('dunk+' + p.Commerce_JSON__c);
        p.Commerce_JSON__c = ProductCommerceParserJSONPayloads.wholeGoodSingleImage();
        update p;

        ProductCommerceParser pcp = new ProductCommerceParser(p);

        //test
        test.startTest();

        pcp.mapModelToDomain(p);

        test.stopTest();
        //asserts
        system.assertEquals('https://www.cubcadet.com/wcpics/CubCadet/products/31AM5BTR710.jpg', p.Image_Primary__c);
    }
    static testMethod void testMapModelToDomain_MultipleImages_http() {
        //setup
        Product2 p = TestData_Product2.createSingleProduct();
        p.Get_Commerce_Data__c = true;
        p.Commerce_JSON__c = ProductCommerceParserJSONPayloads.wholeGoodMultipleImagesHTTP();
        update p;

        ProductCommerceParser pcp = new ProductCommerceParser(p);

        //test
        test.startTest();

        pcp.mapModelToDomain(p);

        test.stopTest();
        //asserts
        system.assertEquals('https://www.cubcadet.com/wcpics/CubCadet/products/TEST1.png', p.Image_Primary__c);
    }
    static testMethod void testMapModelToDomain_MultipleImages_https() {
        //setup
        Product2 p = TestData_Product2.createSingleProduct();
        p.Get_Commerce_Data__c = true;
        p.Commerce_JSON__c = ProductCommerceParserJSONPayloads.wholeGoodMultipleImagesHTTPS();
        update p;

        ProductCommerceParser pcp = new ProductCommerceParser(p);

        //test
        test.startTest();

        pcp.mapModelToDomain(p);

        test.stopTest();
        //asserts
        system.assertEquals('https://www.cubcadet.com/wcpics/CubCadet/products/TEST1.png', p.Image_Primary__c);
    }
    // ***************** COVER TO COVER TO COVER LEGACY CODE THAT HAD NO TEST COVERAGE
    /*     
      @testSetup static void setupTestData() {
        Account a = TestData_Account.createDealerAccount();
        Map<String, Product2> productMap = TestData_Product2.createProducts();
        TestData_Order.createAllPriceBookEntries(productMap.values(), a.Entity_ID__c);
        Ordering_Event__c oe = TestData_Ordering_Event.createOrderingEvent(RecordTypes.orderingEvent_InSeason);
        TestData_Ordering_Event.createOrderingEventProducts(oe.Id, productMap);
        Ordering_Event_Account__c oeAccount = TestData_Ordering_Event.createOrderingEventAccount(oe.Id, a.Id);
    }
*/

    static testMethod void getProductsSummary() {
        Test.startTest();
        SharedModels.ResultMessage result = ProductsCtl.getProductsSummary();
        Test.stopTest();

        System.assert(result.payloadMap.containsKey('productsSummary'));
        ProductsModels.ProductsSummaryResponse productsSummary = (ProductsModels.ProductsSummaryResponse) result.payloadMap.get('productsSummary');
    }

    static testMethod void getProductType() {
        Test.startTest();
        SharedModels.ResultMessage result = ProductsCtl.getProductType('Lawn Tractors');
        Test.stopTest();

        System.assert(result.payloadMap.containsKey('productType'));
        OrderingModels.ProductsWithOrderResponse productType = (OrderingModels.ProductsWithOrderResponse) result.payloadMap.get('productType');
    }

    static testMethod void getQuickQuoteProducts() {
        ProductsBusiness business = new ProductsBusiness();

        Test.startTest();
        OrderingModels.ProductsWithOrderResponse productType = business.getQuickQuoteProducts('Lawn Tractors', true);
        Test.stopTest();
    }

    static testMethod void getProduct() {
        Map<String, Product2> productMap = TestData_Product2.createProducts();
        Product2 p = [SELECT Id FROM Product2 WHERE ProductCode = '13A226JD010' LIMIT 1];
        Account a = TestData_Account.createDealerAccount();
        //Account a = [select Id from Account limit 1];
        User u = TestData_User.createDealerCustomerUser(a.Id, 't@test.com', 'tester');
        Test.startTest();
        SharedModels.ResultMessage result = null;
        System.runAs(u) {
            result = ProductsCtl.getProduct(p.Id);
        }
        Test.stopTest();

        OrderingModels.Product product = (OrderingModels.Product) result.payloadMap.get('product');

        ProductsModels.OrdersProduct ordersProduct = (ProductsModels.OrdersProduct) result.payloadMap.get('ordersProduct');
    }

    static testMethod void updateProductQuantities_createOrder() {
        Map<String, Product2> productMap = TestData_Product2.createProducts();
        Product2 p = [SELECT Id FROM Product2 WHERE ProductCode = '13A226JD010' LIMIT 1];
        Ordering_Event__c oe = TestData_Ordering_Event.createOrderingEvent(RecordTypes.orderingEvent_InSeason);
        //Ordering_Event__c oe = [select Id from Ordering_Event__c limit 1];
        List<Product2> products = new List<Product2>{ p };

        OrderingModels.ProductQuantitiesRequest request = new OrderingModels.ProductQuantitiesRequest();
        OrderingModels.OrderProduct op = new OrderingModels.OrderProduct();
        op.productId = p.Id;
        op.quantity = 4;
        request.products.add(op);
        Account a = TestData_Account.createDealerAccount();
        //Account a = [select Id, Entity_ID__c from Account limit 1];
        User u = TestData_User.createDealerCustomerUser(a.Id, 't@test.com', 'tester');

        Test.startTest();
        SharedModels.ResultMessage result = null;
        System.runAs(u) {
            result = ProductsCtl.createOrderByEventId(oe.Id);

            request.orderId = (Id) result.payloadMap.get('orderId');
            result = ProductsCtl.updateProductQuantities(request);
        }
        Test.stopTest();

        System.debug('Nazia - result : ' + result);
        List<OrderItem> ois = [SELECT Id, Quantity FROM OrderItem];

        result = ProductsCtl.getProduct(p.Id);

        OrderingModels.Product product = (OrderingModels.Product) result.payloadMap.get('product');

        ProductsModels.OrdersProduct ordersProduct = (ProductsModels.OrdersProduct) result.payloadMap.get('ordersProduct');
    }

    static testMethod void processCommerceJson() {
        Map<String, Product2> productMap = TestData_Product2.createProducts();
        Product2 p = [SELECT Id FROM Product2 WHERE ProductCode = '13A226JD010' LIMIT 1];
        p.Commerce_JSON__c = createCommerceJson();
        update p;

        p = [SELECT Id, Commerce_JSON__c, Feature_1__c, Feature_2__c, Feature_3__c, Image_Primary__c FROM Product2 WHERE Id = :p.Id];

        Test.startTest();
        ProductCommerceParser parser = new ProductCommerceParser(p);
        parser.getGallery();

        List<Id> productIds = new List<Id>();
        productIds.add(p.Id);
        SharedModels.ResultMessage specResult = ProductsCtl.getSpecComparison(productIds);
        SharedModels.ResultMessage tabResult = ProductsCtl.getProductTabs(p.Id);
        Test.stopTest();

        System.assert(specResult.payloadMap.containsKey('specComparison'));
        System.assert(specResult.payloadMap.containsKey('productType'));

        System.assert(tabResult.payloadMap.containsKey('specs'));
        System.assert(tabResult.payloadMap.containsKey('accessories'));
    }

    private static String createCommerceJson() {
        return '[{"catentryId":"1626975","itemNumber":"14W-3FM-010","name":"GTX 2000 Garden Tractor","shortDescription":null,"longDescription":"GTX 2000 garden tractor.","siteURL":"http://www.cubcadet.com/equipment/cubcadet/gtx-2000","listPrices":[{"price":4499,"currency":"USD"}],"offerPrices":[{"price":3799.99,"currency":"USD"},{"price":4499,"currency":"USD"}],"attributes":{"RATINGS":[],"SPECS":[{"identifier":"Warranty","name":"Warranty","grouping":"WARRANTY†","values":[{"value":"4-year/300-hr and 5-year/500-hr limited warranty","sequence":0}],"sequence":0},{"identifier":"Alternator","name":"Alternator","grouping":"ELECTRICAL SYSTEM","values":[{"value":"25 amp. regulated","sequence":0}],"sequence":1}],"FEATURES":[{"identifier":"FEATURES","name":"Features","grouping":null,"values":[{"value":"20 HP* Kohler&reg; Command&reg; V-Twin OHV engine","sequence":0}],"sequence":0},{"identifier":"FEATURES","name":"Features","grouping":null,"values":[{"value":"42, 50, or 54 stamped deck sold separately","sequence":0}],"sequence":0},{"identifier":"FEATURES","name":"Features","grouping":null,"values":[{"value":"Smooth, effortless Electronic Power Steering (EPS)","sequence":0}],"sequence":0}]},"relatedProducts":{"ACCESSORY":[{"catentryId":"1615873","itemNumber":"490-325-0020","name":"32 oz. Tire Science - Tire and Tube Sealant","shortDescription":"Tire and Tube Sealant by Tire Science - 32 oz.","longDescription":"Tire and Tube Sealant by Tire Science - 32 oz. This product can extend the life of older tires. It is a non-highway tire and tube sealant for both tubed, and tubeless low-speed tires. This tire sealant formulation finds and stops leaks instantly, even sealing punctures up to 1/8 wide. It also protects your tires by preventing against future leaks. ","siteURL":"http://www.cubcadet.com/equipment/cubcadet/490-325-0020","listPrices":[{"price":17.94,"currency":"USD"}],"offerPrices":[{"price":17.94,"currency":"USD"}],"attributes":{},"relatedProducts":{},"images":["http://www.cubcadet.com/wcpics/CubCadet/products/490-325-0020_large.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/490-325-0020_part_detail_large.png","http://www.cubcadet.com/wcpics/CubCadet/products/490-325-0020_part_detail_zoom.png","http://www.cubcadet.com/wcpics/CubCadet/products/490-325-0020_part_listing_small.png","http://www.cubcadet.com/wcpics/CubCadet/products/490-325-0020_part_thumb_large.png","http://www.cubcadet.com/wcpics/CubCadet/products/490-325-0020_part_thumb_small.png","http://www.cubcadet.com/wcpics/CubCadet/products/490-325-0020_product_detail.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/490-325-0020_product_listing.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/490-325-0020_search_result.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/490-325-0020_small.jpg"]},{"catentryId":"1653927","itemNumber":"490-240-0011","name":"Fuel Defense Fuel Test Swabs 2-in-1 Fuel Quality Test","shortDescription":"Fuel Defense Fuel Test Swabs 2-in-1 fuel quality test","longDescription":"Fuel Defense Fuel Test Swabs 2-in-1 fuel quality test. Test for oxidized (stale) fuel and water in fuel. Quickly diagnoses starting problems and keeps bad fuel out of your equipment.<br/><br/><ul><li>2-in-1 fuel quality test for both standard and 2-cycle mixed fuels</li><li>Tests for oxidized (stale) fuel and water in fuel</li><li>Keeps bad fuel out of your equipment</li><li>Quickly diagnoses starting problems </li><li>Prevents costly repairs. &nbsp;Simple and easy to use.</li><li>Contains three fuel swabs</li></ul>","siteURL":"http://www.cubcadet.com/equipment/cubcadet/490-240-0011","listPrices":[{"price":4.99,"currency":"USD"}],"offerPrices":[{"price":4.99,"currency":"USD"}],"attributes":{},"relatedProducts":{},"images":["http://www.cubcadet.com/wcpics/CubCadet/products/490-240-0011_large.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/490-240-0011_part_detail_large.png","http://www.cubcadet.com/wcpics/CubCadet/products/490-240-0011_part_detail_zoom.png","http://www.cubcadet.com/wcpics/CubCadet/products/490-240-0011_part_listing_small.png","http://www.cubcadet.com/wcpics/CubCadet/products/490-240-0011_part_thumb_large.png","http://www.cubcadet.com/wcpics/CubCadet/products/490-240-0011_part_thumb_small.png","http://www.cubcadet.com/wcpics/CubCadet/products/490-240-0011_product_detail.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/490-240-0011_product_listing.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/490-240-0011_search_result.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/490-240-0011_small.jpg"]},{"catentryId":"1652377","itemNumber":"45-0329-100","name":"Broadcast Spreader (175-ATV)","shortDescription":"Distribute fertilizer up to 12 with the broadcast spreader. This attachment features a rustproof poly hopper for long-lasting use, accomodates up to 175 pounds, and is ideal for covering yards and spaces up to 40,000 sq. ft.","longDescription":null,"siteURL":"http://www.cubcadet.com/equipment/ProductDisplay?storeId=10051&urlRequestType=Base&langId=-1&catalogId=14101&productId=","listPrices":[],"offerPrices":[],"attributes":{},"relatedProducts":{},"images":["http://www.cubcadet.com/wcpics/CubCadet/products/45-0329-100_product_listing.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/45-0329-100_search_result.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/45-0329-100_small.jpg"]}],"UPSELL":[{"catentryId":"1532606","itemNumber":"24BG5HM4010","name":"LS 27 CCHP","shortDescription":"Log Splitter","longDescription":null,"siteURL":"http://www.cubcadet.com/equipment/cubcadet/ls-27-cchp","listPrices":[{"price":1699.99,"currency":"USD"}],"offerPrices":[{"price":1699.99,"currency":"USD"}],"attributes":{},"relatedProducts":{},"images":["http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_1_browse_mobile.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_2_browse_mobile.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_global_nav.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_hero.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_large.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_part_detail_mobile.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_product_detail.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_product_detail.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_product_detail_large.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_product_detail_mobile.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_product_detail_zoom.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_product_details_12.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_product_listing.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_product_listing.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_product_listing_flash.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_product_listing_large.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_product_listing_small.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_product_thumb_large.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_product_thumb_small.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_search_result.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_small.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_target_thumb.png","http://www.cubcadet.com/wcpics/CubCadet/products/24BG5HM4010_thumbnail.jpg"]},{"catentryId":"1532590","itemNumber":"31AM63TR710","name":"2X™ 524 WE","shortDescription":"Two-Stage Power Snow Thrower","longDescription":null,"siteURL":"http://www.cubcadet.com/equipment/cubcadet/2X-524-WE","listPrices":[{"price":699.99,"currency":"USD"}],"offerPrices":[{"price":699.99,"currency":"USD"}],"attributes":{},"relatedProducts":{},"images":["http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_1_browse_mobile.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_2_browse_mobile.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_global_nav.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_hero.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_large.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_part_detail_mobile.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_product_detail.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_product_detail.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_product_detail_large.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_product_detail_mobile.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_product_detail_zoom.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_product_details_12.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_product_listing.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_product_listing.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_product_listing_flash.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_product_listing_large.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_product_listing_small.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_product_thumb_large.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_product_thumb_small.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_search_result.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_small.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_target_thumb.png","http://www.cubcadet.com/wcpics/CubCadet/products/31AM63TR710_thumbnail.jpg"]}]},"images":["http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_1_browse_mobile.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_2_browse_mobile.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_global_nav.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_hero.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_large.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_part_detail_mobile.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_product_detail.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_product_detail.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_product_detail_large.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_product_detail_mobile.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_product_detail_zoom.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_product_details_12.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_product_listing.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_product_listing.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_product_listing_flash.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_product_listing_large.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_product_listing_small.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_product_thumb_large.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_product_thumb_small.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_search_result.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_small.jpg","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_target_thumb.png","http://www.cubcadet.com/wcpics/CubCadet/products/14W-3FM-010_thumbnail.jpg"]}]';
    }
}
