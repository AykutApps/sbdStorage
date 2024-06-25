@isTest
private class USR_CompareSFUsersHelperTest {

    static testMethod void verifyUserGridRows() {
		//call deriveUserGridRows(...) and verify that the fields on the base, other & another users appear in the correct columns
        //COLUMN 1 - Base User
        User base = [	SELECT Id, FirstName, LastName, Title, FederationIdentifier, UserName, Email
                    	, IsActive, ProfileId, Profile.Name, UserRoleId, UserRole.Name
                    	, ContactId, Contact.Name, Contact.AccountId, Contact.Account.Entity_Id__c, Contact.Account.PEID__c
                     	, Contact.Account.ShippingCity, Contact.Account.ShippingState
                    	FROM User
                    	WHERE Id = :UserInfo.getUserId()
                    	];
        //COLUMN 2 - IR Sales Support User
        Profile irProfile = [SELECT ID FROM Profile WHERE Name = 'Dealer Fulfillment Coordinator'];
        User other = [	SELECT Id, FirstName, LastName, Title, FederationIdentifier, UserName, Email
                    	, IsActive, ProfileId, Profile.Name, UserRoleId, UserRole.Name
                    	, ContactId, Contact.Name, Contact.AccountId, Contact.Account.Entity_Id__c, Contact.Account.PEID__c
                     	, Contact.Account.ShippingCity, Contact.Account.ShippingState
                    	FROM User
                    	WHERE ProfileId = :irProfile.Id
                      	LIMIT 1
                    	];
        //COLUMN 3 - IR-USA Dealer Community User
        Profile dlrProfile = [SELECT ID FROM Profile WHERE Name = 'IR-USA-DLR-Base profile'];
        User another = [	SELECT Id, FirstName, LastName, Title, FederationIdentifier, UserName, Email
                    		, IsActive, ProfileId, Profile.Name, UserRoleId, UserRole.Name
                    		, ContactId, Contact.Name, Contact.AccountId, Contact.Account.Entity_Id__c, Contact.Account.PEID__c
                     		, Contact.Account.ShippingCity, Contact.Account.ShippingState
                    		FROM User
                    		WHERE ProfileId = :dlrProfile.Id
                        	LIMIT 1
                    		];
    
    
        Test.startTest();
        List<MTD_CompareModels.GridRow> userRows = USR_CompareSFUsersHelper.deriveUserGridRows(base, other, another);
        Test.stopTest();
    
        //find the rows for some of the fields
        MTD_CompareModels.GridRow userIdRow;
        MTD_CompareModels.GridRow usernameRow;
        MTD_CompareModels.GridRow userProfileNameRow;
        for(MTD_CompareModels.GridRow r : userRows){
            if(r.metaApi == 'Id') userIdRow = r;
            if(r.metaApi == 'Username') usernameRow = r;
            if(r.metaApi == 'Profile.Name') userProfileNameRow = r;
        }
        
        //verify the values in columns 1, 2 and 3 correspond to the correct user - 1 for base user, 2 for other user, 3 for another user
        system.assertEquals(base.Id          ,userIdRow.baseVal);
        system.assertEquals(base.Username    ,usernameRow.baseVal);
        system.assertEquals(base.Profile.Name,userProfileNameRow.baseVal);
    }

	static testMethod void verifyPermissionSetGridRows() {
		//call deriveUserGridRows(...) and verify that the fields on the base, other & another users appear in the correct columns
        //COLUMN 1 - Base User
        User base = [	SELECT Id, FirstName, LastName, Title, FederationIdentifier, UserName, Email
                    	, IsActive, ProfileId, Profile.Name, UserRoleId, UserRole.Name
                    	, ContactId, Contact.Name, Contact.AccountId, Contact.Account.Entity_Id__c, Contact.Account.PEID__c
                     	, Contact.Account.ShippingCity, Contact.Account.ShippingState
                    	FROM User
                    	WHERE Id = :UserInfo.getUserId() AND IsActive = true
                    	];
		List<PermissionSetAssignment> basePSAs = [SELECT ID, AssigneeId, PermissionSetId, PermissionSet.Label FROM PermissionSetAssignment WHERE AssigneeId = :base.Id];
		Set<String> basePermSetLabels = new Set<String>();
        for(PermissionSetAssignment psa : basePSAs){
            basePermSetLabels.add(psa.PermissionSet.Label);
        }

        //COLUMN 2 - IR Sales Support User
        Profile irProfile = [SELECT ID FROM Profile WHERE Name = 'Dealer Fulfillment Coordinator'];
        User other = [	SELECT Id, FirstName, LastName, Title, FederationIdentifier, UserName, Email
                    	, IsActive, ProfileId, Profile.Name, UserRoleId, UserRole.Name
                    	, ContactId, Contact.Name, Contact.AccountId, Contact.Account.Entity_Id__c, Contact.Account.PEID__c
                     	, Contact.Account.ShippingCity, Contact.Account.ShippingState
                    	FROM User
                    	WHERE ProfileId = :irProfile.Id AND IsActive = true
                      	LIMIT 1
                    	];
		List<PermissionSetAssignment> otherPSAs = [SELECT ID, AssigneeId, PermissionSetId, PermissionSet.Label FROM PermissionSetAssignment WHERE AssigneeId = :other.Id];
		Set<String> otherPermSetLabels = new Set<String>();
        for(PermissionSetAssignment psa : otherPSAs){
            otherPermSetLabels.add(psa.PermissionSet.Label);
        }

        //COLUMN 3 - IR-USA Dealer Community User
        Profile dlrProfile = [SELECT ID FROM Profile WHERE Name = 'IR-USA-DLR-Base profile'];
        User another = [	SELECT Id, FirstName, LastName, Title, FederationIdentifier, UserName, Email
                    		, IsActive, ProfileId, Profile.Name, UserRoleId, UserRole.Name
                    		, ContactId, Contact.Name, Contact.AccountId, Contact.Account.Entity_Id__c, Contact.Account.PEID__c
                     		, Contact.Account.ShippingCity, Contact.Account.ShippingState
                    		FROM User
                    		WHERE ProfileId = :dlrProfile.Id AND IsActive = true
                        	LIMIT 1
                    		];
		List<PermissionSetAssignment> anotherPSAs = [SELECT ID, AssigneeId, PermissionSetId, PermissionSet.Label FROM PermissionSetAssignment WHERE AssigneeId = :another.Id];
		Set<String> anotherPermSetLabels = new Set<String>();
        for(PermissionSetAssignment psa : anotherPSAs){
            anotherPermSetLabels.add(psa.PermissionSet.Label);
        }


        //find unique Permission Sets
        List<PermissionSet> permSets = new List<PermissionSet>();
        Set<Id> permSetIds = new Set<Id>();
        for(PermissionSetAssignment psa : basePSAs)    permSetids.add(psa.PermissionSetId);
        for(PermissionSetAssignment psa : otherPSAs)   permSetids.add(psa.PermissionSetId);
        for(PermissionSetAssignment psa : anotherPSAs) permSetids.add(psa.PermissionSetId);
        permSets = [ SELECT Id, Label, Name FROM PermissionSet WHERE Id in :permSetIds ORDER BY Name ];
        
        Test.startTest();
        List<MTD_CompareModels.GridRow> permSetRows = USR_CompareSFUsersHelper.derivePermissionSetGridRows(base, other, another);
        Test.stopTest();

        system.debug('xxx-permSets[0]-'+permSets[0]);
    	system.debug('xxx-basePermSetLabels-'+basePermSetLabels);
    	system.debug('xxx-otherPermSetLabels-'+otherPermSetLabels);
    	system.debug('xxx-anotherPermSetLabels-'+anotherPermSetLabels);

        //find grid-rows for a few permission sets
		PermissionSet ps1 = permSets[0];
		PermissionSet ps2 = permSets[1];
        MTD_CompareModels.GridRow permSetRow1;
        MTD_CompareModels.GridRow permSetRow2;
        for(MTD_CompareModels.GridRow r : permSetRows){
            if(ps1.Name == r.metaApi){ //match on Api Name for the Permission Set
				permSetRow1 = r;
            }
            if(ps2.Name == r.metaApi){ //match on Api Name for the Permission Set
				permSetRow2 = r;
            }
        }
        system.debug('xxx-permSetRow1-'+permSetRow1);
        system.debug('xxx-permSetRow2-'+permSetRow2);

        //verify base-user's permission sets in column 1
        if(basePermSetLabels.contains(permSetRow1.metaLabel)){ //does the user's set of Permission Set Labels have the 1st Permission Set? 
            System.assertEquals(ps1.Label, permSetRow1.getBaseValue());
        } else {
            System.assertEquals('', permSetRow1.getBaseValue()); //cell should be empty
        }
        if(basePermSetLabels.contains(permSetRow2.metaLabel)){ //does the user's set of Permission Set Labels have the 2nd Permission Set? 
            System.assertEquals(ps2.Label, permSetRow2.getBaseValue());
        } else {
            System.assertEquals('', permSetRow2.getBaseValue()); //cell should be empty
        }

        //verify other-user's permission sets in column 2
        if(otherPermSetLabels.contains(permSetRow1.metaLabel)){ //does the user's set of Permission Set Labels have the 1st Permission Set?
            System.assertEquals(ps1.Label, permSetRow1.getOtherValue());
        } else {
            System.assertEquals('', permSetRow1.getOtherValue()); //cell should be empty
        }
        if(otherPermSetLabels.contains(permSetRow2.metaLabel)){ //does the user's set of Permission Set Labels have the 2nd Permission Set? 
            System.assertEquals(ps2.Label, permSetRow2.getOtherValue());
        } else {
            System.assertEquals('', permSetRow2.getOtherValue()); //cell should be empty
        }

        //verify another-user's permission sets in column 3
        if(anotherPermSetLabels.contains(permSetRow1.metaLabel)){ //does the user's set of Permission Set Labels have the 1st Permission Set?
            System.assertEquals(ps1.Label, permSetRow1.getAnotherValue());
        } else {
            System.assertEquals('', permSetRow1.getAnotherValue()); //cell should be empty
        }
        if(anotherPermSetLabels.contains(permSetRow2.metaLabel)){ //does the user's set of Permission Set Labels have the 2nd Permission Set? 
            System.assertEquals(ps2.Label, permSetRow2.getAnotherValue());
        } else {
            System.assertEquals('', permSetRow2.getAnotherValue()); //cell should be empty
        }
    }
    
}