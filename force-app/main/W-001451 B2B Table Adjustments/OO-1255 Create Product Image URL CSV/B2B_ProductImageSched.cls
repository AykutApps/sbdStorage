global with sharing class B2B_ProductImageSched implements Schedulable {
    /* Run daily 1 am.
    --------------------------------------------------------------------------
    Scheduling Script   (copy & paste into execute anonymous window to schedule batch job)
    --------------------------------------------------------------------------
    Usage 1:
    System.schedule('B2B_ProductImageSched', B2B_ProductImageSched.CRON_EXP_DAILY, new B2B_ProductImageSched());

    Usage 2:
    B2B_ProductImageSched s = new B2B_ProductImageSched();
    s.isDaily = false;
    System.schedule('B2B_ProductImageSched', B2B_ProductImageSched.CRON_EXP_MONTHLY, s);
    --------------------------------------------------------------------------
    */
    public static String CRON_EXP_DAILY = '0 0 5 * * ?';
    public static String CRON_EXP_MONTHLY = '0 0 0 1 * ?';

    public Boolean isDaily = true;

    global void execute(SchedulableContext ctx) {
        B2B_ProductImageBatch b = new B2B_ProductImageBatch();
        b.isDaily = isDaily;
        ID BatchProcessId = Database.executeBatch(b,200);
    }
}