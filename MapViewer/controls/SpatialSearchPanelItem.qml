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

 * This file is modified in version 4.1 to show the sublayers if it is a group layer
 */

import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0

Pane {
    id: root

    property color imageColor: "transparent"
    property bool clickable: false
    property bool isChecked: false
    property bool showRightButton: false
    property string txt: ""
    property string rightButtonImage: "images/arrowDown.png"
    property url imageSource: ""
    property alias rightButton: rightButton

    property color primaryColor: "steelBlue"
    property color accentColor: Qt.lighter(app.primaryColor)
    property real iconSize: root.units(48)
    property real defaultMargin: root.units(16)

    signal checked (bool checked)
    signal rightButtonClicked ()
    signal clicked ()


    height:  root.units(56)
    width: parent.width
    padding: 0


    contentItem: Rectangle{
        //color:"black"
        height:40
        width:parent.width


        RowLayout {
            id:legrow
            // LayoutMirroring.enabled: !app.isLeftToRight
            // LayoutMirroring.childrenInherit: !app.isLeftToRight

            anchors {
                fill: parent
                leftMargin: 0 //root.defaultMargin
                rightMargin: 0.5 * root.defaultMargin
            }
            Item{
                Layout.preferredWidth: 6
                Layout.fillHeight: true
                visible:!chkBox.visible


            }

            CheckBox {
                id: chkBox

                checked:isChecked
                //ButtonGroup.group:childGroup
                checkState:isChecked?Qt.Checked:Qt.Unchecked

                visible:(txt.trim()).length > 0 //typeof checkBox !== "undefined"
                Material.accent: app.accentColor//"red"//root.accentColor
                Material.primary: app.primaryColor//"black" //root.primaryColor
                Layout.alignment: Qt.AlignLeft
                Material.theme:Material.Light
                //Material.accent: root1.accentColor


                onClicked: {
                    root.checked(checked)
                    itemClicked = ""
                }
                Connections{
                    target:spatialsearchView
                    function onResetLegend(isValueChanged)
                    {
                        if(!(chkBox.checkState === Qt.Checked))
                        {
                            chkBox.checkState = Qt.Checked

                        }

                        valueChanged = true
                    }
                }

            }
            Rectangle {
                color: "transparent"
                visible: imageSource.toString().length > 0 && showInLegend
                Layout.preferredHeight: Math.min(parent.height, 0.6 * root.iconSize)
                Layout.preferredWidth: 0.6 * root.iconSize
                Layout.alignment: Qt.AlignVCenter
                Layout.margins: 0

                Image {
                    id: img

                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: imageSource
                }

                ColorOverlay{
                    anchors.fill: img
                    source: img
                    color: root.imageColor
                }
            }



            BaseText {
                id: lbl

                objectName: "label"
                visible: txt.length > 0
                text: txt
                Layout.preferredWidth: root.computeTextWidth(parent.width, parent) - 70 * AppFramework.displayScaleFactor
                Layout.preferredHeight: contentHeight
                elide: Text.ElideMiddle
                wrapMode: Text.NoWrap
                horizontalAlignment: Label.AlignLeft
                color:"#6A6A6A"
                fontsize: 12 * scaleFactor
                //clip: true
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // if (chkBox.visible) {
                        // chkBox.checked = !chkBox.checked
                        // }
                    }
                }
            }

            SpaceFiller {
                objectName: "spaceFiller"
                //visible: img.visible || chkBox.visible || lbl.visible
            }

            Icon {
                id: rightButton

                objectName: "rightButton"
                visible: root.showRightButton
                maskColor: root.primaryColor
                imageSource: root.rightButtonImage
                Layout.alignment: Qt.AlignRight

                onClicked: {
                    root.rightButtonClicked()
                }
            }

        }

        Ink {
            objectName: "ink"
            visible: root.clickable
            anchors.fill: parent

            onClicked: {
                root.clicked()
            }
        }
    }
    function computeTextWidth (maxWidth, parentItem) {
        var textWidth = maxWidth,
        ommit = ["label", "spaceFiller", "ink"]
        for (var i=0; i<parentItem.children.length; i++) {
            if (ommit.indexOf(parentItem.children[i].objectName) === -1 && parentItem.children[i].visible) {
                textWidth -= parentItem.children[i].width
            }
        }
        return textWidth - root.defaultMargin
    }


    function units (num) {
        return num ? num * AppFramework.displayScaleFactor : num
    }

}

