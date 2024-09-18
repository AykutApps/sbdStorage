public class B2B_ContentHelper {
    /*    The ContentHelper helps MTD Developers work with files stored on the Salesforce.com Content Platform.
        - helps find libraries
        - helps find files
        - grabs JSON from the most recent version of an SF Content File
        - helps creates new SF Content Files (txt, pdf, blob)
        - hides the complexity of updating SF Content Files (txt, pdf, blob)
        
        IMPORTANT: When you update an SF Content File, a new ContentVersion file is created.  The parent ContentDocument record stores
                   the SF Id for the most recent ContentVersion record.
        IMPORTANT: This class is meant to support any SF Content Library at MTD, not just "enFORCErs File Dump".  Please modify accordingly.
    
        //ToFuture: improve support for finding files using LIKE vs using an EXACT MATCH
    */
        public enum MTD_Library {FILEDUMP}
        static final String fileDumpLibrary = 'enFORCErs File Dump';
    
        public ID libraryID                 { get; private set; }
        public String libraryName           { get; private set; }
        public String libraryApi            { get; private set; }
    
        //---------------
        //constructors
        //---------------
        public ContentHelper(){
            this(MTD_Library.FILEDUMP);   //ToFuture: get default from constant/variable??
        }
        public ContentHelper(MTD_Library library){
            init();
            system.debug('xxx-library'+library);
            if(library == MTD_Library.FILEDUMP){
                system.debug('xxx-in if block for FILEDUMP library');
                this.libraryID = ContentHelper.fetchFileDumpLibrary().Id;
            }
            fetchLibraryInfo();
            system.debug('xxx-constructor libraryID-'+libraryID);
        }
    
        //---------------
        //Public Object Methods
        //---------------
        public ContentVersion fetchFile(String fileName){
            return ContentHelper.fetchFile(libraryId, fileName); //throws runtime if more than 1 file is found
        }
        public Map<String,ContentVersion> fetchFiles(String fileName, boolean exactFileNameMatch){
            return ContentHelper.fetchFiles(libraryId, fileName, exactFileNameMatch);
        }
        public String fetchSerializedSObjectsFromSFContent(String fileName){
            //returns body from SF Content Version which should be a JSON with serialized sObjects
            String out = fetchJSONFromSFContent(fileName);
            //ToFuture: validate that the string is a JSON of the SFDC Serialized SObject(s) format
            return out;
        }
        public String fetchJSONFromSFContent(String fileName){
            boolean exactFileNameMatch = true;
            return fetchJSONFromSFContent(fileName, exactFileNameMatch);
        }
        public String fetchJSONFromSFContent(String fileName, boolean exactFileNameMatch){
            //returns body from SF Content Version which should be a valid JSON
            String out = '';
            system.debug('xxx-libraryID-'+libraryID);
            if(libraryID == null){
                throw new SBX_ConfigException('Cannot fetch JSON from SF ContentVersion without a libraryId.');
            }
            fileName = (fileName == null) ? '' : fileName.trim();
            if(String.isBlank(fileName)){
                throw new SBX_ConfigException('Cannot fetch JSON from SF ContentVersion without a libraryId.');
            }
            //WORK
            ContentVersion v;
    system.debug('xxx-fetchJSONFromSFContent exactFileNameMatch-'+exactFileNameMatch);
            try{
                if(exactFileNameMatch){
                    v = fetchFile(fileName);
                } else {
                    Map<String,ContentVersion> cvs = fetchFiles(fileName, exactFileNameMatch);
                    if(cvs.size() > 0){
                        v = cvs.values()[0]; //ToFuture: support multiple matches based on fileName
                    }
                }
            } catch (Exception ex){ //v remains null
    //ToDo: system log ex; create an ExceptionHelper class that will format the exception data into a nice string
    system.debug('xxx-fetchJSONFromSFContent SOQL ex-'+ex);
            }
    system.debug('xxx-fetchJSONFromSFContent v-'+fileName);
    system.debug('xxx-fetchJSONFromSFContent v-'+v);
            if(v == null){
                throw new SBX_ConfigException('Cannot find file with ContentVersion.Title: '+ fileName);
            } else {
                v = ContentHelper.requeryContentVersion(v);
                Blob b = v.VersionData;
                out = b.toString(); //ToFuture: validate that the string is a valid JSON format
            }
            return out;
        }
        public ContentVersion newDocumentFactory_txt(String inContent, String inTitle, Boolean withDML){
            //ToFuture: validate inputs
            return newDocumentFactory(Blob.valueOf(inContent), inTitle, 'txt', withDML);
        }
        public ContentVersion newDocumentFactory_pdf(String inContent, String inTitle, Boolean withDML){
            //ToFuture: validate inputs
            return newDocumentFactory(Blob.valueOf(inContent), inTitle, 'pdf', withDML);
        }
        public ContentVersion newDocumentFactory(Blob inContent, String inTitle, String fileExtension, Boolean withDML){
            ContentVersion content = new ContentVersion();
            if(libraryID != null) content.FirstPublishLocationId = libraryID; //otherwise the doc will be private
            content.versionData = inContent;
            content.title = (inTitle == null || inTitle.trim() == '') ? 'TBD' : inTitle;
            content.pathOnClient = 'new.' + fileExtension;
            if(withDML == true) insert content;
            system.debug('xxx-content-'+content);
            return content;
        }
        public ContentVersion updateDocumentFactory_txt(ID contentDocID, String inContent, String inReason, Boolean withDML){
            if(inContent == null || inContent.trim() == '') inContent = '<empty>';
            String doNotChangeTitle = null;
            return updateDocumentFactory(contentDocID, Blob.valueOf(inContent), inReason,'txt', true);
        }
        public ContentVersion updateDocumentFactory_pdf(ID contentDocID, String inContent, String inReason, Boolean withDML){
            if(inContent == null || inContent.trim() == '') inContent = '<empty>';
            String doNotChangeTitle = null;
            return updateDocumentFactory(contentDocID, Blob.valueOf(inContent), inReason, 'pdf', true);//To future: extend the file extensions for remaining code.
        }
        public ContentVersion updateDocumentFactory(ID contentDocID, Blob inContent, String inReason, String fileExtension, Boolean withDML){
            ContentVersion content = new ContentVersion();
            content.versionData = inContent;
            Content.contentDocumentID = contentDocID;
            Content.reasonForChange = (inReason == null || inReason.trim() == '') ? 'n/a' : inReason;
            content.pathOnClient = 'update.' + fileExtension;
            if(withDML == true) insert content;
            return content;
        }
    
        //private Object Methods
        private void init(){
        }
        private void fetchLibraryInfo(){
            if(libraryId != null){
                ContentWorkspace lib;
                try{
                    lib = [SELECT Id, DeveloperName, Name FROM ContentWorkspace WHERE Id = :libraryId];
                } catch (Exception ex){} //lib remains null
                if(lib != null){
                    this.libraryName = lib.Name;
                    this.libraryApi = lib.DeveloperName;
                }
            }
        }
    
        //public static methods
        public static ContentWorkspace fetchFileDumpLibrary(){
            ContentWorkspace out;
            //SOQL QUERY ContentWorkspace Table TO FIND THE MTD_Library record & then set libraryID to its ID
            try{
                out = [SELECT Id FROM ContentWorkspace WHERE Name = :fileDumpLibrary ];
            } Catch (Exception ex){
                throw new MTDException('Could not locate SF Content Library called \'' + fileDumpLibrary + '\'');
            }
            return out;
        }
        public static ContentVersion fetchFile(Id libraryId, String fileName){
            ContentVersion out;
            boolean exactFileNameMatch = true;
            Map<String,ContentVersion> cvMap = ContentHelper.fetchFiles(libraryId, fileName, exactFileNameMatch);
            if(cvMap.size() > 1){
                throw new MTDException('More than 1 file found with file name ' + fileName + ' in SF Content Libary \'' + libraryId + '\'.' + ' Call fetchFiles(...) if you want to see all exact matches.');
            } else if(cvMap.size() == 1){
                out = cvMap.values()[0];
            }
            return out;
        }
        public static Map<String,ContentVersion> fetchFiles(Id libraryId, String fileName, boolean exactFileNameMatch){
            //fetches latest version of the file(s) for the current library    //ToFuture: what if file is in more than one library via ContentDocumentLink
            Map<String,ContentVersion> out = new Map<String,ContentVersion>(); //KEY: Title/FileName (no extension)  VALUE: Most Recent ContentVersion sObject
            String searchVal = (fileName == null) ? '' : fileName.trim();
            try{
                if(!String.isBlank(fileName)){
                    List<ContentVersion> cvs = new List<ContentVersion>();
                    if(exactFileNameMatch){
                        cvs = [    SELECT Id, Title, VersionData, FileType, FileExtension, ContentDocumentId, ContentDocument.LatestPublishedVersionId
                                FROM ContentVersion
                                WHERE ContentDocument.ParentId = :libraryId
                                  AND Title = :searchVal
                                ORDER BY ContentDocumentId
                              ];
                    } else { //like
                        searchVal = '%' + searchVal + '%';
                        cvs = [    SELECT Id, Title, VersionData, FileType, FileExtension, ContentDocumentId, ContentDocument.LatestPublishedVersionId
                                FROM ContentVersion
                                WHERE ContentDocument.ParentId = :libraryId
                                  AND Title LIKE :searchVal
                                LIMIT 100 //ToFuture: is limit 100 really the best answer for a LIKE/Wilcard search?
                                ];
                    }
                    //grab latest version
                    for(ContentVersion f : cvs){
                        if(f.Id == f.ContentDocument.LatestPublishedVersionId){
                            out.put(f.Title,f);
                        }
                    }
                }
            } catch (Exception ex){} //out remains empty
            if(out.size() == 0){
                throw new MTDException('No file(s) found with' + ((exactFileNameMatch) ? ' EXACT file name ' : ' file name LIKE ') + '\'' + fileName + '\' in SF Content Libary \'' + libraryId + '\'');
            }
            return out;
        }
        public static ContentVersion requeryContentVersion(ContentVersion inVersionSObject){
            ContentVersion out;
            try{
                out = [    SELECT Id, ContentDocumentId, FirstPublishLocationId, FileType, Title, VersionNumber , VersionData
                       , ContentSize, ContentUrl, CreatedById, CreatedDate, Description, Origin, OwnerId, PathOnClient
                       , PublishStatus, RatingCount, ReasonForChange
                       , ContentDocument.LatestPublishedVersionId
                       FROM ContentVersion
                       WHERE ID = :inVersionSObject.Id
                      ];
            } catch (Exception e){/*out remains null*/} //ToFuture: handle erros/exceptions
            return out;
        }
        public static List<ContentVersion> requeryContentVersions(List<ContentVersion> inVersionSObjects){
            List<ContentVersion> out = new List<ContentVersion>();
            Set<ID> versionIDs = new Set<ID>();
            for(ContentVersion v : inVersionSObjects)
                versionIDs.add(v.ID);
            try{
                out = [SELECT Id, ContentDocumentId, FirstPublishLocationId, FileType, Title, VersionNumber , VersionData
                       , ContentSize, ContentUrl, CreatedById, CreatedDate, Description, Origin, OwnerId, PathOnClient
                       , PublishStatus, RatingCount, ReasonForChange
                       , ContentDocument.LatestPublishedVersionId
                       FROM ContentVersion
                       WHERE ID in :versionIDs
                      ];
            } catch (Exception e){/*out remains null*/} //ToFuture: handle erros/exceptions
            return out;
        }
    
    }