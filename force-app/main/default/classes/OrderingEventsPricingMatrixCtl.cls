public class OrderingEventsPricingMatrixCtl {
    public List<DataItem> productListToView { get; set; }
    public List<DataItem> orderingEventProductsList { get; set; }
    public String filterText { get; set; }
    public Ordering_Event__c orderEvent { get; set; }
    public String oeId { get; set; }
    List<Id> pricebookIds;
    Map<String, String> productPricebookPriceMap;

    public OrderingEventsPricingMatrixCtl(String oeIdProvided) {
        oeId = oeIdProvided;
        initateOrderingEventsPricingMatrix();
    }

    public OrderingEventsPricingMatrixCtl() {
        Map<String, String> urlParams = ApexPages.currentPage().getParameters();
        oeId = urlParams.get('oeId');
        initateOrderingEventsPricingMatrix();
    }

    public void initateOrderingEventsPricingMatrix() {
        getOrderEventWithProducts();
        getListOfPricebookIds();
        getProductPricebookPriceMap();
        setOrderingEventProductsList();
    }

    private void getOrderEventWithProducts() {
        orderEvent = [
            SELECT
                Id,
                Name,
                Start_Date__c,
                Event_Type__c,
                Order_Type__c,
                Ordering_Regions__c,
                Included_Regions__c,
                Price_Book_Retail__c,
                Price_Book_Level_1__c,
                Price_Book_Level_2__c,
                Price_Book_Level_3__c,
                Price_Book_Level_4__c,
                Price_Book_Level_5__c,
                Price_Book_Level_6__c,
                Price_Book_Level_7__c,
                (
                    SELECT
                        Id,
                        Product__c,
                        Product__r.Description,
                        Product__r.Master_SKU__c,
                        Product__r.Brand__c,
                        Product__r.ProductCode,
                        Product__r.Detail_SKU__c,
                        Product__r.Section__c
                    FROM Ordering_Event_Products__r
                )
            FROM Ordering_Event__c
            WHERE Id = :oeId
        ];
    }

    private void getListOfPricebookIds() {
        pricebookIds = new List<Id>();
        if (orderEvent.Price_Book_Retail__c != null)
            pricebookIds.add(orderEvent.Price_Book_Retail__c);
        if (orderEvent.Price_Book_Level_1__c != null)
            pricebookIds.add(orderEvent.Price_Book_Level_1__c);
        if (orderEvent.Price_Book_Level_2__c != null)
            pricebookIds.add(orderEvent.Price_Book_Level_2__c);
        if (orderEvent.Price_Book_Level_3__c != null)
            pricebookIds.add(orderEvent.Price_Book_Level_3__c);
        if (orderEvent.Price_Book_Level_4__c != null)
            pricebookIds.add(orderEvent.Price_Book_Level_4__c);
        if (orderEvent.Price_Book_Level_5__c != null)
            pricebookIds.add(orderEvent.Price_Book_Level_5__c);
        if (orderEvent.Price_Book_Level_6__c != null)
            pricebookIds.add(orderEvent.Price_Book_Level_6__c);
        if (orderEvent.Price_Book_Level_7__c != null)
            pricebookIds.add(orderEvent.Price_Book_Level_7__c);
    }

    private void getProductPricebookPriceMap() {
        productPricebookPriceMap = new Map<String, String>();
        List<PricebookEntry> pricebookEntiries = [
            SELECT Id, format(UnitPrice) price, Product2Id, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id IN (SELECT Product__c FROM Ordering_Event_Product__c WHERE Ordering_Event__c = :oeId) AND Pricebook2Id IN :pricebookIds
        ];

        for (PricebookEntry pe : pricebookEntiries) {
            productPricebookPriceMap.put(String.valueof(pe.Product2Id) + String.valueof(pe.Pricebook2Id), string.valueof(pe.get('price')));
        }
    }

    public void setOrderingEventProductsList() {
        orderingEventProductsList = new List<DataItem>();
        for (Ordering_Event_Product__c oep : orderEvent.Ordering_Event_Products__r) {
            String retailPrice = productPricebookPriceMap.get(String.valueof(oep.Product__c) + String.valueof(orderEvent.Price_Book_Retail__c));
            String level1 = productPricebookPriceMap.get(String.valueof(oep.Product__c) + String.valueof(orderEvent.Price_Book_Level_1__c));
            String level2 = productPricebookPriceMap.get(String.valueof(oep.Product__c) + String.valueof(orderEvent.Price_Book_Level_2__c));
            String level3 = productPricebookPriceMap.get(String.valueof(oep.Product__c) + String.valueof(orderEvent.Price_Book_Level_3__c));
            String level4 = productPricebookPriceMap.get(String.valueof(oep.Product__c) + String.valueof(orderEvent.Price_Book_Level_4__c));
            String level5 = productPricebookPriceMap.get(String.valueof(oep.Product__c) + String.valueof(orderEvent.Price_Book_Level_5__c));
            String level6 = productPricebookPriceMap.get(String.valueof(oep.Product__c) + String.valueof(orderEvent.Price_Book_Level_6__c));
            String level7 = productPricebookPriceMap.get(String.valueof(oep.Product__c) + String.valueof(orderEvent.Price_Book_Level_7__c));

            orderingEventProductsList.add(
                new DataItem(
                    oep.Product__r.Section__c,
                    oep.Product__r.Brand__c,
                    oep.Product__r.ProductCode,
                    oep.Product__r.Detail_SKU__c,
                    oep.Product__r.Master_SKU__c,
                    oep.Product__r.Description,
                    retailPrice,
                    level1,
                    level2,
                    level3,
                    level4,
                    level5,
                    level6,
                    level7
                )
            );
        }
        orderingEventProductsList.sort();
        productListToView = orderingEventProductsList.clone();
    }

    public void filterData() {
        system.debug(filterText);
        if (String.isBlank(filterText)) {
            productListToView = orderingEventProductsList.clone();
        } else {
            List<DataItem> tempProductList = new List<DataItem>();
            for (DataItem item : orderingEventProductsList) {
                if (item.ProductCode.contains(filterText) || item.DetailSKU.contains(filterText) || item.MasterSKU.contains(filterText) || item.Description.contains(filterText)) {
                    tempProductList.add(item);
                }
                productListToView = tempProductList.clone();
            }
        }
    }

    public void resetfilter() {
        filterText = null;
        filterData();
    }

    public class DataItem implements Comparable {
        public String Section { get; set; }
        public String Brand { get; set; }
        public String ProductCode { get; set; }
        public String DetailSKU { get; set; }
        public String MasterSKU { get; set; }
        public String Description { get; set; }
        public String RetailPrice { get; set; }
        public String Level1 { get; set; }
        public String Level2 { get; set; }
        public String Level3 { get; set; }
        public String Level4 { get; set; }
        public String Level5 { get; set; }
        public String Level6 { get; set; }
        public String Level7 { get; set; }
        public String CompareString { get; set; }

        public DataItem(
            String sec,
            String brd,
            String pco,
            String dsku,
            String msku,
            String dsc,
            String rp,
            String l1,
            String l2,
            String l3,
            String l4,
            String l5,
            String l6,
            String l7
        ) {
            Section = sec;
            Brand = brd;
            ProductCode = pco;
            DetailSKU = dsku;
            MasterSKU = msku;
            Description = dsc;
            RetailPrice = rp;
            Level1 = l1;
            Level2 = l2;
            Level3 = l3;
            Level4 = l4;
            Level5 = l5;
            Level6 = l6;
            Level7 = l7;
            CompareString = sec + rp;
        }

        public Integer compareTo(Object other) {
            DataItem dt1 = (DataItem) this;
            DataItem dt2 = (DataItem) other;

            return dt1.CompareString.compareTo(dt2.CompareString);
        }
    }

    public void AptE() {
        system.debug('test');
    }

    public void AptEr() {
        String MyName = 'test3';
        system.debug('test');
    }
}
