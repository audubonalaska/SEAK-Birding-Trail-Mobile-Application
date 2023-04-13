import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0

import QtQuick.Controls.Material 2.2

import ArcGIS.AppFramework 1.0

import "../controls"

Pane {
    id: sketchPanel
    property real value: 0
    property real iconSize: app.iconSize
    property real defaultMargin: app.defaultMargin/2
    property real defaultHeight: 3*app.defaultMargin //+ app.heightOffset
    property var colorObject: {"colorName": "#FF0000", "alpha": "#59FF0000"}
    property bool isIdentifyMode: false
    property bool showSegmentLength: true
    property bool showFillColor: true
    property bool screenWidth:app.isLandscape
    property var selectedColor:colorObject.colorName
    property var selectedColorIndex:0

    onScreenWidthChanged: {
        if(!app.isLandscape)
        {
            if(!app.isPhone)
            {
            screenSizeState.state = "SMALL"
            tooldetailscol.updateIndex(selectedColorIndex)
            }
            else
            {
                screenSizeState.state = "PHONE"
                tooldetailscol.updateIndex(selectedColorIndex)
            }
        }
        else
        {
            screenSizeState.state = "LARGE"
            tooldetailsrow.updateIndex(selectedColorIndex)

        }
    }

    Item {
        id: screenSizeState

        states: [
            State {
                name: "LARGE"
                when: !app.isCompact

                PropertyChanges {
                    target: sketchPanel
                    //width:Math.min(app.units(568), app.width - 0.20 * app.width)
                    width:Math.min(app.units(568), app.width - panelWidth)

                }
                PropertyChanges{
                    target:tabcol
                    width:parent.width/2
                }
                PropertyChanges{
                    target:separator
                    visible:false

                }
                PropertyChanges{
                    target:tooldetailsrow
                    visible:true
                    width:app.units(200)
                }
                PropertyChanges{
                    target:tooldetailscol
                    visible:false

                }
                PropertyChanges{
                    target:tabBarScreen
                    width:app.units(250)
                }
                PropertyChanges{
                    target:horizontalseparator
                    visible:true

                }
                PropertyChanges{
                    target:settingsIcon
                    Layout.rightMargin: app.defaultMargin

                }


            },
            State {
                name: "SMALL"
                when: app.isCompact && !app.isPhone

                PropertyChanges {
                    target: sketchPanel
                    width:app.width - panelWidth//0.20 * app.width
                    height:defaultHeight * 2
                }
                PropertyChanges{
                    target:separator
                    visible:true
                    width:tabcol.width
                }
                PropertyChanges{
                    target:horizontalseparator
                    visible:false

                }
                PropertyChanges{
                    target:tooldetailscol
                    visible:true
                    width:tabcol.width
                }
                PropertyChanges{
                    target:tooldetailsrow
                    visible:false
                    //width:tabcol.width
                }


                PropertyChanges{
                    target:settingsIcon
                    Layout.rightMargin: 2 * app.defaultMargin
                    //anchors.rightMargin: 2 * app.defaultMargin
                }

                PropertyChanges{
                    target:tabcol
                    width:parent.width - defaultMargin - settingsIcon.width - panelWidth//0.20 * parent.width
                }

                PropertyChanges{
                    target:tabBarScreen
                    width:(app.width - app.defaultMargin)/5 * 4
                }

            },
            State {
                name: "PHONE"
                when: app.isPhone

                PropertyChanges {
                    target: sketchPanel
                    width:app.width //- 0.20 * app.width
                    height:defaultHeight * 2 + (app.isNotchAvailable() && app.isPortrait?app.units(20):0)
                }
                PropertyChanges{
                    target:separator
                    visible:true
                    width:tabcol.width
                }
                PropertyChanges{
                    target:horizontalseparator
                    visible:false

                }
                PropertyChanges{
                    target:tooldetailscol
                    visible:true
                    width:tabcol.width
                }
                PropertyChanges{
                    target:tooldetailsrow
                    visible:false
                    //width:tabcol.width
                }


                PropertyChanges{
                    target:settingsIcon
                    Layout.rightMargin: 2 * app.defaultMargin
                    //anchors.rightMargin: 2 * app.defaultMargin
                }

                PropertyChanges{
                    target:tabcol
                    width:parent.width  - settingsIcon.width //- 0.20 * parent.width
                }

                PropertyChanges{
                    target:tabBarScreen
                    width:app.width/5 * 4//(app.width - app.defaultMargin)/5 * 4
                }

            }


        ]


    }

    onVisibleChanged: {
        if (visible) {
            isIdentifyMode = false
        }
    }

    visible: height > 0
    padding: 0
    //bottomPadding: app.heightOffset
    width: app.isCompact?app.width:Math.min(app.units(568), app.width - panelWidth)//0.20 * app.width)
    height: defaultHeight + (app.isNotchAvailable() ? app.units(20):0)
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: viewerPanel.horizontalCenter
    //anchors.horizontalCenter: parent.horizontalCenter
    Behavior on height {
        NumberAnimation {
            duration: 100
        }
    }

    background: Rectangle{
        anchors.fill:parent
        color:"white"
    }

    ColumnLayout{
        id:tabcol
        width:app.isLarge?Math.min(app.units(568), app.width - panelWidth):(app.isPhone?app.width:app.width - panelWidth)
        anchors{
            bottom:parent.bottom
            //horizontalCenter: parent.horizontalCenter
            leftMargin: 0

        }
        spacing:0


        SketchDetails{
            id:tooldetailscol
            Layout.preferredHeight: app.units(50)
            Layout.preferredWidth: app.units(250)

            Layout.alignment: Qt.AlignHCenter
            //visible:app.isCompact
        }
        Rectangle{
            id:separator
            Layout.preferredWidth:app.isLarge?tabcol.width:(app.isPhone?app.width:app.width - panelWidth)
            Layout.preferredHeight:1
            visible:app.isCompact
            color:app.separatorColor
        }
        Rectangle
        {
            id:separator2
            Layout.preferredWidth:app.isLarge?parent.width/2:(app.isPhone?app.width:app.width - panelWidth)
            Layout.preferredHeight:defaultHeight
            //visible:app.isCompact
            //color:"green"

            RowLayout {
                spacing: app.units(16)
                anchors.fill:parent

                TabBar {
                    id:tabBarScreen
                    Layout.preferredWidth:app.isLarge?app.units(250):(app.isPhone?(app.width - app.defaultMargin)/5 * 4:(app.width - app.defaultMargin - panelWidth)/5 * 4)
                    Layout.preferredHeight: parent.height
                    bottomPadding: 0
                    Material.background: "white"//"#424242"
                    Material.accent: app.subTitleTextColor
                    spacing: app.units(24)
                    leftPadding: 0
                    CustomizedTabButton{
                        id: drawLineBtn
                        height:parent.height
                        imageSource: "../images/curve_3.png"
                        highlighted: false

                        onClicked: {
                            canvas.lineMode = true;
                            canvas.arrowMode = false;
                            canvas.penWidth = canvas.selectedLinePenWidth
                        }
                    }

                    CustomizedTabButton{
                        id: drawArrowBtn
                        height: parent.height
                        //width:(app.width - app.defaultMargin - 0.25 * app.width)/6
                        property bool isSmartBefore: false
                        imageSource: "../images/arrow_1.png"
                        highlighted: false
                        onCheckedChanged: {
                            if(!checked) {
                                canvas.smartMode = isSmartBefore;
                            }
                        }

                        onClicked: {
                            isSmartBefore = canvas.smartMode;
                            canvas.smartMode = false;
                            canvas.lineMode = true;
                            canvas.arrowMode = true;
                            canvas.penWidth = canvas.selectedArrowPenWidth
                            if(canvas.selectedArrowPenWidth === 3 || canvas.selectedArrowPenWidth === 5)
                                canvas.textMode = false
                            else
                                canvas.textMode = true

                        }
                    }

                    CustomizedTabButton{
                        id: addTextBtn
                        height: parent.height
                        //width:(app.width - app.defaultMargin - 0.25 * app.width)/6
                        imageSource: "../images/ic_title_white_48dp.png"
                        highlighted: false
                        onClicked: {
                            canvas.lineMode = false;
                            canvas.arrowMode = false;
                            canvas.textMode = true
                        }
                    }

                    CustomizedRoundedTabButton{
                        id:addColorBtn
                        height: parent.height
                        highlighted: false
                        selectedColor: colorObject.colorName
                    }

                }
                Rectangle{
                    id:horizontalseparator
                    Layout.preferredWidth: 2
                    Layout.preferredHeight: parent.height - 2 * app.defaultMargin
                    color:app.subTitleTextColor
                    visible:!app.isCompact
                }
                SketchDetails{
                    id:tooldetailsrow
                    Layout.preferredHeight:defaultHeight
                    Layout.preferredWidth: app.units(200)
                    visible:!app.isCompact
                }


                Rectangle{
                    id:settingsIcon
                    Layout.fillHeight: true
                    Layout.preferredWidth:app.units(50)
                    color:"white"

                        Icon {
                            imageSource: "../images/settings.png"
                            maskColor: app.subTitleTextColor//app.darkIconMask

                            onClicked: {
                                settingsContent.y = -app.units(120)
                                settingsContent.open()
                            }
                        }
                }

            }

        }
        Rectangle
        {
         Layout.preferredWidth:app.isLarge?tabcol.width:(app.isPhone?app.width:app.width - panelWidth)
         Layout.preferredHeight:app.isNotchAvailable() ? app.units(20):0

        }

    }


    Menu {
        id: settingsContent
        property real menuItemHeight: app.units(48)
        property real colorPaletteHeight: 1.4 * menuItemHeight
        modal: true
        width:app.units(300) * app.fontScale
        height:contentCol.height + defaultMargin
        x: parent.width-settingsContent.width-2*defaultMargin
        padding: 0
        bottomMargin: 2*defaultMargin
        topMargin: 0
        topPadding: 0

        property alias listView: listView

        contentItem: Item {
            id: listView
            anchors.fill: parent

            LayoutMirroring.enabled: !app.isLeftToRight
            LayoutMirroring.childrenInherit: !app.isLeftToRight
            ColumnLayout{
                id:contentCol
                width:app.units(300) * app.fontScale
                spacing:0

                ToolBar {
                    z: 8
                    Layout.preferredWidth: parent.width
                    //width: parent.width
                    Layout.preferredHeight: settingsContent.menuItemHeight
                    Material.background: app.backgroundColor
                    Material.elevation: 1
                    padding: 0

                    BaseText {
                        text: app.drawing_settings
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                        leftPadding: app.isLeftToRight ? app.defaultMargin : 0
                        rightPadding: app.isLeftToRight ? 0 : app.defaultMargin
                    }
                }


                Item {
                    Layout.preferredWidth:app.units(300) * app.fontScale
                    Layout.preferredHeight: settingsContent.menuItemHeight
                    Material.background: "transparent"

                    RowLayout {
                        id: smartDrawSwitch
                        anchors.fill: parent
                        anchors.left: parent.left
                        anchors.leftMargin: app.defaultMargin - app.units(5)
                        anchors.rightMargin: app.defaultMargin

                        BaseText {
                            text: app.smart_draw_caps
                            Layout.fillHeight: true
                            Layout.preferredWidth: parent.width - drawSwitch.width
                            Layout.alignment: Qt.AlignVCenter
                            verticalAlignment: Text.AlignVCenter
                            maximumLineCount: 1
                            horizontalAlignment: Text.AlignLeft
                            elide: Text.ElideRight
                        }

                        Switch {
                            id: drawSwitch
                            padding: 0
                            Layout.preferredHeight: app.iconSize
                            Layout.preferredWidth: app.iconSize
                            Layout.alignment: Qt.AlignVCenter
                            Material.primary: app.primaryColor
                            Material.accent: app.accentColor

                            onCheckedChanged: {
                                canvas.smartMode = checked;

                            }
                        }
                    }

                }
                BaseText {
                    id: label
                    fontsize:app.textFontSize
                    color:app.subTitleTextColor

                    Layout.preferredWidth: parent.width - app.baseUnit

                    maximumLineCount: 3
                    elide: Text.ElideRight
                    text:app.smart_draw_string
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    leftPadding: app.isLeftToRight ? app.defaultMargin : 0
                    rightPadding: app.isLeftToRight ? 0 : app.defaultMargin
                    bottomPadding: app.defaultMargin
                }


            }

        }
    }

    function removeMenuItem (name) {
        for (var i=0; i<itemsListModel.count; i++) {
            if (itemsListModel.get(i).name === name) {
                itemsListModel.remove(i)
                break
            }
        }
    }

    function insertMenuItem (index, name, control, isChecked) {
        if (!isChecked) isChecked = false
        var hasItem = false
        for (var i=0; i<itemsListModel.count; i++) {
            if (itemsListModel.get(i).name === name) {
                hasItem = true
                break
            }
        }
        if (!hasItem) {
            itemsListModel.insert(index,
                                  {"name": name, "control": control, "isChecked": isChecked})
        }
    }




    function copyToClipBoard (text) {
        AppFramework.clipboard.copy(text)
        settingsContent.close()
        //copiedToClipboard(text)
    }


}

