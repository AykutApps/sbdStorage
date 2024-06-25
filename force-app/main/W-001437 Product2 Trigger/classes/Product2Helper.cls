public without sharing class Product2Helper {
    public Product2 findProductByFactoryNumber(String factoryNumber) {
        Product2 product;
        try {
            product = [select id, productcode, detail_sku__c from product2 where productcode = :factoryNumber];
        } catch (QueryException queryException) {
            product = null;
        }
        return product;
    }

    //THIS IS NOT BULKIFIED
    public Boolean isValidFactoryModelNumber(String factoryModelNumber){
        Product2 p = findProductByFactoryNumber(factoryModelNumber);
        if(p != null && isTrueProduct(p.Id)){
            return true;
        }
        return false;
    }

    private static Product2 mtdResearchProduct;

    public static Id getMTDResearchProductId(){
        if(mtdResearchProduct == null){
            mtdResearchProduct = new Product2();
            for (Product2 p : [Select Id From Product2 Where ProductCode = 'MTD_Research']) {
                mtdResearchProduct = p;
            }
        }
        return mtdResearchProduct.Id;
    }

    private static Product2 genericOtherProduct;

    public static Id getGenericOtherProductId(){
        if(genericOtherProduct == null){
            genericOtherProduct = new Product2();
            for (Product2 p : [Select Id From Product2 Where ProductCode = 'Other' AND RecordTypeId = :RecordTypes.product_Generic.Id]) {
                genericOtherProduct = p;
            }
        }
        return genericOtherProduct.Id;
    }

    public static Boolean isTrueProduct(Id productId){
        //Add check for generic record type?
        if(productId == null || productId == getMTDResearchProductId() || productId == getGenericOtherProductId()){
            return false;
        }
        return true;
    }

    public static Boolean retailPriceCheck(Decimal retailMax, Decimal retailMin, Decimal retailPrice){ //mburr.2021-07-13 made public for test coverage
        return retailPrice == null || ((retailMin == null || retailPrice >= retailMin) && (retailMax == null || retailPrice <= retailMax));
    }

    public static List<PriceBookEntry> getSGMPriceBookEntriesForProducts(Map<Id, PricebookEntry> prodToRetailPBE, List<Product2> products, SGMData sgm){
        List<Simplified_Gross_Margin__c> levelRules = [Select Id, Brand__c, Family__c, Category__c, Is_XT3_Deck__c, Retail_Maximum__c, Retail_Minimum__c, 
            Level_1_Gross_Margin__c, Level_2_Gross_Margin__c, Level_3_Gross_Margin__c, Level_4_Gross_Margin__c, 
            Level_5_Gross_Margin__c, Level_6_Gross_Margin__c, Level_7_Gross_Margin__c 
            From Simplified_Gross_Margin__c where RecordTypeId = :RecordTypes.sgm_level.Id Order By Level_1_Gross_Margin__c Desc];

        List<Simplified_Gross_Margin__c> tierRules = [Select Id, Brand__c, Family__c, Category__c, Is_XT3_Deck__c, Retail_Maximum__c, Retail_Minimum__c, 
            Tier_1_Gross_Margin__c, Tier_2_Gross_Margin__c, Tier_3_Gross_Margin__c, Tier_4_Gross_Margin__c, Tier_5_Gross_Margin__c 
            From Simplified_Gross_Margin__c where RecordTypeId = :RecordTypes.sgm_tier.Id Order By Tier_1_Gross_Margin__c Desc];

        List<PricebookEntry> pbesToUpsert = new List<PricebookEntry>();
        pbesToUpsert.addAll(getSGMPriceBookEntriesForProducts(prodToRetailPBE, products, sgm, levelRules, true));
        pbesToUpsert.addAll(getSGMPriceBookEntriesForProducts(prodToRetailPBE, products, sgm, tierRules, false));
        return pbesToUpsert;
    }

    private static List<PriceBookEntry> getSGMPriceBookEntriesForProducts(Map<Id, PricebookEntry> prodToRetailPBE, List<Product2> products, SGMData sgm, List<Simplified_Gross_Margin__c> rules, Boolean isLevel){
        List<PricebookEntry> pbesToUpsert = new List<PricebookEntry>();

        for(Product2 p: products){
            if(!prodToRetailPBE.containsKey(p.Id)){
                continue;
            }
            Boolean ruleFound = false;
            List<PriceBookEntry> brandMatchPBES = null;
            List<PriceBookEntry> familyMatchPBES = null;
            List<PriceBookEntry> categoryMatchPBES = null;
            List<PriceBookEntry> familyAndCategoryMatchPBES = null;

            for(Simplified_Gross_Margin__c rule: rules){
                //product brand must match SGM rule brand to continue
                if (rule.Brand__c == null || rule.Brand__c != p.Brand__c) {
                    continue;
                }
                System.debug('Processing margins:' + rule);

                Decimal retailPrice = prodToRetailPBE.get(p.Id).UnitPrice;
                Boolean validPriceRule = retailPriceCheck(rule.Retail_Maximum__c, rule.Retail_Minimum__c, retailPrice);
                Boolean validForFamily = rule.Family__c != null && rule.Family__c == p.Family && validPriceRule;
                Boolean validForCategory = rule.Category__c != null && rule.Category__c == p.Category__c && validPriceRule;

                System.debug('validForFamily:' + validForFamily);
                System.debug('validForCategory:' + validForCategory);

                if(p.Is_XT3_Deck__c){
                    if(rule.Is_XT3_Deck__c){
                        ruleFound = true;
                        pbesToUpsert.addAll(getPBES(rule, p, retailPrice, sgm, isLevel));
                        //System.debug('XT3: ');
                        //pbe for product already created with highest gross margin % rule.  Don't check it again
                        break;
                    }
                }else if (rule.Category__c == null && rule.Family__c == null) {
                    brandMatchPBES = getPBES(rule, p, retailPrice, sgm, isLevel);
                }else if(validForFamily && validForCategory){
                    familyAndCategoryMatchPBES = getPBES(rule, p, retailPrice, sgm, isLevel);
                }else if(validForCategory && rule.Family__c == null){
                    categoryMatchPBES = getPBES(rule, p, retailPrice, sgm, isLevel);
                }else if(validForFamily && rule.Category__c == null){
                    familyMatchPBES = getPBES(rule, p, retailPrice, sgm, isLevel);
                }
            } 
            //a category match must win over a family match
            if (!ruleFound && (brandMatchPBES != null || familyMatchPBES != null || categoryMatchPBES != null || familyAndCategoryMatchPBES != null)) {
                ruleFound = true;
                if (familyAndCategoryMatchPBES != null) {
                    System.debug('took:familyAndCategoryMatchPBES');
                    pbesToUpsert.addAll(familyAndCategoryMatchPBES);
                }else if (categoryMatchPBES != null) {
                    System.debug('took:categoryMatchPBES');
                    pbesToUpsert.addAll(categoryMatchPBES);
                } else if (familyMatchPBES != null) {
                    System.debug('took:familyMatchPBES');
                    pbesToUpsert.addAll(familyMatchPBES);
                } else {
                    System.debug('took:brandMatchPBES');
                    pbesToUpsert.addAll(brandMatchPBES);
                }
            }
            if(!ruleFound){
                System.debug('No SGM rule for: '+p.Id+' | Brand: '+p.Brand__c+' | Family: '+p.Family+' | Category: '+p.Category__c);
            }  
        }
        return pbesToUpsert;
    }

    private static List<PriceBookEntry> getPBES(Simplified_Gross_Margin__c rule, Product2 p, Decimal retailPrice, SGMData sgm, Boolean isLevel){
        List<PricebookEntry> pbesToUpsert = new List<PriceBookEntry>();
        if (isLevel) {
            for(Integer i = 1; i<=7; i++){
                Decimal margin = (Decimal)rule.get('Level_'+String.valueOf(i)+'_Gross_Margin__c');
                if (margin == null) {
                    continue;
                }
                Decimal newPrice = retailPrice - (retailPrice * 0.01 * margin);
                newPrice = newPrice.round(System.RoundingMode.HALF_UP);
                if(sgm.prodToLevelToPBEMap.containsKey(p.Id)){
                    PricebookEntry pbe = sgm.prodToLevelToPBEMap.get(p.Id).get(i);
                    if(pbe != null){ //mburr.2021-07-13 pricebooks for SGM were abanded in 2018, so skip if SGM Unit price does not exist 
                        if(pbe.UnitPrice != newPrice){
                            pbesToUpsert.add(new PriceBookEntry(Id = pbe.Id, UnitPrice = newPrice, IsActive = true));
                        }
                    }
                }else{
                    pbesToUpsert.add(new PriceBookEntry(Product2Id = p.Id, PriceBook2Id = sgm.levelToPriceBook.get(i), UnitPrice = newPrice, IsActive = true));
                }
            }
        } else {
            for(Integer i = 1; i<=5; i++){
                Decimal margin = (Decimal)rule.get('Tier_'+String.valueOf(i)+'_Gross_Margin__c');
                if (margin == null) {
                    continue;
                }
                Decimal newPrice = retailPrice - (retailPrice * 0.01 * margin);
                newPrice = newPrice.round(System.RoundingMode.HALF_UP);
                if(sgm.prodToTierToPBEMap.containsKey(p.Id)){
                    PricebookEntry pbe = sgm.prodToTierToPBEMap.get(p.Id).get(i);
                    if(pbe.UnitPrice != newPrice){
                        pbesToUpsert.add(new PriceBookEntry(Id = pbe.Id, UnitPrice = newPrice, IsActive = true));
                    }
                }else{
                    pbesToUpsert.add(new PriceBookEntry(Product2Id = p.Id, PriceBook2Id = sgm.tierToPriceBook.get(i), UnitPrice = newPrice, IsActive = true));
                }
            }
        }

        return pbesToUpsert;
    }

    public class SGMData {
        public SGMData(Map<Integer, Id> levelToPricebook, 
            Map<Integer, Id> tierToPricebook, 
            Map<Id, Map<Integer, PricebookEntry>> prodToLevelToPBEMap, 
            Map<Id, Map<Integer, PricebookEntry>> prodToTierToPBEMap) {
            this.levelToPricebook = levelToPricebook;
            this.tierToPricebook = tierToPricebook;
            this.prodToLevelToPBEMap = prodToLevelToPBEMap;
            this.prodToTierToPBEMap = prodToTierToPBEMap;
            createDebugInfo();
        }

        public Map<Integer, Id> levelToPricebook = new Map<Integer, Id>();
        public Map<Integer, Id> tierToPricebook = new Map<Integer, Id>();
        public Map<Id, Map<Integer, PricebookEntry>> prodToLevelToPBEMap {get; set;}
        public Map<Id, Map<Integer, PricebookEntry>> prodToTierToPBEMap {get; set;}

        public void createDebugInfo() {
            System.debug('levelToPricebook: ' + levelToPricebook.values().size());
            System.debug('tierToPricebook: ' + tierToPricebook.values().size());
            System.debug('prodToLevelToPBEMap: ' + prodToLevelToPBEMap.values().size());
            System.debug('prodToTierToPBEMap: ' + prodToTierToPBEMap.values().size());
        }
    }

    public static SGMData getSGMDataForProducts(Set<Id> productIds) {
        System.debug('getSGMDataForProducts: ' + productIds.size());
        Map<Integer, Id> levelToPricebook = new Map<Integer, Id>();
        Map<Integer, Id> tierToPricebook = new Map<Integer, Id>();
        Map<Id, Map<Integer, PricebookEntry>> prodToLevelToPBEMap = new Map<Id, Map<Integer, PricebookEntry>>();
        Map<Id, Map<Integer, PricebookEntry>> prodToTierToPBEMap = new Map<Id, Map<Integer, PricebookEntry>>();
        for(Pricebook2 pb: [Select Id, Level__c, Tier__c, (Select Id, UnitPrice, Product2Id From PriceBookEntries Where Product2Id IN :productIds) 
                                From Pricebook2 Where (Level__c != null or Tier__c != null) AND IsActive = true]){
            if (pb.Level__c != null) {
                levelToPricebook.put(Integer.valueOf(pb.Level__c), pb.Id);
            } else {
                tierToPricebook.put(Integer.valueOf(pb.Tier__c), pb.Id);
            }

            for(PriceBookEntry pbe: pb.PriceBookEntries){
                Id productId = pbe.Product2Id;
                if (pb.Level__c != null) {
                    if(prodToLevelToPBEMap.containsKey(productId)){
                        prodToLevelToPBEMap.get(productId).put(Integer.valueOf(pb.Level__c), pbe);
                    }else{
                        prodToLevelToPBEMap.put(productId, new Map<Integer, PricebookEntry>{Integer.valueOf(pb.Level__c) => pbe});
                    }
                } else {
                    if(prodToTierToPBEMap.containsKey(productId)){
                        prodToTierToPBEMap.get(productId).put(Integer.valueOf(pb.Tier__c), pbe);
                    }else{
                        prodToTierToPBEMap.put(productId, new Map<Integer, PricebookEntry>{Integer.valueOf(pb.Tier__c) => pbe});
                    }
                }
            }
        }
        return new SGMData(levelToPricebook, tierToPricebook, prodToLevelToPBEMap, prodToTierToPBEMap);
    }

    public static Boolean isCaliforniaOnlyProduct(Product2 p) {
        if (String.isNotBlank(p.California_Standard__c) && p.California_Standard__c == 'California Only') {
            return true;
        }
        return false;
    }

    public List<ProductByProductCodeSearchResult> searchProductsByModelNumber(String searchTerm, id recordTypeId, String productType) {

        List<ProductByProductCodeSearchResult> resultsToReturn = new List<ProductByProductCodeSearchResult>();
        List<Product2> pList = new List<Product2>();

        String query = 'Select ProductCode, Id, Master_SKU__c, Bid_Price__c, Bid_Rebate__c, Fleet_Price__c, Fleet_Rebate__c, Retail_Price_US__c from Product2 WHERE ProductCode like \''+String.escapeSingleQuotes(searchTerm)+'%\'';

        if (recordTypeId != null){
            query = query + 'AND RecordTypeId = \''+recordTypeId+'\'';
        }

        if (productType == 'Bid'){
            query = query + 'AND Bid_Eligible__c = true';
        }
        else if(productType == 'Fleet'){
            query = query + 'AND Fleet_Eligible__c = true';
        }


        query = query + ' ORDER BY ProductCode limit 200';

        pList = Database.query(query);

        for (Product2 p : pList) {
            ProductByProductCodeSearchResult result = new ProductByProductCodeSearchResult();
            result.id = p.id;
            result.modelNo=p.Master_SKU__c;
            result.retailPrice=p.Retail_Price_US__c;
            result.bidPrice=p.Bid_Price__c;
            result.bidRebate=p.Bid_Rebate__c;
            result.fleetPrice=p.Fleet_Price__c;
            result.fleetRebate=p.Fleet_Rebate__c;
            result.productCode=p.ProductCode;
            resultsToReturn.add(result);
        }

        return resultsToReturn;
    }    
    
    public static Date addDaysSkippingSundays(Date inputDate, Integer daysToAdd) {
        DateTime resultDate = DateTime.newInstance(inputDate,  System.now().time());
        // DateTime resultDate = (DateTime)inputDate;
        Integer addedDays = 0;

        while (addedDays < daysToAdd) {
            // Add a day
            resultDate = resultDate.addDays(1);

            if (resultDate.format('E') != 'Sun') {
                addedDays++;
            }
        }

        return Date.ValueOf(resultDate);
    }
    
    public static Date addDaysSkippingWeekend(Date inputDate, Integer daysToAdd) {
        // DateTime resultDate = (DateTime)inputDate;
        DateTime resultDate = DateTime.newInstance(inputDate,  System.now().time());
        Integer addedDays = 0;

        while (addedDays < daysToAdd) {
            // Add a day
            resultDate = resultDate.addDays(1);

            // Check if the new date is not a Sunday
            system.debug(resultDate.format('E'));
            if (!(resultDate.format('E') == 'Sun' || resultDate.format('E') == 'Sat')) {
                addedDays++;
            }
        }

        return Date.ValueOf(resultDate);
    }
}