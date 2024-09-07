global with sharing class B2B_CommunityUserSched implements Schedulable {
    /* Run daily 1 am.
    --------------------------------------------------------------------------
    System.schedule('B2B_CommunityUserSched at 1 AM Friday', B2B_CommunityUserSched.CRON_EXP, new B2B_CommunityUserSched());
    --------------------------------------------------------------------------
    */
    public static String CRON_EXP = '0 0 1 ? * FRI *';

    global void execute(SchedulableContext ctx) {
        B2B_CommunityUserBatch b = new B2B_CommunityUserBatch();
        ID BatchProcessId = Database.executeBatch(b, 200);
    }
}
