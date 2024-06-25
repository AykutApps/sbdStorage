import { LightningElement, track } from "lwc";
import getWebcartItems from "@salesforce/apex/PartSmartInjectorCtl.getWebcartItems";

const columnsItems = [
    { label: "Product Name", fieldName: "Name", type: "text" },
    { label: "Quantity", fieldName: "Quantity", type: "number", cellAttributes: { alignment: 'left' } },
    { label: "Description", fieldName: "Description", type: "text" }
];

export default class WebcartDetail extends LightningElement {
    @track columnsItems = columnsItems;
    @track webcartItems = [];

    connectedCallback(){

        window.addEventListener("message", (event) => {
            console.log('some event');
        });
    }

    // @wire(getWebcartItems)
    // wiredWebcarts({ error, data }) {
    //     if (data) {
    //         this.webcartItems = data.map((record) => ({
    //             ...record
    //         }));
    //     } else if (error) {
    //         console.error("Error retrieving webcartItems:", error);
    //     }
    // }
    // renderedCallback() {
    //     this.refreshData();
    // }

    refreshData() {
        console.log("Button clicked: ");
        getWebcartItems()
            .then((result) => {
                this.webcartItems = result;
                console.log('results', result);
                this.webcartItems = result.map((record) => ({
                    ...record,
                    Description: record.Product2.Description // Add the owner's name to each record
                }));
            })
            .catch((error) => {
                console.log("ERROR: ", error);
            });
    }
}
