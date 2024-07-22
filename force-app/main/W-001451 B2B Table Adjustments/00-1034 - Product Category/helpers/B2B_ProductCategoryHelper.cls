public with sharing class B2B_ProductCategoryHelper {
    public static void adjustProductCategories(Set<Id> product2Ids) {
        List<ProductCategoryProduct> pcpToInsert = new List<ProductCategoryProduct>();
        List<ProductCategoryProduct> pcpToUpdate = new List<ProductCategoryProduct>();
        List<ProductCategoryProduct> pcpToDelete = new List<ProductCategoryProduct>();
        List<Product2> prs = [
            SELECT Id, B2B_Product_Type__c, Commerce_JSON__c, (SELECT Id, IsPrimaryCategory, ProductCategory.Name FROM ProductCategoryProducts)
            FROM Product2
            WHERE Id IN :product2Ids
        ];
        Map<String, ProductCategory> nameProductCategoryMap = getNameProductCategoryMap();

        for (Product2 p : prs) {
            // check if Product Category link is there, if not then create on insert
            if (getProductCategoryLink(p, 'Products').isEmpty() && !String.isBlank(nameProductCategoryMap.get('Products')?.Id)) {
                String productCategoryId = nameProductCategoryMap.get('Products')?.Id;
                pcpToInsert.add(new ProductCategoryProduct(ProductCategoryId = productCategoryId, ProductId = p.Id, IsPrimaryCategory = false));
            }

            if (p.B2B_Product_Type__c == 'Whole Goods') {
                List<ProductCategoryProduct> wgPcps = getProductCategoryLink(p, 'Whole Goods');
                String productCategoryId = nameProductCategoryMap.get('Whole Goods')?.Id;
                if (wgPcps.isEmpty()) {
                    pcpToInsert.add(new ProductCategoryProduct(ProductCategoryId = productCategoryId, ProductId = p.Id, IsPrimaryCategory = true));
                } else if (wgPcps.size() == 1) {
                    // wgPcps[0].ProductCategoryId = productCategoryId;
                    wgPcps[0].ProductId = p.Id;
                    wgPcps[0].IsPrimaryCategory = true;
                    pcpToUpdate.add(wgPcps[0]);
                }

                pcpToDelete.addAll(getProductCategoryLink(p, 'Parts'));
                pcpToDelete.addAll(getNonRelavantPartsSubProductCategoryLinks(p, null));
            } else if (p.B2B_Product_Type__c == 'Parts') {
                CommerceData cdata = getCategoryFromCommerceJson(p.Commerce_JSON__c);

                if (cdata != null && cdata.category == 'Handheld') {
                    List<ProductCategoryProduct> hhPcps = getProductCategoryLink(p, 'Handheld');
                    String productCategoryId = nameProductCategoryMap.get('Handheld')?.Id;
                    if (hhPcps.isEmpty()) {
                        pcpToInsert.add(new ProductCategoryProduct(ProductCategoryId = productCategoryId, ProductId = p.Id, IsPrimaryCategory = true));
                    } else if (hhPcps.size() == 1) {
                        // wgPcps[0].ProductCategoryId = productCategoryId;
                        hhPcps[0].ProductId = p.Id;
                        hhPcps[0].IsPrimaryCategory = true;
                        pcpToUpdate.add(hhPcps[0]);
                    }

                    pcpToDelete.addAll(getProductCategoryLink(p, 'Parts'));
                    pcpToDelete.addAll(getProductCategoryLink(p, 'Whole Goods'));
                    pcpToDelete.addAll(getNonRelavantPartsSubProductCategoryLinks(p, cdata.category));
                } else {
                    // get category from commerce JSON
                    String subProductCategoryId = (cdata == null) ? null : nameProductCategoryMap.get(cdata.category)?.Id;
                    Boolean partIsPrimary = (subProductCategoryId == null);

                    List<ProductCategoryProduct> partPcps = getProductCategoryLink(p, 'Parts');
                    String productCategoryId = nameProductCategoryMap.get('Parts')?.Id;
                    if (partPcps.isEmpty() && !String.isBlank(productCategoryId)) {
                        pcpToInsert.add(new ProductCategoryProduct(ProductCategoryId = productCategoryId, ProductId = p.Id, IsPrimaryCategory = partIsPrimary));
                    } else if (partPcps.size() == 1) {
                        // partPcps[0].ProductCategoryId = productCategoryId;
                        partPcps[0].ProductId = p.Id;
                        partPcps[0].IsPrimaryCategory = partIsPrimary;
                        pcpToUpdate.add(partPcps[0]);
                    }

                    if (cdata != null && !String.isBlank(cdata.category)) {
                        List<ProductCategoryProduct> cDataPcps = getProductCategoryLink(p, cdata.category);
                        if (cDataPcps.isEmpty()) {
                            if (!String.isBlank(subProductCategoryId)) {
                                pcpToInsert.add(new ProductCategoryProduct(ProductCategoryId = subProductCategoryId, ProductId = p.Id, IsPrimaryCategory = !partIsPrimary));
                            }
                        }
                    }

                    pcpToDelete.addAll(getProductCategoryLink(p, 'Whole Goods'));
                    if (cdata != null && !String.isBlank(cdata.category))
                        pcpToDelete.addAll(getNonRelavantPartsSubProductCategoryLinks(p, cdata.category));
                }
            }
        }

        // DML Operation
        if (!pcpToDelete.isEmpty()) {
            delete pcpToDelete;
        }

        if (!pcpToUpdate.isEmpty()) {
            update pcpToUpdate;
        }

        if (!pcpToInsert.isEmpty()) {
            system.debug('pcpToInsert');
            system.debug(pcpToInsert);
            insert pcpToInsert;
        }
    }

    // Helper Methods
    private static List<ProductCategoryProduct> getProductCategoryLink(Product2 p, String productCategoryName) {
        List<ProductCategoryProduct> pcps = new List<ProductCategoryProduct>();
        for (ProductCategoryProduct pcp : p.ProductCategoryProducts) {
            if (pcp.ProductCategory.Name == productCategoryName) {
                pcps.add(pcp);
            }
        }
        return pcps;
    }

    private static List<ProductCategoryProduct> getNonRelavantPartsSubProductCategoryLinks(Product2 p, String productCategoryName) {
        List<ProductCategoryProduct> pcps = new List<ProductCategoryProduct>();
        for (ProductCategoryProduct pcp : p.ProductCategoryProducts) {
            if (pcp.ProductCategory.Name != 'Products' && pcp.ProductCategory.Name != 'Parts' && pcp.ProductCategory.Name != 'Whole Goods') {
                if (productCategoryName == null || pcp.ProductCategory.Name != productCategoryName) {
                    pcps.add(pcp);
                }
            }
        }
        return pcps;
    }

    private static Map<String, ProductCategory> getNameProductCategoryMap() {
        Map<String, ProductCategory> nameProductCategoryMap = new Map<String, ProductCategory>();
        for (ProductCategory pc : [SELECT Id, Name FROM ProductCategory]) {
            nameProductCategoryMap.put(pc.Name, pc);
        }

        return nameProductCategoryMap;
    }

    public class CommerceData {
        public String category;
    }

    public static CommerceData getCategoryFromCommerceJson(String jsonString) {
        // Deserialize JSON string to list of Root objects
        try {
            List<CommerceData> cDatas = (List<CommerceData>) JSON.deserialize(jsonString, List<CommerceData>.class);
            return cDatas[0];
        } catch (Exception exp) {
            System.debug(exp);
            return null;
        }
    }
}
