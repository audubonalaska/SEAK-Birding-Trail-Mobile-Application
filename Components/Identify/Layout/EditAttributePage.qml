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


import "../../../MapViewer/controls"  as Controls

//import "../widgets" as Widgets

Controls.PopupPage {

    id: editAttributePage
    width:panelPage.width
    height:panelPage.height

    property var editObject:null
    property bool isShowTextArea: false
    property bool isRangeValidated:true
    property bool isInputValidated:true
    property bool canResetValidator:true
    property bool hasEdits:false
    Material.elevation: 0

    signal updateAttribute(var editObject)

    signal fieldUpdated(var editObject)
    signal closeSection()
    signal dismissKeyboard()

    onDismissKeyboard: {

        if(Qt.inputMethod.visible===true) Qt.inputMethod.hide();
    }


    onFieldUpdated:{

        identifyManager.editedFeatures.push(identifyManager.currentFeature)//editObject.fieldName)
        identifyManager.featureEdited = true
    }

    onOpened:{
        loader.sourceComponent = (function(){
            busyIndicator.visible = false
            if(editObject && editObject.domainName.count === 0)
            {
                if(!editObject.nullableValue && editObject.fieldValue.trim() === "")
                    isInputValidated = false
                else
                    isInputValidated=true

                canResetValidator = true
                return editControl
            }
            else
                return cvdControl

        })()
        //identifyManager.editedFeatures = []
        //identifyManager.featureEdited = false

    }

    onClosed: {
        loader.sourceComponent = undefined
        panelPage.action = ""
        busyIndicator.visible = false
    }




    onVisibleChanged: {
        app.focus = true
    }


    function cancelEdit()
    {
        dismissKeyboard()
        //close the list page sections in case of coded Domain value control
        closeSection()
        editAttributePage.close()
    }

    contentItem: Controls.BasePage{

        footer: ToolBar {
            id: footer
            width: parent.width
            height:app.units(80) + app.notchHeight
            Material.background: "#F4F4F4"
            Material.elevation: 0
            LayoutMirroring.enabled:isRightToLeft
            LayoutMirroring.childrenInherit: isRightToLeft

           /* RowLayout {
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
                        cancelEdit()
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
                    text:strings.done
                    font.pixelSize:app.baseFontSize
                    font.bold: hasEdits?true:false
                    //font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    //enabled: isInputValidated && hasEdits?true : false

                    background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                    }

                    onClicked: {
                        dismissKeyboard()

                        if(hasEdits)
                        {
                            let  featureEdited

                            busyIndicator.visible = true
                            if(editObject.feature)
                            {
                                //case 1 - related feature
                                featureEdited = editObject.feature

                            }
                            else
                            {
                                if(mapPage.isInShapeCreateMode)
                                    featureEdited = sketchEditorManager.newFeatureObject["feature"]
                                else
                                    featureEdited = identifyManager.features[identifyBtn.currentPageNumber-1]

                            }

                            let {_feature,_editObject} = attributeEditorManager.saveFeatureAttributesInMemory(featureEdited,editObject)
                            if(_editObject.feature)
                            {
                                //if related feature
                                _editObject.feature = _feature
                                // identifyManager.relatedFeatures[identifyBtn.currentPageNumber -1] = _feature
                                identifyManager.editedFeatures.push(_feature)
                                closeEditPageAfterSavingRelatedAttributes(_feature)
                            }
                            else
                            {
                                if(isInShapeCreateMode)
                                    sketchEditorManager.newFeatureObject["feature"] = _feature

                                identifyManager.currentFeature = _feature

                                //fieldUpdated(editObject)
                            }
                            fieldUpdated(_editObject)

                            busyIndicator.visible = false
                            editAttributePage.close()

                        }
                        else
                            cancelEdit()

                    }
                }


            }*/






            RowLayout{
                width:parent.width - 32
                anchors.horizontalCenter: parent.horizontalCenter
                height:parent.height //+ app.notchHeight
                //anchors.fill: parent
                spacing:10

                Button {
                    id:cancelBtn
                    text: strings.cancel


                    Material.foreground: pressed ? Qt.lighter(app.primaryColor) : app.primaryColor

                    background: Rectangle {
                        implicitWidth: (footer.width - 42)/2
                        implicitHeight: app.units(48)

                        border.color: app.primaryColor//"#888"
                        radius: 4

                    }



                    onClicked:{
                        cancelEdit()


                    }

                }

                Button {
                    id:saveBtn
                    text: strings.done
                    Material.foreground: "white"

                    background: Rectangle {
                        implicitWidth: (footer.width - 42)/2
                        implicitHeight: app.units(48)
                        //color:app.primaryColor
                        color: saveBtn.pressed ? Qt.lighter(app.primaryColor) : app.primaryColor

                        radius: 4

                    }



                  onClicked: {
                        dismissKeyboard()

                        if(hasEdits)
                        {
                            let  featureEdited

                            busyIndicator.visible = true
                            if(editObject.feature)
                            {
                                //case 1 - related feature
                                featureEdited = editObject.feature

                            }
                            else
                            {
                                if(mapPage.isInShapeCreateMode)
                                    featureEdited = sketchEditorManager.newFeatureObject["feature"]
                                else
                                    featureEdited = identifyManager.features[identifyBtn.currentPageNumber-1]

                            }

                            let {_feature,_editObject} = attributeEditorManager.saveFeatureAttributesInMemory(featureEdited,editObject)
                            if(_editObject.feature)
                            {
                                //if related feature
                                _editObject.feature = _feature
                                // identifyManager.relatedFeatures[identifyBtn.currentPageNumber -1] = _feature
                                identifyManager.editedFeatures.push(_feature)
                                closeEditPageAfterSavingRelatedAttributes(_feature)
                            }
                            else
                            {
                                if(isInShapeCreateMode)
                                    sketchEditorManager.newFeatureObject["feature"] = _feature

                                identifyManager.currentFeature = _feature

                                //fieldUpdated(editObject)
                            }
                            fieldUpdated(_editObject)

                            busyIndicator.visible = false
                            editAttributePage.close()

                        }
                        else
                            cancelEdit()

                    }





                }


            }














        }

        contentItem:Rectangle{
            width:parent.width
            height:parent.height - footer.height

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
                    Layout.leftMargin: !app.isRightToLeft ?  app.units(16) : 0
                    Layout.rightMargin: !app.isRightToLeft ?  0 : app.units(16)
                    horizontalAlignment: !app.isRightToLeft ? Text.AlignLeft : Text.AlignRight

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
                        anchors.leftMargin: !isRightToLeft ? app.units(16) : ((editObject && editObject.domainName.count === 0)?app.units(16):0)
                        anchors.rightMargin: !isRightToLeft ? ((editObject && editObject.domainName.count === 0)?app.units(16):0) : app.units(16)
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
            id:domain_codedValue
            Connections{
                target:editAttributePage
                function onCloseSection(){
                    //check the first section

                    domain_codedValue.collapseSection ("category", strings.others_text, false)

                }

            }

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




    function closeEditPageAfterSavingAttributes()
    {

        if(editAttributePage)
        {
            editAttributePage.close()
            mapView.identifyProperties.refreshModel(identifyBtn.currentPageNumber)
        }
    }


    //gets called after saving a attribute for related feature
    function closeEditPageAfterSavingRelatedAttributes(editedFeature)
    {
        if(editAttributePage)
        {

            var _feature = identifyManager.populateModelAfterEditForRelatedAttributes(editedFeature)
            editAttributePage.close()
        }
    }




    Component.onCompleted: {
        /* identifyManager.attributesSaved.disconnect(closeEditPageAfterSavingAttributes)
        identifyManager.attributesSaved.connect(closeEditPageAfterSavingAttributes)*/
        //identifyManager.relatedAttributesSaved.disconnect(closeEditPageAfterSavingRelatedAttributes)
        // identifyManager.relatedAttributesSaved.connect(closeEditPageAfterSavingRelatedAttributes)

    }



}
