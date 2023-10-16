public without sharing class OrderingEventsPricingMatrixCtl {
    public List<DataItem> productListToView { get; set; }
    public List<DataItem> orderingEventProductsList { get; set; }
    public String filterText { get; set; }
    public Ordering_Event__c orderEvent { get; set; }
    public String oeId { get; set; }
    List<Id> pricebookIds;
    Map<String, String> productPricebookPriceMap;

    public OrderingEventsPricingMatrixCtl() {
        Map<String, String> urlParams = ApexPages.currentPage().getParameters();
        oeId = urlParams.get('oeId');
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
        Set<String> pricebookFields = new Set<String>{
            'Price_Book_Retail__c',
            'Price_Book_Level_1__c',
            'Price_Book_Level_2__c',
            'Price_Book_Level_3__c',
            'Price_Book_Level_4__c',
            'Price_Book_Level_5__c',
            'Price_Book_Level_6__c',
            'Price_Book_Level_7__c'
        };

        for (SObjectField field : pricebookFields) {
            Id pricebookId = (Id) orderEvent.get(field);
            if (pricebookId != null) {
                pricebookIds.add(pricebookId);
            }
        }
    }

    private void getProductPricebookPriceMap() {
        productPricebookPriceMap = new Map<String, String>();
        List<PricebookEntry> pricebookEntries = [
            SELECT Id, format(UnitPrice) price, Product2Id, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id IN (SELECT Product__c FROM Ordering_Event_Product__c WHERE Ordering_Event__c = :oeId) AND Pricebook2Id IN :pricebookIds
        ];

        for (PricebookEntry pe : pricebookEntries) {
            productPricebookPriceMap.put(String.valueOf(pe.Product2Id) + String.valueOf(pe.Pricebook2Id), String.valueOf(pe.get('price')));
        }
    }

    public void setOrderingEventProductsList() {
        orderingEventProductsList = new List<DataItem>();
        for (Ordering_Event_Product__c oep : orderEvent.Ordering_Event_Products__r) {
            DataItem item = new DataItem(
                oep.Product__r.Section__c,
                oep.Product__r.Brand__c,
                oep.Product__r.ProductCode,
                oep.Product__r.Detail_SKU__c,
                oep.Product__r.Master_SKU__c,
                oep.Product__r.Description,
                getPrice(oep.Product__c, orderEvent.Price_Book_Retail__c),
                getPrice(oep.Product__c, orderEvent.Price_Book_Level_1__c),
                getPrice(oep.Product__c, orderEvent.Price_Book_Level_2__c),
                getPrice(oep.Product__c, orderEvent.Price_Book_Level_3__c),
                getPrice(oep.Product__c, orderEvent.Price_Book_Level_4__c),
                getPrice(oep.Product__c, orderEvent.Price_Book_Level_5__c),
                getPrice(oep.Product__c, orderEvent.Price_Book_Level_6__c),
                getPrice(oep.Product__c, orderEvent.Price_Book_Level_7__c)
            );
            orderingEventProductsList.add(item);
        }
        orderingEventProductsList.sort();
    }

    private String getPrice(Id productId, Id pricebookId) {
        return productPricebookPriceMap.get(String.valueOf(productId) + String.valueOf(pricebookId));
    }

    public void filterData() {
        if (filterText == null) {
            orderingEventProductsList.sort();
        } else {
            List<DataItem> tempProductList = new List<DataItem>();
            for (DataItem item : orderingEventProductsList) {
                if (item.ProductCode.contains(filterText) || item.DetailSKU.contains(filterText) || item.MasterSKU.contains(filterText) || item.Description.contains(filterText)) {
                    tempProductList.add(item);
                }
            }
            productListToView = tempProductList;
        }
    }

    public void resetFilter() {
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
}
