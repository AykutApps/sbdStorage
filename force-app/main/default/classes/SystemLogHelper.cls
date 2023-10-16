public without sharing class SystemLogHelper {
    /*  MTD uses SObject System_Log_Helper__c for loggin purposes.  Use this helper class to create log records.
    - 6 static helper methods
    - 3 variants
    - each variant has 2 signatures: 1 for a string dump (32,768 characters) & 1 for an Apex Exception dump
    
    Variant 1: synchronous  insert with DB Rollback+; uses DML insert
    Variant 2: asynchronous insert with DB Rollback;  uses DML insert with SFDC's @future notation
    Variant 3: asynchronous insert;  no DB Rollback;  disconnected from the SF Context; uses EventBus.publish(...)

    + SFDC's database the roll the insert back (a) if runtime error occurs or (b) if you rollback & inserted the log AFTER a DB savepoint

    DATE MODIFIED    AUTHOR              DESCRIPTION
     01/11/2018       Ben Kennedy         Added an @future method for async logging.
     03/26/2019       Craig Johnson       Added event logging methods to support System Log Platform event. 
     11/26/2021       Mike Burroughs      Added logSort as a sortable prefix to System_Log__c.Description__c.

    ----------------------------------
    EXECUTION SCRIPTS - 2 Synchronous Variants
    ----------------------------------
    String codeIdentifier = 'xxx';
    String description = 'xxx';
    String extendedInformation = '';
    System_Log__c log = SystemLogHelper.insertSystemLog(codeIdentifier, description, extendedInformation);

    //xxxCatchExceptionHerexxx
    //Exception ex = ; //you may need to assign your exception to the "ex" varable
    String codeIdentifier = 'xxx';
    String descriptionPrefix = 'xxx'; //prefixes the Apex Exception properties
    String extendedInformation = '';
    System_Log__c log = SystemLogHelper.insertSystemLog(codeIdentifier, description, ex);
    ----------------------------------
*/
    private static integer logSort = 0; // for log sorting; increments each time these methods are called: insertSystemLog(...) or insertSystemLogEvent(...)

    public static Boolean shouldInsert = true;

    public static System_Log__c insertSystemLog(String codeIdentifier, String descriptionPrefix, Exception ex) {
        //USE FROM EXECUTE ANONYMOUS ONLY
        String logItemSource = 'ExecAnon ' + fetchFormatedDatetime();
        String loggedInUser = UserInfo.getUserName();
        return insertSystemLog(logItemSource, codeIdentifier, loggedInUser, descriptionPrefix, ex);
    }
    public static System_Log__c insertSystemLog(String logItemSource, String codeIdentifier, String loggedInUser, String descriptionPrefix, Exception ex) {
        string description = descriptionPrefix + ': Line' + ('00000' + String.valueOf(ex.getLineNumber())).right(5) + ' ' + ex.getMessage();
        string extendedInformation = 'TYPE: ' + ex.getTypeName() + '  CAUSE: ' + ex.getCause() + '  STACKTRACE: ' + ex.getStackTraceString() + '  MESSAGE: ' + ex.getMessage();
        return insertSystemLog(logItemSource, codeIdentifier, loggedInUser, description, extendedInformation);
    }
    public static System_Log__c insertSystemLog(String codeIdentifier, String description, String extendedInformation) {
        //USE FROM EXECUTE ANONYMOUS ONLY
        String logItemSource = 'ExecAnon ' + fetchFormatedDatetime();
        String loggedInUser = UserInfo.getUserName();
        return insertSystemLog(logItemSource, codeIdentifier, loggedInUser, description, extendedInformation);
    }
    public static System_Log__c insertSystemLog(String logItemSource, String codeIdentifier, String loggedInUser, String description, String extendedInformation) {
        logSort++;
        description = String.valueOf(logSort).leftPad(2, '0') + ' ' + ((description == null) ? '' : description.trim());

        if (description != null && description.length() > 255) {
            description = description.substring(0, 255);
        }

        if (extendedInformation != null && extendedInformation.length() > 32768) {
            extendedInformation = extendedInformation.substring(0, 32768);
        }

        System_Log__c sysLog = new System_Log__c();
        sysLog.Name = logItemSource + ' : ' + codeIdentifier;
        sysLog.Code_Identifier__c = codeIdentifier;
        sysLog.Description__c = description;
        sysLog.Extended_Information__c = extendedInformation;
        sysLog.Log_Item_Source__c = logItemSource;
        sysLog.Logged_In_User__c = loggedInUser;
        //system.debug('xxx-SystemLogHelper.shouldInsert normal syslog BEFORE IF -'+SystemLogHelper.shouldInsert);
        if (shouldInsert) {
            //system.debug('xxx-SystemLogHelper.shouldInsert normal syslog IN IF -'+SystemLogHelper.shouldInsert);
            insert sysLog;
        }
        return sysLog;
    }

    public static System_Log_Event__e insertSystemLogEvent(String logItemSource, String codeIdentifier, String loggedInUser, String descriptionPrefix, Exception ex) {
        string description = descriptionPrefix + ': ' + ex.getLineNumber() + ' ' + ex.getMessage();
        string extendedInformation = ex.getTypeName() + ' ' + ex.getCause() + ' ' + ex.getStackTraceString();
        return insertSystemLogEvent(logItemSource, codeIdentifier, loggedInUser, description, extendedInformation);
    }

    public static System_Log_Event__e insertSystemLogEvent(String logItemSource, String codeIdentifier, String loggedInUser, String description, String extendedInformation) {
        logSort++;
        description = String.valueOf(logSort).leftPad(2, '0') + ' ' + ((description == null) ? '' : description.trim());

        if (description != null && description.length() > 255) {
            description = description.substring(0, 255);
        }

        if (extendedInformation != null && extendedInformation.length() > 32768) {
            extendedInformation = extendedInformation.substring(0, 32768);
        }

        System_Log_Event__e sysLog = new System_Log_Event__e();
        sysLog.Code_Identifier__c = codeIdentifier;
        sysLog.Description__c = description;
        sysLog.Extended_Information__c = extendedInformation;
        sysLog.Log_Item_Source__c = logItemSource;
        sysLog.Logged_In_User__c = loggedInUser;
        system.debug('xxx-SystemLogHelper.shouldInsert event syslog BEFORE IF -' + SystemLogHelper.shouldInsert);
        if (shouldInsert) {
            system.debug('xxx-SystemLogHelper.shouldInsert event syslog IN IF -' + SystemLogHelper.shouldInsert);
            EventBus.publish(sysLog);
        }
        return sysLog;
    }

    public static void insertSystemLogEvent(System_Log_Event__e systemLogEvent) {
        //ToFuture: change method name to publishSystemLogEvent(...)
        List<System_Log_Event__e> logs = new List<System_Log_Event__e>{ systemLogEvent };
        SystemLogHelper.insertSystemLogEvents(logs);
    }
    public static void insertSystemLogEvents(List<System_Log_Event__e> systemLogEvents) {
        //ToFuture: change method name to publishSystemLogEvents(...)
        //EventBus.publish(systemLogEvents); //mburr.2019-12-19 if more than 1, randomly threw "Duplicate id in list: e03xx0000000001AAA"
        for (System_Log_Event__e sle : systemLogEvents) {
            system.debug('xxx - sle:' + sle);
            EventBus.publish(sle);
        }
    }

    /**
     * This method creates a System_log__c record for the given inputs. Records are saved in the System_Log__c object.
     * @param String LogItemSource - This is the apex class, etc that is creating the log message
     * @param String CodeIdentifier - This is a unique string recorded with the log item that can be used to search
     *        the code for where the log item was generated from.
     * @param String LoggedInUser - This represents the user that was logged in when the log item was generated.
     * @param String description - description of the log item.
     * @param String ExtendedInformation - This is a large text container (32768 characters) that can be used to store any additional information (such
     *        as a stack trace or the value of variables at the time the log item was generated).
     * @return void
     **/
    public static void insertSystemLogFuture(String logItemSource, String codeIdentifier, String loggedInUser, String description, String extendedInformation) {
        logSort++;
        description = String.valueOf(logSort).leftPad(2, '0') + ' ' + ((description == null) ? '' : description.trim());

        if (description != null && description.length() > 255) {
            description = description.substring(0, 255);
        }

        if (extendedInformation != null && extendedInformation.length() > 32768) {
            extendedInformation = extendedInformation.substring(0, 32768);
        }

        System_Log__c sysLog = new System_Log__C();
        sysLog.Code_Identifier__c = codeIdentifier;
        sysLog.Description__c = description;
        sysLog.Extended_Information__c = extendedInformation;
        sysLog.Log_Item_Source__c = logItemSource;
        sysLog.Logged_In_User__c = loggedInUser;
        sysLog.name = logItemSource + ' : ' + codeIdentifier;
        if (shouldInsert) {
            Database.insert(sysLog, false);
        }
    }

    private static string fetchFormatedDatetime() {
        Datetime dt = Datetime.now();
        string out = DateUtilities.formatDateTimeToString(dt, 'yyyy-MM-dd');
        out += ' ' + DatetimeHelper.paddedTime(dt);
        return out;
    }
}
