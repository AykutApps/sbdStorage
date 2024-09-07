global with sharing class B2B_ProductAttributeSched implements Schedulable {
    /* Run daily at 1a
    --------------------------------------------------------------------------
    Scheduling Script   (copy & paste into execute anonymous window to schedule batch job)
    --------------------------------------------------------------------------
    System.schedule('B2B_ProductAttributeSched', B2B_ProductAttributeSched.CRON_EXP, new B2B_ProductAttributeSched());
    --------------------------------------------------------------------------
    */
    public static String CRON_EXP = '0 0 1 * * ?';

    global void execute(SchedulableContext ctx) {
        B2B_ProductAttributeBatch b = new B2B_ProductAttributeBatch();
        ID BatchProcessId = Database.executeBatch(b, 200);
    }
}
