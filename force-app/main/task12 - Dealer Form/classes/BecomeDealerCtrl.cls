/**
 * @Author: aykut.parlak@sbdinc.com
 * Date Created: 2023-12-12
 *
 * BecomeDealerCtrl is a global class responsible for handling the logic associated with becoming a dealer.
 * It primarily deals with processing dealer lead information and maintaining a list of brands and other products.
 * This apex is exposed to BecomeDealer.page under DealerService public site.
 */

global class BecomeDealerCtrl {
    public List<String> brands { get; set; }
    public List<String> otherProducts { get; set; }

    public BecomeDealerCtrl() {
        initializeBrands();
        initializeOtherProducts();
    }

    private void initializeBrands() {
        brands = new List<String>{
            'Arctic Cat',
            'Ariens / Gravely',
            'Bad Boy',
            'Bearcat',
            'BobCat',
            'Branson',
            'Briggs and Stratton',
            'Case',
            'Country Clipper',
            'CountyLine',
            'Cub Cadet',
            'Cub Commercial',
            'Dixie Chopper',
            'Dolmar',
            'Echo',
            'Exmark',
            'Ferris',
            'Grasshopper',
            'Honda',
            'Husqvarna',
            'Hustler',
            'John Deere',
            'Kawasaki',
            'Kioti',
            'Kubota',
            'Mahindra',
            'Mantis',
            'MTD',
            'Murray',
            'New Holland',
            'Polaris',
            'Poulan',
            'SCAG',
            'Shindiawa',
            'Snapper',
            'Snapper PRO',
            'STIHL',
            'Swisher',
            'Toro',
            'Troybilt',
            'White Outdoor',
            'Woods Mow-n-machine',
            'World Lawn',
            'Wright',
            'Yamaha',
            'Yanmar'
        };
    }

    private void initializeOtherProducts() {
        otherProducts = new List<String>{ 'Zero-Turn Lawn Mowers', 'Push Mowers', 'ATV/UTV', 'Snow Removal Equipment', 'General Hardware and Supplies', 'Other' };
    }

    @RemoteAction
    global static void submit(String becomeLeadPayload, String getGoogleReCAPTCHAResponse) {
        if (getGoogleReCAPTCHAResponse(getGoogleReCAPTCHAResponse)) {
            handleBecomeDealerPayload(becomeLeadPayload);
        } else {
        }
    }

    public static void handleBecomeDealerPayload(String becomeLeadPayload) {
        Lead dealerLead = mapToLead(becomeLeadPayload);
        insert dealerLead; // Inserts the new Lead record into Salesforce
    }

    private static Lead mapToLead(String becomeLeadPayload) {
        Map<String, Object> becomeDealerObject = (Map<String, Object>) JSON.deserializeUntyped(becomeLeadPayload);
        Lead dealerLead = new Lead();
        dealerLead.Reason_For_Contacting__c = 'Become a Dealer';
        dealerLead.LeadSource = 'Web';
        dealerLead.Lead_Source_Details__c = (String) becomeDealerObject.get('leadSourceOrigin');
        dealerLead.Type_of_Business__c = (String) becomeDealerObject.get('typeOfBusiness');
        dealerLead.Title = (String) becomeDealerObject.get('title');
        dealerLead.FirstName = (String) becomeDealerObject.get('first_name');
        dealerLead.LastName = (String) becomeDealerObject.get('last_name');
        dealerLead.Company = (String) becomeDealerObject.get('company');
        dealerLead.Phone = (String) becomeDealerObject.get('phone');
        dealerLead.Email = (String) becomeDealerObject.get('email');
        dealerLead.Fax = (String) becomeDealerObject.get('fax');
        dealerLead.Street = (String) becomeDealerObject.get('address');
        dealerLead.City = (String) becomeDealerObject.get('city');
        dealerLead.State = (String) becomeDealerObject.get('state');
        dealerLead.PostalCode = (String) becomeDealerObject.get('zip');
        dealerLead.Website = (String) becomeDealerObject.get('website');
        dealerLead.Current_Annual_Sales_Volume__c = (String) becomeDealerObject.get('annualSalesVolume');
        dealerLead.Number_of_Years_in_Business__c = (String) becomeDealerObject.get('yearsInBusiness');
        dealerLead.Do_you_own_or_rent_your_pe__c = (String) becomeDealerObject.get('rentYourProperty');
        dealerLead.Number_of_Square_Feet_of_Facility__c = ((String) becomeDealerObject.get('facilitySize') == '') ? null : Integer.valueOf(becomeDealerObject.get('facilitySize'));
        dealerLead.Number_of_Full_Time_Employees__c = (String) becomeDealerObject.get('numberOfEmployees');
        dealerLead.Current_Floor_Plan_Provider__c = (String) becomeDealerObject.get('floorPlanProvider');
        dealerLead.Do_You_Offer_Services_for_Products_Sold__c = (Boolean) becomeDealerObject.get('offeringServicesProductSold');
        dealerLead.Do_you_have_a_display_area__c = (Boolean) becomeDealerObject.get('displayArea');
        dealerLead.Do_you_have_a_service_area__c = (Boolean) becomeDealerObject.get('serviceArea');
        dealerLead.Do_you_have_a_parts_area__c = (Boolean) becomeDealerObject.get('partsArea');
        dealerLead.Comments_Additional_Information__c = (String) becomeDealerObject.get('comment');
        dealerLead.Choose_Other_Brands_You_Carry__c = (String) becomeDealerObject.get('selectedOtherBrands');
        dealerLead.Types_of_products_you_currently_sell__c = (String) becomeDealerObject.get('selectedOtherProducts');

        return dealerLead;
    }

    private static String secretKey = '6Ldz1jEpAAAAAOljyuf9x-qrJ05Sxm4n6Nc4HkU4';
    private static String baseUrl = 'https://www.google.com/recaptcha/api/siteverify';
    public String publicKey { get; set; }

    //Get Google reCAPTCHA Service Response
    private static Boolean getGoogleReCAPTCHAResponse_v0(String recaptchaResponse) {
        System.debug('recaptchaResponse');
        System.debug(recaptchaResponse);
        String recaptchaSecretKey = '';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://www.google.com/recaptcha/api/siteverify');
        request.setMethod('POST');
        request.setBody('secret=' + '6Ldz1jEpAAAAAOljyuf9x-qrJ05Sxm4n6Nc4HkU4' + '&response=' + recaptchaResponse);
        HttpResponse response = http.send(request);
        System.debug(response);
        System.debug(response.getBody());
        Boolean successStatus = response.getStatusCode() == 200;
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        return (successStatus && result.containsKey('success') && result.get('success') == true);
    }

    private static final String RECAPTCHA_ENDPOINT = 'https://www.google.com/recaptcha/api/siteverify';
    private static final String RECAPTCHA_SECRET_KEY = '6Ldz1jEpAAAAAOljyuf9x-qrJ05Sxm4n6Nc4HkU4';

    private static Boolean getGoogleReCAPTCHAResponse(String recaptchaResponse) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(RECAPTCHA_ENDPOINT);
        request.setMethod('POST');
        request.setBody('secret=' + RECAPTCHA_SECRET_KEY + '&response=' + recaptchaResponse);

        try {
            HttpResponse response = http.send(request);
            System.debug(response);
            System.debug(response.getBody());
            if (response != null && response.getBody() != null) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Boolean isSuccessful = response.getStatusCode() == 200 && result.containsKey('success') && (Boolean) result.get('success');
                return isSuccessful;
            }
        } catch (Exception e) {
            // Log the exception
            System.debug('Error in getGoogleReCAPTCHAResponse: ' + e.getMessage());
        }
        return false;
    }
}