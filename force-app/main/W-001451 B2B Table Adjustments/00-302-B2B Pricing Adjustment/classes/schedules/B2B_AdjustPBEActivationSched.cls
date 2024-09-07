global with sharing class B2B_AdjustPBEActivationSched implements Schedulable {
    /* Run daily at 1a.
    --------------------------------------------------------------------------
    Scheduling Script   (copy & paste into execute anonymous window to schedule batch job)
    --------------------------------------------------------------------------
    System.schedule('B2B_AdjustPBEActivationSched', B2B_AdjustPBEActivationSched.CRON_EXP, new B2B_AdjustPBEActivationSched());
    --------------------------------------------------------------------------
    */
    public static String CRON_EXP = '0 0 1 * * ?';

    global void execute(SchedulableContext ctx) {
        B2B_AdjustPBEActivationBatch b = new B2B_AdjustPBEActivationBatch();
        ID BatchProcessId = Database.executeBatch(b, 200);
    }
}