global with sharing class B2B_AccountPricebookBgmSched implements Schedulable {
    /* Run daily 1 am.
    --------------------------------------------------------------------------
    Scheduling Script   (copy & paste into execute anonymous window to schedule batch job)
    --------------------------------------------------------------------------
    System.schedule('B2B_AccountPricebookBgmSched', B2B_AccountPricebookBgmSched.CRON_EXP, new B2B_AccountPricebookBgmSched());
    --------------------------------------------------------------------------
    */
    public static String CRON_EXP = '0 0 1 * * ?';

    global void execute(SchedulableContext ctx) {
        B2B_AccountPricebookBgmBatch b = new B2B_AccountPricebookBgmBatch();
        ID BatchProcessId = Database.executeBatch(b, 200);
    }
}
