import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.1
import QtGraphicalEffects 1.0
import Esri.ArcGISRuntime 100.14
import ArcGIS.AppFramework.Notifications 1.0

import "../controls" as Controls
FocusScope {
    id:offlineRoutePage
    anchors.fill: parent
    property bool errorView: false
    property MapView mapView:null
    property LocatorTask locatorTask: mapView ?(mapView.mmpk.locatorTask ? mapView.mmpk.locatorTask : null):null
    property var suggestionsModel: locatorTask ? locatorTask.suggestions : ListModel
    property RouteTask currentRouteTask
    property bool isShowDirection: false
    //property var routeStops: []
    property var activeFieldInFocus:""
    property var currentRouteParams
    property var directionListModel: ListModel{}
    property bool willDockToBottom:false
    property bool showInView:true
    property var fromText:""
    property var toText:""
    property bool routePending:false
    property bool screenWidth:app.isLandscape
    property bool offlineDireView: false
    property bool isGetDirectionVisible:false
    property string fontNameFallbacks: "Helvetica,Avenir"
    readonly property url alertIcon: "../images/alert.png"
    property var prevLabel:null
    property var prevDistanceLabel:null
    property var totalLength:""
    property bool isSwapped:false
    property string locatorErrorMessage:mapView.getLocatorErrorMessage(locatorTask)
    signal hideOfflineRoute()
    signal dockToBottom()
    signal dockToLeft()
    signal dockToTop()
    signal dockToBottomReduced()
    signal highlightRouteSegment(var routePart,var index)

    focus: true
    Keys.onReleased: {
        if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
            event.accepted = true
            backButtonPressed()
        }
    }

    onScreenWidthChanged: {
        if(!app.isLandscape)
        {
            if(offlineDireView)
            {
                willDockToBottom = true
                dockToBottom()
            }
            else
            {
                dockToTop()
            }

        }
        else
        {
            willDockToBottom = false
            dockToLeft()
        }
    }

    Item {
        id: offlineRoutePage1
        width:parent.width
        height:parent.height
        signal hideOfflineRoute()
        signal dockToBottom()
        signal dockToLeft()
        signal dockToTop()
        signal dockToBottomReduced()
        signal highlightRouteSegment(var routePart,var index)
        focus: true

        GeocodeParameters {
            id: geocodeParameters
            minScore: 75
            maxResults: 10
            resultAttributeNames: ["Place_addr", "Match_addr", "Postal", "Region"]
        }


        Connections {
            target: locatorTask

            function onGeocodeStatusChanged() {

                if (locatorTask.geocodeStatus === Enums.TaskStatusCompleted && mapView.map) {

                    if(locatorTask.geocodeResults[0])
                    {
                        var pinLocation = locatorTask.geocodeResults[0].displayLocation
                        updateStopPoints(pinLocation)
                        locatorTask.suggestions.searchText = ""
                        if(!isPortrait)
                            mapView.setViewpointGeometry(locatorTask.geocodeResults[0].extent);

                    }
                }

            }
        }

        Connections {
            target: currentRouteTask

            function onLoadStatusChanged() {
                if (currentRouteTask.loadStatus === Enums.LoadStatusLoaded) {
                    currentRouteTask.createDefaultParameters();

                }
            }

            // obtain default parameters
            function onCreateDefaultParametersStatusChanged() {
                if (currentRouteTask.createDefaultParametersStatus === Enums.TaskStatusCompleted){
                    //console.log("Route Task Completed")
                    currentRouteParams = currentRouteTask.createDefaultParametersResult;
                    // set parameters to return directions
                    currentRouteParams.directionsDistanceUnits = Enums.UnitSystemMetric
                    currentRouteParams.returnDirections = true;
                    if(mapView.routeStops.length === 2)
                        findRoute()
                }
            }

            function onSolveRouteStatusChanged() {

                if (currentRouteTask.solveRouteStatus === Enums.TaskStatusCompleted) {
                    if(currentRouteTask.solveRouteResult === null ) {
                        isShowDirection = true
                        offlineDireView = false
                        directionView.errorView = true
                        //console.log("Not Route Returned", offlineDireView,  directionView.errorView)
                    }
                }


                if(currentRouteTask.solveRouteStatus === Enums.TaskStatusCompleted) {
                    if(currentRouteTask.solveRouteResult > "" ) {
                        //console.log("222222222222 Route Returned", currentRouteTask.solveRouteResult)
                        directionView.errorView = false

                        offlineDireView = true
                        var generatedRoute = currentRouteTask.solveRouteResult.routes[0];
                        var locale = Qt.locale()
                        totalLength = app.getDistance(generatedRoute.totalLength)
                        //add the route at the 2 end points of the route by joining the 2 points
                        addPedestrianRoute(generatedRoute)
                        populateDirectionListModel(generatedRoute)

                        var routeGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: generatedRoute.routeGeometry});
                        var extent = GeometryEngine.combineExtentsOfGeometries(mapView.allPoints);
                        //mapView.setViewpointGeometryAndPadding(extent, 100);
                        mapView.routeGraphicsOverlay.graphics.append(routeGraphic);
                        mapView.setViewpointGeometryAndPadding(mapView.routeGraphicsOverlay.extent, 100);
                        isShowDirection = true
                        if(!app.isLandscape)
                        {
                            willDockToBottom = true
                            dockToBottom()
                        }


                    }
                }                 // otherwise, console error message
                if (currentRouteTask.solveRouteStatus === Enums.TaskStatusErrored)
                    console.log(currentRouteTask.error.message);

            }

        }

        ColumnLayout{
            //anchors.fill:parent
            width:parent.width
            visible:!willDockToBottom
            spacing:0
            LayoutMirroring.enabled: !app.isLeftToRight
            LayoutMirroring.childrenInherit: !app.isLeftToRight

            Rectangle {
                id: routeBar
                border.width:6
                border.color:app.primaryColor
                Material.background: app.primaryColor
                Material.foreground: app.subTitleTextColor
                Layout.preferredWidth: parent.width
                Layout.alignment: Qt.AlignTop

                Layout.preferredHeight:col1.height + app.defaultMargin//+ app.baseUnit//searchBoxHeight + tabBarHeight + app.defaultMargin

                Rectangle{
                    id:root
                    width:parent.width  - app.units(12)//2 * app.baseUnit
                    height:col1.height
                    anchors.centerIn: parent

                    RowLayout {
                        //height:col1.height//parent.height
                        anchors.fill:parent
                        spacing: 0//app.units(4)

                        Item {
                            Layout.preferredWidth:app.units(40)
                            Layout.preferredHeight:col1.height - app.units(10)

                            Controls.Icon {
                                imageSource: "../images/back.png"
                                maskColor: app.subTitleTextColor
                                anchors.horizontalCenter: parent.horizontalCenter
                                rotation: app.isLeftToRight ? 0 : 180
                                //anchors.top: col1.top
                                //anchors.topMargin: app.units(100)

                                onClicked: {
                                    mapView.fromRouteAddress = fromTextField.properties.text
                                    mapView.toRouteAddress = toTextField.properties.text
                                    fromText = fromTextField.properties.text
                                    toText = toTextField.properties.text
                                    clearRouteElements()
                                    hideOfflineRoute()

                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: app.units(100)

                            ColumnLayout{
                                id:col1
                                anchors.fill: parent

                                Controls.CustomTextField {
                                    id: fromTextField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight:app.units(40)
                                    Material.accent: app.primaryColor
                                    //color: "black"
                                    // Material.accent: app.baseTextColor
                                    Material.foreground: app.subTitleTextColor
                                    properties.placeholderText: qsTr("From")
                                    properties.focusReason: Qt.PopupFocusReason
                                    properties.color: app.baseTextColor
                                    properties.font.pointSize: app.baseFontSize
                                    properties.text: fromText//mapView.fromRouteAddress
                                    lineCount:2

                                    properties.onDisplayTextChanged: {
                                        if(!isSwapped)
                                        {
                                            //                                                if(fromText !== "")
                                            //                                                    mapView.allPoints.pop()
                                            clearRoute()
                                            mapView.routeFromStopGraphicsOverlay.graphics.remove(mapView.fromGraphic)
                                        }

                                        if(locatorTask)
                                        {
                                            if (locatorTask.suggestions) {

                                                if(fromTextField.properties.displayText !== mapView.fromRouteAddress)
                                                {

                                                    activeFieldInFocus = "from"
                                                    mapView.fromRouteAddress = fromTextField.properties.displayText
                                                    locatorTask.suggestions.searchText = fromTextField.properties.displayText

                                                }


                                            }
                                        }

                                    }

                                    properties.onAccepted: {
                                        activeFieldInFocus = "from"
                                        var geocodeResult = locatorTask.geocodeWithParameters(fromTextField.properties.displayText, geocodeParameters)
                                        locatorTask.suggestions.searchText = ""


                                    }

                                    onCloseButtonClicked: {
                                        isGetDirectionVisible = false
                                        mapView.routeFromStopGraphicsOverlay.graphics.remove(mapView.fromGraphic)
                                        mapView.routeGraphicsOverlay.graphics.clear();
                                        mapView.routePartGraphicsOverlay.graphics.clear();
                                        mapView.routePedestrianLineGraphicsOverlay.graphics.clear()
                                        mapView.allPoints.pop()
                                        totalLength = ""
                                        directionListModel.clear()
                                        offlineDireView = false
                                        directionView.errorView = false


                                    }

                                }
                                Rectangle{
                                    Layout.preferredWidth: parent.width
                                    Layout.preferredHeight: app.units(2)
                                    color:app.primaryColor
                                }

                                Controls.CustomTextField {
                                    id:toTextField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight:app.units(40)
                                    Material.accent: app.primaryColor
                                    Material.foreground: app.subTitleTextColor
                                    properties.placeholderText: qsTr("To")
                                    properties.focusReason: Qt.PopupFocusReason
                                    properties.color: app.baseTextColor
                                    properties.font.pointSize: app.baseFontSize
                                    properties.text: toText//mapView.toRouteAddress

                                    properties.onDisplayTextChanged: {
                                        if(!isSwapped)
                                        {
                                            //                                                if(toText !== "")
                                            //                                                    mapView.allPoints.pop()
                                            clearRoute()
                                        }

                                        if(locatorTask)
                                        {
                                            if (locatorTask.suggestions) {

                                                if(toTextField.properties.displayText !== mapView.toRouteAddress)
                                                {
                                                    activeFieldInFocus = "to"
                                                    mapView.toRouteAddress = toTextField.properties.displayText

                                                    locatorTask.suggestions.searchText = toTextField.properties.displayText
                                                }
                                            }
                                        }

                                    }

                                    properties.onAccepted: {
                                        activeFieldInFocus = "to"
                                        var geocodeResult = locatorTask.geocodeWithParameters(toTextField.properties.displayText, geocodeParameters)

                                        locatorTask.suggestions.searchText = ""

                                    }

                                    onCloseButtonClicked:{
                                        isGetDirectionVisible = false

                                        mapView.routeToStopGraphicsOverlay.graphics.remove(mapView.toGraphic)
                                        mapView.routePedestrianLineGraphicsOverlay.graphics.clear()
                                        mapView.routeGraphicsOverlay.graphics.clear();
                                        mapView.routePartGraphicsOverlay.graphics.clear();
                                        totalLength = ""
                                        directionListModel.clear()
                                        mapView.allPoints.pop()
                                        offlineDireView = false

                                        directionView.errorView = false


                                    }
                                }
                            }

                        }

                        Item {
                            Layout.preferredWidth:app.units(40)
                            Layout.preferredHeight:col1.height - app.units(10)

                            Controls.Icon {
                                imageSource: "../images/baseline_swap_vert_white_18dp.png"
                                maskColor: app.subTitleTextColor
                                anchors.centerIn: parent

                                onClicked: {
                                    //change routeStops
                                    isSwapped = true
                                    var temp =fromTextField.properties.text
                                    fromTextField.properties.text = toTextField.properties.text
                                    toTextField.properties.text = temp
                                    var tempStop = mapView.routeStops[0]
                                    mapView.routeStops[0] = mapView.routeStops[1]
                                    mapView.routeStops[1] = tempStop
                                    // add the new graphic
                                    mapView.routeToStopGraphicsOverlay.graphics.clear()
                                    mapView.routeFromStopGraphicsOverlay.graphics.clear()
                                    mapView.routePedestrianLineGraphicsOverlay.graphics.clear()
                                    mapView.routePartGraphicsOverlay.graphics.clear()
                                    directionView.errorView = false
                                    var tempGraphic = mapView.fromGraphic
                                    mapView.fromGraphic = mapView.toGraphic
                                    mapView.toGraphic = tempGraphic
                                    mapView.routeToStopGraphicsOverlay.graphics.append(mapView.toGraphic)
                                    mapView.routeFromStopGraphicsOverlay.graphics.append(mapView.fromGraphic)

                                    //clear route
                                    mapView.routeGraphicsOverlay.graphics.clear();
                                    directionListModel.clear()
                                    totalLength = ""

                                    //add the stops
                                    //hideOfflineRoute()
                                    locatorTask.suggestions.searchText = ""

                                }
                            }
                        }


                    }

                }


            }
            Item{
                Layout.fillWidth: true
                Layout.preferredHeight:locatorErrorMessage > "" ? app.units(8) :0



            }

            Item {
                Layout.preferredHeight: locatorErrorMessage > "" ?searchViewTitle.height :0
                Layout.fillWidth: true
                visible: locatorErrorMessage > ""

                Controls.BaseText {
                    id: searchViewTitle
                    visible: locatorErrorMessage > ""
                    text: locatorErrorMessage
                    //height: parent.height
                    width: parent.width
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: app.units(16)
                    maximumLineCount: 6
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: "red"
                    //horizontalAlignment: Label.AlignLeft

                }
            }
            //
            Rectangle{
                Layout.fillWidth: true
                Layout.preferredHeight: app.units(16)
                visible: directionRect.visible
            }

            Rectangle{
                id:directionRect
                Layout.preferredWidth: parent.width - 2 * app.defaultMargin
                Layout.preferredHeight: directionRect.visible?app.units(40):0
                Layout.leftMargin: app.defaultMargin
                radius: 2

                visible:!suggestions.visible && isGetDirectionVisible//mapView && mapView.allPoints.length === 2//suggestionsModel.count === 0 || routeStops.length === 2

                Controls.CustomButton {
                    id: directionsBtn
                    buttonText:qsTr("Get Directions")
                    buttonColor: getColor(primaryColor)
                    buttonWidth: parent.width //- 32 * scaleFactor
                    buttonHeight: parent.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    buttonTextColor: app.primaryColor
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (HapticFeedback.supported === true)
                            {
                                HapticFeedback.send("Heavy")
                            }
                            isSwapped = false
                            mapView.routeGraphicsOverlay.graphics.clear()
                            mapView.routePedestrianLineGraphicsOverlay.graphics.clear()
                            mapView.routePartGraphicsOverlay.graphics.clear()
                            directionListModel.clear()
                            findRoute()

                        }
                        onPressedChanged: {
                            directionsBtn.buttonColor = pressed ?
                                        Qt.darker(directionsBtn.buttonColor, 1.1): directionsBtn.buttonColor
                        }
                    }
                }



            }



            Pane {
                id: suggestions
                padding: 0
                Layout.fillWidth: true
                Layout.preferredHeight: offlineRoutePage.height - routeBar.height - app.defaultMargin
                visible: suggestionsModel.count > 0 && locatorTask.suggestions.searchText > ""


                ListView {
                    clip: true
                    anchors.fill: parent
                    model: suggestionsModel
                    spacing: 0


                    delegate: Pane {
                        height: app.units(50)
                        width: parent ? parent.width : 0
                        padding: 0
                        background: Rectangle{
                            anchors.fill:parent
                            color:"white"
                        }


                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Item {
                                Layout.preferredWidth: app.units(6)
                            }

                            Controls.Icon {
                                id: suggestionSearchIcon
                                imageSource: "../images/search.png"
                                maskColor: app.subTitleTextColor
                            }

                            Controls.BaseText {
                                id: suggestionText

                                Layout.preferredWidth: parent.width - suggestionSearchIcon.width
                                Layout.fillHeight: true
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                text: suggestions.visible?label:""
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignLeft
                            }
                        }

                        Rectangle {
                            id: separator

                            visible: index !== suggestionsModel.count - 1
                            color: app.separatorColor
                            anchors {
                                bottom: parent.bottom
                                right: parent.right
                            }
                            width: suggestionText.width
                            height: Qt.platform.os === "windows"?app.units(1):app.units(0.5)
                            opacity: 0.5
                        }

                        Controls.Ink {
                            anchors.fill: parent

                            onClicked: {
                                var geocodeResult
                                if(activeFieldInFocus === "from")
                                {
                                    fromTextField.properties.text = label

                                    geocodeResult = locatorTask.geocodeWithParameters(fromTextField.properties.displayText, geocodeParameters)

                                    Qt.inputMethod.hide()


                                }
                                else
                                {
                                    toTextField.properties.text = label

                                    geocodeResult = locatorTask.geocodeWithParameters(toTextField.properties.displayText, geocodeParameters)

                                    Qt.inputMethod.hide()

                                }



                            }
                        }
                    }
                }


            }

            RouteDirectionView {
                id: directionView
                Layout.preferredHeight:offlineRoutePage.height - routeBar.height - app.defaultMargin//200
                Layout.preferredWidth:parent.width
                scaleFactor: app.scaleFactor
                direView: offlineDireView

                visible: isShowDirection && app.isLandscape

            }

            Rectangle {
                id:errorComponent

                Layout.preferredHeight: offlineRoutePage.height - routeBar.height - app.defaultMargin
                Layout.preferredWidth: parent.width

                color: "transparent"
                visible:!app.isLandscape && directionView.errorView

                RowLayout {
                    id: errorComp
                    width:300 * scaleFactor
                    height:app.units(48)

                    anchors.top: parent.top
                    anchors.topMargin: 0 * scaleFactor

                    Item {
                        Layout.preferredWidth: 16 * scaleFactor
                    }

                    Item {
                        Layout.preferredHeight: 24 * scaleFactor
                        Layout.preferredWidth: 24 * scaleFactor

                        Image {
                            id: errorIcon
                            anchors.fill: parent
                            source: alertIcon
                            width: 24 * scaleFactor
                            height: 24 * scaleFactor
                            mipmap:true
                        }
                        ColorOverlay {
                            anchors.fill: errorIcon
                            source: errorIcon
                            color: "#D54550"
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Controls.BaseText {
                            anchors.verticalCenter: parent.verticalCenter
                            Layout.alignment: Qt.AlignLeft
                            text: qsTr("No Route Returned")
                            color:  "#D54550"
                            elide: Text.ElideLeft
                        }
                    }

                    Item {
                        Layout.preferredWidth: 16 * scaleFactor
                    }
                }
            }



            function searchOptionSelected()
            {
                var geocodeResult
                if(activeFieldInFocus === "from")
                {
                    geocodeResult = locatorTask.geocodeWithParameters(fromtextField.properties.displayText, geocodeParameters)
                    mapView.setViewpointGeometry(geocodeResult[0].extent);
                    locatorTask.suggestions.searchText = ""
                }
                else
                {
                    geocodeResult = locatorTask.geocodeWithParameters(toTextField.properties.displayText, geocodeParameters)
                    mapView.setViewpointGeometry(geocodeResult[0].extent);
                    locatorTask.suggestions.searchText = ""
                }

            }


        }

        ColumnLayout{
            width:parent.width
            height:offlineRoutePage.height
            visible:willDockToBottom && offlineDireView


            ToolBar {
                Layout.preferredHeight: 0.8 * app.headerHeight
                Layout.fillWidth: true
                Material.background: "#EFEFEF"
                Material.elevation: 0

                RowLayout{
                    anchors.fill: parent

                    RowLayout {

                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Controls.Icon {
                            id: closeBtn

                            visible: true
                            imageSource: "../controls/images/close.png"
                            leftPadding: 16 * scaleFactor
                            // Layout.alignment: Qt.AlignLeft
                            Layout.alignment: Qt.AlignVCenter
                            maskColor: "#4c4c4c"
                            onClicked: {
                                clearRouteElements()

                                hideOfflineRoute()

                            }
                        }

                        Controls.BaseText {
                            Layout.alignment: Qt.AlignVCenter

                            Layout.preferredWidth: parent.width - closeBtn.width - expandIcon.width - 4 * root.defaultMargin

                            text: qsTr("Directions")
                            maximumLineCount: 1

                            //   anchors.centerIn: parent

                            elide: Text.ElideRight
                            font.family: titleFontFamily
                            rightPadding: app.units(16)
                            Layout.preferredHeight: contentHeight
                        }

                        Item {
                            Layout.fillWidth: true
                        }


                        Rectangle {

                            Layout.preferredWidth: app.units(50)
                            Layout.fillHeight: true
                            color:"transparent"


                            Controls.Icon {
                                id: expandIcon
                                anchors.centerIn:parent


                                maskColor: "#4c4c4c"
                                imageSource: "../images/arrowDown.png"
                                rotation:showInView === true? 0:180
                                visible:true

                            }

                            MouseArea {

                                anchors.fill: parent
                                onClicked: {
                                    showInView = !showInView
                                    if(!showInView)
                                        dockToBottomReduced()
                                    else
                                        dockToBottom()


                                }
                            }


                        }



                    }


                }

            }


            Rectangle{
                Layout.fillWidth: true
                Layout.fillHeight:true
                RouteDirectionView {
                    id: directionView1
                    anchors.fill:parent
                    scaleFactor: app.scaleFactor
                    direView: offlineDireView

                }
            }

        }


        onDockToBottom:
        {

            offlineRoutePage.height = parent.height * 0.4
        }


        function populateDirectionListModel(generatedRoute)
        {
            for(var k=0;k<generatedRoute.directionManeuvers.count;k++)
            {
                var dirObj = generatedRoute.directionManeuvers.get(k)

                var length = 0
                var distance = 0
                if(dirObj.length.toFixed(2) > length)
                {

                    distance = app.getDistance(dirObj.length)

                }
                else
                    distance = ""
                directionListModel.append({"directionText":dirObj.directionText,"length":distance,"estimatedArrivalTime":dirObj.estimatedArrivalTime,"directionManeuverType":dirObj.directionManeuverType,"geometry":JSON.stringify(dirObj.geometry.json)})
            }
        }

        function addPedestrianRoute(generatedRoute)
        {
            var polylinebuildr = ArcGISRuntimeEnvironment.createObject("PolylineBuilder",{spatialReference:generatedRoute.routeGeometry.spatialReference})
            //console.log("adding pedestrian line3",dirObj.geometry.x,dirObj.geometry.y)
            polylinebuildr.addPointXY(generatedRoute.routeGeometry.json.paths[0][0][0],generatedRoute.routeGeometry.json.paths[0][0][1])
            polylinebuildr.addPointXY(mapView.fromGraphic.geometry.x,mapView.fromGraphic.geometry.y)
            var routeSegmentGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: polylinebuildr.geometry });
            mapView.routePedestrianLineGraphicsOverlay.graphics.append(routeSegmentGraphic)
            var polylinebuildr1 = ArcGISRuntimeEnvironment.createObject("PolylineBuilder",{spatialReference:generatedRoute.routeGeometry.spatialReference})

            var len = generatedRoute.routeGeometry.json.paths[0].length
            polylinebuildr1.addPointXY(generatedRoute.routeGeometry.json.paths[0][len - 1][0],generatedRoute.routeGeometry.json.paths[0][len - 1][1])
            polylinebuildr1.addPointXY(mapView.toGraphic.geometry.x,mapView.toGraphic.geometry.y)
            var routeSegmentGraphic1 = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: polylinebuildr1.geometry });
            mapView.routePedestrianLineGraphicsOverlay.graphics.append(routeSegmentGraphic1)

        }
        function getIconRotation(directionManeuverType)
        {

            var Icon_rotation = 0
            //var url directionsIcon1 = "../images/baseline_directions_white_48dp.png"

            switch(directionManeuverType.toString())
            {
                //stop
            case "1":
                Icon_rotation = 0
                //directionsIcon_default = "../images/start.png"
                break
                //straight
            case "2":
                Icon_rotation = 0
                //directionsIcon_default = "../images/baseline_arrow_upward_white_48dp.png"
                break
                //bear left
            case "3":
                Icon_rotation = 180
                break
                //bear right
            case "4":
                Icon_rotation = 180
                //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
                break
                //left turn
            case "5":
                Icon_rotation = 180
                //directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"
                break
                //right turn
            case "6":
                Icon_rotation = 180
                //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
                break
                //sharp left
            case "7":
                Icon_rotation = 180
                //directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"
                break
                //sharp right
            case "8":
                Icon_rotation = 180
                //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
                break
                //U turn
            case "9":
                break
                //roundabout
            case "11":
                break
                //merge
            case "12":
                break
                //exit
            case "13":
                break
            default:

            }
            return Icon_rotation

        }

        function getDirectionIcon(directionManeuverType)
        {
            var directionsIcon_default = "../images/baseline_directions_white_48dp.png"
            //var url directionsIcon1 = "../images/baseline_directions_white_48dp.png"

            switch(directionManeuverType.toString())
            {
            case "0":
                directionsIcon_default = "../images/question-32.svg"
                break
                //stop
            case "1":
                directionsIcon_default = "../images/start.png"
                break
                //straight
            case "2":
                directionsIcon_default = "../images/straight-24.svg"
                break
                //bear left
            case "3":
                directionsIcon_default = "../images/bear-left-24.svg"
                break
                //bear right
            case "4":
                directionsIcon_default = "../images/bear-right-24.svg"
                break
                //left turn
            case "5":
                directionsIcon_default = "../images/left-24.svg"
                break
                //right turn
            case "6":
                directionsIcon_default = "../images/right-24.svg"
                break
                //sharp left
            case "7":
                directionsIcon_default = "../images/sharp-left-24.svg"
                break
                //sharp right
            case "8":
                directionsIcon_default = "../images/sharp-right-24.svg"
                break
                //U turn
            case "9":
                directionsIcon_default = "../images/u-turn-24.svg"
                break
                //ferry
            case "10":
                //directionsIcon_default = "../images/u-turn-24.svg"
                break
                //roundabout
            case "11":
                directionsIcon_default = "../images/round-about-24.svg"
                break
                //merge
            case "12":
                directionsIcon_default = "../images/merge-24.svg"
                break
                //exit
            case "13":
                directionsIcon_default = "../images/exit-highway-left-24.svg"
                break
                //change of highway
            case "14":
                directionsIcon_default = "../images/highway-change-24.svg"
                break
                //straight at fork
            case "15":
                directionsIcon_default = "../images/fork-middle-24.svg"
                break
                //left at fork
            case "16":
                directionsIcon_default = "../images/fork-left-24.svg"
                break
                //right at fork
            case "17":
                directionsIcon_default = "../images/fork-right-24.svg"
                break
                //start
            case "18":
                directionsIcon_default = "../images/start.png"
                break;
            case "19":
                directionsIcon_default = "../images/ellipsis-32.svg"
                break;
            case "20":
                directionsIcon_default = "../images/pin-32.svg"
                break;
                //bear right on a ramp
            case "21":
                directionsIcon_default = "../images/bear-right-24.svg"
                break
                //bear left on a ramp
            case "22":
                directionsIcon_default = "../images/bear-left-24.svg"
                break
                //left-right
            case "23":
                directionsIcon_default = "../images/left-right-32.svg"
                break
                //right-left
            case "24":
                directionsIcon_default = "../images/right-left-32.svg"
                break
                //right-right
            case "25":
                directionsIcon_default = "../images/right-right-32.svg"
                break
                //left-left
            case "26":
                directionsIcon_default = "../images/left-left-32.svg"
                break
            default:

            }
            return directionsIcon_default

        }

        function loadRouteTask()
        {
            if (currentRouteTask === null || currentRouteTask.loadStatus !== Enums.LoadStatusLoaded)
            {
                if (mapView && mapView.mmpk.maps[0].transportationNetworks.length > 0) {
                    console.log("RouteTask supported")
                    currentRouteTask = ArcGISRuntimeEnvironment.createObject("RouteTask", {transportationNetworkDataset: mapView.mmpk.maps[0].transportationNetworks[0]});
                    currentRouteTask.load();
                }
            }
        }

    }
    function getAppProperty (appProperty, fallback) {
        if (!fallback) fallback = ""
        try {
            return appProperty ? appProperty : fallback
        } catch (err) {
            return fallback
        }
    }
    function getColor(colorStr)
    {
        var colorString = colorStr.toString()

        var colorval = colorString.split("#")[1]
        return "#"+"20"+colorval
    }

    function updateStopPoints(pinLocation)
    {
        mapView.allPoints.push(pinLocation)
        var pinGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: pinLocation});
        var stop = ArcGISRuntimeEnvironment.createObject("Stop", {name: "stop", geometry: pinLocation});
        //mapView.zoomToPoint(locatorTask.geocodeResults[0].displayLocation)
        // mapView.setViewpointCenterAndScale(locatorTask.geocodeResults[0].displayLocation,1000)
        if (activeFieldInFocus === "from") {

            var pinGraphic_from = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: pinLocation});

            mapView.routeFromStopGraphicsOverlay.graphics.clear()
            mapView.routeFromStopGraphicsOverlay.graphics.append(pinGraphic_from)

            mapView.fromGraphic = pinGraphic_from

            if(mapView.routeStops.length >= 2)
            {
                mapView.routeStops.splice(0,1,stop);
                mapView.routeGraphicsOverlay.graphics.clear()

            }
            else
                mapView.routeStops.splice(0,0,stop);

        }

        if (activeFieldInFocus === "to") {
            var pinGraphic_to = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: pinLocation});

            mapView.routeToStopGraphicsOverlay.graphics.clear()
            mapView.routeToStopGraphicsOverlay.graphics.append(pinGraphic_to);
            mapView.toGraphic = pinGraphic
            if(mapView.routeStops.length >= 2)
            {
                mapView.routeStops.splice(1,1,stop);
                mapView.routeGraphicsOverlay.graphics.clear()
            }
            else
                mapView.routeStops.splice(1,0,stop);

        }
        mapView.routeStops.splice(2)
        locatorTask.suggestions.searchText = ""
        if(mapView.allPoints.length >= 2)
            isGetDirectionVisible = true
    }

    function populateDirectionListModel(generatedRoute)
    {
        for(var k=0;k<generatedRoute.directionManeuvers.count;k++)
        {
            var dirObj = generatedRoute.directionManeuvers.get(k)

            var length = 0
            var distance = 0
            if(dirObj.length.toFixed(2) > length)
            {

                distance = app.getDistance(dirObj.length)

            }
            else
                distance = ""
            directionListModel.append({"directionText":dirObj.directionText,"length":distance,"estimatedArrivalTime":dirObj.estimatedArrivalTime,"directionManeuverType":dirObj.directionManeuverType,"geometry":JSON.stringify(dirObj.geometry.json)})
        }
    }

    function addPedestrianRoute(generatedRoute)
    {
        var polylinebuildr = ArcGISRuntimeEnvironment.createObject("PolylineBuilder",{spatialReference:generatedRoute.routeGeometry.spatialReference})
        //console.log("adding pedestrian line3",dirObj.geometry.x,dirObj.geometry.y)
        polylinebuildr.addPointXY(generatedRoute.routeGeometry.json.paths[0][0][0],generatedRoute.routeGeometry.json.paths[0][0][1])
        //var frompoint = ArcGISRuntimeEnvironment.createObject("Point", {x:mapView.fromGraphic.geometry.x, y:mapView.fromGraphic.geometry.y, spatialReference:mapView.spatialReference})
        var fromPoint = GeometryEngine.project(mapView.fromGraphic.geometry, mapView.spatialReference)
        polylinebuildr.addPointXY(fromPoint.x,fromPoint.y)
        var routeSegmentGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: polylinebuildr.geometry });
        mapView.routePedestrianLineGraphicsOverlay.graphics.append(routeSegmentGraphic)
        var polylinebuildr1 = ArcGISRuntimeEnvironment.createObject("PolylineBuilder",{spatialReference:generatedRoute.routeGeometry.spatialReference})
        var len = generatedRoute.routeGeometry.json.paths[0].length
        polylinebuildr1.addPointXY(generatedRoute.routeGeometry.json.paths[0][len - 1][0],generatedRoute.routeGeometry.json.paths[0][len - 1][1])
        var toPoint = GeometryEngine.project(mapView.toGraphic.geometry, mapView.spatialReference)

        polylinebuildr1.addPointXY(toPoint.x,toPoint.y)
        var routeSegmentGraphic1 = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: polylinebuildr1.geometry });
        mapView.routePedestrianLineGraphicsOverlay.graphics.append(routeSegmentGraphic1)

    }
    function getIconRotation(directionManeuverType)
    {

        var Icon_rotation = 0
        //var url directionsIcon1 = "../images/baseline_directions_white_48dp.png"

        switch(directionManeuverType.toString())
        {
            //stop
        case "1":
            Icon_rotation = 0
            //directionsIcon_default = "../images/start.png"
            break
            //straight
        case "2":
            Icon_rotation = 0
            //directionsIcon_default = "../images/baseline_arrow_upward_white_48dp.png"
            break
            //bear left
        case "3":
            Icon_rotation = 180
            break
            //bear right
        case "4":
            Icon_rotation = 180
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            break
            //left turn
        case "5":
            Icon_rotation = 180
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"
            break
            //right turn
        case "6":
            Icon_rotation = 180
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            break
            //sharp left
        case "7":
            Icon_rotation = 180
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"
            break
            //sharp right
        case "8":
            Icon_rotation = 180
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            break
            //U turn
        case "9":
            break
            //roundabout
        case "11":
            break
            //merge
        case "12":
            break
            //exit
        case "13":
            break
        default:



        }
        return Icon_rotation

    }

    function getDirectionIcon(directionManeuverType)
    {
        var directionsIcon_default = "../images/baseline_directions_white_48dp.png"
        //var url directionsIcon1 = "../images/baseline_directions_white_48dp.png"

        switch(directionManeuverType.toString())
        {
            //stop
        case "1":
            directionsIcon_default = "../images/start.png"
            break
            //straight
        case "2":
            directionsIcon_default = "../images/straight-24.svg"
            //directionsIcon_default = "../images/baseline_arrow_upward_white_48dp.png"
            break
            //bear left
        case "3":
            directionsIcon_default = "../images/bear-left-24.svg"
            // directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"
            break
            //bear right
        case "4":
            directionsIcon_default = "../images/bear-right-24.svg"
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"

            // directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            break
            //left turn
        case "26":
        case "5":
            directionsIcon_default = "../images/left-24.svg"
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"
            break
            //right turn
        case "6":
        case "25":
            directionsIcon_default = "../images/right-24.svg"
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            break
            //sharp left
        case "7":
            directionsIcon_default = "../images/sharp-left-24.svg"
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"
            break
            //sharp right
        case "8":
            directionsIcon_default = "../images/sharp-right-24.svg"
            // directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"

            //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            break
            //U turn
        case "9":
            directionsIcon_default = "../images/u-turn-24.svg"
            break
            //ferry
        case "10":
            //directionsIcon_default = "../images/u-turn-24.svg"
            break
            //roundabout
        case "11":
            directionsIcon_default = "../images/round-about-24.svg"
            break
            //merge
        case "12":
            directionsIcon_default = "../images/merge-24.svg"
            break
            //exit
        case "13":
            directionsIcon_default = "../images/exit-highway-left-24.svg"
            break
            //change of highway
        case "14":
            directionsIcon_default = "../images/highway-change-24.svg"
            break
            //straight at fork
        case "15":
            directionsIcon_default = "../images/fork-middle-24.svg"
            break
            //left at fork
        case "16":
            directionsIcon_default = "../images/fork-left-24.svg"
            break
            //right at fork
        case "17":
            directionsIcon_default = "../images/fork-right-24.svg"
            break
            //start
        case "18":
            directionsIcon_default = "../images/start.png"
            break;
            //bear right on a ramp
        case "21":
            directionsIcon_default = "../images/right_ramp.svg"
            break
            //bear left on a ramp
        case "22":
            directionsIcon_default = "../images/left_ramp.svg"
            break
        default:



        }
        return directionsIcon_default

    }

    function loadRouteTask()
    {
        if (currentRouteTask === null || currentRouteTask.loadStatus !== Enums.LoadStatusLoaded)
        {
            if (mapView && mapView.map.transportationNetworks.length > 0) {
                // console.log("RouteTask supported")
                currentRouteTask = ArcGISRuntimeEnvironment.createObject("RouteTask", {transportationNetworkDataset: mapView.map.transportationNetworks[0]});
                currentRouteTask.load();
            }
        }
    }

    function findRoute()
    {
        if(currentRouteTask)
        {
            if (currentRouteTask.solveRouteStatus !== Enums.TaskStatusInProgress && mapView.routeStops.length === 2) {
                // clear any previous routing displays
                mapView.routeGraphicsOverlay.graphics.clear();

                // set stops
                currentRouteParams.clearStops()
                currentRouteParams.setStops(mapView.routeStops);
                // solve route using created default parameters
                currentRouteTask.solveRoute(currentRouteParams);

            }
        }
        else
        {
            loadRouteTask()
        }

    }

    function clearRoute()
    {
        isGetDirectionVisible = false
        mapView.routeGraphicsOverlay.graphics.clear();
        mapView.routePartGraphicsOverlay.graphics.clear();
        mapView.routePedestrianLineGraphicsOverlay.graphics.clear()
        totalLength = ""
        directionListModel.clear()
        offlineDireView = false
        directionView.errorView = false
    }
    function clearRouteElements()
    {
        try{
            mapView.routeGraphicsOverlay.graphics.clear()
            mapView.routePartGraphicsOverlay.graphics.clear()
            mapView.routePedestrianLineGraphicsOverlay.graphics.clear()
            locatorTask.suggestions.searchText = ""
            directionListModel.clear()
            totalLength = ""
        }
        catch(ex)
        {
            console.error("Error:",ex.toString())
        }
    }


}
