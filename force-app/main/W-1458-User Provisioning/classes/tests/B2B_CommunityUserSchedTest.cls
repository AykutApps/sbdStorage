@isTest
public with sharing class B2B_CommunityUserSchedTest {
    @isTest
    public static void TestB2B_CommunityUserBatch() {
        Account acc = TestData_Account.createDealerAccount('TestIRDealer', 'CONTRG1101');
        acc.Dealer_Status__c = 'Active';
        Contact nullContact;

        TestData.shouldInsert = false;
        User irDealerUsaUser1 = TestData_User.createDealerCustomerUser(acc.ID, 'conTriggerRelatedUserTest1@sftest.mtd.com', 'con1TriggerLast', nullContact);
        irDealerUsaUser1.CommunityNickname = irDealerUsaUser1.CommunityNickname + '1';
        irDealerUsaUser1.Email = 'conTriggerRelatedUserTest1@sftest.mtd.com';
        irDealerUsaUser1.IsActive = true;
        insert irDealerUsaUser1;

        Test.startTest();
        Contact con = [SELECT Id, B2B_Parts_Active__c, B2B_Whole_Goods_Active__c FROM Contact];
        con.B2B_Storefront_Product_Type_Ordering__c='Parts;Whole Goods';
        con.Contact_Status__c = 'Active';
        con.RecordTypeId = RecordTypes.contact_IRDealer.Id;
        update con;

        B2B_CommunityUserSched s = new B2B_CommunityUserSched();
        s.execute(null);

        Test.stopTest();

        User irDealerUsaUser1_after = [
            SELECT
                Id,
                (
                    SELECT Id, PermissionSet.Name
                    FROM PermissionSetAssignments
                    WHERE
                        PermissionSet.Name IN :new List<String>{
                            B2B_CommunityUserHelperTest.partsOrderingPermissionSetName,
                            B2B_CommunityUserHelperTest.dealerOrderingPermissionSetName
                        }
                )
            FROM User
            WHERE contactId = :con.Id
        ];
        System.assertEquals(2, irDealerUsaUser1_after.PermissionSetAssignments.size());
    }
}

