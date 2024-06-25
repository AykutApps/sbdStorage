import { LightningElement } from "lwc";

export default class SendToLWC extends LightningElement {
  messageFromVF;
  connectedCallback() {
    var VfOrigin =
      "https://mtdproducts--devagora--c.sandbox.vf.force.com";
    window.addEventListener("message", (message) => {
        console.log('messageFromVF ');
      if (message.origin !== VfOrigin) {
        //Not the expected origin
        return;
      }

      //handle the message
      if (message.data.name === "SampleVFToLWCMessage") {
        this.messageFromVF = message.data.payload;
      }
    });
  }
}