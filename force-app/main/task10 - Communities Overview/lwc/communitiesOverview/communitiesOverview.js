import { LightningElement, wire } from "lwc";
import getRecords from "@salesforce/apex/GenericLWCService.getRecords";
import MultilineText from 'c/multilineText';

const columns = [
    // { label: "Id", fieldName: "Id" },
    { label: "Name", fieldName: "Name" },
    { label: "Url Prefix", fieldName: "UrlPathPrefix" },
    { label: "Description", fieldName: "Description", wrapText: true,  initialWidth: 280 },
    { label: "Activation Date", fieldName: "FirstActivationDate", wrapText: true },
    { label: "Status", fieldName: "Status", initialWidth: 100},
    { label: "Profiles", fieldName: "ProfileNames", wrapText: true , type: 'multilineText', initialWidth: 280},
    { label: "Permission Sets", fieldName: "PermissionSetNames", wrapText: true, initialWidth: 320 },
    { label: "Chatters Groups", fieldName: "CollaborationGroupNames",initialWidth: 240 }
];

export default class CommunitiesOverview extends LightningElement {

    customTypes = {
        multilineText: {
            template: MultilineText,
            typeAttributes: ['value'],
        },
    };

    error;
    networks = [];
    networkIdMap;
    profiles = [];
    permissionSets = [];
    networkMemberGroups = [];
    collaborationGroups = [];

    columns = columns;
    refinedNetworks = [];

    processCheck = {};

    @wire(getRecords, { query: "SELECT Id, Name, UrlPathPrefix, Description, FirstActivationDate, Status FROM Network ORDER BY Name" })
    getNetworks({ data, errors }) {
        if (data) {
            console.log("networks:", data);
            this.networks = data;
            this.processCheck.networks = true;
            this.checkDataRetrieveIsCompleted();
        }
    }

    @wire(getRecords, { query: "SELECT Id, ParentId, NetworkId FROM NetworkMemberGroup" })
    getNetworkMemberGroups({ data, errors }) {
        if (data) {
            console.log("NetworkMemberGroups:", data);
            this.networkMemberGroups = data;
            this.processCheck.networkMemberGroups = true;
            this.checkDataRetrieveIsCompleted();
        }
    }

    @wire(getRecords, { query: "SELECT Id, Name FROM Profile" })
    getProfiles({ data, errors }) {
        if (data) {
            console.log("Profiles:", data);
            this.profiles = data;
            this.processCheck.profiles = true;
            this.checkDataRetrieveIsCompleted();
        }
    }

    @wire(getRecords, { query: "SELECT Id, Name FROM PermissionSet" })
    getPermissionSets({ data, errors }) {
        if (data) {
            console.log("PermissionSets:", data);
            this.permissionSets = data;
            this.processCheck.permissionSets = true;
            this.checkDataRetrieveIsCompleted();
        }
    }

    @wire(getRecords, { query: "SELECT Id, Name, NetworkId FROM CollaborationGroup" })
    getCollaborationGroups({ data, errors }) {
        if (data) {
            console.log("CollaborationGroups:", data);
            this.collaborationGroups = data;
            this.processCheck.collaborationGroups = true;
            this.checkDataRetrieveIsCompleted();
        }
    }

    checkDataRetrieveIsCompleted() {
        if (
            this.processCheck.networks &&
            this.processCheck.networkMemberGroups &&
            this.processCheck.profiles &&
            this.processCheck.permissionSets &&
            this.processCheck.collaborationGroups
        ) {
            console.log("completed");
            this.refineNetworks();
        } else {
            {
                console.log("not completed");
            }
        }
    }

    refineNetworks() {
        let networkIdMap = this.convertToIdMap(this.networks);
        const profileIdMap = this.convertToIdMap(this.profiles);
        const permissionSetIdMap = this.convertToIdMap(this.permissionSets);
        const collaborationGroupIdMap = this.convertToIdMap(this.collaborationGroups);
        console.log("profileIdMap", profileIdMap);

        for (const ng of this.networkMemberGroups) {
            if (ng.ParentId.startsWith("00e")) {
                if (!networkIdMap[ng.NetworkId].profiles) {
                    networkIdMap[ng.NetworkId].profiles = [];
                }

                networkIdMap[ng.NetworkId].profiles.push(profileIdMap[ng.ParentId]);
            } else {
                if (!networkIdMap[ng.NetworkId].permissionSets) {
                    networkIdMap[ng.NetworkId].permissionSets = [];
                }

                networkIdMap[ng.NetworkId].permissionSets.push(permissionSetIdMap[ng.ParentId]);
            }
        }

        for (const cg of this.collaborationGroups) {
            if (cg.NetworkId) {
                if (!networkIdMap[cg.NetworkId].collaborationGroups) {
                    networkIdMap[cg.NetworkId].collaborationGroups = [];
                }
                networkIdMap[cg.NetworkId].collaborationGroups.push(cg);
            }
        }

        this.refinedNetworks = [];
        for (const id in networkIdMap) {
            let nw = networkIdMap[id];
            if (nw.profiles && !nw.profiles.length !== 0) {
                nw.ProfileNames = nw.profiles.map((obj) => obj.Name).join(",\n ");
            }
            if (nw.permissionSets && !nw.permissionSets.length !== 0) {
                nw.PermissionSetNames = nw.permissionSets.map((obj) => obj.Name).join(", ");
            }
            if (nw.collaborationGroups && !nw.collaborationGroups.length !== 0) {
                nw.CollaborationGroupNames = nw.collaborationGroups.map((obj) => obj.Name).join(", ");
            }

            this.refinedNetworks.push(nw);
        }

        console.log(this.refinedNetworks);
    }

    convertToIdMap(objList) {
        const idMap = objList.reduce((obj, item) => {
            obj[item.Id] = item;
            return obj;
        }, {});
        return JSON.parse(JSON.stringify(idMap));
    }
}
