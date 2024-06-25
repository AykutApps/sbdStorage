import { LightningElement, wire, track } from "lwc";
import getWebcarts from "@salesforce/apex/DOS_WebcardRestService.getWebcarts";
import createCartItem from "@salesforce/apex/DOS_WebcardRestService.createCartItem";

const columns = [
    { label: "Webcart Name", fieldName: "Name" },
    { label: "Webcart ID", fieldName: "Id" },
    { label: "Is Docomotu", fieldName: "Is_Documoto__c", type: "text" },
    { label: "Owner Name", fieldName: "OwnerName", type: "text" },
    {
        label: "Created Date",
        fieldName: "CreatedDate",
        type: "date",
        typeAttributes: {
            year: "numeric",
            month: "short",
            day: "2-digit",
            hour: "2-digit",
            minute: "2-digit",
            second: "2-digit",
            hour12: true
        }
    },
    {
        label: "Action",
        type: "button",
        typeAttributes: {
            label: "View Items",
            name: "view"
        }
    }
];

const columnsItems = [
    { label: "Product Code", fieldName: "ProductCode", type: "text" },
    { label: "Quantity", fieldName: "Quantity", type: "number" }
];

export default class WebcartList extends LightningElement {
    @track webcarts;
    @track webcartItems = [];
    @track columns = columns;
    @track columnsItems = columnsItems;
    maxRowSelection = 1;

    @track isModalOpen = false;
    @track selectedRow = {};

    //
    @track cartName = "";
    @track itemCode = "";
    @track accountNumber = "";
    @track quantity = 0; // New property for the age

    handleChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    handleSubmit() {
        console.log("Submitted values:", this.cartName, this.itemName, this.quantity);
        let payload = `{"cartName":"${this.cartName}","hustlerPartsAccountNumber":"${this.accountNumber}","items":[{"productCode":"${this.itemCode}","productQuantity":"${this.quantity}"}]}`;
        console.log(payload);

        createCartItem({ payload: payload})
            .then((result) => {
                console.log(result); // Handle response
                this.dispatchEvent(new CustomEvent("success", { detail: "User info saved successfully!" }));
            })
            .catch((error) => {
                console.error(error); // Handle error
                this.dispatchEvent(new CustomEvent("error", { detail: error.body.message }));
            });
    }

    @wire(getWebcarts)
    wiredWebcarts({ error, data }) {
        if (data) {
            this.webcarts = data.map((record) => ({
                ...record,
                OwnerName: record.Owner.Name // Add the owner's name to each record
            }));
        } else if (error) {
            this.webcarts = undefined;
            console.error("Error retrieving webcarts:", error);
        }
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;

        if (selectedRows.length === 0) {
            return;
        }

        this.selectedRow = selectedRows[0]; // Take the first selected row for this example
        this.isModalOpen = true;

        this.webcartItems =
            this.selectedRow.CartItems?.map((item) => ({
                ...item,
                ProductCode: item.Product2?.ProductCode || "" // Flatten the Product2 object
            })) || [];
    }

    handleRowAction(event) {
        const row = event.detail.row;
        this.selectedRow = row; // Take the first selected row for this example
        this.isModalOpen = true;

        this.webcartItems =
            this.selectedRow.CartItems?.map((item) => ({
                ...item,
                ProductCode: item.Product2?.ProductCode || "" // Flatten the Product2 object
            })) || [];
    }

    closeModal() {
        this.isModalOpen = false;
    }
}
