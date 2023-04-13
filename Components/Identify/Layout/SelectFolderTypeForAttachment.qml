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
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Notifications 1.0


import "../../../MapViewer/controls"  as Controls

//import "../widgets" as Widgets

Controls.PopupPage {

    id: selectFolderTypeForAttachment
    // width:parent.width - 64
    height:app.units(197)
    property real panelHeaderHeight:app.units(50)
    anchors.centerIn: parent
    bottomMargin:16

    modal: true

    property bool screenWidth:app.isLandscape
    property string attachmentFolder:"photos"
    signal selectFiles(var folderType)


    contentItem: Controls.BasePage{

        ColumnLayout{
            width:parent.width
            spacing:0

            Rectangle {
                id: header
                Layout.preferredHeight: panelHeaderHeight
                Layout.fillWidth:true
                Material.background: "white"

                // LayoutMirroring.enabled:isRightToLeft
                // LayoutMirroring.childrenInherit: isRightToLeft

                RowLayout {
                    anchors.fill: parent
                    Item{
                        Layout.preferredWidth: 24
                        Layout.fillHeight: true
                    }

                    Text {
                        id: headerText

                        // Layout.fillWidth: true

                        font.pixelSize: fontScale * 18
                        font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                        color: colors.blk_200
                        text:strings.add_attachment
                        verticalAlignment: Text.AlignVCenter
                        //elide: Text.ElideRight
                        wrapMode:Text.WordWrap
                        maximumLineCount: 2
                        font.bold: true

                        horizontalAlignment: Label.AlignLeft

                        Layout.alignment: Qt.AlignLeft

                    }


                    Controls.SpaceFiller {
                        Layout.fillWidth: true
                    }


                }

            }

            Rectangle{
                Layout.fillWidth:true
                Layout.preferredHeight: 1
                color:app.separatorColor


            }

            Rectangle{

                Layout.fillWidth:true
                //width:parent.width
                Layout.preferredHeight:95//folderOptions.height//parent.height - header.height
                //Material.elevation: 1
                color:"white"
                ButtonGroup { id: radioGroup }


                ColumnLayout{
                    id:folderOptions
                    width:parent.width
                    height:90
                    spacing:0
                    anchors.centerIn: parent


                    RowLayout{
                        Layout.preferredHeight:app.units(45)
                        spacing:0
                        Item{
                            Layout.preferredWidth: 24
                            Layout.fillHeight: true
                        }



                        Item {
                            Layout.preferredHeight: app.units(45)
                            Layout.preferredWidth: app.iconSize

                            RadioButton {
                                id: radioButtonPhotos

                                anchors.centerIn: parent
                                checkable: true
                                checked: true
                                Material.primary: app.primaryColor
                                Material.accent: app.accentColor
                                Material.theme:Material.Light
                                ButtonGroup.group: radioGroup
                                onClicked: {
                                    attachmentFolder = "photos"
                                }
                            }
                        }

                        Text {

                            text:strings.photos
                            maximumLineCount: 1
                            //elide:Text.ElideMiddle
                            //fontSizeMode: Text.Fit

                            font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                            font.pixelSize: 16 * fontScale

                            color: titleColor
                            Layout.alignment: Qt.AlignLeft
                            verticalAlignment: Qt.AlignVCenter
                            //Layout.leftMargin: !app.isRightToLeft ?  app.units(16) : 0
                            //Layout.rightMargin: !app.isRightToLeft ?  0 : app.units(16)
                            horizontalAlignment: !app.isRightToLeft ? Text.AlignLeft : Text.AlignRight

                        }
                    }

                    RowLayout{
                        Layout.preferredHeight:app.units(45)
                        spacing:0
                        Item{
                            Layout.preferredWidth: app.units(24)
                            Layout.fillHeight: true
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.preferredWidth: app.iconSize

                            RadioButton {
                                id: radioButtonFile

                                anchors.centerIn: parent
                                checkable: true

                                Material.primary: app.primaryColor
                                Material.accent: app.accentColor
                                Material.theme:Material.Light
                                ButtonGroup.group: radioGroup
                                onClicked: {
                                    attachmentFolder = "files"
                                }
                            }
                        }

                        Text {

                            text:strings.files
                            maximumLineCount: 1
                            elide:Text.ElideMiddle
                            // fontSizeMode: Text.Fit
                            font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                            font.pixelSize: 16 * fontScale

                           // font.pixelSize:fontScale * 14//app.baseFontSize
                           // font.family: app.baseFontFamily
                            color: titleColor

                            Layout.alignment: Qt.AlignLeft
                            verticalAlignment: Qt.AlignVCenter
                            //Layout.leftMargin: !app.isRightToLeft ?  app.units(16) : 0
                            //Layout.rightMargin: !app.isRightToLeft ?  0 : app.units(16)
                            horizontalAlignment: !app.isRightToLeft ? Text.AlignLeft : Text.AlignRight

                        }
                    }



                }



            }



            Rectangle{
                Layout.fillWidth:true
                Layout.preferredHeight: 1
                color:app.separatorColor


            }

            Rectangle {
                Layout.preferredHeight: panelHeaderHeight
                Layout.fillWidth:true

                Material.background:"white"

                RowLayout{
                    width:parent.width
                    height:parent.height
                    Controls.SpaceFiller {
                        Layout.fillWidth: true
                    }

                    Rectangle{
                        id:_cancel
                        Layout.preferredWidth:cancelTxt.width + 20
                        Layout.preferredHeight:app.units(28)

                        border.color:"transparent"
                        color:"transparent"

                        Text {
                            id:cancelTxt
                            text: strings.cancel
                            anchors.left:parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                            font.pixelSize: 16 * app.scaleFactor
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: app.primaryColor
                            //color: pressed ? Qt.lighter(app.primaryColor) : app.primaryColor

                        }

                        MouseArea{
                            anchors.fill:_cancel
                            onClicked:{
                             if (HapticFeedback.supported === true) { HapticFeedback.send(1)}
                                selectFolderTypeForAttachment.close()
                            }

                        }


                    }

                    Item{
                        id:_apply
                        Layout.preferredWidth:applyTxt.width + 20
                        Layout.preferredHeight:app.units(28)

                        Text {
                            id:applyTxt
                            text:  strings.next
                            anchors.right:parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                            font.pixelSize: 16 * app.scaleFactor
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: app.primaryColor
                        }
                        MouseArea{
                            anchors.fill:_apply

                            onClicked:{

                               if (HapticFeedback.supported === true) { HapticFeedback.send(1)}

                                selectFiles(attachmentFolder)
                            }

                        }



                    }

                    Item{
                        Layout.preferredWidth:32
                        Layout.fillHeight: true
                    }

                }

            }
        }

    }





}
