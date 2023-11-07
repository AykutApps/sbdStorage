public class MTD_CompareModels {
    /*  Grid Model for comparing 3 things
     */

    //inner classes
    public class Membership {
        public Id parentId { get; set; }
        public boolean includesBase { get; set; } //Is the base entity a member of the parent?
        public boolean includesOther { get; set; } //Is the first comparison-entity a member of the parent?
        public boolean includesAnother { get; set; } //Is the second comparison-entity a member of the parent?

        public Membership() {
            throw new MTDException('Default Constructor is not supported.');
        }
        public Membership(Id parentId) {
            init();
            if (parentId == null) {
                throw new MTDException('You must pass a valid SF Id into the constructor.');
            } else {
                this.parentId = parentId;
            }
        }

        private void init() {
            this.includesBase = false;
            this.includesOther = false;
            this.includesAnother = false;
        }
    }

    public class GridRow {
        //public boolean displayApi       { get; set; } //ToFuture: should this be moved to a grid-manager class?
        public boolean isSFId { get; set; } //is this row display an SF Id?
        public integer sortOrder { get; set; }

        public string parentType { get; set; }
        public string parentLabel { get; set; }
        public string parentApi { get; set; }

        public string metaType { get; set; }
        public string metaLabel { get; set; }
        public string metaApi { get; set; }

        public string baseVal { get; set; } //value or label; depends on the metaType
        public string baseApi { get; set; }

        public string otherVal { get; set; } //value or label; depends on the metaType
        public string otherApi { get; set; }

        public string anotherVal { get; set; } //value or label; depends on the metaType
        public string anotherApi { get; set; }

        public GridRow() {
            throw new MTDException('Default Constructor is not supported.');
        }
        public GridRow(integer sortOrder, string parentType, string parentLabel, string parentApi, string metaType, string metaLabel, string metaApi) {
            init();
            this.sortOrder = sortOrder;
            this.parentType = parentType; // Ex. SObject
            this.parentLabel = parentLabel; // Ex. Registration
            this.parentApi = parentApi; // Ex. Asset_Owernship__c
            this.metaType = metaType; // Ex. Field
            this.metaLabel = metaLabel; // Ex. Serial Number
            this.metaApi = metaApi; // Ex. SerialNumber
        }

        //public getters & setters
        public string getBaseValue() {
            string out = (baseVal == null) ? '' : baseVal.trim();
            //if(displayApi || String.isBlank(baseVal)){
            if (String.isBlank(baseVal)) {
                out = this.baseApi;
            }
            return out;
        }
        public string getOtherValue() {
            string out = (otherVal == null) ? '' : otherVal.trim();
            //if(displayApi || String.isBlank(otherVal)){
            if (String.isBlank(otherVal)) {
                out = this.otherApi;
            }
            return out;
        }
        public string getOtherAnalysis() {
            String out = '';
            //trim & make lower case
            String tmpBase = (getBaseValue() == null) ? '' : getBaseValue().trim().toLowerCase();
            String tmpOther = (getOtherValue() == null) ? '' : getOtherValue().trim().toLowerCase();
            //compare
            if (tmpBase == tmpOther) {
                out = 'same';
            } else if (tmpBase != '' && tmpOther == '') {
                out = 'missing';
            } else if (tmpBase == '' && tmpOther != '') {
                out = 'extra';
            } else if (tmpBase != '' && tmpOther != '' && tmpBase != tmpOther) {
                out = 'different';
            }
            return out;
        }
        public string getAnotherValue() {
            string out = (anotherVal == null) ? '' : anotherVal.trim();
            //if(displayApi || String.isBlank(anotherVal)){
            if (String.isBlank(anotherVal)) {
                out = this.anotherApi;
            }
            return out;
        }
        public string getAnotherAnalysis() {
            String out = '';
            //trim & make lower case
            String tmpBase = (getBaseValue() == null) ? '' : getBaseValue().trim().toLowerCase();
            String tmpAnother = (getAnotherValue() == null) ? '' : getAnotherValue().trim().toLowerCase();
            //compare
            if (tmpBase == tmpAnother) {
                out = 'same';
            } else if (tmpBase != '' && tmpAnother == '') {
                out = 'missing';
            } else if (tmpBase == '' && tmpAnother != '') {
                out = 'extra';
            } else if (tmpBase != '' && tmpAnother != '' && tmpBase != tmpAnother) {
                out = 'different';
            }
            return out;
        }

        //public methods
        public void populateRow(String baseValOrLabel, String otherValOrLabel, String anotherValOrLabel) {
            this.baseVal = baseValOrLabel;
            this.otherVal = otherValOrLabel;
            this.anotherVal = anotherValOrLabel;
        }
        public void populateRowApis(String baseApi, String otherApi, String anotherApi) {
            this.baseApi = baseApi;
            this.otherApi = otherApi;
            this.anotherApi = anotherApi;
        }

        //private methods
        private void init() {
            //this.displayApi = false;
            this.isSFId = false;
            this.sortOrder = 99;
        }
    }
}
