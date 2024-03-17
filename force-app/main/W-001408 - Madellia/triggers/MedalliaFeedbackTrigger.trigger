trigger MedalliaFeedbackTrigger on medallia_xm__Medallia_Feedback__c(after insert, after update) {
    /*  If an invitation request is sent to Medallia via the appexchange package, medallia will 
    invite the individual to complete a survey (opt out & quarantine logic is applied by Medallia)
    If the individual completes the survey, Medallia creates a record in this response table:  medallia-feedback

    The trigger belows converts CSC Report Card/NPS response to 2 SObjects established in Summer 2017:
    - ReportCard__c
    - Survey_Reponse__c
*/
    set<id> setCaseId = new Set<id>();
    List<ReportCard__c> lstInsReportCard = new List<ReportCard__c>();
    List<ReportCard__c> lstUpdReportCard = new List<ReportCard__c>();
    List<SurveyResponse__c> lstSurveyRes = new List<SurveyResponse__c>();
    List<Contact> lstUpdContact = new List<Contact>();
    List<Case> lstUpdCase = new List<Case>();

    for (medallia_xm__Medallia_Feedback__c mf : Trigger.new) {
        medallia_xm__Medallia_Feedback__c old;
        if (Trigger.isUpdate && Trigger.isAfter) {
            old = Trigger.oldMap.get(mf.Id);
        }

        //gateway logic
        if (
            Trigger.isInsert ||
            (old != null &&
            (mf.medallia_xm__Response_Main_score__c <> old.medallia_xm__Response_Main_score__c ||
            mf.Digital_CSAT_Score__c <> old.Digital_CSAT_Score__c ||
            mf.NPS_Other_Reason__c <> old.NPS_Other_Reason__c ||
            mf.Knowledgeable_customer_service__c <> old.Knowledgeable_customer_service__c ||
            mf.Courteous_customer_service__c <> old.Courteous_customer_service__c ||
            mf.Customer_service_provide_timely_answer__c <> old.Customer_service_provide_timely_answer__c ||
            mf.First_time_contact_about_this__c <> old.First_time_contact_about_this__c ||
            mf.How_can_we_improve_in_the_future__c <> old.How_can_we_improve_in_the_future__c ||
            mf.Digital_Issue_Resolved_Yes_No__c <> old.Digital_Issue_Resolved_Yes_No__c ||
            mf.Digital_Unresolved_Comment__c <> old.Digital_Unresolved_Comment__c))
        ) {
            if (mf.Case__c != null && string.isNotEmpty(mf.Case__c)) {
                setCaseId.add(mf.Case__c);
            } else if (mf.medallia_xm__Original_case_Number__c != null) {
                setCaseId.add(mf.medallia_xm__Original_case_Number__c);
            }
        }
    }

    if (setCaseId != null && setCaseId.size() > 0) {
        map<Id, List<ReportCard__c>> mapCaseIdToRepCard = new Map<Id, List<ReportCard__c>>();
        map<Id, List<SurveyResponse__c>> mapCaseIdToSR = new Map<Id, List<SurveyResponse__c>>();
        map<string, Case> mapIdToCase = new Map<string, Case>();
        map<Id, medallia_xm__Medallia_Feedback__c> mapIdToMF = new Map<Id, medallia_xm__Medallia_Feedback__c>();

        for (Case objCase : [
            SELECT Id, AccountId, ContactEmail, ContactId, OwnerId, CaseNumber, Manager__c, Manager__r.Email, RecordType.Name, Origin
            FROM Case
            WHERE Id IN :setCaseId
        ]) {
            mapIdToCase.put(objCase.Id, objCase);
        }

        List<medallia_xm__Medallia_Feedback__c> lstMF = [
            SELECT Id, Case__c, medallia_xm__Feedback_Program__r.medallia_xm__Medallia_Id__c
            FROM medallia_xm__Medallia_Feedback__c
            WHERE Id IN :Trigger.new
        ];
        for (medallia_xm__Medallia_Feedback__c objMF : lstMF) {
            mapIdToMF.put(objMF.Id, objMF);
        }

        for (ReportCard__c objRC : [
            SELECT
                Id,
                Case__c,
                Advocacy__c,
                Likely_recommend_to_friend_or_colleague__c,
                Reason_recommend_not_recommend__c,
                NPS_Other_Reason__c,
                Knowledgeable_customer_service__c,
                Courteous_customer_service__c,
                Customer_service_provide_timely_answer__c,
                First_time_contact_about_this__c
            FROM ReportCard__c
            WHERE Case__c IN :setCaseId
        ]) {
            if (mapCaseIdToRepCard.get(objRC.Case__c) == null) {
                mapCaseIdToRepCard.put(objRC.Case__c, new List<ReportCard__c>());
            }
            mapCaseIdToRepCard.get(objRC.Case__c).add(objRC);
        }

        for (SurveyResponse__c objS : [
            SELECT
                Id,
                Case__c,
                Advocacy__c,
                Unresolved_Comment__c,
                Issue_Resolved_Picklist__c,
                How_can_we_improve_in_the_future__c,
                First_time_contact_about_this__c,
                Customer_service_provide_timely_answer__c,
                Courteous_customer_service__c,
                Knowledgeable_customer_service__c,
                NPS_Other_Reason__c,
                Reason_recommend_not_recommend__c,
                Likely_recommend_to_friend_or_colleague__c
            FROM SurveyResponse__c
            WHERE Case__c IN :setCaseId
        ]) {
            if (mapCaseIdToSR.get(objS.Case__c) == null) {
                mapCaseIdToSR.put(objS.Case__c, new List<SurveyResponse__c>());
            }
            mapCaseIdToSR.get(objS.Case__c).add(objS);
        }

        for (medallia_xm__Medallia_Feedback__c mf : Trigger.new) {
            string strCaseId = '';
            if (mf.Case__c != null) {
                strCaseId = mf.Case__c;
            } else {
                strCaseId = mf.medallia_xm__Original_case_Number__c;
            }

            if (mf.Case__c != null || mf.medallia_xm__Original_case_Number__c != null) {
                ReportCard__c objConUpdateReportCard;

                //Repeated Code.
                //Digital_CSAT_Score__c 0 to 10 - MJ
                //medallia_xm__Response_Main_score__c 0 to 10 - MJ
                Decimal dcAdvocacy; //As per MJ, default should be null not zero because choose value 0 - 10.
                string strLikelyRecommend = '';
                if (mf.Digital_CSAT_Score__c >= 0) {
                    dcAdvocacy = mf.Digital_CSAT_Score__c;
                    strLikelyRecommend = string.valueOf(Integer.valueOf(dcAdvocacy));
                } else {
                    dcAdvocacy = mf.medallia_xm__Response_Main_score__c; // no change -  2023-07-03.
                    strLikelyRecommend = string.valueOf(Integer.valueOf(mf.medallia_xm__Response_Main_score__c));
                }

                List<ReportCard__c> lstRC = mapCaseIdToRepCard.get(mf.Case__c);
                if (lstRC != null && lstRC.size() > 0) {
                    for (ReportCard__c objRC : lstRC) {
                        //objR.Advocacy__c = mf.medallia_xm__Response_Main_score__c;
                        if (mf.Digital_CSAT_Score__c >= 0) {
                            //Check Overall_Satisfaction__c is changed or not
                            if (objRC.Advocacy__c != mf.Digital_CSAT_Score__c) {
                                //update contact Latest_Survey__c field value
                                objConUpdateReportCard = objRC;
                            }
                        } else {
                            //Check Overall_Satisfaction__c is changed or not
                            if (objRC.Advocacy__c != mf.medallia_xm__Response_Main_score__c) {
                                //update contact Latest_Survey__c field value
                                objConUpdateReportCard = objRC;
                            }
                        }

                        objRC.Advocacy__c = dcAdvocacy;
                        objRC.Likely_recommend_to_friend_or_colleague__c = strLikelyRecommend;
                        if (string.isNotBlank(mf.medallia_xm__Response_Main_score_comment__c)) {
                            string strReason = mf.medallia_xm__Response_Main_score_comment__c;
                            if (strReason.contains(',')) {
                                strReason = strReason.replaceAll(',', ';');
                            }
                            strReason = strReason.replace('[', '');
                            strReason = strReason.replace(']', '');
                            if (!(mf.Digital_CSAT_Score__c >= 0)) {
                                //mburr.2023-07-11 do not set for digital per Sam
                                objRC.Reason_recommend_not_recommend__c = strReason;
                            }
                        }

                        objRC.NPS_Other_Reason__c = mf.NPS_Other_Reason__c;
                        //2023-06-26 Medallia provides True or False or Null, so pass through those values per Sudhir.
                        if (mf.Knowledgeable_customer_service__c != null) {
                            objRC.Knowledgeable_customer_service__c = mf.Knowledgeable_customer_service__c;
                        }

                        //2023-06-26 Medallia provides True or False or Null, so pass through those values per Sudhir.
                        if (mf.Courteous_customer_service__c != null) {
                            objRC.Courteous_customer_service__c = mf.Courteous_customer_service__c;
                        }

                        //2023-06-26 Medallia provides True or False or Null, so pass through those values per Sudhir.
                        if (mf.Customer_service_provide_timely_answer__c != null) {
                            objRC.Customer_service_provide_timely_answer__c = mf.Customer_service_provide_timely_answer__c;
                        }

                        /*
                        if(mf.First_time_contact_about_this__c == 'True'){
                            objRC.First_time_contact_about_this__c ='TRUE';
                        }
                        else{
                            objRC.First_time_contact_about_this__c = 'FALSE';
                        }*/

                        objRC.Issue_Resolved_Picklist__c = mf.Digital_Issue_Resolved_Yes_No__c;
                        objRC.Unresolved_Comment__c = mf.Digital_Unresolved_Comment__c;
                        objRC.Comments__c = mf.Digital_Unresolved_Comment__c;
                        objRC.Medallia_Internal_Record_Id__c = mf.medallia_xm__Record_Medallia_Id__c;
                        objRC.Medallia_Feedback__c = mf.Id;

                        lstUpdReportCard.add(objRC);
                    }
                } else {
                    Id clinicRecordTypeId = Schema.SObjectType.ReportCard__c.getRecordTypeInfosByName().get('Support').getRecordTypeId();
                    // Create Report Card record
                    ReportCard__c objRC = new ReportCard__c();
                    objRC.Account__c = mapIdToCase.get(strCaseId).AccountId; //from case
                    objRC.Case__c = strCaseId;
                    objRC.Case_Owner__c = mapIdToCase.get(strCaseId).OwnerId; //from case
                    objRC.Contact_Email_Address__c = mapIdToCase.get(strCaseId).ContactEmail; // from case
                    objRC.Contact__c = mapIdToCase.get(strCaseId).ContactId; //from case
                    objRC.RecordTypeId = clinicRecordTypeId;
                    objRC.Medallia_Internal_Record_Id__c = mf.medallia_xm__Record_Medallia_Id__c;
                    objRC.Medallia_Feedback__c = mf.Id;

                    if (mapIdToCase.get(strCaseId).Origin == 'Chat') {
                        // mburr.2023-06-29 ChatKey__c must have a value on Chat cases for roll-up summaries
                        objRC.ChatKey__c = 'Origin: Chat ' + strCaseId;
                    }

                    objRC.Advocacy__c = dcAdvocacy;
                    objRC.Likely_recommend_to_friend_or_colleague__c = strLikelyRecommend;

                    if (string.isNotBlank(mf.medallia_xm__Response_Main_score_comment__c)) {
                        string strReason = mf.medallia_xm__Response_Main_score_comment__c;
                        if (strReason.contains(',')) {
                            strReason = strReason.replaceAll(',', ';');
                        }
                        strReason = strReason.replace('[', '');
                        strReason = strReason.replace(']', '');
                        if (!(mf.Digital_CSAT_Score__c >= 0)) {
                            //mburr.2023-07-11 do not set for digital per Sam
                            objRC.Reason_recommend_not_recommend__c = strReason;
                        }
                    }

                    objRC.NPS_Other_Reason__c = mf.NPS_Other_Reason__c;

                    //2023-06-26 Medallia provides True or False or Null, so pass through those values per Sudhir.
                    if (mf.Knowledgeable_customer_service__c != null) {
                        objRC.Knowledgeable_customer_service__c = mf.Knowledgeable_customer_service__c;
                    }

                    //2023-06-26 Medallia provides True or False or Null, so pass through those values per Sudhir.
                    if (mf.Courteous_customer_service__c != null) {
                        objRC.Courteous_customer_service__c = mf.Courteous_customer_service__c;
                    }

                    //2023-06-26 Medallia provides True or False or Null, so pass through those values per Sudhir.
                    if (mf.Customer_service_provide_timely_answer__c != null) {
                        objRC.Customer_service_provide_timely_answer__c = mf.Customer_service_provide_timely_answer__c;
                    }

                    objRC.Issue_Resolved_Picklist__c = mf.Digital_Issue_Resolved_Yes_No__c;
                    objRC.Unresolved_Comment__c = mf.Digital_Unresolved_Comment__c;
                    objRC.Comments__c = mf.Digital_Unresolved_Comment__c;
                    objConUpdateReportCard = objRC;

                    lstInsReportCard.add(objRC);
                }

                //Code for Survey Response records
                List<SurveyResponse__c> lstSR = mapCaseIdToSR.get(mf.Case__c);
                system.debug('lstSR :: ' + lstSR);
                if (lstSR != null && lstSR.size() > 0) {
                    for (SurveyResponse__c objS : lstSR) {
                        objS.Advocacy__c = dcAdvocacy;
                        objS.Likely_recommend_to_friend_or_colleague__c = strLikelyRecommend;
                        objS.Reason_recommend_not_recommend__c = mf.medallia_xm__Response_Main_score_comment__c;
                        objS.NPS_Other_Reason__c = mf.NPS_Other_Reason__c;
                        objS.Medallia_Internal_Record_Id__c = mf.medallia_xm__Record_Medallia_Id__c;
                        objS.Medallia_Feedback__c = mf.Id;

                        //2023-06-26 Medallia provides True or False or Null, so pass through those values per Sudhir.
                        if (mf.Knowledgeable_customer_service__c != null) {
                            objS.Knowledgeable_customer_service__c = mf.Knowledgeable_customer_service__c;
                        }

                        //2023-06-26 Medallia provides True or False or Null, so pass through those values per Sudhir.
                        if (mf.Courteous_customer_service__c != null) {
                            objS.Courteous_customer_service__c = mf.Courteous_customer_service__c;
                        }

                        //2023-06-26 Medallia provides True or False or Null, so pass through those values per Sudhir.
                        if (mf.Customer_service_provide_timely_answer__c != null) {
                            objS.Customer_service_provide_timely_answer__c = mf.Customer_service_provide_timely_answer__c;
                        }
                        /*
                        if(mf.First_time_contact_about_this__c == 'True'){
                            objS.First_time_contact_about_this__c ='TRUE';
                        }
                        else{
                            objS.First_time_contact_about_this__c = 'FALSE';
                        }
                        */
                        objS.How_can_we_improve_in_the_future__c = mf.How_can_we_improve_in_the_future__c;
                        objS.Issue_Resolved_Picklist__c = mf.Digital_Issue_Resolved_Yes_No__c;
                        objS.Unresolved_Comment__c = mf.Digital_Unresolved_Comment__c;
                        //objS.OwnerId = mapIdToCase.get(strCaseId).OwnerId;  //from case

                        lstSurveyRes.add(objS);
                    }
                } else if (mapIdToCase.get(strCaseId).Origin == 'Chat' || mf.Time_to_respond_to_your_question__c > 0) {
                    //As per MJ, replaced Customer_service_provide_timely_answer__c field with Time_to_respond_to_your_question__c in IF conditions.
                    // Create SurveyResponse__c record
                    SurveyResponse__c objS = new SurveyResponse__c();
                    if (mapIdToCase.get(strCaseId).Origin == 'Chat') {
                        objS.Name = 'Chat Survey';
                    } else {
                        objS.Name = 'Emailed Survey';
                    }
                    //ToDo: Make sure the PHONE CALL GUID is not overwritten by this logic -- see Dinesh/MJ  See production record:  a3SA0000003wxLd
                    // Phone call guid - 015d5a5f-fc3b-4470-a960-9b2b6b93af9b

                    objS.Account__c = mapIdToCase.get(strCaseId).AccountId; //from case
                    objS.Case__c = strCaseId;

                    objS.Advocacy__c = dcAdvocacy;
                    system.debug('dcAdvocacy :: ' + dcAdvocacy);
                    system.debug('strLikelyRecommend :: ' + strLikelyRecommend);
                    objS.Likely_recommend_to_friend_or_colleague__c = strLikelyRecommend;
                    objS.Reason_recommend_not_recommend__c = mf.medallia_xm__Response_Main_score_comment__c;
                    objS.Medallia_Internal_Record_Id__c = mf.medallia_xm__Record_Medallia_Id__c;
                    objS.Medallia_Feedback__c = mf.Id;
                    objS.NPS_Other_Reason__c = mf.NPS_Other_Reason__c; //2023-07-11 mburr switched back to NPS_Other_Reason__c

                    //2023-06-26 Medallia provides True or False or Null, so pass through those values per Sudhir.
                    if (mf.Knowledgeable_customer_service__c != null) {
                        objS.Knowledgeable_customer_service__c = mf.Knowledgeable_customer_service__c;
                    }

                    //2023-06-26 Medallia provides True or False or Null, so pass through those values per Sudhir.
                    if (mf.Courteous_customer_service__c != null) {
                        objS.Courteous_customer_service__c = mf.Courteous_customer_service__c;
                    }

                    //2023-06-26 Medallia provides True or False or Null, so pass through those values per Sudhir.
                    if (mf.Customer_service_provide_timely_answer__c != null) {
                        objS.Customer_service_provide_timely_answer__c = mf.Customer_service_provide_timely_answer__c;
                    }
                    /*
                    if(mf.First_time_contact_about_this__c == 'True'){
                        objS.First_time_contact_about_this__c ='TRUE';
                    }
                    else{
                        objS.First_time_contact_about_this__c = 'FALSE';
                    }
                    */
                    objS.How_can_we_improve_in_the_future__c = mf.How_can_we_improve_in_the_future__c;
                    objS.Issue_Resolved_Picklist__c = mf.Digital_Issue_Resolved_Yes_No__c;
                    objS.Unresolved_Comment__c = mf.Digital_Unresolved_Comment__c;

                    //Case field mapping
                    objS.Case_Number__c = mapIdToCase.get(strCaseId).CaseNumber; //from case
                    objS.Contact__c = mapIdToCase.get(strCaseId).ContactId; //from case

                    //Process Builder - Survey Response Received  Condition 2.
                    string strCaseRecordType = mapIdToCase.get(strCaseId).RecordType.Name;
                    if (strCaseRecordType.contains('CSC') && mapIdToCase.get(strCaseId).Manager__c != null) {
                        objS.Manager_s_Email__c = mapIdToCase.get(strCaseId).Manager__r.Email;
                    }
                    objS.OwnerId = mapIdToCase.get(strCaseId).OwnerId; //from case

                    lstSurveyRes.add(objS);
                }

                //Code for Contact record update
                if (mf.Case__c != null && mapIdToCase.get(strCaseId).ContactId != null) {
                    Contact con = new Contact(Id = mapIdToCase.get(strCaseId).ContactId);
                    con.Last_Survey_Completed_Date__c = system.Today();
                    con.Last_Survey_Completed__c = mapIdToMF.get(mf.Id).medallia_xm__Feedback_Program__r.medallia_xm__Medallia_Id__c; //Survey Name << from FEEDBACK PROGRAM:  medallia_xm__Medallia_Id__c

                    //update report card id //Replace Process Builder - Update Contact after Survey Submission Logic
                    if (objConUpdateReportCard != null) {
                        con.Latest_Survey__r = objConUpdateReportCard;
                    }
                    lstUpdContact.add(con);
                }

                //Process Builder - Survey Response Received  Condition 1.
                string strCaseRecordType = mapIdToCase.get(strCaseId).RecordType.Name;
                if (strCaseRecordType.contains('CSC')) {
                    Case objC = new Case(Id = strCaseId);
                    objC.Survey_Score__c = dcAdvocacy;
                    lstUpdCase.add(objC);
                }
            }
        }
    }

    if (!lstInsReportCard.isEmpty()) {
        insert lstInsReportCard;
    }

    if (!lstUpdReportCard.isEmpty()) {
        update lstUpdReportCard;
    }
    system.debug('lstSurveyRes :: ' + lstSurveyRes);
    if (!lstSurveyRes.isEmpty()) {
        upsert lstSurveyRes;
    }

    if (!lstUpdContact.isEmpty()) {
        for (Contact con : lstUpdContact) {
            con.Latest_Survey__c = con.Latest_Survey__r.Id;
        }
        update lstUpdContact;
    }
    /*
    //Need to add in Feedback //Future is possible, need to user Async Data Design pattern. 
       //if solve in 15 min, go head Otherwise it will enhancement next week. 
    if(!lstUpdCase.isEmpty()){
        update lstUpdCase;
    }
*/
}
