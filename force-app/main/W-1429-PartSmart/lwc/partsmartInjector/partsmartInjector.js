import { LightningElement } from "lwc";
import getScriptUrl from "@salesforce/apex/PartSmartHelper.getScriptUrl";
import getLoggedInUser from "@salesforce/apex/PartSmartHelper.getLoggedInUser";


export default class PartsmartInjector extends LightningElement {
    scriptURL;
    loggedInUser;

    connectedCallback(){
        console.log('PartsmartInjector connectedCallback');
        console.log('Set Listener:');
        window.addEventListener('message', this.handleMessage);
        this.getScriptUrlFromServer();
        this.getLoggedInUserFromServer();
    }

    getScriptUrlFromServer() {
        console.log("getScriptUrlFromServer2: ");
        getScriptUrl()
            .then((result) => {
                console.log('results', result);
                this.scriptURL = 'https://mtdproducts--devagora.sandbox.my.salesforce-sites.com/dealerservice/PartSmartTest?scriptUrl=' + encodeURIComponent(result);
                console.log('scriptURL',scriptURL);
            })
            .catch((error) => {
                console.log("ERROR: ", error);
            });
    }

    getLoggedInUserFromServer() {
        console.log("getLoggedInUserFromServer: ");
        getLoggedInUser()
            .then((result) => {
                this.loggedInUser = result;
            })
            .catch((error) => {
                console.log("ERROR: ", error);
            });
    }

    handleMessage(event) {
        console.log('Message received: ', event.data);
    }
}
