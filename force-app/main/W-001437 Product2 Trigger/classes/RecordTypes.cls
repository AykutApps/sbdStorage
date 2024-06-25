public with sharing class RecordTypes {
    //MTD
    public static RecordType account_IRProspectiveDealer = getRecordType('Account', 'IR_Prospective_Dealer');
    public static RecordType account_IRAuthorizedDealer  = getRecordType('Account', 'IR_Authorized_Dealer');
    public static RecordType account_IRLandscaper        = getRecordType('Account', 'IR_Landscaper');
    public static RecordType account_IRTerminatedDealer  = getRecordType('Account', 'IR_Terminated_Dealer');
    public static RecordType account_Consumer            = getRecordType('Account', 'Consumer');
    public static RecordType account_DewaltConsumer      = getRecordType('Account', 'Pro_Support_Hub'); //Dewalt Pro Hub Support Consumer
public static RecordType account_AUConsumer              = getRecordType('Account', 'AU_Consumer_Account');
    public static RecordType account_CAConsumer          = getRecordType('Account', 'CA_Consumer_Account');
    public static RecordType account_MTDInternal         = getRecordType('Account', 'MTD_Internal');
    public static RecordType account_APACProspectiveAccount = getRecordType('Account', 'APAC_Prospective_Account');
    public static RecordType account_APACAuthorizedAccount  = getRecordType('Account', 'APAC_Authorized_Account');
    public static RecordType account_APACTerminatedAccount  = getRecordType('Account', 'APAC_Terminated_Account');
    public static RecordType account_MSProspectiveAccount   = getRecordType('Account', 'MS_Prospective_Accounts');
    public static RecordType account_MSAuthorizedAccount    = getRecordType('Account', 'Mass_Sales_Authorized_Accounts');
    public static RecordType account_MSTerminatedAccount    = getRecordType('Account', 'MS_Authorized_Accounts'); // mburr.2020-12-30 strange; api for "MS - Terminated Accounts" (SF Account) is MS_Authorized_Accounts
    public static RecordType account_CAProspectiveAccount = getRecordType('Account', 'CA_Prospective_Account');
    public static RecordType account_CAAuthorizedAccount = getRecordType('Account', 'CA_Authorized_Account');
    public static RecordType account_CATerminatedAccount = getRecordType('Account', 'CA_Terminated_Account');
    public static RecordType account_ServiceDealer = getRecordType('Account', 'Service_Dealer');
public static RecordType account_GroundControl = getRecordType('Account', 'Ground_Control'); //ToFuture: deprecate the ground control references; JW indicated in spring 2021 that IOT will happen, but not as "Ground Control"

    public static RecordType contact_Consumer = getRecordType('Contact', 'Consumer');
    public static RecordType contact_DewaltConsumer = getRecordType('Contact', 'Pro_Support_Hub'); //Dewalt Pro Hub Support Consumer
public static RecordType contact_AUConsumer = getRecordType('Contact', 'AU_Consumer_Contact');
    public static RecordType contact_CAConsumer = getRecordType('Contact', 'CA_Consumer_Contact');
    public static RecordType contact_IRDealer = getRecordType('Contact', 'IR_Dealer');
    public static RecordType contact_IRDealerAPAC = getRecordType('Contact', 'APAC_Dealer');
    public static RecordType contact_IRDealerCanada = getRecordType('Contact', 'CA_Dealer');
    public static RecordType contact_ServiceDealer = getRecordType('Contact', 'Service_Dealer');
    //public static RecordType contact_GroundControl = getRecordType('Contact', 'Ground_Control');
    public static RecordType contact_MTDInternal = getRecordType('Contact', 'MTD_Internal_Contact');

    public static RecordType task_MassRetailer = getRecordType('Task', 'MS_General_Tasks');

    public static RecordType product_WholeGood = getRecordType('Product2', 'Whole_Good');
    public static RecordType product_Attachment = getRecordType('Product2', 'Attachment');
    public static RecordType product_IndependentRetail = getRecordType('Product2', 'Independent_Retail');
    public static RecordType product_FinishedGoodsFromEDW = getRecordType('Product2', 'Finished_Goods_From_EDW');
    public static RecordType product_Generic = getRecordType('Product2', 'Generic');
    public static RecordType product_Other = getRecordType('Product2', 'Other');
    public static RecordType product_Part = getRecordType('Product2', 'Part');
    
    public static RecordType product_region_Canada = getRecordType('Product_Region__c', 'Canada');

    public static RecordType dfOrder_Canada = getRecordType('Consumer_Order__c', 'CA_Consumer');
    public static RecordType dfOrder_US = getRecordType('Consumer_Order__c', 'US_Consumer');

    public static RecordType order_PreSeason = getRecordType('Order', 'Pre_Season');
    public static RecordType order_PreSeasonFallWinter = getRecordType('Order', 'Pre_Season_Fall_Winter');
    public static RecordType order_EDealerDropShipWG = getRecordType('Order', 'E_Dealer_Drop_Ship_Whole_Goods');
    public static RecordType order_InSeason = getRecordType('Order', 'In_Season');
    public static RecordType order_Promotion = getRecordType('Order', 'Promotion');
    public static RecordType order_Parts = getRecordType('Order', 'Parts');
    public static RecordType order_EDealerDropShipParts = getRecordType('Order', 'E_Dealer_Drop_Ship_Parts');

    public static RecordType orderingEvent_PreSeason = getRecordType('Ordering_Event__c', 'Pre_Season');
    public static RecordType orderingEvent_PreSeasonFallWinter = getRecordType('Ordering_Event__c', 'Pre_Season_Fall_Winter');
    public static RecordType orderingEvent_InSeason = getRecordType('Ordering_Event__c', 'In_Season');
    public static RecordType orderingEvent_Promotion = getRecordType('Ordering_Event__c', 'Promotion');

    public static RecordType orderingEventRule_QuantityRule = getRecordType('Ordering_Event_Quantity_Rule__c', 'Quantity_Rule');
    public static RecordType orderingEventRule_PricingRule = getRecordType('Ordering_Event_Quantity_Rule__c', 'Pricing_Rule');

    public static RecordType erpOrder_PreSeason = getRecordType('ERP_Order__c', 'Pre_Season');
    public static RecordType erpOrder_InSeason = getRecordType('ERP_Order__c', 'In_Season');
    public static RecordType erpOrder_EDealerDropShipWG = getRecordType('ERP_Order__c', 'E_Dealer_Drop_Ship_Whole_Goods');
    public static RecordType erpOrder_Promotion = getRecordType('ERP_Order__c', 'Promotion');
    public static RecordType erpOrder_Parts = getRecordType('ERP_Order__c', 'Parts');
    public static RecordType erpOrder_EDealerDropShipParts = getRecordType('ERP_Order__c', 'E_Dealer_Drop_Ship_Parts');
    public static RecordType erpOrder_Unknown = getRecordType('ERP_Order__c', 'Unknown');

    public static RecordType sgm_Level = getRecordType('Simplified_Gross_Margin__c', 'Level');
    public static RecordType sgm_Tier = getRecordType('Simplified_Gross_Margin__c', 'Tier');
    
    //Regional Target Fund
    public static RecordType rtf_CUB = getRecordType('Regional_Target_Funds__c', 'Regional_Target_Fund_CUB');
    public static RecordType rtf_HUSTLER = getRecordType('Regional_Target_Funds__c', 'Regional_Target_Fund_HUSTLER');
    

    public static RecordType bizHours_DFSLA = getRecordType('Custom_Business_Hours__c', 'DF_SLA_Hours');
    public static RecordType bizHours_Retail = getRecordType('Custom_Business_Hours__c', 'Retail_Store_Hours');
    public static RecordType bizHours_ServiceRepair = getRecordType('Custom_Business_Hours__c', 'Service_Repair_Hours');

    public static RecordType case_IRContactUs = getRecordType('Case', 'IR_Contact_Us');
    public static RecordType case_APACContactUs = getRecordType('Case', 'APAC_Contact_Us');
    public static RecordType case_IRContactUsCanada = getRecordType('Case', 'IR_Contact_Us_Canada');
    public static RecordType case_APACDealerSupport = getRecordType('Case', 'APAC_Dealer_Support');
    public static RecordType case_CA_CSR_CanScan_Case = getRecordType('Case', 'CA_CSR_CanScan_Case');
    public static RecordType case_AU_Dealer_Support = getRecordType('Case', 'AU_Dealer_Support');
    public static RecordType case_CSCCase = getRecordType('Case', 'CSC_Case');
    public static RecordType case_CSCConcealedDamage = getRecordType('Case', 'Concealed_Damage_Freight_Damage');
    public static RecordType case_CSCCommunityContactUs = getRecordType('Case', 'CSC_Community_Contact_Us_Case');
    public static RecordType case_CSCCustomerService = getRecordType('Case', 'CSC_Customer_Service_Case');
    public static RecordType case_CSCDealerSales = getRecordType('Case', 'CSC_Dealer_Sales_Case');
    public static RecordType case_CSCDealerTechnical = getRecordType('Case', 'CSC_Dealer_Technical_Case');
    public static RecordType case_CSCRecall = getRecordType('Case', 'CSC_Recall_Case');
    public static RecordType case_CSCRefund = getRecordType('Case', 'CSC_Refund_Case');
    public static RecordType case_CSCRetail = getRecordType('Case', 'CSC_Retail_Case');
    public static RecordType case_CSCSales = getRecordType('Case', 'CSC_Sales_Case');
    public static RecordType case_CSCSocial = getRecordType('Case', 'CSC_Social_Case');
    public static RecordType case_CSCTechnical = getRecordType('Case', 'CSC_Technical_Case');
    public static RecordType case_CSCWarrantyAdmin = getRecordType('Case', 'CSC_Warranty_Admin');
    public static RecordType case_DFCanada = getRecordType('Case', 'Dealer_Fulfillment_Canada');
    public static RecordType case_DFUS = getRecordType('Case', 'Dealer_Fulfilment'); //    api name mispelled in PROD as "Dealer_Fulfilment"; cannot fix mispelling
    
    public static RecordType salesAllowance_ServiceAdjustment = getRecordType('Sales_Allowance__c', 'Service_Adjustment');
    
    public static RecordType lead_Consumer = getRecordType('Lead', 'Consumer');
    public static RecordType lead_IR = getRecordType('Lead', 'MTD_IR_Leads');
    public static RecordType lead_Troy_Bilt = getRecordType('Lead', 'Troy_Built');

    //CMS
    public static RecordType cmsContentVersion_News = getRecordType('Cms_Content_Version__c', 'News');
    public static RecordType cmsContentVersion_General = getRecordType('Cms_Content_Version__c', 'General');
    public static RecordType cmsContentVersion_ProductMarkets = getRecordType('Cms_Content_Version__c', 'Product_Markets');

    public static RecordType cmsDataView_RelatedList = getRecordType('Cms_Data_View__c', 'Related_List');
    public static RecordType cmsDataView_ContentTemplate = getRecordType('Cms_Data_View__c', 'Content_Template');

    //These are stubbed in to support CMS-CRM
    public static RecordType account_Dealer = getRecordType('Account', 'Dealer');
    public static RecordType contact_Customer = getRecordType('Contact', 'Customer'); //ToFuture: deprecate? use IR_Dealer for IR-USA dealer contacts & consumer for USA end-consumers

    public static RecordType assetOwnership_IRDealer = getRecordType('Asset_Ownership__c', 'IR_Dealer');
    public static RecordType assetOwnership_Consumer = getRecordType('Asset_Ownership__c', 'Consumer');
    public static RecordType assetOwnership_ServiceDealer = getRecordType('Asset_Ownership__c', 'Service_Dealer');
    public static RecordType assetOwnership_CanadaDealer = getRecordType('Asset_Ownership__c', 'CA_Dealer');

    public static RecordType asset_Gold = getRecordType('Asset', 'Gold_Asset');
    public static RecordType asset_Silver = getRecordType('Asset', 'Silver_Asset');
    public static RecordType asset_Bronze = getRecordType('Asset', 'Bronze_Asset');

    //Interactions
    public static RecordType interaction_registration = getRecordType('Interaction__c', 'Registration');
    public static RecordType interaction_lead = getRecordType('Interaction__c', 'Lead');
    public static RecordType interaction_MC_Subscription = getRecordType('Interaction__c', 'MC_Subscription_Center');
    public static RecordType interaction_Consumer_Ordering = getRecordType('Interaction__c', 'Consumer_Ordering');

    //Merge Archives
    public static RecordType mergeArchive_lead = getRecordType('Merge_Archive_Account_People__c', 'Lead');
    public static RecordType mergeArchive_contact = getRecordType('Merge_Archive_Account_People__c', 'Contact');
    public static RecordType mergeArchive_account = getRecordType('Merge_Archive_Account_People__c', 'Account');

    //Bid Fleet
    public static RecordType bidFleet_Bid = getRecordType('Bid_Fleet__c', 'Bid');
    public static RecordType bidFleet_Fleet = getRecordType('Bid_Fleet__c', 'Fleet');
    public static RecordType bidFleet_NALP = getRecordType('Bid_Fleet__c', 'NALP');
    public static RecordType bidFleet_NationalAcc = getRecordType('Bid_Fleet__c', 'National_Account');
    public static RecordType bidFleet_Sourcewell = getRecordType('Bid_Fleet__c', 'Sourcewell');

    //REQ Information Requests
    public static RecordType infoRequest_irUsaLegalOwnerData = getRecordType('REQ_Account_Info_Request__c', 'IR_USA_DLR_Legal_Owner_Data');

    //LGL Legal Sets of Owners
    public static RecordType legalOwnersSet_irUsa = getRecordType('LGL_Legal_Owners_Set__c', 'IR_USA');

    //ESG Confidential Documents (moving PDFs from DocuSign_Status__c to ESG_Confidential_Document__c)
    public static RecordType confidentialDoc_irUsa = getRecordType('ESG_Confidential_Document__c', 'IR_USA_Confidential_Document');
    
    //Warranty Matrix
    public static RecordType warrantyMatrix_Base = getRecordType('Warranty_Matrix__c', 'Base_Warranty');
    public static RecordType warrantyMatrix_Promotion = getRecordType('Warranty_Matrix__c', 'Promotional_Warranty');
    public static RecordType warrantyMatrix_Extended = getRecordType('Warranty_Matrix__c', 'Extended_Warranty');

    //Warranty Entitlement/Contract
    public static RecordType warrantyEntitlement_Base = getRecordType('Warranty_Entitlement__c', 'Base');
    public static RecordType warrantyEntitlement_Promotion = getRecordType('Warranty_Entitlement__c', 'Promotional');
    public static RecordType warrantyEntitlement_Extended = getRecordType('Warranty_Entitlement__c', 'Extended');

    //Dealer Termination
    public static RecordType auction = getRecordType('Liquidation_Type__c', 'Auction');
    public static RecordType localMarket = getRecordType('Liquidation_Type__c', 'Local_Market');
    
    private static Map<String, RecordType> recordTypeMap = null;

    private static RecordType getRecordType(String sObjectType, String developerName) {

        if (recordTypeMap == null) {
            recordTypeMap = new Map<String, RecordType>();

            for (RecordType rt : [select Id, DeveloperName, SObjectType,name from RecordType]) {
                String tempKey = rt.SObjectType + '|' + rt.DeveloperName;
                recordTypeMap.put(tempKey, rt);
            }
        }

        String key = sObjectType + '|' + developerName;
        if (recordTypeMap.containsKey(key)) {
            return recordTypeMap.get(key);
        }
        System.debug('getRecordType:Does not exist: ' + key);
        return null;
    }

    private static Map<Id, Map<String, Record_Type_Id_Mapping__c>> recordMap;
    public static Map<Id, Map<String, Record_Type_Id_Mapping__c>> getRecordMaps() {
        if(recordMap == null){
            recordMap = new Map<Id, Map<String, Record_Type_Id_Mapping__c>>();
            for (Record_Type_Id_Mapping__c rtm : Record_Type_Id_Mapping__c.getAll().values()){
                if(recordMap.containsKey(rtm.Source_Record_Type_Id__c)){
                    recordMap.get(rtm.Source_Record_Type_Id__c).put(rtm.Destination_Object_Type__c.toUpperCase(), rtm);
                } else {
                    recordMap.put(rtm.Source_Record_Type_Id__c, new Map<String, Record_Type_Id_Mapping__c>{ rtm.Destination_Object_Type__c.toUpperCase() => rtm});
                }
            }
        }

        return recordMap;
    }

    public static String getRecordTypeMap(Id sourceRecordTypeId, String destinationObjectType){
        /*    accesses the record-type mappings stored in custom-setting Record_Type_Id_Mapping__c which maps
            an interaction-rec-type to 1 or more target record types (e.g. a registration in Interaction__c has data for SF Account & SF Contact)
            
            2017 examples:    
            - "Lead Interaction To Contact":          maps the lead-interaction-rec-type to the usa-end-consumer's contact rec-type
            - "Lead Interaction To Lead":             maps the lead-interaction-rec-type to the usa-end-consumer's lead rec-type
            - "Registration Interaction To Account":  maps the reg-interaction-rec-type  to the usa-end-consumer's household account rec-type
            - "Registration Interaction To Account":  maps the reg-interaction-rec-type  to the usa-end-consumer's contact rec-type
        */
        destinationObjectType = destinationObjectType.toUpperCase();
        Map<Id, Map<String, Record_Type_Id_Mapping__c>> rmaps = getRecordMaps();
        if(rmaps.containsKey(sourceRecordTypeId) && rmaps.get(sourceRecordTypeId).containsKey(destinationObjectType)){
            return rmaps.get(sourceRecordTypeId).get(destinationObjectType).Destination_Record_Type_Id__c;
        } else {
            return null;
        }
    }
}