trigger ProcessHelperEventTrigger on Process_Helper__e(after insert) {
    system.debug('ProcessHelperEventTrigger running');
    for (Process_Helper__e event : Trigger.New) {
        system.debug(event.Process_Type__c);
        system.debug(event.Process_Payload__c);
        if (event.Process_Type__c == 'WebCart') {
            String requestBody = event.Process_Payload__c;
            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf(requestBody);
            RestContext.request = req;

            DOS_WebcardRestServiceV2.Response2 response = DOS_WebcardRestServiceV2.handleProcessHelperRequest();
            system.debug('ProcessHelperEventTrigger response');
            system.debug(response);
        }
    }
}
