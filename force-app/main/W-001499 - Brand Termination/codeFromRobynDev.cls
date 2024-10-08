public class TerminationTriggerHandler implements TriggerInterface {
    public static boolean firstPass = true;

    public void beforeInsert() {
        checkApprovalCriteria(Trigger.old, Trigger.new);
        preventDuplicateTermination(Trigger.new);
        preventDuplicateBrandTermination(Trigger.new);
    }

    public void beforeUpdate() {
        checkApprovalCriteria(Trigger.old, Trigger.new);
    }

    public void beforeDelete() {
    }

    public void afterInsert() {
    }

    public void afterUpdate() {
    }

    public void afterDelete() {
    }

    public void finish() {
    }

    private void checkApprovalCriteria(List<Termination__c> oldTerminations, List<Termination__c> newTerminations) {
        String errorString = 'Required fields must be entered before Approving: ';
        String errorFields = '';
        Integer listPointer = 0;

        Map<Id, RecordTypeInfo> recordTypeInfoMap = Termination__c.sObjectType.getDescribe().getRecordTypeInfosById();

        for (Termination__c t : newTerminations) {
            Boolean isBrandTermination = recordTypeInfoMap.get(t.RecordTypeId).getDeveloperName() == 'Brand_Termination';
            Boolean isDealerTermination = recordTypeInfoMap.get(t.RecordTypeId).getDeveloperName() == 'Termination';
            List<String> brandValues = t.Brand__c != null ? t.Brand__c.split(';') : new List<String>();

            Boolean isCubBrandTermination = brandValues.contains('Cub') && isBrandTermination;
            Boolean isHustlerBrandTermination = brandValues.contains('Hustler') && isBrandTermination;
            Boolean isBigDogBrandTermination = brandValues.contains('Big Dog') && isBrandTermination;

            if (t.Status__c != null && (t.Status__c != oldTerminations.get(listPointer).Status__c)) {
                //only perform validations if there is a status, and only if the status has changed (ex: do NOT validate if the record is just saved rather than approved)

                // TODO  Termnination and Only Cub Dealer
                if (t.Status__c == 'Watch') {
                    if (t.Over__c == null && (isDealerTermination || isCubBrandTermination)) {
                        errorFields = errorFields + '(Over 540 Days) ';
                    }
                    if (t.SAU_Amount__c == null && (isDealerTermination || isCubBrandTermination)) {
                        errorFields = errorFields + '(SAU Amount) ';
                    }
                    if (errorFields != '') {
                        t.addError(errorString + errorFields);
                    }
                } else if (t.Status__c == 'Initation') {
                    if (t.Open_Account_Balance__c == null) {
                        errorFields = errorFields + '(Open Account Balance) ';
                    }
                    if (t.Termination_Type__c == null) {
                        errorFields = errorFields + '(Termination Type) ';
                    }
                    if (errorFields != '') {
                        t.addError(errorString + errorFields);
                    }
                } else if (t.Status__c == 'Legal') {
                    if (t.Termination_Letter_Rec_d_Date__c == null) {
                        errorFields = errorFields + '(Termination Letter Received Date) ';
                    }
                    if (t.Termination_Letter_Type__c == null) {
                        errorFields = errorFields + '(Termination Letter Type) ';
                    }
                    if (t.Termination_Reason__c == null) {
                        errorFields = errorFields + '(Termination Reason) ';
                    }
                    if (t.Estimated_Parts_Return__c == null) {
                        errorFields = errorFields + '(Estimated Parts Return) ';
                    }
                    if (t.Paid_Inventory_Value__c == null && (isDealerTermination || isCubBrandTermination)) {
                        errorFields = errorFields + '(Paid Inventory Value XXX) ';
                    }
                    if (t.Parts_Returned__c == null) {
                        errorFields = errorFields + '(Parts Returned) ';
                    }

                    // Brand Only
                    if (isBrandTermination) {
                        if (t.Huster_Termination_Date__c == null && checkPicklistValue(t, 'Brand__c', 'Hustler')) {
                            errorFields = errorFields + '(Huster Termination Date) ';
                        }
                        if (t.Big_Dog_Termination_Date__c == null && checkPicklistValue(t, 'Brand__c', 'Big Dog')) {
                            errorFields = errorFields + '(Big_Dog Termination Date) ';
                        }
                        if (t.Cub_Cadet_Termination_Date__c == null && checkPicklistValue(t, 'Brand__c', 'Cub')) {
                            errorFields = errorFields + '(Cub Cadet Termination Date) ';
                        }
                    }

                    if (errorFields != '') {
                        t.addError(errorString + errorFields);
                    }
                } else if (t.Status__c == 'Inv. Disposition') {
                    // TODO Actual_Termination_Date__c only dealer termination not Brands, brands needs to be excluded
                    if (t.Actual_Termination_Date__c == null && isDealerTermination) {
                        errorFields = errorFields + '(Actual Termination Date) ';
                    }
                    if (t.Confirmation_Letter_Required__c == null) {
                        errorFields = errorFields + '(Confirmation Letter Required) ';
                    }
                    if (t.Floorplan_Inventory__c == null && (isDealerTermination || isCubBrandTermination)) {
                        errorFields = errorFields + '(Floor Plan Inventory) ';
                    }
                    if (t.Paid_Inventory__c == null && (isDealerTermination || isCubBrandTermination)) {
                        errorFields = errorFields + '(Paid Inventory) ';
                    }
                    if (t.Billiable_By_State_Law__c == null && (isDealerTermination || isCubBrandTermination)) {
                        errorFields = errorFields + '(Billable by State Law) ';
                    }
                    // TODO Dealer Termincation and Brands, Only hustler and big dog, NOT Cub

                    if (errorFields != '') {
                        t.addError(errorString + errorFields);
                    } else {
                        if (t.Simple_Termination__c == true) {
                            t.Status__c = 'Parts';
                        }
                    }
                } else if (t.Status__c == 'Invoice') {
                    //veryify tha one liquidiation types exist
                    Integer liquidCt = [SELECT COUNT() FROM Liquidation_Type__c WHERE Liquidation_Types__c = :t.Id];
                    if (liquidCt < 1 && (isDealerTermination || isCubBrandTermination)) {
                        t.addError('To Approve, at least One related Liquidation Type must be created');
                    }

                    if (t.Repossession_Date__c == null && (isDealerTermination || isCubBrandTermination)) {
                        errorFields = errorFields + '(Repossession Date) ';
                    }
                    //if (t.Repossession_Perform_By__c==null) {errorFields=errorFields + '(Repossession Performed By) ';}
                    if (t.Shelby_Re_Stock__c == null && (isDealerTermination || isCubBrandTermination)) {
                        errorFields = errorFields + '(Shelby Re-Stock) ';
                    }
                    if (t.Martin_Re_Stock__c == null && (isDealerTermination || isCubBrandTermination)) {
                        errorFields = errorFields + '(Martin Re-Stock) ';
                    }
                    if (t.Willard_Re_Stock__c == null && (isDealerTermination || isCubBrandTermination)) {
                        errorFields = errorFields + '(Willard Re-Stock) ';
                    }
                    if (t.CTP_Re_Stock__c == null && (isDealerTermination || isCubBrandTermination)) {
                        errorFields = errorFields + '(CTP Re-Stock) ';
                    }
                    if (t.Freight_Cost_For_Pickup__c == null && (isDealerTermination || isCubBrandTermination)) {
                        errorFields = errorFields + '(Freight Cost (For Pickup)) ';
                    }
                    if (t.Hesston_Re_Stock__c == null && (isDealerTermination || isHustlerBrandTermination || isBigDogBrandTermination)) {
                        errorFields = errorFields + '(Hesston Re-Stock) ';
                    }

                    if (errorFields != '') {
                        t.addError(errorString + errorFields);
                    }
                } else if (t.Status__c == 'Parts') {
                    //make sure at least one termination invoice exist
                    Integer invCt = [SELECT COUNT() FROM Invoice__c WHERE Dealer_Termination_Invoice__c = :t.Id];
                    if (invCt < 1 && (isDealerTermination || isCubBrandTermination)) {
                        t.addError('To Approve, at least One related Dealer Termination Invoice must be created');
                    }
                    //if (t.Actual_Parts_Returned__c==null) {errorFields=errorFields + '(Actual Parts Return) ';}

                    //if (errorFields !='') {
                    //    t.addError(errorString + errorFields);
                    //}

                    if (errorFields != '') {
                        t.addError(errorString + errorFields);
                    }
                } else if (t.Status__c == 'Collection') {
                    if (t.Parts_Returned__c == 'Yes') {
                        if (t.Parts_List_Received__c == null) {
                            errorFields = errorFields + '(Parts List Received) ';
                        }
                        if (t.Pick_Lists_Sent__c == null) {
                            errorFields = errorFields + '(Pick Lists Sent) ';
                        }
                        if (t.Parts_Received_to_Plant__c == null) {
                            errorFields = errorFields + '(Parts Received to Plant) ';
                        }
                        if (t.Parts_Credit_Issued__c == null) {
                            errorFields = errorFields + '(Parts Credit Issued) ';
                        }
                        if (t.Amount_of_Credit__c == null) {
                            errorFields = errorFields + '(Amount of Credit) ';
                        }

                        if (errorFields != '') {
                            t.addError(errorString + errorFields);
                        }
                    }
                } else if (t.Status__c == 'Ready to Finalize') {
                    if (t.Collection_Date__c == null) {
                        errorFields = errorFields + '(Collection Date) ';
                    }
                    if (t.Collection_Amount__c == null) {
                        errorFields = errorFields + '(Collection Amount) ';
                    }
                    if (t.Write_Off_Date__c == null) {
                        errorFields = errorFields + '(Write Off Date) ';
                    }
                    if (t.Write_Off_Amount__c == null) {
                        errorFields = errorFields + '(Write Off Amount) ';
                    }
                    if (t.Open_Account_Balance__c <> 0) {
                        errorFields = errorFields + '(Open Account Balance MUST be Zero) ';
                    }
                    if (errorFields != '') {
                        t.addError(errorString + errorFields);
                    }
                } else if (t.Status__c == 'Complete') {
                    //no criteria
                }
            }
            listPointer = listPointer + 1;
        }
    }

    public static void preventDuplicateTermination(List<Termination__c> newList) {
        Id terminationRecordTypeId = Schema.SObjectType.Termination__c.getRecordTypeInfosByName().get('Termination').getRecordTypeId();
        // Collect all account IDs from the new termination records to be inserted
        Set<Id> accountIds = new Set<Id>();
        for (Termination__c term : newList) {
            if (term.Account__c != null) {
                accountIds.add(term.Account__c);
            }
        }

        // Query to find if any existing termination records exist for these accounts
        Map<Id, Termination__c> existingTerminations = new Map<Id, Termination__c>();
        for (Termination__c term : [SELECT Id, Account__c FROM Termination__c WHERE Account__c IN :accountIds AND RecordType.DeveloperName = 'Termination']) {
            existingTerminations.put(term.Account__c, term);
        }

        // Check each new termination record against existing ones
        system.debug(Schema.SObjectType.Termination__c.getRecordTypeInfosByName());
        system.debug(Schema.SObjectType.Termination__c.getRecordTypeInfosByName().get('Termination'));
        system.debug(Schema.SObjectType.Termination__c.getRecordTypeInfosByName().get('Termination').getRecordTypeId());
        for (Termination__c term : newList) {
            if (term.RecordTypeId == terminationRecordTypeId && existingTerminations.containsKey(term.Account__c)) {
                term.addError('A termination record already exists for this account.');
            }
        }
    }

    public static void preventDuplicateBrandTermination(List<Termination__c> newList) {
        system.debug(Schema.SObjectType.Termination__c.getRecordTypeInfosByName());
        system.debug(Schema.SObjectType.Termination__c.getRecordTypeInfosByName().get('Brand Termination'));
        system.debug(Schema.SObjectType.Termination__c.getRecordTypeInfosByName().get('Brand Termination').getRecordTypeId());
        Id brandTerminationRecordTypeId = Schema.SObjectType.Termination__c.getRecordTypeInfosByName().get('Brand Termination').getRecordTypeId();
        // Prepare sets to collect unique combinations of Account IDs and Brand values
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Set<String>> newBrandsByAccount = new Map<Id, Set<String>>();

        for (Termination__c term : newList) {
            if (term.Account__c != null && term.Brand__c != null) {
                accountIds.add(term.Account__c);
                if (!newBrandsByAccount.containsKey(term.Account__c)) {
                    newBrandsByAccount.put(term.Account__c, new Set<String>());
                }
                // Splitting the multi-select picklist values and adding them to the set
                newBrandsByAccount.get(term.Account__c).addAll(term.Brand__c.split(';'));
            }
        }

        // Query existing records for overlaps in brand values
        Map<Id, Set<String>> existingBrandsByAccount = new Map<Id, Set<String>>();
        for (Termination__c existingTerm : [
            SELECT Id, Account__c, Brand__c
            FROM Termination__c
            WHERE Account__c IN :accountIds AND RecordType.DeveloperName = 'Brand_Termination'
        ]) {
            if (existingTerm.Brand__c != null) {
                if (!existingBrandsByAccount.containsKey(existingTerm.Account__c)) {
                    existingBrandsByAccount.put(existingTerm.Account__c, new Set<String>());
                }
                existingBrandsByAccount.get(existingTerm.Account__c).addAll(existingTerm.Brand__c.split(';'));
            }
        }

        system.debug(existingBrandsByAccount);
        system.debug(newBrandsByAccount);

        // Compare new record brands with existing brands for each account
        for (Termination__c term : newList) {
            system.debug('term');
            system.debug(term);
            system.debug(term.RecordType.DeveloperName);
            system.debug(term.Account__c);
            if (term.RecordTypeId == brandTerminationRecordTypeId && newBrandsByAccount.containsKey(term.Account__c)) {
                system.debug('If');
                system.debug(newBrandsByAccount);
                Set<String> existingBrands = existingBrandsByAccount.get(term.Account__c);
                Set<String> newBrands = newBrandsByAccount.get(term.Account__c);

                system.debug(existingBrands);
                system.debug(newBrands);

                // Check for any overlap between new and existing brands
                for (String brand : newBrands) {
                    system.debug('new Brand');
                    system.debug(brand);
                    if (existingBrands != null && existingBrands.contains(brand)) {
                        term.addError('A Brand Termination record already exists for one or more of the selected brands under the same account.');
                        break;
                    }
                }
            }
        }
    }

    public static Boolean checkPicklistValue(sObject record, String fieldName, String valueToCheck) {
        // Retrieve the multi-select picklist field value as a string
        String picklistValues = (String) record.get(fieldName);

        // Check if the picklistValues string is not empty
        if (String.isNotBlank(picklistValues)) {
            // Split the picklist values into an array
            List<String> valuesList = picklistValues.split(';');

            // Check if the array contains the value to check
            return valuesList.contains(valueToCheck);
        }
        return false;
    }
}
