import { LightningElement,track,api } from 'lwc';
import contextApi from 'commerce/contextApi';
import getAccountDetails from '@salesforce/apex/B2B_AccountController.getAccountDetails';
import { NavigationMixin } from "lightning/navigation";
import PartsmartLink2 from '@salesforce/label/c.B2B_PartSmartLink';
import DocumotoLink from '@salesforce/label/c.B2B_DocumotoLink';
import communityId from '@salesforce/community/Id';
import productSearch from '@salesforce/apex/B2B_PLPController.productSearch';
import basePath from '@salesforce/community/basePath';
export default class B2B_ButtonsFromAccount extends NavigationMixin(LightningElement) {
    @track showSpinner = false;
    effectiveAccountId;
    @track accountDetails;
    _recordId;
    isParts = false;
    categoryId;
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.getCurrentCategory();
    }

    connectedCallback(){
        this.showSpinner = true
        const result = contextApi.getSessionContext();
        result.then((response) => {
            this.effectiveAccountId = response.effectiveAccountId;

            this.getCurrentCategory();
            this.getAccountDetails(this.effectiveAccountId);
            this.showSpinner = false
        }).catch((error) => {
            this.showSpinner = false
            console.log(error);
        });
    }
    getCurrentCategory(){
        if(this.effectiveAccountId != null){
            const searchQuery = JSON.stringify({
                searchTerm: null,
                categoryId: this.recordId,
            });debugger;
            productSearch({
                communityId: communityId,
                searchQuery: searchQuery,
                effectiveAccountId: this.effectiveAccountId
            })
                .then((result) => {debugger;
                    this.displayData = result;
                    if(result.categories && result.categories.category && result.categories.category.name == 'Parts'){
                        this.isParts = true;
                    }else{
                        this.isParts = false;
                    }
                })
                .catch((error) => {
                    this.error = error;
                    this.showSpinner = false;
                    console.log(error);
                });  
        }
      
    }
    getAccountDetails(accId){
        this.showSpinner = true
        let dataMap = {
            "effectiveAccountId":accId,
        };
        getAccountDetails({
            'dataMap' : dataMap,
        }).then((result)=>{
            console.log('B2B_result')
            console.log(result)
            this.accountDetails = result.account; 
        }).catch((error)=>{
            this.showSpinner = false
            const errorMessage = error.body.message;
            console.log('Error in fecthcing cart items: getAccountDetails' +errorMessage);
            console.log(error);
        }); 
    }
    handleCubRedirect(event) {
        console.log('Partsmart redirect');
        console.log(PartsmartLink2);
        this.redirectHandler(PartsmartLink2);
    }
    handleHustlerRedirect(event) {
        console.log('XXX - handleHustlerRedirect');
        let documotoLinkRefined;
        if (this.accountDetails.Hustler_Parts_Account__c) {
            documotoLinkRefined = DocumotoLink.replace("<WGAccountNumber>", this.accountDetails.Hustler_WG_Account__c)
                .replace("<PartAccountNumber>", this.accountDetails.Hustler_Parts_Account__c)
                .replace("<DealerDomainName>", "hustlerturf");
        } else if (this.accountDetails.BigDog_Parts_Account__c) {
            documotoLinkRefined = DocumotoLink.replace("<WGAccountNumber>", this.accountDetails.BigDog_WG_Account__c)
                .replace("<PartAccountNumber>", this.accountDetails.BigDog_Parts_Account__c)
                .replace("<DealerDomainName>", "bigdogmowers");
        }

        console.log('documotoLinkRefined');
        console.log(documotoLinkRefined);

        if (documotoLinkRefined) {
            this.redirectHandler(documotoLinkRefined);
        } else {
            alert("Error: Your account is missing a Hustler or BigDog Mower Co. Part Number!");
        }
    }
    handleMultiLinePartsRedirect(event){
        var url = basePath+'/quick-order'
        this.redirectHandler(url);
    }
    redirectHandler(link){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: link
            }
        }).then((url) => {
            window.open(url, '_blank');
        });
    }
}