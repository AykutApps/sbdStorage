import { LightningElement, track } from "lwc";
import contextApi from "commerce/contextApi";
import getAccountDetails from "@salesforce/apex/B2B_AccountController.getAccountDetails";
import { NavigationMixin } from "lightning/navigation";
import PartSmartLink from "@salesforce/label/c.B2B_PartSmartLink";
import DocumotoLink from "@salesforce/label/c.B2B_DocumotoLink";
export default class B2B_ButtonsFromAccount extends NavigationMixin(LightningElement) {
    @track showSpinner = false;
    effectiveAccountId;
    @track accountDetails;
    connectedCallback() {
        this.showSpinner = true;
        const result = contextApi.getSessionContext();
        result
            .then((response) => {
                this.effectiveAccountId = response.effectiveAccountId;
                this.getAccountDetails(this.effectiveAccountId);
                this.showSpinner = false;
            })
            .catch((error) => {
                this.showSpinner = false;
                console.log(error);
            });
    }

    getAccountDetails(accId) {
        this.showSpinner = true;
        let dataMap = {
            effectiveAccountId: accId
        };
        getAccountDetails({
            dataMap: dataMap
        })
            .then((result) => {
                console.log("B2B_result");
                console.log(result);
                this.accountDetails = result.account;
            })
            .catch((error) => {
                this.showSpinner = false;
                const errorMessage = error.body.message;
                console.log("Error in fecthcing cart items: getAccountDetails" + errorMessage);
                console.log(error);
            });
    }

    handleCubRedirect(event) {
        this.redirectHandler(PartSmartLink);
    }
    handleHustlerRedirect(event) {
        let documotoLinkRefined;
        if(this.accountDetails.Hustler_Parts_Account__c){
            documotoLinkRefined = DocumotoLink
            .replace("<WGAccountNumber>", this.accountDetails.Hustler_WG_Account__c)
            .replace("<PartAccountNumber>",this.accountDetails.Hustler_Parts_Account__c)
            .replace("<DealerDomainName>",'hustlerturf');
        } else if(this.accountDetails.BigDog_Parts_Account__c){
            documotoLinkRefined = DocumotoLink
            .replace("<WGAccountNumber>", this.accountDetails.BigDog_WG_Account__c)
            .replace("<PartAccountNumber>",this.accountDetails.BigDog_Parts_Account__c)
            .replace("<DealerDomainName>",'bigdogmowers');
        } 

        if (documotoLinkRefined){
            this.redirectHandler(documotoLinkRefined);
        } else{
            alert('Error: Your account is missing a Hustler or BigDog Mower Co. Part Number!');
        }
        
    }
    redirectHandler(link) {
        this[NavigationMixin.GenerateUrl]({
            type: "standard__webPage",
            attributes: {
                url: link
            }
        }).then((url) => {
            window.open(url, "_blank");
        });
    }
}