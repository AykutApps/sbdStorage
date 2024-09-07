@isTest
public with sharing class B2B_CommunityUserBatchTest {
    @isTest
    public static void TestB2B_CommunityUserBatch() {
        Account acc = TestData_Account.createDealerAccount('TestIRDealer', 'CONTRG1101');
        Contact nullContact;

        TestData.shouldInsert = false;
        User irDealerUsaUser1 = TestData_User.createDealerCustomerUser(acc.ID, 'conTriggerRelatedUserTest1@sftest.mtd.com', 'con1TriggerLast', nullContact);
        irDealerUsaUser1.CommunityNickname = irDealerUsaUser1.CommunityNickname + '1';
        irDealerUsaUser1.Email = 'conTriggerRelatedUserTest1@sftest.mtd.com';
        insert irDealerUsaUser1;

        Test.startTest();
        Contact con = [SELECT Id, B2B_Parts_Active__c, B2B_Whole_Goods_Active__c FROM Contact];
        con.B2B_Storefront_Product_Type_Ordering__c='Parts;Whole Goods';
        update con;

        B2B_CommunityUserBatch b = new B2B_CommunityUserBatch();
        b.whereClause = ' WHERE Id = \'' + con.Id + '\'';
        ID BatchProcessId = Database.executeBatch(b, 200);

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
