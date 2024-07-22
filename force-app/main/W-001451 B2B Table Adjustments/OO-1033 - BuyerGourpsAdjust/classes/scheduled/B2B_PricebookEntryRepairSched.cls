global with sharing class B2B_PricebookEntryRepairSched implements Schedulable {
    /* Run daily 1 am.
    --------------------------------------------------------------------------
    Scheduling Script   (copy & paste into execute anonymous window to schedule batch job)
    --------------------------------------------------------------------------
    System.schedule('B2B_PricebookEntryRepairSched', B2B_PricebookEntryRepairSched.CRON_EXP, new B2B_PricebookEntryRepairSched());
    --------------------------------------------------------------------------
    */
    public static String CRON_EXP = '0 0 1 * * ?';

    global void execute(SchedulableContext ctx) {
        B2B_PricebookEntryRepairBatch b = new B2B_PricebookEntryRepairBatch();
        ID BatchProcessId = Database.executeBatch(b, 200);
    }
}
