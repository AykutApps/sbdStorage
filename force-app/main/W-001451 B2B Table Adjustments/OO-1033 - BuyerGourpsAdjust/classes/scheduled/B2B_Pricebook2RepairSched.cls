global with sharing class B2B_Pricebook2RepairSched implements Schedulable {
    /* Run daily 1 am.
    --------------------------------------------------------------------------
    Scheduling Script   (copy & paste into execute anonymous window to schedule batch job)
    --------------------------------------------------------------------------
    System.schedule('B2B_Pricebook2RepairSched', B2B_Pricebook2RepairSched.CRON_EXP, new B2B_Pricebook2RepairSched());
    --------------------------------------------------------------------------
    */
    public static String CRON_EXP = '0 0 1 * * ?';

    global void execute(SchedulableContext ctx) {
        B2B_Pricebook2RepairBatch b = new B2B_Pricebook2RepairBatch();
        ID BatchProcessId = Database.executeBatch(b, 200);
    }
}
