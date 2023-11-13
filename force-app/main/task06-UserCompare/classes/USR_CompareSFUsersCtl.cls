global with sharing class USR_CompareSFUsersCtl {
    /*  Simple utility that compares up to 3 users for the Salesforce.com Triager Support Team (aka sales/retail support).
    - base sf user:    provide SF Id in query-string-param "Id"
    - other sf user:   compare to base user; end-user keys User.Username on the VF page
    - another sf user: compare to base user; end-user keys User.Username on the VF page

    IMPORTANT: should be WITH SHARING so that the tool can be opened up to the business admins in the future
*/
    //member properties
    public Boolean testMode { get; set; }
    public Boolean showAnalysis { get; set; } //true means the analysis columns will display to the user
    public Integer curPage { get; private set; } // multi-page VF wizard

    private Id baseId; //set by query-string-param "Id"
    public User baseUser { get; private set; }

    public String otherUsername { get; set; } //user input
    private Id otherId;
    public User otherUser { get; private set; }

    public String anotherUsername { get; set; } //user input
    private Id anotherId;
    public User anotherUser { get; private set; }

    public Map<Id, SelectOption> userSelectOptionsMap { get; private set; }
    public Map<Id, List<PermissionSet>> userIdTopermSetsMap { get; private set; } //PermissionSet memberships for each SF User
    public Map<Id, List<GroupMember>> userIdToQueuesMap { get; private set; } //Queue memberships for each SF User
    public Map<Id, List<GroupMember>> userIdToPublicGroupsMap { get; private set; } //Public Group memberships for each SF User

    public List<MTD_CompareModels.GridRow> rows { get; private set; } //each row has 3 columns - col 1 for baseUser, col 2 for otherUser, col 3 for anotherUser

    //////// LOOKUP //////////

    public String searchString { get; set; }
    public List<User> users { get; set; }
    public User compareUser2 { get; set; }
    public User compareUser3 { get; set; }

    public void dynamicSearch() {
        if (searchString != null && searchString.length() > 2) {
            // Only search after 2 characters have been typed.
            String query = '%' + searchString + '%';
            users = [SELECT Id, Name, Username FROM User WHERE Name LIKE :query LIMIT 10];
        } else {
            users.clear();
        }
    }
    //////////////

    //constructors
    public USR_CompareSFUsersCtl() {
        users = new List<User>();
        compareUser2 = new User();
        compareUser3 = new User();
        init();
        //get testMode (optional)
        if (ApexPages.currentPage().getParameters().get('testMode') == '1') {
            testMode = true;
        }
        //get base SF User Id for the compare
        String inUserId = ApexPages.currentPage().getParameters().get('Id');
        if (IDHelper.isValid(inUserId, '005')) {
            //Must be an SF User ID
            try {
                baseId = inUserId;
            } catch (Exception ex) {
            } //baseId remains null
        }
        if (baseId == null) {
            baseId = UserInfo.getUserId();
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'No SF User ID provided, so the base user for the comparison is set to you.');
            ApexPages.addMessage(msg);
        }
        //if in testMode, find 2 quality SF User records in the ORG if available
        if (testMode == true) {
            try {
                otherUserName = [SELECT Id, Username FROM User WHERE IsActive = TRUE AND Profile.Name = 'IR-USA-DLR-Base profile' LIMIT 1].Username;
            } catch (Exception ex) {
            } //otherUserName remains null
            try {
                anotherUserName = [SELECT Id, Username FROM User WHERE Profile.Name = 'Dealer Fulfillment Coordinator' LIMIT 1].Username;
            } catch (Exception ex) {
            } //anotherUserName remains null
        }
        //fetch user
        fetchUsers();
    }
    //public getters/setters

    //public actions
    public PageReference toggleAnalysis() {
        this.showAnalysis = !this.showAnalysis;
        return null; //repaint screen
    }
    public PageReference saveAsPDF() {
        //ToFuture
        return null;
    }
    public PageReference saveAsSheet() {
        //ToFuture
        return null;
    }
    public PageReference refresh() {
        rows = null;
        curPage = 2;

        fetchUsers();
        //compare the base to 1 or 2 other SF Users
        rows = USR_CompareSFUsersHelper.deriveUserGridRows(baseUser, otherUser, anotherUser);
        rows.addAll(USR_CompareSFUsersHelper.derivePermissionSetGridRows(baseUser, otherUser, anotherUser));
        rows.addAll(USR_CompareSFUsersHelper.deriveGroupAndQueueGridRows(baseUser, otherUser, anotherUser));
        rows.addAll(USR_CompareSFUsersHelper.deriveChatterGroupGridRows(baseUser, otherUser, anotherUser));

        //route
        PageReference pg = Page.CompareSFUsers2; //VF Wizard Page 2
        if (pg == null) {
            return null; //forces repaint
        } else {
            return pg;
        }
    }
    public PageReference compareUsers() {
        rows = null;
        curPage = 2;
        otherUsername = compareUser2?.UserName;
        anotherUsername = compareUser3?.UserName;
        fetchUsers();
        //compare the base to 1 or 2 other SF Users
        rows = USR_CompareSFUsersHelper.deriveUserGridRows(baseUser, otherUser, anotherUser);
        rows.addAll(USR_CompareSFUsersHelper.derivePermissionSetGridRows(baseUser, otherUser, anotherUser));
        rows.addAll(USR_CompareSFUsersHelper.deriveGroupAndQueueGridRows(baseUser, otherUser, anotherUser));
        rows.addAll(USR_CompareSFUsersHelper.deriveChatterGroupGridRows(baseUser, otherUser, anotherUser));
        rows.addAll(USR_CompareSFUsersHelper.deriveDelegateGroups(baseUser, otherUser, anotherUser));

        //route
        PageReference pg = Page.CompareSFUsers2; //VF Wizard Page 2
        if (pg == null) {
            return null; //forces repaint
        } else {
            return pg;
        }
    }
    public PageReference chooseUsers() {
        curPage = 1;

        //route
        PageReference pg = Page.CompareSFUsers; //VF Wizard Page 1
        if (pg == null) {
            return null; //forces repaint
        } else {
            return pg;
        }
    }
    public PageReference swapUsers() {
        rows = null;
        curPage = 2;

        Id newBaseId, newOtherId, newAnotherId;
        String newOtherUsername, newAnotherUsername;

        //swap if 3 users or if otherId is null
        if (anotherId != null && baseId != null) {
            if (otherId != null) {
                newAnotherId = otherId;
                newAnotherUsername = otherUser.Username;
                newOtherId = baseId;
                newOtherUsername = baseUser.Username;
                newBaseId = anotherId;
            } else {
                newAnotherId = null;
                newAnotherUsername = null;
                newOtherId = baseId;
                newOtherUsername = baseUser.Username;
                newBaseId = otherId;
            }
        } else if (otherId != null && baseId != null) {
            newAnotherId = null;
            newAnotherUsername = null;
            newOtherId = baseId;
            newOtherUsername = baseUser.Username;
            newBaseId = otherId;
        } else {
            //ToFuture: message that says "nothing to swap" (or similar)
        }

        //assign users
        anotherId = (newAnotherId != null) ? newAnotherId : null;
        anotherUsername = (newAnotherUsername != null) ? newAnotherUsername : null;

        otherId = (newOtherId != null) ? newOtherId : null;
        otherUsername = (newOtherUsername != null) ? newOtherUsername : null;

        baseId = (newBaseId != null) ? newBaseId : null;

        fetchUsers();
        //compare the base to 1 or 2 other SF Users
        rows = USR_CompareSFUsersHelper.deriveUserGridRows(baseUser, otherUser, anotherUser);
        rows.addAll(USR_CompareSFUsersHelper.derivePermissionSetGridRows(baseUser, otherUser, anotherUser));
        rows.addAll(USR_CompareSFUsersHelper.deriveGroupAndQueueGridRows(baseUser, otherUser, anotherUser));

        //route
        PageReference pg = null; //Page.CompareSFUsers2; //VF Wizard Page 2
        if (pg == null) {
            return null; //forces repaint
        } else {
            return pg;
        }
    }

    @RemoteAction
    global static String updatePermission(String PermissionId, String UserId) {
        insert new PermissionSetAssignment(PermissionSetId = PermissionId, AssigneeId = UserId);
        return 'OK';
    }

    //private methods
    private void init() {
        testMode = false; //should be false in SIT, UAT, PROD; instead add query-string-param testMode=1
        showAnalysis = false;
        curPage = 1;
        userSelectOptionsMap = new Map<Id, SelectOption>();
        userIdTopermSetsMap = new Map<Id, List<PermissionSet>>();
        userIdToQueuesMap = new Map<Id, List<GroupMember>>();
        userIdToPublicGroupsMap = new Map<Id, List<GroupMember>>();
        rows = new List<MTD_CompareModels.GridRow>();
    }

    private void fetchUsers() {
        userSelectOptionsMap = new Map<Id, SelectOption>();
        //base user
        if (baseId != null) {
            User u = fetchUser(baseId);
            if (u != null && u.Id != null) {
                this.baseId = u.Id;
                this.baseUser = u;
                addToUserSelectOptions(u);
            }
        } else {
            baseuser = null;
        }
        //other user
        otherUsername = (otherUsername != null) ? otherUsername.trim() : '';
        if (baseUser != null && !String.isBlank(otherUsername)) {
            User tmp;
            try {
                tmp = [SELECT Id FROM User WHERE UserName = :otherUserName];
            } catch (Exception ex) {
            } //tmp remains null
            if (tmp != null) {
                User u = fetchUser(tmp.Id);
                if (u != null && u.Id != null) {
                    this.otherId = u.Id;
                    this.otherUser = u;
                    addToUserSelectOptions(u);
                }
            } else {
                otherId = null;
                otherUser = null;
            }
        } else {
            otherId = null;
            otherUser = null;
        }
        //another user
        anotherUsername = (anotherUsername != null) ? anotherUsername.trim() : '';
        if (baseUser != null && !String.isBlank(anotherUsername)) {
            User tmp;
            try {
                tmp = [SELECT Id FROM User WHERE UserName = :anotherUserName];
            } catch (Exception Ex) {
            } //tmp remains null
            if (tmp != null) {
                User u = fetchUser(tmp.Id);
                if (u != null && u.Id != null) {
                    this.anotherId = u.Id;
                    this.anotherUser = u;
                    addToUserSelectOptions(u);
                }
            } else {
                anotherId = null;
                anotherUser = null;
            }
        } else {
            anotherId = null;
            anotherUser = null;
        }
    }
    private User fetchUser(Id userId) {
        User out;
        if (userId == null) {
            return out;
        }
        try {
            out = [
                SELECT
                    Id,
                    FirstName,
                    LastName,
                    Title,
                    FederationIdentifier,
                    UserName,
                    Email,
                    IsActive,
                    ProfileId,
                    Profile.Name,
                    UserRoleId,
                    UserRole.Name,
                    ContactId,
                    Contact.Name,
                    Contact.AccountId,
                    Contact.Account.Entity_Id__c,
                    Contact.Account.PEID__c,
                    Contact.Account.ShippingCity,
                    Contact.Account.ShippingState
                FROM User
                WHERE Id = :userId
            ];
        } catch (Exception ex) {
        } //out remains null
        return out;
    }
    private void addToUserSelectOptions(User u) {
        if (u != null && u.Id != null) {
            SelectOption so = new SelectOption(u.id, u.FirstName + ' ' + u.LastName + ' - ' + u.username);
            userSelectOptionsMap.put(u.Id, so);
        }
    }
}
