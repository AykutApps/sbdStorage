public with sharing class B2B_ProductCategoryHelper {
    /*  analyze JSON from Demandware/PIM stored on Product2 and 

    2024-06    Aykut (CRM Agile Team) creates class per OO-1034: Salesforce SBD - Assign products to category
    2024-07-19 mburr(MJ) populated Product2.Section__c to 'Part' or 'Handheld' if not populated - applies to Product2 Record Type 'Part' only
*/
    public static void adjustProductCategories(Set<Id> product2Ids) {
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
                B2B_Product_Category_Override__c,
                (SELECT Id, IsPrimaryCategory, ProductCategory.Name FROM ProductCategoryProducts)
            FROM Product2
            WHERE Id IN :product2Ids AND (NOT Product_Code_External_Id__c LIKE '%-LEGACY')
        ];
        Map<String, ProductCategory> nameProductCategoryMap = getNameProductCategoryMap();

        for (Product2 p : prs) {
            // related product category
            String productCategoryId;

            // Update the product if needed
            Product2 pToUpdate;
            // update Product2 if needed
            if (String.isBlank(p.Section__c) && p.RecordTypeId == RecordTypes.product_Part.Id) {
                //pToUpdate = new Product2(Id = p.Id);
                //pToUpdate.Section__c = 'Part'; //mburr.2024-08 maps to the "Type" filter in B2B Catalogs - biz does not want to filter by Part anymore
            }

            CommerceData cdata = getCategoryFromCommerceJson(p.Commerce_JSON__c);

            // Check Product Types
            boolean isWG, isHH, isPart = false;
            if (p.B2B_Product_Category_Override__c == 'Whole Good')
                isWG = true;
            else if (p.B2B_Product_Category_Override__c == 'Handheld')
                isHH = true;
            else if (p.B2B_Product_Category_Override__c == 'Part')
                isPart = true;
            else if (p.B2B_Product_Type__c == 'Whole Goods')
                isWG = true;
            else if (p.B2B_Product_Type__c == 'Parts' && cdata.category == 'Handheld')
                isHH = true;
            else if (p.B2B_Product_Type__c == 'Parts' || p.RecordTypeId == RecordTypes.product_Attachment.Id)
                isPart = true;

            if (isWG) {
                productCategoryId = nameProductCategoryMap.get('Whole Goods')?.Id;
                if (!String.isBlank(productCategoryId)) {
                    pcpToInsert.add(new ProductCategoryProduct(ProductCategoryId = productCategoryId, ProductId = p.Id, IsPrimaryCategory = true));
                }
            } else if (isHH || isPart) {
                if (cdata != null && String.isNotBlank(cdata.category)) {
                    // Handhelds
                    if (isHH) {
                        //If Product2.Section__c is blank and Product2.RecordType is 'Part', then change to 'Handheld'
                        if (String.isBlank(p.Section__c) && p.RecordTypeId == RecordTypes.product_Part.Id) {
                            if (pToUpdate == null)
                                pToUpdate = new Product2(Id = p.Id);
                            if (String.isBlank(pToUpdate.Section__c) || pToUpdate.Section__c == 'Part') {
                                pToUpdate.Section__c = 'Handheld';
                            }
                        }

                        productCategoryId = nameProductCategoryMap.get('Handheld')?.Id;

                        if (!String.isBlank(productCategoryId)) {
                            pcpToInsert.add(new ProductCategoryProduct(ProductCategoryId = productCategoryId, ProductId = p.Id, IsPrimaryCategory = true));
                        }
                        // Other categories
                    } else {
                        productCategoryId = (nameProductCategoryMap.get(cdata.category) == null)
                            ? nameProductCategoryMap.get('Parts')?.Id
                            : nameProductCategoryMap.get(cdata.category)?.Id;
                        if (!String.isBlank(productCategoryId)) {
                            pcpToInsert.add(new ProductCategoryProduct(ProductCategoryId = productCategoryId, ProductId = p.Id, IsPrimaryCategory = true));
                        }
                    }
                } else {
                    productCategoryId = nameProductCategoryMap.get('Parts')?.Id;
                    if (!String.isBlank(productCategoryId)) {
                        pcpToInsert.add(new ProductCategoryProduct(ProductCategoryId = productCategoryId, ProductId = p.Id, IsPrimaryCategory = true));
                    }
                }
            } else {
                //throw new MTDException('Cannot assign B2B Category for ' + p.ProductCode);
            }

            // delete non primary products
            pcpToDelete.addAll(p.ProductCategoryProducts);

            if (pToUpdate != null) {
                productsToUpdate.add(pToUpdate);
            }
        }

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
            insert pcpToInsert;
        }
    }

    // Helper Methods
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
