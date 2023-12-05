({
    doInit: function (component, event, helper) {
        console.log("CommunityPageToExternalUrl:doInit");
        var externalUrl = component.get("v.externalUrl");
        var loadInExistingWindow = component.get("v.loadInExistingWindow");
        console.log(externalUrl);
        console.log(loadInExistingWindow);
        if (loadInExistingWindow && window.location.href.indexOf("--livepreview") == -1) {
            if (window.performance && window.performance.navigation.type == window.performance.navigation.TYPE_BACK_FORWARD) {
                //cant use window.history.back as this sets the navigation to 2 even though the user is on the home page and clicks training again.
                var baseUrlAction = component.get("c.getBaseUrl");
                baseUrlAction.setCallback(this, function (response) {
                    var state = response.getState();
                    if (component.isValid() && state === "SUCCESS") {
                        window.location.href = response.getReturnValue();
                    } else {
                        console.log("Failed with state: " + state);
                    }
                });
                $A.enqueueAction(baseUrlAction);
            } else {
                console.log("loadInExistingWindow");
                window.location.href = externalUrl;
            }
        } else {
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                url: externalUrl
            });
            urlEvent.fire();

            console.log(window.location.href);
            if (window.location.href.indexOf("--livepreview") == -1) {
                window.history.back();
            }
        }
    }
});
