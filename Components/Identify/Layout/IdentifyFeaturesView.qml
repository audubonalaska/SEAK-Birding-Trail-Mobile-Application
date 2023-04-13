import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1


import Esri.ArcGISRuntime 100.14

import "../../../MapViewer/controls" as Controls

ListView {
    id: identifyFeaturesView

    property string featureSymbolUrl:identifyManager.featureSymbol
    property string measurement :identifyManager.measurement
    property string layerName: ""
    property string popupTitle: ""
    property var identifiedFeature:null
    property real minDelegateHeight: 2 * app.units(56)
    property real headerHeight:0.8 * app.headerHeight
    property var calendarPicker:null
    property alias editBusyIndicator:editbusyIndicator
    property var editorTrackingInfo:isInShapeEditMode ? null :identifyManager.featureEditorTrackingInfo
    //property bool savingInProgress:false
    //property string noValue:"No Value"

    highlightMoveVelocity: 2000
    highlightMoveDuration: 10
    //property int selectedIndex:0
    boundsBehavior: Flickable.StopAtBounds

    signal hidePanelPage()
    signal showSuccessMessage()
    signal highlightFeature(var feature)



    clip: true
    spacing: 0
    width: panelPage.width

    Controls.CustomListModel{
        id:editedData
    }
    Connections{
        target:attributeEditorManager
        function onSaveFeatureStarted()
        {
            editBusyIndicator.visible = true
        }

        function onSaveFeatureCompleted()
        {
            editBusyIndicator.visible = false
        }

    }

    /*  Connections{
        target:identifyManager
        function onPopulateModelCompletedChanged(){
            exitEditModeInProgress = false
            identifyFeaturesView.model = identifyManager.attrListModel

        }
        function onUpdateFeaturesView(editObject){
            editedData.clear()


            for(let k=0;k< identifyManager.attrListModel.count;k++)
            {

                let existingRecord = identifyManager.attrListModel.get(k)
                if(existingRecord.fieldName === editObject.fieldName)
                {
                    existingRecord["unformattedValue"] = editObject.fieldValue > ""?editObject.fieldValue.toString():""
                    existingRecord["editedValue"] = editObject.fieldValue > "" ?editObject.fieldValue.toString():""
                    editedData.append(existingRecord)
                    // identifyFeaturesView.currentIndex = selectedIndex
                }
                else
                {

                    editedData.append(existingRecord)
                }

                //identifyFeaturesView.currentIndex = selectedIndex
            }
            model = editedData
            // let isContigencyListValid = validateContingentValues(feature1)

            identifyFeaturesView.forceLayout()


        }

        function onSaveFeatureStarted()
        {
            editBusyIndicator.visible = true
        }

        function onSaveFeatureCompleted()
        {
            editBusyIndicator.visible = false
        }
    }*/




    onShowSuccessMessage: {
        identifyManager.showSuccessfulMessage()
    }


    /*
      update the attributes in the currentedited feature from the values
      of the edited and  also update the field domains based on edited data

   */
    function updateAttributeListModel(editObject)
    {
        //update the domains if the featureType changes
        //get the CurrentFeature
         let editedTable = editObject.currentFeatureEdited.featureTable.tableName
        let currentlyEditedFeature = identifyManager.currentFeature
        let featureTable  = currentlyEditedFeature.featureTable
        let featureTypeField = featureTable.typeIdField

        var newEditObject = Object.assign({},editObject)
        editedData.clear()
        for(let k=0;k< identifyManager.attrListModel.count;k++)
        {
            //get the old value
            let existingRecord = identifyManager.attrListModel.get(k)

            //get the new value from the edited feature
            let newfldval = featuresManager.getFieldValueFromFeature(currentlyEditedFeature,existingRecord.fieldName)
            if(newfldval !== null && existingRecord.fieldValue !== newfldval.toString())
            {

                //update the model

                identifyManager.attrListModel.setProperty(k,"fieldValue",newfldval)

            }

            //need to check if the user changes a featureType then we need to
            //update the domain values of other fields which is depended on that

            featuresManager.updateFeatureWithDomains(existingRecord,newEditObject,featureTable,currentlyEditedFeature)

            editedData.append(existingRecord)
            identifyFeaturesView.currentIndex = selectedIndex

        }

        //model = editedData
        updateCurrentModel(editedData)
        identifyManager.currentFeature = currentlyEditedFeature
        identifyManager.editedFeatures.push(currentlyEditedFeature)
        //identifyManager.editedFeatures.push(editObject.fieldName)
        identifyManager.featureEdited = true
        identifyFeaturesView.forceLayout()
    }



    function updateCurrentModel(editedData)
    {
        for (let k=0;k< editedData.count;k++)
        {
            let fldobject = editedData.get(k)
            if(model.get(k)["fieldValue"] !== fldobject["fieldValue"])
            {
                model.setProperty(k,"fieldValue",fldobject["fieldValue"])
                model.setProperty(k,"domainName",fldobject["domainName"])
                model.setProperty(k,"domainCode",fldobject["domainCode"])
                model.setProperty(k,"editedValue",fldobject["editedValue"])
            }


        }
    }

    /* function createFeature(editObject)
    {
        var newEditObject = Object.assign({},editObject)

    }*/




    footer:Rectangle{
        height:isIphoneX ? 56 * scaleFactor :36 * scaleFactor
        width:identifyFeaturesView.width
        color:"transparent"

        RowLayout{
            height:parent.height
            spacing:0
            anchors.horizontalCenter: parent.horizontalCenter
            Controls.BaseText {

                fontsize:app.textFontSize
                color:app.subTitleTextColor
                maximumLineCount: 1
                elide: Text.ElideRight
                text: editorTrackingInfo !== null ? strings.edited :""
                visible:typeof editorTrackingInfo !== "undefined" && editorTrackingInfo !== null?true:false
                wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                leftPadding: !app.isRightToLeft ? app.defaultMargin : 0
                rightPadding: !app.isRightToLeft ? 0 : app.defaultMargin

                topPadding: app.baseUnit//app.defaultMargin
                //font.italic:true
            }
            Controls.BaseText {
                id: userEdited
                fontsize:app.textFontSize
                color:app.subTitleTextColor
                maximumLineCount: 1
                elide: Text.ElideRight
                text:typeof editorTrackingInfo !== "undefined" && editorTrackingInfo !== null? editorTrackingInfo["editor"]:""
                wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                //leftPadding: !app.isRightToLeft && text > ""? app.defaultMargin : 0
                //rightPadding: !app.isRightToLeft  && text > ""? 0 : app.defaultMargin
                //bottomPadding: app.defaultMargin
                topPadding: app.baseUnit//app.defaultMargin
                //font.italic:true
            }
            Controls.BaseText {
                id: editedTime
                fontsize:app.textFontSize
                color:app.subTitleTextColor
                maximumLineCount: 1
                elide: Text.ElideRight
                text:editorTrackingInfo !== null && typeof editorTrackingInfo !== "undefined"?editorTrackingInfo["editedDate"]:""
                wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft

                topPadding: app.baseUnit//app.defaultMargin
                //font.italic:true
            }



        }

    }

    delegate:Item {
        width: identifyFeaturesView.width
        height:relatedFeatureControl.height
        Controls.FeatureControl{
            id:relatedFeatureControl
            width:parent.width
            //visible:!mapPage.isInShapeEditMode
            _currentFeature:typeof feature !== "undefined"? feature : null

            _layerName:typeof serviceLayerName !== "undefined" ? serviceLayerName : null
            _editableFeature: typeof editableFeature !== "undefined" ? editableFeature: null
            _fieldName:typeof fieldName !== "undefined" ? fieldName : (typeof label !== "undefined" ? label:"")
            _label:typeof label !== "undefined" ? label : "undefined"
            _domainName:typeof domainName !== "undefined" ? domainName : "undefined"
            _fieldValue:typeof fieldValue !== "undefined" ? fieldValue : "undefined"
            _description:typeof description !== "undefined" ? description : "undefined"
            _domainCode:typeof domainCode != "undefined" ? domainCode : "undefined"
            _minValue:typeof minValue !== "undefined" ? minValue : "undefined"
            _maxValue:typeof maxValue !== "undefined" ? maxValue : "undefined"
            _length:typeof length !== "undefined" ? length:"undefined"
            _fieldType:typeof fieldType !== "undefined" ? fieldType:"undefined"
            _nullableValue:typeof nullableValue !== "undefined" ? nullableValue:"undefined"
            _unformattedValue:typeof unformattedValue !== "undefined" ? unformattedValue:"undefined"
            _isInEditMode:app.isInEditMode
            _fieldValidType:typeof fieldValidType !== "undefined" ? fieldValidType :"undefined"


            onUpdateFieldObject:{
            if(_fieldName === editObject.fieldName)
                updateAttributeListModel(editObject)
            }



        }
    }


    Controls.BaseText {
        id: message
        visible:(!exitEditModeInProgress && !mapView.identifyProperties.isModelBindingInProgress) && identifyManager.attrListModel.count <= 0
        maximumLineCount: 5
        elide: Text.ElideRight
        width: parent.width
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: qsTr("There are no attributes configured.")
    }

    BusyIndicator {
        id: editbusyIndicator

        width: app.iconSize
        visible: false//exitEditModeInProgress || mapView.identifyProperties.isModelBindingInProgress
        height: width
        anchors.centerIn: parent
        Material.primary: app.primaryColor
        Material.accent: app.accentColor

        Timer {
            id: timeOut

            interval: 3000
            running: true
            repeat: false
            onTriggered: {
                //busyIndicator.visible = false
            }
        }
    }



}


