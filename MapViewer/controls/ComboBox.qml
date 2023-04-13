import QtQuick 2.7
import QtSensors 5.3
import QtPositioning 5.3
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import Esri.ArcGISRuntime 100.14

import ArcGIS.AppFramework 1.0

import "../controls" as Controls

Rectangle {
    id: root
    //color:"red"

    Layout.fillHeight: true
    Layout.preferredWidth: defaultWidth
    Layout.maximumWidth: defaultWidth
    property real menuLeftMargin: 2*root.defaultMargin + (app.width - measurePanel.width)/2
    property real menuBottomMargin:2*root.defaultMargin
    property real scale: app.fontScale
    property real iconSize: app.iconSize
    property real maxLabelWidth: app.units(120)
    property real maxMenuWidth: maxLabelWidth
    property real menuItemHeight: app.units(34)
    property real defaultWidth: Math.min(label.contentWidth, maxLabelWidth) + dropdown.width + content.spacing
    // property real defaultWidth: Math.min(label.contentWidth, maxLabelWidth) + dropdown.width + content.spacing
    property real defaultMargin: app.defaultMargin/2
    property int pointSize: app.baseFontSize
    property int selectedIndex:0
    property ListModel model: ListModel {}

    signal labelChanged (string label)

    property bool showBorder: false
    property alias menu: menu
    property alias listView: listView
    property alias dropdown: dropdown
    // property alias label: label


    border.width: app.units(1)
    border.color: showBorder ? Qt.darker(app.backgroundColor, 1.05) : "transparent"

    Menu {
        id: menu

        width: listView.width//root.maxMenuWidth
        //width:listView.width
        height: padding + model.count * (listView.spacing + menuItemHeight)
        padding: root.defaultMargin
        leftPadding: 0
        rightPadding: 0
        bottomMargin: menuBottomMargin//2*root.defaultMargin
        leftMargin: root.menuLeftMargin

        property alias listView: listView

        contentItem: ListView {
            id: listView
            clip: true
            width: contentItem.childrenRect.width
            spacing: app.units(4)
            currentIndex: selectedIndex
            delegate: BaseText {
                property color backgroundColor: "#FFFFFF"
                height: menuItemHeight
                width:implicitWidth
                //width: parent?parent.width:0
                padding: root.defaultMargin
                leftPadding: 2 * root.defaultMargin
                rightPadding: 2 * root.defaultMargin
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 1
                font.pointSize: root.pointSize
                text: typeof itemLabel !== "undefined" ? itemLabel : ""
                background: Rectangle {
                    width:listView.width
                    color: text !== label.text ?  backgroundColor : colors.blk_020//index !== selectedIndex ? backgroundColor : colors.blk_020
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        listView.currentIndex = index
                        menu.close()
                    }

                    onEntered: {
                        backgroundColor = Qt.darker(app.backgroundColor, 1.1)
                    }

                    onExited: {
                        backgroundColor = "#FFFFFF"
                    }
                }
            }
            model: root.model

            onCountChanged: {
                updateLabel ()
            }

            onCurrentIndexChanged: {
                updateLabel()
            }
        }
    }

    RowLayout {
        id: content

        anchors.fill: parent
        spacing: 0

        Controls.BaseText {

            id: label

            padding: 0
            leftPadding: 0//app.baseUnit
            elide: Text.ElideRight
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 1
            verticalAlignment: Text.AlignVCenter
            font.pointSize:14 //root.pointSize
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            Layout.alignment: Qt.AlignRight
            Layout.fillHeight: true
            //Layout.maximumWidth: root.maxLabelWidth
            horizontalAlignment: Text.AlignRight
            rightPadding: 0

            /*onTextChanged: {
                labelChanged(text)
            }*/

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    menu.open()
                }
            }
        }

        Controls.Icon {
            id: dropdown

            iconSize:root.iconSize
            Layout.rightMargin: 2 * root.defaultMargin
            Layout.topMargin: 0
            imageSource:"../images/caret-down.svg"//carot_600_48dp.png" //"../controls/images/arrowDown.png"//"../images/caret-down.svg"
            maskColor: app.darkIconMask
            Layout.alignment: Qt.AlignRight
            onClicked: menu.open()
            visible:label.text > ""
            width:visible ? implicitWidth :0
            Layout.leftMargin: 0

        }

        Item{
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    Component.onCompleted: {
        updateLabel()
    }

    function updateLabel (value) {
        if (listView.currentIndex >= 0 && (value > 0 || typeof value === "undefined")) {
            var currentItem = root.model.get(listView.currentIndex)
            if (currentItem && typeof currentItem.itemLabel !== "undefined")
                label.text = currentItem.itemLabel
        }
        else
            label.text  = ""
    }
}
