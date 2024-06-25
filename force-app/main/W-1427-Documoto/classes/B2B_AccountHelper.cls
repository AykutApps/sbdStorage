public class B2B_AccountHelper {
    public static Map<String, Object> getAccountDetails(Map<String, Object> dataMap) {
        try {
            String effectiveAccountId = (String) dataMap.get('effectiveAccountId');
            Account acc = [
                SELECT Id, Name, Cub_Active__c, Hustler_Active__c, Hustler_Parts_Account__c, Hustler_WG_Account__c, BigDog_Parts_Account__c, BigDog_WG_Account__c
                FROM Account
                WHERE Id = :effectiveAccountId
                LIMIT 1
            ];
            dataMap.put('account', acc);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return dataMap;
    }
}
