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


import "../controls" as Controls

import "../widgets" as Widgets

Controls.PopupPage {

    id: editAttributePage
    width:panelPage.width
    height:panelPage.height
    y:pageView.state === "anchorbottom"?app.headerHeight + pageView.height * 0.6:0
    property var editObject:null
    property bool isShowTextArea: false
    property bool isRangeValidated:true
    property bool isInputValidated:true
    property bool canResetValidator:true
    property bool hasEdits:false
    Material.elevation: 0

    signal updateAttribute(var editObject)


    onOpened:{
        loader.sourceComponent = (function(){
        busyIndicator.visible = false
            if(editObject && editObject.domainName.count === 0)
            {
                isInputValidated = true

                canResetValidator = true
                return editControl
            }
            else
                return cvdControl

        })()

    }

    onClosed: {
        loader.sourceComponent = undefined
        panelPage.action = ""

    }
     onVisibleChanged: {
       // app.forceActiveFocus()
        app.focus = true
    }

    function updateModel()
    {
        //update attrListModel using set property

        featuresView.updateModel1(editObject)

    }

    contentItem: Controls.BasePage{

        header: ToolBar {
            id: header
            height:panelPage.panelHeaderHeight
            width: parent.width
            Material.background: "#F4F4F4"
            Material.elevation: 0
            LayoutMirroring.enabled: !isLeftToRight
            LayoutMirroring.childrenInherit: !isLeftToRight

            RowLayout {
                anchors.fill: parent

                ToolButton {
                    id: cancelBtn
                    visible:true
                    width:parent.width/2 - app.units(32)
                    height:app.units(56)
                    Layout.leftMargin: app.units(14)
                    Material.foreground:getAppProperty(app.subTitleTextColor, Qt.darker("#F7F8F8", 1.5))
                    text:strings.cancel //qsTr("Cancel")
                    font.pixelSize:app.baseFontSize
                    font.family: app.baseFontFamily

                    background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                    }

                    onClicked: {
                        editAttributePage.close()

                    }
                }



                Controls.SpaceFiller {
                    Layout.fillWidth: true
                }

                ToolButton {
                    id: saveBtn
                    visible:true//isInEditMode
                    width:parent.width/2 - app.units(32)
                    height:app.units(56)
                    Layout.rightMargin: app.units(10)

                    Material.foreground:app.primaryColor
                    text:strings.save
                    font.pixelSize:app.baseFontSize
                    font.bold: hasEdits?true:false
                    //font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    enabled: isInputValidated

                    background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                    }

                    onClicked: {
                        //mapPage.saveBusyIndicator.visible = true
                        exitEditModeInProgress = true
                        busyIndicator.visible = true
                        if(editObject.feature)
                        saveAttributesRelatedObject(editObject)
                        else
                        saveAttributes_object(editObject)

                    }
                }


            }
        }

        contentItem:Rectangle{
            width:parent.width
            height:parent.height - header.height

            color:"white"

            ColumnLayout{
                width:parent.width
                height:parent.height
                spacing:0

                Controls.BaseText {
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight: visible?app.units(45):0
                    text:editObject?editObject.label + ":":""
                    maximumLineCount: 1
                    elide:Text.ElideMiddle
                    fontSizeMode: Text.Fit
                    font.pixelSize:app.baseFontSize
                    font.family: app.baseFontFamily
                    color:app.primaryColor
                    visible:editObject?editObject.domainName.count > 0:false
                    Layout.alignment: Qt.AlignLeft
                    verticalAlignment: Qt.AlignVCenter
                    Layout.leftMargin: app.isLeftToRight ?  app.units(16) : 0
                    Layout.rightMargin: app.isLeftToRight ?  0 : app.units(16)
                    horizontalAlignment: app.isLeftToRight ? Text.AlignLeft : Text.AlignRight

                }

                Rectangle{
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color:app.separatorColor
                    visible:editObject?editObject.domainName.count > 0:false

                }


                Flickable{
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Loader {
                        id: loader
                        property int defaultIndex
                        property var rangeArray: []
                        property var codedNameArray : []
                        property var codedCodeArray: []
                        property int domainTypeIndex: 0
                        property var domainTypeArray
                        property var functionArray
                        anchors.fill:parent
                        anchors.leftMargin: app.isLeftToRight ? app.units(16) : ((editObject && editObject.domainName.count === 0)?app.units(16):0)
                        anchors.rightMargin: app.isLeftToRight ? ((editObject && editObject.domainName.count === 0)?app.units(16):0) : app.units(16)
                        anchors.topMargin: 0

                    }


                }

            }

            BusyIndicator {
                id: busyIndicator
                Material.primary: app.primaryColor
                Material.accent: app.accentColor
                visible:false
                width: app.iconSize
                height: app.iconSize
                anchors.centerIn: parent

            }

        }


    }


    Component {
        id: editControl
        Controls.EditControl{

        }
    }

    Component {
        id: cvdControl

        Controls.Domain_CodedValue {

        }
    }



    Component {
        id: rangeControl
        Controls.Domain_Range {}
    }

    Component {
        id: dateControl
        Controls.DateControl {}
    }



}
