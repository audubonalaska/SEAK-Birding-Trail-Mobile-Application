import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.12
import QtQuick.Controls 2.12 as QtControls
import QtQuick.Controls.Material 2.1
import QtGraphicalEffects 1.0
import Esri.ArcGISRuntime 100.14
import ArcGIS.AppFramework.Notifications 1.0
import QtQuick.Window 2.12

import "../controls" as Controls
FocusScope {

    id:spatialSearch

    //anchors.fill: parent
    property MapView _mapView:null
    property var noitems:5
    property bool screenWidth:app.isLandscape
    property bool willDockToBottom:false
    property string activeBtn:"distance"
    property bool showResults:false
    property bool intermediateView: false
    property alias listView: resultsListView
    property real headerHeight: 0.8 * app.headerHeight
    property real expandIconSize: app.units(40)
    property string sectionPropertyAttr: "layerNameWithCount"
    property bool search:false
    property var measurementUnits:measurePanel.lengthUnits.miles
    property var measurementUnits_abbr: strings.mi
    property var currentRadius: 5
    property bool valueChanged:false



    signal hideSpatialSearch()
    signal dockToBottom()
    signal dockToLeft()
    signal dockToTop()
    signal doSpatialSearch()

    //height: app.height
    //width:parent.width
    focus: true
    Keys.onReleased: {
        if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
            event.accepted = true
            backButtonPressed()
        }
    }

    onScreenWidthChanged: {

        if(spatialSearchDockItem.visible){

            if(!app.isLandscape)
            {
                dockToBottom()
                spatialSearch.height = app.height * 0.50
                spatialsearchPage.height = app.height * 0.505


            }
            else
            {
                willDockToBottom = false
                dockToLeft()
                spatialSearch.height = app.height - app.headerHeight
                spatialsearchPage.height = app.height - app.headerHeight
            }

        }
    }




    Item {
        id: spatialsearchPage
        height: app.height - app.headerHeight
        width:parent.width

        LayoutMirroring.enabled: !app.isLeftToRight
        LayoutMirroring.childrenInherit: !app.isLeftToRight

        property MapView mapView
        visible:!showResults

        Controls.BasePage {
            id:spatialSearchContent

            anchors.fill: parent
            anchors.bottom: parent.bottom
            anchors.bottomMargin: app.isIphoneX ? 2 * app.defaultMargin : 0
            Material.background: "white"//app.backgroundColor//"transparent"

            header: Rectangle {
                id: spatialsearchBar

                property real tabBarHeight: 0.8 * app.headerHeight
                property real searchBoxHeight: app.headerHeight
                Material.background: app.primaryColor
                Material.foreground: app.subTitleTextColor
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                height: searchBoxHeight //+ tabBarHeight + app.defaultMargin

                Rectangle {
                    anchors {
                        fill: parent

                    }
                    radius: app.units(2)

                    color: app.backgroundColor

                    ColumnLayout {
                        anchors.fill: parent
                        width: parent.width
                        height: parent.height
                        spacing: 0


                        RowLayout {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            spacing: 0
                            Controls.Icon {
                                imageSource: "../images/close.png"
                                maskColor:"#4c4c4c" //app.subTitleTextColor
                                rotation: app.isLeftToRight ? 0 : 180

                                onClicked: {
                                    hideSpatialSearch()
                                    isExpandButtonClicked = false


                                }
                            }

                            //Controls.CustomTextField {
                            Label{
                                id: textField

                                Material.accent: app.baseTextColor
                                Material.foreground: app.subTitleTextColor
                                Layout.alignment:Qt.AlignVCenter
                                Layout.leftMargin: app.baseUnit
                                Layout.rightMargin: app.baseUnit
                                text:strings.filters

                            }

                            Item{
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                            }
                            Label{
                                id: textField2

                                Material.accent: app.baseTextColor
                                Material.foreground: app.subTitleTextColor
                                Layout.alignment:Qt.AlignVCenter
                                Layout.leftMargin: app.baseUnit
                                Layout.rightMargin:baseUnit //24 * scaleFactor//app.baseUnit
                                text:strings.reset//qsTr("Reset")
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        spatialSearchContent.reset()
                                    }
                                }

                            }




                            Rectangle{
                                id:expandIcon
                                Layout.preferredWidth:app.units(40)//app.units(130)
                                Layout.fillHeight: true
                                color:"transparent"
                                Layout.alignment: Qt.AlignRight

                                visible:!app.isLandscape
                                RowLayout{
                                    anchors.fill:parent
                                    spacing:0


                                    Rectangle{
                                        id:expandrect
                                        Layout.preferredWidth:expandBtn.visible? app.units(40):0
                                        Layout.fillHeight: true
                                        color:"transparent"
                                        //visible:expandBtn.visible

                                        Controls.Icon {
                                            id: expandBtn
                                            visible:true
                                            anchors.centerIn: parent
                                            imageWidth: app.units(30)
                                            imageHeight: app.units(30)

                                            //Material.background: root.backgroundColor
                                            Material.elevation: 0
                                            maskColor: "#4c4c4c"
                                            rotation:isExpandButtonClicked ? 0:180
                                            imageSource: "../images/arrowDown.png"

                                            onClicked: {

                                                if(isExpandButtonClicked)
                                                {
                                                    dockToBottom()
                                                    spatialSearch.height = app.height * 0.50//0.45
                                                    spatialsearchPage.height = app.height * 0.505
                                                    app.isExpandButtonClicked = false

                                                }
                                                else{

                                                    dockToTop()
                                                    spatialSearch.height = app.height - app.headerHeight
                                                    spatialsearchPage.height = app.height - app.headerHeight
                                                    app.isExpandButtonClicked = true
                                                    //
                                                }
                                            }
                                        }
                                    }

                                }



                            }



                        }
                    }



                }
            }

            footer: Rectangle {
                id:buttonbar
                width: parent.width
                height: 48 * scaleFactor
                visible: submitBtn.enabled
                anchors.bottom: spatialSearchContent.bottom//app.bottom
                radius: 4*app.scaleFactor
                clip: true

                Rectangle{
                    width:parent.width
                    height:1
                    color:app.separatorColor
                    anchors.top:parent.top
                    opacity: 0.5
                }



                RowLayout{

                    anchors.fill: parent
                    spacing:8 * app.scaleFactor

                    Rectangle{
                        Layout.preferredWidth: parent.width - 32 * scaleFactor
                        Layout.fillHeight: true
                        color:"transparent"
                        Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter

                        Controls.CustomButton {
                            id: submitBtn
                            enabled: mapView.spatialfeaturesModel.searchGeometry !== null && mapView.isSpatialSearchFinished

                            buttonText: valueChanged ?strings.update:strings.see_results
                            buttonColor: enabled ?app.primaryColor: "grey"//app.buttonColor
                            buttonFill: true

                            buttonWidth: parent.width
                            buttonHeight: 40 * app.scaleFactor
                            anchors.centerIn:parent

                            MouseArea {
                                anchors.fill: parent
                                enabled:app.isOnline
                                onClicked: {

                                    if (valueChanged){
                                        if(currentRadius > 0){
                                            spatialSearchManager.saveSearchConfig(currentRadius,measurementUnits)
                                            doSpatialSearch();

                                            valueChanged = false
                                        }
                                    }
                                    else
                                    {
                                        //mapView.spatialfeaturesModel.searchGeometry
                                        mapView.zoomToSpatialSearchLayer(mapView.spatialfeaturesModel.searchGeometry)

                                        showResults = true
                                    }

                                }
                            }
                        }

                    }

                }

            }

            contentItem:Flickable{
                id:spatialSearchPanel
                anchors.fill: parent
                contentWidth: parent.width
                contentHeight:colsp.height //spatialSearch.height
                boundsBehavior: Flickable.StopAtBounds
                clip: true


                ColumnLayout{
                    id:colsp
                    width:parent.width
                    //anchors.fill: parent
                    spacing:0//8 * scaleFactor
                    anchors.centerIn: parent

                    Rectangle{
                        Layout.preferredWidth:parent.width
                        Layout.preferredHeight:app.headerHeight - 16 * scaleFactor

                    }
                    Rectangle{
                        Layout.preferredHeight: 8 * scaleFactor
                        Layout.fillWidth: true
                        color:app.backgroundColor

                    }

                    Rectangle{
                        id:criteriarect
                        Layout.preferredWidth:parent.width
                        Layout.preferredHeight:170 * scaleFactor
                        Layout.alignment: Qt.AlignHCenter


                        ColumnLayout{
                            width:parent.width - 32 * scaleFactor
                            height:parent.height
                            anchors.centerIn: parent
                            spacing:0

                            Rectangle{
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32 * scaleFactor

                            }

                            Label {
                                Layout.fillWidth: parent.width - 32 * scaleFactor
                                Layout.topMargin: 0

                                Layout.preferredHeight: 16 * scaleFactor
                                text: strings.search_criteria
                                leftPadding: 0
                                font.pixelSize: 16 * scaleFactor
                                font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                color: "#6A6A6A"

                                font.bold:true
                                horizontalAlignment: Label.AlignLeft

                            }


                            Rectangle{
                                id:criteriaRect
                                Layout.preferredWidth:parent.width
                                Layout.preferredHeight:40 * scaleFactor
                                color:app.backgroundColor
                                Layout.topMargin: 24 * scaleFactor
                                Layout.alignment: Qt.AlignCenter
                                radius: 5


                                RowLayout{
                                    id:btns
                                    spacing:0

                                    anchors.centerIn: parent

                                    anchors.fill: parent
                                    Rectangle {
                                        id: distanceBtn
                                        Layout.preferredWidth:parent.width/2
                                        Layout.preferredHeight:parent.height
                                        color:activeBtn === "distance" ?app.primaryColor:app.backgroundColor//buttonFill ? buttonColor : "transparent"

                                        radius:5 * scaleFactor


                                        Text {
                                            id: text
                                            height:parent.height
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color:activeBtn === "distance"?"white":app.primaryColor
                                            text:strings.distance
                                            font.pixelSize: 14
                                            fontSizeMode: Text.Fit
                                            font.bold: true
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (HapticFeedback.supported === true)
                                                {
                                                    HapticFeedback.send("Heavy")
                                                }


                                            }
                                            onPressedChanged: {
                                                activeBtn = "distance"

                                            }
                                        }


                                    }
                                    /* Rectangle{
                                        Layout.preferredWidth: 1
                                        Layout.preferredHeight: parent.height - 20
                                        color:app.separatorColor
                                        visible:activeBtn === "distance"?false:true
                                    }*/

                                    Rectangle {
                                        id: extentBtn
                                        Layout.preferredWidth:parent.width/2

                                        Layout.preferredHeight:parent.height
                                        color:activeBtn === "extent"?app.primaryColor:app.backgroundColor

                                        radius:5//buttonBorderRadius


                                        Text {
                                            id: text1
                                            height:parent.height
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color:activeBtn === "extent"?"white":app.primaryColor
                                            text:strings.map_extent
                                            font.pixelSize: 14
                                            fontSizeMode: Text.Fit
                                            font.bold: true
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (HapticFeedback.supported === true)
                                                {
                                                    HapticFeedback.send("Heavy")
                                                }


                                            }
                                            onPressedChanged: {
                                                activeBtn = "extent"

                                            }
                                        }


                                    }
                                    //commented out to be included later

                                    /* Rectangle{
                                        Layout.preferredWidth: 1
                                        Layout.preferredHeight: parent.height - 20
                                        color:app.separatorColor
                                    }
                                    Rectangle {
                                        id: shapeBtn
                                        Layout.preferredWidth:(criteriaRect.width - 2)/3
                                        Layout.preferredHeight:parent.height
                                        color:activeBtn === "shape"? app.primaryColor:app.backgroundColor//buttonFill ? buttonColor : "transparent"
                                        //border.color: buttonColor
                                        //border.width: buttonFill ? 0 : 2
                                        radius:5//buttonBorderRadius
                                        //anchors.horizontalCenter: parent.horizontalCenter
                                        Text {
                                            id: text2
                                            height:parent.height
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color:activeBtn === "shape"?"white":app.primaryColor//buttonFill ? buttonTextColor : buttonColor
                                            text:"Shape"
                                            font.pixelSize: 14
                                            fontSizeMode: Text.Fit
                                            font.bold:true
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (HapticFeedback.supported === true)
                                                {
                                                    HapticFeedback.send("Heavy")
                                                }
                                            }
                                            onPressedChanged: {
                                                distanceBtn.buttonColor = pressed ?
                                                            Qt.darker(distanceBtn.buttonColor, 1.1): distanceBtn.buttonColor
                                            }
                                        }
                                    }
*/




                                }
                            }

                            Label {
                                id:hintText
                                Layout.preferredWidth:parent.width
                                Layout.topMargin: 10 * scaleFactor
                                Layout.preferredHeight: 24 * scaleFactor
                                text:activeBtn === "distance"?strings.search_distance_hint : strings.search_extent_hint
                                leftPadding: 0
                                font.pixelSize: 12 * scaleFactor
                                font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                color: "#6A6A6A"
                                opacity:0.7
                                elide: Text.ElideRight
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2

                                // font.bold:true
                                horizontalAlignment: Label.AlignLeft

                            }

                            Rectangle{
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24

                            }


                        }



                    }
                    Rectangle{
                        Layout.preferredHeight: 8 * scaleFactor
                        Layout.fillWidth: true
                        color:app.backgroundColor

                    }

                    Rectangle{
                        id:distanceconfrect
                        //color:"yellow"
                        Layout.preferredWidth:parent.width
                        Layout.preferredHeight:120 * scaleFactor
                        visible:activeBtn === "distance"
                        ColumnLayout{
                            width:parent.width - 32 * scaleFactor//48
                            height:parent.height - 48 * scaleFactor
                            anchors.centerIn: parent

                            Label {
                                Layout.fillWidth: parent.width - 32 * scaleFactor

                                Layout.preferredHeight: 22 * scaleFactor
                                text:strings.distance //qsTr("Distance")
                                leftPadding: 0
                                font.pixelSize: 16 * scaleFactor
                                font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                color:"#6A6A6A"

                                font.bold:true
                                horizontalAlignment: Label.AlignLeft
                            }


                            Rectangle{
                                id:distanceRect
                                Layout.preferredWidth:parent.width
                                Layout.preferredHeight:parent.height/2
                                color:"transparent"//app.backgroundColor





                                RowLayout{
                                    id:distancebtns
                                    spacing:0
                                    anchors.fill: parent

                                    Label {
                                        id:searchText

                                        Layout.preferredWidth:implicitWidth > parent.width - 24 - 72   - unitsLabel.width ? parent.width - 24 - 72   - unitsLabel.width :implicitWidth

                                        text: strings.search_results_within
                                        leftPadding: 0
                                        font.pixelSize: 14 * scaleFactor
                                        font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                        color: "#6A6A6A"
                                        elide: Text.ElideRight
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2

                                        // font.bold:true
                                        horizontalAlignment: Label.AlignLeft

                                        MouseArea{
                                            anchors.fill: parent
                                            onClicked: {

                                                unitsPopup.open()

                                            }

                                        }
                                    }
                                    Label {
                                        id:unitsLabel

                                        text: "(%1)".arg(measurementUnits_abbr)
                                        leftPadding: 4
                                        font.pixelSize: 14 * scaleFactor
                                        font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                        color:app.primaryColor //"#6A6A6A"


                                        font.bold:true
                                        horizontalAlignment: Label.AlignLeft
                                        MouseArea{
                                            anchors.fill: parent
                                            onClicked: {

                                                unitsPopup.open()

                                            }

                                        }
                                    }

                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: parent.height - 20
                                        color:"transparent"
                                    }

                                    TextField {
                                        id: amount
                                        Layout.preferredHeight: 32 * scaleFactor
                                        Layout.preferredWidth: 72 * app.scaleFactor
                                        topPadding: 0
                                        bottomPadding: 0
                                        leftPadding: 4 * scaleFactor
                                        rightPadding: 4 * scaleFactor
                                        font.pixelSize: 14 * app.scaleFactor
                                        font.bold: true
                                        font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                        color: "#6A6A6A"
                                        Material.accent: app.primaryColor
                                        clip: true
                                        selectByMouse: true
                                        horizontalAlignment: TextField.AlignHCenter
                                        verticalAlignment: TextField.AlignVCenter
                                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                                        validator: RegExpValidator{regExp: /^[0-9/]+$/}

                                        background: Rectangle {

                                            anchors.fill: parent
                                            color: "#EAEAEA"
                                        }

                                        onEditingFinished: {
                                            amount.text = qsTr("%L1").arg(currentRadius);
                                        }

                                        Component.onCompleted: {
                                            // Set default value of the selected buffer radius to the textfield when opened
                                            amount.text = qsTr("%L1").arg(currentRadius);
                                            if (visible) {
                                                if (focus) {
                                                    forceActiveFocus();

                                                    cursorPosition = text.length;
                                                }
                                            }
                                        }

                                        onTextChanged: {
                                            if(_mapView.spatialSearchConfig && _mapView.spatialSearchConfig.distance !== amount.text){
                                                valueChanged = true;
                                                var _locallang = Qt.locale()
                                                let _txt = Number.fromLocaleString(_locallang, amount.text)

                                                // set current radius to reflect the change in the radius textfield
                                                currentRadius = parseInt(_txt);
                                                spatialSearchManager.saveSearchConfig(currentRadius,measurementUnits);
                                            }
                                        }

                                        Rectangle {
                                            id: bottomBorder

                                            width: parent.width
                                            height: app.scaleFactor
                                            color: app.primaryColor

                                            anchors.bottom: parent.bottom
                                        }

                                    }



                                    Controls.PopupMenu {
                                        id: unitsPopup

                                        // defaultMargin: app.defaultMargin

                                        backgroundColor: "#FFFFFF"
                                        highlightColor: Qt.darker(app.backgroundColor, 1.1)
                                        textColor: app.baseTextColor
                                        primaryColor: app.primaryColor
                                        menuItems: [

                                            {"itemLabel": strings.ft},
                                            {"itemLabel":strings.km },
                                            {"itemLabel": strings.m},
                                            {"itemLabel":strings.mi }

                                        ]

                                        Material.primary: app.primaryColor
                                        Material.background: backgroundColor

                                        height: app.units(160)

                                        x: app.isLeftToRight ? (searchText.width + 20) : (parent.width - width - app.baseUnit)
                                        //y: 0
                                        y : -app.units(20)
                                        padding: 0
                                        bottomMargin: 2*defaultMargin

                                        onMenuItemSelected: {
                                            switch (itemLabel) {
                                            case strings.mi:
                                                measurementUnits_abbr = strings.mi
                                                measurementUnits = measurePanel.lengthUnits.miles
                                                currentRadius = 5;
                                                valueChanged = true
                                                break
                                            case strings.ft:
                                                measurementUnits_abbr = strings.ft
                                                measurementUnits = measurePanel.lengthUnits.feet
                                                currentRadius = 5000;
                                                valueChanged = true
                                                break
                                            case strings.km:
                                                measurementUnits_abbr = strings.km
                                                measurementUnits = measurePanel.lengthUnits.kilometers
                                                currentRadius = 5;
                                                valueChanged = true
                                                break
                                            case strings.m:
                                                measurementUnits_abbr = strings.m
                                                measurementUnits = measurePanel.lengthUnits.meters
                                                currentRadius = 500;
                                                valueChanged = true
                                                break
                                            }

                                            amount.text = qsTr("%L1").arg(currentRadius);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle{
                        Layout.preferredHeight: 8 * scaleFactor
                        Layout.fillWidth: true
                        color:app.backgroundColor

                    }


                    Rectangle{
                        Layout.preferredWidth:parent.width
                        Layout.preferredHeight: searchlayerspanel.height

                        ColumnLayout{
                            id:searchlayerspanel
                            width:parent.width
                            Item{
                                Layout.preferredWidth: parent.width
                                Layout.preferredHeight: 24 * scaleFactor

                            }

                            RowLayout{
                                Layout.preferredWidth: parent.width
                                Layout.preferredHeight: 20 * scaleFactor

                                Item{
                                    Layout.preferredWidth: 10
                                    Layout.fillHeight: true

                                }

                                Label {
                                    id:selectcategory

                                    text: strings.select_category
                                    //leftPadding: 10 * scaleFactor
                                    font.pixelSize: 16 * scaleFactor
                                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                    color: "#6A6A6A"

                                    font.bold:true

                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Rectangle{
                                    Layout.preferredWidth: 20 * scaleFactor
                                    Layout.preferredHeight: 20 * scaleFactor
                                    // color:"red"
                                    Layout.alignment: Qt.AlignVCenter

                                    Controls.Icon {
                                        id: infoBtn
                                        imageWidth: app.units(20)
                                        imageHeight: app.units(20)

                                        maskColor: "#6A6A6A"

                                        imageSource: "../images/info.png"
                                        anchors.centerIn: parent

                                        onClicked: {
                                            infoPopup1.open()

                                        }
                                    }

                                }


                                Item{
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }


                                QtControls.Popup {
                                    id: infoPopup1

                                    property int defaultMargin: units(16)

                                    y: 20 * scaleFactor
                                    x:app.isLeftToRight? 40 * scaleFactor:app.width - infoPopup1.width - 16 * scaleFactor


                                    padding: 0
                                    height: app.units(50)
                                    width:Screen.devicePixelRatio > 1 ? Math.min(300 * scaleFactor,parent.width) : 240 * scaleFactor
                                    LayoutMirroring.enabled: !app.isLeftToRight
                                    LayoutMirroring.childrenInherit: !app.isLeftToRight

                                    visible: false
                                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
                                    Controls.BaseText {
                                        id: message
                                        width:parent.width - 32
                                        anchors.centerIn: parent

                                        color: "#6A6A6A"
                                        text:strings.show_layer_list

                                        maximumLineCount: 2
                                        horizontalAlignment: !app.isLeftToRight ? Text.AlignRight : Text.AlignLeft
                                    }

                                }

                            }

                            Item{
                                Layout.preferredWidth: parent.width
                                Layout.preferredHeight: 4 * scaleFactor

                            }

                            Rectangle{
                                Layout.fillWidth: true

                                Layout.preferredHeight:spatialSearchView.height

                                Rectangle{
                                    id:featurelayerlist1
                                    width:parent.width
                                    height:100
                                    anchors.centerIn: parent
                                    visible:featurelayerlist.visible//_mapView.spatialfeaturesModel.count === 0

                                    Text {
                                        id: featurelayerlist
                                        width:parent.width
                                        height:100
                                        //anchors.centerIn: parent

                                        text:strings.unsupported_layers
                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                        //leftPadding: app.units(16)
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        //Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                                        visible:!spatialSearchView.visible
                                    }
                                }

                                SpatialSearchLegend {
                                    id:spatialSearchView
                                    visible:_mapView ?_mapView.orderedLegendInfos_spatialSearch.count > 0 : false
                                    //visible:_mapView ?_mapView.orderedLegendInfos.count > 0 : false

                                    //model:_mapView ?_mapView.orderedLegendInfos:[] //mapView?mapView.orderedLegendInfos_spatial:[]//mapView.legendInfos
                                    model:_mapView ?_mapView.orderedLegendInfos_spatialSearch:[]

                                    Component.onCompleted: {
                                        spatialSearchManager.addAllLayersToSearch()
                                        spatialSearchManager.saveSearchConfig(currentRadius,measurementUnits)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            function reset(){
                amount.text = currentRadius.toLocaleString(Qt.locale());
                measurementUnits = measurePanel.lengthUnits.miles
                spatialSearchManager.addAllLayersToSearch()
                spatialSearchManager.saveSearchConfig(currentRadius,measurementUnits)

                var isValueChanged = spatialSearchManager.updateOrderedLegendInfos()
                spatialSearchView.resetLegend(isValueChanged)



            }
        }
        /* Connections{
            target:measurePanel
            function onStateChanged()
            {
                if(measurePanel.state === "MEASURE_MODE")
                    spatialsearchPage.height = app.height
                else
                    spatialsearchPage.height = app.height - app.headerHeight
            }
        }*/
        Connections{
            target:mapView
            function onSpatialSearchFinished()
            {
                showResults = true
                var sections = mapView.spatialfeaturesModel.sections
                if(sections.length === 1)
                    resultsListView.expandSection (resultsListView.section.property, sections[0], true)
                else
                {

                    for (var k = 0;k< mapView.spatialfeaturesModel.count;k++)
                    {
                        var item = mapView.spatialfeaturesModel.get(k)

                        if(resultsContent.expandedsections.includes(item.layerNameWithCount))
                        {
                            mapView.spatialfeaturesModel.set(k,{"showInView":true})

                        }
                    }
                }


                /* var sections = mapView.spatialfeaturesModel.sections
                if(sections.length > 1)
                    resultsListView.collapseAllSections()
                if(!spatialSearch.showResults)
                    spatialSearch.showResults = true*/

            }

            function onSpatialSearchModelUpdated()
            {
                spatialSearchManager.addAllLayersToSearch();
                spatialSearchManager.saveSearchConfig(currentRadius,measurementUnits)
                if(_mapView.orderedLegendInfos_spatialSearch.count > 0)
                {
                    spatialSearchView.visible = true
                    featurelayerlist1.visible = false
                }
                else
                {
                    spatialSearchView.visible = false
                    featurelayerlist1.visible = true
                }
            }

            function onLayerLoadingError()
            {
                if(_mapView.orderedLegendInfos_spatialSearch.count > 0)
                {
                    spatialSearchView.visible = true
                    featurelayerlist1.visible = false
                }
                else
                {
                    spatialSearchView.visible = false
                    featurelayerlist1.visible = true
                }
            }


        }



    }


    //show it in a list view with sections . hide/show the elements in a section
    //for count call a function for each section

    Item{
        id:spatialSearchResults
        height:parent.height//app.height - app.headerHeight
        width:parent.width
        visible:showResults
        Controls.BasePage {
            id:resultsContent
            property var expandedsections:[]
            anchors.fill: parent
            //Material.background: app.backgroundColor//"transparent"
            header: Rectangle {
                id: resultsBar

                property real tabBarHeight: 0.8 * app.headerHeight
                property real searchBoxHeight: app.headerHeight
                Material.background: app.primaryColor
                Material.foreground: app.subTitleTextColor
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                height: searchBoxHeight //+ tabBarHeight + app.defaultMargin

                Rectangle {
                    anchors {
                        fill: parent
                        // margins: 0.5 * app.defaultMargin
                    }
                    radius: app.units(2)
                    //color:"red"
                    color: app.backgroundColor

                    ColumnLayout {
                        anchors.fill: parent
                        width: parent.width
                        height: parent.height
                        spacing: 0


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
                                leftPadding: app.units(16)

                                onClicked: {
                                    showResults = false

                                }
                            }

                            //Controls.CustomTextField {
                            Label{
                                id: resultstextField

                                Material.accent: app.baseTextColor
                                Material.foreground: app.subTitleTextColor
                                // Layout.fillHeight: true
                                // Layout.fillWidth: true
                                Layout.alignment:Qt.AlignVCenter
                                Layout.leftMargin: app.baseUnit
                                Layout.rightMargin: app.baseUnit
                                text:qsTr("Results")

                            }
                        }
                    }



                }
            }

            contentItem:Rectangle{
                //anchors.fill:parent
                width:parent.width
                height:resultsContent.height - headerHeight

                Rectangle{
                    width:parent.width
                    height:100
                    anchors.centerIn: parent
                    visible:_mapView.spatialfeaturesModel.count === 0 && _mapView.isSpatialSearchFinished

                    Text {
                        id: nofeatures
                        width:parent.width
                        height:100
                        //anchors.centerIn: parent

                        text:strings.no_results_found
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        //leftPadding: app.units(16)
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        //Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                        visible:_mapView.spatialfeaturesModel.count === 0
                    }
                }


                ListView{
                    id:resultsListView
                    visible:_mapView.spatialfeaturesModel.count > 0
                    clip: true
                    width:parent.width
                    height:parent.height //- headerHeight
                    //anchors.fill:parent
                    property string firstSection: resultsListView.model.count > 0?resultsListView.model.get(0)[sectionPropertyAttr]:""//(count && sectionPropertyAttr > "") ? resultsListView.model.get(0)[sectionPropertyAttr] : ""
                    model:_mapView ?_mapView.spatialfeaturesModel:null


                    function collapseAllSections () {

                        resultsContent.expandedsections.forEach(section =>
                                                                {
                                                                    resultsListView.collapseSection(resultsListView.section.property, section, false)
                                                                    var filtered = resultsContent.expandedsections.filter(item => item !== section)
                                                                    resultsContent.expandedsections = filtered
                                                                })







                    }



                    header:  Rectangle{
                        width:resultsListView.width
                        height:headerHeight

                        RowLayout{
                        LayoutMirroring.enabled: !app.isLeftToRight
                        LayoutMirroring.childrenInherit: !app.isLeftToRight
                          anchors.fill: parent

                            Controls.BaseText {
                                id: resultsLabelField
                                //Layout.preferredWidth: 50
                                text: !app.isLeftToRight ? qsTr("%L1: Total").arg(_mapView.spatialfeaturesModel.count) : qsTr("Total: %L1").arg(_mapView.spatialfeaturesModel.count)
                                maximumLineCount: 1
                                elide: Text.ElideRight
                                leftPadding: app.defaultMargin
                                rightPadding: app.defaultMargin
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignLeft

                            }

                        }

                        Rectangle{
                            width:parent.width
                            height:1
                            color:app.separatorColor
                            anchors.bottom:parent.bottom
                            opacity: 0.5

                        }

                    }

                    delegate: SpatialSearchResultsDelegate
                    {
                        title:search_attr

                        onClicked:{
                            var featureObj = _mapView.spatialfeaturesModel.features[index]
                            identifyManager.populateIdentifyPropertiesForFeature (featureObj,layerName)
                           // mapView.populateIdentifyPropertiesForFeature (featureObj,layerName)

                        }
                        onCurrentIndexChanged:{
                            //checked = index === currentIndex
                        }

                    }
                    section {
                        property: "layerNameWithCount"
                        delegate:Pane {
                            id: sectionDelegate
                            property var isExpanded:false

                            clip: true
                            height:app.units(56) //headerHeight
                            width: parent.width
                            //property var count:getCount(section)
                            z: app.baseUnit
                            Material.background:"white"
                            //Material.background: Qt.darker(app.backgroundColor, 1.1)
                            padding: 0
                            LayoutMirroring.enabled: !app.isLeftToRight
                            LayoutMirroring.childrenInherit: !app.isLeftToRight

                            MouseArea {

                                anchors.fill: parent
                                onClicked: {
                                    sectionDelegate.toggle()
                                }
                            }


                            Rectangle{
                                width: parent.width
                                height: 1
                                color:app.separatorColor
                                anchors.bottom: parent.bottom
                                opacity: 0.5
                            }
                            Rectangle{
                                width: parent.width
                                height: 1
                                color:app.separatorColor
                                anchors.top: parent.top
                                opacity: 0.5
                                visible:resultsListView.firstSection !== section
                            }
                            RowLayout {
                                anchors {
                                    leftMargin: app.baseUnit
                                    rightMargin: app.baseUnit
                                    fill: parent
                                }


                                //Controls.BaseText {
                                Label{
                                    text: section
                                    color: "#6A6A6A"//app.subTitleTextColor
                                    maximumLineCount: 2
                                    elide: Text.ElideMiddle
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth:parent.width  - expandIcon.width //parent.width - countText.width - expandIcon.width
                                    Layout.preferredHeight: parent.height
                                    font.pixelSize: 14 * scaleFactor
                                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")

                                    font.bold: true
                                    leftPadding: app.units(8)
                                    rightPadding: app.units(8)
                                }

                                Controls.Icon {
                                    id: expandIcon

                                    Layout.alignment: Qt.AlignVCenter

                                    maskColor: app.subTitleTextColor
                                    imageSource: "../images/arrowDown.png"

                                    rotation:resultsContent.expandedsections.includes(section)?180:0

                                    onClicked: {

                                        sectionDelegate.toggle()
                                    }
                                }


                            }

                            function toggle () {
                                if(resultsContent.expandedsections.includes(section))
                                {
                                    resultsListView.collapseSection(resultsListView.section.property, section, false)
                                    var filtered = resultsContent.expandedsections.filter(item => item !== section)
                                    resultsContent.expandedsections = filtered
                                }

                                else
                                {

                                    resultsListView.expandSection(resultsListView.section.property, section, true)
                                    resultsContent.expandedsections.push(section)
                                }



                            }


                            Component.onCompleted: {

                                /* if(section === resultsListView.firstSection)
                                    sectionDelegate.toggle()
                                else
                                    resultsListView.collapseAllSections()*/

                            }

                        }
                    }
                    Component.onCompleted: {

                    }

                    function expandSection (sectionProperty, section, expand) {
                        resultsContent.expandedsections.push(section)
                        for (var i=0; i<resultsListView.model.count; i++) {
                            var item = resultsListView.model.get(i)
                            if (item[sectionProperty] === section) {

                                item["showInView"] = expand
                            }
                        }
                    }

                    function collapseSection (sectionProperty, section, expand) {
                        for (var i=0; i<resultsListView.model.count; i++) {
                            var item = resultsListView.model.get(i)
                            if (item[sectionProperty] === section) {
                                item["showInView"] = expand
                            }
                        }
                    }




                }


            }



        }






        Component.onCompleted: {
            resultsListView.collapseAllSections()

            // resultsListView.expandSection(resultsListView.section.property, section, true)
        }


    }

    onShowResultsChanged:{
        /* if(showResults)
        {
        }*/
    }




    Component.onCompleted:{
        spatialSearchManager._mapView = _mapView
        if(!app.isLandscape)
        {
            spatialSearch.height = app.height * 0.50
            spatialsearchPage.height = app.height * 0.505
        }
        else
        {
            spatialSearch.height = app.height - app.headerHeight
            spatialsearchPage.height = app.height - app.headerHeight
        }

    }

}
