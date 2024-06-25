public with sharing class RecallHelper {
/*  Supports MTD's Global Recall Processes including Stop Sale & Safety Advisory notices to IR Dealers.
*/
    public static string deriveKey(Recall_Account__c ra){
        String out; 
        //ToDo: move this to the RecallHelper
        if(ra != null){
            out = IDHelper.deriveIDKey(ra.Recall__c, ra.Account__c);
        }
        return out;
    }
    
    //ToFuture:  switch to RegEx to match the RC-00005 in the email subject
    public static string parseRecallNumber(string subject){
        //does the inbound string have an 8 character recall #?  Recall__c.Recall_Number__c (e.g. RC-00005) 
        string out; //returns null or recall number
        subject = (subject == null) ? '' : subject.trim();
        system.debug('xxx-subject-'+subject);
        if(subject == ''){
            system.debug('xxx-skip/no subject');
        } else if(subject.contains('RC-')) { //may have an 8 character Recall__c.Recall_Number__c (e.g. RC-00005) 
            integer pos = subject.indexOf('RC-');
            //system.debug('xxx-pos-'+pos);
            if(subject.length() >= pos + 7){
                String tmp = subject.substring(pos, pos + 8); //is this an 8 character recall number?
                //system.debug('xxx-tmp-'+tmp);
                String seed = tmp.right(5);
                system.debug('xxx-seed-'+seed);
                if(seed.isNumeric()){
                    out = tmp;
                }
            }
        }
        return out;
    }

}