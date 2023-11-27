import { LightningElement, wire } from "lwc";
import getRecords from "@salesforce/apex/GenericLWCService.getRecords";

const columns = [
    { label: "Id", fieldName: "Id" },
    { label: "Name", fieldName: "Name" },
    { label: "Url Prefix", fieldName: "UrlPathPrefix" },
    { label: "Description", fieldName: "Description", wrapText: true },
    { label: "Profiles", fieldName: "ProfileNames" , wrapText: true},
    { label: "Permission Sets", fieldName: "PermissionSetNames", wrapText: true, initialWidth: 320 },
    { label: "Chatters", fieldName: "CollaborationGroupNames"}
];

export default class CommunitiesOverview extends LightningElement {
    error;
    networks = [];
    networkIdMap;
    profiles = [];
    permissionSets = [];
    networkMemberGroups = [];
    collaborationGroups = [];

    columns = columns;
    refinedNetworks = [];

    @wire(getRecords, { query: "SELECT Id, Name, UrlPathPrefix, Description FROM Network" })
    getNetworks({ data, errors }) {
        if (data) {
            console.log("networks:", data);
            this.networks = data;
            this.checkDataRetrieveIsCompleted();
        }
    }

    @wire(getRecords, { query: "SELECT Id, ParentId, NetworkId FROM NetworkMemberGroup" })
    getNetworkMemberGroups({ data, errors }) {
        if (data) {
            console.log("NetworkMemberGroups:", data);
            this.networkMemberGroups = data;
            this.checkDataRetrieveIsCompleted();
        }
    }

    @wire(getRecords, { query: "SELECT Id, Name FROM Profile" })
    getProfiles({ data, errors }) {
        if (data) {
            console.log("Profiles:", data);
            this.profiles = data;
            this.checkDataRetrieveIsCompleted();
        }
    }

    @wire(getRecords, { query: "SELECT Id, Name FROM PermissionSet" })
    getPermissionSets({ data, errors }) {
        if (data) {
            console.log("PermissionSets:", data);
            this.permissionSets = data;
            this.checkDataRetrieveIsCompleted();
        }
    }

    @wire(getRecords, { query: "SELECT Id, Name, NetworkId FROM CollaborationGroup" })
    getCollaborationGroups({ data, errors }) {
        if (data) {
            console.log("CollaborationGroups:", data);
            this.collaborationGroups = data;
            this.checkDataRetrieveIsCompleted();
        }
    }

    checkDataRetrieveIsCompleted() {
        if (
            this.networks.length !== 0 &&
            this.networkMemberGroups.length !== 0 &&
            this.profiles.length !== 0 &&
            this.permissionSets.length !== 0 &&
            this.collaborationGroups.length !== 0
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
                nw.ProfileNames = nw.profiles.map((obj) => obj.Name).join(", ");
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
