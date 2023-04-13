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
    id: root1

    property color imageColor: "transparent"
    property bool clickable: false
    property bool isChecked: false
    property bool showRightButton: false
    property string txt: ""
    property bool isVisible:true
    property string rightButtonImage: "images/arrowDown.png"
    property url imageSource: ""
    property ListModel subLayersList
    readonly property color maskColor: "transparent"

    property alias rightButton: rightButton

    property color primaryColor: "steelBlue"
    property color accentColor: Qt.lighter(primaryColor)
    property real iconSize: root1.units(48)
    property real defaultMargin: root1.units(50)
    //Material.background: root.headerBackgroundColor

     signal checked (bool checked,string sublyr,string identificationIndex)
    signal rightButtonClicked ()
    signal clicked ()

   height: subLayersList && subLayersList.count > 0 ? contentCol.height : app.units(56)//subLayersList && subLayersList.count > 0? app.units(56) + subLayersList.count * 0.75 * root1.iconSize:app.units(56)

    width: parent ? parent.width : 0
    padding: 0

    contentItem: Item{

       ColumnLayout{
       id:contentCol
       spacing:0

        RowLayout {
            id:legrow
            Layout.preferredHeight: 0.7 * root1.iconSize


            Rectangle {
                color:"transparent"
                visible: imageSource.toString().length > 0
                Layout.preferredHeight: parent.height
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
                    color: root1.imageColor
                }
            }
            CheckBox{
                id: chkBox
                checked: isChecked
                visible: typeof checkBox !== "undefined"
                Material.theme:Material.Light
                Material.accent: root1.accentColor
                Layout.alignment: Qt.AlignLeft
                onClicked: {

                    root1.checked(checked,null,"0")
                }
            }






            Label{
                id: root3
                property string fontNameFallbacks: "Helvetica,Avenir"
                property string baseFontFamily: root3.getAppProperty (app.baseFontFamily, fontNameFallbacks)
                property string titleFontFamily: root3.getAppProperty (app.titleFontFamily, "")
                property string accentColor: root3.getAppProperty(app.accentColor)

                color: isVisible?root3.getAppProperty (app.baseTextColor, Qt.darker("#F7F8F8")):"#D3D3D3"
                font {
                    pointSize: root3.getAppProperty (app.baseFontSize, 14)
                    family: "%1,%2".arg(baseFontFamily).arg(fontNameFallbacks)
                }
                text: txt
                Layout.preferredHeight: contentHeight
                Layout.preferredWidth: root1.computeTextWidth()
                elide: Label.ElideMiddle
                horizontalAlignment: Label.AlignLeft
               // Material.accent: accentColor
                wrapMode: Text.WordWrap
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (chkBox.visible) {
                            chkBox.checked = !chkBox.checked
                            root1.checked(chkBox.checked)
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

            }



            SpaceFiller {
                objectName: "spaceFiller"

            }

            Icon {
                id: rightButton

                objectName: "rightButton"
                visible: root1.showRightButton
                maskColor: root1.primaryColor
                imageSource: root1.rightButtonImage
                Layout.alignment: Qt.AlignRight

                onClicked: {
                    root1.rightButtonClicked()
                }
            }


        }

        Repeater{

            model:subLayersList
            RowLayout{
            id:sublyr
            Layout.preferredHeight: 0.7 * root1.iconSize
            spacing:0

                Item{
                    width:1.0 * root1.iconSize
                    height: 0.6 * root1.iconSize

                }

                CheckBox{
                        id: chkBox1
                        checked:checkbox
                        visible: layerType !== 4
                        Material.theme:Material.Light
                        Material.accent: root1.accentColor
                        Layout.alignment: Qt.AlignLeft
                        onClicked: {

                            var sublyr = layerName
                            var lyr = txt

                             root1.checked(checked,sublyr,identificationIndex)
                        }
                    }

                 Item{
                     Layout.preferredWidth:!chkBox1.visible?app.fontScale * 0.3 * app.iconSize:0
                     Layout.preferredHeight: !chkBox1.visible?app.fontScale * 0.3 * app.iconSize:0
                        Image {
                            id: layerimage
                            sourceSize.width: app.fontScale * 0.3 * app.iconSize
                            sourceSize.height: app.fontScale * 0.3 * app.iconSize
                            source: "images/layer.png"
                            asynchronous: true
                            smooth: true
                            fillMode: Image.PreserveAspectCrop
                            mipmap:true
                            visible: !chkBox1.visible


                        }

                        ColorOverlay{

                            Layout.fillHeight: true
                            source: layerimage
                            color: maskColor
                            visible: !chkBox1.visible

                        }

                    }


               /* Item{
                    width:0.4 * root1.iconSize
                    height: 0.5 * root1.iconSize
                }*/

                BaseText {
                    id: lbl

                    objectName: "label"
                    visible: layerName.length > 0
                    text: layerName
                    Layout.preferredWidth: root1.computeTextWidth() - 80 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: contentHeight
                    elide: Text.ElideMiddle
                    wrapMode: Text.NoWrap
                    color:isSubLyrVisible?root3.getAppProperty (app.baseTextColor, Qt.darker("#F7F8F8")):"#D3D3D3"
                    horizontalAlignment: Label.AlignLeft

                }
            }
        }
        }


        Ink {
            objectName: "ink"
            visible: root1.clickable
            anchors.fill: parent

            onClicked: {
                root1.clicked()
            }
        }
    }
    function computeTextWidth () {
        var textWidth = root1.width
        return textWidth - root1.defaultMargin
    }

    function units (num) {
        return num ? num * AppFramework.displayScaleFactor : num
    }
}



