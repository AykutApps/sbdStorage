@isTest
private class BecomeDealerCtrlTest {
    /**
     * Tests the constructor of the BecomeDealerCtrl class.
     */
    @isTest
    static void testConstructor() {
        BecomeDealerCtrl controller = new BecomeDealerCtrl();

        // Verify that brands and otherProducts are initialized
        System.assertNotEquals(null, controller.brands, 'Brands should be initialized');
        System.assertNotEquals(null, controller.otherProducts, 'Other Products should be initialized');
    }

    /**
     * Tests the submit method with valid data.
     */
    @isTest
    static void testSubmitValidData() {
        // Set up test data
        String jsonPayload = '{"leadSourceOrigin":"hustler_become_dealer_form","typeOfBusiness":"Independent Retailer","title":"tesrt","first_name":"Test","last_name":"Test","company":"Test 01","phone":"1","email":"admin.test01@test.com","fax":"123","address":"Enrg","city":"Vienna","state":"AZ","zip":"1020","website":"t.com","annualSalesVolume":"$250,000 - $500,000","yearsInBusiness":">5 years","rentYourProperty":"Rent Property","facilitySize":"1231","numberOfEmployees":"3-4","floorPlanProvider":"Other","offeringServicesProductSold":true,"displayArea":true,"serviceArea":true,"partsArea":true,"comment":"test","selectedOtherBrands":"Arctic Cat;Ariens / Gravely;Bad Boy","selectedOtherProducts":"Zero-Turn Lawn Mowers"}';
        Test.startTest();
        //BecomeDealerCtrl.submit(jsonPayload);
        Test.stopTest();

        Lead testLead = [SELECT Id, Firstname, Lastname FROM Lead LIMIT 1];

        Assert.areEqual(testLead.Firstname,'Test');
    }
}