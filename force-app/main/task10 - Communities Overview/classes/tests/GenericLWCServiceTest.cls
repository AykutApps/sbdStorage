@isTest
private class GenericLWCServiceTest {

    static String ACCNAME = 'test account';

    @TestSetup
    static void setup() {
        TestData_Account.createConsumerAccount(ACCNAME);
    }

    @isTest
    static void testGetRecords() {
        List<Account> accs = (List<Account> )GenericLWCService.getRecords('SELECT Id, Name FROM Account');
        Assert.areEqual(accs.size(),1);
    }
}