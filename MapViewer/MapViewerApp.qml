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

import QtQuick 2.9
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.Authentication 1.0
import ArcGIS.AppFramework.WebView 1.0
import ArcGIS.AppFramework.Sql 1.0

import Esri.ArcGISRuntime 100.14

import ArcGIS.AppFramework.Platform 1.0


import "controls" as Controls
import "views" as Views
import "../assets"
import "./views/Controller"
import "../utility"
import "../Components/Identify"

import "../Components/Editor"
import "../Components/Editor/Layout" as Sketch
import "./audubonalaska/Nashelper.js" as Nashelper

App {
    id: app

    height: 690
    width: 950 //420 //
    signal showSpatialSearchResults()
    //webmapId is the parameter that accepts input  when you open a webmap in Player
    property bool isAddLayerMode:false
    property var refreshToken:""
    property string userName:""
    property var userpassword:""
    property var basemapUrl:""
    property var token:""
    property bool isEmbedded:true
    property var layerType:""
    property string layerUrl:""
    property bool isPrivateItem:false
    property string appTitle:""
    property bool isSignInPageOpened:false
    property  int searchLegendListHeight:100


    property string itemId:""
    property string basemapsGroupId:app.info.properties.baseMapsGroupId
    readonly property string appId: app.info.itemInfo.id
    readonly property real baseUnit: app.units(8)
    readonly property real defaultMargin: 2 * app.baseUnit
    readonly property real textSpacing: 0.5 * app.defaultMargin
    readonly property real iconSize: 5 * app.baseUnit
    readonly property real mapControlIconSize: 6 * app.baseUnit
    readonly property real headerHeight: 7 * app.baseUnit
    readonly property real preferredContentWidth: 75 * app.baseUnit
    readonly property real maxMenuWidth: 36 * app.baseUnit
    readonly property real baseElevation: 2
    readonly property real raisedElevation: 8
    readonly property real compactThreshold: app.units(496)
    readonly property real heightOffset: isIphoneX ? app.units(20) : 0
    readonly property real widthOffset: isIphoneX && isLandscape ? app.units(40) : 0
    property bool isIphoneX: false
    property bool isWindows7: false
    property bool isIphoneXAndLandscape: isNotchAvailable() && !isPortrait
    property real notchHeight: ( Qt.platform.os === "ios") ? ( isPortrait ? getHeightPortrait() : getHeightLandscape() ) : 0
    property bool isPortrait: app.width < app.height
    property real fontScale: app.isDesktop? 0.8 : 1
    readonly property real baseFontSize: fontScale * app.getProperty("baseFontSize", Qt.platform.os === "windows" ? 10 : 14)
    readonly property real subtitleFontSize: 1.5 * app.baseFontSize
    readonly property real titleFontSize: 2 * app.baseFontSize
    readonly property real textFontSize: 0.9 * app.baseFontSize
    readonly property real labelFontSize: 1.8 * app.baseFontSize
    readonly property real scaleFactor: AppFramework.displayScaleFactor

    property bool isOnline: Networking.isOnline
    readonly property bool isCompact: app.width <= app.compactThreshold
    readonly property bool isMidsized: (app.width > app.compactThreshold) && (app.width <= 800)
    readonly property bool isLarge: !app.isCompact && !app.isMidsized
    readonly property bool isLandscape: app.width > app.height
    readonly property bool isDebug: false

    // portal and security
    property url portalUrl:""
    property string portalSortField:app.getProperty("portalSortField","modified")
    property int portalSortOrder:app.getSortOrderAsInt("portalSortOrder")

    property bool supportSecuredMaps: app.getProperty("supportSecuredMaps", false) && isOnline
    property bool supportEditing: isEmbedded && isOnline ?app.getProperty("supportEditing", false):(isOnline? true:false)
    property bool skipMmpkLogin: true
    property bool showPublishedMmpksOnly: true && !isSignedIn
    readonly property string mapTypes: app.getProperty("mapTypes", "showWebMapsOnly")
    readonly property bool showOfflineMapsOnly: mapTypes === "showOfflineMapsOnly"
    property bool showAllMaps:mapTypes === "showBoth"
    readonly property bool showWebMapsOnly: mapTypes === "showWebMapsOnly"
    property bool enableAnonymousAccess: app.getProperty("enableAnonymousAccess", false)
    property string clientId:getClientId()
    property int portalType: 0
    property bool isIWAorPKI: false
    property bool isClientIDNeeded: false
    property bool isWebMapsLoaded: false
    property bool isMMPKsLoaded: false
    property int currentTab: app.showOfflineMapsOnly? 2 : 1
    readonly property string unableToAccessPortal: qsTr("Unable to access portal at this time. Please check the network.")
    readonly property string loginRequiredNotification:  qsTr("Sign in required to access maps for this portal.")
    property var portalUserInfo:({})

    readonly property color primaryColor: app.isDebug ? app.randomColor("primary") : app.getProperty("brandColor", "#166DB2")
    readonly property color backgroundColor: app.isDebug ? app.randomColor("background") : "#EFEFEF"
    readonly property color foregroundColor: app.isDebug ? app.randomColor("foreground") : "#22000000"
    readonly property color separatorColor: Qt.darker(app.backgroundColor, 1.2)
    readonly property color accentColor: Qt.lighter(app.primaryColor)
    readonly property color titleTextColor: app.backgroundColor
    readonly property color subTitleTextColor: Qt.darker(app.backgroundColor)
    readonly property color baseTextColor: Qt.darker(app.subTitleTextColor)
    readonly property color iconMaskColor: "transparent"
    readonly property color black_87: "#DE000000"
    readonly property color white_100: "#FFFFFFFF"
    readonly property color warning_color:"#D54550"
    readonly property url license_appstudio_icon: "./Images/appstudio.png"


    readonly property color darkIconMask: "#4c4c4c"

    readonly property bool canUseBiometricAuthentication: BiometricAuthenticator.supported && BiometricAuthenticator.activated
    property bool hasFaceID: isIphoneX

    // start page
    readonly property color startForegroundColor: app.foregroundColor
    readonly property color startBackgroundColor: app.backgroundColor
    readonly property url startBackground: app.folder.fileUrl(app.getProperty("startBackground"))

    // gallery page
    readonly property string searchQuery: itemId >""?("id:" + itemId):app.getProperty("galleryMapsQuery")

    readonly property int maxNumberOfQueryResults: app.getProperty("maxNumberOfQueryResults", 20)

    readonly property string feedbackEmail: app.getProperty("feedbackEmail", "")

    readonly property bool hasDisclaimer: app.info.itemInfo.licenseInfo > ""
    property bool showDisclaimer: app.info.propertyValue("showDisclaimer", true)
    property bool disableDisclaimer: app.settings.boolValue("disableDisclaimer", false)
    property bool showMapUnits: true
    property bool showGrid: false
    property bool showGridLabel: false

    // menu
    property bool showBackToGalleryButton: true

    // Use mobile data strings
    readonly property string kUseMobileData: qsTr("Use your mobile data to download the Mobile Map Package %1")
    readonly property string kWaitForWifi: qsTr("Wait for Wi-Fi")

    // Check capabilities
    readonly property string locationAccessDisabledTitle: qsTr("Location access disabled")
    readonly property string locationAccessDisabledMessage: qsTr("Please enable Location access permission for %1 in the device Settings.")
    readonly property string ok_String: qsTr("Ok")
    readonly property string cancel_string: qsTr("Cancel")
    readonly property string today_string: qsTr("Today")
    readonly property bool isDesktop: Qt.platform.os === "ios" || Qt.platform.os === "android" ? false:true
    property bool hasLocationPermission:false
    property bool isTablet: (Math.max(app.width, app.height) > 1000 * scaleFactor) || (AppFramework.systemInformation.family === "tablet")

    property string kBackToGallery:qsTr("Back to Gallery")
    property string kBack:qsTr("Back")

    // Offline Routing strings
    readonly property string offline_routing: qsTr("Offline Routing")
    readonly property string choose_starting_point: qsTr("Choose starting point")
    readonly property string choose_destination: qsTr("Choose destination")
    readonly property string directions: qsTr("Directions")
    readonly property string no_route_found: qsTr("No route found")
    readonly property string location_outside_extent: qsTr("Location is outside the extent of the offline map.")
    readonly property string current_location: qsTr("Current location")
    readonly property string search_a_place: qsTr("Search a place")
    readonly property string search_a_feature: qsTr("Search a feature")
    readonly property string choose_on_map: qsTr("Choose on map")
    readonly property string directions_not_available: qsTr("Directions not available for this route.")
    readonly property string kOfflineMapArea:qsTr("Offline map area")
    readonly property string kOfflineMapAreas_title:qsTr("Offline Map Areas")
    readonly property var mapsWithMapAreas:[]
    readonly property string kMapArea:qsTr("Map Area")
    property bool identifyInProgress:false
    property bool exitEditModeInProgress:false
    property bool isWebMap:false
    property bool isLeftToRight:!(AppFramework.localeInfo().esriName === "ar" || AppFramework.localeInfo().esriName === "he")
    property bool isRightToLeft:!isLeftToRight
    readonly property string save_image:qsTr("Save Image")
    readonly property string save_edit:qsTr("Do you want to save edits?")
    readonly property string smart_draw_enabled:qsTr("Smart draw enabled.")
    readonly property string smart_draw_disabled:qsTr("Smart draw disabled.")
    readonly property string smart_draw_string:qsTr("Enable to turn hand drawn lines and text into straight lines, circles and rectangles.")
    readonly property string smart_draw_caps:qsTr("Smart Draw")
    readonly property string smart_draw_sentence_case:qsTr("Smart draw")
    readonly property string save_changes:qsTr("Do you want to save changes?")
    readonly property string draw_settings:qsTr("Settings")
    readonly property string annotation_settings:qsTr("Annotation settings")
    readonly property string drawing_settings:qsTr("Drawing settings")

    readonly property string map_title: qsTr("Map Title")
    readonly property string north_arrow: qsTr("North Arrow")
    readonly property string scale_bar: qsTr("Scale Bar")
    readonly property string draw_settings_date: qsTr("Date")
    readonly property string draw_settings_logo: qsTr("Logo")
    readonly property string draw_settings_legend: qsTr("Legend")

    // Animation
    readonly property int normalDuration: 250
    readonly property int fastDuration: 250
    property real maximumScreenWidth: app.width > 1000 * scaleFactor ? 800 * scaleFactor : 568 * scaleFactor

    // EmailComposerErrorMessage
    readonly property string invalid_attachment: qsTr("Invalid attachment.")
    readonly property string attachment_file_not_found: qsTr("Cannot find attachment.")
    readonly property string mail_client_open_failed: qsTr("Cannot open mail client.")
    readonly property string mail_service_not_configured: qsTr("Mail service not configured.")
    readonly property string platform_not_supported: qsTr("Platform not supported.")
    readonly property string send_failed: qsTr("Failed to send email.")
    readonly property string save_failed: qsTr("Failed to save email.")
    readonly property string unknown_error: qsTr("Unknown error.")
    property bool isPhone:AppFramework.systemInformation.family === "phone"
    property var screenShotsCacheFolder:null
    property var findItemsCompleted:app.itemId >""?false:true
    property bool isInEditMode:false
    property bool isExpandButtonClicked:false
    property var screenHeight:app.height
    property string activeSearchTab:app.tabNames.kPlaces
    property bool userHasEditRole:false
    property bool isUserRoleDetermined:false

    //portalItems to search - webmap, mmpk, basemap
    property var portalItemTypesToSearch:[]
    property string portalItemTypeCurrentlySearching:""
    property var favoriteMeasurementUnits : measurementUnits["m"]
    property var authChallenge



    signal populateGalleryTab()
    signal refreshGallery()

    property AuthenticationController controller: AuthenticationController {}
    property var signInPage

    property bool isPortalSecured:false
    property bool isPortalLoading:false

    QtObject {
        id:measurementUnits
        property int m:0
        property int mi:1
        property int km:2
        property int ft:3
        property int yd:4

    }

    Component.onDestruction: {
        //this is added because on opening secured maps the refreshtoken changes
        if(portal && portal.credential)
            secureStorage.setContent("oAuthRefreshToken", portal.credential.oAuthRefreshToken)
    }

    Fonts {
        id: fonts
    }

    //    FeaturesManager{
    //        id:featuresManager

    //    }
    LayerManager{
        id:layerManager

    }

    UtilityFunctions{
        id:utilityFunctions
    }

    // Utility file used to assist in Basemap names' translation
    BasemapsTranslator{
        id: basemapsTranslator
    }

    //--------------------------------------------------------------------------
    /*
        cannot check for editorTrackingInfo to find out if it is disabled or enabled because
        trying to access feature.featureTable.serviceGeodatabase.serviceInfo.editorTrackingInfo was causing a delay in
        loading the attachments and the fetchData for the attachment was returning an error. So we are just checking for
        editFieldsInfo.
    */

    function getHeightLandscape() {
        return isNotchAvailable() ? 0 : 20
    }

    function getHeightPortrait() {
        return isNotchAvailable() ? 40 : 20
    }

    function getEditorTrackingInfo(feature)
    {
        let editorInfo = null

        if(feature.featureTable && feature.featureTable.layerInfo){

            let editFieldsInfo = feature.featureTable.layerInfo.editFieldsInfo
            let attributesJson = feature.attributes.attributesJson
            //get the editor date
            if(editFieldsInfo)
            {
                let editDate = attributesJson[editFieldsInfo.editDateField]
                let editor = attributesJson[editFieldsInfo.editorField]
                editorInfo = {}
                if(editDate){
                    let editedDate = app.getTimeDiff(editDate)
                    editorInfo["editedDate"] = editedDate
                }

                editorInfo["editor"] = editor
            }


        }
        return editorInfo

    }



    function getDate(timestamp)
    {
        var date = new Date(timestamp);
        var jsDateValues = [
                    date.getMonth()+1,
                    date.getDate(),
                    date.getFullYear()
                ]
        return jsDateValues.join("/")
    }

    function getTimeDiff(date1)
    {
        let timeDiff =  ""

        let date_obj2 = new Date(date1)
        let date_obj1 = new Date()


        let diff_secs =(date_obj1.getTime() - date_obj2.getTime()) / 1000;
        if(diff_secs > 60)
        {
            let diff_mins = diff_secs/60;
            if(diff_mins > 60)
            {
                let diff_hrs = diff_mins/60;
                if(diff_hrs > 24)
                    timeDiff = getFormattedFieldValue(date1,Enums.FieldTypeDate)
                else
                {
                    let hrs = Math.round(diff_hrs)
                    if(hrs > 1)
                        timeDiff = strings.hours_ago.arg(hrs)
                    else
                        timeDiff = strings.hour_ago.arg(hrs)
                }
            }
            else
            {
                let mins = Math.round(diff_mins)
                if(mins > 1)
                    timeDiff = strings.minutes_ago.arg(mins)
                else
                    timeDiff = strings.minute_ago.arg(mins)

            }
        }
        else
        {
            let secs = Math.round(diff_secs)
            if (secs > 1)
                timeDiff = strings.seconds_ago.arg(secs)
            else
                timeDiff = strings.second_ago.arg(secs)

        }

        return timeDiff

    }


    function getDistance(val)
    {
        var locale = Qt.locale()
        var distance
        var distanceInMeters = val
        if(Qt.locale().measurementSystem !== Locale.MetricSystem)
        {

            var distanceInMiles = (distanceInMeters/1609.34)
            if(distanceInMiles < 0.1)
            {
                var distanceInFeet = distanceInMiles * 5280
                distance = parseFloat(Math.round(distanceInFeet)).toLocaleString(Qt.locale()) + " " + strings.ft
            }
            else
                distance = parseFloat(distanceInMiles.toFixed(1)).toLocaleString(Qt.locale()) + " " + strings.mi
        }
        else
        {
            if(distanceInMeters > 1000)
            {
                var distanceInKm = distanceInMeters/1000
                distance = parseFloat(distanceInKm.toFixed(1)).toLocaleString(Qt.locale()) + " " + strings.km
            }
            else
                distance = parseFloat(Math.round(distanceInMeters)).toLocaleString(Qt.locale()) + " " + strings.m
        }
        return distance

    }


    function isNotchAvailable(){
        let unixName

        if ( AppFramework.systemInformation.hasOwnProperty("unixMachine") )
            unixName = AppFramework.systemInformation.unixMachine;

        if ( typeof unixName === "undefined" )
            return false

        if ( unixName.match(/iPhone([1-9][0-9])/) ) {
            switch ( unixName ){
            case "iPhone10,1":
            case "iPhone10,4":
            case "iPhone10,2":
            case "iPhone10,5":
            case "iPhone12,8":
                return false
            default:
                return true
            }
        }

        return false
    }

    function deleteOfflineMapArea(mapid,mapareaId)
    {
        var fileName = "mapareasinfos.json"

        var mapAreaPath = offlineMapAreaCache.fileFolder.path + "/"+ mapid
        let mapAreafileInfo = AppFramework.fileInfo(mapAreaPath)
        //fileInfo.folder points to previous folder
        if (mapAreafileInfo.folder.fileExists(fileName)) {
            var   fileContent = mapAreafileInfo.folder.readJsonFile(fileName)
            var results = fileContent.results
            var existingmapareas = results.filter(item => item.id !== mapareaId)
            fileContent.results = existingmapareas

            //delete the folder
            var thumbnailFolder = mapareaId + "_thumbnail"
            var mapareacontentpath = [mapAreaPath,thumbnailFolder].join("/")
            let fileFolder= AppFramework.fileFolder(mapareacontentpath)
            var isthumbnaildeleted = fileFolder.removeFolder()
            var mapareacontents = [mapAreaPath,mapareaId].join("/")
            let mapareafileFolder = AppFramework.fileFolder(mapareacontents)
            var isdeleted = mapareafileFolder.removeFolder()
            if(isdeleted)
                mapAreafileInfo.folder.writeJsonFile(fileName, fileContent)

        }

        portalSearch.populateLocalMapPackages()
        refreshGallery()

    }


    onFontScaleChanged: {
        app.settings.setValue("fontScale", fontScale)
    }

    property alias baseFontFamily: baseFontFamily.name
    FontLoader {
        id: baseFontFamily

        source: app.folder.fileUrl(app.getProperty("regularFontTTF", ""))
    }

    property alias titleFontFamily: titleFontFamily.name
    FontLoader {
        id: titleFontFamily

        source:  app.folder.fileUrl(app.getProperty("mediumFontTTF", ""))
    }


    //--------------------------------------------------------------------------

    property alias tabNames: tabNames
    QtObject {
        id: tabNames

        property string kLegend: qsTr("LEGEND")
        property string kContent: qsTr("LAYERS")
        property string kInfo: qsTr("INFO")
        property string kBookmarks: qsTr("BOOKMARKS")
        property string kMapAreas: qsTr("MAPAREAS")
        property string kFeatures: qsTr("FEATURES")
        property string kPlaces: qsTr("PLACES")
        property string kBasemaps: qsTr("BASEMAPS")
        property string kMapUnits: qsTr("MAP UNITS")
        property string kOfflineMaps: qsTr("OFFLINE MAPS")
        property string kGraticules: qsTr("GRATICULES")
        property string kMedia: qsTr("MEDIA")
        property string kAttachments: qsTr("ATTACHMENTS")
        property string kRelatedRecords: qsTr("RELATED")
        property string kElevationProfile: qsTr("PROFILE")
        property string kCreateNewFeature: qsTr("CREATENEWFEATURE")
    }

    //--------------------------------------------------------------------------

    property alias stackView: stackView
    StackView {
        id: stackView

        anchors.fill: parent
        initialItem: startPage
    }


    function openMap (portalItem, mapProperties) {
        if(portalItem){
            var screenshotsBasePath = screenshotsCache.storagePath + portalItem.id + "/"
            screenShotsCacheFolder = AppFramework.fileInfo(screenshotsBasePath).folder
            screenShotsCacheFolder.makeFolder()
            if (!mapProperties) mapProperties = {"fileUrl": "","isMapArea":false,"mapId":portalItem.id}
            stackView.push(mapPage, {destroyOnPop: true, "mapProperties": mapProperties, "portalItem": portalItem})
        }
    }
    function openEmptyMap()
    {
        if(app.layerType === "Feature Collection")
        {
            let  mapProperties = {"fileUrl": "","isMapArea":false,"mapId":""}
            stackView.push(mapPage, {destroyOnPop: true, "mapProperties": mapProperties, "portalItem": ""})

        }
        else if(app.layerType === "Vector Tile Service")
        {
            let  _mapProperties = {"fileUrl": "","isMapArea":false,"mapId":"","layerUrl":layerUrl}
            stackView.push(mapPage, {destroyOnPop: true, "mapProperties": _mapProperties, "portalItem": ""})

        }

        else
        {


            addFeatureService(parseFeatureServiceResponse)

        }
    }

    function parseFeatureServiceResponse(response)
    {

        var serviceObj = JSON.parse(response)
        if(serviceObj.error)
        {
            let error = serviceObj.error.message
            if(serviceObj.error.code === 499) //
            {
                addFeatureService(parseFeatureServiceResponse,true)
            }
            else
            {

                app.messageDialog.show(qsTr("Error"),error)

                app.messageDialog.connectToAccepted(function () {
                    app.parent.exitApp()
                })
            }





        }
        else
        {

            var layers = serviceObj.layers

            let  mapProperties = {"fileUrl": "","isMapArea":false,"mapId":"","layerUrl":layerUrl,"layers":layers}
            stackView.push(mapPage, {destroyOnPop: true, "mapProperties": mapProperties, "portalItem": ""})
        }


    }

    function addFeatureService (callback,tokenReqd) {
        //get the json from the featureServiceUrl
        if(!tokenReqd)
            tokenReqd = false
        var component = selfnetworkRequestComponent;
        var networkRequest = component.createObject(parent);
        networkRequest.url = layerUrl
        networkRequest.callback = callback
        var obj = {
            "f": "json",

        }

        if((app.isPrivateItem) || tokenReqd)
        {
            obj = {
                "f": "json",
                "token":token

            }
        }

        networkRequest.send(obj)

    }



    Component{
        id: selfnetworkRequestComponent
        NetworkRequest{
            id: networkRequest

            property var name;
            property var callback;
            followRedirects: true
            ignoreSslErrors: true
            method: "GET"

            responseType: "json"



            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE ){
                    if(errorCode != 0){
                        //fileFolder.removeFile(networkRequest.name);
                        //loadStatus = 2;
                        //networkRequest.send(obj)

                    } else {

                        if (callback) {
                            callback(responseText);
                        }
                    }
                }
            }

            function getFeatureServiceJson(serviceUrl,callback){


                networkRequest.url = serviceUrl;
                //networkRequest.responsePath = mapAreaThumbnailFolder.path + "/" + downloadedmapareaId + "_thumbnail" + "/" + thumbnailImgName;
                networkRequest.callback = callback;
                networkRequest.send();

            }
        }
    }



    //--------------------------------------------------------------------------

    Component {
        id: startPage

        Views.StartPage {
            objectName: "startPage"
            onNext: {
                stackView.push(galleryPage, {destroyOnPop: true})

            }
        }
    }

    MapViewerCore{
        id:mapViewerCore

    }

    Strings {
        id: strings
    }

    Colors{
        id:colors
    }

    Component{
        id:customBtn
        Controls.CustomButton{

        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: galleryPage



        Views.GalleryPage {
            objectName: "galleryPage"

            onPrevious: {
                stackView.pop()
            }

            Component.onCompleted: {
                if (app.showDisclaimer && app.hasDisclaimer && !app.disableDisclaimer) {
                    app.disclaimerDialog.open()
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapPage

        Views.MapPage {
            objectName: "mapPage"
            onPrevious: {
                stackView.pop()
                populateGalleryTab()
            }
        }
    }


    //--------------------------------------------------------------------------

    property alias aboutAppPage: aboutAppPage
    Views.AboutAppPage {
        id: aboutAppPage
    }

    Component {
        id:offlineRoutePage
        Views.OfflineRouteView{
            objectName:offlineRoutePage

        }
    }

    Component {
        id:spatialSearchPage
        Views.SpatialSearchView{
            objectName:spatialSearchPage

        }
    }

    Component {
        id:searchPage
        Views.SearchPage{
            objectName:searchPage

        }
    }

    Component {
        id: menuPage
        Views.MenuPage {
            objectName: menuPage
        }
    }


    //--------------------------------------------------------------------------

    Component {
        id: webPageComponent

        Controls.WebPage {

        }
    }


    Component {
        id: safariBrowserComponent

        BrowserView {

        }
    }




    function openUrlInternally(url) {
        var browserView;

        if (Qt.platform.os === "ios" || Qt.platform.os === "android") {
            browserView = safariBrowserComponent.
            createObject(null, {
                             url: url
                         });
            browserView.show();
        } else {
            browserView = webPageComponent.createObject(app);
            browserView.closed.connect(browserView.destroy)
            browserView.loadPage(url)
        }
    }

    Component {
        id: webComponent
        Controls.WebPage {

        }
    }

    function openUrlInternallyWithWebView (url) {
        var webPage = webComponent.createObject (app)
        webPage.closed.connect(webPage.destroy)
        webPage.loadPage (url)
    }


    //--------------------------------------------------------------------------

    property alias messageDialog: messageDialog
    Controls.MessageDialog {
        id: messageDialog

        Material.primary: app.primaryColor
        Material.accent: app.accentColor
        pageHeaderHeight: app.headerHeight

    }

    //--------------------------------------------------------------------------

    property alias disclaimerDialog: disclaimerDialog
    Views.DisclaimerView {
        id: disclaimerDialog
    }

    //--------------------------------------------------------------------------

    property alias networkConfig: networkConfig
    Controls.NetworkConfig {
        id: networkConfig
    }

    property alias parentCache: parentCache
    Controls.NetworkCacheManager {
        id: parentCache

        subFolder: portalSearch.subFolder
    }

    property alias onlineCache: onlineCache
    Controls.NetworkCacheManager {
        id: onlineCache

        subFolder: [portalSearch.subFolder, portalSearch.onlineFolder].join("/")
    }

    property alias offlineCache: offlineCache
    Controls.NetworkCacheManager {
        id: offlineCache

        subFolder: [portalSearch.subFolder, portalSearch.offlineFolder].join("/")
    }

    property alias screenshotsCache: screenshotsCache
    Controls.NetworkCacheManager {
        id: screenshotsCache

        subFolder: [portalSearch.subFolder, portalSearch.screenShotsCacheFolder].join("/")
    }

    property alias offlineMapAreaCache: offlineMapAreaCache
    Controls.NetworkCacheManager {
        id: offlineMapAreaCache
        subFolder: [portalSearch.subFolder, portalSearch.offlineMapAreaFolder].join("/")

    }


    property alias portalSearch: portalSearch
    Controls.PortalSearch {
        id: portalSearch

        isOnline: app.isOnline
        subFolder: app.appId

        onUpdateModel: {
            if(portalSearch.portal.findItemsStatus === Enums.TaskStatusCompleted)
                portalSearch.populateSearcResultsModel(portalSearch.token)

        }

        onFindItemsResultsChanged: {

            /* if(portal)
            {

                if(portal.findItemsStatus === Enums.TaskStatusCompleted)
                    populateSearcResultsModel(portalSearch.token)
            }*/
        }

        function populateSearcResultsModel (token) {
            webMapsModel.clear()
            baseMapsModel.clear()
            localMapPackages.clear()
            onlineMapPackages.clear()
            var flaggedForDeletion = app.settings.value("flaggedForDeletion", "")
            for (var i=0; i<findItemsResults.length; i++) {
                var itemJson = findItemsResults[i]
                if(portal && portal.credential)
                    token = portal.credential.token
                itemJson.token = token
                if (!itemJson) continue

                itemJson.token = token
                switch (itemJson.itemType) {

                case "BaseMap":
                    baseMapsModel.append(itemJson)
                    break

                case "WebMap":
                    if (app.showAllMaps || !app.showOfflineMapsOnly) {
                        itemJson.cardState = -2
                        webMapsModel.append(itemJson)
                    }
                    break
                case "MMPK":

                    if (flaggedForDeletion.indexOf(itemJson.id) !== -1) continue
                    mmpkManager.itemId = itemJson.id
                    if (showPublishedMmpksOnly && !isPublishedMap(itemJson)) continue
                    if (mmpkManager.hasOfflineMap()) {
                        continue
                    } else {
                        if ((app.isSignedIn && (app.showAllMaps || !app.showWebMapsOnly)) || app.skipMmpkLogin) {
                            itemJson.cardState = -1
                            itemJson.needsUnpacking = false
                            onlineMapPackages.append(itemJson)
                        }
                    }
                }

            }

            if (app.showAllMaps || !app.showWebMapsOnly) {
                updateLocalMaps()
                updateLocalMapAreas()
            }

           if(findItemsResults.length === 1)
            {
                if(stackView.get(stackView.depth - 1).objectName !== "mapPage")
                {
                    if(app.itemId > "" )
                    {
                        app.showBackToGalleryButton = false
                        app.openMap(app.webMapsModel.get(0))

                    }
                    else if(app.localMapPackages.count === 0)
                    {
                        app.showBackToGalleryButton = true
                        app.isWebMap = true
                        app.openMap(app.webMapsModel.get(0))

                    }
                }
            }


        }

        function isPublishedMap (item) {
            return item.typeKeywords.indexOf("Published Map") !== -1
        }

        function populateLocalMapPackages()
        {
            localMapPackages.clear()
            updateLocalMaps()
            updateLocalMapAreas()
        }

        function updateLocalMaps () {
            var fileName = "mapinfos.json"


            if (offlineCache.fileInfo.folder.fileExists(fileName)) {
                var fileContent = offlineCache.fileInfo.folder.readJsonFile(fileName)


                localMapPackages.clear()
                if(fileContent.results)
                {
                    for (var i=0; i<fileContent.results.length; i++) {
                        fileContent.results[i].cardState = 0;
                        localMapPackages.append(fileContent.results[i])

                    }
                }
            }


        }

        function removeMapAreaFromLocal(mapareaid)
        {
            var indx = -1
            for(var k=0;k<localMapPackages.count;k++)
            {
                var item = localMapPackages.get(0)
                if(item.id === mapareaid)
                    indx = k
            }
            if(indx > -1)
                localMapPackages.remove(indx)
        }


        function updateLocalMapAreas () {
            var fileName = "mapareasinfos.json"
            //iterate through the subfolders

            var txt=""
            if (offlineMapAreaCache.fileInfo.folder.fileExists(fileName)) {
                var fileContent = offlineMapAreaCache.fileFolder.readJsonFile(fileName)
                var indx = localMapPackages.count
                Object.getOwnPropertyNames(fileContent).forEach(function(val, idx, array) {
                    txt += (val + ' -> ' + fileContent[val] + "\n");
                });

                for (var i=0; i<fileContent.results.length; i++) {

                    var   basemaps =  fileContent.results[i].basemaps.join(",")
                    fileContent.results[i].basemaps = basemaps
                    fileContent.results[i].cardState = 0;

                    localMapPackages.append(fileContent.results[i])

                }
            }
        }





    }
    /* function getFileSize(fileSizeInBytes)
    {
        var i = -1;
        var byteUnits = [strings.kb, strings.mb, strings.gb];
        do {
            fileSizeInBytes = fileSizeInBytes / 1024;
            i++;
        } while (fileSizeInBytes > 1024);

        return !app.isLeftToRight ? "%1 %2".arg(byteUnits[i]).arg(Number(Math.max(fileSizeInBytes, 0.1).toFixed(1)).toLocaleString(Qt.locale(), "f", 0))
                                  : "%1 %2".arg(Number(Math.max(fileSizeInBytes, 0.1).toFixed(1)).toLocaleString(Qt.locale(), "f", 0)).arg(byteUnits[i]);

    }*/

    property alias webMapsModel: webMapsModel
    ListModel {
        id: webMapsModel
    }

    property alias baseMapsModel: baseMapsModel
    ListModel {
        id: baseMapsModel
    }

    property alias localMapPackages: localMapPackages
    ListModel {
        id: localMapPackages
    }

    property alias onlineMapPackages: onlineMapPackages
    ListModel {
        id: onlineMapPackages
    }

    property alias mmpkManager: mmpkManager
    Controls.MmpkManager {
        id: mmpkManager

        rootUrl: "%1/sharing/rest/content/items/".arg(portalUrl)
        subFolder: [app.appId, app.portalSearch.offlineFolder].join("/")
    }

    //---------------------------PORTAL-----------------------------------------


    property Portal portal

    property bool isSignedIn: portal ? portal.loadStatus === Enums.LoadStatusLoaded && (portal.credential && portal.credential.username > "") : false


    onIsSignedInChanged: {
        if (isSignedIn) {
            //app.securedPortal.credential.oAuthClientInfo.refreshTokenExchangeInterval = 2
            //app.securedPortal.credential.onoAuthRefreshTokenChanged.connect(tokenChanged())

            if(portal.credential && portal.credential.authenticationType !== 0)
                portalType = portal.credential.authenticationType;

            if(portalType === 1 )
                setRefreshToken();
            else if(portalType === 2 || portalType === 3)
                setUserNamePswd();

            if(portal.portalUser) {
                portalUserInfo = portal.portalUser;
            }

            refreshTokenTimer.start()
        } else {
            if (!refreshTokenTimer.isRefreshing) {
                clearRefreshToken()
            }
            refreshTokenTimer.stop()

            if((app.portalType !== 2) && (app.portalType !== 3))
                loadPublicPortal()

            portalUserInfo = {};
        }
    }

    Connections {
        target: app
        function onIsOnlineChanged() {
            if(!Networking.isOnline)
            {
                toastMessage.isBodySet = false
                toastMessage.show(qsTr("Your device is now offline."))
            }

        }
    }


    /* the below code is not working because of runtime bug and so commented out*/
    //    Connections{
    //      target:app.portal.credential
    //      onoAuthRefreshTokenChanged:{
    //
    //      }
    //    }

    //    function tokenChanged()
    //    {
    //      console.log("token changed")
    //    }

    function credentialChanged(token)
    {
        return new Promise(function(resolve,reject){

            if(token)
            {
                resolve(token)
            }
            else
            {

                reject(new Error("invalid token"))
            }

        }
        )
    }

    function signOut () {

        if (portal) {
            portal.destroy()
        }
        portal = null
        removeSignInCredentials()
        isUserRoleDetermined = false
        userHasEditRole = false
        if(app.portalType !== 2 && app.portalType !== 3)
            loadPublicPortal ()
    }

    function removeSignInCredentials(){
        AuthenticationManager.credentialCache.removeAndRevokeAllCredentials()
        clearRefreshToken()
    }

    function getAutoSignInProps () {

        return {
            "oAuthRefreshToken": secureStorage.getContent("oAuthRefreshToken"),
            "tokenServiceUrl": app.settings.value("tokenServiceUrl", ""),
            "previousPortalUrl": app.settings.value("portalUrl", ""),
            "clientId": app.settings.value("clientId", ""),
            "username": app.settings.value("username",""),
            "password": secureStorage.getContent("password")
        }
    }

    function setRefreshToken () {
        secureStorage.setContent("oAuthRefreshToken", portal.credential.oAuthRefreshToken)
        app.settings.setValue("tokenServiceUrl", portal.credential.tokenServiceUrl)
        app.settings.setValue("portalUrl", portal.url)
        app.settings.setValue("clientId", portal.credential.oAuthClientInfo.clientId)
        app.settings.setValue("username", portal.portalUser.username)
    }

    function setUserNamePswd () {
        secureStorage.setContent("password", portal.credential.password)
        app.settings.setValue("tokenServiceUrl", portal.credential.tokenServiceUrl)
        app.settings.setValue("portalUrl", portal.url)
        app.settings.setValue("clientId", portal.credential.oAuthClientInfo.clientId)
        if(portal.portalUser)
            app.settings.setValue("username", portal.portalUser.username)
        else
            app.settings.setValue("username", portal.credential.username)

    }

    function clearRefreshToken () {
        secureStorage.clearContent("oAuthRefreshToken")
        secureStorage.clearContent("password")
        app.settings.setValue("tokenServiceUrl", "")
        app.settings.setValue("portalUrl", "")
        app.settings.setValue("clientId", "")
        app.settings.setValue("useBiometricAuthentication", "")
        app.settings.setValue("username","")
    }

    function createCredential (clientId, credentialInfo, tokenServiceUrl) {
        var oAuthClientInfo = ArcGISRuntimeEnvironment.createObject("OAuthClientInfo", {oAuthMode: Enums.OAuthModeUser, clientId: clientId})
        var credential = ArcGISRuntimeEnvironment.createObject("Credential", {oAuthClientInfo: oAuthClientInfo})
        var oAuthRefreshToken = credentialInfo.oAuthRefreshToken;
        var password = credentialInfo.password;
        var username = credentialInfo.username;

        oAuthClientInfo.refreshTokenExpirationInterval = 129600;

        if (tokenServiceUrl > "")
            credential.tokenServiceUrl = tokenServiceUrl;

        if (oAuthRefreshToken > "")
            credential.oAuthRefreshToken = oAuthRefreshToken;
        else{
            if(username > "")
                credential.username = username;
            if(password > "")
                credential.password = password;
        }
        if(credentialInfo.token)
            credential.token = credentialInfo.token
        return credential
    }

    // loading  basemaps from a custom group if provided
    function populateBasemaps()
    {
        if(app.basemapsGroupId > "")
        {
            portalItemTypeCurrentlySearching = "BaseMap"
            portalSearch.findItems(portal, basemapqueryParameters)
        }
        else
        {
            portal.fetchBasemaps()
            searchNextPortalItem()

        }

    }



    function loadSecuredPortal (callback) {
        var _credential
        isPortalSecured = true

        if(!app.portal){
            var autoSignInProps = getAutoSignInProps()
            var failTimes = 0;
            if(app.refreshToken === "")
            {

                if(app.isEmbedded)
                {
                    var credentialInfo = {
                        password:autoSignInProps.password,
                        oAuthRefreshToken:autoSignInProps.oAuthRefreshToken,
                        username:autoSignInProps.username,

                    }
                    _credential = createCredential(app.clientId, credentialInfo, autoSignInProps.tokenServiceUrl)

                    app.portal = ArcGISRuntimeEnvironment.createObject("Portal", {url: portalUrl, credential: _credential, sslRequired: false})

                }
                else
                {
                    var pwcredentialInfo = {
                        password:app.userpassword,
                        token:app.token,
                        //oAuthRefreshToken:autoSignInProps.oAuthRefreshToken,
                        username:app.userName,

                    }
                    var pwcredential = createCredential(app.clientId, pwcredentialInfo, app.portalUrl)

                    app.portal = ArcGISRuntimeEnvironment.createObject("Portal", {url: app.portalUrl, credential: pwcredential, sslRequired: false})


                }


            }
            else
            {
                var _credentialInfo = {
                    // password:app.password,
                    oAuthRefreshToken:app.refreshToken,
                    // username:app.userName,
                    token: app.token
                }
                _credential = createCredential(app.clientId, _credentialInfo, app.portalUrl)

                app.portal = ArcGISRuntimeEnvironment.createObject("Portal", {url: app.portalUrl, credential: _credential, sslRequired: false})


            }

            if(app.portal.credential)
            {

                if (app.portal.credential.authenticationType !== 0) {

                    app.portalType = app.portal.credential.authenticationType;
                    if(app.portalType === 2 || portalType === 3){
                        supportSecuredMaps = true;
                        isIWAorPKI = true;

                        //if the platform is windows, the app will automatically sign you in using iwa, so no need to have skip button
                        if (Qt.platform.os === "windows") enableAnonymousAccess = false;
                    }
                }
            }

            app.portal.onLoadStatusChanged.connect(function(){


                if(!app.portal.credential)
                    app.portal.credential = _credential

                switch (app.portal.loadStatus) {
                case Enums.LoadStatusFailedToLoad:

                    if(failTimes<3){

                        if(signInPage && !signInPage.closeButtonClicked)
                        {
                            portal.retryLoad();
                            ++failTimes;
                        }
                        else
                            signOut()
                    }else {

                        if(portal.error.code === 404)
                            messageDialog.show(qsTr("Error"),unableToAccessPortal);
                        app.portal = null
                        if(stackView.depth > 1)
                            signOut()
                        else
                            clearRefreshToken()

                        if (hasVisibleSignInPage()) {
                            destroySignInPage()
                        }
                    }
                    break
                case Enums.LoadStatusLoaded:

                    portalSearch.clearResults()
                    webMapsModel.clear()
                    localMapPackages.clear()
                    onlineMapPackages.clear()
                    if(app.portal.credential)
                    {



                        var promiseToFindPortalItems = credentialChanged(app.portal.credential.token)

                        promiseToFindPortalItems.then(function(token){
                            if(!app.portal.portalUser)
                            {
                                portal.load()
                                return
                            }
                            else{

                                portalUserInfo = app.portal.portalUser;
                                setUserNamePswd ()
                                portal.onFindItemsStatusChanged.connect(function(){
                                    if(portal.findItemsStatus === Enums.TaskStatusCompleted)
                                    {
                                        portalSearch.searchEventHandler();

                                    }
                                })
                                if(!app.isAddLayerMode){
                                    if (app.showAllMaps){
                                        app.portalItemTypesToSearch.push("MMPK")
                                        app.portalItemTypesToSearch.push("WebMap")
                                    }
                                    else if(app.showOfflineMapsOnly)
                                        app.portalItemTypesToSearch.push("MMPK")
                                    else
                                        app.portalItemTypesToSearch.push("WebMap")
                                    populateBasemaps()

                                }
                                else
                                {
                                    portal.fetchBasemaps()
                                    app.openEmptyMap()
                                }



                            }



                        }, function(err){
                            clearRefreshToken()
                            messageDialog.show(qsTr("Fetch Basemaps"),qsTr("Invalid Token"))
                            messageDialog.connectToAccepted(function () {
                                if(!app.isEmbedded  && app.parent)
                                    app.parent.exitApp()

                            })


                        }


                        )
                    }
                    else
                    {

                        app.portal.load()

                    }
                    if (app.settings.value("useBiometricAuthentication", "") !== true &&
                            app.settings.value("useBiometricAuthentication", "") !== false &&
                            app.canUseBiometricAuthentication && app.isEmbedded) {
                        biometricController.showBiometricDialog()
                    }
                    break
                }

            })

            portalSearch.clearResults()
            app.portal.load()

        }
        else
        {
            if(!app.isAddLayerMode)
            {
                portalSearch.findItems(portal, queryParameters)
                portal.fetchBasemaps()

            }
            else
            {
                portal.fetchBasemaps()
                app.openEmptyMap()
            }

        }

        if (callback) callback()
    }


    function searchNextPortalItem()
    {
        if(portalItemTypesToSearch.length > 0)
            var item = portalItemTypesToSearch.pop()
        if(item === "MMPK")
        {
            portalItemTypeCurrentlySearching = "MMPK"
            portalSearch.findItems(portal, queryParametersMMPK)
        }
        else if (item === "WebMap")
        {
            portalItemTypeCurrentlySearching = "WebMap"
            portalSearch.findItems(portal, queryParameters)
        }

    }



    Connections {
        target: controller
        function onAuthenticationChallenge(challenge){
            if(!isSignInPageOpened)
            {
                //if it is IWA then it will throw challenge and if we try to load publicPortal then cancel load
                if(isPortalLoading && !isPortalSecured)
                {
                    challenge.cancel()
                    app.portal.cancelLoad()
                }

            }
        }
    }



    function loadPublicPortal () {
        //portalType = ""
        isPortalSecured = false
        isPortalLoading = true

        var failTimes = 0;
        if (portal) portal.destroy()
        portalSearch.clearResults()
        app.portal = ArcGISRuntimeEnvironment.createObject("Portal", {url: portalUrl})
        app.portal.onLoadStatusChanged.connect(function(){
            if (app.portal.credential)
                if (app.portal.credential.authenticationType!== 0) {
                    app.portalType = app.portal.credential.authenticationType;
                    if(app.portalType === 2 || portalType === 3){
                        supportSecuredMaps = true;
                        isIWAorPKI = true;

                        //if the platform is windows, the app will automatically sign you in using iwa, so no need to have skip button
                        if (Qt.platform.os === "windows") enableAnonymousAccess = false;

                    }
                }

            switch (portal.loadStatus) {
            case Enums.LoadStatusFailedToLoad:
                if(failTimes <3){
                    portal.retryLoad();
                    ++failTimes;
                }else{

                    //iwa or pki but has network error
                    if(portalType === 0){
                        supportSecuredMaps = true;
                        isIWAorPKI = true;
                    }
                }

                break
            case Enums.LoadStatusLoaded:

                portalSearch.clearResults()
                webMapsModel.clear()
                localMapPackages.clear()
                onlineMapPackages.clear()
                isPortalLoading = false
                portal.onFindItemsStatusChanged.connect(function(){
                    if(portal.findItemsStatus === Enums.TaskStatusCompleted)
                    {
                        portalSearch.searchEventHandler();

                    }
                })
                if(!isIWAorPKI)
                {
                    if (app.showAllMaps){


                        app.portalItemTypesToSearch.push("MMPK")
                        app.portalItemTypesToSearch.push("WebMap")
                    }
                    else if(app.showOfflineMapsOnly)
                        app.portalItemTypesToSearch.push("MMPK")

                    else
                        app.portalItemTypesToSearch.push("WebMap")
                    populateBasemaps()

                }

                break
            }
        })
        app.portal.load();
    }



    PortalQueryParametersForItems {
        id: basemapqueryParameters

        types: {

            return [Enums.PortalItemTypeWebMap]

        }
        groupId:app.basemapsGroupId
        searchString:""
        sortOrder:app.portalSortOrder //Enums.PortalQuerySortOrderDescending
        sortField:app.portalSortField // "modified"
        //limit: app.maxNumberOfQueryResults
        //searchPublic: true
    }




    PortalQueryParametersForItems {
        id: queryParameters

        types: {
            if (app.showAllMaps) {
                return [Enums.PortalItemTypeWebMap]
            } else if (app.showOfflineMapsOnly) {
                return [Enums.PortalItemTypeMobileMapPackage]
            } else {
                return [Enums.PortalItemTypeWebMap]
            }
        }
        searchString: app.searchQuery
        sortOrder:app.portalSortOrder //Enums.PortalQuerySortOrderDescending
        sortField:app.portalSortField // "modified"
        limit: app.maxNumberOfQueryResults
        //        searchPublic: true
    }

    PortalQueryParametersForItems {
        id: queryParametersMMPK

        types: {

            return [Enums.PortalItemTypeMobileMapPackage]

        }
        searchString: app.searchQuery ? app.searchQuery:"mmpk"
        sortOrder: Enums.PortalQuerySortOrderDescending
        sortField: "modified"
        limit: app.maxNumberOfQueryResults
        //        searchPublic: true

    }

    QueryParameters {
        id: spatialqueryParameters
        //returnGeometry: true
        //whereClause:
        //geometry:
    }

    function setPortalUrl(){
        var _portalUrl = app.info.propertyValue("portalUrl");
        if(_portalUrl === "") _portalUrl = "https://www.arcgis.com";

        _portalUrl = _portalUrl.toLowerCase();
        if (_portalUrl.startsWith('http://'))
            _portalUrl = _portalUrl.replace('http://','https://');
        _portalUrl.trim();

        if(_portalUrl[_portalUrl.length-1]==="/")
        {_portalUrl=_portalUrl.substring(0,_portalUrl.length-1);}
        if(_portalUrl.substring(_portalUrl.length-4)==="home")
        {_portalUrl=_portalUrl.substring(0,_portalUrl.length-5);}

        app.portalUrl = _portalUrl;
    }

    function getThumbnailUrl (portalUrl, portalItem, token) {
        if(portal)
            token = portal.credential.token
        try {
            if (portalItem.thumbnailUrl) return portalItem.thumbnailUrl
        } catch (err) {}

        var imgName = portalItem.thumbnail
        if (!imgName) {
            return ""
        }
        var urlFormat = "%1/sharing/rest/content/items/%2/info/%3%4",
        prefix = ""
        if (token) {
            prefix = "?token=%1".arg(token)
        }
        return urlFormat.arg(portalUrl).arg(portalItem.id).arg(imgName).arg(prefix)
    }

    //--------------------------------------------------------------------------

    Controls.SecureStorageHelper {
        id: secureStorage
    }

    //------------------BIOMETRIC AUTHENTICATION--------------------------------

    Connections {
        id: biometricController

        property var biometricDialogs: []
        readonly property string kTouchIdFailed: qsTr("Unable to verify using Touch ID. Please sign in again.")
        readonly property string kFaceIdFailed: qsTr("Unable to verify using Face ID. Please sign in again.")

        target: BiometricAuthenticator

        function onAccepted() {
            if(app.portal)
                app.portal.destroy()
            loadSecuredPortal()
        }

        function onRejected() {
            signOut()
            clearRefreshToken()
            messageDialog.show("", app.hasFaceID ? biometricController.kFaceIdFailed : biometricController.kTouchIdFailed)
        }

        function showBiometricDialog () {
            biometricController.destroyBiometricDialogs()
            var biometricDialog = biometricDialogComponent.createObject(app)
            biometricDialog.open()
            biometricController.biometricDialogs.push(biometricDialog)
        }

        function destroyBiometricDialogs () {
            for (var i=0; i<biometricController.biometricDialogs.length; i++) {
                if (biometricController.biometricDialogs[i]) {
                    biometricController.biometricDialogs[i].destroy()
                }
            }
            biometricController.biometricDialogs = []
        }
    }

    Component {
        id: biometricDialogComponent

        Controls.MessageDialog {
            id: biometricDialog

            readonly property string kEnableTouchId: Qt.platform.os === "ios" || Qt.platform.os === "osx" ? qsTr("Enable Touch ID to sign in?") : qsTr("Enable Fingerprint Reader to sign in")
            readonly property string kEnableFaceId: qsTr("Enable Face ID to sign in?")
            readonly property string kTouchIdEnabled: qsTr("Touch ID enabled. Sign out to disable.")
            readonly property string kFaceIdEnabled: qsTr("Face ID enabled. Sign out to disable.")

            Material.primary: app.primaryColor
            Material.accent: app.accentColor
            title: app.hasFaceID ? kEnableFaceId : kEnableTouchId
            text: qsTr("Once enabled, the app will provide an easy and secured way to access your maps. You can always sign out at anytime to disable this feature.")
            standardButtons: Dialog.NoButton

            footer: DialogButtonBox {
                Button {
                    text: qsTr("Cancel")
                    Material.background: "transparent"
                    DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                }
                Button {
                    text: qsTr("Enable")
                    Material.background: "transparent"
                    DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                }
            }

            onAccepted: {
                app.settings.setValue("useBiometricAuthentication", true)
                toastMessage.show(app.hasFaceID ? kFaceIdEnabled : kTouchIdEnabled)
                biometricDialog.destroy()
            }

            onRejected: {
                app.settings.setValue("useBiometricAuthentication", false)
                biometricDialog.destroy()
            }
        }
    }

    //--------------------------------------------------------------------------

    Controls.ToastDialog {
        id: toastMessage
        isBodySet: false

        enter: Transition {
            NumberAnimation { property: "y"; from:parent.height; to:parent.height - (toastMessage.isBodySet?units(76):units(56))}
        }
        exit:Transition {
            NumberAnimation { property: "y"; from:parent.height - (toastMessage.isBodySet?units(76):units(56)); to:parent.height}
        }

        textColor: app.titleTextColor
    }



    //--------------------------------------------------------------------------
    Component{
        id:customAuth
        Views.CustomAuthenticationView {
            //TODO: This will be used to replace the runtime authentication popup. It has a consistent material look
            id: loginDialog
        }
    }

    property var signInPages: []
    Component {
        id: signInPageComponent

        Views.SignInPage{

            portal: app.portal
            iconSize: app.iconSize
            headerHeight: app.headerHeight

            onCloseButtonClickedChanged: {
                /*if (closeButtonClicked) {
                    signOut()
                }*/
            }


        }



        //                Views.OAuth2View {
        //                    id: signInPage

        //                    portal: app.portal
        //                    iconSize: app.iconSize
        //                                headerHeight: app.headerHeight
        //                    onCloseButtonClickedChanged: {
        //                        if (closeButtonClicked) {
        //                            signOut()
        //                        }
        //                    }

        //                    onOpened: {
        //                        loadSecuredPortal()
        //                    }
        //                }
    }

    function hasVisibleSignInPage () {
        for (var i=0; i<signInPages.length; i++) {
            if (signInPages[i].visible) return true
        }
        return false
    }

    function createSignInPage () {
        signInPage = signInPageComponent.createObject(app)
        signInPage.onClosed.connect(function () {
            if (app.hasVisibleSignInPage()) {
                destroySignInPage()
            }
        })
        signInPages.push(signInPage)
        signInPage.open()
    }

    function destroySignInPage () {
        for (var i=0; i<signInPages.length; i++) {
            signInPages[i].visible = false
            signInPages[i].destroy()
        }
        signInPages = []
    }

    //--------------------------------------------------------------------------

    signal backButtonPressed ()

    focus: true

    Keys.onPressed: {
        if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
            event.accepted = true
            backButtonPressed ()
        }
    }

    onBackButtonPressed: {
        if (aboutAppPage.visible) {
            aboutAppPage.close()
        } else if (hasVisibleSignInPage()) {
            destroySignInPage()
        }
    }

    //--------------------------------------------------------------------------

    property alias refreshTokenTimer: refreshTokenTimer
    Timer {
        id: refreshTokenTimer

        property bool isRefreshing: false
        property date lastRefreshed: new Date()

        signal tokenRefreshed ()

        onTokenRefreshed: {
            lastRefreshed = new Date()
        }

        interval: 1800000 // 30 minutes
        running: false
        repeat: true

        onTriggered: {
            refreshToken ()
        }

        function refreshToken () {
            isRefreshing = true
            getNewToken(function () {
                isRefreshing = false
                tokenRefreshed()
            })

        }

        function getNewToken(){
            var autoSignInProps = getAutoSignInProps()

            var credentialInfo = {
                password:autoSignInProps.password,
                oAuthRefreshToken:autoSignInProps.oAuthRefreshToken,
                username:autoSignInProps.username
            }

            var credential = createCredential(app.clientId, credentialInfo, autoSignInProps.tokenServiceUrl)

            portal.credential = credential;

            if(portalType === 1 )
                setRefreshToken();
            else if(portalType === 2 || portalType === 3)
                setUserNamePswd();

        }
    }

    Connections {
        target: Qt.application

        function onStateChanged() {
            switch (Qt.application.state) {
            case Qt.ApplicationActive:
                var autoSignInProps = getAutoSignInProps()
                if (autoSignInProps.oAuthRefreshToken && autoSignInProps.tokenServiceUrl && app.supportSecuredMaps) {
                    if (!refreshTokenTimer.isRefreshing && (new Date() - refreshTokenTimer.lastRefreshed >= refreshTokenTimer.interval)) {
                        refreshTokenTimer.refreshToken()
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        initialize()
        Nashelper.testHelper("Hello World")
    }

    function setSystemProps () {
        var sysInfo = typeof AppFramework.systemInformation !== "undefined" && AppFramework.systemInformation ? AppFramework.systemInformation : ""
        if (!sysInfo) return
        if (Qt.platform.os === "ios" && sysInfo.hasOwnProperty("unixMachine")) {
            var unixName = sysInfo.unixMachine;

            switch(unixName){
                //iPhone X
            case "iPhone10,3":
            case "iPhone10,6":
                //iPhone XS, XR
            case "iPhone11,2":
            case "iPhone11,4":
            case "iPhone11,6":
            case "iPhone11,8":
                //iPhone 11
            case "iPhone12,1":
            case "iPhone12,3":
            case "iPhone12,5":
                //iPhone 12
            case "iPhone13,1":
            case "iPhone13,2":
            case "iPhone13,3":
            case "iPhone13,4":
                app.isIphoneX = true;
            }
        } else if (Qt.platform.os === "windows") {
            var kernelVersionPattern = /^6\.1/
            var osVersionPattern = /^7/
            isWindows7 = kernelVersionPattern.test(AppFramework.kernelVersion) && osVersionPattern.test(AppFramework.osVersion)
        }
    }

    function initialize () {
        var isSignedOut = false
        if(StatusBar.supported && Qt.platform.os === "ios") {
            StatusBar.theme = StatusBar.Dark;
        }
        if(isEmbedded)
        {
            setPortalUrl();

            var autoSignInProps = getAutoSignInProps()
        }

        setSystemProps()

        if (app.isOnline && isEmbedded)
        {
            if (app.supportSecuredMaps && autoSignInProps.username > "" && (app.portalUrl.toString() !== app.settings.value("portalUrl") || autoSignInProps.clientId !== app.clientId)) {

                //signOut()
                AuthenticationManager.credentialCache.removeAllCredentials()
                clearRefreshToken()
                isUserRoleDetermined = false
                isSignedOut = true
            }
            else
            {
                //check whether autosign in is possible
                if ((autoSignInProps.oAuthRefreshToken > ""||autoSignInProps.password > "") && autoSignInProps.tokenServiceUrl > "" && autoSignInProps.previousPortalUrl === app.portalUrl.toString()) {
                    if (app.isOnline && app.settings.value("useBiometricAuthentication", false) && app.canUseBiometricAuthentication) {
                        if (Qt.platform.os === "osx") {
                            BiometricAuthenticator.message = qsTr("authenticate")
                        } else {
                            BiometricAuthenticator.message = qsTr("Please authenticate to proceed.")
                        }
                        BiometricAuthenticator.authenticate()
                    } else {

                        loadSecuredPortal()
                    }
                } else {
                    if(!isSignedOut)
                    {
                        AuthenticationManager.credentialCache.removeAllCredentials()

                        clearRefreshToken()
                        // loadSecuredPortal()

                    }

                }
            }


        }
        else if(app.isOnline && !isEmbedded)
        {
            loadSecuredPortal()
        }



        app.fontScale = app.settings.value("fontScale", 1.0)

        if (!isOnline) {
            portalSearch.populateLocalMapPackages()

        }
    }

    //--------------------------------------------------------------------------
    function getSortOrderAsInt(name)
    {
        let sortorder = app.info.propertyValue(name)
        if(sortorder > "")
        {
            sortorder = sortorder.toLowerCase()
            if(sortorder === "asc")
                return Enums.SortOrderAscending
            else if(sortorder === "desc")
                return Enums.SortOrderDescending
            else
                return Enums.SortOrderDescending

        }
        else
            return Enums.SortOrderDescending

    }



    function getProperty (name, fallback) {
        if (!fallback && typeof fallback !== "boolean") fallback = ""
        return app.info.propertyValue(name, fallback) //|| fallback
    }

    function getClientId (fallback) {
        if (!fallback) fallback = ""
        try {
            return app.info.json.deployment.clientId
        } catch (err) {
            return fallback
        }
    }

    function units (num) {
        return num ? num * AppFramework.displayScaleFactor : num
    }

    //--------------------------------------------------------------------------

    function randomColor (colortype) {
        var types = {
            "primary": ["#4A148C", "#0D47A1", "#004D40", "#006064", "#1B5E20", "#827717", "#3E2723"],
            "background": ["#F5F5F5", "#EEEEEE"],
            "foreground": ["#22000000"],
            "accent": ["#FF9800", "yellow", "red"]
        },
        type = types[colortype]
        return type[Math.floor(Math.random() * type.length)]
    }

    function isFieldVisible(fields,fieldName)
    {
        for(var k=0;k< fields.length; k++)
        {
            var field = fields[k]
            var name = ""
            if(field.name)
                name = field.name
            else if(field.fieldName)
                name = field.fieldName


            if(name.toUpperCase() === fieldName.toUpperCase())
            {
                if(field.visible)
                    return field.visible
                else
                    return true

            }
        }
        return true
    }

    function getFieldLabelFromPopup(featureTable,field)
    {
        try{
            if(featureTable  && featureTable.popupDefinition)
            {
                let popupFields = featureTable.popupDefinition.fields
                for(let p=0; p<popupFields.length;p++)
                {
                    let _fld = popupFields[p]
                    if(_fld.fieldName === field && _fld.label > "")
                    {
                        field = _fld.label
                        return field
                    }
                }
            }
            if(featureTable && featureTable.fields)
            {
                let fields = featureTable.fields
                field = app.getFieldAlias(fields,field)
            }

            return field
        }
        catch(ex)
        {
            console.error("Error:",ex.toString())
            return field
        }
    }



    function getFieldAlias(fields,fieldName)
    {
        for(var k=0;k< fields.length; k++)
        {
            var field = fields[k]
            var name = ""
            if(field.name)
                name = field.name
            else if(field.fieldName)
                name = field.fieldName


            if(name.toUpperCase() === fieldName.toUpperCase())
            {
                if(field.label)
                    return field.label
                else
                {
                    if(field.alias)
                        return field.alias
                }

            }
        }
        return fieldName
    }

    function getFieldType(fields,fieldName)
    {
        for(var k=0;k< fields.length; k++)
        {
            var field = fields[k]
            var name = ""
            if(field.name)
                name = field.name
            else if(field.fieldName)
                name = field.fieldName


            if(name.toUpperCase() === fieldName.toUpperCase())
            {
                return field.fieldType

            }
        }
        return null
    }

    function getCodedValue(fields,fieldName,fieldValue)
    {
        for(var k=0;k< fields.length; k++)
        {
            var field = fields[k]
            if(field.name === fieldName)
            {
                var domain = field.domain
                if(domain && domain.codedValues)
                {
                    var codedValues = domain.codedValues

                    for(var x=0;x<codedValues.length;x++)
                    {
                        if(codedValues[x].code  ===  fieldValue)
                        {
                            var codedValueObj = codedValues[x]
                            return codedValueObj.name
                        }
                    }


                }
                else
                    return fieldValue

            }
        }
        return fieldValue
    }

    function getFormattedFieldValue(_fieldVal,fieldType){
        let isNotNumber = isNaN(_fieldVal)
        let formattedVal = "";

        if(_fieldVal && !isNotNumber){
            if ( fieldType === Enums.FieldTypeFloat32 || fieldType === Enums.FieldTypeFloat64 ){
                _fieldVal = ( Math.round(parseFloat(_fieldVal) * 100) ) / 100;
            }

            formattedVal = _fieldVal.toLocaleString(Qt.locale());

            if (formattedVal)
                _fieldVal = formattedVal
        }

        //check if it is a date
        if(fieldType === Enums.FieldTypeDate){
            let dt = Date.parse(_fieldVal)

            if (dt){
                let date_ob = new Date(dt)
                let _datepart = date_ob.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
                let timepart = date_ob.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)

                _fieldVal = _datepart + ", " + timepart
            }
        }

        return _fieldVal
    }
    //--------------------------------------------------------------------------

    function getDomainCodeFromFeatureTable(layerServiceTable,fieldName,fieldValue){
        //let lyr = layerManager.getLayerById(lyrid)
        //let layerServiceTable = lyr.featureTable
        if(layerServiceTable){
            let fields = layerServiceTable.fields
            if(fieldName === layerServiceTable.typeIdField)
            {
                return getCodeFromFeatureTypeName(layerServiceTable,fieldValue)
            }
            else

                return getCodeIfDomain(fields,fieldName,fieldValue)
        }
        else
            return fieldValue
    }

    function getCodeIfDomain(fields,fieldName,fieldValue)
    {
        for(var k=0;k< fields.length; k++)
        {
            let field = fields[k]
            if(field.name === fieldName)
            {
                let domain = field.domain
                if(domain && domain.codedValues)
                {
                    let codedValues = domain.codedValues

                    for(let x=0;x<codedValues.length;x++)
                    {
                        if(codedValues[x].name.toUpperCase()  ===  fieldValue.toUpperCase())
                        {
                            let codedValueObj = codedValues[x]
                            return codedValueObj.code
                        }
                    }


                }
                else
                    return fieldValue

            }
        }
        return fieldValue
    }



    function getCodeFromFeatureTypeName(layerServiceTable,fieldValue)
    {
        let featureTypes = layerServiceTable.featureTypes
        for(let k=0;k<featureTypes.length; k++)
        {
            let _type = featureTypes[k]
            let _templates = _type.templates
            if(_templates.length)
            {
                let templateType = _templates[0].name
                if(templateType === fieldValue)
                    return _type.typeId
            }
            else
            {

                if(_type.name === fieldValue)
                {
                    return _type.typeId
                }
            }
        }
        return fieldValue
    }




}
