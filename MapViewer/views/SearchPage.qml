import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework.Platform 1.0

import Esri.ArcGISRuntime 100.14

import "../controls" as Controls

//Controls.PopupPage {
Item{
    id: searchPage

    property MapView mapView

    property string kUseMapExtent: qsTr("Use map extent")
    property string kWithinExtent: qsTr("Within Map Extent")
    property string kOutsideExtent: qsTr("Outside Map Extent")
    property alias tabBar:tabBar
    property bool isLoaded:false
    property var  searchResultTitleText:""
    property var searchFieldNames:({})
    property var layersSearchCompleted:[]
    property var layeridsSearched : []
    property var searchTabs: {
        var tabs = []
        if (locatorTask) tabs.push(app.tabNames.kPlaces)
        if ((featureSearchProperties.supportsSearch && featureSearchProperties.layerProperties.length > 0) || (mapView && mapView.mmpk.loadStatus === Enums.LoadStatusLoaded))
            tabs.push(app.tabNames.kFeatures)
        return tabs
    }
    property int transitionDuration: 200
    property real pageExtent: 0
    property real base: searchPage.height
    property string transitionProperty: "y"
    property string currentPlaceSearchText: ""
    property string currentFeatureSearchText: ""
    property alias sizeState: screenSizeState.name
    property bool hasLocationPermission: app.hasLocationPermission
    property bool screenWidth:app.isLandscape
    property bool willDockToBottom:false
    property var searchText:""
    property string activeTab:app.activeSearchTab.toUpperCase() === app.tabNames.kPlaces?app.tabNames.kPlaces:app.tabNames.kFeatures
    property string locatorError:""

    //property string activeTab:app.activeSearchTab.toUpperCase() === "PLACES"?"places":"features"//"features"//swipeView.currentIndex === 0 ? "places":"features"
    //property bool visible: false
    signal geocodeSearchCompleted ()
    signal featureSearchCompleted ()


    signal hideSearchPage()
    signal dockToBottom()
    signal dockToLeft()
    signal dockToTop()

    property var lyrNames:{
        var searchLayers = []
        return searchLayers
    }

    onScreenWidthChanged: {
        if(!app.isLandscape)
        {
            dockToTop()

        }
        else
        {
            willDockToBottom = false
            dockToLeft()
        }
    }

    onActiveTabChanged: {
        if(searchPage.searchTabs.length > 1)
        {
            if(activeTab.toUpperCase() === app.tabNames.kPlaces)
            {

                swipeView.currentIndex = 0

            }
            else
            {

                swipeView.currentIndex = 1

            }
        }
    }

    onFeatureSearchCompleted: {
        mapView.featuresModel.sortByStringAttribute("layerName")
        if (swipeView.currentItem.item.objectName === "searchFeaturesView") {
            var count = mapView.featuresModel.count
            displayFeatureResultsCount(count)
        }
    }

    onGeocodeSearchCompleted: {
        mapView.withinExtent.sortByNumberAttribute("numericalDistance", "desc")
        mapView.outsideExtent.sortByNumberAttribute("numericalDistance", "desc")
        mapView.geocodeModel.appendModelData(mapView.withinExtent)
        mapView.geocodeModel.appendModelData(mapView.outsideExtent)
        if (swipeView.currentItem.item.objectName === "searchPlacesView") {
            var count = mapView.geocodeModel.count
            displayPlaceResultsCount(count)
        }
    }

    Item {
        id: screenSizeState

        property string name: state

        states: [
            State {
                name: "LARGE"
                when: app.isLandscape

                PropertyChanges {
                    target: searchPage
                    pageExtent: height
                    height: parent.height
                    width:parent.width
                }

            }


        ]

    }
    //y: sizeState === "" ? 0 : height
    height: app.height
    width:parent.width
    //width: parent ? parent.width : 0


    /*
    enter: Transition {
        NumberAnimation {
            id: bottomUp_MoveIn

            property: searchPage.transitionProperty
            duration: searchPage.transitionDuration
            from: searchPage.base
            to: searchPage.pageExtent
            easing.type: Easing.InOutQuad
        }
    }

    exit: Transition {
        NumberAnimation {
            id: topDown_MoveOut

            property: searchPage.transitionProperty
            duration: searchPage.transitionDuration
            from: searchPage.pageExtent
            to: searchPage.base
            easing.type: Easing.InOutQuad
        }
    }
*/

    //contentItem:
    Controls.BasePage {
        anchors.fill: parent
        //Material.background: "transparent"
        Material.background: "#F4F4F4"

        header: ToolBar {
            id: searchBar

            property real tabBarHeight: 0.8 * app.headerHeight
            property real searchBoxHeight: app.headerHeight
            Material.background: app.primaryColor
            Material.foreground: app.subTitleTextColor
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            height: searchBoxHeight + tabBarHeight + app.defaultMargin + app.notchHeight
            topPadding: app.notchHeight

            Rectangle {
                anchors {
                    fill: parent
                    margins: 0.5 * app.defaultMargin
                }
                radius: app.units(2)
                //color: app.backgroundColor

                ColumnLayout {
                    anchors.fill: parent
                    width: parent.width
                    height: parent.height
                    spacing: 0

                    Pane {
                        Material.background: "transparent"
                        Layout.preferredHeight: searchBar.tabBarHeight
                        Layout.fillWidth: true
                        Layout.topMargin: 0.5 * app.defaultMargin
                        leftPadding: app.defaultMargin
                        rightPadding: app.defaultMargin
                        topPadding: 0
                        bottomPadding: 0

                        TabBar {
                            id: tabBar
                            width: parent.width
                            height: searchBar.tabBarHeight
                            //currentIndex:swipeView.currentIndex
                            padding: 0

                            Repeater {
                                id: tabView

                                model: searchPage.searchTabs

                                delegate: TabButton {
                                    id: tabButton
                                    checked:modelData === activeTab.toUpperCase() ? true:false
                                    width: Math.max(app.units(64), tabBar.width/tabView.model.length)
                                    height: 0.8 * parent.height
                                    anchors.verticalCenter: parent.verticalCenter
                                    contentItem: Controls.BaseText {
                                        text: modelData
                                        color: tabButton.checked ? app.primaryColor : app.subTitleTextColor
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    //                                    implicitWidth: Math.max(app.units(64), tabView.width/tabView.model.count)
                                    onClicked: {
                                        activeTab = modelData
                                    }

                                    Keys.onReleased: {
                                        if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
                                            event.accepted = true
                                            backButtonPressed ()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        spacing: 0
                        LayoutMirroring.enabled: !app.isLeftToRight
                        LayoutMirroring.childrenInherit: !app.isLeftToRight
                        Controls.Icon {
                            imageSource: "../images/back.png"
                            maskColor: app.subTitleTextColor
                            rotation: app.isLeftToRight ? 0 : 180

                            onClicked: {
                                //hideSearchPage()
                                app.activeSearchTab = activeTab
                                mapView.searchText = textField.properties.text
                                searchPage.close()
                            }
                        }

                        Controls.CustomTextField {
                            id: textField

                            Material.accent: app.baseTextColor
                            Material.foreground: app.subTitleTextColor
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.leftMargin: app.baseUnit
                            Layout.rightMargin: app.baseUnit
                            properties.placeholderText: qsTr("Search")
                            properties.focusReason: Qt.PopupFocusReason
                            properties.color: app.baseTextColor
                            properties.font.pointSize: app.baseFontSize
                            properties.text:searchText

                            onAccepted: {
                                mapView.searchText = textField.properties.text
                                searchPage.search(textField.properties.text)
                            }

                            onBackButtonPressed: {
                                app.backButtonPressed()
                            }

                            Connections {
                                target: textField.properties

                                function onDisplayTextChanged() {
                                    if(isLoaded){
                                        mapView.geocodeModel.clearAll()
                                        if (!textField.properties.displayText) {
                                            currentPlaceSearchText = ""
                                            mapView.featuresModel.clearAll()
                                            currentFeatureSearchText = ""
                                            swipeView.currentItem.item.reset()
                                            searchBusyIndicator.visible = false
                                            // if (Qt.platform.os === "android") app.focus = true
                                        }
                                        if (locatorTask.suggestions) {
                                            locatorTask.suggestions.searchText = textField.properties.displayText

                                            if (locatorTask.loadError !== null)
                                            {
                                                locatorError = locatorTask.loadError.message
                                                //.geocodeSearchCompleted ()
                                                searchBusyIndicator.visible = false

                                            }
                                        }
                                    }
                                }
                            }

                            onCloseButtonClicked: {
                                textField.properties.text = ""
                                mapView.searchText = textField.properties.text
                                searchResultTitleText = ""

                            }
                        }
                    }
                }
            }
        }

        contentItem: SwipeView {
            id: swipeView

            property QtObject currentView
            property QtObject itemModel
            property QtObject itemDelegate
            property string sectionProperty
            //currentIndex:activeTab.toUpperCase() === "FEATURES"?1:0//tabBar.currentIndex

            // currentIndex: 1//activeTab.toUpperCase() === "FEATURES"?1:0//tabBar.currentIndex //app.activeSearchTab === "places"?0:1 //tabBar.currentIndex
            interactive: false
            clip: true


            anchors {
                top: searchBar.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: sizeState === "" ? app.heightOffset : 0
            }

            Repeater {
                model: tabView.model?tabView.model.length:null

                Loader {
                    id:searchPageLoader
                    //active: true//SwipeView.isCurrentItem || SwipeView.isNextItem || SwipeView.isPreviousItem
                    //visible: true//SwipeView.isCurrentItem

                    sourceComponent: swipeView.currentView
                }
            }





            onCurrentIndexChanged: {
                let currenttab = activeTab.toUpperCase()
                if(tabView.model[currentIndex] !== currenttab)
                    currentIndex = currenttab === app.tabNames.kFeatures? 1:0
                //switch (tabView.model[currentIndex]) {
                switch(currenttab){
                case app.tabNames.kFeatures:
                    mapView.hidePin(function () {
                        swipeView.currentView = searchFeaturesView
                        searchPageLoader.visible = true
                        if(currentFeatureSearchText)
                        {
                            if(mapView.featuresModel.count > 0)
                                displayFeatureResultsCount (mapView.featuresModel.count)
                            else
                                performFeatureSearch(currentFeatureSearchText)
                        }
                        if ((currentFeatureSearchText !== currentPlaceSearchText) || (mapView.featuresModel.count === 0)) {
                            mapView.featuresModel.clearAll()
                            if(currentPlaceSearchText > "")
                                performFeatureSearch(currentPlaceSearchText)
                            else if(currentFeatureSearchText > "")
                            {

                                performFeatureSearch(currentFeatureSearchText)
                            }
                        } else if (mapView.featuresModel.currentIndex >= 0) {

                            swipeView.currentItem.item.searchResultSelected(mapView.featuresModel.features[mapView.featuresModel.currentIndex], mapView.featuresModel.currentIndex, false)
                        }
                    })
                    break
                case app.tabNames.kPlaces:

                    mapView.identifyProperties.clearHighlight(function () {
                        swipeView.currentView = searchPlacesView
                        if (mapView.geocodeModel.count) {
                            displayPlaceResultsCount(mapView.geocodeModel.count)
                        }
                        if ((currentFeatureSearchText !== currentPlaceSearchText) || (mapView.geocodeModel.count === 0)) {
                            mapView.geocodeModel.clearAll()
                            if(currentFeatureSearchText > "")
                                searchPlaces(currentFeatureSearchText)
                        } else if (mapView.geocodeModel.currentIndex >= 0) {
                            //if(swipeView.currentItem)
                            swipeView.currentItem.item.searchResultSelected(mapView.geocodeModel.features[mapView.geocodeModel.currentIndex], mapView.geocodeModel.currentIndex, false)
                        }
                    })

                    break
                }
            }
        }
    }

    Component {
        id: searchPlacesView


        SearchPlacesView {
            id:searchPlaceView
            searching: searchBusyIndicator.visible
            listView.model: mapView.geocodeModel
            suggestionsModel: locatorTask ? locatorTask.suggestions : ListModel


            onSearchResultSelected: {
                searchBusyIndicator.visible = false
                //var extent = feature.extent
                if(feature)
                {
                    if (closeSearchPageOnSelection) {
                        searchPage.close()
                    }
                    //mapView.setViewpointGeometry(extent)
                    mapView.zoomToPoint(feature.displayLocation)
                    mapView.showPin(feature.displayLocation)
                }
            }

            onSearchSuggestionSelected: {
                textField.properties.text = suggestion
                searchPage.search(textField.properties.text)
            }
        }
    }

    Component {
        id: searchFeaturesView

        SearchFeaturesView {
            searching: searchBusyIndicator.visible
            listView.model: mapView.featuresModel
            defaultSearchViewTitleText: featureSearchProperties.hintText
            onSearchResultSelected: {
                searchBusyIndicator.visible = false
                //var extent = feature.geometry
                if (closeSearchPageOnSelection) {
                    searchPage.close()
                }
                mapView.identifyProperties.clearHighlight(function () {
                    identifyManager.features = [feature]
                    mapView.identifyProperties.highlightFeature(0,true)

                })
            }
        }
    }



    onVisibleChanged: {
        if (visible) {
            mapView.isIdentifyTool = false
            featureSearchProperties.hintText = featureSearchProperties.getHintText()
            if (mapView.featuresModel.features.length && tabView.model[tabBar.currentIndex] === app.tabNames.kFeatures) {
                swipeView.currentItem.item.searchResultSelected(mapView.featuresModel.features[mapView.featuresModel.currentIndex], mapView.featuresModel.currentIndex, false)
            } else if (mapView.geocodeModel.features.length && tabView.model[tabBar.currentIndex] === app.tabNames.kPlaces) {
                swipeView.currentItem.item.searchResultSelected(mapView.geocodeModel.features[mapView.geocodeModel.currentIndex], mapView.geocodeModel.currentIndex, false)
            }
            textField.focus = true
            if ( hasLocationPermission )
                mapView.devicePositionSource.active = true
        } else {
            if (sizeState !== "") {
                if(!mapView.isIdentifyTool)
                {
                    mapView.identifyProperties.clearHighlight()
                    mapView.hidePin()
                }
            }

            if(!hasLocationPermission)
                mapView.devicePositionSource.active = false

            searchBusyIndicator.visible = false
        }
    }
    /*
    Controls.CustomListModel {
        id: featuresModel

        property var features: []
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
*/
    QueryParameters {
        id: featureParameters
        maxFeatures: 10
    }

    GeocodeParameters {
        id: geocodeParameters

        maxResults: 25
        forStorage: false
        minScore: 90
        preferredSearchLocation: mapView ? mapView.center:null
        outputSpatialReference: mapView ? mapView.map.spatialReference:null
        outputLanguageCode: Qt.locale().name
        resultAttributeNames: ["Place_addr"]
    }

    Connections {
        target: locatorTask

        function onGeocodeStatusChanged() {
            searchBusyIndicator.visible = true
            try{
                if (locatorTask.geocodeStatus === Enums.TaskStatusCompleted && mapView.map) {
                    if (locatorTask.geocodeResults.length > 0) {
                        var deviceLocation = CoordinateFormatter.fromLatitudeLongitude("%1 %2".arg(mapView.devicePositionSource.position.coordinate.latitude).arg(mapView.devicePositionSource.position.coordinate.longitude), mapView.spatialReference)
                        //var deviceLocation = CoordinateFormatter.fromLatitudeLongitude("%1 %2".arg(32).arg(118), mapView.spatialReference)
                        for (var i=0; i<locatorTask.geocodeResults.length; i++) {
                            if (locatorTask.geocodeResults[i].label > "") {
                                let distance = GeometryEngine.distance(deviceLocation, locatorTask.geocodeResults[i].displayLocation)
                                let distanceInMiles = (distance/1609.34) < 100 ?  parseFloat((distance/1609.34).toPrecision(3)).toLocaleString(Qt.locale()) : "100+"
                                let unitsinMiles = strings.mi
                                let distanceInMiles_str = `${distanceInMiles} ${unitsinMiles}`
                                let distanceInKm = (distance/1000.0) < 100 ?  parseFloat((distance/1000.0).toPrecision(3)).toLocaleString(Qt.locale()) : "100+"
                                let unitsinKm = strings.km
                                let distanceInKm_str = `${distanceInKm} ${unitsinKm}`
                                let distanceLabel = Qt.locale().measurementSystem === Locale.MetricSystem ? distanceInKm_str : distanceInMiles_str
                                let initialMapExtent = GeometryEngine.project(mapView.map.initialViewpoint.extent, mapView.map.spatialReference)
                                let resultExtent = GeometryEngine.contains(initialMapExtent, locatorTask.geocodeResults[i].displayLocation) ? kWithinExtent : kOutsideExtent
                                let linearUnit  = ArcGISRuntimeEnvironment.createObject("LinearUnit", {linearUnitId: Enums.LinearUnitIdMillimeters})
                                let angularUnit = ArcGISRuntimeEnvironment.createObject("AngularUnit", {angularUnitId: Enums.AngularUnitIdDegrees})
                                let geodeticInfo = GeometryEngine.distanceGeodetic(deviceLocation, locatorTask.geocodeResults[i].displayLocation, linearUnit, angularUnit, Enums.GeodeticCurveTypeGeodesic),
                                results = {
                                    "score": locatorTask.geocodeResults[i].score,
                                    "extent": locatorTask.geocodeResults[i].extent,
                                    "resultExtent": resultExtent,
                                    "place_label": locatorTask.geocodeResults[i].label,
                                    "place_addr": locatorTask.geocodeResults[i].attributes.Place_addr,
                                    "showInView": true,
                                    "initialIndex": i,
                                    "hasNavigationInfo": deviceLocation ? true : false,
                                    "numericalDistance": distance,
                                    "distance": distanceLabel,
                                    "degrees": geodeticInfo.azimuth1
                                }

                                mapView.geocodeModel.features.push(locatorTask.geocodeResults[i])

                                if (resultExtent === kWithinExtent) {
                                    withinExtent.append(results)
                                } else {
                                    outsideExtent.append(results)
                                }
                            }
                            //console.log(GeometryEngine.contains(initialMapExtent, geocodeResults[i].displayLocation), JSON.stringify(initialMapExtent.json),  geocodeResults[i].displayLocation.x, geocodeResults[i].displayLocation.y)
                        }
                    }
                    geocodeSearchCompleted ()
                    searchBusyIndicator.visible = false
                }
                if (locatorTask.geocodeStatus === Enums.TaskStatusErrored)
                {
                    locatorError = locatorTask.loadError.message
                    geocodeSearchCompleted ()
                    searchBusyIndicator.visible = false

                }

            }
            catch(ex)
            {
                geocodeSearchCompleted ()
                searchBusyIndicator.visible = false
            }
        }
    }

    property alias textField: textField
    property LocatorTask locatorTask: mapView ?(mapView.mmpk.locatorTask ? mapView.mmpk.locatorTask : app.isOnline ? onlineLocatorTask : null):null
    LocatorTask {
        id: onlineLocatorTask

        url: "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer"

        suggestions.suggestParameters: SuggestParameters {
            maxResults: 10
            preferredSearchLocation: mapView?mapView.currentCenter():null
        }
    }

    QtObject {
        id: featureSearchProperties

        property bool supportsSearch: false
        property var layerProperties: []
        property string hintText: qsTr("Search for features")
        property bool ready: {
            try {
                return (mapView.map.loadStatus === Enums.LoadStatusLoaded) && layerProperties.length && mapView.treeContentListModel.count > 0
            } catch (err) {
                return false
            }
        }

        onReadyChanged: {
            if (ready) {
                hintText = getHintText()
            }
        }

        function getHintText () {
            var hint = qsTr("Search for features")
            if (supportsSearch) {
                hint = qsTr("Search for")
                for (var i=0; i<layerProperties.length; i++) {
                    var layer = getLayerInfoById(layerProperties[i].id,layerProperties[i].subLayer)
                    if(layer)
                    {
                        hint += qsTr(" %1 in %2").arg(layerProperties[i].field.name).arg(layer.name)
                        // hint += qsTr(" %1 in %2").arg(layerProperties[i].field.name).arg(layer.lyrname)
                        if (i !== layerProperties.length - 1) {
                            hint += ", "
                        }
                    }
                }
            }
            return hint
        }
    }

    Connections {
        target: mapView ? mapView.map:null
        function onLoadStatusChanged() {
            if (mapView.map) {
                switch (mapView.map.loadStatus) {
                case Enums.LoadStatusLoaded:
                    try {
                        featureSearchProperties.supportsSearch = mapView.map.json.applicationProperties.viewing.search.enabled
                        featureSearchProperties.layerProperties = mapView.map.json.applicationProperties.viewing.search.layers || []
                    } catch (err) {

                    }
                    break
                }
            }
        }
    }

    function updateFeatureSearchProperties()
    {
        try{
            if(mapView.map.json.applicationProperties && mapView.map.json.applicationProperties.viewing.search)
            {
                featureSearchProperties.supportsSearch = mapView.map.json.applicationProperties.viewing.search.enabled
                featureSearchProperties.layerProperties = mapView.map.json.applicationProperties.viewing.search.layers || []
            }
        }
        catch(ex)
        {
            console.error("search not supported")
        }
    }

    BusyIndicator {
        id: searchBusyIndicator

        visible: false
        Material.primary: app.primaryColor
        Material.accent: app.accentColor
        width: app.iconSize
        height: app.iconSize
        anchors.centerIn: parent
    }

    function getLayerInfoById (id,subLayerId) {
        //var layerList = mapView.map.operationalLayers
        var layerList = legendManager.treeContentListModel
        for (var i=0; i<layerList.count; i++) {
            var layer = layerList.get(i)
            if (!layer) continue
            if (layer.lyrid === id) {
                if(layer._children.count > 0){
                    let sublayers = layer._children

                    for(var p=0;p<sublayers.count;p++)
                    {
                        var sublyr = sublayers.get(p)
                        if(sublyr.lyrid.toString() === subLayerId.toString())
                        {
                            var lyrname = sublyr.name
                            layer.name = lyrname
                        }
                    }
                }
                return layer
            }
        }
    }


    function close()
    {
        visible = false
        hideSearchPage()
    }

    function getLayerById (id) {
        var layerList = mapView.map.operationalLayers
        for (var i=0; i<layerList.count; i++) {
            var layer = layerList.get(i)

            if (!layer) continue
            if (layer.layerId === id) {
                return layer
            }
        }
    }

    function searchPlaces (txt) {
        currentPlaceSearchText = txt
        //console.log("SEARCHING PLACES FOR ", txt)
        geocodeParameters.preferredSearchLocation = mapView.currentCenter()
        locatorTask.geocodeWithParameters(txt, geocodeParameters)
    }

    function searchGroupLayers(layer,txt)
    {
        for(var k=0;k<layer.layers.count;k++)
        {
            var sublayer = layer.layers.get(k)
            var serviceTable = sublayer.featureTable
            if (typeof serviceTable === "undefined") {
                continue
            }
            let fields = []

            for (var key in serviceTable.fields) {
                var searchFieldName = serviceTable.fields[key].name
                fields.push(searchFieldName)

            }
            lyrNames.push(sublayer.name)

            queryServiceTable_mmpk(serviceTable, sublayer.name, fields, false, txt)
        }
    }


    function searchOfflineMapFeatures (txt) {
        currentFeatureSearchText = txt

        searchBusyIndicator.visible = true
        mapView.featuresModel.clearAll()
        let  isSearching = false;
        if(mapView.map)
        {
            var lyrs = mapView.map.operationalLayers

            for (var i=0; i<lyrs.count; i++) {
                var layer = lyrs.get(i)
                var   serviceTable
                if(layer.objectType === "GroupLayer")
                {
                    searchGroupLayers(layer,txt)
                }
                else
                {
                    serviceTable = layer.featureTable
                }

                if (typeof serviceTable === "undefined") {
                    continue
                }
                let fields = []

                for (var key in serviceTable.fields) {
                    var searchFieldName = serviceTable.fields[key].name
                    fields.push(searchFieldName)

                }
                lyrNames.push(layer.name)
                isSearching=true
                queryServiceTable_mmpk(serviceTable, layer.name, fields, false, txt)

            }

            if(!isSearching)
                featureSearchCompleted()
        }
    }

    QueryParameters {
        id: params
        // maxFeatures: 10  // setting this was causing not to return results for some webmaps

    }

    function searchFeaturesTileSubLayer_online (url,layername,lyrid,sublyr)
    {
        params.whereClause = ""
        for (var i=0; i<featureSearchProperties.layerProperties.length; i++) {
            var layerProperties = featureSearchProperties.layerProperties[i]
            var id = layerProperties.subLayer
            var searchFieldName = layerProperties.field.name
            var isExactMatch = layerProperties.field.exactMatch
            var fieldType = layerProperties.field.type
            if(lyrid.toString() === id.toString())
            {
                if(params.whereClause)
                    params.whereClause += " OR "

                if (isExactMatch) {
                    if(fieldType === "esriFieldTypeSmallInteger" || fieldType === "esriFieldTypeInteger" || fieldType === "esriFieldTypeDouble")
                    {
                        params.whereClause += "%1 = %2".arg(searchFieldName).arg(currentFeatureSearchText)
                    }
                    else
                        params.whereClause += "LOWER(%1) = LOWER('%2')".arg(searchFieldName).arg(currentFeatureSearchText)
                } else {
                    params.whereClause += "LOWER(%1) LIKE LOWER('%%2%')".arg(searchFieldName).arg(currentFeatureSearchText)
                }

                if(searchFieldNames[lyrid.toString()])
                {
                    var searchfields = searchFieldNames[lyrid.toString()]
                    if(!searchfields.includes(searchFieldName))
                        searchfields.push(searchFieldName)
                    searchFieldNames[lyrid.toString()] = searchfields
                }
                else
                {
                    var _searchfields = []
                    _searchfields.push(searchFieldName)
                    searchFieldNames[lyrid.toString()] = _searchfields
                }

            }
        }

        if(params.whereClause)
        {
            var urlstr = url.toString()

            var newurl = url + "/"+ lyrid.toString()
            var queryFeatureTable = ArcGISRuntimeEnvironment.createObject("ServiceFeatureTable", {url: newurl,featureRequestMode: Enums.FeatureRequestModeManualCache})

            var outFields= ["*"]
            queryFeatureTable.populateFromServiceStatusChanged.connect(function(){
                if(queryFeatureTable.populateFromServiceStatus === Enums.TaskStatusCompleted)
                {

                    while(queryFeatureTable.populateFromServiceResult.iterator.hasNext)
                    {
                        var feature = queryFeatureTable.populateFromServiceResult.iterator.next(),
                        attributeNames = feature.attributes.attributeNames
                        var searchlyrid = queryFeatureTable.serviceLayerId
                        var searchfldnames = searchFieldNames[searchlyrid]

                        var search_attr_val = ""
                        feature.attributes.attributeNames.forEach(fld =>
                                                                  {
                                                                      if(searchfldnames.includes(fld))
                                                                      {
                                                                          var val = feature.attributes.attributeValue(fld)
                                                                          var val_uppercase = val !== null?val.toString().toUpperCase():""
                                                                          var txt_search = currentFeatureSearchText.toString().toUpperCase()
                                                                          var n = val_uppercase.includes(txt_search);
                                                                          if(n)
                                                                          search_attr_val = fld.toString() + " : " + val.toString()
                                                                      }
                                                                  }
                                                                  )
                        if(search_attr_val)
                        {
                            mapView.featuresModel.append({
                                                             "layerName": queryFeatureTable.displayName,
                                                             "search_attr": search_attr_val,
                                                             "extent": feature.geometry,
                                                             "showInView": false,
                                                             "initialIndex": mapView.featuresModel.features.length,
                                                             "hasNavigationInfo": false,
                                                             "distance":0
                                                         })
                            mapView.featuresModel.features.push(feature)
                        }

                    }
                    searchBusyIndicator.visible = false
                    featureSearchCompleted()
                }
                else if(queryFeatureTable.populateFromServiceStatus === Enums.TaskStatusErrored)
                {
                    if(queryFeatureTable.error)
                        console.log("error:", queryFeatureTable.error.message, queryFeatureTable.error.additionalMessage);
                }
            })
            queryFeatureTable.populateFromService(params,true,outFields)
        }

    }


    function processSearchTiledLayer(layer)
    {
        if(layer.mapServiceInfo)
        {
            var mapserviceInfo = layer.mapServiceInfo
            var url = mapserviceInfo.url
            var layerinfos = mapserviceInfo.layerInfos
            for(var q=0;q <layerinfos.length;q++)
            {
                if(layerinfos[q].parentLayerId > -1)
                {
                    searchFeaturesTileSubLayer_online (url,layerinfos[q].name,q)
                }
            }

        }
        else if (layer.subLayerContents && layer.subLayerContents.length > 0 && layer.subLayerContents[0] !== null)
        {
            for(var x=layer.subLayerContents.length;x--;){
                var sublyr = layer.subLayerContents[x]
                searchOnlineTiledGroupLayer(sublyr)
            }

        }
        else if(layer.mapServiceSublayerInfo)
        {
            var url1 = layer.mapServiceSublayerInfo.url.toString()
            if(layer.sublayerId)
                searchFeaturesTileSubLayer_online (url1,layer.name,layer.sublayerId)
            else
                searchFeaturesTileSubLayer_online (url1,layer.name,layer.layerId)
        }

    }


    function searchOnlineTiledGroupLayer(layer){
        if (layer.loadStatus !== Enums.LoadStatusLoaded)
        {
            layer.loadStatusChanged.connect(function(){
                if (layer.loadStatus === Enums.LoadStatusLoaded){
                    processSearchTiledLayer(layer)
                }

            }
            )
            layer.load()
        }
        else
        {
            processSearchTiledLayer(layer)

        }

    }

    function searchOnlineMapImageGroupLayer(layer)
    {
        if(layer)
        {
            layer.loadTablesAndLayersStatusChanged.connect(function(){
                if (layer.loadTablesAndLayersStatus === Enums.TaskStatusCompleted)
                {

                    if(layer.subLayerContents)
                    {
                        for(var k=0;k<layer.subLayerContents.length;k++)
                        {
                            var sublayer = layer.subLayerContents[k]
                            if(sublayer.mapServiceSublayerInfo && sublayer.mapServiceSublayerInfo.parentLayerInfo)
                            {
                                //it is another sub group layer
                                searchOnlineMapImageGroupLayer(sublayer)

                            }
                            else
                            {
                                var layerServiceTable = layer.subLayerContents[k].table

                                searchFeatureLayer(layerServiceTable,layer.subLayerContents[k].name,layer.subLayerContents[k].id,currentFeatureSearchText)
                            }
                        }
                    }
                    layer = null
                }
                else if(layer.loadTablesAndLayersStatus === Enums.TaskStatusErrored)
                {
                    searchBusyIndicator.visible = false
                    messageDialog.show(qsTr("Error"),qsTr("Error encountered during feature search"));
                }
            })
            layer.loadTablesAndLayers()
        }
    }


    function searchFeatures (txt) {
        currentFeatureSearchText = txt
        layeridsSearched = []
        layersSearchCompleted = []
        //console.log("SEARCHING FEATURES FOR ", txt)

        searchBusyIndicator.visible = true
        mapView.featuresModel.clearAll()

        for (var i=0; i<featureSearchProperties.layerProperties.length; i++) {
            var layerProperties = featureSearchProperties.layerProperties[i]
            if(layerProperties.subLayer > -1)
            {
                var id = layerProperties.id
                var searchFieldName = layerProperties.field.name
                var isExactMatch = layerProperties.field.exactMatch
                if(!layeridsSearched.includes(id))
                {
                    var layer = searchPage.getLayerById(id)
                    layeridsSearched.push(id)

                    if (layer.loadStatus === Enums.LoadStatusLoaded)
                    {
                        if(layer.objectType === "ArcGISTiledLayer")
                        {
                            searchOnlineTiledGroupLayer(layer)
                        }
                        else if (layer.objectType === "ArcGISMapImageLayer")
                        {
                            searchOnlineMapImageGroupLayer(layer)
                        }
                    }
                }

            }
            else
            {
                var id1 = layerProperties.id
                var searchFieldName1 = layerProperties.field.name
                var isExactMatch1 = layerProperties.field.exactMatch
                var layer1 = searchPage.getLayerById(id1)
                var layerServiceTable = layer1.featureTable
                if(!layeridsSearched.includes(id1))
                {
                    layeridsSearched.push(id1)
                    searchFeatureLayer(layerServiceTable,layer1.name,id1,txt)

                }
            }

        }



    }

    function searchFeatureLayer(layerServiceTable,layername,lyrid,txt)
    {

        params.whereClause = ""
        for (var i=0; i<featureSearchProperties.layerProperties.length; i++) {
            var layerProperties = featureSearchProperties.layerProperties[i]
            var id = layerProperties.subLayer !== undefined && layerProperties.subLayer !== null ?layerProperties.subLayer:layerProperties.id
            var searchFieldName = layerProperties.field.name
            var isExactMatch = layerProperties.field.exactMatch
            var fieldType = layerProperties.field.type
            if(lyrid.toString() === id.toString())
            {
                //console.log("querying",layername)

                if(params.whereClause)
                    params.whereClause += " OR "

                if (isExactMatch) {
                    if(fieldType === "esriFieldTypeSmallInteger" || fieldType === "esriFieldTypeInteger" || fieldType === "esriFieldTypeDouble")
                    {
                        //if(typeof(currentFeatureSearchText) == "number")
                        params.whereClause += "%1 = %2".arg(searchFieldName).arg(currentFeatureSearchText)
                    }
                    else
                    {
                        params.whereClause += "LOWER(%1) = LOWER('%2')".arg(searchFieldName).arg(currentFeatureSearchText)
                    }
                } else {
                    params.whereClause += "LOWER(%1) LIKE LOWER('%%2%')".arg(searchFieldName).arg(currentFeatureSearchText)
                }
                if(layerServiceTable.serviceLayerId)
                {
                    if(searchFieldNames[layerServiceTable.serviceLayerId])
                    {
                        var searchfields = searchFieldNames[layerServiceTable.serviceLayerId]
                        if(!searchfields.includes(searchFieldName))
                            searchfields.push(searchFieldName)
                        searchFieldNames[layerServiceTable.serviceLayerId] = searchfields
                    }
                    else
                    {
                        var _searchfields = []
                        _searchfields.push(searchFieldName)
                        searchFieldNames[layerServiceTable.serviceLayerId] = _searchfields
                    }
                }

            }
        }
        if (typeof layerServiceTable !== "undefined" && params.whereClause) {
            queryServiceTable(layerServiceTable, layername,txt,params,lyrid)
        }
        else
            layersSearchCompleted.push(lyrid)

        if(layersSearchCompleted.length >= layeridsSearched.length)
        {
            searchBusyIndicator.visible = false
            featureSearchCompleted()
        }

    }



    function queryServiceTable_mmpk (serviceTable, layerName, fields, isExactMatch, txt) {
        serviceTable.queryFeaturesStatusChanged.connect (function () {
            if (serviceTable.queryFeaturesStatus === Enums.TaskStatusCompleted) {
                if(lyrNames){
                    if(lyrNames.includes(layerName))
                    {
                        if (serviceTable.queryFeaturesResult) {

                            serviceTable.queryFeaturesResult.iterator.reset()
                            var ids=[]
                            let iterator = serviceTable.queryFeaturesResult.iterator;
                            while(iterator.hasNext){

                                let feature = iterator.next()
                                let objectid_fldname = featuresManager.getUniqueFieldName(feature.featureTable)
                                let  oid = feature.attributes.attributeValue(objectid_fldname)
                                // let  oid = feature.attributes.attributeValue("ObjectId")
                                if(!oid)
                                    oid = feature.attributes.attributeValue("fid")

                                if(!ids.includes(oid))
                                {
                                    //get the field which has the txt
                                    var search_attr_val = ""
                                    feature.attributes.attributeNames.forEach(fld =>
                                                                              {
                                                                                  var val = feature.attributes.attributeValue(fld)
                                                                                  var val_uppercase = val !== null?val.toString().toUpperCase():""

                                                                                  var txt_search = currentFeatureSearchText.toString().toUpperCase()
                                                                                  var n = val_uppercase.includes(txt_search);
                                                                                  if(n)
                                                                                  search_attr_val = fld.toString() + " : " + val.toString()

                                                                              }
                                                                              )
                                    if(search_attr_val)
                                    {

                                        mapView.featuresModel.append({
                                                                         "layerName": layerName,
                                                                         "search_attr":search_attr_val,// feature.attributes.attributeValue("ObjectId"),
                                                                         "extent": feature.geometry,
                                                                         "showInView": false,
                                                                         "initialIndex": mapView.featuresModel.features.length,
                                                                         "hasNavigationInfo": false,
                                                                         "distance":"0"
                                                                     })
                                        mapView.featuresModel.features.push(feature)
                                        ids.push(oid)
                                    }
                                }
                            }
                            searchBusyIndicator.visible = false
                            featureSearchCompleted()
                        }
                        let searchlyrs = lyrNames.filter(name => name !== layerName)
                        lyrNames = searchlyrs
                    }
                }
            }
        })

        let whereClause = ""
        if (isExactMatch) {
            featureParameters.whereClause = "LOWER(%1) = LOWER('%2')".arg(searchFieldName).arg(currentFeatureSearchText)
        } else {

            fields.forEach(function(fieldname){
                let where = "(LOWER(%1) IS NOT NULL AND LOWER(%1) LIKE LOWER('%%2%'))".arg(fieldname).arg(currentFeatureSearchText)

                if(whereClause)
                    whereClause += " OR " + where
                else
                    whereClause = where

            }
            )

            featureParameters.whereClause = whereClause



        }

        serviceTable.queryFeatures(featureParameters)
    }

    function queryServiceTable (serviceTable, layerName, txt,featureParameters,lyrid) {
        serviceTable.queryFeaturesStatusChanged.connect (function () {
            if(serviceTable)
            {
                if (serviceTable.queryFeaturesStatus === Enums.TaskStatusCompleted) {
                    layersSearchCompleted.push(lyrid)

                    if (serviceTable.queryFeaturesResult) {
                        var recCount = 0
                        var searchFields = searchFieldNames[serviceTable.serviceLayerId]
                        for(var k=0;k<serviceTable.queryFeaturesResult.iterator.features.length;k++){
                            var feature = serviceTable.queryFeaturesResult.iterator.features[k],
                            attributeNames = feature.attributes.attributeNames
                            var search_attr_val = ""
                            feature.attributes.attributeNames.forEach(fld =>
                                                                      {
                                                                          if(searchFields.includes(fld.toString()))
                                                                          {
                                                                              var val = feature.attributes.attributeValue(fld)
                                                                              var val_uppercase = val !== null?val.toString().toUpperCase():""
                                                                              var txt_search = currentFeatureSearchText.toString().toUpperCase()
                                                                              var n = val_uppercase.includes(txt_search);
                                                                              if(n)
                                                                              search_attr_val = fld.toString() + " : " + val.toString()

                                                                          }

                                                                      }
                                                                      )
                            if(search_attr_val)
                            {
                                if(recCount < 10)
                                {
                                    recCount +=1
                                    mapView.featuresModel.append({
                                                                     "layerName": layerName,
                                                                     "search_attr": search_attr_val,
                                                                     "extent": feature.geometry,
                                                                     "showInView": false,
                                                                     "initialIndex": mapView.featuresModel.features.length,
                                                                     "hasNavigationInfo": false,
                                                                     "distance":"0"
                                                                 })

                                    mapView.featuresModel.features.push(feature)
                                }
                                else
                                    break

                            }

                        }

                        searchBusyIndicator.visible = false
                        featureSearchCompleted()
                        serviceTable = null
                    }
                    else
                    {
                        searchBusyIndicator.visible = false
                        featureSearchCompleted()
                        serviceTable = null
                    }
                }

                if (serviceTable !== null && serviceTable.queryFeaturesStatus === Enums.TaskStatusErrored) {

                    layersSearchCompleted.push(lyrid)

                    //searchBusyIndicator.visible = false
                    //featureSearchCompleted()
                    // messageDialog.show(qsTr("Error"),qsTr("Error encountered during feature search"));


                }

                if(layersSearchCompleted.length >= layeridsSearched.length)
                {
                    searchBusyIndicator.visible = false
                    featureSearchCompleted()
                }
            }
        })

        serviceTable.queryFeatures(featureParameters)
    }

    function performFeatureSearch (txt) {
        if (mapView.mmpk.loadStatus === Enums.LoadStatusLoaded) {
            searchOfflineMapFeatures(txt)
        } else {
            searchFeatures(txt)
        }
    }

    function search (txt) {
        let currenttab = activeTab.toUpperCase()
        // switch (searchPage.searchTabs[swipeView.currentIndex]) {
        switch(currenttab){
        case app.tabNames.kPlaces:
            mapView.geocodeModel.clearAll()
            searchPlaces(txt)
            break
        case app.tabNames.kFeatures:
            performFeatureSearch(txt)
            break
        }
    }

    function displayFeatureResultsCount (count) {
        if (count) {
            if (count === 1) {
                //searchResultTitleText = "%1 %2".arg(count).arg(qsTr("result found for features"))
                searchResultTitleText = !app.isLeftToRight ? "%L1: Count".arg(count) : qsTr("Count: %L1").arg(count)
                swipeView.currentItem.item.searchViewTitleText = searchResultTitleText
                //swipeView.currentItem.item.searchViewTitleText = "%1 %2".arg(count).arg(qsTr("result found for features"))
            } else {
                searchResultTitleText = !app.isLeftToRight ? "%L1: Count".arg(count) : qsTr("Count: %L1").arg(count)
                //searchResultTitleText = "%1 %2".arg(count).arg(qsTr("result found for features"))
                swipeView.currentItem.item.searchViewTitleText = searchResultTitleText

                //swipeView.currentItem.item.searchViewTitleText = "%1 %2".arg(count).arg(qsTr("results found for features"))
            }
        } else {

            swipeView.currentItem.item.searchViewTitleText = qsTr("No results found for features")
        }
    }

    function displayPlaceResultsCount (count) {
        if (count) {
            if (count === 1) {
                searchResultTitleText = !app.isLeftToRight ? "%L1: Count".arg(count) : qsTr("Count: %L1").arg(count)
                swipeView.currentItem.item.searchViewTitleText = searchResultTitleText
                //searchResultTitleText = "%1 %2".arg(count).arg(qsTr("result found for places"))
                //swipeView.currentItem.item.searchViewTitleText = "%1 %2".arg(count).arg(qsTr("result found for places"))
            } else {
                searchResultTitleText = !app.isLeftToRight ? "%L1: Count".arg(count) : qsTr("Count: %L1").arg(count)
                swipeView.currentItem.item.searchViewTitleText = searchResultTitleText
                //searchResultTitleText = "%1 %2".arg(count).arg(qsTr("results found for places"))
                //swipeView.currentItem.item.searchViewTitleText = "%1 %2".arg(count).arg(qsTr("results found for places"))
            }
        } else {
            swipeView.currentItem.item.searchViewTitleText = qsTr("No results found for places")
        }
    }
}



