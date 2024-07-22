global with sharing class B2B_AccountPBMapBuyerGroupMembSched implements Schedulable {
    /* Run daily 1 am.
    --------------------------------------------------------------------------
    Scheduling Script   (copy & paste into execute anonymous window to schedule batch job)
    --------------------------------------------------------------------------
    System.schedule('B2B_AccountPBMapBuyerGroupMembSched', B2B_AccountPBMapBuyerGroupMembSched.CRON_EXP, new B2B_AccountPBMapBuyerGroupMembSched());
    --------------------------------------------------------------------------
    */
    public static String CRON_EXP = '0 0 1 * * ?';

    global void execute(SchedulableContext ctx) {
        B2B_AccountPBMapBuyerGroupMembBatch b = new B2B_AccountPBMapBuyerGroupMembBatch();
        ID BatchProcessId = Database.executeBatch(b, 200);
    }
}
