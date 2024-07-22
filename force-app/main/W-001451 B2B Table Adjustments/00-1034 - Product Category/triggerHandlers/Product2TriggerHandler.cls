/**
 * Maintains composite key used to match universal attachments
 *
 * @author Craig Johnson
 * @date 3/2016
 *
 * UPDATES
 * mburr.2017-05-03 S-05508  auto-load EDW products into record type "Finished Goods from EDW"
 * mburr.2018-06-05 W-000196 1. ProductCode s/b upper case except on Generic products
 *                           2. set Product_Code_External_ID__c as an unique/case insensitive constraint based on ProductCode
 * mburr.2022-05-02 PMX Canada Online  Product2 must be active if 1 or more child Product_Region__c records are active; otherwise SFDC Pricebooks won't work
 */
public class Product2TriggerHandler implements TriggerInterface {
    public Product2TriggerHandler() {
    }

    public void beforeInsert() {
        setRecordType(Trigger.new);
        setCompositeKeys(Trigger.new);
        setExternalIds(Trigger.new);
        setNames(Trigger.new); //must follow setExternalIds; setExternalIds changes ProductCode which is used in some Product2.Name logic
        setIRPortalBusinessDivisions(Trigger.new);
        setDealerTypes(Trigger.new);

        clearOverrides(Trigger.new);
        updateFulfillFrom(Trigger.new, (Map<Id, Product2>) Trigger.oldMap);
    }

    public void beforeUpdate() {
        validations(Trigger.new);
        setRecordType(Trigger.new);
        setCompositeKeys(Trigger.new);
        setExternalIds(Trigger.new);
        setNames(Trigger.new); //must follow setExternalIds; setExternalIds changes ProductCode which is used in some Product2.Name logic
        setIRPortalBusinessDivisions(Trigger.new);
        setDealerTypes(Trigger.new);
        if (!test.isRunningTest()) {
            setCommerceJson(Trigger.new);
        }
        clearOverrides(Trigger.new);
        processInventoryRemaining((Map<Id, Product2>) Trigger.oldMap, Trigger.new);
        setRetailPrice((Map<Id, Product2>) Trigger.oldMap, Trigger.new);
        updateFulfillFrom(Trigger.new, (Map<Id, Product2>) Trigger.oldMap);
        updateShippingAndDeliveryDates((Map<Id, Product2>) Trigger.newMap, (Map<Id, Product2>) Trigger.oldMap);
    }

    public void beforeDelete() {
    }

    public void afterInsert() {
        addRetailPBE(Trigger.new);

        updateSimplifiedGrossMarginPBEs((Map<Id, Product2>) Trigger.oldMap, (Map<Id, Product2>) Trigger.newMap);
        TriggerHelper.setAlreadyfired();
        adjustProductCategories();
    }

    public void afterUpdate() {
        updateSimplifiedGrossMarginPBEs((Map<Id, Product2>) Trigger.oldMap, (Map<Id, Product2>) Trigger.newMap);
        TriggerHelper.setAlreadyfired();

        updateChildren(Trigger.new);
        adjustProductCategories();
    }

    public void afterDelete() {
        TriggerHelper.setAlreadyfired();
    }

    public void finish() {
    }

    private void validations(List<Product2> products) {
        //PREP
        Map<Id, Product2> deactivatedMap = new Map<Id, Product2>(); //key: Product2.Id  val: Product2 SObject
        for (Product2 p : products) {
            if (Trigger.isUpdate && p.IsActive == false) {
                Product2 old = (Product2) Trigger.oldMap.get(p.Id);
                if (p.IsActive != old.IsActive) {
                    deactivatedMap.put(p.Id, p);
                }
            }
        }
        Map<Id, Product_Region__c> pIdToActivePRegionMap = new Map<Id, Product_Region__c>(); //key: Product2.Id  val: child Product_Region__c SObject if active
        if (deactivatedMap.size() > 0) {
            for (Product_Region__c pr : [
                SELECT ID, Product__c, Is_Active__c
                FROM Product_Region__c
                WHERE Product__c IN :deactivatedMap.keySet() AND Is_Active__c = TRUE
            ]) {
                if (pr.Is_Active__c == true) {
                    pIdToActivePRegionMap.put(pr.Product__c, pr);
                }
            }
        }

        //WORK - prevent Product2 from being deactivated if there are active Product_Region__c records
        if (deactivatedMap.size() > 0) {
            for (Product2 p : products) {
                if (pIdToActivePRegionMap.containsKey(p.Id)) {
                    p.addError(
                        'This product is shared with another region and cannot be made inactive.  Please remove the “Available For In-Season” or check the “InSeason Soldout” flags to remove the product from the dealer order form'
                    ); //ToFuture: custom label
                }
            }
        }
    }

    private void setNames(List<Product2> products) {
        ID finishedEdwRecTypeID = RecordTypes.product_FinishedGoodsFromEDW.ID;
        ID genericRecTypeID = RecordTypes.product_Generic.ID;
        ID otherRecTypeID = RecordTypes.product_Other.ID;
        for (Product2 p : products) {
            String desiredName;
            if (p.RecordTypeID == finishedEdwRecTypeID) {
                //Diane wanted Retail SKU but it is not unique; so she chose ProductCode
                desiredname = p.ProductCode;
            } else if (p.RecordTypeID == genericRecTypeID) {
                desiredname = p.ProductCode;
            } else if (String.isBlank(p.Family) || p.RecordTypeID == otherRecTypeID) {
                //no IR Family means product2 is not a whole good or attachment
                desiredname = p.ProductCode;
            } else {
                desiredName = String.isNotBlank(p.Detail_SKU__c) ? p.Detail_SKU__c : p.Master_SKU__c;
            }

            if (desiredName == null || desiredName.trim() == '') {
                desiredName = 'missing SKU' + ((p.ProductCode == null) ? '' : ' (' + p.ProductCode + ')');
            }
            //update name only if it changed
            if (p.Name != desiredName) {
                p.Name = desiredName;
            }
        }
    }

    private void setCompositeKeys(List<Product2> products) {
        for (Product2 p : products) {
            p.Composite_Key__c = OrderingHelpers.getUniversalAttachmentKey(p);
        }
    }

    private void setIRPortalBusinessDivisions(List<Product2> products) {
        /*	mburr 6/2018: Long ago, the creators of the IBM Websphere(WAS) Portal that allows dealers to access parts & warrantees
         *                established 4 IR-Admin Business Divisions which allows products to be segregated by
         *                4 administrative groupings:
         * 					1 = US
         *                  2 = AUS
         *                  3 & 4 are used for Canada
         *                They use these business divisions when syncing products, inventory availability, inventory overrides, etc.
         *                between Portal/SFDC<-->MSSQL<-->COM.  And, business users only see products for their countries; however,
         *                business users are not aware of these divisions.  Business Users refer to Selling Divisions, Servicing Divisions, etc.
         *                which are not related to this IR-Admin Business Division.
         */
        Integer genericBizDiv = 0;
        ID genericRecTypeID = RecordTypes.product_Generic.ID; //maintained by system admin

        Integer irUsaBizDiv = 1;
        ID irWholeGoodRecTypeID = RecordTypes.product_WholeGood.ID; //maintained by Darlene's team
        ID irAttachmentRecTypeID = RecordTypes.product_Attachment.ID; //maintained by Darlene's team
        ID irPartRecTypeID = RecordTypes.product_Part.ID; //assigned by Agora when inserting the part records

        Integer edwFinishedGoodsBizDiv = 1;
        ID edwFinishedGoodsID = RecordTypes.product_FinishedGoodsFromEDW.ID; //In Spring 2017, EDW Finished Goods represent an aggregate of unique products sold to/registered by USA IR Dealers in the last 10 years

        for (Product2 p : products) {
            if (p.RecordTypeID == genericRecTypeID && p.Business_Division__c != genericBizDiv) {
                p.Business_Division__c = genericBizDiv;
            } else if (
                (p.RecordTypeID == irWholeGoodRecTypeID || p.RecordTypeID == irAttachmentRecTypeID || p.RecordTypeID == irPartRecTypeID) && p.Business_Division__c != irUsaBizDiv
            ) {
                p.Business_Division__c = irUsaBizDiv;
            } else if (p.RecordTypeID == edwFinishedGoodsID && p.Business_Division__c != edwFinishedGoodsBizDiv) {
                p.Business_Division__c = edwFinishedGoodsBizDiv;
            }
        }
    }

    private void setExternalIds(List<Product2> products) {
        //makes sure Product2.ProductCode is upper case and then sets unique key Product2.Product_Code_External_ID__c

        //These types of products are created manually.  DataStage or other tools/code should not create/update these product types via INSERT/UPDATE/UPSERT
        ID genericRecTypeID = RecordTypes.product_Generic.ID; //maintained by system admin
        ID otherRecTypeID = RecordTypes.product_Other.ID; //maintained by system admin

        for (Product2 p : products) {
            string pCode = (String.isBlank(p.ProductCode)) ? '' : p.ProductCode.trim();
            if (pCode == '') {
                p.ProductCode.addError('MTDException-ProductCode is a required field.');
            }
            //product code for Generic Products can be upper/lower
            if (p.RecordTypeID == genericRecTypeID && pCode != p.ProductCode) {
                // operator != is case insensitive
                p.ProductCode = pCode;
                //otherwise product code s/b all caps
            } else if (p.RecordTypeID != genericRecTypeID && !pCode.toUpperCase().equals(p.ProductCode)) {
                // String.equals(...) is case sensitive
                p.ProductCode = pCode.toUpperCase();
            }
            //calculate external ID
            string desiredExtID = '';
            if (p.RecordTypeID == genericRecTypeID) {
                desiredExtID = 'GEN-' + pCode;
            } else if (p.RecordTypeID == otherRecTypeID) {
                desiredExtID = 'OTH-' + pCode;
            } else {
                desiredExtID = pCode;
            }
            //Product_Code_External_ID__c is always upper case
            desiredExtID = desiredExtID.toUpperCase();
            if (!desiredExtID.equals(p.Product_Code_External_ID__c)) {
                p.Product_Code_External_ID__c = desiredExtID;
            }
        }
    }

    private void setDealerTypes(List<Product2> products) {
        //if Product2 has an Independent Retail record type, allow changes to Product2.Dealer_Type__c; default if blank
        ID irWholeGoodRecTypeID = RecordTypes.product_WholeGood.ID;
        ID irAttachmentRecTypeID = RecordTypes.product_Attachment.ID;

        String crAndDR = 'CR;DR';
        String crOnly = 'CR'; // only CR dealers can retail UV's

        for (Product2 p : products) {
            if (p.RecordTypeID == irWholeGoodRecTypeID || p.RecordTypeID == irAttachmentRecTypeID) {
                Product2 old;
                if (Trigger.isUpdate) {
                    old = (Product2) Trigger.oldMap.get(p.ID);
                }
                boolean justBecameIRProduct = ((old != null && p.RecordTypeID != old.RecordTypeID) ? true : false);
                //set default value Dealer_Type__c
                if (String.isBlank(p.Dealer_Types__c) && (Trigger.isInsert || justBecameIRProduct)) {
                    if (p.Category__c == 'UV') {
                        p.Dealer_Types__c = crOnly;
                    } else {
                        p.Dealer_Types__c = crAndDR;
                    }
                }
            } else {
                if (!String.isBlank(p.Dealer_Types__c)) {
                    p.Dealer_Types__c = null;
                }
            }
        }
    }

    private void setRecordType(List<Product2> products) {
        ID irWholeGoodRecTypeID = RecordTypes.product_WholeGood.ID; //mainted by Independent Retail team
        ID irAttachmentRecTypeID = RecordTypes.product_Attachment.ID; //mainted by Independent Retail team
        ID irPartRecTypeID = RecordTypes.product_Part.ID; // Set by Agora in fall 2024, all parts sourced from INFOR
        ID genericRecTypeID = RecordTypes.product_Generic.ID; //maintained by system admin
        ID edwFinishedGoodsID = RecordTypes.product_FinishedGoodsFromEDW.ID;
        ID otherRecTypeID = RecordTypes.product_Other.ID; //maintained by system admin

        //
        for (Product2 p : products) {
            if (p.RecordTypeID == irPartRecTypeID || p.RecordTypeID == otherRecTypeID || p.RecordTypeID == genericRecTypeID || p.RecordTypeID == edwFinishedGoodsID) {
                //allow it; nothing to do
            } else if ((Trigger.isInsert) || (Trigger.isUpdate && p.RecordTypeId == null)) {
                //Product2.Family is an IR Categorization
                if (p.Family == 'Attachment') {
                    //mburr preserved sundogs ability to load products via jquery scripts for IR Dealer Order Testing
                    p.RecordTypeId = irAttachmentRecTypeID;
                } else if (!String.isBlank(p.Family)) {
                    //mburr preserved sundogs ability to load products via jquery scripts for IR Dealer Order Testing
                    p.RecordTypeId = irWholeGoodRecTypeID; //
                } else {
                    p.RecordTypeId = otherRecTypeID; //
                }
            }
        }
    }
    private void setCommerceJson(List<Product2> products) {
        for (Product2 p : products) {
            ProductCommerceParser parser = new ProductCommerceParser(p);
            parser.mapModelToDomain(p);
        }
    }

    private void clearOverrides(List<Product2> products) {
        //  if Product2.Inventory_Override__c = false, clears override quantity
        //  if Product2.Production_Override__c = false, clears override quantity and dates
        for (Product2 p : products) {
            if (p.Inventory_Override__c == false) {
                if (p.Inventory_Override_Quantity__c != null) {
                    p.Inventory_Override_Quantity__c = null;
                }
            }
            if (p.Production_Override__c == false) {
                if (p.Production_Quantity__c != null) {
                    p.Production_Quantity__c = null;
                }
                if (p.Production_Date__c != null) {
                    p.Production_Date__c = null;
                }
                if (p.Displayed_Production_Override_Date__c != null) {
                    p.Displayed_Production_Override_Date__c = null;
                }
            }
        }
    }
    private void processInventoryRemaining(Map<Id, Product2> oldMap, List<Product2> products) {
        for (Product2 p : products) {
            if (oldMap.get(p.Id) == null) {
                //only process logic on an update
                continue;
            }

            Product2 old = oldMap.get(p.Id);
            Boolean hasOverride = p.Production_Override__c || p.Inventory_Override__c;
            Boolean inventoryRemainingUpdated = false;

            //if inventory override has been checked, set quantity available to override value
            if (!old.Production_Override__c && p.Production_Override__c || p.Production_Override__c && (old.Production_Quantity__c != p.Production_Quantity__c)) {
                p.Inventory_Remaining__c = p.Production_Quantity__c;
                inventoryRemainingUpdated = true;
            }

            if (!old.Inventory_Override__c && p.Inventory_Override__c || p.Inventory_Override__c && (old.Inventory_Override_Quantity__c != p.Inventory_Override_Quantity__c)) {
                p.Inventory_Remaining__c = p.Inventory_Override_Quantity__c;
                inventoryRemainingUpdated = true;
            }

            //when override is in place, in-season orders decrement remaining as they are processed
            //don't reset remaining when override is in place
            ENV__c env = ENV__c.getInstance();
            if (UserInfo.getUserId() == env.Product_Sync_ETL_User_Id__c && !hasOverride && !inventoryRemainingUpdated) {
                p.Inventory_Remaining__c = p.Inventory_Available__c;
            }

            if (p.Production_Date__c != null) {
                Date adjustedOverride = null;
                //2018-01-26.mburr Per S-06809, logic that says 'if Friday then return Monday' is not consistent with the logic used by SQL Server SPR's UpdIR_ITEM_HIERARCHYinventory & RefreshIR_ITEM_HIERARCHY
                //if (SharedHelpers.getDayOfWeek(p.Production_Date__c) == 5) {
                //if original date is friday, carry over to monday
                //    adjustedOverride = SharedHelpers.addBusinessDays(p.Production_Date__c, 1);
                //} else {
                adjustedOverride = SharedHelpers.addBusinessDays(p.Production_Date__c, 2);
                p.Displayed_Production_Override_Date__c = adjustedOverride;
            } else {
                p.Displayed_Production_Override_Date__c = null;
            }

            //TODO: when should this checkbox be displayed
            //p.Availability__c = p.Inventory_Remaining__c > 0;
        }
    }

    private void setRetailPrice(Map<Id, Product2> oldMap, List<Product2> products) {
        //TestData_Order.createStandardPricebookEntries(products);
        Map<Id, Decimal> prodToPrice = new Map<Id, Decimal>();
        for (Product2 p : products) {
            if (p.RecordTypeId == RecordTypes.product_Attachment.Id || p.RecordTypeId == RecordTypes.product_WholeGood.Id) {
                if (p.Retail_Price_US__c != oldMap.get(p.Id).Retail_Price_US__c) {
                    prodToPrice.put(p.Id, p.Retail_Price_US__c);
                }
            }
        }

        List<PriceBookEntry> pbesToUpsert = new List<PriceBookEntry>();
        Map<Id, PriceBookEntry> prodToRetailPBE = new Map<Id, PriceBookEntry>();
        for (PriceBookEntry pbe : [
            SELECT Id, UnitPrice, Product2Id
            FROM PriceBookEntry
            WHERE PriceBook2.Is_Retail__c = TRUE AND (NOT Pricebook2.name LIKE '%canada%') AND Product2Id IN :prodToPrice.keySet()
        ]) {
            prodToRetailPBE.put(pbe.Product2Id, pbe);
        }

        for (Id pid : prodToPrice.keySet()) {
            if (prodToRetailPBE.containsKey(pid)) {
                prodToRetailPBE.get(pid).UnitPrice = prodToPrice.get(pid);
                pbesToUpsert.add(prodToRetailPBE.get(pid));
            } else {
                Decimal price = prodToPrice.get(pid);
                if (price != null && price != 0) {
                    pbesToUpsert.add(new PriceBookEntry(Product2Id = pid, PriceBook2Id = OrderingHelpers.getRetailPriceBookId(), UnitPrice = price, IsActive = true));
                }
            }
        }

        if (!pbesToUpsert.isEmpty()) {
            upsert pbesToUpsert;
        }
    }

    private void addRetailPBE(List<Product2> products) {
        List<PriceBookEntry> pbesToInsertStandard = new List<PriceBookEntry>();
        List<PriceBookEntry> pbesToInsertRetail = new List<PriceBookEntry>();
        for (Product2 p : products) {
            if (
                (p.RecordTypeId == RecordTypes.product_Attachment.Id ||
                p.RecordTypeId == RecordTypes.product_WholeGood.Id) &&
                p.Retail_Price_US__c != null &&
                p.Retail_Price_US__c != 0
            ) {
                PriceBookEntry pbeRetail = new PriceBookEntry(
                    Product2Id = p.Id,
                    PriceBook2Id = OrderingHelpers.getRetailPriceBookId(),
                    UnitPrice = p.Retail_Price_US__c,
                    IsActive = true
                );
                pbesToInsertRetail.add(pbeRetail);
            }

            PriceBookEntry pbeStandard = new PriceBookEntry(
                Product2Id = p.Id,
                PriceBook2Id = OrderingHelpers.getStandardPriceBookId(),
                UnitPrice = 0,
                IsActive = true,
                CurrencyIsoCode = 'USD'
            );

            pbesToInsertStandard.add(pbeStandard);
        }
        system.debug('xxx-Product2TriggerHandler.pbesToInsertStandard:' + pbesToInsertStandard);
        if (!pbesToInsertStandard.isEmpty()) {
            insert pbesToInsertStandard;
        }
        if (!pbesToInsertRetail.isEmpty()) {
            insert pbesToInsertRetail;
        }
    }

    private void updateSimplifiedGrossMarginPBEs(Map<Id, Product2> oldMap, Map<Id, Product2> newMap) {
        Map<Id, PriceBookEntry> prodToRetailPBE = new Map<Id, PriceBookEntry>();
        for (PriceBookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM Pricebookentry WHERE Pricebook2.Is_Retail__c = TRUE AND Product2Id IN :newMap.keySet()]) {
            prodToRetailPBE.put(pbe.Product2Id, pbe);
        }

        Set<Id> prodQuery = new Set<Id>();
        List<Product2> qualifiedRecords = new List<Product2>();
        for (Product2 p : newMap.values()) {
            if (
                (p.RecordTypeId == RecordTypes.product_Attachment.Id ||
                p.RecordTypeId == RecordTypes.product_WholeGood.Id) &&
                p.Retail_Price_US__c != null &&
                p.Retail_Price_US__c != 0 &&
                p.IsActive == true &&
                prodToRetailPBE.containsKey(p.Id) &&
                (oldMap == null ||
                (p.Retail_Price_US__c != oldMap.get(p.Id).Retail_Price_US__c ||
                p.IsActive != oldMap.get(p.Id).IsActive ||
                p.Family != oldMap.get(p.Id).Family ||
                p.Category__c != oldMap.get(p.Id).Category__c ||
                p.Is_XT3_Deck__c != oldMap.get(p.Id).Is_XT3_Deck__c))
            ) {
                prodQuery.add(p.Id);
                qualifiedRecords.add(p);
            }
        }

        if (prodQuery.size() > 100 && Trigger.isInsert) {
            if (!TriggerHelper.hasAlreadyfired()) {
                UpdateLevelPricebookEntriesBatch batch = new UpdateLevelPricebookEntriesBatch();
                Database.executeBatch(batch, 200);
            }
        } else if (prodQuery.size() != 0) {
            Product2Helper.SGMData sgm = Product2Helper.getSGMDataForProducts(prodQuery);

            List<Pricebookentry> pbesToUpsert = Product2Helper.getSGMPriceBookEntriesForProducts(prodToRetailPBE, qualifiedRecords, sgm);

            if (!pbesToUpsert.isEmpty()) {
                upsert pbesToUpsert;
            }
        }
    }

    private void updateChildren(List<Product2> prods) {
        //PREP
        System.debug('JOSH - START');
        List<Id> toProcess = new List<Id>();
        for (Product2 p : prods) {
            Product2 old;
            if (Trigger.isUpdate)
                old = (Product2) Trigger.oldMap.get(p.Id);
            if (
                Trigger.isInsert ||
                (Trigger.isUpdate &&
                (p.RecordTypeId != old.RecordTypeId ||
                p.Name != old.Name ||
                p.Product_Code_External_Id__c != old.Product_Code_External_Id__c ||
                p.ProductCode != old.ProductCode ||
                p.Master_SKU__c != old.Master_SKU__c ||
                p.Detail_SKU__c != old.Detail_SKU__c))
            ) {
                toProcess.add(p.Id);
            }
        }
        if (toProcess.size() > 0) {
            List<Product_Region__c> regions = [SELECT Name FROM Product_Region__c WHERE Product__c IN :toProcess];
            List<Product_Translation__c> translates = [SELECT Name FROM Product_Translation__c WHERE Product__c IN :toProcess];
            System.debug('JOSH - ' + regions + ' ' + translates);

            for (Product_Region__c pr : regions) {
                pr.Name = 'x';
            }
            update regions;
            for (Product_Translation__c pt : translates) {
                pt.Name = 'x';
            }
            update translates;
        }
    }

    private void updateFulfillFrom(List<Product2> newProducts, Map<Id, Product2> oldMap) {
        //Agora will populate the text(20) field Update_Fulfill_From_Text__c.  This trigger will update the multi-select picklist Update_Fulfill__c.
        //The value in Update_Fulfill_From_Text__c will be cleared after updating the multi-select picklist.

        // Handle new insertions.
        if (Trigger.isInsert) {
            for (Product2 product : newProducts) {
                product.Update_Fulfill_From__c = String.isBlank(product.Update_Fulfill_From_Text__c) ? null : product.Update_Fulfill_From_Text__c;
                product.Update_Fulfill_From_Text__c = null;
            }
        }
        // Handle updates to existing records.
        else if (Trigger.isUpdate) {
            for (Product2 newProduct : newProducts) {
                Product2 oldProduct = oldMap.get(newProduct.Id);
                // Check if 'Update_Fulfill_From_Text__c' has been changed and is not blank, and the new value is not already part of 'Update_Fulfill_From__c'.
                if (
                    oldProduct.Update_Fulfill_From_Text__c != newProduct.Update_Fulfill_From_Text__c &&
                    !String.isBlank(newProduct.Update_Fulfill_From_Text__c) &&
                    (newProduct.Update_Fulfill_From__c == null || !newProduct.Update_Fulfill_From__c.contains(newProduct.Update_Fulfill_From_Text__c))
                ) {
                    // Append or set the 'Update_Fulfill_From_Text__c' value to 'Update_Fulfill_From__c'.
                    newProduct.Update_Fulfill_From__c = newProduct.Update_Fulfill_From__c == null
                        ? newProduct.Update_Fulfill_From_Text__c
                        : newProduct.Update_Fulfill_From__c + ';' + newProduct.Update_Fulfill_From_Text__c;
                }
                newProduct.Update_Fulfill_From_Text__c = null;
            }
        }
        // For other trigger events, no action is performed.
    }

    private void updateShippingAndDeliveryDates(Map<Id, Product2> newMap, Map<Id, Product2> oldMap) {
        Integer DAYS_FOR_TRANSFER_FROM_PLANT_TO_WAREHOUSE_US = 1; // number of days required to move the physical unit from plant to warehouse
        Integer DAYS_FOR_PICK_AND_PACK_ENOUGH_INVENTORY = 1; // 0 day pick + 1 day for pack
        Integer DAYS_FOR_PICK_AND_PACK_NOT_ENOUGH_INVENTORY = 0; // 0 day pick + 0 day for pack
        Integer DAYS_FOR_SHIPPING = 5;

        Date today = System.today();

        for (Id prodId : newMap.keySet()) {
            Product2 newProduct = newMap.get(prodId);
            Product2 oldProduct = oldMap.get(prodId);

            Boolean isAvailabilityInformationChanged =
                newProduct.Availability__c != oldProduct.Availability__c ||
                newProduct.Availability_Date__c != oldProduct.Availability_Date__c ||
                newProduct.Inventory_Available__c != oldProduct.Inventory_Available__c ||
                newProduct.Inventory_Remaining__c != oldProduct.Inventory_Remaining__c;

            Boolean isProductAvailableNow = newProduct.Inventory_Remaining__c > 0;

            if (isAvailabilityInformationChanged) {
                if (isProductAvailableNow) {
                    newProduct.IR_INV_EXP_SHIP_Y_AVAIL_DT__c = Product2Helper.addDaysSkippingSundays(
                        today,
                        DAYS_FOR_TRANSFER_FROM_PLANT_TO_WAREHOUSE_US + DAYS_FOR_PICK_AND_PACK_ENOUGH_INVENTORY
                    );
                    newProduct.IR_INV_EXP_RECV_Y_AVAIL_DT__c = Product2Helper.addDaysSkippingWeekend(newProduct.IR_INV_EXP_SHIP_Y_AVAIL_DT__c, DAYS_FOR_SHIPPING);
                } else {
                    newProduct.IR_INV_EXP_SHIP_Y_AVAIL_DT__c = null;
                    newProduct.IR_INV_EXP_RECV_Y_AVAIL_DT__c = null;
                }

                if (newProduct.Availability_Date__c != null && newProduct.Availability_Date__c >= today) {
                    newProduct.IR_INV_EXP_SHIP_N_AVAIL_DT__c = Product2Helper.addDaysSkippingSundays(newProduct.Availability_Date__c, DAYS_FOR_PICK_AND_PACK_NOT_ENOUGH_INVENTORY);
                    newProduct.IR_INV_EXP_RECV_N_AVAIL_DT__c = Product2Helper.addDaysSkippingWeekend(newProduct.IR_INV_EXP_SHIP_N_AVAIL_DT__c, DAYS_FOR_SHIPPING);
                } else {
                    newProduct.IR_INV_EXP_SHIP_N_AVAIL_DT__c = null;
                    newProduct.IR_INV_EXP_RECV_N_AVAIL_DT__c = null;
                }
            }
        }
    }

    private void adjustProductCategories() {
        // filter to check the update on commerce JSON
        if (Trigger.isInsert) {
            B2B_ProductCategoryHelper.adjustProductCategories(Trigger.newMap.keySet());
        } else if (Trigger.isUpdate) {
            Set<Id> pIds = new Set<Id>();
            for (Id pId : Trigger.newMap.keySet()) {
                Product2 p_old = (Product2) Trigger.oldMap.get(pId);
                Product2 p_new = (Product2) Trigger.newMap.get(pId);
                if (p_old.Commerce_JSON__c != p_new.Commerce_JSON__c || p_old.B2B_Product_Type__c != p_new.B2B_Product_Type__c) {
                    pIds.add(pId);
                }
            }
            B2B_ProductCategoryHelper.adjustProductCategories(pIds);
        }
    }
}
