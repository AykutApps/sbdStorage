
global with sharing class B2B_ProductQuantityRuleSched implements Schedulable {
    /* Run daily 5 am.
    --------------------------------------------------------------------------
    Scheduling Script   (copy & paste into execute anonymous window to schedule batch job)
    --------------------------------------------------------------------------
    System.schedule('B2B_ProductQuantityRuleSched', B2B_ProductQuantityRuleSched.CRON_EXP, new B2B_ProductQuantityRuleSched());
    --------------------------------------------------------------------------
    */
    public static String CRON_EXP = '0 0 5 * * ?';

    global void execute(SchedulableContext ctx) {
        B2B_ProductQuantityRuleBatch b = new B2B_ProductQuantityRuleBatch();
        ID BatchProcessId = Database.executeBatch(b,200); 
    }
}
