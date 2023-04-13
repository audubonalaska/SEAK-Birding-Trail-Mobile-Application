/* Copyright 2022 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0

import "../controls" as Controls

Controls.MenuPage {
    id: menuPage

    property string kFeedback: qsTr("Feedback")
    property string kNightMode: qsTr("Night Mode")
    property string kAboutApp: qsTr("About the App")
    property string kSignIn: qsTr("Sign In")
    property string kSignOut: qsTr("Sign Out")
    property string kFontSize: qsTr("Font Size")
    property string kClearCache: qsTr("Clear Cache")
    property string feedbackUrl: menuPage.generateFeedbackEmailLink(app.feedbackEmail)
    property url bannerImage: ""
    property url fallbackBannerImage: ""
    property bool isClearingCache: false
    //contentHeader properties
    property var modified
    property string title
    property bool showContentHeader: false//app.isSignedIn ? false:true

    property bool isMapOpened: false

    signal cacheCleared ()
    signal errorClearingCache ()
    signal goBackToStartPage()

    isCompact: app.isCompact
    showUserDetail: !showContentHeader

    controlsFontSize: 0.65 * app.textFontSize
    fontFamilyName: app.baseFontFamily

    onFontScaleChanged: {
        app.fontScale = getFontScale(fontScale)

    }

    iconSize: app.iconSize
    iconColor: Qt.darker(app.backgroundColor, 2)

    contentHeader: showContentHeader ? menuContentHeader : null

    Component {
        id: menuContentHeader

        Pane {
            visible: showContentHeader
            height: 2 * app.headerHeight + (isIphoneX ? 5 * app.baseUnit: 0)
            width: parent ? parent.width:0
            padding: 0
            Material.background: app.primaryColor

            LayoutMirroring.enabled: !app.isLeftToRight
            LayoutMirroring.childrenInherit: !app.isLeftToRight

            RowLayout {
                anchors {
                    fill: parent
                    margins: app.defaultMargin
                    topMargin: (Qt.platform.os === "ios"? app.units(24) : app.units(16)) + (isIphoneX ? app.baseUnit: 0)
                    bottomMargin:  (isIphoneX ? 3 * app.baseUnit: app.defaultMargin)
                }
                spacing: 0

                Rectangle {
                    id: spaceFiller
                    color: "transparent"
                    Layout.preferredWidth: app.widthOffset
                    Layout.fillHeight: true
                }

                Rectangle {
                    id: thumbnail

                    Layout.preferredHeight: 0.8 * parent.height
                    Layout.preferredWidth: 0.8 * parent.height
                    Layout.alignment: Qt.AlignVCenter
                    color: "transparent"
                    clip: true

                    Image {
                        source: bannerImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        mipmap: true

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Item {
                                width: thumbnail.width
                                height: thumbnail.height
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: parent.height
                                    radius: Math.min(width, height)
                                }
                            }
                        }
                        onStatusChanged: {
                            if (status === Image.Error) {
                                source = fallbackBannerImage
                            }
                        }
                    }
                }

                Controls.BaseText {
                    text: title

                    color: "#FFFFFF"
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    Layout.margins: app.defaultMargin
                    Layout.preferredWidth: parent.width - thumbnail.width - 2 * app.defaultMargin - spaceFiller.width
                    Layout.alignment: Qt.AlignVCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                    horizontalAlignment: Label.AlignLeft
                }

            }

            Rectangle {
                color: Qt.darker(app.backgroundColor, 1.3)
                anchors.bottom: parent.bottom
                width: parent.width
                height: app.units(1)
            }
        }
    }

    Connections {
        target: app

       function onIsSignedInChanged() {
            if (app.stackView.currentItem.objectName !== "mapPage") {
                if (isSignedIn) {
                    removeItemsFromMenuListByAttribute ("itemLabel", kSignIn)
                } else {
                    removeItemsFromMenuListByAttribute ("itemLabel", kSignIn)
                    menuPage.insertItemToMenuList(1, { "iconImage": "../images/login.png", "itemLabel": menuPage.kSignIn, "control": "" })
                }
            }
        }
    }

    menuItems: [
        {"iconImage": "../images/font-size.png", "itemLabel":menuPage.kFontSize, "control": "spinBox"}
    ]
    width: Math.min(0.74 * parent.width, app.maxMenuWidth)
    defaultMargin: app.defaultMargin

    onMenuItemSelected: {
        switch (itemLabel) {
        case sideMenu.kFeedback:
            Qt.openUrlExternally(menuPage.feedbackUrl)
            break
        case sideMenu.kNightMode:
            //console.log("Menu item selected = ", sideMenu.kNightMode)
            break
        case sideMenu.kAboutApp:
            app.aboutAppPage.open()
            break
        case sideMenu.kSignOut:
            app.signOut()
            app.isMMPKsLoaded = false;
            app.isWebMapsLoaded = false;
            break
        case sideMenu.kSignIn:
         if(app.authChallenge)
                app.authChallenge.cancel()
            if(app.clientId || app.isIWAorPKI)
            {
                app.isWebMapsLoaded = false;
                app.isMMPKsLoaded = false;
                app.createSignInPage()
            }
            else
                messageDialog.show(qsTr("Missing Client ID"),qsTr("ArcGIS Client ID is missing. Please upload your app and go to Settings > Licensing to register a Client ID."))
            break
        case itemLabel.includes(sideMenu.kClearCache) ? itemLabel : false:
            app.messageDialog.standardButtons = Dialog.No | Dialog.Yes
            app.messageDialog.show(qsTr("Clear Cache"), qsTr("This will erase downloaded offline maps and cached images from this device. Would you like to continue?"))
            app.messageDialog.connectToAccepted(function () {
                isClearingCache = true
                try {
                    offlineCache.clearAllCache(null, function () {
                        onlineCache.clearAllCache(null, function () {
                            app.screenshotsCache.clearAllCache(null,function(){
                                offlineMapAreaCache.clearAllCache(null,function(){
                                    app.portalSearch.refresh()
                                    isClearingCache = false
                                    cacheCleared()
                                })
                            })
                        })
                    })
                } catch (err) {
                    errorClearingCache()
                }
            })
            app.messageDialog.open()
        }
    }

    Component.onCompleted: {
        addAboutItem()
        refreshFeedbackItem()
        refreshLoginItem()
        fontScale = app.settings.value("fontScale", 1.0)
    }

    onVisibleChanged: {
        if (!visible) {
            app.focus = true
        }
    }

    function getFontScale(fontScale)
    {
        var newScale = fontScale
        if (app.isDesktop){
            switch(fontScale.toString()){
            case "1":
                newScale = 0.8
                break;
            case "1.2":
                newScale = 1.0
                break;
            case "1.4":
                newScale = 1.2
                break;
            }
        }
        return newScale
    }

    function refreshClearCacheItem () {
        var mmpkcacheSize = app.offlineCache.getCacheSizeRecursively()
        app.offlineMapAreaCache.fileFolder.refresh()
        var mapareacacheSize = app.offlineMapAreaCache.fileFolder.size
        var screenshotsBasePath = app.screenshotsCache.storagePath
        //var screenshotsBasePath ="~/ArcGIS/AppStudio/cache/"+ app.info.itemId.toString() + "/screenshotsCache/"
        var screenShotsCacheFolder = AppFramework.fileInfo(screenshotsBasePath).folder

        var screenshotsCache = screenShotsCacheFolder.size
        var cacheSize = mmpkcacheSize + mapareacacheSize + screenshotsCache
        menuPage.removeItemsFromMenuListByString(menuPage.kClearCache)
        if (cacheSize) {
           let _sizeinlocale = (Math.round((cacheSize/1000000) * 10) / 10).toLocaleString(Qt.locale())
            var sizeInMb = qsTr("%L1 %2").arg(_sizeinlocale).arg(strings.mb)

            if(cacheSize/1000000 > 0.1)
                menuPage.insertItemToMenuList(menuPage.menuItems.length, { "iconImage": "../images/delete.png", "itemLabel": "%1 (%2)".arg(menuPage.kClearCache).arg(sizeInMb), "control": "" })
        }
        menuPage.updateMenu();
    }

    function refreshFeedbackItem () {
        if (app.feedbackEmail) {
            menuPage.insertItemToMenuList(1, { "iconImage": "../images/feedback.png", "itemLabel": menuPage.kFeedback, "control": "" })
        }
    }

    function addAboutItem(){
        menuPage.insertItemToMenuList(1,{"iconImage": "../images/info.png", "itemLabel": menuPage.kAboutApp, "control": ""})
    }

    function refreshLoginItem () {
        if (app.supportSecuredMaps) {
            if (app.isSignedIn) {
            } else {
                menuPage.insertItemToMenuList(1, { "iconImage": "../images/login.png", "itemLabel": menuPage.kSignIn, "control": "" })
            }
        }
    }

    function generateFeedbackEmailLink(email) {
        var urlInfo = AppFramework.urlInfo("mailto:%1".arg(email)),
        deviceDetails = [
                    "%1: %2 (%3)".arg(qsTr("Device OS")).arg(Qt.platform.os).arg(AppFramework.osVersion),
                    "%1: %2".arg(qsTr("Device Locale")).arg(Qt.locale().name),
                    "%1: %2".arg(qsTr("App Version")).arg(app.info.version),
                    "%1: %2".arg(qsTr("AppStudio Version")).arg(AppFramework.version),
                ];
        urlInfo.queryParameters = {
            "subject": "%1 %2".arg(qsTr("Feedback for")).arg(app.info.title),
            "body": "\n\n%1".arg(deviceDetails.join("\n"))
        };
        return urlInfo.url
    }
}
