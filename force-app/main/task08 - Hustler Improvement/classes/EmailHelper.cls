public class EmailHelper {
    private ID orgWideEmailID; //User or Organization Wide Email Address
    private string senderDisplayName; //string used when an ORG WIDE EMAIL ADDRESS is NOT provided
    private boolean saveAsActivity;
    private boolean useSignature;

    private Map<String, EmailTemplate> templateMapByApiName;

    public Integer maxEmails { get; private set; }
    public Integer emailsRequested { get; private set; }
    public Integer emailsAttempted { get; private set; }
    public Integer emailsSent { get; private set; }
    public Integer emailsFailed { get; private set; }
    public Integer emailsSkipped { get; private set; }

    //DEFAULT CONSTRUCTOR:  FROM Address & FROM LABEL is for the current user
    public EmailHelper() {
        init();
    }
    //CONSTRUCTOR:  sets a corporate FROM ADDRESS & FROM EMAIL (based on SF Configuration "Organization Wide Addresses")
    public EmailHelper(ID orgWideEmailID) {
        this();
        this.orgWideEmailID = orgWideEmailID;
    }
    //CONSTRUCTOR:  sets the FROM ADDRESS to the current user with a customized display name for the FROM
    public EmailHelper(String senderDisplayName) {
        this();
        this.senderDisplayName = senderDisplayName;
    }

    public Integer sendQueuedSingleEmail(Comm_Queue__c email) {
        List<Comm_Queue__c> n = new List<Comm_Queue__c>();
        n.add(email);
        return sendQueuedSingleEmails(n);
    }
    public Integer sendQueuedSingleEmails(List<Comm_Queue__c> emails) {
        List<Comm_Queue__c> upEmails = new List<Comm_Queue__c>();
        emailsRequested = (emails == null) ? 0 : emails.size();
        emailsAttempted = 0;
        emailsFailed = 0;
        emailsSent = 0;
        emailsSkipped = 0;
        //query WHO ID Data
        Set<ID> contactIDs = new Set<ID>();
        Set<ID> leadIDs = new Set<ID>();
        Set<ID> userIDs = new Set<ID>();
        for (Comm_Queue__c em : emails) {
            String who = (em.Who_ID__c != null) ? em.Who_ID__c.trim() : '';
            try {
                if (who.length() == 15 || who.length() == 18) {
                    if (who.substring(0, 3) == '003')
                        contactIDs.add(who);
                    if (who.substring(0, 3) == '001')
                        leadIDs.add(who);
                    if (who.substring(0, 3) == '005')
                        userIDs.add(who);
                }
            } catch (Exception ex) {
            } //okay; logic will record send email failure due to no SF record
        }
        Map<ID, Contact> contactMap = new Map<ID, Contact>([SELECT ID, Contact_Status__c, FirstName, LastName, Email FROM Contact WHERE ID IN :contactIDs]);
        Map<ID, Lead> leadMap = new Map<ID, Lead>([SELECT ID, Status, Name, Email FROM Lead WHERE ID IN :leadIDs]);
        Map<ID, User> userMap = new Map<ID, User>([SELECT ID, isActive, Name, FirstName, LastName, UserName, Email FROM User WHERE ID IN :userIDs]);
        //query SObject Fields related to the WHAT SOBJECT used as {!FieldMerges} in the templates and place in generic map (1 generic map per SObject)

        // ----------------
        //send single emails using Messaging.SingleEmailMessage (each email is customized to the user)
        // ----------------
        for (Comm_Queue__c em : emails) {
            system.debug('mtd-em-' + em);
            boolean skip = false;
            boolean emailSuccess = true;
            String emailSendStatusMsg = '';
            String emailfailedComment = '';
            //Grab SObject for WHO ID
            Contact whoCon;
            if (contactMap.containsKey(em.Who_ID__c)) {
                whoCon = contactMap.get(em.Who_ID__c);
            }

            //Grab SObject for WHO ID
            User whoUser;
            if (userMap.containsKey(em.Who_ID__c)) {
                whoUser = userMap.get(em.Who_ID__c);
            }
            //ToFuture: support lead
            //ToFuture: support user
            //Should email be sent?
            if (emailsAttempted >= maxEmails)
                break;
            //get WHO ID's preferred language
            String prefLang = 'English';
            // ----------------
            //get email content (favor subject & body if subject has a value)
            // ----------------
            String subject;
            String body;
            EmailTemplate sfTemplate;
            if (!String.isBlank(em.Subject__c)) {
                subject = (em.Subject__c == null) ? '' : em.Subject__c.trim();
                body = (em.Body__c == null) ? '' : em.Body__c.trim();
            } else {
                if (prefLang == 'English' && templateMapByApiName.containsKey(em.Comm_Template_FK__r.Template_API_Name_en_US__c)) {
                    sfTemplate = templateMapByApiName.get(em.Comm_Template_FK__r.Template_API_Name_en_US__c);
                }
                //validate sfTemplate
                if (sfTemplate == null) {
                    emailfailedComment += (emailfailedComment != '') ? ' | ' : '';
                    emailfailedComment += prefLang + ' version of the email template does not exist for ' + em.Comm_Template_FK__r.name;
                } else if (!sfTemplate.isActive) {
                    emailfailedComment += (emailfailedComment != '') ? ' | ' : '';
                    emailfailedComment += ' SF Template is not active: ' + em.Comm_Template_FK__r.Template_API_Name_en_US__c;
                }
            }
            // ----------------
            //prepare email
            // ----------------
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            //set mail properties
            if (sfTemplate != null) {
                mail.setTemplateId(sfTemplate.ID);
            } else {
                mail.setSubject(subject); //overriden by template
                mail.setPlainTextBody(body); //overriden by template
            }
            if (em.Who_SObject__c == 'User') {
                mail.setSaveAsActivity(false);
            } else {
                mail.setSaveAsActivity(saveAsActivity);
            }
            mail.setUseSignature((subject != null) ? true : false);
            //IMPORTANT: set org-wide-id -OR- display name (not both)
            if (orgWideEmailID != null) {
                mail.setOrgWideEmailAddressId(orgWideEmailID);
            } else if (!String.isBlank(senderDisplayName)) {
                mail.setSenderDisplayName(senderDisplayName);
            }
            // set WHO ID :: Who gets the email?
            ID whoID;
            try {
                whoID = em.Who_ID__c;
                mail.setTargetObjectId(whoID);
            } catch (Exception e) {
                emailfailedComment += (emailfailedComment != '') ? ' | ' : '';
                emailfailedComment += 'Could not assign WHO ID for ' + em.Who_SObject__c + ' ' + em.Who_ID__c + '/' + em.Who_Name__c;
            }
            // set WHAT ID :: What record is the email linked to?  (cannot be user, lead or contact)
            ID whatID;
            try {
                whatID = em.What_ID__c;
                if (whatID != null)
                    mail.setWhatId(whatID);
            } catch (Exception e) {
                emailfailedComment += (emailfailedComment != '') ? ' | ' : '';
                emailfailedComment += 'Could not assign WHAT ID for ' + em.What_SObject__c + ' ' + em.What_ID__c + '/' + em.What_Name__c;
            }
            // ----------------
            // send Email
            // ----------------
            boolean delaySend = (em.Delay_Until__c != null && em.Delay_Until__c < Datetime.now()) ? true : false;
            if (emailfailedComment != null && emailfailedComment.trim() != '') {
                emailSuccess = false;
            } else if (em.Status__c == 'Pending' && !delaySend) {
                System.debug('mtd-eMail-' + mail);
                emailsAttempted++;
                List<Messaging.SendEmailResult> results = new List<Messaging.SendEmailResult>();
                if (!Test.isRunningTest()) {
                    try {
                        results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
                        System.debug('mtd-eMail Results-' + results);
                        if (results.size() > 0) {
                            if (!results.get(0).isSuccess()) {
                                emailSendStatusMsg += 'EMAIL FAILED: ' + results.get(0).getErrors()[0].getMessage();
                                System.debug('mtd-eMail Send Failed-emailSendStatusMsg-' + emailSendStatusMsg);
                                emailSuccess = false;
                                emailFailedComment = emailSendStatusMsg;
                            } else {
                                System.debug('***************Email Send***************');
                                emailSendStatusMsg += 'mtd-eMail Sent-SendEmailResult.isSuccess equals TRUE';
                                System.debug('mtd-eMail Succeeded-' + emailSendStatusMsg);
                                emailSuccess = true;
                            }
                        }
                    } catch (EmailException eEmail) {
                        System.debug('**********EMAIL EXCEPTION**********' + eEmail);
                        emailSendStatusMsg += 'EMAIL EXCEPTION: ' + eEmail.getMessage();
                        System.debug('mtd-eMail Exception-' + emailSendStatusMsg);
                        emailSuccess = false;
                        emailFailedComment = emailSendStatusMsg;
                    } catch (Exception e) {
                        System.debug('**********GENERAL EXCEPTION**********' + e);
                        emailSendStatusMsg += 'GENERAL EXCEPTION: ' + e.getMessage();
                        System.debug('mtd-General Exception-' + emailSendStatusMsg);
                        emailSuccess = false;
                        emailFailedComment = emailSendStatusMsg;
                    }
                } //end not running test
            } else {
                skip = true;
            }
            System.debug('mtd-eMail after sending-' + mail);
            //update Comm_Queue__c record
            Comm_Queue__c up = new Comm_Queue__c(id = em.id);
            up.From_ID__c = (orgWideEmailID != null) ? orgWideEmailID : null;
            up.From_Corporate_Email__c = (orgWideEmailID != null) ? true : false;
            if (skip) {
                emailsSkipped++;
            } else if (emailSuccess) {
                emailsSent++;
                up.Status__c = 'Sent';
                up.Sent__c = Datetime.now();
                if (sfTemplate != null) {
                    up.Template_Used_ID__c = sfTemplate.ID;
                    up.Template_Used_Name__c = sfTemplate.DeveloperName;
                }
                up.Comment__c = (emailSendStatusMsg == null) ? '' : emailSendStatusMsg.left(255);
                up.Error_Code__c = null;
                up.Error_Message__c = null;
                if (whoCon != null) {
                    up.Who_Name__c = whoCon.FirstName + ' ' + whoCon.LastName;
                    up.Who_Email__c = whoCon.email; //only record on successful send
                }

                if (whoUser != null) {
                    up.Who_Name__c = whoUser.FirstName + ' ' + whoUser.LastName;
                    up.Who_Email__c = whoUser.email; //only record on successful send
                }
            } else {
                emailsFailed++;
                up.Status__c = 'Error';
                up.Sent__c = null;
                up.Template_Used_ID__c = null;
                up.Comment__c = null;
                up.Error_Code__c = 'ERR';
                up.Error_Message__c = (emailFailedComment == null) ? '' : emailFailedComment.left(750);
            }
            upEmails.add(up);
            //housekeeping
        } // end for - send single emails
        //update email status
        if (upEmails.size() > 0)
            update upEmails;
        return emailsFailed;
    }

    public boolean sendSingleEmail(string subject, string body, id whoId) {
        boolean successFlag = false;
        //whoID should be a lead-00Q, contact-003 or user-005
        if (IDHelper.isValid(whoId, '00Q') || IDHelper.isValid(whoId, '003') || IDHelper.isValid(whoId, '005')) {
            Messaging.SingleEmailMessage e = new Messaging.SingleEmailMessage();
            e.setTargetObjectId(whoId);
            if (!IDHelper.isValid(whoId, '005')) {
                //setSaveAsActivity is not allowed when emailing SF User records
                e.setSaveAsActivity(true);
            }
            subject = (subject == null) ? '' : subject.trim();
            if (!String.isBlank(subject)) {
                e.setSubject(subject);
            }
            if (body != null && body != '') {
                e.setPlainTextBody(body);
            }
            senderDisplayName = (senderDisplayName == null) ? '' : subject.trim();
            if (orgWideEmailID != null) {
                e.setOrgWideEmailAddressId(orgWideEmailID); //orgWideEmailID
            } else if (!String.isBlank(senderDisplayName)) {
                e.setSenderDisplayName(senderDisplayName);
            } else {
                throw new mtdexception('You cannot use the default constructor when calling EmailHelper.sendSingleEmail');
            }

            List<Messaging.SingleEmailMessage> toSend = new List<Messaging.SingleEmailMessage>();
            toSend.add(e);

            if (test.isRunningTest()) {
                return true;
            } else if (successFlag) {
                try {
                    Messaging.sendEmail(toSend);
                    successFlag = true;
                } catch (DmlException ex) {
                    throw new mtdexception('The following error has occured: ' + ex.getMessage());
                }
            }
        } else {
            throw new mtdexception('Invalid To ID');
        }
        return successFlag;
    }

    //--------------------
    //private methods
    //--------------------
    private void init() {
        templateMapByApiName = EmailTemplateHelper.fetchEmailTemplatesByApiName();
        senderDisplayName = 'MTD Products, inc.';
        emailsRequested = 0;
        emailsAttempted = 0;
        emailsFailed = 0;
        emailsSent = 0;
        emailsSkipped = 0;
        maxEmails = 0;
        calcMaxEmails();
        saveAsActivity = true;
        useSignature = true;
    }
    private void calcMaxEmails() {
        maxEmails = 5; //maximum calls to any SF "Send Email" method is 5 per context
    }
    //--------------------
    //public static methods
    //--------------------
    public static string fixEmail(string inEmail) {
        string out = '';

        if (String.isBlank(inEmail)) {
            return out;
        }

        if (inEmail.length() <= 5) {
            return inEmail;
        }

        out = inEmail.trim();

        // Replace any comma with a period
        out = out.replace(',', '.');
        // Replace double characters with singles
        out = out.replace('..', '.');
        out = out.replace('@@', '@');
        out = out.replace('--', '-');

        //Sundog test originating from InteractionHelpers.cleanInvalidEmails
        if (out.startsWith('.')) {
            out = out.removeStart('.');
        }

        Pattern p = Pattern.compile('([a-zA-Z0-9_\\-\\.]+)@(((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3}))');
        Matcher m = p.matcher(out);
        if (m.matches()) {
            return out;
        }

        // Create the pattern to validate characters around the @
        // Allow lowercase a-z, uppercase A-Z and 0-9
        p = Pattern.compile('([a-zA-Z0-9])');

        // Validate the 1 character PRIOR TO the @
        integer charPos = out.indexOf('@') - 1;
        if (charPos <= 0) {
            return out;
        } else if (charPos > out.length() - 1) {
            return out;
        }
        string character = out.substring(charPos, charPos + 1);
        m = p.matcher(character);
        if (!m.matches()) {
            // Remove the bad character prior to the @
            character = character + '@';
            out = out.replace(character, '@');
        }
        // Validate the 1 character AFTER the @
        charPos = out.indexOf('@') + 1;
        if (charPos <= 0) {
            return out;
        } else if (charPos > out.length() - 1) {
            return out;
        }
        character = out.substring(charPos, charPos + 1);
        m = p.matcher(character);
        if (!m.matches()) {
            // Remove the bad character after the @
            character = '@' + character;
            out = out.replace(character, '@');
        }
        // Return the newly formatted email
        return out;
    }

    /*
    ----------------------------------------
    Execute Anonymous Test Script
    ----------------------------------------
    List<Comm_Queue__c> emails = [SELECT Id, Name, Status__c, Type__c, Delay_Until__c
                                        , What_ID__c, What_Link__c, What_Name__c, What_SObject__c
                                        , Who_Email__c, Who_ID__c, Who_Link__c, Who_Name__c, Who_SObject__c
                                        , Subject__c, Body__c
                                        , Comm_Template_FK__c, Comm_Template_FK__r.Template_API_Name_de__c, Comm_Template_FK__r.Template_API_Name_en_US__c, Comm_Template_FK__r.Template_API_Name_es__c, Comm_Template_FK__r.Template_API_Name_fr__c
                                        , Template_Used_ID__c, Template_Used_Link__c, Template_Used_Name__c
                                        , Comm_Template_FK__r.Name                                        
                                        FROM Comm_Queue__c
                                        WHERE id = 'a1h4B0000009Su8' and what_id__c = null
                                        //WHERE Status__c = 'Pending'
                                        ORDER BY Comm_Template_FK__r.Priority__c, CreatedDate
                                        ];
    ID orgWideID = '0D24B00000000er';  
    String senderDisplayName = 'MTD Support';

//    EmailHelper h = new emailhelper(senderDisplayName);
    EmailHelper h = new emailhelper(orgWideID);
    system.debug(h.sendQueuedSingleEmails(emails));

    system.debug('mtd-max emails-'+h.maxEmails);
    system.debug('mtd-requested-'+h.emailsRequested);
    system.debug('mtd-attempted-'+h.emailsAttempted);
    system.debug('mtd-sent-'+h.emailsSent);
    system.debug('mtd-failed-'+h.emailsFailed);
    system.debug('mtd-skipped-'+h.emailsSkipped);
    ---------------------------------------- 
*/
}
