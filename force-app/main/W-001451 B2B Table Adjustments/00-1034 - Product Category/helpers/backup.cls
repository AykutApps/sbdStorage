public without sharing class B2B_ProductCategoryHelper {
    /*  analyze JSON from Demandware/PIM stored on Product2 and 

    2024-06    Aykut (CRM Agile Team) creates class per OO-1034: Salesforce SBD - Assign products to category
    2024-07-19 mburr(MJ) populated Product2.Section__c to 'Part' or 'Handheld' if not populated - applies to Product2 Record Type 'Part' only
*/
    public static void adjustProductCategories(Set<Id> product2Ids) {
        system.debug('xxx - B2B_ProductCategoryHelper.adjustProductCategories is started');
        system.debug(product2Ids);
        List<Product2> productsToUpdate = new List<Product2>();
        List<ProductCategoryProduct> pcpToInsert = new List<ProductCategoryProduct>();
        List<ProductCategoryProduct> pcpToUpdate = new List<ProductCategoryProduct>();
        List<ProductCategoryProduct> pcpToDelete = new List<ProductCategoryProduct>();
        List<Product2> prs = [
            SELECT
                Id,
                RecordTypeId,
                B2B_Product_Type__c,
                Section__c,
                Commerce_JSON__c,
                Product_Code_External_Id__c,
                B2B_Handheld_Override__c,
                (SELECT Id, IsPrimaryCategory, ProductCategory.Name FROM ProductCategoryProducts)
            FROM Product2
            WHERE Id IN :product2Ids AND (NOT Product_Code_External_Id__c LIKE '%-LEGACY')
        ];
        Map<String, ProductCategory> nameProductCategoryMap = getNameProductCategoryMap();

        for (Product2 p : prs) {
            system.debug('xxx - Started over products');
        	system.debug(p);
            System.debug(p.ProductCategoryProducts);
            Product2 pToUpdate;
            // update Product2 if needed
            if (String.isBlank(p.Section__c) && p.RecordTypeId == RecordTypes.product_Part.Id) {
                pToUpdate = new Product2(Id = p.Id);
                pToUpdate.Section__c = 'Part';
            }

            // check if Product Category link is there, if not then create on insert
            if (getProductCategoryLink(p, 'Products').isEmpty() && !String.isBlank(nameProductCategoryMap.get('Products')?.Id)) {
                String productCategoryId = nameProductCategoryMap.get('Products')?.Id;
                if (!String.isBlank(productCategoryId)) {
                    //pcpToInsert.add(new ProductCategoryProduct(ProductCategoryId = productCategoryId, ProductId = p.Id, IsPrimaryCategory = false));
                }
            }
            
            

            if (p.B2B_Product_Type__c == 'Whole Goods') {
                system.debug('xxx - Started Whole Goods');
        		system.debug(p);
                
                List<ProductCategoryProduct> wgPcps = getProductCategoryLink(p, 'Whole Goods');
                String productCategoryId = nameProductCategoryMap.get('Whole Goods')?.Id;
                if (wgPcps.isEmpty() && !String.isBlank(productCategoryId)) {
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
                system.debug('xxx - Started Parts');
                CommerceData cdata = getCategoryFromCommerceJson(p.Commerce_JSON__c);

                if ((cdata != null && cdata.category == 'Handheld') || p.B2B_Handheld_Override__c) {
                    system.debug('xxx - Started Handheld 0');
                    //If Product2.Section__c is blank and Product2.RecordType is 'Part', then change to 'Handheld'
                    if (String.isBlank(p.Section__c) && p.RecordTypeId == RecordTypes.product_Part.Id) {
                        if (pToUpdate == null)
                            pToUpdate = new Product2(Id = p.Id);
                        if (String.isBlank(pToUpdate.Section__c) || pToUpdate.Section__c == 'Part') {
                            pToUpdate.Section__c = 'Handheld';
                        }
                    }
					
                    system.debug('xxx - Started Handheld 1');
                    system.debug('xxx - Started Handheld 1 p');
                    system.debug(p);
                    System.debug(p.ProductCategoryProducts);
                    List<ProductCategoryProduct> hhPcps = getProductCategoryLink(p, 'Handheld');
                    system.debug('xxx - Started Handheld 1.0');
                    system.debug(hhPcps);
                    String productCategoryId = nameProductCategoryMap.get('Handheld')?.Id;
                    system.debug('xxx - Started Handheld 1.1');
                    system.debug(productCategoryId);
                    system.debug('xxx - Started Handheld 1.2');
                    system.debug((hhPcps.isEmpty() && !String.isBlank(productCategoryId)));
                    if (hhPcps.isEmpty() && !String.isBlank(productCategoryId)) {
                        system.debug('xxx - Started Handheld 2');
                        pcpToInsert.add(new ProductCategoryProduct(ProductCategoryId = productCategoryId, ProductId = p.Id, IsPrimaryCategory = true));
                        system.debug('xxx - Started Handheld pcpToInsert');
                        system.debug(pcpToInsert);
                    } else if (hhPcps.size() == 1) {
                        // wgPcps[0].ProductCategoryId = productCategoryId;
                        hhPcps[0].ProductId = p.Id;
                        hhPcps[0].IsPrimaryCategory = true;
                        pcpToUpdate.add(hhPcps[0]);
                    }

                    pcpToDelete.addAll(getProductCategoryLink(p, 'Parts'));
                    pcpToDelete.addAll(getProductCategoryLink(p, 'Whole Goods'));
                    if(cdata?.category != null)pcpToDelete.addAll(getNonRelavantPartsSubProductCategoryLinks(p, cdata.category));
                } else {
                     system.debug('xxx - Started Part After If');
                    // get category from commerce JSON
                    String subProductCategoryId = (cdata == null) ? null : nameProductCategoryMap.get(cdata.category)?.Id;
                    Boolean partIsPrimary = (subProductCategoryId == null);

                    List<ProductCategoryProduct> partPcps = getProductCategoryLink(p, 'Parts');
                    String productCategoryId = nameProductCategoryMap.get('Parts')?.Id;
                    if (partPcps.isEmpty() && !String.isBlank(productCategoryId)) {
                        if (partIsPrimary)
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
                                if (!partIsPrimary)
                                    pcpToInsert.add(new ProductCategoryProduct(ProductCategoryId = subProductCategoryId, ProductId = p.Id, IsPrimaryCategory = !partIsPrimary));
                            }
                        }
                    }

                    pcpToDelete.addAll(getProductCategoryLink(p, 'Whole Goods'));
                    if (cdata != null && !String.isBlank(cdata.category))
                        pcpToDelete.addAll(getNonRelavantPartsSubProductCategoryLinks(p, cdata.category));
                }
            }

            // delete non primary products
            pcpToDelete.addAll(getNonPrimaryProductCategoryLink(p));

            if (pToUpdate != null) {
                productsToUpdate.add(pToUpdate);
            }
        }
        
        system.debug('pcpToInsert');
            system.debug(pcpToInsert);
        
        system.debug('pcpToUpdate');
            system.debug(pcpToUpdate);
        
        system.debug('pcpToDelete');
            system.debug(pcpToDelete);

        // DML Operation
        if (!productsToUpdate.isEmpty()) {
            update productsToUpdate;
        }
        
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
        System.debug('getProductCategoryLink');
        System.debug(p.ProductCategoryProducts);
         System.debug(productCategoryName);
        List<ProductCategoryProduct> pcps = new List<ProductCategoryProduct>();
        for (ProductCategoryProduct pcp : p.ProductCategoryProducts) {
            if (pcp.ProductCategory.Name == productCategoryName) {
                pcps.add(pcp);
            }
        }
        return pcps;
    }

    private static List<ProductCategoryProduct> getNonPrimaryProductCategoryLink(Product2 p) {
        List<ProductCategoryProduct> pcps = new List<ProductCategoryProduct>();
        for (ProductCategoryProduct pcp : p.ProductCategoryProducts) {
            if (!pcp.IsPrimaryCategory) {
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