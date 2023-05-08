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
import QtSensors 5.3
import QtPositioning 5.3
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1
import QtQuick.Window 2.12
//import QtMultimedia 5.12

import Esri.ArcGISRuntime 100.14

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0

import "../controls" as Controls
import "../../Components/Identify"
import "../../Components/Legend"

import "../../Components/Editor"
import "../../Components/Editor/Layout" as Sketch

import "../../Components/MapArea" as MapArea
import "../../Components/FloorAware"
import "../../utility"
import "../views" as Views

Controls.BasePage {
    id: mapPage

    LayoutMirroring.enabled: app.isRightToLeft
    LayoutMirroring.childrenInherit: app.isRightToLeft

    property string featureCollectionItemId :""
    property var  _featureCollection;
    property var  _featureCollectionLayer;
    property var _portalItem
    property var mapLayers:[]
    property var opLayers:[]


    property alias docksource:offlineLoader.source
    property var portalItem
    property var mapProperties: Object
    property var portalItem_main
    property var mapProperties_main: Object

    readonly property string kDrawPath: qsTr("Tap on the map to draw a path.")
    readonly property string kDrawArea: qsTr("Tap on the map to draw an area.")
    readonly property string kClear: qsTr("CLEAR")
    readonly property string kDistance: qsTr("Distance")
    readonly property string kArea: qsTr("Area")
    readonly property string kMeasure: qsTr("Measure")
    readonly property string kBasemaps: qsTr("BaseMaps")

    property bool showMeasureTool: false
    property string captureType: "line"
    property int attachqueryno:0
    property bool _getAttachmentCompleted:false
    property bool isAttachmentPresent:false
    property bool isGetAttachmentRunning:false
    property var mapAreasModel:ListModel{}
    property Geodatabase offlineGdb:null
    property var mapAreaslst:[]
    property var  offlineSyncTask:null
    property var offlinemapSyncJob:null
    property var existingmapareas:null
    property bool updatesAvailable:false
    property bool hasMapArea:false
    property bool showUpdatesAvailable:false
    property bool isMapAreaOpened:false
    property var mapAreaGraphicsArray:[]
    property bool updateMapArea:false
    property bool comingFromMapArea:false
    property int mapAreasCount:0
    property bool hasTransportationNetwork:false
    property string defaultAnchor:app.isLeftToRight?"anchorright":"anchorleft"

    property var processedLayers : []
    property var uidRequested:[]
    property var screenshotsCount: screenShotsView.screenShots.count > 0?screenShotsView.screenShots.count:0
    property alias saveBusyIndicator:busyIndicator//savebusyIndicator
    // property bool hasEdits:false
    property bool backToGallery:false
    property var layersToSearch:[]
    property var definitionQueryDic:({})

    property bool isUpdatingContentsModel:false
    property bool isSortingLegend:false
    // property bool mapInitialized:false

    property var oplayersCopy:[]
    property var layerLegendDic: ({})
    property var visibleLayersList : []
    //property ListModel layerList: ListModel {}
    property var layerList
    property bool isScaleChanged:false
    property bool canPopulateLegendOnZoom:true

    property var mymap
    //<lyrid_sublayerid,minScale>
    property var minScaleDictionary:({})
    //<lyrid_sublayerId, maxScale>
    property var maxScaleDictionary:({})
    property var listOfLayersToProcess:[]
    property int layersNotLoadedAtStart:0
    property int countOflegendItemsPopulatedInTree:0

    property var editableLayerList:[]
    property bool isInShapeCreateMode:false
    property bool isInShapeEditMode:false
    property bool isShowingCreateNewFeature:false
    property alias newFeatureEditBtn:createNewFeatureBtn
    property bool isMapLoaded:false
    property bool savingInProgress:false
    property bool isEditingExistingFeature:false
    property bool canDeleteSketchVertex:false
    property var featureTableDictionary:({})
    property bool startShowScale:false

    signal mapSyncCompleted(string title)
    signal cacheCleared()
    signal getAttachmentCompleted()

    onCacheCleared: {
        for(var p=0;p < mapAreasModel.count;p++)
        {
            mapAreasModel.setProperty(p,"isPresent",false)

        }

    }
    Connections {
        target: AuthenticationManager

        function onAuthenticationChallenge(challenge){
            app.authChallenge = challenge;

            var _type = Number(challenge.authenticationChallengeType);

        }
    }


    function showFeatureAttributeForm(hasAttachments){

        let tabString =  `${app.tabNames.kFeatures}`
        if(hasAttachments)
            tabString =  `${app.tabNames.kFeatures},${app.tabNames.kAttachments}`
        //identifyBtn.populateTabHeaders(isInEditMode,true)
        var tabnames = identifyBtn.populateTabHeaderModel(tabString)
        app.isInEditMode = true
        panelDockItem.childItem = ""
        panelDockItem.addDock("identify",tabString)
        //newFeatureEditBtn.visible = false
    }


    Component.onCompleted: {
        processedLayers = []

        more.updateMenuItemsContent();

    }

    BusyIndicator {
        id: busyIndicator
        Material.primary: app.primaryColor
        Material.accent: app.accentColor
        visible: ((mapView.drawStatus === Enums.DrawStatusInProgress) && (mapView.mapReadyCount < 1)) || (mapView.identifyLayersStatus === Enums.TaskStatusInProgress) || identifyInProgress === true ||  !mapInitialized
        width: app.iconSize
        height: app.iconSize
        anchors.centerIn: mapView//parent

    }


    onGetAttachmentCompleted: {

        isGetAttachmentRunning = false
        busyIndicator.visible=false
        //identifyInProgress = false
        if (identifyManager.popupManagers.length) {
            identifyBtn.checked = true
            identifyBtn.currentEditTabName = "FEATURES"

            identifyBtn.currentEditTabIndex = 0

        }


        // _getAttachmentCompleted = true
        if(!app.isInEditMode)
            identifyBtn.populateTabHeaders()
        //isGetAttachmentRunning = false

        if(identifyManager.populateModelCompleted)
        {

            exitEditModeInProgress = false

            mapView.identifyProperties.isModelBindingInProgress = false
        }



    }




    Item {
        id: screenSizeState

        states: [
            State {
                name: "SMALL"
                when: !isLandscape
            }
        ]

        onStateChanged: {
            more.updateMenuItemsContent()
        }
    }

    header: ToolBar {
        id: mapPageHeader
        height:app.isNotchAvailable()? app.headerHeight + app.notchHeight : app.headerHeight
        topPadding:app.isNotchAvailable() ? (app.isPortrait?app.notchHeight:0):0

        LayoutMirroring.enabled: !isLeftToRight
        LayoutMirroring.childrenInherit: !isLeftToRight

        RowLayout {
            id:toolbarrow
            anchors {
                fill: parent
                rightMargin: app.isLandscape ? app.widthOffset: 0
                leftMargin: app.isLandscape ? app.widthOffset: 0
            }


            Controls.Icon {
                id: menuIcon
                iconSize: 6 * app.baseUnit

                visible:app.isEmbedded //!panelPage.fullView
                imageSource: mapProperties.isMapArea && portalItem_main?"../images/back.png":"../images/menu.png"

                onClicked: {
                    if(!portalItem_main)
                    {
                        //if(!mapProperties.isMapArea)
                        sideMenu.toggle()
                    }
                    else
                    {
                        comingFromMapArea = true
                        //panelDockItem.removeDock()
                        // hasMapArea = true
                        portalItem = portalItem_main
                        mapProperties = mapProperties_main
                        if(panelPageLoader.item)
                        {
                            panelPageLoader.item.mapTitle = ""
                            panelPageLoader.item.owner = ""
                            panelPageLoader.item.modifiedDate = ""
                        }
                        hasMapArea = true
                        portalItem_main = null
                        mapProperties_main = null
                        // panelDockItem.removeDock()
                        mapareasIcon.checked = false

                        //stackView.pop()
                        //load the previous map with map area

                    }
                }
            }

            Controls.Icon {
                id: backIcon

                visible:!app.isEmbedded
                imageSource: "../images/back.png"

                onClicked: {
                    if(!app.isEmbedded  && app.parent)
                        app.parent.exitApp(app.portal)


                }
            }




            Label{
                text:app.kMapArea
                visible:mapProperties.isMapArea !== undefined  && portalItem_main ? mapProperties.isMapArea:false
                elide: Text.ElideRight
                Layout.preferredWidth: 80 * app.scaleFactor
                font.bold: true
            }

            Controls.SpaceFiller {
            }

            RowLayout {
                id: mapTools
                visible: mapView.map ? (mapView.map.loadStatus === Enums.LoadStatusLoaded) : false
                Layout.fillHeight: true
                Layout.fillWidth: true
                opacity: app.isInEditMode?0.5:1
                enabled: app.isInEditMode?false:true

                Controls.Icon {
                    id: searchIcon
                    visible:(mmpk.loadStatus !== Enums.LoadStatusLoaded && mapProperties.isMapArea === undefined) || (mapProperties.isMapArea !== undefined && mapProperties.isMapArea === false)
                    imageSource: "../images/search.png"
                    checkable: true


                    onCheckedChanged: {
                        if (checked) {
                            //identifyProperties.clearHighlightInLayer()
                            offlineRouteDockItem.visible=false


                            pageView.hidePanelItem()
                            pageView.hideOfflineRoute()
                            pageView.hideSpatialSearch()
                            toolBarBtns.uncheckButtons()
                            searchDockItem.addDock()
//                            moreIcon.checked = false
                            offlineRouteIcon.checked = false

                        } else {
                            searchDockItem.removeDock()

                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        visible: showMeasureTool
                        onClicked: {
                            parent.checked = true
                        }
                    }
                }


                Controls.Icon {
                    id: offlineRouteIcon
                    visible:hasTransportationNetwork


                    objectName: "offlineroute"
                    imageSource: "../images/baseline_directions_white_48dp.png"
                    checkable: app.isInEditMode?false:true

                    onCheckedChanged: {
                        if(checked)
                        {

                            toolBarBtns.uncheckAll()
                            pageView.hidePanelItem()

                            pageView.hideSearchItem()
                            pageView.hideSpatialSearch()
                            searchIcon.checked = false

                        }

                        if (checked) {
                            pageView.showOfflineRoute()

                        } else {
                            offlineRouteDockItem.visible=false
                            pageView.hideOfflineRoute()
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        visible:true
                        onClicked: {

                            parent.checked = !parent.checked

                        }
                    }
                }


                Controls.Icon {
                    id: spatialSearchIcon

                    objectName: "spatialSearch"
                    imageSource: "../images/spatialsearch.png"
                    checkable: true//app.isInEditMode?false:true
                    rotation: 0
                    maskColor: "white"


                    onCheckedChanged: {

                        if(checked){

                            offlineRouteDockItem.visible=false
                            panelDockItem.visible = false
                            pageView.hidePanelItem()
                            pageView.hideOfflineRoute()
                            pageView.hideSearchItem()
                            toolBarBtns.uncheckButtons()
                            offlineRouteIcon.checked = false
                            mapView.populateVisibleLayers()

                            legendManager.initializeLegend()
                            mapView.populateModelForSpatialSearch()
                            pageView.showSpatialSearch()
                        }
                        else
                        {
                            //searchExtentBtn.visible = false
                            spatialSearchDockItem.visible=false
                            pageView.hideSpatialSearch()
                        }


                    }


                    MouseArea {
                        anchors.fill: parent
                        visible:true
                        onClicked: {

                            parent.checked = !parent.checked

                        }
                    }
                }



                ButtonGroup {
                    id: toolBarBtns

                    property string previouslyChecked:isLandscape? "info":""

                    buttons: btns.children

                    function uncheckAll (callback) {
                        if (showMeasureTool) {
                            if (callback) callback()
                            return
                        }
                        uncheckButtons()
                        previouslyChecked = ""
                        //close offline route if open
                        pageView.hidePanelItem()
                        pageView.hideSearchItem()
                        pageView.hideSpatialSearch()


                    }
                    function uncheckRoute()
                    {
                        if(!offlineRouteIcon.checked)
                        {
                            offlineRouteDockItem.visible=false
                            pageView.hideOfflineRoute()
                        }
                    }

                    function uncheckButtons () {
                        for (var i=0; i<buttons.length; i++) {
                            if (buttons[i].checked) {
                                buttons[i].checked = false
                            }
                        }

                        previouslyChecked = ""
                    }

                    onClicked: {
                        if (button.objectName === previouslyChecked) {
                            uncheckAll(null)
                        }
                        else
                            previouslyChecked = button.objectName
                    }
                }

                RowLayout {
                    id: btns
                    enabled: app.isInEditMode?false:true
                    opacity: app.isInEditMode?0.5:1

                    Controls.Icon {
                        id: infoIcon

                        objectName: "info"
                        imageSource: "../images/info.png"
                        checkable: true

                        onCheckedChanged: {
                            if (checked) {
                                offlineRouteIcon.checked = false
                                pageView.hideOfflineRoute()
                                pageView.hideSearchItem()
                                pageView.hideSpatialSearch()
                                panelDockItem.addDock("info")


                            } else {

                                panelDockItem.visible=false
                                pageView.hidePanelItem()

                            }


                        }
                        MouseArea {
                            anchors.fill: parent
                            visible: showMeasureTool
                            onClicked: {
                                if (button.objectName === previouslyChecked) {
                                    uncheckAll(null)
                                }
                                previouslyChecked = button.objectName
                                parent.checked = true
                            }
                        }
                    }

                    Controls.Icon {
                        id: measureToolIcon

                        property bool previouslyCheckedByClicking: false

                        objectName: "measure"
                        imageSource: "../images/measure.png"
                        checkable: app.isInEditMode?false:true
                        onCheckedChanged: {
                            if (checked) {
                                offlineRouteIcon.checked = false
                                offlineRouteDockItem.visible=false
                                pageView.hideOfflineRoute()
                                //panelPage.hideDetailsView()
                                pageView.hideSpatialSearch()
                                mapView.clearGraphics()
                                // if(mapView.spatialfeaturesModel.searchMode === searchMode.spatial)
                                if((mapView.spatialfeaturesModel.searchMode === searchMode.distance) || (mapView.spatialfeaturesModel.searchMode === searchMode.extent))
                                {
                                    mapView.clearSpatialSearch()
                                    mapView.hideSpatialSearchResults()

                                }
                                showMeasureTool = true
                                previouslyCheckedByClicking = false

                            } else {
                                showMeasureTool = false
                            }
                        }
                        onClicked: {
                            if (previouslyCheckedByClicking && toolBarBtns.previouslyChecked === measureToolIcon.objectName) {
                                checked = false
                            }
                            previouslyCheckedByClicking = checked
                        }
                        MouseArea {
                            anchors.fill: parent
                            visible: showMeasureTool && (lineGraphics.hasData() || areaGraphics.hasData())
                            onClicked: {
                                parent.checked = false
                            }
                        }
                    }

                    Controls.Icon {
                        id: offlineMapsIcon

                        objectName: "offlineMaps"
                        visible: offlineMaps.count > 1
                        imageSource: "../images/layers.png"
                        checkable: app.isInEditMode?false:true

                        onCheckedChanged: {
                            if (checked) {
                                offlineRouteIcon.checked = false
                                offlineRouteDockItem.visible=false
                                pageView.hideOfflineRoute()



                                pageView.hideSearchItem()
                                panelDockItem.addDock("offlineMaps")

                            } else {
                                pageView.hidePanelItem()
                                //panelDockItem.removeDock()
                                //panelPage.hide()
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            visible: showMeasureTool
                            onClicked: {
                                parent.checked = true
                            }
                        }
                    }

                    Controls.Icon {
                        id: basemapsIcon

                        objectName: "basemap"
                        imageSource: "../images/basemaps.png"
                        visible:(mapProperties.isMapArea !== undefined && mapProperties.isMapArea === false && mmpk.loadStatus !== Enums.LoadStatusLoaded )?true:false

                        checkable: mmpk.loadStatus !== Enums.LoadStatusLoaded

                        onCheckedChanged: {
                            if (checked) {
                                offlineRouteIcon.checked = false
                                offlineRouteDockItem.visible=false
                                pageView.hideOfflineRoute()
                                pageView.hideSearchItem()
                                pageView.hideSpatialSearch()
                                if((app.basemapsGroupId > "" && app.baseMapsModel.count > 0) || app.basemapsGroupId === ""){
                                    panelDockItem.addDock(more.titleCase(app.tabNames.kBasemaps))
                                } else
                                {
                                    messageDialog.show("",strings.no_basemaps_found)
                                }

                            } else {
                                panelDockItem.removeDock()
                                //panelPage.hide()
                                basemapsIcon.checked = false
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            visible: showMeasureTool
                            onClicked: {
                                parent.checked = true

                            }
                        }
                    }

                    Controls.Icon {
                        id: bookmarksIcon
                        //visible:(mmpk.loadStatus !== Enums.LoadStatusLoaded && mapProperties.isMapArea === undefined) || (mapProperties.isMapArea !== undefined && mapProperties.isMapArea === false)


                        objectName: "bookmark"
                        imageSource: "../images/book.png"
                        checkable:app.isInEditMode?false:true

                        onCheckedChanged: {
                            if (checked) {
                                offlineRouteIcon.checked = false
                                offlineRouteDockItem.visible=false
                                pageView.hideOfflineRoute()

                                pageView.hideSearchItem()
                                pageView.hideSpatialSearch()
                                panelDockItem.addDock("bookmark")
                                //                                panelPage.headerTabNames = [app.tabNames.kBookmarks]
                                //                                panelPage.title = qsTr("Bookmarks")
                                //                                panelPage.showPageCount = false
                                //                                panelPage.showFeaturesView()
                                //                                panelPage.show()
                            } else {
                                panelDockItem.removeDock()
                                //panelPage.hide()
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            visible:false //showMeasureTool
                            onClicked: {
                                parent.checked = true

                            }
                        }
                    }
                    Controls.Icon {
                        id: mapareasSyncIcon
                        visible:app.isOnline?(mapProperties.isMapArea?mapProperties.isMapArea:false):false

                        objectName: "updatesAvailable"
                        imageSource: "../images/available-updates-24.png"

                        MouseArea {
                            anchors.fill: parent
                            visible:true
                            onClicked: {

                                app.messageDialog.standardButtons = Dialog.Yes | Dialog.No
                                app.messageDialog.show("", qsTr("Do you want to update  %1?").arg(portalItem.title))
                                app.messageDialog.connectToAccepted(function () {
                                    mapareasbusyIndicator.visible = true
                                    mapAreaManager.checkForUpdates()
                                    //applyUpdates()
                                })



                            }
                        }
                        enabled: !mapareasbusyIndicator.visible
                        BusyIndicator {
                            id: mapareasbusyIndicator

                            visible: false

                            Material.primary: "white"//app.primaryColor
                            Material.accent: "white"//app.accentColor
                            width: app.iconSize
                            height: app.iconSize
                            anchors.centerIn: parent
                        }
                    }

                    Controls.Icon {
                        id: mapareasIcon
                        visible:mapPage.hasMapArea
                        objectName: "mapareas"
                        imageSource: "../images/download_mapArea.png"
                        checkable: true

                        onCheckedChanged: {
                            if (checked) {
                                panelDockItem.addDock("mapareas")

                            } else {
                                panelDockItem.removeDock()
                                polygonGraphicsOverlay.graphics.clear()
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            visible:true
                            onClicked: {
                                parent.checked = !parent.checked

                            }
                        }
                    }


                   /* Controls.Icon {
                        id: cameraIcon
                        imageWidth: app.units(24)
                        imageHeight: app.units(24)
                        maskColor: "white"
                        enabled: !measureToast.visible
                        //opacity: enabled ? 1 : 0.3

                        objectName: "camera"
                        imageSource: "../images/newcameraGrey.png"

                        onClicked: {
                            var cnt = screenShotsView.screenShots.count
                            screenShotsView.takeScreenShot()

                            if(cnt === 0)
                            {
                                // mapPage.header.y = - app.headerHeight
                                mapPage.header.y = - (app.headerHeight + (app.isNotchAvailable() ? app.notchHeight:0))
                                toolbarrow.visible = false
                                screenShotsView.listCurrentIndex = 0
                                toolBarBtns.uncheckAll()
                                screenShotsView.open()
                            }
                        }
                    }*/


//                    SequentialAnimation {
//                        id: flash

//                        PropertyAnimation {
//                            id: highlight
//                            target:cameraIcon //rotation
//                            properties:"checked"
//                            //properties: "maskColor"
//                            from: false
//                            to: true
//                            duration: 1
//                        }



//                        PropertyAnimation {
//                            id: removehighlight
//                            target: cameraIcon
//                            properties:"checked"
//                            //properties: "maskColor"
//                            from: true
//                            to: false
//                            duration: 500
//                        }
//                        ScriptAction {
//                            script:
//                            {
//                                var cnt = screenShotsView.screenShots.count
//                                screenShotsView.takeScreenShot()

//                                //pageView.hideSearchItem()
//                                if(cnt === 0)
//                                {
//                                    // mapPage.header.y = - app.headerHeight
//                                    mapPage.header.y = - (app.headerHeight + (app.isNotchAvailable() ? app.notchHeight:0))
//                                    toolbarrow.visible = false
//                                    screenShotsView.listCurrentIndex = 0
//                                    toolBarBtns.uncheckAll()
//                                    screenShotsView.open()
//                                }
//                                //loadImageInCanvas();
//                            }
//                        }


//                    }


                    Controls.Icon {
                        id: identifyBtn

                        visible: false // just a placeholder button
                        objectName: "identify"
                        checkable: true
                        property int currentPageNumber:0
                        property int currentEditTabIndex:0
                        property string currentEditTabName:"FEATURES"
                        property int currentlyEditedPageNumber:1
                        onCheckedChanged: {
                            if (checked) {
                                offlineRouteIcon.checked = false
                                searchIcon.checked = false
                                //if(!isGetAttachmentRunning)
                                //    checkIfAttachmentPresent(0)

                            } else {
                                panelDockItem.removeDock()
                                // panelPage.hide()
                            }
                            //identifyProperties.clearHighlight()
                        }


                        function populateTabHeaderModel(tabString)
                        {  var tabObjects = []
                            var tabnames = tabString.split(",")
                            tabnames.forEach(element => {
                                                 switch(element){
                                                     case app.tabNames.kMedia:
                                                     tabObjects.push({name:app.tabNames.kMedia,iconUrl:"../images/Media.png"})
                                                     break
                                                     case app.tabNames.kRelatedRecords:
                                                     tabObjects.push({name:app.tabNames.kRelatedRecords,iconUrl:"../images/Related.png"})
                                                     break
                                                     case app.tabNames.kAttachments:
                                                     tabObjects.push({name:app.tabNames.kAttachments,iconUrl:"../images/Attachments.png"})
                                                     break
                                                     case app.tabNames.kFeatures:
                                                     tabObjects.push({name:app.tabNames.kFeatures,iconUrl:"../images/Info-Features.png"})
                                                     break
                                                     case app.tabNames.kElevationProfile:
                                                     tabObjects.push({name:app.tabNames.kElevationProfile,iconUrl:"../images/Elevation.png"})
                                                     break

                                                 }

                                             }
                                             )
                            return tabObjects
                        }




                        function populateTabHeaders(editMode,canEditAttachments)
                        {

                            var _editMode = false
                            if(editMode)
                                _editMode = true
                            var tabString = app.tabNames.kFeatures
                            if(isAttachmentPresent || (_editMode && canEditAttachments))
                            {
                                tabString = tabString + "," + app.tabNames.kAttachments
                            }

                            var relatedRecordsPresent = identifyManager.checkRelatedRecords()

                            if(relatedRecordsPresent)
                            {
                                tabString = tabString + "," + app.tabNames.kRelatedRecords
                            }


                            //check for media
                            var isMediaPresent = identifyManager.checkForMedia()
                            var isLineFeaturePresent = identifyManager.checkForLineFeature()
                            if(isMediaPresent && !isInEditMode)
                                tabString = tabString + "," + app.tabNames.kMedia
                            if(isLineFeaturePresent && !isInEditMode)
                                tabString = tabString + "," + app.tabNames.kElevationProfile

                            var tabnames = populateTabHeaderModel(tabString)//tabString.split(",")

                            panelPage.headerTabNames = tabnames//tabString.split(",")
                            panelPage.showPageCount = true
                            panelPage.pageCount = identifyManager.popupManagers.length
                            panelPage.showFeaturesView()
                            //panelPage.visible = true
                            //panelPage.show()
                            pageView.hideOfflineRoute()
                            pageView.hideSearchItem()
                            panelDockItem.removeDock()
                            //identifyBtn.currentPageNumber = 1
                            panelDockItem.addDock("identify",tabString)
                        }




                    }

                }

//                Controls.Icon {
//                    id: moreIcon

//                    objectName: "more"
//                    imageSource: "../images/more.png"
//                    // checkable: true
//                    /* onCheckedChanged: {
//                            if (checked) {
//                               // offlineRouteIcon.checked = false
//                               // searchIcon.checked = false
//                                more.open()
//                            } else {
//                                more.close()
//                               // panelDockItem.removeDock()
//                            }
//                        }*/
//                    MouseArea {
//                        anchors.fill: parent
//                        // visible: showMeasureTool
//                        onClicked: {
//                            // parent.checked = true
//                            more.open()
//                        }
//                    }
//                }

            }

//            Controls.PopupMenu {
//                id: more

//                property string kRefresh: qsTr("Refresh")

//                defaultMargin: app.defaultMargin
//                backgroundColor: "pink"//"#FFFFFF"
//                highlightColor: Qt.darker(app.backgroundColor, 1.1)
//                textColor: app.baseTextColor
//                primaryColor: app.primaryColor

//                Connections {
//                    target: screenSizeState

//                    function onStateChanged() {
//                        more.updateMenuItemsContent()
//                    }
//                }

//                menuItems: [
//                    {"itemLabel": more.titleCase(app.tabNames.kMapUnits)},
//                    {"itemLabel": qsTr("Graticules")},
//                    //{"itemLabel": more.titleCase(kMeasure)}
//                    //{"itemLabel": more.kRefresh},
//                    //{"itemLabel": qsTr("Sketch")}
//                ]

//                Material.primary: app.primaryColor
//                Material.background: backgroundColor

//                height: app.units(160)

//                x: app.isLeftToRight ? (parent.width - width - app.baseUnit) : (0 + app.baseUnit)
//                y: 0 + app.baseUnit

//                onMenuItemSelected: {
//                    console.log("click-------------")
//                    console.log("itemLabel", itemLabel)
//                    toolBarBtns.uncheckAll()
//                    pageView.hideOfflineRoute()
//                    switch (itemLabel) {
//                    case more.titleCase(app.tabNames.kMapUnits):

//                        pageView.hideSearchItem()
//                        panelDockItem.addDock("mapunits")
//                        measureToolIcon.checked = false
//                        break
//                    case qsTr("Graticules"):
//                        pageView.hideSearchItem()
//                        panelDockItem.addDock("graticules")
//                        break
//                    case more.titleCase(app.tabNames.kBookmarks):
//                        bookmarksIcon.checked = !bookmarksIcon.checked
//                        break
//                    case more.titleCase(app.tabNames.kBasemaps):
//                        basemapsIcon.checked = !basemapsIcon.checked
//                        break
//                    case more.titleCase(kMeasure):
//                        measureToolIcon.checked = !showMeasureTool
//                        break
//                    case more.kRefresh:
//                        break
//                    }
//                }

//                onVisibleChanged: {
//                    if (!visible)
//                    {

//                    }
//                    else{

//                        updateMenuItemsContent()
//                    }


//                }

//                function updateMenuItemsContent () {

//                    if (screenSizeState.state === "SMALL") {
//                        var isBasemapsVisible = (mapProperties.isMapArea !== undefined && mapProperties.isMapArea === false && mmpk.loadStatus !== Enums.LoadStatusLoaded )?true:false

//                        if(isBasemapsVisible || basemapsIcon.visible)
//                        {
//                            more.appendUniqueItemToMenuList({"itemLabel": more.titleCase(app.tabNames.kBasemaps)})
//                            basemapsIcon.visible = false
//                        }
//                        more.appendUniqueItemToMenuList({"itemLabel": more.titleCase(kMeasure)})
//                        measureToolIcon.visible = false

//                        if (mapView.map && mapView.map.bookmarks.count > 0) {
//                            // more.appendUniqueItemToMenuList({"itemLabel": more.titleCase(kMeasure)})
//                            more.removeItemFromMenuList({"itemLabel": more.titleCase(app.tabNames.kBookmarks)})
//                            if(!mapProperties.isMapArea) //&& mapProperties.isMapArea === false)
//                                bookmarksIcon.visible = true
//                            // measureToolIcon.visible = false

//                        } else {
//                            more.appendUniqueItemToMenuList({"itemLabel": more.titleCase(app.tabNames.kBookmarks)})
//                            //more.removeItemFromMenuList({"itemLabel": more.titleCase(kMeasure)})


//                            bookmarksIcon.visible = false
//                            //measureToolIcon.visible = true
//                        }
//                    } else {
//                        if(hasMenuItem({"itemLabel": more.titleCase(kBasemaps)}))
//                        {
//                            more.removeItemFromMenuList({"itemLabel": more.titleCase(kBasemaps)})
//                            basemapsIcon.visible = true
//                        }
//                        more.removeItemFromMenuList({"itemLabel": more.titleCase(kMeasure)})
//                        if (mapView.map && mapView.map.bookmarks.count > 0) {
//                            more.removeItemFromMenuList({"itemLabel": more.titleCase(app.tabNames.kBookmarks)})
//                            if(!mapProperties.isMapArea) // && mapProperties.isMapArea === false)
//                                bookmarksIcon.visible = true
//                        }
//                        else{
//                            more.appendUniqueItemToMenuList({"itemLabel": more.titleCase(app.tabNames.kBookmarks)})
//                            bookmarksIcon.visible = false
//                        }


//                        measureToolIcon.visible = true
//                    }
//                    more.updateMenu()

//                }

//                function titleCase(str) {
//                    return str.toLowerCase().split(" ").map(function(word) {
//                        return (word.charAt(0).toUpperCase() + word.slice(1));
//                    }).join(" ");
//                }
//            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 100
            }
        }
    }

    contentItem: Rectangle {
        id: pageView
        state:"anchorright"

        Material.background:app.backgroundColor

        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom


        }


        PanelPage {
            id: panelPage

            property real extentFraction: 0.48

            mapView: mapView

            pageExtent: (1-extentFraction) * pageView.height

            onVisibleChanged: {
                if (!visible) {
                    if (!more.visible) {
                        toolBarBtns.uncheckAll()
                    } else {
                    }
                } else {
                    app.forceActiveFocus()
                    searchPage.close()
                }
            }

            onFullViewChanged: {
                if (measurePanel.state !== 'MEASURE_MODE') {
                    if (fullView && !app.isLandscape) {
                        mapPage.header.y = - (app.headerHeight + (app.isNotchAvailable() ? app.notchHeight:0))
                        toolbarrow.visible = false
                    } else {
                        // mapPage.header.y = 0
                    }
                }
            }
        }

        Views.MenuPage {
            id: sideMenu



            fallbackBannerImage: "../images/default-thumbnail.png"

            title: portalItem ? mapPage.portalItem.title : ""
            modified: portalItem ? mapPage.portalItem.modified : ""
            bannerImage: getThumbnailUrl()
            isMapOpened: true
            showContentHeader: true

            onCacheCleared: {
                mapPage.cacheCleared()
            }


            onMenuItemSelected: {
                switch (itemLabel) {
                case app.kBack:
                case app.kBackToGallery:
                    app.isInEditMode = false
                    toolBarBtns.uncheckAll(mapPage.previous)
                    if(mmpk.maps.length > 0)
                    {
                        mmpk.close()
                    }


                    if(loginDialog.visible)
                        loginDialog.close()
                    mapPage.previous()
                    if(app.authChallenge)
                        app.authChallenge.cancel()
                    if (locationBtn.checked) locationBtn.clicked()

                    break
                }
            }

            Component.onCompleted: {
                if (app.showBackToGalleryButton) {
                    sideMenu.insertItemToMenuList(0, { "iconImage": "../images/back.png", "itemLabel": app.kBackToGallery, "control": "" })
                }
                removeItemsFromMenuListByAttribute ("itemLabel", kSignIn)
                removeItemsFromMenuListByAttribute ("itemLabel", kSignOut)
                removeItemsFromMenuListByAttribute("itemLabel", kClearCache)

                title = portalItem ? mapPage.portalItem.title : ""
                modified = portalItem ? mapPage.portalItem.modified : ""
                bannerImage = getThumbnailUrl()
            }


            function getThumbnail_MapArea()
            {
                var url = fallbackBannerImage

                var storageBasePath = offlineMapAreaCache.fileFolder.path//app.rootUrl //AppFramework.resolvedUrl("./ArcGIS/AppStudio/cache")

                var mapareapath = [storageBasePath,portalItem.mapid].join("/")
                if(Qt.platform.os === "windows")
                    url = "file:///" + mapareapath + "/" + portalItem.id + "_thumbnail/" + portalItem.thumbnailUrl
                else
                    url = "file://" + mapareapath + "/" + portalItem.id + "_thumbnail/" + portalItem.thumbnailUrl



                return url
            }

            function getThumbnailUrl () {
                try {
                    if(portalItem.type === "maparea")
                        return getThumbnail_MapArea()
                    else
                    {
                        var url = portalItem ? mapPage.portalItem.thumbnailUrl.toString() : ""
                        if (url.startsWith("http") && portalItem){
                            url = offlineCache.cache(url, '', {"token":app.portal?(app.portal.credential?app.portal.credential.token:""):""}, null)
                            url += "?token=%1".arg(app.portal?(app.portal.credential?app.portal.credential.token:""):"");
                        }
                        return url > "" ? url : fallbackBannerImage
                    }
                } catch (err) {
                    return fallbackBannerImage
                }
            }

        }

        MapArea.MapAreaManager{
            id:mapAreaManager
            _offlineMapTask:offlineMapTask
            portalItem : mapPage.portalItem
        }

        ContingencyValues{
            id: contingencyValues
        }

        SearchPage{
            id:searchPage
        }



        IdentifyManager{
            id:identifyManager
            isInEditMode: app.isInEditMode

            //onShowIdentifyUI: mapView.showIdentifyPanel()
            onGetAttachmentCompleted :mapPage.getAttachmentCompleted()
            onPopupManagersCountChanged :{



                // identifyProperties.popupManagersCount = popupManagers.length
                // identifyProperties.popupManagersCountChanged()
            }
            onHighlightFeature: {
                //identifyProperties.clearHighlight()

                let featureTable = feature.featureTable
                let layer = featureTable.layer


                identifyProperties.showInMap(layer,feature,true)
                //feature.featureTable.layer.clearSelection()
                // feature.featureTable.layer.selectFeature(feature)
                //identifyProperties.zoomToFeature(feature)
            }

            onFeatureDeleted: {
                panelPageLoader.item.hidePanelPage()
            }
            onIsAttachmentPresentChanged: {
                mapPage.isAttachmentPresent = isAttachmentPresent
            }


        }

        FeaturesManager {
            id:featuresManager
        }




        MapView {
            id: mapView

            LayoutMirroring.enabled: false
            LayoutMirroring.childrenInherit: false
            property var searchLegendListHeight:100
            property var tasksInProgress: []
            property ListModel contentListModel: ListModel {}
            property ListModel treeContentListModel: ListModel {}
            property ListModel sortedTreeContentListModel: ListModel {}
            property ListModel mapunitsListModel: ListModel {}
            property ListModel gridListModel: ListModel{}
            property ListModel unOrderedLegendInfos: Controls.CustomListModel {}
            property ListModel orderedLegendInfos: Controls.CustomListModel {} // model used in view
            property ListModel orderedLegendInfos_spatialSearch: Controls.CustomListModel {} // model used in view
            property ListModel orderedLegendInfos_legend: Controls.CustomListModel {}
            //property ListModel orderedLegendInfos_spatial: Controls.CustomListModel {}
            property int noSwatchRequested:0
            property int noSwatchReceived:0
            property var scale:mapView.mapScale
            property int noOfFeaturesRequestReceived:0
            property int noOfFeaturesRequested:0
            property var featureTableRequestReceived:[]
            property bool isIdentifyTool:false
            property int mapReadyCount: 0
            property real initialMapRotation: 0
            property alias compass: defaultLocationDataSource.compass
            property alias devicePositionSource: defaultLocationDataSource.positionInfoSource
            property Point center
            property alias pointGraphicsOverlay:placeSearchResult
            property alias routeGraphicsOverlay:routeGraphicsOverlay
            property alias routeFromStopGraphicsOverlay:routeStopsGraphicsOverlay
            property alias routeToStopGraphicsOverlay:routeToStopGraphicsOverlay
            property alias routePartGraphicsOverlay:routePartGraphicsOverlay
            property alias routePedestrianLineGraphicsOverlay:routePedestrianlineGraphicsOverlay
            property string routeColor:"#66ff00"
            property var fromGraphic:null
            property var toGraphic:null
            property var routeStops: []
            property string fromRouteAddress:""
            property string toRouteAddress:""
            property var allPoints: []
            property string searchText:""
            property string activeSearchTab:app.tabNames.kPlaces
            property alias geocodeModel:geocodeModel
            property alias featuresModel:featuresModel
            property alias spatialfeaturesModel:spatialfeaturesModel
            property alias withinExtent:withinExtent
            property alias outsideExtent:outsideExtent
            property var spatialSearchConfig:null
            property alias measurePanel:measurePanel
            property bool spatialSearchInitialized:false
            property alias elevationPtGraphicsOverlay:elevationpointGraphicsOverlay
            property string elevationUnits:"ft"
            property int currentFeatureIndexForElevation:-1
            property string panelTitle:panelPage.title

            property var taskId_spatialQuery:null
            property var currentTableForSpatialQuery:null
            //property var nolayersforWhichQueryFailed:0
            property bool isSpatialQueryCancelled:false
            property var spatialQueryGeometry:null
            property bool isSpatialSearchFinished:true
            property bool startZooming:false
            property bool startNavigating:false
            property var prevMapScale

            property bool mapInitialized:false
            property alias _sketchGraphicsOverlay:sketchGraphicsOverlay
            property alias polygonGraphicsOverlay:polygonGraphicsOverlay
            //property  var selectedMeasurementUnits:measurementUnits.imperial

            signal showSpatialSearchResults()
            signal hideSpatialSearchResults()
            signal spatialSearchFinished()
            signal spatialSearchBackBtnPressed()
            signal spatialSearchModelUpdated()
            signal layerLoadingError()
            signal layerVisibilityChanged()


            QtObject {
                id: searchMode



                property int attribute: 0
                // property int spatial: 1
                property int distance: 1
                property int extent: 2


            }

            Controls.CustomListModel {
                id: spatialfeaturesModel

                property var features: []
                property var sections: []
                property var popupManagers: []
                property var popupDefinitions: []
                property var searchMode:searchMode.attribute
                property int currentIndex: -1
                property var searchGeometry:null

                function clearAll () {
                    currentIndex = -1
                    features = []
                    sections = []
                    clear()
                    searchGeometry = null
                }
            }


            Controls.CustomListModel {
                id: featuresModel

                property var features: []
                property var popupManagers: []
                property var popupDefinitions: []
                property var searchMode:searchMode.attribute
                property int currentIndex: -1

                function clearAll () {
                    currentIndex = -1
                    features = []
                    clear()
                    mapView.identifyProperties.clearHighlight()
                }
            }

            Controls.CustomListModel {
                id: geocodeModel

                property var features: []
                property int currentIndex: -1

                function clearAll () {
                    currentIndex = -1
                    features = []
                    clear()
                    withinExtent.clear()
                    outsideExtent.clear()
                    mapView.hidePin()
                }

                function appendModelData (model) {
                    for (var i=0; i<model.count; i++) {
                        append(model.get(i))
                    }
                }
            }

            Controls.CustomListModel {
                id: withinExtent
            }

            Controls.CustomListModel {
                id: outsideExtent
            }



            property QtObject layersWithErrorMessages: QtObject {
                id: layersWithErrorMessages

                property var layers: []
                property var messagesRequiringLogin: [
                    "Unable to generate token.",
                    "Token Required"
                ]
                property real count: layers.length

                function clear () {
                    layers = []
                }

                function append (item) {
                    layers.push(item)
                    count += 1
                }

                onLayersChanged: {
                    count = layers.length
                }

                onCountChanged: {
                    if (count) {
                        handleErrors()
                    }
                }

                function handleErrors () {
                    for (var i=0; i<count; i++) {
                        var layerContent = layers[i]

                        if (!layerContent.verified) {

                            if (layerContent.layer.loadError) {
                                if (messagesRequiringLogin.indexOf(layerContent.layer.loadError.message) !== -1) {

                                    // Commented out because this is handled by the singleton AuthenticationManager
                                    // Mark as verified and let AuthenticationManager handle it

                                    //loginDialog.show(qsTr("Authentication required to acceess the layer %1").arg(layerContent.layer.name))
                                    //loginDialog.onAccepted.connect(function () {
                                    //    layerContent.verified = true
                                    //    return handleErrors()
                                    //})
                                    //loginDialog.onRejected.connect(function () {
                                    //    layerContent.verified = true
                                    //    return handleErrors()
                                    //})

                                    layerContent.verified = true // verified by AuthenticationManager in loginDialog
                                    return handleErrors()
                                } else if (!app.messageDialog.visible) {
                                    var title = layerContent.layer.loadError.message
                                    var message = layerContent.layer.loadError.additionalMessage
                                    if (!title || !message) {
                                        message = message ? message : title
                                        title = ""
                                    }
                                    app.messageDialog.show (title, message)
                                    app.messageDialog.connectToAccepted(function () {
                                        layerContent.verified = true
                                        return layersWithErrorMessages.handleErrors()
                                    })
                                }
                            }
                        }
                    }
                    //console.log(layers[0].layer, layers[0].verified)
                }
            }

            property QtObject identifyProperties: QtObject {
                id: identifyProperties
                property var temporal: []
                property var currentFeatureIndex:0
                property bool isModelBindingInProgress:false
                property bool isCurrentFeatureHighlighted:false
                property var mouseCoord:({})
                signal prepareAfterEditFeature()
                signal refreshModel(var pageNumber)
                signal doIdentify()
                signal saveFeature()

                //                onSaveCurrentFeature: {

                //                }
                onDoIdentify: {
                    if(mapPage.backToGallery)
                    {
                        toolBarBtns.uncheckAll(mapPage.previous)
                        mapPage.previous()
                        backToGallery = false
                        if (locationBtn.checked) locationBtn.clicked()
                    }
                    else
                    {
                        if(mouseCoord.x)
                            mapView.identifyFeatures (mouseCoord.x, mouseCoord.y)
                    }
                }

                function reset () {
                    identifyProperties.clearHighlight()
                    identifyManager.popupManagers = []
                    identifyManager.popupDefinitions = []
                    identifyManager.features = []
                    identifyManager.fields = []
                    mapView.noOfFeaturesRequested = 0
                    mapView.noOfFeaturesRequestReceived = 0
                    mapView.featureTableRequestReceived = []

                    computeCounts()
                }

                function computeCounts () {
                    identifyManager.popupManagersCount = identifyManager.popupManagers.length
                    identifyManager.popupDefinitionsCount = identifyManager.popupDefinitions.length
                    identifyManager.featuresCount = identifyManager.features.length
                    identifyManager.fieldsCount = identifyManager.fields.length
                }

                // Function that highlights feature on the map when clicked
                function showInMap(currentLayer, feature, zoom){
                    let featuregeometry = feature.geometry;
                    clearHighlight()
                    if(featuregeometry)
                    {

                        if(featuregeometry.geometryType !== null){
                            if ( currentLayer && currentLayer.objectType === "FeatureLayer" ){
                                // Highlight feature directly from layer if the currentLayer is a FeatureLayer QML type
                                currentLayer.selectFeature(feature)
                                if (featuregeometry.geometryType === Enums.GeometryTypePoint) {
                                    if (zoom) {
                                        mapView.zoomToPoint(featuregeometry.extent.center)
                                    }
                                    else
                                        mapView.setViewpointCenter(featuregeometry)

                                } else {
                                    if (zoom) {
                                        mapView.zoomToExtent(featuregeometry.extent)
                                    }
                                    else
                                        mapView.setViewpointCenter(featuregeometry.extent.center)
                                }
                            } else {
                                // Layers of other types (other than FeatureLayer QML type) does not support highlighting feature directly, appending overlay graphics to highlight features
                                if (featuregeometry.geometryType === Enums.GeometryTypePoint) {
                                    let simpleMarker = ArcGISRuntimeEnvironment.createObject("SimpleMarkerSymbol",
                                                                                             {color: "cyan", size: app.units(10),
                                                                                                 style: Enums.SimpleMarkerSymbolStyleCircle}),
                                    graphic = ArcGISRuntimeEnvironment.createObject("Graphic",
                                                                                    {symbol: simpleMarker, geometry: featuregeometry})
                                    pointGraphicsOverlay.graphics.append(graphic)
                                    mapView.setViewpointCenter(graphic.geometry)
                                    if (zoom) {
                                        mapView.zoomToPoint(pointGraphicsOverlay.extent.center)
                                    }

                                    temporal.push(simpleMarker, graphic)
                                } else if (featuregeometry.geometryType === Enums.GeometryTypePolygon) {
                                    simpleFillSymbol.color = "transparent"
                                    let graphic = ArcGISRuntimeEnvironment.createObject("Graphic",
                                                                                        {symbol: simpleFillSymbol, geometry: featuregeometry})
                                    polygonGraphicsOverlay.graphics.append(graphic)

                                    // Zoom to the feature after expanding 150% in case it is not within the current map extent
                                    if (zoom) {
                                        mapView.zoomToExtent(polygonGraphicsOverlay.extent)
                                    }
                                    else {
                                        mapView.setViewpointCenter(polygonGraphicsOverlay.extent.center)
                                    }

                                    temporal.push(graphic)
                                } else {
                                    let graphic = ArcGISRuntimeEnvironment.createObject("Graphic",
                                                                                        {symbol: simpleLineSymbol, geometry: featuregeometry})
                                    lineGraphicsOverlay.graphics.append(graphic)

                                    if (zoom) {
                                        mapView.zoomToExtent(lineGraphicsOverlay.extent)
                                    } else{
                                        mapView.setViewpointCenter(lineGraphicsOverlay.extent.center)
                                    }

                                    temporal.push(graphic)
                                }
                            }
                        }
                    }

                }

                // Wrapper function that calls showInMap function to highlight features in map
                function highlightFeature (index, zoom) {
                    if (!zoom) zoom = false
                    if (!identifyManager.features.length) return

                    let feature = identifyManager.features[index]
                    let featureTable = feature.featureTable
                    let layer = featureTable.layer

                    showInMap(layer, feature,zoom)
                }

                function clearGroupLayer(layer)
                {
                    if(layer.subLayerContents.length > 0)
                    {
                        for(let k=0;k<layer.subLayerContents.length;k++)
                        {
                            let sublyr = layer.subLayerContents[k]
                            clearGroupLayer(sublyr)
                        }
                    }
                    else
                    {
                        try{
                            layer.clearSelection()
                        }
                        catch(ex)
                        {

                        }
                    }

                }

                function clearHighlightInLayer(){
                    try{
                        clearHighlight();

                        for (var i = 0 ; i < mapView.map.operationalLayers.count; i++) {
                            var lyr = mapView.map.operationalLayers.get(i);
                            if(lyr.objectType === "GroupLayer")
                                clearGroupLayer(lyr)
                            else
                            {
                                if(lyr && lyr.objectType === "FeatureCollectionLayer") {
                                    for(var j = 0; j < lyr.layers.length; j++){
                                        lyr.layers[j].clearSelection()
                                    }
                                }
                                else
                                {

                                    if(lyr && lyr.objectType !== "ArcGISVectorTiledLayer" && lyr.objectType !== "ArcGISTiledLayer" && lyr.objectType !== "ArcGISMapImageLayer" && lyr.visible)
                                        lyr.clearSelection();

                                }
                            }
                        }
                    }
                    catch(ex)
                    {
                        console.log(ex)

                    }
                }

                // Function to clear existing highlighted feature/ overlay graphics on the map
                function clearHighlight (callback) {
                    try{
                        // if (!callback) callback = function () {}

                        pointGraphicsOverlay.graphics.clear()
                        polygonGraphicsOverlay.graphics.clear()
                        lineGraphicsOverlay.graphics.clear()

                        // Clear existing selection from all layers before highlighting
                        for (let i = 0; i < mapView.map.operationalLayers.count; i++) {
                            let lyr = mapView.map.operationalLayers.get(i);

                            if(lyr.objectType === "GroupLayer")
                                clearGroupLayer(lyr)
                            else
                            {
                                if(lyr.objectType === "FeatureCollectionLayer") {
                                    for (let j = 0; j < lyr.layers.length; j++){
                                        lyr.layers[j].clearSelection()
                                    }
                                } else {
                                    try {
                                        if ( lyr && lyr.objectType !== "ArcGISVectorTiledLayer" && lyr.objectType !== "ArcGISTiledLayer" && lyr.objectType !== "ArcGISMapImageLayer" && lyr.visible ){
                                            lyr.clearSelection();
                                        }
                                    } catch(e){
                                        console.error(e);
                                    }
                                }

                            }
                        }

                        for (let k = 0; k < temporal.length; k++) {
                            if (temporal[k]) {
                                temporal[k].destroy()
                            }
                        }

                        temporal = []
                        if(callback)
                            callback()
                    }
                    catch(ex)
                    {
                        console.error(ex.toString())
                    }
                }
                function highlightInMap(featureLayer,feature,zoom)
                {
                    clearHighlightInLayer()
                    if(featureLayer)
                    {
                        featureLayer.clearSelection()
                        featureLayer.selectFeature(feature)
                        if(isBufferSearchEnabled){
                            const centerPoint2 = GeometryEngine.project(feature.geometry, mapView.spatialReference)
                            const viewPointCenter = ArcGISRuntimeEnvironment.createObject("ViewpointCenter", {center: centerPoint2})
                            if (feature.geometry.geometryType === Enums.GeometryTypePoint)
                                mapView.setViewpointGeometryAndPadding(mapView.bufferGeometry.extent,30)
                            else
                            {
                                let isContained = GeometryEngine.contains(mapView.bufferGeometry.extent,feature.geometry.extent)
                                if(isContained)
                                    mapView.setViewpointGeometryAndPadding(mapView.bufferGeometry.extent,30)
                                else
                                {
                                    let combinedGeometry = []
                                    combinedGeometry.push(mapView.bufferGeometry)
                                    combinedGeometry.push(feature.geometry)
                                    var combinedextent = GeometryEngine.combineExtentsOfGeometries(combinedGeometry);
                                    mapView.setViewpointGeometryAndPadding(combinedextent,30)
                                }

                            }

                        }
                        else
                        {
                            let extent = mapView.searchExtent //mapView.currentViewpointExtent.extent
                            mapView.setViewpointGeometryAndPadding(extent,0)

                        }

                    }
                }

                function zoomToFeature(feature)
                {
                    mapView.prevMapExtent = mapView.currentViewpointExtent.extent
                    mapView.setViewpointGeometryAndPadding(feature.geometry.extent,40)
                }

                function zoomToPreviousExtent()
                {
                    mapView.setViewpointGeometryAndPadding(mapView.prevMapExtent,0)
                }

            }

            property QtObject mapInfo: QtObject {
                id: mapInfo

                property string title: ""
                property string snippet: ""
                property string description: ""
            }

            onMapReadyCountChanged: {
                if (mapReadyCount === 1) {
                    initialMapRotation = mapRotation
                }
            }




            onMapScaleChanged:{
                startZooming = true

            }

            AttributeEditorManager{
                id:attributeEditorManager
                _mapView:mapView
                isInCreateMode: mapPage.isInShapeCreateMode
            }

            SketchEditorManager{
                id:sketchEditorManager
                _sketchEditor: sketchEditor
                _mapView:mapView
                //symbolUrl: identifyManager.featureSymbol
                onSelectedmeasurementUnitIndexChanged: {
                    switch(selectedmeasurementUnitIndex)
                    {
                    case 0:
                        app.setFavoriteMeasurementUnits("m")
                        break;
                    case 1:
                        app.setFavoriteMeasurementUnits("mi")
                        break
                    case 2:
                        app.setFavoriteMeasurementUnits("km")
                        break
                    case 3:
                        app.setFavoriteMeasurementUnits("ft")
                        break
                    case 4:
                        app.setFavoriteMeasurementUnits("yd")
                        break
                    }


                }

                onShowErrorMessage: {
                    panelPageLoader.item.showErrorMessage(editresult)

                }
                onShowSuccessMessage: {
                    panelPageLoader.item.hidePanelPage()
                    identifyManager.showSuccessfulMessage()

                    app.isInEditMode = false
                }


                onFeatureUpdated:{
                    // identifyProperties.clearHighlightInLayer()
                    toastMessage.show(strings.successfully_saved)

                    if(feature && feature.featureTable)
                        feature.featureTable.layer.selectFeature(feature)

                }
            }

            SketchEditor{
                id:sketchEditor

                style: SketchStyle{
                    showNumbersForVertices: false
                    vertexSymbol:primaryColorSymbol
                    selectedVertexSymbol:primaryColorSymbol

                }

            }




            backgroundGrid: BackgroundGrid {
                gridLineWidth: 1
                gridLineColor: "#22000000"
            }

            Map {
                id:myWebmap
                initUrl: mapPage.portalItem.type === "Web Map" ? mapPage.portalItem.url : ""
                Basemap {
                    //initStyle : Enums.BasemapStyleArcGISTopographic//.BasemapStyleOsmStandard
                    // Nest an ArcGISMapImage Layer in the Basemap
                    ArcGISMapImageLayer {
                        url: app.basemapUrl >"" ?app.basemapUrl:"https://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"
                    }
                }

                function zoomAndPopulateContent(){

                    mapView.processLoadStatusChange()
                    if (_featureCollectionLayer.loadStatus === Enums.LoadStatusLoaded)
                        mapView.zoomToExtent(_featureCollectionLayer.fullExtent)

                }

                function addLayerToContent(layer)
                {
                    if (layer.loadStatus !== Enums.LoadStatusLoaded)
                    {
                        layer.loadStatusChanged.connect(function(){
                            if (layer.loadStatus === Enums.LoadStatusLoaded){

                                mapView.zoomToExtent(layer.fullExtent)

                                mapView.processLoadStatusChange()

                            }

                        }
                        )
                        layer.load()
                    }
                    else
                    {
                        mapView.processLoadStatusChange()
                        mapView.setViewpointGeometry(layer.fullExtent)

                    }
                }



                onLoadStatusChanged: {
                    // pageView.state = defaultAnchor//"anchorright"


                    mapView.processLoadStatusChange()

                    if(mapPage.portalItem.type === "Web Map")
                    {
                        //checkExistingAreas()
                        let outputFilePath = offlineMapAreaCache.fileFolder.path + "/"
                        existingmapareas = mapAreaManager.checkExistingAreas(outputFilePath)
                        more.updateMenuItemsContent()
                        var taskid = offlineMapTask.preplannedMapAreas();
                    }
                    else if((app.layerType === "Feature Collection") && !mapLayers.includes(app.itemId))
                        loadFeatureCollectionLayer()
                    else if((app.layerType === "Vector Tile Service") && layerUrl > ""&& !mapLayers.includes(layerUrl))
                        loadVectorTileLayer()
                    else if ((app.layerType === "Tile Layer") && !mapLayers.includes(layerUrl))
                        loadTileLayer()
                    else
                    {
                        if(layerUrl > "" && !mapLayers.includes(layerUrl))
                        {
                            mapLayers.push(layerUrl)
                            if(app.layerType === "Map Image Layer")
                                loadMapImageLayer()
                            else
                                loadFeatureService()

                        }
                    }

                }

                ViewpointExtent {
                    id: seAKviewpointExtent
                    extent: seakEnvelope
                }

                Envelope {
                    id: seakEnvelope
                    xMax: -15902737
                    xMin: -14309946
                    yMin: 7255676
                    yMax: 8432227
                    spatialReference: SpatialReference {
                        wkid: 3857
                    }
                }

                function addSubLayer(sublayerurl,canZoom)
                {
                    if(app.layerType === "Feature Service")
                    {
                        let serviceFeatureTable = ArcGISRuntimeEnvironment.createObject("ServiceFeatureTable", {url: sublayerurl});
                        let customLayer = ArcGISRuntimeEnvironment.createObject("FeatureLayer", {featureTable: serviceFeatureTable,spatialReference: Factory.SpatialReference.createWebMercator()});
                        operationalLayers.append(customLayer)
                        if (customLayer.loadStatus !== Enums.LoadStatusLoaded)
                        {
                            customLayer.loadStatusChanged.connect(function(){
                                if (customLayer.loadStatus === Enums.LoadStatusLoaded){
                                    if(customLayer.featureTable)
                                    {
                                        if(canZoom)
                                            mapView.zoomToExtent(customLayer.featureTable.extent)

                                    }

                                    mapView.processLoadStatusChange()

                                }

                            }
                            )
                            customLayer.load()
                        }
                        else
                        {
                            if(customLayer.featureTable)
                                mapView.zoomToExtent(customLayer.featureTable.extent)

                            mapView.processLoadStatusChange()
                        }
                    }

                }



                function loadFeatureService()
                {

                    var canZoom = true
                    if(mapProperties.layers)
                    {

                        for(let k = 0;k<mapProperties.layers.length;k ++)
                        {
                            let lyrid = mapProperties.layers[k].id
                            let sublayerurl = layerUrl + "/" + lyrid

                            canZoom = false
                            if(k === 0)
                                canZoom = true

                            addSubLayer(sublayerurl,canZoom)

                        }


                    }
                    else
                    {

                        addSubLayer(layerUrl,canZoom)
                    }
                }


                function loadMapImageLayer()
                {
                    var mapImagecustomLayer = ArcGISRuntimeEnvironment.createObject("ArcGISMapImageLayer", {url: layerUrl});

                    operationalLayers.append(mapImagecustomLayer)
                    if (mapImagecustomLayer.loadStatus !== Enums.LoadStatusLoaded)
                    {
                        mapImagecustomLayer.loadStatusChanged.connect(function(){
                            if (mapImagecustomLayer.loadStatus === Enums.LoadStatusLoaded){
                                mapView.setViewpointCenterAndScale(mapImagecustomLayer.fullExtent.center, mapImagecustomLayer.minScale);


                                mapView.processLoadStatusChange()

                            }

                        }
                        )
                        mapImagecustomLayer.load()
                    }
                    else
                    {
                        mapView.processLoadStatusChange()
                        mapView.setViewpointGeometryAndPadding(mapImagecustomLayer.fullExtent,80)
                        mapView.setViewpointScale(mapImagecustomLayer.minScale)

                    }
                }


                function loadTileLayer()
                {
                    mapLayers.push(layerUrl)

                    const tiledcustomLayer1 = ArcGISRuntimeEnvironment.createObject("ArcGISTiledLayer", {url: layerUrl});
                    operationalLayers.append(tiledcustomLayer1)
                    if (tiledcustomLayer1.loadStatus !== Enums.LoadStatusLoaded)
                    {
                        tiledcustomLayer1 .loadStatusChanged.connect(function(){
                            if (tiledcustomLayer1.loadStatus === Enums.LoadStatusLoaded){
                                mapView.zoomToExtent(tiledcustomLayer1.fullExtent)

                                mapView.processLoadStatusChange()

                            }

                        }
                        )
                        tiledcustomLayer1.load()
                    }
                    else
                    {
                        mapView.processLoadStatusChange()
                        mapView.zoomToExtent(tiledcustomLayer1.fullExtent)

                    }
                }

                function loadVectorTileLayer()
                {
                    mapLayers.push(layerUrl)

                    const tiledcustomLayer = ArcGISRuntimeEnvironment.createObject("ArcGISVectorTiledLayer", {url: layerUrl});
                    operationalLayers.append(tiledcustomLayer)
                    addLayerToContent(tiledcustomLayer)
                }

                function loadFeatureCollectionLayer()
                {
                    mapLayers.push(app.itemId)
                    featureCollectionItemId = app.itemId
                    var _portalItem = ArcGISRuntimeEnvironment.createObject("PortalItem",{
                                                                                portal: portal,
                                                                                itemId: featureCollectionItemId
                                                                            });
                    _portalItem.loadStatusChanged.connect(function(){
                        if (_portalItem.loadStatus === Enums.LoadStatusLoaded){
                            _featureCollection = ArcGISRuntimeEnvironment.createObject("FeatureCollection",{item: _portalItem});
                            _featureCollectionLayer = ArcGISRuntimeEnvironment.createObject("FeatureCollectionLayer",{featureCollection: _featureCollection});
                            mapView.map.operationalLayers.append(_featureCollectionLayer);
                            _featureCollectionLayer.name = _portalItem.title;
                            _featureCollectionLayer.loadStatusChanged.connect(zoomAndPopulateContent);
                            _featureCollectionLayer.load();
                        }
                    });
                    _portalItem.load();

                }





                onLoadErrorChanged: {
                    mapView.processLoadErrorChange()
                }
            }

            rotationByPinchingEnabled: true
            zoomByPinchingEnabled: true
            wrapAroundMode: Enums.WrapAroundModeEnabledWhenSupported
            //anchors.fill: parent
            //anchors.right:pageView.right
            anchors.top:pageView.top
            width: (searchDockItem.visible ||spatialSearchDockItem.visible || panelDockItem.visible || offlineRouteDockItem.visible)?(pageView.state ==="anchorbottom"?pageView.width:pageView.width  * 0.65):pageView.width
            height:offlineRouteDockItem.visible?(pageView.state ==="anchorbottom"?pageView.height * 0.6:pageView.height):pageView.height

            Sketch.FeatureSketch{
                id: featureSketch
                isShown: isInShapeEditMode || isInShapeCreateMode
                isPanMode:sketchEditorManager.selectedDrawMode === sketchEditorManager._editMode.pan
                // onExitShapeEditMode: panelPage.exitShapeEditMode(action)
                onExitShapeEditMode: exitEditMode(action)
                function exitEditMode(action)
                {
                    let isFeatureEdited = false
                    let lyrid =  null
                    let feature1 = null
                    //  sketchGraphicsOverlay.graphics.clear()
                    if(isInShapeCreateMode)
                    {
                        isFeatureEdited = sketchEditor.isSketchValid()
                    }
                    else
                    {
                        feature1 = identifyManager.features[identifyBtn.currentPageNumber - 1]
                        lyrid = feature1.featureTable.layer.layerId
                        isFeatureEdited = sketchEditorManager.isGeometryEdited(feature1)
                    }

                    if(isFeatureEdited && action === "cancel")
                    {
                        app.messageDialog.width = messageDialog.units(300)
                        app.messageDialog.standardButtons = Dialog.Cancel | Dialog.Yes
                        app.messageDialog.show(strings.discard_edits,strings.cancel_editing)
                        app.messageDialog.connectToAccepted(function () {

                            sketchEditorManager.stopSketchEditor()
                            sketchEditorManager.setFeatureVisibility(lyrid,feature1,false)
                            cancelEditing()

                            sketchGraphicsOverlay.graphics.clear()
                            sketchEditorManager.stopSketchEditor()

                        })
                        app.messageDialog.connectToRejected(function () {
                            //console.log("no change")
                        })
                    }
                    else
                    {
                        sketchEditorManager.stopSketchEditor()

                        cancelEditing()
                    }

                }

                function cancelEditing()
                {
                    mapPage.isEditingExistingFeature = false
                    newFeatureEditBtn.checked = false
                    isShowingCreateNewFeature = false
                    sketchGraphicsOverlay.graphics.clear()

                    if(isInShapeCreateMode)
                    {
                        isInShapeCreateMode = false
                        app.isInEditMode = false
                        panelDockItem.panelItemLoader._footerLoader.source = ""
                        panelDockItem.panelItemLoader.isFooterVisible = false
                        panelDockItem.panelItemLoader.hidePanelPage()
                        sketchGraphicsOverlay.graphics.clear()

                        mapPage.state = "anchorright"//"anchorrightnopanel"
                        mapPageHeader.visible = true
                        mapPageHeader.y = 0
                        mapPageHeader.height = app.headerHeight + app.notchHeight
                        //pageView.state = "anchorrightnopanel"

                    }
                    else
                    {
                        isInShapeEditMode = false
                        panelDockItem.panelItemLoader.showIdentifyPageFooter()
                        panelDockItem.panelItemLoader.showIdentifyPageHeader()
                        mapView.identifyProperties.highlightFeature(identifyBtn.currentPageNumber - 1,true)
                        if(app.isLandscape)
                            panelDockItem.dockToLeft()

                        else
                            panelDockItem.dockToBottom()
                    }

                }
            }


            ColumnLayout {
                id: mapControls
                property real radius: 0.5 * app.mapControlIconSize
                height: parent.height - 148 * app.scaleFactor//3 * width
                width: mapControls.radius + app.defaultMargin
                spacing:16 * scaleFactor

                anchors {
                    top: parent.top
                    right: parent.right
                    rightMargin:app.isLandscape ? app.widthOffset +  units(26):units(26)
                    topMargin: homebutton.visible ? -8 * scaleFactor:2 * app.defaultMargin

                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: homebutton.visible ? app.baseUnit: app.units(112)//app.defaultMargin
                }


                Rectangle{
                    id:homebutton
                    Layout.preferredWidth: 56 * app.scaleFactor
                    Layout.preferredHeight: 56 * scaleFactor
                    radius:height/2
                    visible:(!isInShapeEditMode && !isInShapeCreateMode) || sketchEditorManager.selectedDrawMode === sketchEditorManager._editMode.pan

                    Controls.Icon {
                        anchors.fill:parent
                        imageSource: "../images/home.png"
                        maskColor:colors.blk_200

                        onClicked: {
                            mapView.setViewpointWithAnimationCurve(mapView.map.initialViewpoint, 2.0, Enums.AnimationCurveEaseInOutCubic)

                        }
                    }
                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 1
                        verticalOffset: 3 * scaleFactor
                        radius: 12 * scaleFactor
                        samples: 25
                        color: "#25000000"//colors.softShadow
                    }
                }

                Rectangle{
                    Layout.preferredWidth: 56 * app.scaleFactor
                    Layout.preferredHeight: 56 * scaleFactor
                    radius:height/2
                    visible:(!isInShapeEditMode && !isInShapeCreateMode) || sketchEditorManager.selectedDrawMode === sketchEditorManager._editMode.pan


                    Controls.Icon {
                        id: locationBtn
                        anchors.fill:parent
                        imageSource: "../images/location.svg"
                        maskColor: mapView.devicePositionSource.active  ? "steelBlue" : colors.blk_200

                        onClicked: {
                            if(!((Qt.platform.os === "ios") || (Qt.platform.os == "android")))

                                mapView.zoomToLocation()
                            else
                            {
                                if (Permission.checkPermission(Permission.PermissionTypeLocationWhenInUse) === Permission.PermissionResultGranted)
                                {

                                    mapView.zoomToLocation()

                                }
                                else
                                {

                                    permissionDialog.permission = PermissionDialog.PermissionDialogTypeLocationWhenInUse;
                                    permissionDialog.open()

                                }
                            }

                        }
                    }

                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 1
                        verticalOffset: 3 * scaleFactor
                        radius: 12 * scaleFactor
                        samples: 25
                        color: "#25000000"//colors.softShadow
                    }

                }


                Rectangle{
                    Layout.preferredWidth: 56 * app.scaleFactor
                    Layout.preferredHeight: 56 * scaleFactor
                    radius:height/2
                    color:"transparent"

                    opacity: mapView.mapRotation ? 1 : 0
                    Controls.Icon {
                        anchors.fill:parent
                        imageWidth: parent.width
                        imageHeight: imageWidth
                        imageSource: "../images/compass.png"
                        //maskColor:colors.blk_200
                        rotation: mapView.mapRotation
                        //opacity: mapView.mapRotation ? 1 : 0

                        onClicked: {
                            mapView.setViewpointRotation(mapView.initialMapRotation)

                        }
                    }
                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 1
                        verticalOffset: 3 * scaleFactor
                        radius: 12 * scaleFactor
                        samples: 25
                        color: "#25000000"//colors.softShadow
                    }

                }


                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            Item{
                id:createnewBtn
                width:app.units(68)
                height:app.units(68)
                anchors.bottom: parent.bottom
                anchors.bottomMargin: app.notchHeight//16 * scaleFactor
                anchors.right: parent.right
                anchors.rightMargin: units(2)

                visible: !measureToolIcon.checked && supportEditing && !spatialSearchIcon.checked  && panelPageLoader.item === null && app.isOnline  && mapPage.mapProperties["isMapArea"] === false

                // visible: !measureToolIcon.checked && supportEditing && app.isOnline  && !isShowingCreateNewFeature  && mapPage.mapProperties["isMapArea"] === false && !isInEditMode && !isInShapeCreateMode && !isInShapeEditMode

                Controls.FloatingButton{
                    id:createNewFeatureBtn

                    MouseArea{
                        anchors.fill:parent
                        onClicked: {
                            if(!createNewFeatureBtn.checked)
                            {
                                isShowingCreateNewFeature = true

                                mapPage.savingInProgress = false
                                let portalItem = mapPage.portalItem
                                let _portal = portalSearch.portal
                                featuresManager.updateLicenseIfLite(portalItem,_portal)
                                mapView.populateEditableLayerList()
                                identifyProperties.clearHighlightInLayer()
                                panelDockItem.addDock("createnewfeature",app.tabNames.kCreateNewFeature)

                                if( !app.isLandscape )
                                {
                                    pageView.state = "anchortop"
                                    app.isExpandButtonClicked = true
                                }
                                else
                                    pageView.state = "anchorright"
                            }
                        }


                    }

                }
            }

            FloorFilter {
                id: floorFilter
                height: 400 * scaleFactor
                anchors.top: mapControls.top
                anchors.topMargin: app.baseUnit

                geoView: mapView
                onFloorSearchDialogOpenedChanged: {

                }
            }

            function zoomToLocation()
            {
                if (!mapView.locationDisplay.started) {

                    mapView.locationDisplay.start()
                    mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeRecenter
                }
                else {
                    mapView.locationDisplay.stop()
                }
            }

            PermissionDialog {
                id:permissionDialog
                openSettingsWhenDenied: true

                onRejected:{


                }
                onAccepted:{

                }


            }

            locationDisplay {
                dataSource: DefaultLocationDataSource { //Set the dataSource property inside locationDisplay qmlProperty of MapView QML type
                    id: defaultLocationDataSource
                }
            }

            SimpleFillSymbol {
                id: simpleFillSymbol
                color: "transparent"
                style: Enums.SimpleFillSymbolStyleSolid

                SimpleLineSymbol {
                    style: Enums.SimpleLineSymbolStyleSolid
                    color: "cyan"
                    width: app.units(2)
                }
            }


            SimpleFillSymbol {
                id: bufferSimpleFillSymbol
                color: "transparent"
                style: Enums.SimpleFillSymbolStyleSolid

                SimpleLineSymbol {
                    style: Enums.SimpleLineSymbolStyleSolid
                    color: "cyan"
                    width: app.units(2)
                }
            }



            SimpleFillSymbol {
                id: simpleMapAreaFillSymbol
                color: "transparent"
                style: Enums.SimpleFillSymbolStyleSolid

                SimpleLineSymbol {
                    style: Enums.SimpleLineSymbolStyleSolid
                    color: "brown"
                    width: app.units(2)
                }
            }

            SimpleLineSymbol {
                id: simpleLineSymbol

                style: Enums.SimpleLineSymbolStyleSolid
                color: "cyan"
                width: app.units(2)
            }

            SimpleLineSymbol {
                id: simpleLineSymbol1

                width: 2
                color: "white"

            }

            SimpleMarkerSymbol {
                id: routeStartSymbol
                color: "yellow"
                size: 10.0
                style: Enums.SimpleMarkerSymbolStyleCircle

                // declare the symbol's outline
                outline:SimpleLineSymbol {
                    style: Enums.SimpleLineSymbolStyleSolid
                    width: app.units(2)
                    color: "#66ff00"
                }
            }
            SimpleMarkerSymbol {
                id: routeStopSymbol
                color: "yellow"
                size: 10.0
                style: Enums.SimpleMarkerSymbolStyleCircle

                // declare the symbol's outline
                outline:SimpleLineSymbol {
                    style: Enums.SimpleLineSymbolStyleSolid
                    width: app.units(2)
                    color: "#de1738"
                }
            }




            GraphicsOverlay{
                id: spatialQueryGraphicsOverlay
            }


            GraphicsOverlay{
                id: polygonGraphicsOverlay
            }

            GraphicsOverlay{
                id: elevationpointGraphicsOverlay
            }

            GraphicsOverlay{
                id: pointGraphicsOverlay

            }
            GraphicsOverlay{
                id: sketchGraphicsOverlay
                renderer: SimpleRenderer {
                    symbol:  SimpleLineSymbol {
                        style: Enums.SimpleLineSymbolStyleSolid
                        color: "black"
                        width: app.units(2)
                    }
                }
            }

            GraphicsOverlay {
                id: lineGraphicsOverlay
            }
            GraphicsOverlay{
                id:routeGraphicsOverlay
                SimpleRenderer {
                    SimpleLineSymbol {
                        id: lineSymbol

                        color: mapView.routeColor//"app.primaryColor"
                        style: Enums.SimpleLineSymbolStyleSolid
                        width: 6
                    }
                }
                renderingMode: Enums.GraphicsRenderingModeStatic
            }
            GraphicsOverlay{
                id:routePartGraphicsOverlay

                SimpleRenderer {
                    SimpleLineSymbol {
                        id: routelineSymbol

                        color: "cyan"
                        style: Enums.SimpleLineSymbolStyleSolid
                        width: 6
                    }
                }
                renderingMode: Enums.GraphicsRenderingModeStatic

            }

            GraphicsOverlay {
                id: placeSearchResult
                SimpleRenderer {
                    PictureMarkerSymbol{
                        width: app.units(32)
                        height: app.units(32)
                        url: "../images/pin.png"
                    }
                }
            }

            Timer{
                id:elapsedTimer
                interval:500
                repeat:true
                onTriggered:mapView.isZooming()
            }

            PictureMarkerSymbol {
                id: basePictureMarkerSymbol
                url: "../images/pin.png"
                opacity: 0.5
                width: 20
                height: 20

            }

            GraphicsOverlay {
                id: routeStopsGraphicsOverlay
                SimpleRenderer{
                    SimpleMarkerSymbol {
                        id: routeStartSymbol1
                        color: "yellow"
                        size: app.units(14)
                        style: Enums.SimpleMarkerSymbolStyleCircle

                        // declare the symbol's outline
                        outline:SimpleLineSymbol {
                            style: Enums.SimpleLineSymbolStyleSolid
                            width: app.units(2)
                            color: "#66ff00"
                        }
                    }
                }

                /*SimpleRenderer {
                    PictureMarkerSymbol{
                        id:startSymbol
                        width: app.units(20)
                        height: app.units(20)
                        url: "../images/start.png"


                    }
                }*/

            }
            GraphicsOverlay {
                id: routeToStopGraphicsOverlay

                SimpleRenderer {
                    SimpleMarkerSymbol {
                        id: routeStopSymbol1
                        color: "yellow"
                        size: 14.0
                        style: Enums.SimpleMarkerSymbolStyleCircle

                        // declare the symbol's outline
                        outline:SimpleLineSymbol {
                            style: Enums.SimpleLineSymbolStyleSolid
                            width: app.units(2)
                            color: "#de1738"
                        }
                    }


                    //                    PictureMarkerSymbol{
                    //                        width: app.units(32)
                    //                        height: app.units(32)
                    //                        url: "../images/pin.png"
                    //                    }
                }

            }
            GraphicsOverlay {
                id: routePedestrianlineGraphicsOverlay
                SimpleRenderer{
                    SimpleLineSymbol {
                        id: pedestrianlineSymbol
                        color: mapView.routeColor
                        style: Enums.SimpleLineSymbolStyleDash
                        width: 3
                    }
                }
            }


            function isZooming()
            {
                isScaleChanged = true
                populateVisibleLayers()

                elapsedTimer.stop()

            }

            Timer {
                id: legendContentTimer
            }

            function sortLegendContentAfterTimeInterval()
            {
                legendContentTimer.interval = 0
                legendContentTimer.repeat = false
                legendContentTimer.triggered.connect(sortLegendContent)

                legendContentTimer.start();

            }

            function storeDefQueryOfLayer(layer)
            {
                if(layer.subLayerContents && layer.subLayerContents.length > 0)
                {
                    for(let k=0;k< layer.subLayerContents.length; k++)
                    {
                        let sublyr = layer.subLayerContents[k]
                        storeDefQueryOfLayer(sublyr)
                    }
                }
                else
                {
                    let lyrDefQuery = definitionQueryDic[layer.name]
                    if(lyrDefQuery === undefined && layer.definitionExpression)
                        definitionQueryDic[layer.name] = layer.definitionExpression
                }
            }

            function storeTheOriginalDefQueryOfLayers()
            {
                let  layers = mapView.map.operationalLayers
                let count = layers.count || layers.length
                if(count)
                {
                    for (var i=count; i--;) {
                        try{
                            let layer = mapView.map.operationalLayers.get(i)
                            storeDefQueryOfLayer(layer)
                            featureTableDictionary[layer.name] = layer.featureTable
                        }
                        catch(ex)
                        {
                            console.error("error in fetching layer")
                        }
                    }
                }

            }




            function processLoadStatusChange () {
                switch (mapView.map.loadStatus) {
                case Enums.LoadStatusLoaded:
                    if(!mapView.mapInitialized)
                    {
                        storeTheOriginalDefQueryOfLayers()
                        if(mapView.mmpk.locatorTask)
                        {
                            if(mapView.map.transportationNetworks && mapView.map.transportationNetworks.length > 0)
                                mapPage.hasTransportationNetwork = true
                            else
                                mapPage.hasTransportationNetwork = false
                        }
                        else
                            mapPage.hasTransportationNetwork = false

                        legendManager.mapView = mapView
                        layerManager.mapView = mapView
                        //relatedRecordsManager.mapView = mapView
                        mapUnitsManager.mapView = mapView
                        //layerManager.mapView = mapView
                        legendManager.updateLayers()
                        mapView.updateMapInfo()
                        mapInitialized = true
                        busyIndicator.visible = false
                        isMapLoaded = true
                        layerManager.mapView = mapView
                        mapView.mapReadyCount += 1
                        if (app.isLandscape && app.isLandscape && mapView.mapReadyCount <= 1) {
                            infoIcon.checked = true
                        }

                        if (mapView && mapView.map) {
                            if(mapView && mapView.map && mapView.map.initialViewpoint)
                            {
                                var mapExtent = ArcGISRuntimeEnvironment.createObject("EnvelopeBuilder", { geometry: seakEnvelope })
                                mapView.center = mapExtent.center
                                mapView.map.minScale = 10000000
                            }
                        }

                        if (mmpk.locatorTask) {
                            mmpk.locatorTask.onLoadStatusChanged.connect(function () {
                                if (mmpk.locatorTask.loadStatus === Enums.LoadStatusLoaded) {
                                    if (mmpk.locatorTask.suggestions) {
                                        mmpk.locatorTask.suggestions.suggestParameters = ArcGISRuntimeEnvironment.createObject("SuggestParameters", { maxResults: 10, preferredSearchLocation: mapView.center })
                                    }
                                }
                            })
                            mmpk.locatorTask.load()
                        }
                        measurePanel.setUnitByScale(mapView.mapScale)
//                        more.updateMenuItemsContent()
                        // keepTrackOfOriginalLayerVisForFilter()

                        infoIcon.checked = true

                    }

                    break
                }
            }


            function processLoadErrorChange () {
                app.messageDialog.connectToAccepted(function () {
                    if (mapView) {
                        if (mapView.map.loadStatus !== Enums.loadStatusLoaded) {
                            if(!app.isEmbedded  && app.parent)
                                app.parent.exitApp()
                            else
                                previous()
                        }
                    }
                })
                var title = mapView.map.loadError.message
                var message = mapView.map.loadError.additionalMessage
                if (!title || !message) {
                    message = message ? message : title
                    title = ""
                }
                app.messageDialog.show (title, message)
            }

            function getLocatorErrorMessage(locatorTask)
            {
                let errorMsg = ""
                if (locatorTask && locatorTask.loadError !== null)
                {
                    let _errorMsg = locatorTask.loadError.additionalMessage
                    if(_errorMsg.includes("ArcGIS runtime is not licensed to use the Street Map"))
                        errorMsg = strings.locator_not_licensed
                    else if(_errorMsg.includes("Locators created with the Create Address Locator"))
                        errorMsg = strings.locator_not_supported
                    else
                        errorMsg = strings.locator_loading_error

                }
                return errorMsg

            }

            function populateEditableLayerList()
            {

                editableLayerList = sketchEditorManager.getEditableLayerList()

                // panelDockItem.addDock("createNewFeature",app.tabNames.kCreateNewFeature)


            }


            function updateModelForFeatureTypes(element,layer)
            {
                var _featureTable = layer.table
                if(!_featureTable)
                    _featureTable = layer.featureTable
                if(layer.featureTable){

                    if(_featureTable.featureTypes){

                        var _featureTypes = _featureTable.featureTypes

                        for(var k=0;k<_featureTypes.length;k++)
                        {
                            var _featType = _featureTypes[k]
                            let _template = _featType.templates
                            if(_featType.name === element.name || (_template && _template[0].name === element.name))
                                element.isFeatureType = true

                        }
                    }


                }
                return element


            }


            function updateModelForSpatialSearchConfig(item)
            {

                if(mapView.spatialSearchConfig && mapView.spatialSearchConfig.searchLayers){
                    const result = mapView.spatialSearchConfig.searchLayers.filter(obj => obj.layerName === item.layerName && obj.rootLayerName === item.rootLayerName);

                    if(result.length > 0)
                    {
                        if(result[0].legendName.length > 0)
                        {
                            if(result[0].legendName.includes(item.name))
                                item.isSelected = true
                            else
                                item.isSelected = false

                        }

                        else
                        {
                            if(item.name > "" && item.name !== "<all other values>")
                                item.isSelected = false
                            else
                                item.isSelected = true
                        }



                    }

                    else if(mapView.spatialfeaturesModel.count > 0 || spatialQueryGraphicsOverlay.graphics.count > 0)
                        item.isSelected = false
                    else
                        item.isSelected = false


                }


                return item
            }


            function populateLayerList()
            {
                for (let k=0;k<mapView.map.operationalLayers.count;k++)
                {
                    let item = mapView.map.operationalLayers.get(k)
                    layerList.append(item)
                }
            }

            function checkSubLayerVisibility(rootLayerName,layer)
            {
                if(layer){
                    if(layer.subLayerContents && layer.subLayerContents.length > 0)
                    {
                        for(let k=0;k < layer.subLayerContents.length; k++)
                        {
                            let sublyr = layer.subLayerContents[k]
                            checkSubLayerVisibility(rootLayerName,sublyr)
                        }
                    }
                    else
                    {
                        // if (layer.visible  && layer.isVisibleAtScale(mapView.mapScale)){
                        if (layer.isVisibleAtScale(mapView.mapScale)){
                            let key = rootLayerName + "_" + layer.name
                            visibleLayersList.push(key)
                        }
                    }
                }

            }

            //
            function  populateVisibleLayers()
            {
                //var visibleLayersList = []
                visibleLayersList = []

                let layerList = mapView.map.operationalLayers


                // if(!layers)
                // layers = layerList

                //loop through the operational layers and update the subLayers based on their visibility
                //Some layers  may have scale dependency. So we need to check the visibility
                //of the layers/sublayers based on the mapscale and prepare the legend accordingly
                //console.log("visiblelacount:",layerList.count)


                for (let k=0; k<layerList.count; k++)
                {
                    let layer = layerList.get(k)


                    if (layer && layer.visible  && layer.isVisibleAtScale(mapView.mapScale))
                    {
                        if(layer.subLayerContents && layer.subLayerContents.length > 0)
                        {
                            checkSubLayerVisibility(layer.name,layer,legendManager.visibleLayersList)

                        }
                        else
                        {
                            //add to visible layers list
                            visibleLayersList.push(layer.name)
                        }

                    }

                }


            }

            function  populateVisibleLayers_()
            {
                //var visibleLayersList = []
                visibleLayersList = []

                layerList = mapView.map.operationalLayers


                // if(!layers)
                // layers = layerList

                //loop through the operational layers and update the subLayers based on their visibility
                //Some layers  may have scale dependency. So we need to check the visibility
                //of the layers/sublayers based on the mapscale and prepare the legend accordingly
                //console.log("visiblelacount:",layerList.count)


                for (let k=0; k<layerList.count; k++)
                {
                    let layer = layerList.get(k)


                    if (layer.visible  && layer.isVisibleAtScale(mapView.mapScale))
                    {
                        if(layer.subLayerContents && layer.subLayerContents.length > 0)
                        {
                            checkSubLayerVisibility(layer.name,layer,visibleLayersList)

                        }
                        else
                        {
                            //add to visible layers list
                            visibleLayersList.push(layer.name)
                        }

                    }

                }


            }


            function zoomToPoint (point, scale) {
                if (!scale) scale = 10000
                var centerPoint = GeometryEngine.project(point, mapView.spatialReference)
                var viewPointCenter = ArcGISRuntimeEnvironment.createObject("ViewpointCenter", {center: centerPoint, targetScale: scale})
                mapView.setViewpointWithAnimationCurve(viewPointCenter, 2.0, Enums.AnimationCurveEaseInOutCubic)

            }

            function zoomToExtent (_envelope) {
                //mapView.setViewpointGeometryAndPadding(extent, 80);
                var envelope
                if(_envelope.spatialReference.wkid !== mapView.map.spatialReference.wkid)
                    envelope =  GeometryEngine.project(_envelope, mapView.spatialReference)
                else
                    envelope = _envelope

                var envBuilder = ArcGISRuntimeEnvironment.createObject("EnvelopeBuilder",{geometry:envelope,spatialReference:mapView.map.spatialReference})
                envBuilder.expandByFactor(1.5)
                var viewPointExtent = ArcGISRuntimeEnvironment.createObject("ViewpointExtent", {extent: envBuilder.geometry})
                mapView.setViewpointWithAnimationCurve(viewPointExtent, 2.0, Enums.AnimationCurveEaseInOutCubic)
            }

            function showPin (point) {
                hidePin(function () {
                    var pictureMarkerSymbol = ArcGISRuntimeEnvironment.createObject("PictureMarkerSymbol", {width: app.units(32), height: app.units(32), url: "../images/pin.png"})
                    var graphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: point})
                    placeSearchResult.visible = true
                    placeSearchResult.graphics.insert(0, graphic)
                })
            }

            function hidePin (callback) {
                placeSearchResult.visible = false
                placeSearchResult.graphics.remove(0, 1)
                if (callback) callback()
            }

            //-------------------------MEASURE TOOL-------------------------------------------------------------

            property color measureSymbolColor: measurePanel.colorObject ? measurePanel.colorObject.colorName : "#F89927"
            property color measureSymbolColorAlpha: measurePanel.showFillColor ? (measurePanel.colorObject ? measurePanel.colorObject.alpha : "#59F89927") : "transparent"

            GraphicsOverlay {
                id: labels

                visible: measurePanel.showSegmentLength && lineGraphics.visible
                labelsEnabled: true

                onComponentCompleted: {
                    var textSymbol = ArcGISRuntimeEnvironment.createObject("TextSymbol", {size: app.baseFontSize, backgroundColor: app.backgroundColor, color: app.baseTextColor})
                    var textSymbolJSON = textSymbol.json
                    var pointLabelDefinitionJSON = {"labelExpressionInfo" : {"expression" : "$feature.length"}, "labelPlacement": "esriServerLinePlacementAboveAlong", "symbol": textSymbolJSON}
                    var pointLabelDefinition = ArcGISRuntimeEnvironment.createObject("LabelDefinition", {json: pointLabelDefinitionJSON})
                    labelDefinitions.append(pointLabelDefinition)
                }
            }

            GraphicsOverlay {
                id: lineGraphics

                property bool isUndoable: done.length > 0
                property bool isRedoable: unDone.length > 0

                // list of points
                property var done: []
                property var unDone: []

                function hasData () {
                    return done.length || unDone.length
                }

                function add (item, clearHistory) {
                    done.push(item)
                    if (clearHistory) unDone = []
                    recount()
                }

                function remove () {
                    unDone.push(done.pop())
                    recount()
                }

                function reset () {
                    done = []
                    unDone = []
                    recount()
                }

                function recount () {
                    isUndoable = done.length > 0
                    isRedoable = unDone.length > 0
                }

                visible: captureType === "line" && (measureToolIcon.checked || measurePanel.state !== "MEASURE_MODE")
            }

            GraphicsOverlay{
                id: areaGraphics

                property bool isUndoable: done.length > 0
                property bool isRedoable: unDone.length > 0

                // list of points
                property var done: []
                property var unDone: []

                function hasData () {
                    return done.length || unDone.length
                }

                function add (item, clearHistory) {
                    done.push(item)
                    if (clearHistory) unDone = []
                    recount()
                }

                function remove () {
                    unDone.push(done.pop())
                    recount()
                }

                function reset () {
                    done = []
                    unDone = []
                    recount()
                }

                function recount () {
                    isUndoable = done.length > 0
                    isRedoable = unDone.length > 0
                }

                visible: captureType === "area" && (measureToolIcon.checked || measurePanel.state !== "MEASURE_MODE")
            }

            PolylineBuilder {
                id: polylineBuilder
                spatialReference: mapView.spatialReference
            }

            PolygonBuilder {
                id: polygonBuilder
                spatialReference: mapView.spatialReference
            }

            SimpleFillSymbol {
                id: fillSymbol
                color: mapView.measureSymbolColorAlpha
                style: Enums.SimpleFillSymbolStyleSolid

                SimpleLineSymbol {
                    style: Enums.SimpleLineSymbolStyleSolid
                    color: mapView.measureSymbolColor
                    width: app.units(4)
                }
            }

            SimpleLineSymbol {
                //id: lineSymbol
                color: mapView.measureSymbolColor
                style: Enums.SimpleLineSymbolStyleSolid
                width: app.units(4)
            }

            SimpleMarkerSymbol {
                id: measurePointSymbol
                color: mapView.measureSymbolColor
                style: Enums.SimpleMarkerSymbolStyleCircle
                size: 8
            }

            SimpleMarkerSymbol {
                id: primaryColorSymbol
                color: mapView.measureSymbolColor
                style: Enums.SimpleMarkerSymbolStyleCircle
                size: 12
                outline: SimpleLineSymbol {
                    style: Enums.SimpleLineSymbolStyleSolid
                    color: "#FFFFFF"
                    width: app.units(2)
                }
            }

            function redoGraphic () {
                var point
                if (captureType === "line" && lineGraphics.isRedoable) {
                    point = lineGraphics.unDone.pop()
                    addPointToPolyline(point, false)
                    drawPoint(point, lineGraphics)
                    lineGraphics.recount()
                } else if (captureType === "area" && areaGraphics.isRedoable) {
                    point = areaGraphics.unDone.pop()
                    addPointToPolygon(point, false)
                    drawPoint(point, areaGraphics)
                    areaGraphics.recount()
                }
            }

            function undoPolyline(graphicOverlay){
                var polylinePart = polylineBuilder.parts.part(0);
                polylinePart.removePoint(polylinePart.pointCount-1, 1);
                var graphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: lineSymbol, geometry: polylineBuilder.geometry, zIndex: 1});
                graphicOverlay.graphics.remove(0, 1);
                graphicOverlay.graphics.insert(0, graphic);

                var previousPoint = graphicOverlay.graphics.get(graphicOverlay.graphics.count-3);
                var previousGeometry = previousPoint.geometry;
                var newPointGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: primaryColorSymbol, geometry: previousGeometry, zIndex: 3});
                graphicOverlay.graphics.remove(graphicOverlay.graphics.count-1,1);
                graphicOverlay.graphics.remove(graphicOverlay.graphics.count-1,1);
                graphicOverlay.graphics.append(newPointGraphic);

                graphicOverlay.remove()
                labels.graphics.remove(labels.graphics.count - 1)
                measurePanel.value = mapView.getDetailValue();
            }

            function undoPolygon(graphicOverlay){
                var polygonPart = polygonBuilder.parts.part(0);
                polygonPart.removePoint(polygonPart.pointCount-1, 1);
                var graphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: fillSymbol, geometry: polygonBuilder.geometry, zIndex: 1});
                graphicOverlay.graphics.remove(0, 1);
                graphicOverlay.graphics.insert(0, graphic);

                var previousPoint = graphicOverlay.graphics.get(graphicOverlay.graphics.count-3);
                var previousGeometry = previousPoint.geometry;
                var newPointGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: primaryColorSymbol, geometry: previousGeometry, zIndex: 3});
                graphicOverlay.graphics.remove(graphicOverlay.graphics.count-1,1);
                graphicOverlay.graphics.remove(graphicOverlay.graphics.count-1,1);
                graphicOverlay.graphics.append(newPointGraphic);

                graphicOverlay.remove()
                measurePanel.value = mapView.getDetailValue();
            }

            function resetMeasureTool () {
                polylineBuilder.parts.removeAll()
                lineGraphics.graphics.clear()
                lineGraphics.reset()
                labels.graphics.clear()
                polygonBuilder.parts.removeAll()
                areaGraphics.graphics.clear()
                areaGraphics.reset()
                measurePanel.value = 0
            }

            function clearGraphics(){
                labels.graphics.clear()
                if (captureType === "line") {
                    polylineBuilder.parts.removeAll();
                    lineGraphics.graphics.clear();
                    lineGraphics.reset()
                } else if (captureType === "area") {
                    polygonBuilder.parts.removeAll();
                    areaGraphics.graphics.clear()
                    areaGraphics.reset()
                }
                if (measurePanel.value === 0) {
                    measurePanel.mUnit.updateDistance()
                    measurePanel.mUnit.updateArea()
                } else {
                    measurePanel.value = 0;
                }
            }

            function draw (mouse) {
                if (captureType === "line"){
                    addPointToPolyline(mapView.screenToLocation(mouse.x, mouse.y), true);
                    drawPoint(mapView.screenToLocation(mouse.x, mouse.y), lineGraphics);
                } else if(captureType === "area") {
                    addPointToPolygon(mapView.screenToLocation(mouse.x, mouse.y), true);
                    drawPoint(mapView.screenToLocation(mouse.x, mouse.y), areaGraphics);
                }
            }

            function getMidPoint (p1, p2) {
                var x1 = p1.x
                var y1 = p1.y
                var x2 = p2.x
                var y2 = p2.y
                var Xmid = (x1+x2)/2
                var Ymid = (y1+y2)/2
                return ArcGISRuntimeEnvironment.createObject("Point", {x:Xmid, y:Ymid, spatialReference:mapView.spatialReference})
            }

            function addPointToPolyline (point, clearHistory) {
                lineGraphics.add(point, clearHistory)
                if(polylineBuilder.parts.empty || polylineBuilder.empty) {
                    var part = ArcGISRuntimeEnvironment.createObject("Part");
                    part.spatialReference = mapView.spatialReference;
                    var pCollection = ArcGISRuntimeEnvironment.createObject("PartCollection");
                    pCollection.spatialReference = mapView.spatialReference;
                    pCollection.addPart(part);
                    polylineBuilder.parts = pCollection;
                }
                point = GeometryEngine.project(point, polylineBuilder.spatialReference);

                var polylinePart = polylineBuilder.parts.part(0);

                if (polylinePart.pointCount) {
                    var p1 = polylinePart.point(polylinePart.pointCount-1)
                    var midPoint = getMidPoint (point, p1)
                    var simpleMarker = ArcGISRuntimeEnvironment.createObject("SimpleMarkerSymbol", {color: "transparent", size: 1, style: Enums.SimpleMarkerSymbolStyleCircle});
                    var labelGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: midPoint, symbol:simpleMarker, zIndex: 1})
                    var length = getDistance(p1, point)
                    labelGraphic.attributes.attributesJson = {"length": measurePanel.convert(length), "meters": length, "id": labels.graphics.count}
                    labels.graphics.append(labelGraphic)
                }

                polylinePart.addPoint(point);
                var graphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: lineSymbol, geometry: polylineBuilder.geometry, zIndex: 1});
                lineGraphics.graphics.remove(0, 1);
                lineGraphics.graphics.insert(0, graphic);

                measurePanel.value = mapView.getDetailValue();
            }

            function updateSegmentLengths () {
                labels.graphics.clear()
                for (var i=1; i<lineGraphics.done.length; i++) {
                    var p1 = lineGraphics.done[i-1]
                    var p2 = lineGraphics.done[i]
                    var length = getDistance(p1, p2)
                    var midPoint = getMidPoint(p1, p2)
                    var simpleMarker = ArcGISRuntimeEnvironment.createObject("SimpleMarkerSymbol", {color: "transparent", size: 1, style: Enums.SimpleMarkerSymbolStyleCircle});
                    var labelGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: midPoint, symbol:simpleMarker, zIndex: 1})
                    labelGraphic.attributes.attributesJson = {"length": measurePanel.convert(length), "meters": length, "id": labels.graphics.count}
                    labels.graphics.append(labelGraphic)
                }
            }

            function getDistance (p1, p2) {
                var results = GeometryEngine.distanceGeodetic(p1, p2, Enums.LinearUnitIdMeters, Enums.AngularUnitIdDegrees, Enums.GeodeticCurveTypeGeodesic)
                return results.distance
            }

            function drawPoint(point, graphicOverlay){
                var oldPointGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: measurePointSymbol, geometry: point, zIndex: 2});
                var newPointGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: primaryColorSymbol, geometry: point, zIndex: 3});
                var graphicsCount = graphicOverlay.graphics.count;
                if(graphicsCount>=3)graphicOverlay.graphics.remove(graphicsCount-1, 1);
                graphicOverlay.graphics.append(oldPointGraphic);
                graphicOverlay.graphics.append(newPointGraphic);
            }

            function addPointToPolygon(point, clearHistory){
                areaGraphics.add(point, clearHistory)
                if(polygonBuilder.parts.empty) {
                    var part = ArcGISRuntimeEnvironment.createObject("Part");
                    part.spatialReference = mapView.spatialReference;
                    var pCollection = ArcGISRuntimeEnvironment.createObject("PartCollection");
                    pCollection.spatialReference = mapView.spatialReference;
                    pCollection.addPart(part);
                    polygonBuilder.parts = pCollection;
                }

                point = GeometryEngine.project(point, polygonBuilder.spatialReference);

                var polygonPart = polygonBuilder.parts.part(0);

                polygonPart.addPoint(point);
                var graphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: fillSymbol, geometry: polygonBuilder.geometry, zIndex: 1});
                areaGraphics.graphics.remove(0, 1);
                areaGraphics.graphics.insert(0, graphic);

                measurePanel.value = mapView.getDetailValue();
            }

            function getDetailValue () {
                if (!mapView.map) return "";
                var center = (mapView.currentViewpointCenter && mapView.currentViewpointCenter && mapView.map.loadStatus === Enums.LoadStatusLoaded) ?
                            CoordinateFormatter.toLatitudeLongitude(mapView.currentViewpointCenter.center, Enums.LatitudeLongitudeFormatDecimalDegrees, 3)
                          : "";//qsTr("No Location Available.");
                if(captureType === "line"){
                    try { return polylineBuilder.geometry? Math.abs(GeometryEngine.lengthGeodetic(polylineBuilder.geometry, Enums.LinearUnitIdMeters, Enums.GeodeticCurveTypeGeodesic)):0;
                    } catch (err) {}
                } else if(captureType === "area"){
                    try { return polygonBuilder.geometry? Math.abs(GeometryEngine.areaGeodetic(polygonBuilder.geometry, Enums.AreaUnitIdSquareMeters, Enums.GeodeticCurveTypeGeodesic)):0;
                    } catch (err) {}
                }
                return 0//center + ""
            }


            RoundButton {
                id: searchExtentBtn
                //opacity: (mapView.featuresModel.count > 0) ? 1:0
                width: Math.max(19 * app.baseUnit,implicitWidth)
                height: 6 * app.baseUnit
                radius: 3 * app.baseUnit
                anchors.bottom: mapView.bottom
                anchors.bottomMargin: 24 * scaleFactor //2 * app.baseUnit
                anchors.horizontalCenter: parent.horizontalCenter
                text:strings.search_this_area
                Material.foreground: app.primaryColor
                Material.background: "#FFFFFF"
                Material.elevation: 2
                visible:spatialSearchIcon.checked && mapView.height > 0 && mapView.spatialfeaturesModel.searchMode === searchMode.extent && mapView.spatialfeaturesModel.count === 0
                contentItem: Text {
                    text: searchExtentBtn.text
                    font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    font.pixelSize: 14 * app.scaleFactor
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: "#2B2B2B"//colors.blk_200
                }

                onClicked: {

                    mapView.applySpatialSearchByExtent()


                }


            }

            RoundButton {
                id: cancelquerytBtn
                //opacity: (mapView.featuresModel.count > 0) ? 1:0
                width: Math.max(19 * app.baseUnit,implicitWidth)
                height: 6 * app.baseUnit
                radius: 3 * app.baseUnit
                anchors.bottom: mapView.bottom
                anchors.bottomMargin: 24 * scaleFactor //2 * app.baseUnit
                anchors.horizontalCenter: parent.horizontalCenter
                text:strings.cancel
                Material.foreground: app.primaryColor
                Material.background: "#FFFFFF"
                Material.elevation: 2
                visible:false
                contentItem: Text {
                    text: cancelquerytBtn.text
                    font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    font.pixelSize: 14 * app.scaleFactor
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: "#2B2B2B"//colors.blk_200
                }

                /*onClicked: {

                    mapView.cancelSpatialQuery()

                }*/
                MouseArea{
                    anchors.fill:parent
                    onClicked: {
                        mapView.cancelSpatialQuery()
                    }
                }


            }


            RoundButton {
                id: clearsearchresultsBtn
                //opacity: (mapView.featuresModel.count > 0) ? 1:0
                width: Math.max(19 * app.baseUnit,implicitWidth)
                height: 6 * app.baseUnit
                radius: 3 * app.baseUnit
                anchors.bottom: mapView.bottom
                anchors.bottomMargin: 24 * scaleFactor //2 * app.baseUnit
                anchors.horizontalCenter: parent.horizontalCenter
                text:strings.clear_search_results
                Material.foreground: app.primaryColor
                Material.background: "#FFFFFF"
                Material.elevation: 2
                visible:(mapView.spatialfeaturesModel.count > 0 || spatialQueryGraphicsOverlay.graphics.count > 0) && (mapView.spatialfeaturesModel.searchMode === searchMode.extent || mapView.spatialfeaturesModel.searchMode === searchMode.distance) && !cancelquerytBtn.visible  && mapView.height > 0
                contentItem: Text {
                    text: clearsearchresultsBtn.text
                    font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    font.pixelSize: 14 * app.scaleFactor
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: "#2B2B2B"//colors.blk_200
                }

                onClicked: {

                    if(mapView.spatialfeaturesModel.searchMode === searchMode.distance || mapView.spatialfeaturesModel.searchMode === searchMode.extent)
                    {
                        mapView.clearSpatialSearch()
                        mapView.hideSpatialSearchResults()

                    }

                }


            }



            Controls.Tooltip {
                id: spatialSearchLabel
                text: strings.spatialsearch_distance_tooltip

                visible: spatialSearchDockItem.visible && !clearsearchresultsBtn.visible && !cancelquerytBtn.visible && mapView.spatialfeaturesModel.searchMode === searchMode.distance
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    margins: app.baseUnit
                    bottomMargin: 24 * scaleFactor
                }
            }

            Controls.Tooltip {
                id: mapunitsLabel

                visible: false
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    margins: app.baseUnit
                }
            }



            Controls.Tooltip {
                id: measureToolTip

                visible: measureToolIcon.checked && (captureType === "line" && lineGraphics.graphics.count === 0 || captureType === "area" && areaGraphics.graphics.count === 0)
                text: captureType === "line" ? kDrawPath : kDrawArea
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    margins: app.baseUnit
                }
            }

            Pane {
                id: undoRedoDraw
                visible: (measureToolIcon.checked && !measureToolTip.visible)

                padding: 0
                leftPadding: app.defaultMargin
                rightPadding: app.defaultMargin
                width:(measureToolIcon.checked && !measureToolTip.visible)? 2*app.iconSize + clearText.width + 2*app.defaultMargin + 2 * app.baseUnit:clearText.width + 2*app.defaultMargin + 2 * app.baseUnit
                height: (2/3) * app.headerHeight
                Material.elevation: 4
                Material.background: "#FFFFFF"
                anchors {
                    right: parent.right
                    top: parent.top
                    topMargin: app.baseUnit
                    rightMargin: app.defaultMargin
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0


                    Controls.BaseText {
                        id: clearText
                        text: kClear
                        Layout.rightMargin: app.defaultMargin
                        verticalAlignment: Text.AlignVCenter

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mapView.clearGraphics()

                            }
                        }

                    }

                    Rectangle {
                        Layout.preferredHeight: parent.height - 2*app.baseUnit
                        Layout.preferredWidth: app.units(2)
                        color: app.backgroundColor
                    }

                    Controls.Icon {
                        imageSource: !app.isLeftToRight ? "../images/redo.png" : "../images/undo.png"
                        Layout.leftMargin: app.baseUnit
                        maskColor: {
                            if (captureType === "line") {
                                return lineGraphics.isUndoable ? app.darkIconMask : Qt.lighter(app.darkIconMask, 2.5)
                            } else if (captureType === "area") {
                                return areaGraphics.isUndoable ? app.darkIconMask : Qt.lighter(app.darkIconMask, 2.5)
                            }
                        }
                        imageWidth: 0.7 * iconSize
                        imageHeight: 0.7 * iconSize
                        visible:(measureToolIcon.checked && !measureToolTip.visible)
                        iconSize: 0.8 * app.iconSize-undoRedoDraw.topPadding-undoRedoDraw.bottomPadding
                        onClicked: {
                            if (captureType === "line" && lineGraphics.isUndoable) {
                                mapView.undoPolyline(lineGraphics)
                            } else if (captureType === "area" && areaGraphics.isUndoable) {
                                mapView.undoPolygon(areaGraphics)
                            }
                        }
                    }

                    Controls.Icon {
                        imageSource: !app.isLeftToRight ? "../images/undo.png" : "../images/redo.png"
                        Layout.rightMargin: app.baseUnit
                        maskColor: {
                            if (captureType === "line") {
                                return lineGraphics.isRedoable ? app.darkIconMask : Qt.lighter(app.darkIconMask, 2.5)
                            } else if (captureType === "area") {
                                return areaGraphics.isRedoable ? app.darkIconMask : Qt.lighter(app.darkIconMask, 2.5)
                            }
                        }
                        imageWidth: 0.7 * iconSize
                        imageHeight: 0.7 * iconSize
                        visible:(measureToolIcon.checked && !measureToolTip.visible)
                        iconSize: 0.8 * app.iconSize-undoRedoDraw.topPadding-undoRedoDraw.bottomPadding
                        onClicked: {
                            mapView.redoGraphic()
                        }
                    }
                }
            }

            RoundButton {
                id: identifyModeSwitch

                visible: (measureToolIcon.checked || measurePanel.isIdentifyMode) && (lineGraphics.hasData() || areaGraphics.hasData()) && !measureToast.visible
                radius: mapControls.radius
                Material.background: "#FFFFFF"
                width: 2 * mapControls.radius
                height: width
                anchors {
                    right: parent.right
                    bottom: locationAccuracy.visible ? locationAccuracy.top : parent.bottom
                    bottomMargin: locationAccuracy.visible ? measurePanel.defaultMargin : measurePanel.defaultHeight + app.defaultMargin
                    rightMargin: app.isLandscape ? app.widthOffset +  app.defaultMargin : app.defaultMargin
                }
                contentItem: Image {

                    id: identifyModeImg
                    source: "../images/rotate.png"
                    width: mapControls.radius
                    height: mapControls.radius
                    mipmap: true
                }
                ColorOverlay{
                    anchors.fill: identifyModeImg
                    source: identifyModeImg
                    color: "#4c4c4c"
                }
                onClicked: {
                    if (measurePanel.isIdentifyMode) {
                        measureToolIcon.checked = true
                        measureToast.isBodySet = false
                        measureToast.toVar = parent.height
                        measureToast.show(qsTr("Switched to measure mode."), parent.height, 1500)
                    } else {
                        measurePanel.isIdentifyMode = !measurePanel.isIdentifyMode
                        measureToast.isBodySet = false
                        if(isIphoneX)
                        {

                            measureToast.toVar = parent.height
                            measureToast.show(qsTr("Switched to identify mode."), parent.height, 1500)
                        }
                        else
                        {
                            measureToast.toVar = parent.height-measureToast.height-measurePanel.height - app.baseUnit
                            measureToast.show(qsTr("Switched to identify mode."), parent.height-measureToast.height-measurePanel.height - app.baseUnit, 1500)

                        }

                    }
                }
            }

            //-------------------------------------------------------------------------------------------------------

            Pane {
                id: locationAccuracy

                property string distanceUnit: Qt.locale().measurementSystem === Locale.MetricSystem ? "m" : "ft"
                property real accuracy: Qt.locale().measurementSystem === Locale.MetricSystem ? mapView.devicePositionSource.position.horizontalAccuracy : 3.28084 * mapView.devicePositionSource.position.horizontalAccuracy
                property real threshold: Qt.locale().measurementSystem === Locale.MetricSystem ? (50/3.28084) : 50

                visible: mapView.devicePositionSource.active && mapView.devicePositionSource.position.horizontalAccuracyValid && locationBtn.checked

                padding: 0
                Material.elevation: app.baseElevation + 2
                width: accuracyLabel.contentWidth + app.defaultMargin/2
                height: accuracyLabel.height
                background: Rectangle {
                    radius: app.units(1)
                    color: locationAccuracy.accuracy <= locationAccuracy.threshold ? "green" : "red"
                }
                anchors {
                    bottom: !app.isLandscape && measurePanel.visible ? measurePanel.top : parent.bottom
                    right: parent.right
                    rightMargin: app.defaultMargin + app.widthOffset
                    bottomMargin: app.defaultMargin + app.heightOffset + app.baseUnit
                }

                Controls.BaseText {
                    id: accuracyLabel

                    anchors.centerIn: parent
                    height: contentHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    color: "#FFFFFF"
                    text: "±%L1 %L2".arg(parseFloat(locationAccuracy.accuracy.toFixed(1)).toLocaleString(Qt.locale())).arg(locationAccuracy.distanceUnit)
                    fontSizeMode: Text.HorizontalFit
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    onClicked: {
                        mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeRecenter
                    }
                }
            }

            //-------------------------------------------------------------------------------------------------------
            //-------------------------------------------------------------------------------------------------------
            // adapted from https://stackoverflow.com/questions/6090740/image-rounded-corners-in-qml/32710773
            //-------------------------------------------------------------------------------------------------------
            RadioButton {
                id: screenShotThumbnail
                visible:screenShotsView.screenShots.count > 0

                property real aspectRatio: 96/80

                Material.elevation: app.baseElevation + 2
                height: app.units(56)//app.units(88)
                width: height//Math.max(height*aspectRatio, app.units(96))

                anchors {
                    left: parent.left
                    bottom: measurePanel.top
                    //margins: app.defaultMargin
                    leftMargin: app.isLandscape ? app.widthOffset + app.units(6) : app.units(6)
                    // bottomMargin:!measurePanel.visible ? 1.5 * app.defaultMargin + (app.isNotchAvailable() ? app.notchHeight:0):1.5 * app.defaultMargin
                    bottomMargin:!measurePanel.visible ? 38 * scaleFactor + (app.isNotchAvailable() ? app.notchHeight:0):38 * scaleFactor
                    // bottomMargin: 32 * scaleFactor
                }

                indicator:
                    Rectangle{
                    width:parent.width
                    height:width
                    radius: height/2
                    border.width:app.units(2)
                    border.color:"#151515"
                    color:"transparent"

                    Rectangle {
                        id:thumbnailmask
                        width:parent.width - 2
                        height:width
                        radius: height/2
                        anchors.centerIn: parent
                        //anchors.fill: parent
                        color: app.darkIconMask

                        Image {
                            id:thumbnailImg
                            width:parent.width
                            height:parent.height
                            property bool rounded: true
                            property bool adapt: true
                            layer.enabled: rounded
                            layer.effect: OpacityMask {
                                maskSource: Item {
                                    width: screenShotThumbnail.width //- app.unis(4)
                                    height: screenShotThumbnail.height //- app.units(4)
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: thumbnailImg.adapt ? thumbnailImg.width : Math.min(thumbnailImg.width, thumbnailImg.height)
                                        height: thumbnailImg.adapt ? thumbnailImg.height : width
                                        radius: Math.min(width, height)

                                    }
                                }
                            }

                            opacity: 0.45//0.8
                            source: {
                                var idx = screenShotsView.screenShots.count - 1
                                var item = screenShotsView.screenShots.get(idx)
                                return screenShotsView.screenShots.count && item ? item.url : ""
                            }

                        }

                        Controls.SubtitleText {
                            id: screenShotCount
                            visible: screenShotsView.screenShots.count
                            verticalAlignment: Qt.AlignVCenter
                            horizontalAlignment: Qt.AlignHCenter
                            anchors.centerIn: parent
                            text: qsTr("%L1").arg(screenShotsView.screenShots.count)
                            font.bold: true
                            color: "#FFFFFF"
                        }
                    }
                }
                onCheckedChanged: {
                    if (checked) {

                        //screenShotsView.listCurrentIndex = 0
                        toolBarBtns.uncheckButtons()
                        // mapPage.header.y = -app.headerHeight
                        mapPage.header.y = - (app.headerHeight + (app.isNotchAvailable() ? app.notchHeight:0))
                        screenShotsView.open()
                        pageView.hideSpatialSearch()
                    } else {
                        screenShotsView.close()
                        toolbarrow.visible = true
                    }
                }

                Component.onCompleted: {
                    aspectRatio = mapView.width/mapView.height
                }
            }

            SequentialAnimation {
                id: fullRotate
                PropertyAction {
                    target: screenShotCount
                    property: "text"
                    value:screenshotsCount//screenShotsView.screenShots.count
                }

                PropertyAnimation {
                    id: rotate_away
                    target:thumbnailmask //rotation
                    properties: "color"
                    from: app.darkIconMask
                    to: "white"
                    duration: 1000
                }



                PropertyAnimation {
                    id: rotate_new
                    target: thumbnailmask
                    properties: "color"
                    from: "white"
                    to: app.darkIconMask
                    duration: 1000
                }
                PropertyAction {
                    target: screenShotCount
                    property: "text"
                    value:screenshotsCount + 1//screenShotsView.screenShots.count
                }

            }

            ScreenShotsView {
                id: screenShotsView

                mapView: mapView
                onClosed: {
                    screenShotThumbnail.checked = false
                    //if(measurePanel.state !== "MEASURE_MODE")
                    mapPage.header.y = 0

                    toolBarBtns.uncheckButtons()
                }
                onOpened: {
                    pageView.hideSearchItem()
                    pageView.hideOfflineRoute()

                }

                onScreenShotTaken: {
                    measureToast.isBodySet = false
                    if(measurePanel.state === "MEASURE_MODE")
                    {
                        measureToast.toVar = parent.height - measureToast.height
                        measureToast.show(qsTr("Screenshot captured."), parent.height-measureToast.height, 1500)
                    }
                    else
                    {
                        if(screenShotsView.screenShots.count > 0)
                        {
                            fullRotate.start()
                            measureToast.toVar = parent.height - measureToast.height
                            measureToast.show(qsTr("Screenshot captured."), parent.height-measureToast.height, 1500)
                        }

                    }
                }
            }

            MeasurePanel {
                id: measurePanel

                onCameraClicked: {
                    screenShotsView.takeScreenShot()
                }

                onIsIdentifyModeChanged: {
                    if (isIdentifyMode) {
                        measureToolIcon.checked = false
                    }
                }

                z: parent.z + 2
                states: [
                    State {
                        when: showMeasureTool && !measurePanel.isIdentifyMode
                        name: "MEASURE_MODE"

                        PropertyChanges {
                            target: mapPageHeader
                            y: -(app.headerHeight + (app.isNotchAvailable()? app.notchHeight:0))

                        }

                        PropertyChanges {
                            target: undoRedoDraw
                            anchors.topMargin: app.defaultMargin + (app.isNotchAvailable()? app.notchHeight:0)
                        }

                        PropertyChanges {
                            target: measureToolTip
                            anchors.topMargin: app.defaultMargin + (app.isNotchAvailable()? app.notchHeight:0)

                        }

                        PropertyChanges {
                            target: placeSearchResult
                            visible: false
                        }
                    }
                ]

                onCopiedToClipboard: {
                    measureToast.show(qsTr("Copied to clipboard"), parent.height-measureToast.height-measurePanel.height )
                }

                onMeasurementUnitChanged: {
                    mapView.updateSegmentLengths()
                }
            }



            Controls.ToastDialog {
                id: measureToast
                z: parent.z + 1
                fromVar: parent.height
                enter: Transition {
                    NumberAnimation { property: "y";easing.type:Easing.InOutQuad; from:measureToast.fromVar; to:measureToast.toVar}
                }
                exit:Transition {
                    NumberAnimation { property: "y";easing.type:Easing.InOutQuad; from:measureToast.toVar; to:measureToast.fromVar}
                }
            }

            //------------------------------------------------------------------------------------------

            property MobileMapPackage mmpk: MobileMapPackage {
                id: mmpk

                signal mmpkLoaded ()

                onLoadStatusChanged: {
                    if (loadStatus === Enums.LoadStatusLoaded) {

                        loadMmpkMapInMapView (0)
                        //mapView.mapInitialized = true
                        for (var i=0; i<maps.length; i++) {
                            maps[i].maxExtent = seakEnvelope;
                            if(maps[i].item)
                            {
                                offlineMaps.append ({
                                                        "name": maps[i].item.title,
                                                        "isChecked": i === 0
                                                    })
                            }
                        }

                    }

                }

                function loadMmpkMapInMapView (idx) {
                    if (!idx) idx = 0
                    //legendManager.procLayers()

                    var map = mmpk.maps[idx]
                    if(map.loadStatus === Enums.LoadStatusLoaded)
                    {

                        mapView.map = map
                        mymap = map
                        mapView.processLoadStatusChange()
                    }
                    else
                    {

                        map.loadStatusChanged.connect(function () {
                            //busyIndicator.visible = true

                            mapView.processLoadStatusChange()
                        })

                        map.loadErrorChanged.connect(function () {
                            mapView.processLoadErrorChange()
                        })
                        mapView.map = map
                        mymap = map
                    }
                }

                function loadMmpk (path, idx) {
                    mmpk.path = path
                    mmpk.load()
                }
            }

            property alias offlineMaps: offlineMaps
            ListModel {
                id: offlineMaps
            }

            onViewpointChanged: {

                if(prevMapScale === mapView.mapScale)
                {

                    updateMapUnitsModel()
                    updateGridModel()
                }
                else
                    prevMapScale = (mapView.mapScale).valueOf()

            }


            onScaleChanged:{

                if(!isNaN(mapView.mapScale) && mapInitialized)
                {
                    let mapScale = "1:%1".arg(Math.round(mapView.mapScale))
                    mapunitsLabel.text = mapScale
                    if(!mapunitsLabel.visible && startShowScale)
                        mapunitsLabel.visible = true
                    else
                    {
                        mapunitsLabel.visible = false
                        startShowScale = true
                    }
                }

            }
            onNavigatingChanged:{

                // mapunitsLabel.visible = false

                if(!startNavigating)
                {

                    let mapScale = "1:%1".arg(Math.round(mapView.mapScale))
                    //mapunitsLabel.text = mapScale
                    if(prevMapScale !== mapView.mapScale)
                    {

                        // mapunitsLabel.visible = true

                    }
                    else
                    {
                        prevMapScale = mapView.mapScale
                        startNavigating = true

                    }

                }

                if(prevMapScale !== mapView.mapScale)
                {
                    startNavigating = false
                    prevMapScale = null
                    populateVisibleLayers()
                    legendManager.populateContentListBasedOnVisibility()
                    if(orderedLegendInfos.count === 0 || orderedLegendInfos.count !== unOrderedLegendInfos.count)
                        legendManager.sortUnorderedLegendInfos()

                    legendManager.populatelegendModel()


                }


            }


            onMousePressed: {
                if (app.showMapUnits &&
                        mapView.map.loadStatus === Enums.LoadStatusLoaded &&
                        !measureToolIcon.checked) {
                    mapunitsLabel.visible = true
                }
            }

            onMouseReleased: {

                mapunitsLabel.visible = false

            }

            onMouseClicked: {
                if (mapView.map.loadStatus === Enums.LoadStatusLoaded) {
                    if (measureToolIcon.checked && measurePanel.state === "MEASURE_MODE") {
                        draw(mouse)
                    } else {


                        if((!spatialSearchDockItem.visible) && !isInShapeEditMode && !isInShapeCreateMode)
                        {
                            isIdentifyTool=true
                            identifyInProgress = true
                            busyIndicator.visible=true
                            app.isInEditMode = false
                            identifyFeatures (mouse.x, mouse.y)
                        }
                        else
                        {
                            //mapView.spatialfeaturesModel.searchMode === searchMode.extent
                            if(spatialSearchDockItem.visible){
                                if((mapView.spatialfeaturesModel.features.length > 0) || mapView.spatialfeaturesModel.searchMode === searchMode.extent)
                                {
                                    //pageView.hideSpatialSearch()
                                    identifyFeatures (mouse.x, mouse.y)
                                }
                                else
                                {
                                    if(spatialSearchConfig ){
                                        mapView.spatialSearchInitialized = true
                                        let bufferDistance = spatialSearchConfig.distance

                                        var selectedPoint = mapView.screenToLocation(mouse.x, mouse.y)
                                        spatialSearchConfig.location = selectedPoint


                                        if(bufferDistance > 0){

                                            findFeaturesWithinBuffer(selectedPoint,bufferDistance)
                                        }
                                    }

                                }
                            }
                        }

                    }
                }
            }



            onIdentifyLayersStatusChanged: {
                switch (identifyLayersStatus) {
                case Enums.TaskStatusCompleted:
                    if (mapView.identifyLayersResults.length) {
                        if(mapView.spatialfeaturesModel.count === 0)
                            pageView.hideSpatialSearch()
                        mapView.identifyProperties.reset()
                        //populateIdentifyProperties(mapView.identifyLayersResults)
                        identifyBtn.currentPageNumber = 1
                        mapView.identifyProperties.currentFeatureIndex = 0
                        //need to reinitialize the array before processing the results
                        identifyManager.init()
                        identifyManager.populateIdentifyProperties(mapView.identifyLayersResults,mapPage.mapProperties)
                        //busyIndicator.visible=false
                    }
                    else
                    {
                        identifyInProgress = false
                        busyIndicator.visible=false
                    }

                    break
                }
            }



            function applySpatialSearchByExtent(){
                var extent = mapView.currentViewpointExtent.extent
                spatialqueryParameters.geometry = extent
                spatialqueryParameters.spatialRelationship = Enums.SpatialRelationshipContains//Enums.SpatialRelationshipIntersects
                var spatialSearchLayers = mapView.spatialSearchConfig.searchLayers

                if(!spatialSearchLayers)
                    spatialSearchLayers = []

                mapView.spatialfeaturesModel.clearAll()


                layersToSearch = [...spatialSearchLayers];

                let lyrindx = 0

                let lyrobj = null
                if(layersToSearch.length > 0)
                {
                    lyrobj = layersToSearch.pop()
                    let rootlyrname = lyrobj.rootLayerName
                    lyrindx =  mapView.getLayerIndex(rootlyrname)

                    mapView.spatialfeaturesModel.searchMode = searchMode.extent//searchMode.spatial
                    mapView.isSpatialSearchFinished = false
                    mapView.queryLayers(spatialSearchLayers,lyrobj,layersToSearch,extent)


                    identifyInProgress = true

                    setTimeout(10000);
                    mapView.isSpatialQueryCancelled = false
                }

            }


            function applySpatialSearchByDistance()
            {
                let bufferDistance = spatialSearchConfig.distance
                if(spatialSearchConfig.location && bufferDistance > 0)
                {
                    var removeDock = false
                    clearSpatialSearch(removeDock)
                    findFeaturesWithinBuffer(spatialSearchConfig.location, bufferDistance)
                }
            }


            function cancelAllTasks () {
                for (var i=0; i<mapView.tasksInProgress.length; i++) {
                    mapView.cancelTask(mapView.tasksInProgress[i])
                }
                mapView.tasksInProgress = []
            }


            function showIdentifyPanel () {
                if (mapView.identifyProperties.popupManagers.length) {
                    identifyBtn.checked = true
                    identifyBtn.currentEditTabName = "FEATURES"

                    identifyBtn.currentEditTabIndex = 0
                    //identifyInProgress = false


                    identifyBtn.checkIfAttachmentPresent(0)
                }
            }

            function identifyFeatures (x, y, tolerance, returnPopupsOnly, maxResults) {
                cancelAllTasks()
                //mapView.spatialfeaturesModel.searchMode = searchMode.attribute
                if (typeof tolerance === "undefined") tolerance = 10
                if (typeof returnPopupsOnly === "undefined") returnPopupsOnly = false
                if (typeof maxResults === "undefined") maxResults = 10
                var id = mapView.identifyLayersWithMaxResults(x, y, tolerance, returnPopupsOnly, maxResults)
                mapView.tasksInProgress.push(id)
            }


            function findFeaturesWithinBuffer(selectedPoint,bufferRadius,spatialSearchLayers)
            {


                mapView.isSpatialQueryCancelled = false
                mapView.isSpatialSearchFinished = false

                bufferRadius = spatialSearchConfig.distance


                spatialSearchLayers = spatialSearchConfig.searchLayers //dictionary{rootlayerName,sublayername}


                if(spatialSearchLayers.length > 0)
                {
                    identifyInProgress = true
                    setTimeout(10000);


                    mapView.hidePin()

                    mapView.spatialfeaturesModel.clearAll()

                    //add the point to the map

                    mapView.showPin(selectedPoint)
                    var pointGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: selectedPoint});
                    const bufferInMeters = spatialSearchConfig.distance
                    layersToSearch = [...spatialSearchLayers];

                    let lyrindx = -1

                    let lyrobj = null
                    if(layersToSearch.length > 0)
                    {
                        lyrobj = layersToSearch.pop()


                    }

                    //create the buffer
                    if(bufferRadius > 0 && lyrobj !== null){
                        var bufferGeometry = GeometryEngine.buffer(selectedPoint, bufferInMeters);
                        if(selectedPoint.spatialReference.wkid === 4326)//if geographic
                            bufferGeometry = GeometryEngine.bufferGeodetic(selectedPoint, bufferInMeters, Enums.LinearUnitIdMeters, NaN, Enums.geodesicCurveTypeGeodesic)

                        mapView.spatialfeaturesModel.searchGeometry = bufferGeometry
                        drawBuffer(bufferGeometry)
                        spatialqueryParameters.geometry = bufferGeometry
                        mapView.spatialQueryGeometry = bufferGeometry
                        spatialqueryParameters.spatialRelationship = Enums.SpatialRelationshipContains//Enums.SpatialRelationshipIntersects//Enums.SpatialRelationshipContains//Enums.SpatialRelationshipIntersects

                        queryLayers(spatialSearchLayers,lyrobj,layersToSearch,bufferGeometry)



                    }
                    else
                    {
                        identifyInProgress = false
                        searchtimer.stop()
                    }
                }

            }


            function clearSpatialSearch(removeDock)
            {
                if(removeDock === null && removeDock === "undefined")
                    removeDock = true

                spatialQueryGraphicsOverlay.graphics.clear()
                mapView.spatialfeaturesModel.searchGeometry = null
                hidePin()
                for (var k =0; k<mapView.orderedLegendInfos_spatialSearch.count;k++)
                {
                    var item = mapView.orderedLegendInfos_spatialSearch.get(k)

                    let rootLayerName = item.rootLayerName
                    if(!rootLayerName)
                        rootLayerName = item.layerName
                    let rootlyrindex =  getLayerIndex(rootLayerName)
                    var layername = item.layerName

                    let layer = getLayerByName_Index(rootlyrindex,layername,item.layerIndex)

                    if(layer){
                        let lyrDefQuery = definitionQueryDic[layer.name]
                        if(!(lyrDefQuery === undefined))
                            layer.definitionExpression = definitionQueryDic[layer.name]
                        else
                            layer.definitionExpression = ""
                    }

                }

                mapView.spatialfeaturesModel.clearAll()
                mapView.identifyProperties.clearHighlight()
                if(removeDock)
                    spatialSearchDockItem.removeDock()


            }



            function getLayerType(rootlyrindex)
            {
                let   layer = mapView.map.operationalLayers.get(rootlyrindex)
                return layer.objectType

            }

            function getLayerByIndex(rootlyrindex,layerIndex)
            {

                let   layer = mapView.map.operationalLayers.get(rootlyrindex)
                let targetlayer = getSubLayerByIndex(layer,layerIndex)
                return targetlayer

            }

            function getLayerByName_Index(rootlyrindex,layername,layerIndex)
            {

                let   layer = mapView.map.operationalLayers.get(rootlyrindex)
                let targetlayer = getSubLayer(layer,layername,layerIndex)
                return targetlayer

            }

            function getSubLayer(layer,targetLyrName,targetLyrIndex)
            {
                let targetlyr = null
                if(layer)
                {

                    if(layer.subLayerContents.length > 0)
                    {

                        for (var k=0;k<layer.subLayerContents.length;k++)
                        {

                            let sublyr = getSubLayerByIndex(layer.subLayerContents[k],targetLyrIndex)
                            if(sublyr !== null && sublyr !== "undefined" && (sublyr.sublayerId === targetLyrIndex.toString() || sublyr.layerId === targetLyrIndex.toString()))
                            {
                                targetlyr = sublyr
                                return targetlyr
                            }
                        }
                    }
                    else
                    {
                        if(layer.name === targetLyrName)
                        {
                            targetlyr = layer
                            return targetlyr
                        }


                    }
                }
                return targetlyr

            }



            function getSubLayerByIndex(layer,targetLyrIndex)
            {
                if(layer){
                    if(layer.sublayerId === targetLyrIndex.toString() || layer.layerId === targetLyrIndex.toString())
                        return layer
                    else
                    {
                        if(layer.subLayerContents.length > 0)
                        {
                            for (var k=0;k<layer.subLayerContents.length;k++)
                            {

                                let sublyr = getSubLayerByIndex(layer.subLayerContents[k],targetLyrIndex)
                                if(sublyr !== null && sublyr !== "undefined" && (sublyr.sublayerId === targetLyrIndex.toString() || sublyr.layerId === targetLyrIndex.toString()))
                                    return sublyr
                            }
                            return null

                        }
                        else
                            return null

                    }
                }
                else
                    return null
            }

            Timer {
                id: searchtimer
            }

            function setTimeout(delayTime) {

                searchtimer.interval = delayTime;
                searchtimer.repeat = false;
                searchtimer.triggered.connect(function(){
                    if(!mapView.isSpatialSearchFinished)
                        cancelquerytBtn.visible = true
                }
                );
                searchtimer.start();
            }

            function cancelSpatialQuery()
            {
                var isCancelled = false
                mapView.isSpatialQueryCancelled = true

                if(mapView.taskId_spatialQuery && mapView.currentTableForSpatialQuery)
                    isCancelled =  mapView.currentTableForSpatialQuery.cancelTask(mapView.taskId_spatialQuery)
                // if(isCancelled)
                // {

                identifyInProgress = false
                searchtimer.stop()
                cancelquerytBtn.visible = false
                mapView.isSpatialSearchFinished = true
                mapView.spatialSearchFinished()
                // if(mapView.nolayersforWhichQueryFailed > 0)
                //    showLayersFailedToQueryMessage()
                var spatialSearchLayers = spatialSearchConfig.searchLayers
                // hideFeaturesInOtherLayers(spatialSearchLayers)

                if(mapView.spatialfeaturesModel.searchMode === searchMode.distance)
                    zoomToSpatialSearchLayer(mapView.spatialQueryGeometry)
                // }


            }

            function queryLayers(spatialSearchLayers,lyrobj,layersToSearch,bufferGeometry)
            {
                if(!layersToSearch)
                    layersToSearch = [...spatialSearchLayers];


                var promiseToQueryLayers =  new Promise(
                            (resolve, reject)=>{
                                let rootLayerName = lyrobj.rootLayerName
                                if(rootLayerName === "")
                                rootLayerName = lyrobj.layerName

                                let rootlyrindex =  getLayerIndex(rootLayerName)
                                let layername = lyrobj.layerName


                                let layer = getLayerByName_Index(rootlyrindex,layername,lyrobj.layerIndex)


                                if(layer){
                                    if(layer.visible && layer.isVisibleAtScale(mapView.mapScale)){
                                        let layerType = getLayerType(rootlyrindex)


                                        queryLayerByLyrObject(layer,lyrobj.legendName,resolve)
                                    }
                                    else
                                    resolve()
                                }
                                else
                                resolve()



                            }
                            )


                promiseToQueryLayers.then(function(result){

                    if(spatialSearchLayers.length > 0){
                        //if(mapView.isSpatialQueryCancelled)
                        //    showLayersFailedToQueryMessage()
                        if(layersToSearch.length > 0  && !mapView.isSpatialQueryCancelled)
                        {
                            let nextlyrObj = layersToSearch.pop()

                            queryLayers(spatialSearchLayers,nextlyrObj,layersToSearch,bufferGeometry)


                        }
                        else
                        {

                            identifyInProgress = false
                            searchtimer.stop()
                            cancelquerytBtn.visible = false
                            mapView.spatialSearchFinished()
                            mapView.isSpatialSearchFinished = true

                            //hideFeaturesInOtherLayers(spatialSearchLayers)

                            if(mapView.spatialfeaturesModel.searchMode === searchMode.distance)
                                zoomToSpatialSearchLayer(bufferGeometry)

                        }
                    }
                    else
                    {

                        identifyInProgress = false
                        searchtimer.stop()
                        cancelquerytBtn.visible = false
                        mapView.spatialSearchFinished()
                        mapView.isSpatialSearchFinished = true

                        if(!spatialSearchView.showResults)
                            spatialSearchView.showResults = true


                    }


                })




            }

            function showLayersFailedToQueryMessage()
            {
                measureToast.isBodySet = false
                measureToast.toVar = parent.height-measureToast.height
                measureToast.show(qsTr("Failed to query some of the  layers.Please try again later."),parent.height - measureToast.height, 1500)
            }



            function hideFeaturesInOtherLayers(spatialSearchLayers)
            {

                for (var k =0; k<mapView.orderedLegendInfos_spatialSearch.count;k++)
                {
                    var item = mapView.orderedLegendInfos_spatialSearch.get(k)
                    if(!isItemPresentInSearchList(item,spatialSearchLayers))
                    {
                        let rootLayerName = item.rootLayerName
                        if(!rootLayerName)
                            rootLayerName = item.layerName
                        let rootlyrindex =  getLayerIndex(rootLayerName)
                        var layername = item.layerName
                        let layerIndex = item.layerIndex
                        let layer = getLayerByName_Index(rootlyrindex,layername,layerIndex)
                        var  _table = null

                        if(layer){

                            if(layer.loadStatus === Enums.LoadStatusLoaded){


                                if(layer.table)
                                    _table = layer.table
                                else if(layer.featureTable)
                                    _table = layer.featureTable

                                var uniqueFieldName = featuresManager.getUniqueFieldName(_table)

                                //console.log(layer.name)
                                layer.definitionExpression = `${uniqueFieldName} < -1`//definitionQueryDic[layer.name]
                                //layer.visible = false

                            }
                            else
                            {
                                layer.loadStatusChanged.connect(function(){
                                    if (layer.loadStatus === Enums.LoadStatusLoaded){
                                        if(layer.table)
                                            _table = layer.table
                                        else if(layer.featureTable)
                                            _table = layer.featureTable

                                        var uniqueFieldName = featuresManager.getUniqueFieldName(_table)

                                        // console.log(layer.name)
                                        layer.definitionExpression = `${uniqueFieldName} < -1`//definitionQueryDic[layer.name]
                                        //layer.visible = false

                                    }

                                }
                                )
                                layer.load()
                            }
                        }
                    }


                }


            }

            function isItemPresentInSearchList(item,spatialSearchLayers)
            {
                const result = spatialSearchLayers.filter(obj => obj.layerName === item.layerName && obj.rootLayerName === item.rootLayerName);
                if(result.length > 0)
                    return true
                else
                    return false
            }

            function queryLayerByLyrObject(layer,legendName,resolve)
            {
                //console.log("querying layer",layer.name)

                let lyrDefQuery = definitionQueryDic[layer.name]
                if(!(lyrDefQuery === undefined))
                    layer.definitionExpression = definitionQueryDic[layer.name]
                else
                {

                    definitionQueryDic[layer.name] = layer.definitionExpression

                }



                if(layer.loadStatus === Enums.LoadStatusLoaded){


                    buildAndExecuteQuery(layer,legendName,resolve)


                }
                else
                {
                    layer.loadStatusChanged.connect(function(){
                        if (layer.loadStatus === Enums.LoadStatusLoaded){
                            buildAndExecuteQuery(layer,legendName,resolve)

                        }

                    }
                    )
                    layer.load()

                }


            }

            function buildAndExecuteQuery(layer,legendNames,resolve)
            {
                let searchString = ""
                let _table = null

                if(layer.table)
                    _table = layer.table
                else if(layer.featureTable)
                    _table = layer.featureTable


                if(_table !== null){

                    let uniqueFieldName = featuresManager.getUniqueFieldName(_table)

                    if(legendNames.length > 0)
                    {
                        if(_table.featureTypes && _table.featureTypes.length > 0)
                            searchString = createAttributeQuery_ByFeatureType(_table,legendNames)


                        if(!searchString)
                        {
                            searchString = createAttributeQuery_ByRenderer(_table,legendNames,layer)
                        }


                    }

                    spatialqueryParameters.spatialRelationship = Enums.SpatialRelationshipIntersects
                    mapView.currentTableForSpatialQuery = _table
                    var promiseToQuery = queryFeatures(searchString, _table)
                    promiseToQuery.then(function(result){
                        mapView.taskId_spatialQuery = null
                        mapView.currentTableForSpatialQuery = null
                        const features = Array.from(result.iterator.features);

                        showSpatialFeatures(features,layer,uniqueFieldName)
                        if(resolve){

                            resolve()
                        }


                    })
                    .catch(error => {

                               console.error("error occurred",error.message)
                               resolve()


                           })
                }
                else
                {
                    resolve()

                }

            }



            function showSpatialFeatures(features,layer,_field)
            {
                var inputFeatures = features

                if(features.length > 0){


                    if(layer.visible){
                        var displayFieldName = features[0].featureTable.layerInfo.displayFieldName ? features[0].featureTable.layerInfo.displayFieldName : _field

                        if(_field){
                            var featureids = inputFeatures.map(obj => obj.attributes.attributeValue(_field));
                            inputFeatures.forEach(feature =>{

                                                      var popupDefinition = null
                                                      if(feature.featureTable)
                                                      popupDefinition = feature.featureTable.popupDefinition
                                                      if(!popupDefinition)
                                                      popupDefinition = ArcGISRuntimeEnvironment.createObject("PopupDefinition", {initGeoElement: feature})

                                                      var popUp = ArcGISRuntimeEnvironment.createObject("Popup", {initGeoElement: feature, initPopupDefinition: popupDefinition})
                                                      var popupManager = ArcGISRuntimeEnvironment.createObject("PopupManager", {popup: popUp})
                                                      popupManager.objectName = layer.name

                                                      mapView.spatialfeaturesModel.popupManagers.push(popupManager)

                                                      mapView.spatialfeaturesModel.popupDefinitions.push(popupDefinition)
                                                      var featureAttrValue = ""//popupManager.title
                                                      var attrValue=""
                                                      if(!featureAttrValue)
                                                      {
                                                          featureAttrValue = feature.attributes.attributeValue(displayFieldName)
                                                      }
                                                      if(!featureAttrValue){
                                                          featureAttrValue = feature.attributes.attributeValue(_field)
                                                          attrValue = `${_field}:${featureAttrValue}`
                                                      }
                                                      else
                                                      attrValue = `${displayFieldName}:${featureAttrValue}`

                                                      let lyrnameWithCount = !app.isLeftToRight ? `(${qsTr("%L1").arg(inputFeatures.length)}) ${layer.name}` : `${layer.name} (${inputFeatures.length})`



                                                      mapView.spatialfeaturesModel.append({
                                                                                              "layerNameWithCount":lyrnameWithCount, //layer.name,
                                                                                              "layerName":layer.name,
                                                                                              "search_attr":attrValue, //popupManager.title,
                                                                                              "extent": feature.geometry,
                                                                                              "showInView": false,
                                                                                              "initialIndex": mapView.featuresModel.features.length,
                                                                                              "hasNavigationInfo": false,
                                                                                              "distance":0
                                                                                          })
                                                      mapView.spatialfeaturesModel.features.push(feature)
                                                      if(!mapView.spatialfeaturesModel.sections.includes(lyrnameWithCount))
                                                      mapView.spatialfeaturesModel.sections.push(lyrnameWithCount)

                                                  })


                            var newexpr = ""

                            var existingExpr = layer.definitionExpression
                            var newexpression = `${_field} IN (${featureids})`
                            if(existingExpr  > "" && !existingExpr.includes(newexpression))
                                newexpr =`${existingExpr} AND ${_field} IN (${featureids})`
                            else
                                newexpr =`${_field} IN (${featureids})`


                            //create a definitionQuery
                            layer.definitionExpression = newexpr
                            mapView.showSpatialSearchResults()


                        }
                    }
                }
                else
                {
                    //layer.visible = false
                    layer.definitionExpression = `${_field} < -1`
                    mapView.showSpatialSearchResults()

                }
            }

            function zoomToSpatialSearchLayer(bufferGeometry)
            {
                if(app.isPhone)
                    mapView.setViewpointGeometryAndPadding(bufferGeometry,24)
                else
                    mapView.setViewpointGeometryAndPadding(bufferGeometry,64)

            }

            function queryFeatures(searchString, table){
                return new Promise(
                            (resolve, reject)=>{
                                let taskId;
                                // let parameters = ArcGISRuntimeEnvironment.createObject("QueryParameters");
                                if(searchString > "")
                                spatialqueryParameters.whereClause = searchString;
                                else
                                spatialqueryParameters.whereClause = ""



                                const featureStatusChanged = ()=> {
                                    switch (table.queryFeaturesStatus) {
                                        case Enums.TaskStatusCompleted:
                                        table.queryFeaturesStatusChanged.disconnect(featureStatusChanged);
                                        const result = table.queryFeaturesResults[taskId];
                                        if (result) {
                                            resolve(result);
                                        } else {
                                            reject({message: "The query finished but there was no result for this taskId", taskId: taskId});
                                        }
                                        break;
                                        case Enums.TaskStatusErrored:
                                        table.queryFeaturesStatusChanged.disconnect(featureStatusChanged);
                                        if (table.error) {
                                            reject(table.error);
                                        } else {
                                            reject({message: table.tableName + ": query task errored++++"});
                                        }
                                        break;
                                        default:
                                        break;
                                    }
                                }

                                table.queryFeaturesStatusChanged.connect(featureStatusChanged);
                                if(table.queryFeaturesWithFieldOptions)
                                taskId = table.queryFeaturesWithFieldOptions(spatialqueryParameters, Enums.QueryFeatureFieldsLoadAll);
                                else
                                taskId = table.queryFeatures(spatialqueryParameters);

                                mapView.taskId_spatialQuery = taskId
                            });
            }


            function getLayerIndex(layerName)
            {

                for (var i=0;i < mapView.map.operationalLayers.count; i++) {
                    var lyr = mapView.map.operationalLayers.get(i)
                    if(lyr.name === layerName)
                        return i

                }


            }

            function getDistanceInMeters(realValue, fromUnit)
            {
                switch (fromUnit) {
                case measurePanel.lengthUnits.meters:
                    realValue = parseFloat(realValue)
                    return realValue
                case measurePanel.lengthUnits.miles:
                    realValue = realValue * 1609.34
                    return realValue
                case measurePanel.lengthUnits.kilometers:
                    return (realValue*1000)
                case measurePanel.lengthUnits.feet:
                    return (realValue*0.3048)
                case measurePanel.lengthUnits.feetUS:
                    return (realValue*0.3)
                case measurePanel.lengthUnits.yards:
                    return (realValue*0.9144)
                case measurePanel.lengthUnits.nauticalMiles:
                    return (realValue*1852)
                default:
                    return realValue


                }
            }

            function drawBuffer(bufferGeometry)
            {
                spatialQueryGraphicsOverlay.graphics.clear()
                var graphic = ArcGISRuntimeEnvironment.createObject("Graphic",
                                                                    {symbol: bufferSimpleFillSymbol, geometry: bufferGeometry})
                spatialQueryGraphicsOverlay.graphics.append(graphic)

                //mapView.setViewpointGeometryAndPadding(spatialQueryGraphicsOverlay.extent,100)

            }

            function createAttributeQuery_ByRenderer(featureTable,legendnames,searchLayer)
            {

                var targetfieldname = ""
                var targetfieldvalue = ""
                var searchString = ""

                var _rendererObj = searchLayer.renderer
                if(_rendererObj.objectType === "UniqueValueRenderer"){
                    var fieldNames = _rendererObj.fieldNames
                    targetfieldname = fieldNames[0]
                }

                //var _targetfieldvalues = `(${targetfieldvalue})`

                var targetfieldValues = ""
                for(var k=0;k<legendnames.length; k++)
                {

                    var legendname = legendnames[k]
                    legendname = legendname.trim()
                    if(legendname > ""){
                        let subtypeField = featureTable.subtypeField
                        var fields = featureTable.fields
                        var isSubtype = false

                        let subtype_domain = []
                        if(subtypeField)
                        {
                            let subtypes = featureTable.featureSubtypes
                            let subtypeNames = []

                            for(var k1=0;k1<subtypes.length;k1++){
                                let subtype = subtypes[k1]
                                if(subtype.name === legendname)
                                {
                                    targetfieldname = subtypeField.name
                                    if(targetfieldValues.length > 1)
                                        targetfieldValues = targetfieldValues + "," + subtype.code //legendname
                                    else
                                        targetfieldValues = subtype.code //legendname
                                    isSubtype = true

                                }
                                //subtypeNames.push({"name":subtype.name,"code":subtype.code})
                            }
                            //check if the legendname is one of the subtypenames

                        }
                        if(!isSubtype)
                        {

                            for(var key in fields)

                            {
                                let field = fields[key]
                                if(field.name === targetfieldname){
                                    if(field.domain)
                                    {
                                        let domainObj = field.domain.codedValues
                                        for(var k2=0;k2<domainObj.length;k2++)
                                        {
                                            var domaincode =  domainObj[k2].code
                                            var domainname = domainObj[k2].name
                                            if(domainname === legendname)
                                            {
                                                targetfieldname = field.name

                                                if(targetfieldValues.length > 0)
                                                    targetfieldValues = targetfieldValues + ",'" + domaincode + "'"
                                                else
                                                    targetfieldValues =  "'" + domaincode + "'"

                                                // targetfieldvalue = domaincode
                                                break
                                            }


                                        }

                                    }
                                    else
                                    {
                                        // if(field.name === targetfieldname){
                                        var fieldtype = field.fieldType
                                        if(targetfieldValues.length > 0)
                                        {
                                            if(fieldtype === "esriFieldTypeSmallInteger" || fieldtype === "esriFieldTypeInteger" || fieldtype === "esriFieldTypeDouble")
                                                targetfieldValues = targetfieldValues + "," + legendname

                                            else
                                            {
                                                legendname = addEscapeCharacterLegendName(legendname)
                                                targetfieldValues = targetfieldValues + ",'" + legendname + "'"

                                            }
                                        }
                                        else
                                        {
                                            if(fieldtype === "esriFieldTypeSmallInteger" || fieldtype === "esriFieldTypeInteger" || fieldtype === "esriFieldTypeDouble")

                                                targetfieldValues = legendname
                                            else
                                            {
                                                legendname = addEscapeCharacterLegendName(legendname)

                                                targetfieldValues = "'" + legendname + "'"
                                            }


                                        }

                                    }

                                }
                            }
                        }

                    }
                }


                if(targetfieldname > "" && targetfieldValues > "")
                    searchString = `${targetfieldname} IN (${targetfieldValues})`

                return searchString


            }

            function addEscapeCharacterLegendName(legendName)
            {
                var updatedlegendName =  legendName.replace("'", "''");
                return updatedlegendName
            }



            function createAttributeQuery_ByFeatureType(featureTable,legendNames)
            {
                var targetfieldname = ""
                var targetfieldvalue = ""
                var searchString = ""
                var _targetfieldvalues = `(${targetfieldvalue})`
                var _featureTypes = featureTable.featureTypes
                var fieldValues = ""

                var  targetfieldvalueObj = getTargetFieldName(featureTable,legendNames)
                targetfieldname = targetfieldvalueObj["targetFieldName"]
                fieldValues = targetfieldvalueObj["values"]
                //fieldValues = fldvals.join(",")

                if(targetfieldname > "" && fieldValues > "")
                    searchString = `${targetfieldname} IN (${fieldValues})`

                return searchString


            }




            function getTargetFieldName(featureTable,legendName)
            {
                var targetFieldName = ""
                var values = null //[]
                var _featureTypes = featureTable.featureTypes
                for(var x = 0; x < _featureTypes.length; x++)
                {
                    let _featType = _featureTypes[x]

                    for(var k=0;k<legendName.length;k++)
                    {
                        var leg = legendName[k]
                        if(_featType.name === leg)
                        {
                            var _templates = _featType.templates
                            var _typeid = _featType.typeId
                            var _template = _templates[0]
                            var _prototypeAttributes = _template.prototypeAttributes
                            if(values)
                            {
                                if(typeof _typeid === "string")
                                {
                                    _typeid = addEscapeCharacterLegendName(_typeid)
                                    values = values + ",'" + _typeid + "'"
                                }
                                else
                                {
                                    values = values + "," + _typeid
                                }

                            }
                            else
                            {
                                if(typeof _typeid === "string")
                                {
                                    _typeid = addEscapeCharacterLegendName(_typeid)
                                    values =  "'" + _typeid + "'"

                                }
                                else
                                    values = _typeid
                            }


                            if(!(targetFieldName > "")){
                                for(var key in _prototypeAttributes)
                                {
                                    if(_prototypeAttributes[key] === _typeid)
                                        targetFieldName = key
                                }
                            }

                            //break
                        }

                    }




                }
                var fieldObj = {}
                fieldObj["targetFieldName"] = targetFieldName
                fieldObj["values"] = values

                return  fieldObj


            }

            function getTargetFieldValue(featureTable,fieldName,value)
            {
                let targetFieldValue = value
                var fields = featureTable.fields
                let targetFieldType = 7 //Enums.fieldTypeText

                for(var key in fields)
                {
                    let field = fields[key]
                    if(field.name === fieldName)
                    {
                        if(field.domain)
                        {
                            let domainObj = field.domain.codedValues
                            for(var k1=0;k1<domainObj.length;k1++)
                            {
                                var domaincode =  domainObj[k1].code
                                var domainname = domainObj[k1].name
                                if(domainname === value)
                                {
                                    targetFieldValue = domaincode

                                    break
                                }


                            }

                        }
                        targetFieldType = field.fieldType

                    }
                }
                var fieldObj = {}
                fieldObj["targetFieldType"] = targetFieldType
                fieldObj["targetFieldValue"] = targetFieldValue

                return fieldObj


            }




            function updateMapInfo () {
                if (!mapView.map) return
                if (mapView.map.item) {
                    if (mapView.map.item.title) {
                        mapView.mapInfo.title = mapView.map.item.title
                    }
                    if (mapView.map.item.snippet) {
                        mapView.mapInfo.snippet = mapView.map.item.snippet
                    }
                    if (mapView.map.item.description) {
                        mapView.mapInfo.description = mapView.map.item.description
                    }
                }
            }



            /*
              added a timer to resolve the crash issue for some mmpk using 3D symbols

              */
            Timer {
                id: timer
            }


            function populateModelForSpatialSearch()
            {
                legendManager.orderedLegendInfos_spatialSearch.clear()

                for(var k=0;k< legendManager.orderedLegendInfos_legend.count;k++)
                {
                    var item = legendManager.orderedLegendInfos_legend.get(k)


                    if(item.layerType === "FeatureLayer" || item.layerType === "ArcGISMapImageSublayer" || item.layerType === "ArcGISMapImageLayer")
                    {
                        var updatedelement  = legendManager.updateModelForSpatialSearchConfig(item)
                        legendManager.orderedLegendInfos_spatialSearch.append(updatedelement)

                        //mapView.orderedLegendInfos_spatialSearch.addIfUnique(updatedelement,"uid")
                    }


                }

                app.searchLegendListHeight = spatialSearchDockItem.getSpatialSearchListViewHeight()//spatialSearchDockItem.getSpatialSearchListViewHeight()


                if(!mapView.spatialSearchInitialized)
                {
                    mapView.spatialSearchModelUpdated()
                    //mapView.spatialSearchInitialized = true
                }

            }



            function find(model,layername)
            {
                for(var i=0;i<model.count;i++)
                {
                    var item = model.get(i)
                    if(item.lyrname === layername)
                        return true
                }
                return false
            }

            function updateMapUnitsModel () {
                if (!mapView.currentViewpointCenter.center) return
                var isEmpty = mapView.mapunitsListModel.count === 0,
                DD = CoordinateFormatter.toLatitudeLongitude(mapView.currentViewpointCenter.center, Enums.LatitudeLongitudeFormatDecimalDegrees, 3),
                DM = CoordinateFormatter.toLatitudeLongitude(mapView.currentViewpointCenter.center, Enums.LatitudeLongitudeFormatDegreesDecimalMinutes, 3),
                DMS = CoordinateFormatter.toLatitudeLongitude(mapView.currentViewpointCenter.center, Enums.LatitudeLongitudeFormatDegreesMinutesSeconds, 3),
                MGRS = CoordinateFormatter.toMgrs(mapView.currentViewpointCenter.center, Enums.MgrsConversionModeAutomatic, 3, true),
                mapUnitsObjects = [
                            { "name": "%1 (wkid: %2, %3)".arg(qsTr("Default")).arg(mapView.spatialReference.wkid).arg(getUnitNameFromWkText(mapView.spatialReference.wkText)),
                                "value": "%1 %2".arg(mapView.currentViewpointCenter.center.y.toFixed(4)).arg(mapView.currentViewpointCenter.center.x.toFixed(4)),
                                "isChecked": false,
                            },
                            { "name": "DD",
                                "value": parseDecimalCoordinate(DD),
                                "isChecked": false,
                            },
                            { "name": "DM",
                                "value": parseDecimalCoordinate(DM),
                                "isChecked": true,
                            },
                            { "name": "DMS",
                                "value": parseDecimalCoordinate(DMS),
                                "isChecked": false,
                            },
                            { "name": "MGRS",
                                "value": MGRS,
                                "isChecked": false,
                            }
                        ]

                for (var i=0; i<mapUnitsObjects.length; i++) {
                    if (isEmpty) {
                        mapView.mapunitsListModel.append(mapUnitsObjects[i])
                    } else {
                        for (var key in mapUnitsObjects[i]) {
                            if (mapUnitsObjects[i].hasOwnProperty(key) && key !== "isChecked") {
                                mapView.mapunitsListModel.setProperty(i, key, mapUnitsObjects[i][key])
                            }
                        }
                    }
                    var currentItem = mapView.mapunitsListModel.get(i)
                    if (currentItem.isChecked && mapInitialized) {
                        mapunitsLabel.text = currentItem.value
                    }
                }
            }

            function updateGridModel () {
                var isEmpty = mapView.gridListModel.count === 0,
                gridObjects = [
                            { "name": strings.none,
                                "value": "",

                                "isChecked": true,
                            },
                            { "name": "Lat/Long " + strings.grid,
                                "value": "",
                                "gridObject" : "LatitudeLongitudeGrid",
                                "isChecked": false,
                            },
                            { "name": "UTM " + strings.grid,
                                "value": "",
                                "gridObject" :"UTMGrid",
                                "isChecked": false,
                            },
                            { "name": "USNG " + strings.grid,
                                "value": "",
                                "gridObject" : "USNGGrid",
                                "isChecked": false,
                            },

                            { "name": "MGRS " + strings.grid,
                                "value": "",
                                "gridObject": "MGRSGrid",
                                "isChecked": false,
                            }
                        ]

                for (var i=0; i<gridObjects.length; i++) {
                    if (isEmpty) {
                        mapView.gridListModel.append(gridObjects[i])
                    } else {
                        for (var key in gridObjects[i]) {
                            if (gridObjects[i].hasOwnProperty(key) && key !== "isChecked") {
                                mapView.gridListModel.setProperty(i, key, gridObjects[i][key])
                            }
                        }
                    }
                    var currentItem = mapView.gridListModel.get(i)
                    if (currentItem.isChecked) {
                        mapView.grid = ArcGISRuntimeEnvironment.createObject(currentItem.gridObject, {labelPosition: Enums.GridLabelPositionAllSides})
                    }
                }
            }

            function getUnitNameFromWkText (wkText) {
                var unit
                try {
                    unit = JSON.parse("[" + wkText.split("UNIT")[2])[0][0].split(",")
                } catch (err) {
                    unit = wkText
                }
                return unit[0]
            }

            function parseDecimalCoordinate (coord) {
                switch (coord.split(" ").length) {
                case (2):
                    return parseDD (coord)
                case (4):
                    return parseDM (coord)
                case (6):
                    return parseDMS (coord)
                default:
                    return coord
                }
            }

            function replaceDirectionStrings (originalText, replacement) {
                var directions = ["N", "S", "E", "W"]
                for (var i=0; i<directions.length; i++) {
                    originalText = originalText.replace(directions[i],
                                                        "%1 %2".arg(replacement).arg(directions[i]))
                }
                return originalText
            }

            function parseDD (DD) {
                var DDSplit = DD.split(" ")
                DD = "%1  %2".arg(DDSplit[0]).arg(DDSplit[1])
                return replaceDirectionStrings(DD, "°")
            }

            function parseDM (DM) {
                var DMSplit = DM.split(" ")
                DM = "%1° %2  %3° %4".arg(DMSplit[0]).arg(DMSplit[1]).arg(DMSplit[2]).arg(DMSplit[3])
                return replaceDirectionStrings(DM, "'")
            }

            function parseDMS (DMS) {
                var DMSSplit = DMS.split(" ")
                DMS = "%1° %2' %3  %4° %5' %6".arg(DMSSplit[0]).arg(DMSSplit[1]).arg(DMSSplit[2]).arg(DMSSplit[3]).arg(DMSSplit[4]).arg(DMSSplit[5])
                return replaceDirectionStrings(DMS, "''")
            }

            function currentCenter () {
                var x = app.width/2
                var y = (app.height - app.headerHeight)/2
                return screenToLocation(x, y)
            }
        }

        /* BusyIndicator {
            id: busyIndicator
            Material.primary: app.primaryColor
            Material.accent: app.accentColor
            visible: ((mapView.drawStatus === Enums.DrawStatusInProgress) && (mapView.mapReadyCount < 1)) || (mapView.identifyLayersStatus === Enums.TaskStatusInProgress) || identifyInProgress === true ||  !mapInitialized
            width: app.iconSize
            height: app.iconSize
            anchors.centerIn: mapView//parent

        }*/
        Label {
            id: busyIndicatorText

            width: parent.width
            visible: busyIndicator.visible
            text: strings.loading
            anchors.top: busyIndicator.bottom
            anchors.topMargin: 12 * app.scaleFactor
            anchors.horizontalCenter: mapView.horizontalCenter
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.pixelSize: 20 * app.scaleFactor
            font.bold: true
            font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
            color: "white"
        }


        MapPageStates{
            id:mapPageStates
        }

        states:mapPageStates.states

        Component{
            id:spatialSearchComponent
            SpatialSearchView
            {
                id:spatialSearchView
                width: app.isLandscape? app.width * 0.35: app.width//350
                height:app.isLandscape? app.height - app.headerHeight : app.height * 0.50 //- app.units(20)
                _mapView: mapView
                onDoSpatialSearch: {

                    //app.showSpatialSearchResults.connect(connectfunction)
                    if(activeBtn === "distance"){
                        mapView.spatialfeaturesModel.searchMode = searchMode.distance
                        mapView.applySpatialSearchByDistance()
                    }
                    else if (activeBtn === "extent")
                    {
                        mapView.spatialfeaturesModel.searchMode = searchMode.extent
                        mapView.applySpatialSearchByExtent()
                    }

                }
                onActiveBtnChanged: {
                    mapView.clearSpatialSearch()
                    if(activeBtn === "extent"){

                        // searchExtentBtn.visible = true
                        mapView.spatialfeaturesModel.searchMode = searchMode.extent

                        //spatialSearchLabel.visible = false
                    }
                    else
                    {
                        //searchExtentBtn.visible = false
                        mapView.spatialfeaturesModel.searchMode = searchMode.distance
                        //spatialSearchLabel.visible = false
                    }

                }

                Connections{
                    target:mapView
                    function onShowSpatialSearchResults(){
                        spatialSearchView.showResults = true
                        spatialSearchView.valueChanged = false
                        //mapView.featuresModel


                        //update the showinView

                    }
                    function onHideSpatialSearchResults(){
                        spatialSearchView.showResults = false
                    }


                    function onSpatialSearchBackBtnPressed(){
                        if(spatialSearchView.showResults && panelDockItem.visible)
                            panelDockItem.visible = false
                        else if(spatialSearchView.showResults)
                            spatialSearchView.showResults = false
                        else
                        {
                            mapView.clearSpatialSearch()
                            spatialSearchIcon.checked = false
                            spatialSearchDockItem.visible=false
                            spatialSearchDockItem.removeDock()
                        }

                    }

                }

                Component.onCompleted: {
                    if(activeBtn === "distance")
                        mapView.spatialfeaturesModel.searchMode = searchMode.distance
                    else
                        mapView.spatialfeaturesModel.searchMode = searchMode.extent
                }



            }
        }

        Rectangle{
            id:searchDockItem
            width:parent.width * 0.35
            height:parent.height
            visible:false

            property int floatingWidth: 100
            property int floatingHeight: 100

            Drag.active: dragArea2.drag.active
            Drag.hotSpot.x:100

            //Drag.hotSpot.y: 10

            MouseArea {

                id: dragArea2
                anchors.fill: parent
                enabled:pageView.state !== "anchorbottom"

                drag.target: isLandscape ? searchDockItem : null
                onPressed: {
                    if (!searchDockItem.anchors.fill) {
                        searchDockItem.floatingWidth = searchDockItem.width;
                        searchDockItem.floatingHeight = searchDockItem.height;
                    }
                    searchDockItem.anchors.fill = null;
                    searchDockItem.width = floatingWidth;
                    searchDockItem.height = floatingHeight;
                    let mousePos = searchDockItem.mapToItem(searchDockItem.parent, mouseX, mouseY);
                    searchDockItem.x = mousePos.x - searchDockItem.width / 2;
                    searchDockItem.y = mousePos.y - searchDockItem.height / 2;
                    searchDockItem.z = Date.now();
                }

                onReleased: {
                    if(isLandscape)
                    {

                        searchDockItem.y=0
                        if(searchDockItem.x > parent.width/2)
                        {
                            searchDockItem.x = mapView.width
                            pageView.state = "anchorleft"

                        }
                        else
                        {
                            searchDockItem.x = 0
                            pageView.state = "anchorright"
                        }
                    }

                }
            }
            property alias searchItemLoader: searchPageLoader.item
            Loader{
                id:searchPageLoader

                anchors.fill:parent

                onLoaded: {
                    item.mapView = mapView
                    item.searchText = mapView.searchText
                    if(mapView.activeSearchTab.toUpperCase() === "PLACES")
                    {
                        item.currentPlaceSearchText = mapView.searchText
                        item.currentFeatureSearchText = mapView.searchText

                    }
                    else
                    {
                        item.currentFeatureSearchText = mapView.searchText
                        item.currentPlaceSearchText = mapView.searchText

                    }
                    item.visible = true
                    item.isLoaded = true
                    //item.search(item.searchText)

                }
            }
            Connections {
                target: searchPageLoader.item
                function onHideSearchPage()
                {
                    mapView.searchText = searchPageLoader.item.searchText
                    mapView.activeSearchTab = searchPageLoader.item.activeTab
                    app.activeSearchTab = searchPageLoader.item.activeTab
                    searchIcon.checked = false
                    placeSearchResult.visible = false
                    searchDockItem.removeDock()
                }

                function onVisibleChanged() {
                    var hasPermission = Permission.checkPermission(Permission.PermissionTypeLocationWhenInUse) === Permission.PermissionResultGranted
                    app.hasLocationPermission = hasPermission
                    app.activeSearchTab = searchPageLoader.item.activeTab
                    if (!searchPageLoader.item.visible) {
                        if (searchPageLoader.item.sizeState === "") {
                            mapPage.header.y = 0
                            toolbarrow.visible = true
                        }
                        searchIcon.checked = false
                    } else {
                        if (searchPageLoader.item.sizeState === "") {
                            mapPage.header.y = - (app.headerHeight + (app.isNotchAvailable() ? app.notchHeight:0))

                            toolbarrow.visible = false
                        }
                        measureToolIcon.checked = false
                    }
                }

                function onSizeStateChanged() {
                    if (searchPageLoader.item.sizeState === "" && measurePanel.state !== 'MEASURE_MODE') {
                        if (!visible) {
                            mapPage.header.y = 0
                            toolbarrow.visible = true
                        } else {
                            mapPage.header.y = - (app.headerHeight + (app.isNotchAvailable() ? app.notchHeight:0))
                            toolbarrow.visible = false
                            //mapPage.header.y = - app.headerHeight
                        }
                    }
                    else // sizeState is 'LARGE'
                    {
                        mapPage.header.y = 0
                        toolbarrow.visible = true
                    }
                }

                function onDockToLeft()
                {
                    pageView.state = defaultAnchor//"anchorright"

                }
                function onDockToTop()
                {

                    pageView.state = "anchortop"

                }

                function onDockToBottom()
                {
                    searchDockItem.dockToBottom()
                }



            }

            function dockToBottomReduced()
            {
                pageView.state = "anchorbottomReduced"

            }

            function dockToBottom()
            {
                pageView.state = "anchorbottom"
                Qt.inputMethod.hide()

            }

            function addDock(){
                panelDockItem.childItem = ""
                if ( !app.isLandscape ){
                    pageView.state = "anchortop"
                } else {
                    pageView.state = defaultAnchor
                }

                if(!searchPageLoader.item){
                    searchPageLoader.source = "SearchPage.qml"
                    searchItemLoader.mapView = mapView
                    searchItemLoader.visible = true
                    placeSearchResult.visible = true
                    /*searchItemLoader.mapProperties = mapProperties
                    searchItemLoader.searchType = isBufferSearchEnabled ? "bufferSearch":"searchByExtent"
                    searchItemLoader.visible = true
                    searchItemLoader.currentPlaceSearchText = mapView.searchText
                    searchItemLoader.currentFeatureSearchText = mapView.searchText*/

                } else
                    searchPageLoader.item.willDockToBottom = false

                if(!mapView.mmpk.maps.length > 0)
                    searchItemLoader.updateFeatureSearchProperties()
                searchDockItem.visible = true
            }


            function removeDock()
            {
                if(!mapView.searchText)
                    mapView.searchText = searchItemLoader.currentPlaceSearchText//searchPageLoader.item.searchText
                mapView.activeSearchTab = searchPageLoader.item.activeTab
                searchPageLoader.source = ""
                placeSearchResult.visible = false

                pageView.state = defaultAnchor//"anchorright"
                searchDockItem.visible = false

            }


        }





        Rectangle{
            id:panelDockItem
            width:parent.width * 0.35//350
            height:parent.height //- app.units(20)
            visible:false
            color:"red"
            property var childItem
            Drag.active: dragArea2.drag.active
            Drag.hotSpot.x:10
            z:99


            //Drag.hotSpot.y: 10

            MouseArea {

                id: dragArea3
                anchors.fill: parent
                enabled:pageView.state !== "anchorbottom"

                drag.target: isLandscape ? panelDockItem : null

                onReleased: {
                    if(isLandscape)
                    {

                        panelDockItem.y=0
                        if(panelDockItem.x > parent.width/2)
                        {
                            panelDockItem.x = mapView.width
                            pageView.state = "anchorleft"

                        }
                        else
                        {
                            panelDockItem.x = 0
                            pageView.state = "anchorright"
                        }
                    }

                }
            }
            property alias panelItemLoader: panelPageLoader.item
            Loader{
                id:panelPageLoader
                width:parent.width //- 50
                height:parent.height



                onLoaded: {

                }
            }
            Connections {
                target: panelPageLoader.item
                function onHidePanelPage()
                {
                    //panelDockItem.removeDock()
                    toolBarBtns.uncheckAll()
                    mapView.elevationPtGraphicsOverlay.graphics.clear()

                    pageView.hidePanelItem()
                    pageView.hideSearchItem()
//                    moreIcon.checked = false

                    identifyProperties.clearHighlightInLayer()
                    if(isInShapeCreateMode)
                    {
                        sketchGraphicsOverlay.graphics.clear()
                        sketchEditorManager.stopSketchEditor()
                        isInShapeEditMode = false
                        isInShapeCreateMode = false
                        mapPage.state = "anchorright"
                        mapPageHeader.visible = true
                        mapPageHeader.y = 0
                        mapPageHeader.height = app.headerHeight + app.notchHeight
                        isShowingCreateNewFeature = false
                    }

                }
                function onZoomToLayer(lyrname,identificationIndex)
                {
                    let layerIndexes = identificationIndex.split(',')
                    let lyr = null
                    let minScale = 0
                    let maxScale = 0
                    let rootLyr =  mapView.map.operationalLayers.get(layerIndexes[0])
                    let _extent = rootLyr.fullExtent

                    let lyrs = mapView.map.operationalLayers.get(layerIndexes[0]).subLayerContents
                    if(lyrs.length > 0){
                        for(var k=1;k<layerIndexes.length;k++)
                        {
                            lyr = lyrs[layerIndexes[k]]
                            lyrs = lyr.subLayerContents

                        }

                    }

                    if(!lyr)
                        lyr = rootLyr

                    if(lyr.fullExtent)
                        _extent = lyr.fullExtent//mapView.map.initialViewpoint.extent
                    //_extent = mapView.map.initialViewpoint.extent

                    if(lyr.minScale)
                        minScale = lyr.minScale
                    if(lyr.maxScale)
                        maxScale = lyr.maxScale

                    if(_extent)
                    {
                        mapView.startNavigating = true
                        mapView.prevMapScale = mapView.mapScale.valueOf()

                        if(lyr.minScale === 0 && lyr.maxScale === 0)
                        {
                            //_extent = mapView.map.initialViewpoint.extent
                            mapView.zoomToExtent(_extent)
                        }
                        else if (lyr.maxScale > 0)
                            mapView.zoomToPoint(_extent.center,maxScale)
                        else
                            mapView.zoomToPoint(_extent.center,minScale)
                        // mapView.zoomToPoint(_extent.center,minScale - 200)

                    }


                }




                function onChangeLayerVisibility(identificationIndex,checked){
                    var layerIndexes = identificationIndex.split(',')
                    //var lyr = {}
                    let lyr = mapView.map.operationalLayers.get(layerIndexes[0])
                    if(layerIndexes.length > 1)
                    {
                        var lyrs = mapView.map.operationalLayers.get(layerIndexes[0]).subLayerContents
                        for(var k=1;k<layerIndexes.length;k++)
                        {

                            lyr = lyrs[layerIndexes[k]]
                            lyrs = lyr.subLayerContents


                        }
                    }

                    lyr.visible = checked//!lyr.visible

                }

                function onEditGeometry()
                {
                    let feature1 = identifyManager.features[identifyBtn.currentPageNumber - 1]
                    panelDockItem.dockToEditMode()
                    mapView.identifyProperties.highlightFeature(identifyBtn.currentPageNumber - 1,true)
                    mapPage.isEditingExistingFeature = true
                    sketchEditorManager.symbolUrl = identifyManager.featureSymbol
                    sketchEditorManager.startedEditing = true
                    sketchEditorManager.startSketchEditor(feature1)
                    //sketchMode = sketchEditorManager.startEdit
                }

                function onDrawNewSketch(geometryType,layerName,layerId,subtype,symbolUrl)
                {
                    isInShapeCreateMode = true

                    panelDockItem.dockToEditMode()
                    mapPage.isEditingExistingFeature = true
                    sketchEditorManager.startSketchEditorForNewSketch(geometryType,layerName,layerId,subtype,symbolUrl)
                    // mapPage.sketchMode = "newFeatureStartEdit"

                    //sketchMode = sketchEditorManager.startNewFeature//startEdit


                }


                function clearEditGeometry()
                {
                    sketchGraphicsOverlay.graphics.clear()
                    sketchEditorManager.stopSketchEditor()
                }

                function onExitShapeEditMode(action)
                {

                    let isFeatureEdited = false
                    let lyrid =  null
                    let feature1 = null
                    mapPage.isInShapeEditMode = false
                    mapPage.isInShapeCreateMode = false
                    isShowingCreateNewFeature = false
                    //  sketchGraphicsOverlay.graphics.clear()


                    if(isInShapeCreateMode)
                    {
                        isFeatureEdited = mapPage.isSketchValid
                    }
                    else
                    {

                        feature1 = identifyManager.features[identifyBtn.currentPageNumber - 1]

                        lyrid = feature1.featureTable.layer.layerId

                        isFeatureEdited = sketchEditorManager.isGeometryEdited(feature1)
                    }

                    if(isFeatureEdited && action === "cancel")
                    {

                        app.messageDialog.width = messageDialog.units(300)
                        app.messageDialog.standardButtons = Dialog.Cancel | Dialog.Yes

                        app.messageDialog.show(strings.discard_edits,strings.cancel_editing)

                        app.messageDialog.connectToAccepted(function () {

                            sketchEditorManager.stopSketchEditor()
                            sketchEditorManager.setFeatureVisibility(lyrid,feature1,true)

                            cancelEditing()

                            sketchGraphicsOverlay.graphics.clear()
                            sketchEditorManager.stopSketchEditor()


                        })
                        app.messageDialog.connectToRejected(function () {

                        })
                    }
                    else
                    {

                        sketchEditorManager.stopSketchEditor()
                        sketchEditorManager.setFeatureVisibility(lyrid,feature1,true)
                        cancelEditing()
                    }

                }



                function cancelEditing()
                {
                    mapPage.isEditingExistingFeature = false
                    newFeatureEditBtn.checked = false
                    sketchGraphicsOverlay.graphics.clear()

                    if(isInShapeCreateMode)
                    {
                        //isInShapeCreateMode = false
                        app.isInEditMode = false
                        panelDockItem.panelItemLoader._footerLoader.source = ""
                        panelDockItem.panelItemLoader.isFooterVisible = false
                        panelDockItem.panelItemLoader.hidePanelPage()

                    }
                    else
                    {
                        isInShapeEditMode = false
                        panelDockItem.panelItemLoader.showIdentifyPageFooter()
                        panelDockItem.panelItemLoader.showIdentifyPageHeader()
                        mapView.identifyProperties.highlightFeature(identifyBtn.currentPageNumber - 1,true)
                        if(app.isLandscape)
                            panelDockItem.dockToLeft()

                        else
                            panelDockItem.dockToBottom()
                    }

                }



                function checkOrUncheckChildItems(item,checked)
                {
                    for(let k =0;k<item._children.count;k++)
                    {
                        let subitem = item._children.get(k)
                        subitem["checkBox"] = checked
                        onChangeLayerVisibility(subitem.lyrIdentificationIndex,checked)
                        checkOrUncheckChildItems(subitem,checked)

                    }

                }

                /* function onUpdateCheckboxInSortedTreeContentListModel(identificationIndex,checked,name)
                {
                    var layerIndexes = identificationIndex.split(',')

                    let item = mapView.sortedTreeContentListModel.get(layerIndexes[0])
                    // if(name !== item.name)
                    if (mmpk.loadStatus === 0)
                        item = mapView.sortedTreeContentListModel.get(mapView.sortedTreeContentListModel.count - layerIndexes[0] - 1)


                    for(var k=1;k<layerIndexes.length;k++)
                    {
                        let indx = layerIndexes[k]
                        if (mmpk.loadStatus === 0)
                            item = item._children.get(item._children.count - indx - 1)
                        else
                            item = item._children.get(indx)

                    }


                    checkOrUncheckChildItems(item,checked)

                }
*/


                function onDockToLeft()
                {
                    pageView.state = defaultAnchor//"anchorright"

                }
                function onDockToTop()
                {
                    pageView.state = "anchortop"
                    //Qt.inputMethod.hide()
                    var extent = mapView.routeGraphicsOverlay.extent
                    mapView.setViewpointGeometryAndPadding(extent, 50);
                }

                function onDockToBottom()
                {

                    panelDockItem.dockToBottom()
                }
                function onDockToTopReduced()
                {
                    panelDockItem.dockToTopReduced()
                }

            }

            function dockToBottomReduced()
            {
                pageView.state = "anchorbottomReduced"

            }

            function dockToLeft() {
                if ( panelPageLoader.visible ){
                    if ( app.isLandscape ){
                        pageView.state = "anchorright"
                    }
                }
            }

            function dockToBottom()
            {
                // if(app.isInEditMode)
                //     pageView.state = "anchortop"
                // else
                pageView.state = "anchorbottom"
                Qt.inputMethod.hide()

            }

            function dockToTopReduced()
            {
                pageView.state = "anchorTopReduced"
            }

            function populatePanelPageMapUnits(panelPage)
            {
                panelPage.headerTabNames = [app.tabNames.kMapUnits]
                panelPage.title = qsTr("Map Units")
                panelPage.showPageCount = false
                panelPage.showPanelHeader()


            }
            function populatePanelPageGraticules(panelPage)
            {
                panelPage.headerTabNames = [app.tabNames.kGraticules]
                panelPage.title = qsTr("Graticules")
                panelPage.showPageCount = false
                panelPage.showPanelHeader()


            }

            function populatePanelPageOfflineMaps(panelPage)
            {
                panelPage.headerTabNames = [app.tabNames.kOfflineMaps]
                panelPage.title = qsTr("Offline Maps")
                panelPage.showPageCount = false
                panelPage.showFeaturesView()
                panelPage.showPanelHeader()


            }

            function populatePanelPageMapAreas(panelPage)
            {
                panelPage.headerTabNames = [app.tabNames.kMapAreas]
                panelPage.title = qsTr("Map Areas")
                mapView.panelTitle = strings.kMapArea
                panelPage.showPageCount = false
                panelPage.showFeaturesView()
                panelPage.symbolUrl = ""
                mapAreaManager.mapView = mapView
                mapAreaManager.loadUnloadedMapAreas()
                mapAreaManager.drawMapAreas()
                // offlineMapTask.loadUnloadedMapAreas()
                // drawMapAreas()
                panelPage.showPanelHeader()
            }

            function populatePanelPageBaseMapProperties(panelPage)
            {
                panelPage.headerTabNames = [app.tabNames.kBasemaps]
                panelPage.title = qsTr("Basemaps")
                panelPage.showPageCount = false
                panelPage.showFeaturesView()
                panelPage.showPanelHeader()

            }

            function populatePanelPageBookmarkProperties(panelPage)
            {
                panelPage.headerTabNames = [app.tabNames.kBookmarks]
                panelPage.title = qsTr("Bookmarks")
                panelPage.showPageCount = false
                panelPage.showFeaturesView()
                panelPage.showPanelHeader()

                //panelPage.show()
            }

            function populatePanelPageIdentifyProperties(panelPage,tabString)
            {

                panelPage.headerTabNames = identifyBtn.populateTabHeaderModel(tabString)//tabString.split(",")

                panelPage.pageCount = identifyManager.popupManagers.length
                //   panelPage.showFeaturesView()
                panelPage.pageCount = identifyManager.popupManagers.length
                panelPage.showPageCount = panelItemLoader.pageCount > 1 ? true:false
                panelPage.popupTitle = identifyManager.popupTitle

            }

            function populatePanelPageInfoProperties(panelPage)
            {
                // panelPage.hideDetailsView()
                panelPage.headerTabNames = [app.tabNames.kInfo, app.tabNames.kLegend, app.tabNames.kContent]
                panelPage.title = qsTr("Map details")
                if(mapProperties.title && mapProperties.title > "")
                {
                    panelPage.mapTitle = mapProperties.title
                }
                if(mapProperties.owner && mapProperties.owner > "")
                {
                    panelPage.owner = mapProperties.owner
                }
                if(mapProperties.modifiedDate && mapProperties.modifiedDate > "")
                {
                    panelPage.modifiedDate = mapProperties.modifiedDate
                }


                panelPage.showPageCount = false
                panelPage.showPanelHeader()

            }

            function populatePanelPageCreateNewFeature(panelPage)
            {
                panelPage.headerTabNames = [app.tabNames.kCreateNewFeature]
                panelPage.title = strings.kSelectType
                panelPage.showPageCount = false
                panelPage.showPanelHeader()
                //panelPage.showCreateNewFeature()
            }

            function populatePanelPage(type,tabString)
            {
                switch(type) {
                case "info":
                    childItem = "info"
                    populatePanelPageInfoProperties(panelItemLoader)
                    break
                case "identify":
                    childItem = "identify"
                    populatePanelPageIdentifyProperties(panelItemLoader,tabString)
                    break
                case "bookmark":
                    childItem = "bookmark"
                    populatePanelPageBookmarkProperties(panelItemLoader)
                    break
                case more.titleCase(app.tabNames.kBasemaps):
                    childItem = "basemaps"
                    populatePanelPageBaseMapProperties(panelItemLoader)
                    break
                case "offlineMaps":
                    childItem = "offlineMaps"
                    populatePanelPageOfflineMaps(panelItemLoader)
                    break
                case "mapunits":
                    childItem = "mapunits"
                    populatePanelPageMapUnits(panelItemLoader)
                    break
                case "graticules":
                    childItem = "graticules"
                    populatePanelPageGraticules(panelItemLoader)
                    break
                case "mapareas":
                    populatePanelPageMapAreas(panelItemLoader)
                    break
                case "createnewfeature":
                    populatePanelPageCreateNewFeature(panelItemLoader)
                }
            }

            function addDock(type,tabString)
            {
                if(!app.isLandscape &&  !app.isInEditMode)
                {
                    //if(app.isExpandButtonClicked)
                    //    pageView.state = "anchortop"
                    // else

                    pageView.state = "anchorbottom"
                }
                else if(!app.isLandscape && app.isInEditMode)
                {
                    isExpandButtonClicked = true
                    pageView.state = "anchortop"
                }
                else
                    pageView.state = defaultAnchor//"anchorright"


                if(!panelPageLoader.item)
                {

                    //close any other window like panelPage and searchPage
                    panelPageLoader.source = "PanelPage.qml"
                    panelItemLoader.mapView = mapView
                    populatePanelPage(type,tabString)

                }
                else
                {
                    //clear previous panel page item
                    if(childItem !== type)
                        populatePanelPage(type,tabString)
                    panelPageLoader.item.willDockToBottom = false
                }

                panelDockItem.visible = true

            }


            function removeDock()
            {
                panelPageLoader.source = ""
                if(!spatialSearchIcon.checked)
                    pageView.state = defaultAnchor//"anchorright"
                panelDockItem.visible = false
                app.isExpandButtonClicked = false


            }

            function dockToEditMode()
            {
                pageView.state = "shapeEditMode"
                app.isInEditMode = false
            }

        }


        Rectangle{
            id:offlineRouteDockItem
            width:pageView.width * 0.35
            height:parent.height
            visible:false

            property var routeComponent:null

            Drag.active: dragArea.drag.active
            Drag.hotSpot.x: width/2
            //Drag.hotSpot.y: 10
            MouseArea {

                id: dragArea
                anchors.fill: parent
                enabled:pageView.state !== "anchorbottom"

                drag.target: isLandscape? parent:null

                onReleased: {
                    if(isLandscape)
                    {

                        offlineRouteDockItem.y=0
                        if(offlineRouteDockItem.x > parent.width/2)
                        {
                            offlineRouteDockItem.x = mapView.width
                            pageView.state = "anchorleft"

                        }
                        else
                        {
                            offlineRouteDockItem.x = 0
                            pageView.state = "anchorright"
                        }
                    }

                }
            }
            property alias itemLoader: offlineLoader.item
            Loader{
                id:offlineLoader

                width:parent.width
                height:parent.height

                onLoaded: {
                    item.fromText = mapView.fromRouteAddress
                    item.toText = mapView.toRouteAddress
                    item.isGetDirectionVisible = mapView.allPoints.length >= 2
                    item.loadRouteTask()
                }
            }
            Connections {
                target: offlineLoader.item
                function onHideOfflineRoute()
                {
                    mapView.fromRouteAddress = offlineLoader.item.fromText
                    mapView.toRouteAddress = offlineLoader.item.toText
                    mapView.routeFromStopGraphicsOverlay.visible = false
                    mapView.routeToStopGraphicsOverlay.visible = false

                    offlineRouteIcon.checked = false
                    offlineRouteDockItem.visible=false
                    offlineRouteDockItem.removeDock()
                }
                function onDockToLeft()
                {
                    pageView.state = defaultAnchor
                    //Qt.inputMethod.hide()
                    var extent = mapView.routeGraphicsOverlay.extent
                    mapView.setViewpointGeometryAndPadding(extent, 50);
                }
                function onDockToTop()
                {
                    pageView.state = "anchortop"
                    //Qt.inputMethod.hide()
                    var extent = mapView.routeGraphicsOverlay.extent
                    mapView.setViewpointGeometryAndPadding(extent, 50);
                }

                function onDockToBottom()
                {
                    offlineRouteDockItem.dockToBottom()
                }
                function onDockToBottomReduced()
                {
                    offlineRouteDockItem.dockToBottomReduced()
                }
                function onHighlightRouteSegment(routePart,index)
                {
                    routePartGraphicsOverlay.graphics.clear()
                    if(routePart)
                    {
                        var jsonobj = JSON.parse(routePart)
                        var geometry_obj
                        var routeSegmentGraphicsp = ArcGISRuntimeEnvironment.createObject("SpatialReference",{wkid:jsonobj.spatialReference.wkid})
                        if(jsonobj.paths)
                        {
                            var polylinebuildr = ArcGISRuntimeEnvironment.createObject("PolylineBuilder",{spatialReference:routeSegmentGraphicsp})
                            var _paths = jsonobj.paths[0]
                            for(var p=0;p<_paths.length;p ++)
                            {
                                polylinebuildr.addPointXY(_paths[p][0],_paths[p][1])
                            }
                            geometry_obj = polylinebuildr.geometry
                            var routeSegmentGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: geometry_obj });

                            routePartGraphicsOverlay.graphics.append(routeSegmentGraphic);
                            var extent = routePartGraphicsOverlay.extent
                            mapView.setViewpointGeometryAndPadding(extent, 80);
                        }
                        else
                        {

                            var routePoint =  ArcGISRuntimeEnvironment.createObject("Point", {x:jsonobj.x, y:jsonobj.y, spatialReference:routeSegmentGraphicsp})
                            var extent1 = routePoint.extent
                            //mapView.setViewpointGeometryAndPadding(extent1, 50);
                            //do the union
                            var newGeom
                            if(index === 18)
                            {
                                var fromPoint = GeometryEngine.project(mapView.fromGraphic.geometry, mapView.spatialReference)

                                newGeom = GeometryEngine.unionOf(fromPoint, routePoint)
                            }
                            else
                            {
                                var toPoint = GeometryEngine.project(mapView.toGraphic.geometry, mapView.spatialReference)

                                newGeom = GeometryEngine.unionOf(toPoint, routePoint)
                            }
                            mapView.setViewpointGeometryAndPadding(newGeom.extent, 100);

                        }

                    }
                }


            }
            function dockToBottomReduced()
            {
                pageView.state = "anchorbottomReduced"
                var extent = mapView.routeGraphicsOverlay.extent
                mapView.setViewpointGeometryAndPadding(extent, 50);
            }

            function dockToBottom()
            {
                pageView.state = "anchorbottom"
                Qt.inputMethod.hide()
                var extent = mapView.routeGraphicsOverlay.extent
                mapView.setViewpointGeometryAndPadding(extent, 50);
            }

            function addDock()
            {
                if(!app.isLandscape)
                    pageView.state = "anchortop"
                else
                    pageView.state = defaultAnchor//"anchorright"
                mapView.routeFromStopGraphicsOverlay.visible = true
                mapView.routeToStopGraphicsOverlay.visible = true
                mapView.routeGraphicsOverlay.visible = true
                mapView.routePedestrianLineGraphicsOverlay.visible = true

                if(!offlineLoader.item)
                {
                    //close any other window like panelPage and searchPage
                    offlineLoader.source = "OfflineRouteView.qml"
                    itemLoader.mapView = mapView
                    itemLoader.locatorTask = mapView ?(mapView.mmpk.locatorTask ? mapView.mmpk.locatorTask : null):null
                }
                else
                    offlineLoader.item.willDockToBottom = false

            }


            function removeDock()
            {
                offlineLoader.source = ""
                pageView.state = defaultAnchor
                offlineRouteDockItem.visible = false
                //routeComponent.destroy()
            }

        }


        Rectangle{
            id:spatialSearchDockItem
            width:app.isLandscape? pageView.width * 0.35 : pageView.width
            height:app.isLandscape ? app.height - app.headerHeight : app.height * 0.50
            visible:false


            Drag.active: dragArea_spatial.drag.active
            Drag.hotSpot.x: width/2
            //Drag.hotSpot.y: 10
            MouseArea {

                id: dragArea_spatial
                anchors.fill: parent
                enabled:pageView.state !== "anchorbottom"

                drag.target: isLandscape ? parent : null

                onReleased: {
                    if(isLandscape)
                    {

                        spatialSearchDockItem.y=0
                        if(spatialSearchDockItem.x > parent.width/2)
                        {
                            spatialSearchDockItem.x = mapView.width
                            pageView.state = "anchorleft"

                        }
                        else
                        {
                            spatialSearchDockItem.x = 0
                            pageView.state = "anchorright"
                        }
                    }

                }
            }
            property alias itemLoader: spatialSearchLoader.item
            Loader{
                id:spatialSearchLoader

                width:parent.width
                height:parent.height

                onLoaded: {
                    /*item.fromText = mapView.fromRouteAddress
                    item.toText = mapView.toRouteAddress
                    item.isGetDirectionVisible = mapView.allPoints.length >= 2
                    item.loadRouteTask()*/
                }
            }
            Connections {
                target: spatialSearchLoader.item
                function onHideSpatialSearch()
                {
                    mapView.clearSpatialSearch(true)
                    spatialSearchIcon.checked = false
                    mapView.spatialfeaturesModel.searchGeometry = null
                    //spatialSearchDockItem.visible=false
                    // spatialSearchDockItem.removeDock()
                }
                function onDockToLeft()
                {
                    pageView.state = defaultAnchor
                    //Qt.inputMethod.hide()
                    // var extent = mapView.routeGraphicsOverlay.extent
                    // mapView.setViewpointGeometryAndPadding(extent, 50);
                }
                function onDockToTop()
                {
                    pageView.state = "anchortop"
                    //Qt.inputMethod.hide()
                    // var extent = mapView.routeGraphicsOverlay.extent
                    // mapView.setViewpointGeometryAndPadding(extent, 50);
                }

                function onDockToBottom()
                {
                    spatialSearchDockItem.dockToBottom()
                }

                /* function onDockToBottomReduced()
                {
                    spatialSearchDockItem.dockToBottomReduced()
                }
*/

            }

            function dockToBottomReduced(){
                pageView.state = "anchorbottomReduced"
            }

            function dockToBottom(){
                pageView.state = "anchorbottom"
                Qt.inputMethod.hide()
            }

            function getSpatialSearchListViewHeight(){
                var legenddic = {}
                var devicePixelRatio = Screen.devicePixelRatio
                var height = devicePixelRatio > 1? 150 * scaleFactor : 100 * scaleFactor
                // var height = 100 * scaleFactor
                for(var k = 0; k < mapView.orderedLegendInfos_spatialSearch.count; k++)
                {
                    var legnd = mapView.orderedLegendInfos_spatialSearch.get(k)
                    if(legenddic[legnd.displayName])
                    {
                        if(legnd.displayName.split("<br/>").length > 1)
                            height += devicePixelRatio > 1? 60 * scaleFactor:50 * scaleFactor
                        else
                            height += devicePixelRatio > 1? 75 * scaleFactor:50 * scaleFactor
                        legenddic[legnd.displayName].push(legnd.layerName)
                    }
                    else
                    {
                        legenddic[legnd.displayName] = []
                        if(legnd.displayName.split("<br/>").length > 1)
                        {
                            if(!legnd.showInLegend)
                                height += (devicePixelRatio > 1 ? 60 * scaleFactor:50 * scaleFactor) + 2 * legnd.displayName.split("<br/>").length//200 * legnd.displayName.split("<br/>").length //+ 200
                            else
                                height += (devicePixelRatio > 1 ? 100 * scaleFactor:70 * scaleFactor) + 2 * legnd.displayName.split("<br/>").length
                        }
                        else
                        {
                            //console.log("pixelratio",Screen.devicePixelRatio)
                            if(!legnd.showInLegend)
                                height += (devicePixelRatio > 1 ? 60 * scaleFactor:60 * scaleFactor)
                            else
                                height += (devicePixelRatio > 1?110 * scaleFactor : 80 * scaleFactor)
                        }
                    }
                }
                return height
            }

            function calculateHeight(legenddic)
            {
                let devicePixelRatio = Screen.devicePixelRatio
                let height = devicePixelRatio > 1? 150 * scaleFactor : 150 * scaleFactor
                Object.keys(legenddic).forEach(function(legend){
                    let sublegends = legenddic[legend].length
                    if(sublegends > 1)
                        height +=  (devicePixelRatio > 1 ? 100 * scaleFactor:40 * scaleFactor) * sublegends ///2 * legnd.displayName.split("<br/>").length
                    else
                        height +=  (devicePixelRatio > 1 ? 100 * scaleFactor:100 * scaleFactor) + 4

                })
                return height
            }



            function addDock()
            {


                if(!app.isLandscape)
                    pageView.state = "anchorbottom"
                else
                    pageView.state = defaultAnchor//"anchorright"


                if(!spatialSearchLoader.item)
                {


                    spatialSearchLoader.sourceComponent = spatialSearchComponent

                    spatialSearchLoader.active = true

                }
                else
                    spatialSearchLoader.item.willDockToBottom = false

            }


            function removeDock()
            {
                spatialSearchLoader.source = ""

                pageView.state = defaultAnchor
                spatialSearchDockItem.visible = false

            }

        }

        OfflineMapTask {
            id: offlineMapTask
            onlineMap: myWebmap
            onLoadErrorChanged: {

            }

            onLoadStatusChanged:{
                if (loadStatus == Enums.LoadStatusLoaded){


                }
            }

            onPreplannedMapAreasStatusChanged: {
                if(preplannedMapAreasStatus === Enums.TaskStatusCompleted)
                {
                    var token = null
                    var url = ""
                    mapAreaGraphicsArray = []
                    var areasModel = offlineMapTask.preplannedMapAreaList;
                    if(portal && portal.credential)
                        token = portal.credential.token
                    for(let i = 0;i< offlineMapTask.preplannedMapAreaList.count;i++){
                        mapAreaManager.loadMapAreaFromIndex(i)

                    }

                    mapAreasCount = offlineMapTask.preplannedMapAreaList.count

                    if(offlineMapTask.preplannedMapAreaList.count > 0)
                    {
                        mapPage.hasMapArea = true

                        var item = app.mapsWithMapAreas.filter(id => id === mapPage.portalItem.id)
                        if(item.length === 0)
                            app.mapsWithMapAreas.push(mapPage.portalItem.id)
                    }

                    else
                        mapPage.hasMapArea = false

                    //updateMenuItemsContent()

                }

            }

        }

        function getOfflineMaps() {

            //get the downloaded mapareas for mapPage.portalItem.id
            var fileName = "mapareasinfos.json"
            var fileContent = null
            var mapAreaFolder = offlineMapAreaCache.fileFolder.path
            if (mapAreaFolder.fileExists(fileName)) {
                fileContent = mapAreaFolder.readJsonFile(fileName)
            }
            var results = fileContent.results
            existingmapareas = results.filter(item => item.mapid === mapPage.portalItem.id)
            var taskid = offlineMapTask.preplannedMapAreas();

        }

        function showOfflineRoute()
        {
            offlineRouteDockItem.visible=true
            offlineRouteDockItem.addDock()
        }
        function showSpatialSearch()
        {
            spatialSearchDockItem.visible=true
            spatialSearchDockItem.addDock()

        }

        function hidePanelItem(activeTool)
        {
            panelDockItem.removeDock()
            panelDockItem.visible = false
        }

        function hideSearchItem()
        {
            searchIcon.checked = false
        }

        function hideOfflineRoute()
        {
            offlineRouteIcon.checked = false
            mapView.routeGraphicsOverlay.graphics.clear()
            mapView.routePartGraphicsOverlay.graphics.clear()
            mapView.routeGraphicsOverlay.visible = false
            mapView.routePedestrianLineGraphicsOverlay.visible = false
            mapView.routeFromStopGraphicsOverlay.visible = false
            mapView.routeToStopGraphicsOverlay.visible = false
            offlineRouteDockItem.removeDock()
            offlineRouteDockItem.visible=false
        }

        function hideSpatialSearch()
        {
            mapView.clearSpatialSearch(true)
            spatialSearchIcon.checked = false


            /*mapView.routeGraphicsOverlay.graphics.clear()
            mapView.routePartGraphicsOverlay.graphics.clear()
            mapView.routeGraphicsOverlay.visible = false
            mapView.routePedestrianLineGraphicsOverlay.visible = false
            mapView.routeFromStopGraphicsOverlay.visible = false
            mapView.routeToStopGraphicsOverlay.visible = false*/
            spatialSearchDockItem.removeDock()
            spatialSearchDockItem.visible=false
        }

    }


    onShowMeasureToolChanged: {
        if (!showMeasureTool && measurePanel.state !== "MEASURE_MODE") {
            mapView.resetMeasureTool()
        } else {
            pageView.hideSearchItem()
            pageView.hidePanelItem()
            mapView.cancelAllTasks()
        }
    }

    Component {
        id: discardMeasurements

        Controls.MessageDialog {
            id: discardDialog
            Material.primary: app.primaryColor
            Material.accent: app.accentColor
            pageHeaderHeight: app.headerHeight

            onCloseCompleted: {
                discardDialog.destroy()
            }
        }
    }

    function highlightMapArea(index){
        var graphic = mapPage.mapAreaGraphicsArray[index]

        // mapView.setViewpointGeometryAndPadding(polygonGraphicsOverlay.extent,100)
        //if(app.isLandscape)
        mapView.setViewpointCenterAndScale(graphic.geometry.extent.center,mapView.scale)

        var graphicList = []

        graphicList.push(graphic)

        polygonGraphicsOverlay.clearSelection()
        polygonGraphicsOverlay.selectGraphics(graphicList)
    }

    function showDiscardMeasurementsDialog (onAccepted, onRejected) {
        if (lineGraphics.hasData() || areaGraphics.hasData()) {
            var discardDialog = discardMeasurements.createObject(app)
            discardDialog.standardButtons = 0
            discardDialog.addButton(qsTr("CANCEL"), DialogButtonBox.RejectRole, Qt.lighter(app.primaryColor))
            discardDialog.addButton(qsTr("DISCARD"), DialogButtonBox.AcceptRole, "#FFC7461A")
            discardDialog.onAccepted.connect(onAccepted)
            discardDialog.onRejected.connect(onRejected)
            discardDialog.show("", qsTr("Discard measurements?"))
        } else {
            onAccepted()
        }
    }

    onPrevious: {
        if(mapView.map)
        {
            mapView.map.cancelLoad()
            mapView.map = null
            if(app.authChallenge)
                app.authChallenge.cancel()
            //cancel the challenge if present

        }
    }

    CustomAuthenticationView {
        //TODO: This will be used to replace the runtime authentication popup. It has a consistent material look
        id: loginDialog
    }

    Controls.SpatialSearchManager{
        id:spatialSearchManager

    }


    LegendManager{
        id:legendManager
        mapView: mapView
        visibleLayersList:mapPage.visibleLayersList
        Component.onCompleted: {
            mapView.orderedLegendInfos_spatialSearch = legendManager.orderedLegendInfos_spatialSearch
        }

    }

    MapUnitsManager{
        id:mapUnitsManager
        mapView: mapView
    }


    Component {
        id: listModelComponent

        ListModel {
        }
    }



    Connections {
        target: app

        function onIsSignedInChanged() {
            if (!app.isSignedIn && !app.refreshTokenTimer.isRefreshing) {
                toolBarBtns.uncheckAll(mapPage.previous)
            }
        }

        function onBackButtonPressed() {
            if (app.stackView.currentItem.objectName === "mapPage" &&
                    !app.aboutAppPage.visible && !hasVisibleSignInPage()) {
                if (more.visible) {
                    more.close()
                } else if (app.messageDialog.visible) {
                    app.messageDialog.close()
                } else if (loginDialog.visible) {
                    loginDialog.close()
                } else if (panelDockItem.visible) {
                    if(panelDockItem.panelItemLoader.relatedDetails && panelDockItem.panelItemLoader.relatedDetails.visible)
                    {
                        panelDockItem.panelItemLoader.relatedDetails.visible = false
                        panelDockItem.panelItemLoader.panelContent.visible = true
                    }
                    else
                    {
                        if(panelDockItem.panelItemLoader.tabBar.currentIndex > 0)
                        {
                            panelDockItem.panelItemLoader.tabBar.currentIndex = 0
                        }
                        else if(pageView.state === "anchortop" && !app.isLandscape) {
                            if(app.isInEditMode)
                            {
                                isInEditMode = false
                                identifyBtn.currentEditTabIndex = 0
                                mapView.identifyProperties.prepareAfterEditFeature()

                            }
                            else
                            {
                                panelDockItem.panelItemLoader.hideFullView()
                                pageView.state = "anchorbottom"
                                isExpandButtonClicked = false
                            }

                        }
                        else
                        {
                            if(app.isInEditMode)
                            {
                                isInEditMode = false
                                identifyBtn.currentEditTabIndex = 0
                                mapView.identifyProperties.prepareAfterEditFeature()

                            }
                            else
                            {
                                panelDockItem.removeDock()
                                identifyProperties.clearHighlight()
                                toolBarBtns.uncheckButtons()
                            }

                        }
                    }
                }

                else if (searchDockItem.visible) {
                    if(searchDockItem.searchItemLoader.tabBar.currentIndex)
                    {
                        searchDockItem.searchItemLoader.tabBar.currentIndex = 0
                    }
                    else
                        searchDockItem.removeDock()

                }
                else if(offlineRouteDockItem.visible)
                {
                    if(pageView.state === "anchorbottomReduced")
                        pageView.state = "anchorbottom"
                    else
                    {
                        pageView.hideOfflineRoute()
                        offlineRouteDockItem.removeDock()
                    }

                }
                else if (measureToolIcon.checked) {
                    measureToolIcon.checked = false
                }
                else if(spatialSearchDockItem.visible)
                {
                    mapView.spatialSearchBackBtnPressed()

                }
                else {
                    mapPage.previous()
                }
            }
        }
    }

    onPortalItemChanged: {
        if (mapPage.portalItem) {
            //need to clear the info of previous item
            panelPage.owner = ""
            panelPage.modifiedDate = ""
            panelPage.mapTitle = ""
            switch(mapPage.portalItem.type) {
            case "Web Map":
                //mapPage.hasMapArea = true
                if(comingFromMapArea)
                {
                    var newItem = ArcGISRuntimeEnvironment.createObject("PortalItem", { url: portalItem.url });

                    // construct a map from an item
                    var newMap = ArcGISRuntimeEnvironment.createObject("Map", { item: newItem });

                    // add the map to the map view
                    mapView.map = newMap;
                    app.isWebMap = true

                    mapView.map.loadStatusChanged.connect(function () {
                        mapView.processLoadStatusChange()
                    })

                }
                mapPage.showUpdatesAvailable = false
                //Default map is a web map
                break
            case "Mobile Map Package":
                mapPage.hasMapArea = false
                app.isWebMap = false
                mapPage.showUpdatesAvailable = false
                if (mapPage.mapProperties.needsUnpacking) {
                    mmpk.loadMmpk(mapPage.mapProperties.fileUrl.toString().replace(".mmpk", ""))
                } else {
                    mmpk.loadMmpk(mapPage.mapProperties.fileUrl)
                }
                break
            case "maparea":
                mapPage.hasMapArea = false
                mapPage.showUpdatesAvailable = false
                var _basemaps
                if(typeof(mapProperties.basemaps) !== "object")
                    _basemaps = mapProperties.basemaps.split(",")
                else
                    _basemaps = mapProperties.basemaps
                myWebmap.basemap.baseLayers.clear()
                myWebmap.operationalLayers.clear()
                polygonGraphicsOverlay.graphics.clear()
                app.isWebMap = false
                openMapArea()
                panelDockItem.removeDock()
                break

            default:
                busyIndicator.visible = false
                app.messageDialog.show(qsTr("Unsupported Item Type"), qsTr("Cannot open item of type ") + mapPage.portalItem.type)
                app.messageDialog.connectToAccepted(function () { mapPage.previous() })
            }
        }
    }

    function openMapArea()
    {
        let filePath = mapProperties.fileUrl //+ _basemaps[k]
        let fileInfo = AppFramework.fileInfo(filePath)
        var mmpk = null
        if (fileInfo.exists) {
            mmpk = ArcGISRuntimeEnvironment.createObject("MobileMapPackage", { path: filePath });
            mmpk.path = AppFramework.resolvedPathUrl(filePath)
            mmpk.loadStatusChanged.connect(()=> {
                                               if (mmpk.loadStatus !== Enums.LoadStatusLoaded )
                                               {
                                                   return;
                                               }

                                               if (mmpk.maps.length < 1)
                                               return;

                                               mapView.map = mmpk.maps[0];

                                               mapView.map.loadStatusChanged.connect(() => {

                                                                                         mapView.processLoadStatusChange()
                                                                                     }

                                                                                     )

                                               mapView.mapInitialized = true

                                           });
            mmpk.load();
        }
    }


    function showSpatialSearchSettingsSavedMessage(message,body)
    {
        toastMessage.isBodySet = true
        toastMessage.display(message,body)
    }

    function showDownloadCompletedMessage(message,body)
    {
        toastMessage.isBodySet = true
        toastMessage.display(message,body)
    }

    function showDownloadFailedMessage(message,body)
    {
        if(message > "")
            messageDialog.show(qsTr("Download Failed"),body +": " + message)
    }


}
