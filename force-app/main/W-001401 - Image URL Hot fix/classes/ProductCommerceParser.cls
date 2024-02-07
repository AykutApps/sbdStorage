public class ProductCommerceParser {
    public Product model = null;
    public Map<String, String> imageMap = null;
    public Product2 currentProduct = null; //used so primary image can be pulled from gallery

    public ProductCommerceParser(Product2 p) {
        if (String.isNotBlank(p.Commerce_JSON__c)) {
            List<Product> temp;
            try {
                system.debug('xxx-JSON: ' + p.Commerce_JSON__c);
                system.debug('xxx-CLASS: ' + List<Product>.class);
                temp = (List<Product>) JSON.deserialize(p.Commerce_JSON__c, List<Product>.class);
            } catch (Exception ex) {
                //no JSON available
            }
            if (temp != null && !temp.isEmpty()) {
                model = temp[0];
                system.debug('xxx-model:' + model);
                imageMap = new Map<String, String>();
                String itemNumber = model.itemNumber + '_';
                if (model.images != null && !model.images.isEmpty()) {
                    for (String url : model.images) {
                        String key = url.substringAfterLast(itemNumber);
                        //includes file extention
                        imageMap.put(key, url);
                    }
                }
            }
        }
        currentProduct = p;
    }

    public void mapModelToDomain(Product2 p) {
        if (imageMap != null) {
            p.Image_Primary__c = null;

            if (p.RecordTypeId == RecordTypes.product_Attachment.Id) {
                p.Image_Primary__c = getImageByKey('part_detail_large');

                if (String.isBlank(p.Image_Primary__c)) {
                    p.Image_Primary__c = getImageByKey('part_detail_zoom');
                }
            }

            if (String.isBlank(p.Image_Primary__c)) {
                p.Image_Primary__c = getImageByKey('product_detail');
            }
            if (String.isBlank(p.Image_Primary__c)) {
                p.Image_Primary__c = getImageByKey('product_detail_large');
            }
            if (String.isBlank(p.Image_Primary__c)) {
                p.Image_Primary__c = getImageByKey('product_detail_zoom');
            }
            if (model != null && model.images != null && !model.images.isEmpty() && String.isBlank(p.Image_Primary__c)) {
                p.Image_Primary__c = model.images[0].replace('http:', 'https:'); //added 1/16/2020 Dunk -- to handle the new JSONs from the service; instead of using
                //specific strings in the file name, we now just grab the first image from the model
                //under the tag images
            }
        }

        if (model != null && model.attributes != null) {
            if (model.attributes.FEATURES != null) {
                List<Attribute> features = model.attributes.FEATURES;
                if (features.size() > 0) {
                    p.Feature_1__c = features[0].values[0].value;
                }
                if (features.size() > 1) {
                    p.Feature_2__c = features[1].values[0].value;
                }
                if (features.size() > 2) {
                    p.Feature_3__c = features[2].values[0].value;
                }
            }
        }
    }

    public List<OrderingModels.MediaItem> getGallery() {
        List<OrderingModels.MediaItem> items = new List<OrderingModels.MediaItem>();
        if (imageMap == null) {
            return items;
        }

        String key = 'product_detail';
        if (imageMap.containsKey(key + '.png')) {
            items.add(new OrderingModels.MediaItem('1', key, getImageByKey(key), getImageByKey(key + '_large')));
        }

        key = '2_product_detail';
        if (imageMap.containsKey(key + '.png')) {
            items.add(new OrderingModels.MediaItem('2', key, getImageByKey(key), getImageByKey(key + '_large')));
        }

        key = '3_product_detail';
        if (imageMap.containsKey(key + '.png')) {
            items.add(new OrderingModels.MediaItem('3', key, getImageByKey(key), getImageByKey(key + '_large')));
        }

        key = '4_product_detail';
        if (imageMap.containsKey(key + '.png')) {
            items.add(new OrderingModels.MediaItem('4', key, getImageByKey(key), getImageByKey(key + '_large')));
        }

        key = '5_product_detail';
        if (imageMap.containsKey(key + '.png')) {
            items.add(new OrderingModels.MediaItem('5', key, getImageByKey(key), getImageByKey(key + '_large')));
        }

        if (items.isEmpty() && String.isNotBlank(currentProduct.Image_Primary__c)) {
            items.add(new OrderingModels.MediaItem('1', 'product_detail', currentProduct.Image_Primary__c, currentProduct.Image_Primary__c));
        }

        return items;
    }

    public List<AttributeGrouping> getSpecifications() {
        if (model.attributes != null) {
            if (model.attributes.SPECS != null) {
                Map<String, List<Attribute>> attributeMap = new Map<String, List<Attribute>>();
                for (Attribute a : model.attributes.SPECS) {
                    String key = a.grouping;
                    if (key == null) {
                        continue;
                    }
                    List<Attribute> temp = null;
                    if (attributeMap.containsKey(key)) {
                        temp = attributeMap.get(key);
                    } else {
                        temp = new List<Attribute>();
                    }
                    temp.add(a);
                    attributeMap.put(key, temp);
                }

                List<AttributeGrouping> groupings = new List<AttributeGrouping>();
                Integer x = 0;
                for (String grouping : attributeMap.keySet()) {
                    groupings.add(new AttributeGrouping(String.valueOf(x), grouping, attributeMap.get(grouping)));
                    x++;
                }
                return groupings;
            }
        }

        return null;
    }

    public Map<String, Attribute> getSpecificationMap(Set<String> specKeySet) {
        if (model.attributes != null) {
            if (model.attributes.SPECS != null) {
                Map<String, Attribute> attributeMap = new Map<String, Attribute>();
                for (Attribute a : model.attributes.SPECS) {
                    String key = a.grouping + '|' + a.identifier;
                    attributeMap.put(key, a);
                    specKeySet.add(key);
                }

                return attributeMap;
            }
        }

        return null;
    }

    public List<Product> getAccessories() {
        if (model != null && model.relatedProducts != null) {
            RelatedProducts relatedProducts = model.relatedProducts;
            if (relatedProducts.ACCESSORY != null) {
                for (Product p : relatedProducts.ACCESSORY) {
                    for (String url : p.images) {
                        if (url.contains(p.itemNumber + '_part_listing_small')) {
                            p.imagePrimaryUrl = url.replace('http:', 'https:');
                            break;
                        }

                        for (Price cost : p.listPrices) {
                            cost.priceFormatted = SharedHelpers.formatCurrency(cost.price);
                        }

                        for (Price cost : p.offerPrices) {
                            cost.priceFormatted = SharedHelpers.formatCurrency(cost.price);
                        }
                    }
                }
                return relatedProducts.ACCESSORY;
            }
        }

        return null;
    }

    private String getImageByKey(String key) {
        //tofuture - this is likely not needed anymore because of changes to mapModelToDomain
        if (imageMap.containsKey(key + '.png')) {
            return imageMap.get(key + '.png').replace('http:', 'https:');
        }
        if (imageMap.containsKey(key + '.jpg')) {
            return imageMap.get(key + '.jpg').replace('http:', 'https:');
        }
        return null;
    }

    public class Product {
        public String catentryId { get; set; }
        public String itemNumber { get; set; }
        public String name { get; set; }
        public String shortDescription { get; set; }
        public String longDescription { get; set; }
        public List<Price> listPrices { get; set; }
        public List<Price> offerPrices { get; set; }
        public Attributes attributes { get; set; }
        public RelatedProducts relatedProducts { get; set; }
        public List<String> images { get; set; }

        //these properties are not dependent on JSON
        public String imagePrimaryUrl { get; set; }
    }

    public class Price {
        public Decimal price { get; set; }
        //public String currency {get;set;} //TODO: currency is a reserved word, do a replace before parsing to use it

        //these properties are not dependent on JSON
        public String priceFormatted { get; set; }
    }

    public class Attributes {
        public List<Attribute> RATINGS { get; set; }
        public List<Attribute> SPECS { get; set; }
        public List<Attribute> FEATURES { get; set; }
    }

    public class Attribute {
        public String identifier { get; set; }
        public String name { get; set; }
        public String grouping { get; set; }
        public List<Value> values { get; set; }
        public Decimal sequence { get; set; }
    }

    public class Value {
        public String value { get; set; }
        public Decimal sequence { get; set; }
    }

    public class RelatedProducts {
        public List<Product> ACCESSORY { get; set; }
    }

    //model not dependent on JSON
    public class AttributeGrouping {
        public AttributeGrouping(String id, String name, List<Attribute> attributes) {
            this.id = id;
            this.name = name;
            this.attributes = attributes;
        }
        public String id { get; set; }
        public String name { get; set; }
        public List<Attribute> attributes { get; set; }
    }
}
