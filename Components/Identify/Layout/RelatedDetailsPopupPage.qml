import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0

import "../../../MapViewer/controls"  as Controls

Controls.PopupPage {
    id: root

    property url link: ""
    property bool showCloseButton: true
    property real headerHeight: root.getAppProperty(app.headerHeight, root.units(56))
    property var relatedDetailsObj
    property real headerRowheight:   0.8 * app.headerHeight + ( panelPage.fullView ? app.notchHeight : 0 )
    property bool hasEdits:false//attributeEditorManager.editedFieldValues.length > 0
    property bool isValidated:true
    property alias identifyRelatedFeaturesViewlst:identifyRelatedFeaturesViewlst
    clip:true
    topMargin: 10


    signal closed ()

    onOpened: {
        attributeEditorManager.editedFieldValues = []
    }
    onClosed:{
        attributeEditorManager.editedFieldValues = []
    }

    Connections{
        target:attributeEditorManager
        //function onFeatureEditedChanged(){
        function onAttributesSavedInMemory(feature){
            let fldValueChanged = false
            attributeEditorManager.editedFieldValues.forEach(function(fieldObj){
                if(fieldObj.oldValue !== fieldObj.newValue)
                    fldValueChanged = true

            })
            if(fldValueChanged)
                hasEdits = true
            else
                hasEdits = false

            let featureValidationErrorType = contingencyValues.validateContingentValues(feature)
            if(featureValidationErrorType !== "Error")
                isValidated = true


        }
    }

    Connections{
        target:attributeEditorManager
        function onAttributesSaved()
        {
            root.close()
        }
    }

    Controls.CustomListModel{
        id:editedData
    }



    contentItem: Controls.BasePage {

        width: parent.width
        height: parent.height
        //topPadding: 20


        // LayoutMirroring.enabled: app.isRightToLeft
        // LayoutMirroring.childrenInherit: app.isRightToLeft
        // Material.background:  "green"



        header: ToolBar {

            id: identifyRelatedFeaturesViewheader

            height:headerRowHeight//app.units(50)//headerRowHeight
            width: parent.width
            Material.background: headerBackgroundColor
            Material.elevation: 0
            // topPadding: 10

            RowLayout {
                anchors.fill: parent

                /*  Controls.Icon {
                    id: closeBtn

                    visible: true
                    imageSource: "../../../MapViewer/controls/images/back.png"

                    leftPadding: 16 * scaleFactor

                    Material.background: app.backgroundColor
                    Material.elevation: 0
                    maskColor: "#4c4c4c"
                    onClicked: {
                        //relateddetails.visible=false
                        //panelContent.visible=true
                        //isHeaderVisible = true
                        root.close()

                    }
                }
*/
                Rectangle{
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.leftMargin:16 * scaleFactor
                    color:"transparent"

                    Controls.BaseText {

                        width:parent.width

                        text: relatedDetailsObj ? relatedDetailsObj.headerText: ""//headerText
                        maximumLineCount: 1

                        anchors.centerIn: parent

                        elide: Text.ElideRight

                        color: app.baseTextColor
                        font {
                            pointSize: app.textFontSize
                        }
                        rightPadding: app.units(16)
                    }

                }
            }
        }


        contentItem:Rectangle{
            width: parent.width
            height:parent.height.height  - panelHeaderHeight
            color:"white"
            ListView {
                id: identifyRelatedFeaturesViewlst
                anchors.fill:parent
                //width: parent.width
                model:relatedDetailsObj ? relatedDetailsObj.model:null
                // Layout.fillHeight: true
                //height:parent.height.height  - panelHeaderHeight
                boundsBehavior: Flickable.StopAtBounds
                property var feature:relatedDetailsObj && relatedDetailsObj.feature ? relatedDetailsObj.feature :null
                property bool canEdit:relatedDetailsObj && relatedDetailsObj.canEdit? relatedDetailsObj.canEdit:false
                property var serviceLayerName:relatedDetailsObj ? relatedDetailsObj.serviceLayerName : ""
                Material.background:"#FFFFFF"


                clip: true
                footer:Rectangle{
                    height:100 * scaleFactor
                    width:identifyRelatedFeaturesViewlst.width
                    color:"transparent"
                }



                delegate:

                    Item {
                    width: identifyRelatedFeaturesViewlst.width //- app.units(16)
                    //anchors.right:identifyRelatedFeaturesViewlst.right

                    height:relatedFeatureControl.height//contentColumn.height
                    Controls.FeatureControl{
                        id:relatedFeatureControl
                        width:identifyRelatedFeaturesViewlst.width
                        _layerName:identifyRelatedFeaturesViewlst.serviceLayerName
                        _editableFeature: identifyRelatedFeaturesViewlst.feature
                        _fieldName:typeof FieldName !== "undefined" ? FieldName : null
                        _label:typeof label !== "undefined" ? label : null
                        _domainName:typeof domainName !== "undefined" ? domainName : null
                        _fieldValue:typeof FieldValue !== "undefined" ? FieldValue : null
                        _domainCode:typeof domainCode != "undefined" ? domainCode : null
                        _minValue:typeof minValue !== "undefined" ? minValue : -1
                        _maxValue:typeof maxValue !== "undefined" ? maxValue : -1
                        _length:typeof length !== "undefined" ? length:0
                        _fieldType:typeof fieldType !== "undefined" ? fieldType:null
                        _nullableValue:typeof nullableValue !== "undefined" ? nullableValue:null
                        _unformattedValue:typeof unformattedValue !== "undefined" ? unformattedValue:null
                        _isInEditMode:app.isInEditMode

                        onSaveDateField: {
                            attributeEditorManager.saveAttributesRelatedObject(editObject)
                            //identifyManager.saveAttributesRelatedObject(editObject)
                            // updateRelatedDetailsObjModel(editObject)
                        }


                    }


                }

            }
        }


        footer: ToolBar {
            id: footerrelated
            width: parent.width
            height:app.units(80)
            Material.background: "#F4F4F4"
            Material.elevation: 0
            LayoutMirroring.enabled:isRightToLeft
            LayoutMirroring.childrenInherit: isRightToLeft

            RowLayout {
                anchors.fill: parent

                Button {
                    id: cancelBtn
                    visible:true
                    Layout.preferredWidth:(parent.width - 42)/2
                    //width:parent.width/2 - app.units(32)
                    Layout.preferredHeight:app.units(56)
                    Layout.leftMargin: app.units(14)
                    Material.foreground: pressed ? Qt.lighter(app.primaryColor) : app.primaryColor
                   // Material.foreground:getAppProperty(app.subTitleTextColor, Qt.darker("#F7F8F8", 1.5))
                    text:strings.cancel //qsTr("Cancel")
                    //font.pixelSize:app.baseFontSize
                    //font.family: app.baseFontFamily

                   /* background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                    }*/
                    background: Rectangle {
                        width: parent.width//(panelIdentifyFooter.width - 42)/2
                        height: app.units(48)
                        //color:app.primaryColor
                        border.color: app.primaryColor//"#888"
                        radius: 4

                    }

                    onClicked: {
                        root.close()
                        //editAttributePage.close()

                    }
                }



                Controls.SpaceFiller {
                    Layout.fillWidth: true
                }

                Button {
                    id: saveBtn
                    visible:isInEditMode
                    Layout.preferredWidth:(parent.width - 42)/2

                    Layout.preferredHeight:app.units(56)
                   // width:(parent.width - 42)/2//parent.width/2 - app.units(32)
                   // height:app.units(56)
                    Layout.rightMargin: app.units(10)

                    // Material.foreground:app.primaryColor
                    text:strings.save
                    //font.pixelSize:app.baseFontSize
                    Material.foreground: "white"
                    //Material.foreground:hasEdits ? app.primaryColor : getAppProperty(app.subTitleTextColor, Qt.darker("#F7F8F8", 1.5))
                    //font.bold: hasEdits?true:false
                    /* background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                    }*/
                    background: Rectangle {
                        width: parent.width//(panelIdentifyFooter.width - 42)/2
                        height: app.units(48)
                        //color:app.primaryColor
                        color: saveBtn.pressed ? Qt.lighter(app.primaryColor) : app.primaryColor

                        radius: 4

                    }

                    onClicked: {

                        if(hasEdits)
                        {
                            let featureArray = []
                            featureArray.push(relatedDetailsObj.feature)
                            attributeEditorManager.saveExistingFeature(featureArray,true,root)
                            // attributeEditorManager.saveExistingFeature(relatedDetailsObj.feature)
                        }
                        else
                            toastMessage.show(strings.no_edits_to_save)

                    }
                }


            }
        }


    }




    Component.onDestruction: {
    }



    function updateRelatedDetailsObjModel(editObject)
    {
        //update the domains if the featureType changes
        //get the CurrentFeature
        let currentlyEditedFeature = editObject.feature
        let featureTable  = currentlyEditedFeature.featureTable
        let featureTypeField = featureTable.typeIdField

        var newEditObject = Object.assign({},editObject)
        let relatedObjectModel = relatedDetailsObj.model
        editedData.clear()
        for(let k=0;k< relatedObjectModel.count;k++)
        {
            //get the old value
            let existingRecord = relatedObjectModel.get(k)

            //get the new value from the edited feature
            let newfldval = featuresManager.getFieldValueFromFeature(currentlyEditedFeature,existingRecord.FieldName)
            if(existingRecord.FieldValue.toString() !== newfldval.toString())
            {

                //update the model
                relatedObjectModel.setProperty(k,"FieldValue",newfldval.toString())


            }

            featuresManager.updateFeatureWithDomains(existingRecord,newEditObject,featureTable,currentlyEditedFeature)



            editedData.append(existingRecord)
            //identifyFeaturesView.currentIndex = selectedIndex

        }

        relatedObjectModel = editedData
        // identifyManager.currentFeature = currentlyEditedFeature
        //root.forceLayout()
    }




    function getAppProperty (appProperty, fallback) {
        if (!fallback) fallback = ""
        try {
            return appProperty ? appProperty : fallback
        } catch (err) {
            return fallback
        }
    }

    function units (num) {
        return num ? num * AppFramework.displayScaleFactor : num
    }

}
