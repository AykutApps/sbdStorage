/**
 * Batch Job to support 'Mass Task' e-mail notifications
 */
global class MassTaskEMailBatch implements Database.Batchable<SObject>, Database.Stateful{
    
   public ID massTaskReqID;
    
    global MassTaskEMailBatch (ID massTaskReqID){
    	System.debug('********** MassTaskEMailBatch --> Constructor --> MassTask ReqID: '+massTaskReqID);
        this.massTaskReqID = massTaskReqID;
    }
    
    global Database.queryLocator start(Database.BatchableContext ctx){
        return Database.getQueryLocator([SELECT Who_Email__c, Subject__c, Body__c  FROM Comm_Queue__c where Status__c = 'Pending' and Type__c = 'Email' and What_ID__c =: massTaskReqID]);
    }
    
	/*
	* Batch execution context
	*/
    global void execute(Database.BatchableContext ctx, List<Comm_Queue__c> pendings){     
    	System.debug('********** MassTaskEMailBatch --> execute --> Q Items: '+pendings.size());   
		List<Comm_Queue__c> updates = new List<Comm_Queue__c>();
		
		for(Comm_Queue__c q : pendings){
			Comm_Queue__c up = new Comm_Queue__c(ID=q.ID);
			
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[] {q.Who_Email__c};
				mail.setToAddresses(toAddresses);
				mail.setReplyTo('noreply@salesforce.com');
				mail.setSenderDisplayName('Mass Task Admin');
				mail.setSubject(q.Subject__c);
				mail.setPlainTextBody(q.Body__c);
				mail.setHtmlBody(q.Body__c);			
			
			try{
				Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
				up.Status__c = 'Sent';
				System.debug('********** MassTaskEMailBatch --> E-Mail Status: '+up.Status__c); 
			}catch (Exception ex){
				up.Status__c = 'Error';
			    up.Error_Message__c = ex.getMessage();
			    System.debug('********** MassTaskEMailBatch --> E-Mail Exception: '+up.Error_Message__c); 
			}
			
			updates.add(up);                             
	   }
	   
	   if(!updates.isEmpty()){
			update updates;
	   }
    }
    
    /*
     * When the Job is finished, notify Job owner/creator
     */
    global void finish(Database.BatchableContext ctx){        
        // Job wrapup related work
    }
}