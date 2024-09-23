@isTest
public with sharing class PartSmartInjectorCtlTest2 {
    @IsTest(SeeAllData=true)
    public static void initStoreData() {
        //#region Create users
        User userSysAdmin;
        Profile sysAdminProfile;

        try {
            List<Wishlist> accList = [SELECT Id FROM Wishlist WHERE AccountId != NULL LIMIT 1];
            webStoreId = JSON.serialize(accList);
            wishListIdValue = webStoreId.substring(80, 98);
        } catch (Exception e) {
            wishListIdValue = null;
        }

        try {
            sysAdminProfile = [SELECT Id FROM Profile WHERE Name = :PREFERRED_SYSTEM_ADMIN_PROFILE];
            userSysAdmin = [
                SELECT Id, Name
                FROM User
                WHERE ProfileId = :sysAdminProfile.Id AND UserRoleId != NULL AND IsActive = TRUE
                LIMIT 1
            ];
        } catch (Exception e) {
            sysAdminProfile = [SELECT Id FROM Profile WHERE Name = :ALTERNATE_SYSTEM_ADMIN_PROFILE];
            userSysAdmin = [
                SELECT Id, Name
                FROM User
                WHERE ProfileId = :sysAdminProfile.Id AND UserRoleId != NULL AND IsActive = TRUE
                LIMIT 1
            ];
        }
        //#endregion

        //#region Create accounts
        User portalAccountOwner;
        List<Account> accountsObject = new List<Account>();

        System.runAs(userSysAdmin) {
            //Create portal account owner
            UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
            portalAccountOwner = new User(
                UserRoleId = portalRole.Id,
                ProfileId = sysAdminProfile.Id,
                Username = System.now().millisecond() + 'PortalAccountOwner@test.com',
                Alias = 'PAO',
                Email = 'PortalAccountOwner@test.com',
                EmailEncodingKey = 'UTF-8',
                Firstname = 'Portal',
                Lastname = 'Owner',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Chicago'
            );
            insert portalAccountOwner;
        }
        // Create Accounts as new Portal Account Owner
        // System.runAs(portalAccountOwner) {
        Id recordTypeId_MasterAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Account').getRecordTypeId();
        accountsObject.add(
            new Account(
                Name = 'Account 1',
                OwnerId = portalAccountOwner.Id,
                BillingStreet = '789 Main',
                BillingState = 'Texas',
                BillingCity = 'BuringTown',
                BillingPostalCode = '85658',
                BillingCountry = 'United States',
                RecordTypeId = recordTypeId_MasterAccount
            )
        );
        accountsObject.add(
            new Account(
                Name = 'Account 2',
                OwnerId = portalAccountOwner.Id,
                BillingStreet = '123 Main',
                BillingState = 'Ohio',
                BillingCity = 'AnyTown',
                BillingPostalCode = '44199',
                BillingCountry = 'United States',
                RecordTypeId = recordTypeId_MasterAccount
            )
        );
        accountsObject.add(
            new Account(
                Name = 'Child Account of Acct 1',
                OwnerId = portalAccountOwner.Id,
                BillingStreet = '456 Main',
                BillingState = 'Maine',
                BillingCity = 'NowhereTown',
                BillingPostalCode = '85657',
                BillingCountry = 'United States',
                RecordTypeId = recordTypeId_MasterAccount
            )
        );
        insert accountsObject;
        List<AccountTeamMember> atm = new List<AccountTeamMember>();
        for (Account acct : accountsObject) {
            mapAccounts.put(acct.Name, acct);
            atm.add(
                new AccountTeamMember(
                    AccountId = acct.Id,
                    UserId = portalAccountOwner.Id,
                    TeamMemberRole = 'Account Manager',
                    AccountAccessLevel = 'Edit',
                    ContactAccessLevel = 'Edit',
                    OpportunityAccessLevel = 'Edit',
                    CaseAccessLevel = 'Edit'
                )
            );
        }
        insert atm;
        mapAccounts.get('Child Account of Acct 1').ParentId = mapAccounts.get('Account 1').Id;
        update accountsObject;
        // }
        //#endregion

        //#region Create contacts
        //Run dataset as portalAccountOwner, which is a System Admin
        System.runAs(portalAccountOwner) {
            updateCustomSettings();

            Map<String, Id> mapPermSet = new Map<String, Id>();
            for (PermissionSet ps : [
                SELECT Id, Name, Label
                FROM PermissionSet
                WHERE Name LIKE :PERMISSIONSET_PREFIX
            ]) {
                System.debug('ps: ' + ps);
                mapPermSet.put(ps.Label, ps.Id);
            }
            List<Profile> communityUserProfiles = [
                SELECT Id, Name
                FROM Profile
                WHERE Name LIKE :PROFILE_PREFIX
            ];
            Map<String, Profile> mapProfile = new Map<String, Profile>();
            for (Profile p : communityUserProfiles) {
                mapProfile.put(p.Name, p);
            }

            List<BuyerAccount> buyerAccountsObject = new List<BuyerAccount>();
            for (Account acct : accountsObject) {
                BuyerAccount buyerAccount = new BuyerAccount();
                buyerAccount.BuyerId = acct.Id;
                buyerAccount.Name = acct.Name;
                buyerAccount.IsActive = true;
                buyerAccountsObject.add(buyerAccount);
            }
            insert buyerAccountsObject;

            List<Contact> contactsObject = new List<Contact>();
            contactsObject.add(
                new Contact(
                    FirstName = 'b1',
                    LastName = 'buyer1',
                    Email = 'p1@testemail.com',
                    Title = 'Persona1',
                    Employee_Status__c = 'Active',
                    AccountId = mapAccounts.get('Account 1').Id
                )
            );
            contactsObject.add(
                new Contact(
                    FirstName = 'm1',
                    LastName = 'manager1',
                    Email = 'bp2@testemail.com',
                    Title = 'Persona2',
                    Employee_Status__c = 'Active',
                    AccountId = mapAccounts.get('Account 1').Id
                )
            );
            contactsObject.add(
                new Contact(
                    FirstName = 'ro1',
                    LastName = 'readonly1',
                    Email = 'cp3@testemail.com',
                    Title = 'Persona3',
                    Employee_Status__c = 'Active',
                    AccountId = mapAccounts.get('Account 1').Id
                )
            );
            contactsObject.add(
                new Contact(
                    FirstName = 'ro2',
                    LastName = 'readonly2',
                    Email = 'dp3@testemail.com',
                    Title = 'Persona3',
                    Employee_Status__c = 'Active',
                    AccountId = mapAccounts.get('Account 2').Id
                )
            );
            contactsObject.add(
                new Contact(
                    FirstName = 'fb1',
                    LastName = 'fallback1',
                    Email = 'ep4@testemail.com',
                    Title = 'Persona4',
                    Employee_Status__c = 'Active',
                    AccountId = mapAccounts.get('Account 2').Id
                )
            );
            contactsObject.add(
                new Contact(
                    FirstName = 'is1',
                    LastName = 'salesrep',
                    Email = 'salesrep12@testemail.com',
                    Title = 'Persona5',
                    Employee_Status__c = 'Active',
                    AccountId = mapAccounts.get('Account 2').Id
                )
            );
            contactsObject.add(
                new Contact(
                    FirstName = 'orderHistoryTester',
                    LastName = 'exportAffiliate',
                    Email = 'orderHistoryTester1@testemail.com',
                    Title = 'OrderHistoryTester1',
                    Employee_Status__c = 'Active',
                    AccountId = mapAccounts.get('Account 1').Id
                )
            );
            contactsObject.add(
                new Contact(
                    FirstName = 'orderHistoryTester',
                    LastName = 'salesRep',
                    Email = 'orderHistoryTester2@testemail.com',
                    Title = 'OrderHistoryTester2',
                    Employee_Status__c = 'Active',
                    AccountId = mapAccounts.get('Account 1').Id
                )
            );
            insert contactsObject;
            List<Contact_Team__c> ct = new List<Contact_Team__c>();
            for (Contact cont : contactsObject) {
                mapContacts.put(cont.LastName, cont);
                ct.add(new Contact_Team__c(Contact__c = cont.Id, Team_Member__c = portalAccountOwner.Id));
            }
            insert ct;
            //#endregion

            //#region Create community users
            Integer p1cnt = 0;
            Integer p2cnt = 0;
            Integer p3cnt = 0;
            Integer p4cnt = 0;
            Integer p5cnt = 0;
            Integer p6cnt = 0;

            List<User> usersObject = new List<User>();
            for (Contact cont : contactsObject) {
                system.debug('***' + cont + 'mapProfile' + mapProfile);
                // system.debug('Map**'+mapProfile.get(PERSONA1_PROFILE).Id);

                User u = new User();
                u.Email = cont.Email;
                u.Username = cont.Email;
                u.TimeZoneSidKey = 'America/New_York';
                u.EmailEncodingKey = 'ISO-8859-1';
                u.LocaleSidKey = 'en_US';
                u.LanguageLocaleKey = 'en_US';
                u.ContactId = cont.Id;
                u.FirstName = cont.FirstName;
                u.LastName = cont.LastName;
                u.ManagerId = UserInfo.getUserId();

                if (cont.Title == 'Persona1') {
                    u.ProfileId = mapProfile.get(PERSONA1_PROFILE).Id;
                    //u.PortalRole = 'User';
                    u.CommunityNickname = 't_buyer_' + (++p1cnt);
                    u.Alias = 't_b_' + (++p1cnt);
                } else if (cont.Title == 'Persona2') {
                    u.ProfileId = mapProfile.get(PERSONA2_PROFILE).Id;
                    //u.PortalRole = 'User';
                    u.CommunityNickname = 't_manager_' + (++p2cnt);
                    u.Alias = 't_m_' + (++p1cnt);
                } else if (cont.Title == 'Persona3') {
                    u.ProfileId = mapProfile.get(PERSONA3_PROFILE).Id;
                    //u.PortalRole = 'User';
                    u.CommunityNickname = 't_readonly_' + (++p3cnt);
                    u.Alias = 't_ro_' + (++p1cnt);
                } else if (cont.Title == 'Persona4') {
                    u.ProfileId = mapProfile.get(PERSONA4_PROFILE).Id;
                    //u.PortalRole = 'User';
                    u.CommunityNickname = 't_fallback_' + (++p4cnt);
                    u.Alias = 't_fb_' + (++p1cnt);
                } else if (cont.Title == 'Persona5') {
                    u.ProfileId = mapProfile.get(PERSONA4_PROFILE).Id;
                    //u.PortalRole = 'User';
                    u.CommunityNickname = 't_salesrep_' + (++p5cnt);
                    u.Alias = 't_is_' + (++p1cnt);
                } else if (cont.Title == 'OrderHistoryTester1') {
                    u.ProfileId = mapProfile.get(PERSONA1_PROFILE).Id;
                    //u.PortalRole = 'User';
                    u.CommunityNickname = 't_export_' + (++p6cnt);
                    u.Alias = 't_exp_' + (++p1cnt);
                } else if (cont.Title == 'OrderHistoryTester2') {
                    u.ProfileId = mapProfile.get(PERSONA1_PROFILE).Id;
                    //u.PortalRole = 'User';
                    u.CommunityNickname = 't_sales_' + (++p6cnt);
                    u.Alias = 't_sls_' + (++p1cnt);
                } else {
                    throw new applicationTestException('Title of contact not defined - this must be set for the tests');
                }
                usersObject.add(u);
            }
            insert usersObject;
            //#endregion

            //#region Assign permission sets to community users
            List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();

            for (User u : usersObject) {
                mapUsers.put(u.CommunityNickname, u);
                //Set for various personas
                if ((u.CommunityNickname.contains('buyer')) || (u.CommunityNickname.contains('manager')) || (u.CommunityNickname.contains('salesrep'))) {
                    psa.add(new PermissionSetAssignment(PermissionSetId = mapPermSet.get(ALL_USERS_PERMSET), AssigneeId = u.Id));
                    psa.add(new PermissionSetAssignment(PermissionSetId = mapPermSet.get(SWITCH_ACCOUNT_USERS_PERMSET), AssigneeId = u.Id));
                }
                if (u.CommunityNickname.contains('manager')) {
                    psa.add(new PermissionSetAssignment(PermissionSetId = mapPermSet.get(SUPER_USERS_PERMSET), AssigneeId = u.Id));
                }
                if (u.CommunityNickname.contains('readonly')) {
                    psa.add(new PermissionSetAssignment(PermissionSetId = mapPermSet.get(READ_ONLY_USERS_PERMSET), AssigneeId = u.Id));
                }
                if (u.CommunityNickname.contains('salesrep')) {
                    psa.add(new PermissionSetAssignment(PermissionSetId = mapPermSet.get(INTERNAL_SALESREP_PERMSET), AssigneeId = u.Id));
                }
            }
            insert psa;
            //#endregion

            //#region Create price book
            List<Pricebook2> priceBooksObject = new List<Pricebook2>();

            try {
                Pricebook2 checkStandard = [
                    SELECT Id
                    FROM Pricebook2
                    WHERE Name = 'Standard Price Book'
                    LIMIT 1
                ];
            } catch (Exception e) {
                Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true, Name = 'Standard Price Book');
                update standardPricebook;
            }

            priceBooksObject.add(new Pricebook2(Name = 'Commerce Standard', IsActive = true));
            insert priceBooksObject;
            //#endregion

            //#region Assign prices to products
            List<PricebookEntry> pbeStandard = new List<PricebookEntry>();
            List<PricebookEntry> pbeCommerce = new List<PricebookEntry>();

            //#region Create products
            List<Product2> productsObject = new List<Product2>();
            for (Integer i = 0; i < productCount; i++) {
                productsObject.add(
                    new Product2(
                        Name = 'Test Product' + i,
                        StockKeepingUnit = 'test_p' + i,
                        IsActive = true,
                        UniqueId__c = '987654A' + i,
                        Related_Product_SKUs__c = 'test_p1' + ',' + 'test_p2',
                        Instruction_Manual__c = 'test_instruction_manual'
                    )
                );
            }

            system.debug('****' + productsObject);
            insert productsObject;
            //#endregion

            //#region Create product tags
            List<Product_Tag__c> tags = createProductTags(productsObject, true);
            //#endregion

            for (Product2 prod : productsObject) {
                mapProducts.put(prod.StockKeepingUnit, prod);
                pbeStandard.add(
                    new PricebookEntry(Product2Id = prod.Id, Pricebook2 = new Pricebook2(Name = 'Standard Price Book'), UnitPrice = 1.00, UseStandardPrice = false, IsActive = true)
                );
                pbeCommerce.add(
                    new PricebookEntry(Product2Id = prod.Id, Pricebook2 = new Pricebook2(Name = 'Commerce Standard'), UnitPrice = 1.00, UseStandardPrice = false, IsActive = true)
                );
            }
            insert pbeStandard;
            insert pbeCommerce;
            //#endregion

            //#region Create entitlement policy, buyer group, and assign memebers
            CommerceEntitlementPolicy commerceEntPolicy = new CommerceEntitlementPolicy(
                CanViewPrice = true,
                CanViewProduct = true,
                IsActive = true,
                Name = 'Test _ All Products and Prices'
            );
            insert commerceEntPolicy;

            BuyerGroup buyerGrp = new BuyerGroup(Name = 'Test _ Standard');
            insert buyerGrp;

            CommerceEntitlementBuyerGroup cebg = new CommerceEntitlementBuyerGroup(BuyerGroupId = buyerGrp.Id, PolicyId = commerceEntPolicy.Id);
            insert cebg;
            BuyerGroupPricebook bgpb = new BuyerGroupPricebook(BuyerGroupId = buyerGrp.Id, Pricebook2 = new Pricebook2(Name = 'Commerce Standard'), IsActive = true);
            insert bgpb;
            List<BuyerGroupMember> buyerGrpsObject = new List<BuyerGroupMember>();
            for (Account acct : accountsObject) {
                buyerGrpsObject.add(new BuyerGroupMember(BuyerId = acct.Id, BuyerGroupId = buyerGrp.Id));
            }
            insert buyerGrpsObject;
            //#endregion

            // Create User SAP Account records for buyer and manager.
            // The buyer user has only one record, while the manager has several
            // combinations that can be used for testing (which are shown below)
            //   Buyer: (a0, a0)
            // Manager: (a0, a0) (a0, a1) (a0, a2) (a0, a3)
            //          (a1, a3) (a1, a4) (a1, a5)
            //          (a2, a4) (a2, a5)
            userSapAccountList = createUserSapAccounts(true);

            //#region Get community and webstore IDs and create webstore pricebook and catalog
            try {
                communityId = [
                    SELECT Id
                    FROM Network
                    WHERE Name IN :COMMUNITY_NAME_OPTIONS AND Status = 'Live'
                    LIMIT 1
                ]
                .Id;
                webStoreId = [
                    SELECT WebStoreId
                    FROM WebStoreNetwork
                    WHERE NetworkId = :communityId
                    LIMIT 1
                ]
                .WebStoreId;
            } catch (System.QueryException qe) {
                communityId = null;
                webStoreId = null;
            }

            if (String.isBlank(webStoreId)) {
                System.debug('Webstore is BLANK - If you need this value, you will need to use (SeeAllData = true) for your method.');
                System.debug('It is also possible that the name of the community was not found or Active.  The community must be active ');
                System.debug('and have the proper permission sets applied.');
                System.debug('The communities being looked for are: ' + COMMUNITY_NAME_OPTIONS);
            } else {
                WebStoreBuyerGroup wsbg = new WebStoreBuyerGroup(BuyerGroupId = buyerGrp.Id, WebStoreId = webStoreId);
                insert wsbg;
                WebStorePricebook wspb = new WebStorePricebook(Pricebook2 = new Pricebook2(Name = 'Commerce Standard'), WebStoreId = webStoreId, IsActive = true);
                insert wspb;

                WebStoreCatalog catalog = [
                    SELECT Id, ProductCatalogId
                    FROM WebStoreCatalog
                    WHERE SalesStoreId = :webStoreId
                    LIMIT 1
                ];
                //#endregion

                //#region Create product categories
                List<ProductCategoryProduct> productCategories = new List<ProductCategoryProduct>();

                ProductCategory parentCategory = new ProductCategory(Name = 'Parent Category', CatalogId = catalog.ProductCatalogId);
                insert parentCategory;
                mapCategories.put('Parent Category', parentCategory);

                List<ProductCategory> childCategories = new List<ProductCategory>();
                for (Integer i = 0; i < 7; i++) {
                    ProductCategory cat = new ProductCategory(ParentCategoryId = parentCategory.Id, Name = 'Child Category ' + (i + 1), CatalogId = catalog.ProductCatalogId);
                    mapCategories.put(cat.Name, cat);
                    childCategories.add(cat);
                }

                insert childCategories;

                for (Product2 prod : productsObject) {
                    for (ProductCategory child : childCategories) {
                        productCategories.add(new ProductCategoryProduct(ProductId = prod.Id, ProductCategoryId = child.Id));
                    }
                }

                insert productCategories;
                //#endregion

                //#region Create product categories and assign products to category and entitlement policy
                ProductCategory prodCategory = new ProductCategory(Name = 'Test Category', IsNavigational = true, CatalogId = catalog.ProductCatalogId);
                insert prodCategory;
                List<CommerceEntitlementProduct> cep = new List<CommerceEntitlementProduct>();
                for (Product2 prod : productsObject) {
                    cep.add(new CommerceEntitlementProduct(PolicyId = commerceEntPolicy.Id, ProductId = prod.Id));
                }
                insert cep;
            }
            //#endregion
        }
        //#endregion
    }
}
