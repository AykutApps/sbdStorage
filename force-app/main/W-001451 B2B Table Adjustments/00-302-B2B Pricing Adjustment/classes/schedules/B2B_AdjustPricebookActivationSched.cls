global with sharing class B2B_AdjustPricebookActivationSched implements Schedulable {
    /* Run hourly between 6a and 10p.
    --------------------------------------------------------------------------
    Scheduling Script   (copy & paste into execute anonymous window to schedule batch job)
    --------------------------------------------------------------------------
    System.schedule('B2B_AdjustPricebookActivationSched', B2B_AdjustPricebookActivationSched.CRON_EXP, new B2B_AdjustPricebookActivationSched());
    --------------------------------------------------------------------------
    */
    public static String CRON_EXP = '0 0 1 * * ?';

    global void execute(SchedulableContext ctx) {
        B2B_AdjustPricebookActivationBatch b = new B2B_AdjustPricebookActivationBatch();
        ID BatchProcessId = Database.executeBatch(b, 200);
    }
}
