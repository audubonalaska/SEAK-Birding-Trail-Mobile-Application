import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1

import Esri.ArcGISRuntime 100.14

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.WebView 1.0

import "../controls" as Controls
import "./Controller"


WebView {
    id: webItem

    property var challenge
    property real headerHeight: 56
    property real iconSize: 48
    property bool closeButtonClicked: false

     property AuthenticationController controller: AuthenticationController {}

    property LocaleInfo localeInfo: AppFramework.localeInfo(Qt.locale().uiLanguages[0])

    signal signInInitiated ()

    url: {
        if (portal) {
            var portalUrl = portal.url.toString().replace("http://", "https://")
            return (controller.currentChallengeUrl ? controller.currentChallengeUrl + "&hidecancel=true&locale=" + localeInfo.esriName : "").replace("https://www.arcgis.com", portalUrl)
        } else {
            return controller.currentChallengeUrl ? controller.currentChallengeUrl + "&hidecancel=true&locale=" + localeInfo.esriName : ""
        }
    }



    clip: true
    visible: false
    onLoadingChanged: {
        busyIndicator.visible = loadRequest.status === WebView.LoadStartedStatus
        visible = true
        if (loadRequest.status === WebView.LoadSucceededStatus) {
            if (title.indexOf("SUCCESS code=") > -1) {
                var authCode = title.replace("SUCCESS code=", "")
                if (challenge) {
                    controller.continueWithOAuthAuthorizationCode(authCode)
                    signInInitiated()
                }
            } else if (title.indexOf("Denied error=") > -1) {
                if (challenge) {
                    challenge.cancel()
                }
            }
        }
    }

    onSignInInitiated: {
        busyIndicator.visible = true
        pageContent.contentItem.visible = false
    }
}

