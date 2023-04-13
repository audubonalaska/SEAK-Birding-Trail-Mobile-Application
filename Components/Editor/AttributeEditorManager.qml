/*
This file contains the code to save the attributes for existing feature. Saving of attributes is a 2 step process.
First we save the attributes in memory corresponding to each edited field. Then we save the feature when all the edited changes are applied.

*/

import QtQuick 2.0
import QtQuick.Dialogs 1.2
import Esri.ArcGISRuntime 100.14

Item {
    id:attributeEditorManager
    property MapView _mapView
    property var editedFieldValues:[]
    property bool isInCreateMode
    property bool isAttachmentEdited:false
    signal saveFeatureStarted()
    signal saveFeatureCompleted()
    signal attributesSaved(var isRelated)
    signal relatedAttributesSaved(var editedFeature)
    signal attributesSavedInMemory(var updatedFeature)



    function showErrorMessage(editresult) {

        app.messageDialog.width = messageDialog.units(300)
        app.messageDialog.standardButtons = Dialog.Ok//Dialog.Cancel | Dialog.Yes
        app.messageDialog.show("",(strings.error_while_saving.arg(editresult.error)))
        exitEditModeInProgress = false
        //busyIndicator.visible = false

    }


    function showSuccessfulMessage()
    {
        toastMessage.show(strings.successfully_saved,null,2000)
    }

    function validateRequiredFields(_currentFeature)
    {
        let _featureTable = _currentFeature.featureTable
        let fields =  _featureTable.editableAttributeFields//_featureTable.fields
        let fieldsNotNullable = []
        let isValid = true
        let nullFields = []

        for(var key in fields)
        {
            let field = fields[key]
            var fldname = ""
            if(field.name)
                fldname = field.name
            else
                fldname = field.fieldName
            if(!field.nullable)
            {
                fieldsNotNullable.push(fldname)
            }
        }
        for(let k=0;k<fieldsNotNullable.length; k++)
        {
            let _fldname = fieldsNotNullable[k]

            let _fldVal = _currentFeature.attributes.attributeValue(_fldname)
            if(_fldVal === null || typeof _fldVal === "undefined" || (typeof _fldVal === "string" && !_fldVal.trim() > "")){
                isValid = false
                nullFields.push(fldname)
                break;
            }
        }

        return {status:isValid,inValidFields:nullFields}
    }


    function getFieldValueFromEditObject(editObject)
    {
        let fieldVal = null
        let fldObj = editObject
        if(fldObj.originalFieldValue !== fldObj.fieldValue)
        {
            if(fldObj.domainName && (fldObj.domainName.count > 0 || fldObj.domainName.length > 0))
            {
                let _featureTable = fldObj.currentFeatureEdited.featureTable
                let _code = mapViewerCore.getDomainCodeFromFeatureTable(_featureTable,fldObj.fieldName,fldObj.fieldValue)
                return _code
            }
            else if(fldObj.fieldType === Enums.FieldTypeDate)
            {
                fieldVal = new Date(fldObj.fieldValue)
                return fieldVal
            }
            else
                return fldObj.fieldValue
        }
        else
            return null


    }

    function saveExistingFeature(featureArray,isRelated,relatedPopup,isSaved)
    {

        if(featureArray.length > 0)
        {
            let _currentFeature = featureArray.pop()
            //if(!isRelated)
            //    isRelated = false
            let statusObject = validateRequiredFields(_currentFeature)
            let featureValidationErrorType = contingencyValues.validateContingentValues(_currentFeature)
            let isStatusValid = statusObject.status
            let invalidFields = statusObject.inValidFields
            if(featureValidationErrorType !== "Error"){
                if(!isStatusValid)
                {
                    app.messageDialog.width = messageDialog.units(300)
                    app.messageDialog.standardButtons = Dialog.Ok
                    app.messageDialog.show(strings.invalid_fields,strings.show_null_fields.arg(invalidFields))

                }
                else
                {

                    exitEditModeInProgress = true
                    saveFeatureStarted()

                    let isEdited = false
                    let _featuretable  = _currentFeature.featureTable
                    let typeId = _featuretable.typeIdField

                    _featuretable.onApplyEditsStatusChanged.connect(function(){
                        if (_featuretable.applyEditsStatus === Enums.TaskStatusCompleted) {
                            // apply the edits to the service
                            // saveFeatureCompleted()

                            if(_featuretable.applyEditsResult)
                            {
                                let editresult = _featuretable.applyEditsResult[0]
                                if(editresult && editresult.error)
                                {
                                    showErrorMessage(editresult)


                                }
                                else
                                {
                                    if (panelPage && panelPage.action !=="deleteAttachment")
                                    {
                                        // toastMessage.show(strings.successfully_saved,null,2000)
                                        // editedFieldValues = []
                                        if(!isSaved)
                                        isSaved = true
                                        saveExistingFeature(featureArray,isRelated,relatedPopup,isSaved)
                                        //attributesSaved(isRelated)

                                    }

                                }
                            }
                            else
                            {
                                //mapPage.saveBusyIndicator.visible = false
                                // saveFeatureCompleted()
                                //toastMessage.show(qsTr("Error in saving"))
                                var errorObj = {}
                                errorObj.error =qsTr("Error in saving")
                                showErrorMessage(errorObj)
                            }

                        }
                    }
                    )

                    _featuretable.onUpdateFeatureStatusChanged.connect(function(){
                        if (_featuretable.updateFeatureStatus === Enums.TaskStatusCompleted) {
                            // apply the edits to the service
                            _featuretable.applyEdits();

                        }
                        if (_featuretable.updateFeatureStatus === Enums.TaskStatusErrored) {
                            var errorObj = {}
                            errorObj.error = _featuretable.error.message
                            //toastMessage.show("",strings.error_while_saving.arg(errorObj.error))
                            showErrorMessage(errorObj)
                            //saveFeatureCompleted()
                        }
                    }
                    )

                    // update the feature in the feature table asynchronously
                    _featuretable.updateFeature(_currentFeature);

                }
            }
            else
            {
                app.messageDialog.width = messageDialog.units(300)
                app.messageDialog.standardButtons = Dialog.Ok
                app.messageDialog.show(strings.incompatible_fields)
            }
        }
        else
        {
            saveFeatureCompleted()
            if(isSaved)
            toastMessage.show(strings.successfully_saved,null,2000)
            if(!isRelated)
            attributesSaved(null)
            else
            {
             if(relatedPopup)
             relatedPopup.close()
            }

            editedFieldValues = []
        }

    }






    //called when saving existing feature
    function saveExistingFeature_(feature,isRelated)
    {
        let _currentFeature = feature
        //if(!isRelated)
        //    isRelated = false
        let statusObject = validateRequiredFields(_currentFeature)
        let featureValidationErrorType = contingencyValues.validateContingentValues(_currentFeature)
        let isStatusValid = statusObject.status
        let invalidFields = statusObject.inValidFields
        if(featureValidationErrorType !== "Error"){
            if(!isStatusValid)
            {
                app.messageDialog.width = messageDialog.units(300)
                app.messageDialog.standardButtons = Dialog.Ok
                app.messageDialog.show(strings.invalid_fields,strings.show_null_fields.arg(invalidFields))

            }
            else
            {

                exitEditModeInProgress = true
                saveFeatureStarted()

                let isEdited = false
                let _featuretable  = feature.featureTable
                let typeId = _featuretable.typeIdField

                _featuretable.onApplyEditsStatusChanged.connect(function(){
                    if (_featuretable.applyEditsStatus === Enums.TaskStatusCompleted) {
                        // apply the edits to the service
                        saveFeatureCompleted()

                        if(_featuretable.applyEditsResult)
                        {
                            let editresult = _featuretable.applyEditsResult[0]
                            if(editresult && editresult.error)
                            {
                                showErrorMessage(editresult)

                            }
                            else
                            {
                                if (panelPage && panelPage.action !=="deleteAttachment")
                                {
                                    toastMessage.show(strings.successfully_saved,null,2000)
                                    editedFieldValues = []
                                    attributesSaved(isRelated)
                                }

                            }
                        }
                        else
                        {
                            //mapPage.saveBusyIndicator.visible = false
                            saveFeatureCompleted()
                            toastMessage.show(qsTr("Error in saving"))
                        }

                    }
                }
                )

                _featuretable.onUpdateFeatureStatusChanged.connect(function(){
                    if (_featuretable.updateFeatureStatus === Enums.TaskStatusCompleted) {
                        // apply the edits to the service
                        _featuretable.applyEdits();

                    }
                    if (_featuretable.updateFeatureStatus === Enums.TaskStatusErrored) {
                        var errorObj = {}
                        errorObj.error = _featuretable.error.message
                        showErrorMessage(errorObj)
                        saveFeatureCompleted()
                    }
                }
                )

                // update the feature in the feature table asynchronously
                _featuretable.updateFeature(feature);

            }
        }
        else
        {
            app.messageDialog.width = messageDialog.units(300)
            app.messageDialog.standardButtons = Dialog.Ok
            app.messageDialog.show(strings.incompatible_fields)
        }

    }


    //updates the attribute values of related feature in memory
    function saveAttributesRelatedObject(editObject)
    {
        exitEditModeInProgress = true
        let isEdited = false
        let feature1 = editObject.feature
        let {_feature,_editObject} = saveFeatureAttributesInMemory(feature1,editObject)
        editObject.feature = _feature
        return _feature
    }


    //stores the old and new fieldvalues for fields updated by user
    function storeEditedFields(fldname,_oldValue,_newValue)
    {
        let fieldFound=false
        editedFieldValues.forEach(function(fldObj){
            if(fldObj.fieldname === fldname)
            {
                fldObj["newValue"] = _newValue.toString()
                fieldFound = true
            }

        }
        )
        if(!fieldFound)
            editedFieldValues.push({fieldname:fldname,oldValue:_oldValue.toString(),newValue:_newValue.toString()})

    }

    //new function to save the feature in memory
    function saveFeatureAttributesInMemory(_feature,_editObject)
    {
        exitEditModeInProgress = true
        let isEdited = false
        let _featuretable  = _feature.featureTable
        let typeId = _featuretable.typeIdField
        let _fields = _featuretable.editableAttributeFields
        for(let key in _fields)
        {
            let field = _fields[key]
            if(field.editable){
                var fldname = ""
                if(field.name)
                    fldname = field.name
                else
                    fldname = field.fieldName

                var _fieldAlias = fldname

                if(field.label)
                    _fieldAlias = field.label
                else if(field.alias)
                    _fieldAlias = field.alias

                if(_editObject.fieldName === fldname){
                    if(_editObject.fieldValue !== _editObject.originalFieldValue){
                        isEdited = true

                        let fldValToReplace = getFieldValueFromEditObject(_editObject)

                        if(fldValToReplace !==  "null" && fldValToReplace !== strings.no_value && fldValToReplace !== null && (fldValToReplace !== "-999" || fldValToReplace > ""))
                        {
                            if(_editObject.fieldType !== Enums.FieldTypeText && _editObject.fieldType !== Enums.FieldTypeDate)
                            {
                                let _fldValToReplace = Number(fldValToReplace)

                                _feature.attributes.replaceAttribute(fldname, fldValToReplace);
                            }
                            else
                                _feature.attributes.replaceAttribute(fldname, fldValToReplace);

                        }
                        else
                            _feature.attributes.replaceAttribute(fldname, null);

                        storeEditedFields(fldname,_editObject.originalFieldValue,_editObject.fieldValue)
                    }

                }

                //check if the user has changed the featureType. If yes then we need to change the field that depends on it.
                if(_editObject.fieldName === typeId && field.fieldName !== _editObject.fieldName)
                {
                    let typeIdValue= getFieldValueFromEditObject(_editObject)
                    //get the field from the featureTable
                    let fields = _featuretable.fields
                    let targetField = ""
                    for(let key in fields)
                    {
                        let _field = fields[key]
                        if(_field.name === field.fieldName)
                            targetField = _field

                    }
                    let existingfldValue = _feature.attributes.attributeValue(fldname)

                    let newfldValue = featuresManager.getFieldValueFromTemplate(_featuretable,typeIdValue,targetField,existingfldValue)
                    if(newfldValue )
                    {
                        _feature.attributes.replaceAttribute(fldname, newfldValue)
                        storeEditedFields(fldname,existingfldValue,newfldValue)
                    }

                }

            }

        }

        attributesSavedInMemory(_feature)
        return {_feature,_editObject}

    }


    //saves the feature attributes in memory
    function saveAttributes_object(editObject)
    {
        exitEditModeInProgress = true
        let isEdited = false
        let feature1
        var popUp
        var popupManager
        let editableFields
        if(isInCreateMode)
            feature1 = sketchEditorManager.newFeatureObject["feature"]
        else
            feature1 = identifyManager.features[identifyBtn.currentPageNumber-1]

        let {_feature,_editObject}  = saveFeatureAttributesInMemory(feature1,editObject)

        if(isInCreateMode)
            sketchEditorManager.newFeatureObject["feature"] = _feature
        else
            identifyManager.currentFeature = _feature



    }

}
