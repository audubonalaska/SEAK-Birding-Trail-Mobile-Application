import QtQuick 2.0
import QtQuick.Dialogs 1.2
import Esri.ArcGISRuntime 100.14
import "../../MapViewer/controls" as Controls

Item {
    id:identifyManager
    // property var mapView
    property bool isAttachmentPresent:false
    property int attachqueryno:0
    property bool _getAttachmentCompleted:false
    property bool identifyInProgress:false

    property int popupManagersCount: popupManagers.length
    property int popupDefinitionsCount: popupDefinitions.length
    property int featuresCount: features.length
    property int fieldsCount: fields.length
    property int attachmentsCount:attachments.length
    property int currentPageNumber:0
    property int currentFeatureIndex:0
    property var popupManagers: []
    property var popupDefinitions: []
    property var features: []
    property var fields: []
    property var temporal: []
    property var relatedFeatures:[]
    property var attachments:[]
    property var editedFeatures:[]
    property bool featureEdited:false
    property var relatedFeatureTableMap:({})
    property bool populateModelCompleted:false
    property bool isEditable:false
    property var featureEditorTrackingInfo:null
    property alias attrListModel:attrListModel
    property alias relatedFeaturesModel:relatedFeaturesModel
    property alias relatedattrListModel:relatedattrListModel
    // property alias attrListModel:attrListModel
    property string featureSymbol:""
    property string measurement:""
    property bool canDeleteFeature:false
    property bool canEditGeometry:false


    property string layerName:""
    property string popupTitle:""
    property bool isInEditMode:false
    property string action:""
    property var currentFeature


    signal getAttachmentCompleted()
    signal highlightFeature(var feature)
    signal featureDeleted()
    signal featureChanged()



    Controls.CustomListModel {
        id: attrListModel
    }


    Controls.CustomListModel {
        id: relatedFeaturesModel
    }

    Component {
        id: featureListModel
        ListModel {
        }
    }

    Controls.CustomListModel {
        id: relatedattrListModel
    }

    /* Controls.CustomListModel {
                id: attrListModel
            }*/

    function init()
    {
        isAttachmentPresent = false
        _getAttachmentCompleted = false
        attachqueryno = 0
        currentPageNumber = 0
        currentFeatureIndex  = 0
        features = []
        relatedFeatures = []
        features = []
        popupManagers = []
        popupDefinitions = []
        fields = []
    }
    function setCurrentPageNumberAndIndex(_currentPageNumber,_currentFeatureIndex)
    {
        currentPageNumber = _currentPageNumber
        currentFeatureIndex = _currentFeatureIndex
    }

    function populateIdentifyPropertiesForFeature (featureObj,layerName) {

        init()

        let feature = featureObj
        let featureTable = feature.featureTable
        let popupDefinition = featureTable.layer.popupDefinition

        if(!popupDefinition)
            popupDefinition = ArcGISRuntimeEnvironment.createObject("PopupDefinition", {initGeoElement: feature})


        let popUp = ArcGISRuntimeEnvironment.createObject("Popup", {initGeoElement: feature, initPopupDefinition: popupDefinition})
        let popupManager = ArcGISRuntimeEnvironment.createObject("PopupManager", {popup: popUp})
        popupManager.objectName = layerName
        popupManagers.push(popupManager)
        popupManagersCount +=1

        popupDefinitions.push(popupDefinition)
        let _fields = popupDefinition.fields
        let visibleFieldList = []
        for(let k=0;k<_fields.length;k++)
        {
            if(_fields[k].visible)
                visibleFieldList.push(_fields[k])
        }

        fields.push(visibleFieldList)

        features.push(feature)
        //features.push(feature)

        //need to reverse the array so that
        // the related records are correctly ordered
        let newFeatureArray = []
        while(features.length > 0)
            newFeatureArray.push(features.pop())

        //console.log("populating related records")
        features = [...newFeatureArray]

        populateRelatedRecords(newFeatureArray)
    }





    function populateIdentifyProperties (identifyLayerResults,mapProperties) {

        for (var i=0; i<identifyLayerResults.length; i++) {

            var identifyLayerResult = identifyLayerResults[i],
            hasSubLayerResults = false
            if (identifyLayerResult.layerContent.sublayerType === Enums.ArcGISSublayerTypeArcGISTiledSublayer) {
                                    continue
                                }
            try {
                hasSubLayerResults = identifyLayerResult.sublayerResults &&
                        identifyLayerResult.sublayerResults.length
            } catch (err) {}

            if (hasSubLayerResults) {
                //console.log("HAS SUBLAYER RESULTS", identifyLayerResult.sublayerResults.length)
                populateIdentifyProperties(identifyLayerResult.sublayerResults)
            } else {


                if(identifyLayerResult.layerContent && identifyLayerResult.layerContent.popupEnabled){
                    for (var j=0; j<identifyLayerResult.geoElements.length; j++) {

                        var feature = identifyLayerResult.geoElements[j]

                        var popupDefinition = identifyLayerResult.layerContent.popupDefinition
                        if(!popupDefinition)
                            popupDefinition = ArcGISRuntimeEnvironment.createObject("PopupDefinition", {initGeoElement: feature})


                        var popUp = ArcGISRuntimeEnvironment.createObject("Popup", {initGeoElement: feature, initPopupDefinition: popupDefinition})
                        var popupManager = ArcGISRuntimeEnvironment.createObject("PopupManager", {popup: popUp})
                        popupManager.objectName = identifyLayerResult.layerContent.name

                        popupManagers.push(popupManager)
                        popupManagersCount +=1

                        popupDefinitions.push(popupDefinition)
                        var _fields = popupDefinition.fields
                        var visibleFieldList = []

                        for(var k=0;k<_fields.length;k++)
                        {
                            if(_fields[k].visible)
                                visibleFieldList.push(_fields[k])
                        }

                        fields.push(visibleFieldList)

                        features.push(feature)
                        //features.push(feature)

                    }


                }
                else
                {
                    if(mapProperties.isMapArea)
                    {
                        for (var jk=0; jk<identifyLayerResult.geoElements.length; jk++) {

                            var feature1 = identifyLayerResult.geoElements[jk]
                            var popupDefinition1 = ArcGISRuntimeEnvironment.createObject("PopupDefinition", {initGeoElement: feature1})
                            var popUp1 = ArcGISRuntimeEnvironment.createObject("Popup", {initGeoElement: feature1, initPopupDefinition: popupDefinition1})
                            var popupManager1 = ArcGISRuntimeEnvironment.createObject("PopupManager", {popup: popUp1})
                            popupManager1.objectName = identifyLayerResult.layerContent.name
                            popupManagers.push(popupManager1)
                            popupManagersCount +=1


                            popupDefinitions.push(popupDefinition1)


                            var fields1 = popupDefinition1.fields
                            var visibleFieldList1 = []

                            for(var k=0;k<fields1.length;k++)
                            {
                                if(fields1[k].visible)
                                    visibleFieldList1.push(fields1[k])
                            }

                            fields.push(visibleFieldList1)


                            features.push(feature1)
                            //features.push(feature1)
                            //console.log("populating related features")

                        }
                    }

                }
            }

        }

        //need to reverse the array so that
        // the related records are correctly ordered
        var newFeatureArray = []
        // while(features.length > 0)
        //     newFeatureArray.push(features.pop())
        for(let k=features.length - 1; k >=0;k--)
        {
            newFeatureArray.push(features[k])
        }


        //  features = [...newFeatureArray]
        //console.log("populating related records")

        populateRelatedRecords(newFeatureArray)
    }


    function populateRelatedRecords(identifiedFeatures)
    {

        if(identifiedFeatures.length > 0)
        {

            var feature = identifiedFeatures.pop()
            //console.log("fetching record")
            var promiseToFindRelatedRecord = fetchRelatedRecords(feature)
            promiseToFindRelatedRecord.then(isFetched => {
                                                populateRelatedRecords(identifiedFeatures)
                                            })

        }
        else
        {
            //identifyInProgress = false

            //console.log("called from populateRelatedRecords")
            populateFeaturesModel(identifyBtn.currentPageNumber,mapView.identifyProperties.currentFeatureIndex)
            checkIfAttachmentPresent(0)

            if (features.length)
            {
                var _feature = features[0]

                highlightFeature(_feature)

            }

        }


    }

    function addToFeatureTableMap(feat,serviceLayerName)
    {
        if(!relatedFeatureTableMap[serviceLayerName])
            relatedFeatureTableMap[serviceLayerName] = feat.featureTable

    }

    function processRelatedFeature(feat,resolve)
    {
        var fields = feat.featureTable.fields
        var serviceLayerName =  feat.featureTable.layerInfo.serviceLayerName
        let objectid_fldname = featuresManager.getUniqueFieldName(feat.featureTable)
        var displayFieldName = feat.featureTable.layerInfo.displayFieldName ? feat.featureTable.layerInfo.displayFieldName : objectid_fldname

        //var displayFieldName = feat.featureTable.layerInfo.displayFieldName ? feat.featureTable.layerInfo.displayFieldName : "OBJECTID"
        var featureElement = {}
        featureElement["serviceLayerName"] = serviceLayerName
        featureElement["fields"] = []
        featureElement["displayFieldName"] = ""
        featureElement["geometry"] = feat.geometry
        featureElement["feature"] = feat
        addToFeatureTableMap(feat,serviceLayerName)
        var j = feat.attributes.attributesJson;
        for (var key in j) {
            if (j.hasOwnProperty(key)) {
                var fieldobj = {}
                var label = utilityFunctions.getFieldAlias(fields,key)
                var fldType = utilityFunctions.getFieldType(fields,key)
                fieldobj["FieldName"] = label
                var fieldVal = String(j[key])
                if(fieldVal)
                {
                    var codedFieldValue = utilityFunctions.getCodedValue(fields,key,fieldVal)
                    //format the value
                    var _fieldVal = utilityFunctions.getFormattedFieldValue(codedFieldValue,fldType)
                    fieldobj["FieldValue"] = _fieldVal.toString()//fieldVal.toString()

                }
                else
                    fieldobj["FieldValue"] = "null"

                if(key.toUpperCase() === displayFieldName.toUpperCase())
                {
                    if(fieldVal)
                        featureElement["displayFieldName"] = fieldVal.toString()
                    else
                    {
                        fieldVal = feat.attributes.attributeValue(objectid_fldname)
                        //fieldVal = feat.attributes.attributeValue("OBJECTID")

                        featureElement["displayFieldName"] = fieldVal.toString()
                    }

                }
                fieldobj["canShowEditIcon"] = false
                fieldobj["canShowCalendarIcon"] = false
                fieldobj["canShowDomainIcon"] = false

                if(utilityFunctions.isFieldVisible(fields,key))
                    featureElement["fields"].push(fieldobj)
            }
        }

        resolve(featureElement)

    }
     function isFieldVisible(fields,fieldName)
    {
        for(var k=0;k< fields.length; k++)
        {
            var field = fields[k]
            var name = ""
            if(field.name)
                name = field.name
            else if(field.fieldName)
                name = field.fieldName


            if(name.toUpperCase() === fieldName.toUpperCase())
            {
                if(field.visible)
                    return field.visible
                else
                    return true

            }
        }
        return true
    }


    function fetchRelatedFeature(feat)
    {
        return new Promise((resolve, reject) => {

                               if (feat.loadStatus === Enums.LoadStatusLoaded)
                               {
                                   processRelatedFeature(feat,resolve)
                               }
                               else
                               {
                                   feat.loadStatusChanged.connect(function(){
                                       if (feat.loadStatus === Enums.LoadStatusLoaded) {
                                           processRelatedFeature(feat,resolve)

                                       }

                                   })

                                   feat.load();
                               }

                           })
    }

    function processRelatedFeaturesRecords(relfeatures,relatedFeaturesList,resolve)
    {
        var received = true
        //console.log("going to process featurelength " + relfeatures.length)
        if(relfeatures.length > 0)
        {

            var feature = relfeatures.pop()
            var promiseToloadRelatedFeature = fetchRelatedFeature(feature)
            promiseToloadRelatedFeature.then(featureElement => {
                                                 relatedFeaturesList.push(featureElement)
                                                 processRelatedFeaturesRecords(relfeatures,relatedFeaturesList,resolve)
                                             })

        }
        else
        {

            if(received)
            {
                relatedFeatures.push(relatedFeaturesList)
                received = false
                resolve(true)
            }
        }
    }




    function fetchRelatedRecords(feature)
    {
        var fetched = false
        return new Promise((resolve, reject) => {

                               var _relatedRecs = {}

                               var selectedTable = feature.featureTable
                               if(selectedTable){

                                   if(selectedTable.queryRelatedFeaturesStatusChanged)
                                   {
                                       //console.log("fetching related records")
                                       selectedTable.queryRelatedFeaturesStatusChanged.connect(function(){
                                           if (selectedTable.queryRelatedFeaturesStatus === Enums.TaskStatusCompleted)
                                           {
                                               if(!fetched)
                                               {
                                                   var featuresToProcess = []
                                                   var relatedFeatureQueryResultList = selectedTable.queryRelatedFeaturesResults
                                                   var relatedFeaturesList = []
                                                   var noOfRelatedFeatureQueryResultToprocess = relatedFeatureQueryResultList.length
                                                   for (var i=0;i < relatedFeatureQueryResultList.length; i++)
                                                   {
                                                       var iter = relatedFeatureQueryResultList[i].iterator

                                                       //let _relationshipInfo = relatedFeatureQueryResultList[i].relationshipInfo

                                                       for(var k = 0; k < iter.features.length;k++)
                                                       {
                                                           var feat = iter.features[k]
                                                           featuresToProcess.push(feat)

                                                       }

                                                   }

                                                   processRelatedFeaturesRecords(featuresToProcess,relatedFeaturesList,resolve)
                                                   fetched = true
                                               }

                                           }
                                           else if(selectedTable.queryRelatedFeaturesStatus === Enums.TaskStatusErrored) {
                                               resolve(true)
                                               if(selectedTable.error)
                                                   console.error("error:", selectedTable.error.message, selectedTable.error.additionalMessage);

                                           }
                                       }
                                       )
                                       //selectedTable.queryRelatedFeaturesWithFieldOptions(feature,{},Enums.QueryFeatureFieldsLoadAll)
                                       selectedTable.queryRelatedFeatures(feature)


                                   }


                               }
                               else
                               resolve()

                           })

    }



    function checkForMedia()
    {
        var isMediaPresent = false
        for(var p=0;p < popupDefinitions.length;p++)
        {
            var mk = popupDefinitions[p].media
            if(Object.keys(mk).length > 0)
            {
                isMediaPresent = true

                break;
            }

        }
        return isMediaPresent
    }

    function checkForLineFeature()
    {
        let isLineFeaturePresent = false
        for(let k=0;k< features.length; k++)
        {
            var _feature = features[k]
            if(_feature.geometry){
                var objectType = _feature.geometry["objectType"]
                if(objectType === "Polyline")
                {
                    isLineFeaturePresent = true
                    break
                }
            }

        }
        return isLineFeaturePresent
    }


    function checkRelatedRecords()
    {
        var relatedRecordsPresent = false

        for(var k=0;k< popupManagers.length;k++)
        {
            if(!relatedRecordsPresent && relatedFeatures[k] && relatedFeatures[k].length > 0)
            {
                //console.log("related records present")
                relatedRecordsPresent = true

                break;
            }

        }
        return relatedRecordsPresent
    }

    Timer {
        id: fetchAttachmentTimer
    }



    function startAttachmentTimer()
    {

        fetchAttachmentTimer.interval = features.length * 3000
        fetchAttachmentTimer.repeat = false
        fetchAttachmentTimer.triggered.connect(showAttachmentError)

        fetchAttachmentTimer.start();

    }
    function showAttachmentError()
    {
        if(!_getAttachmentCompleted)
        {
            _getAttachmentCompleted = true
            //toastMessage.show(strings.timedout_fetching_attachments,null,4000)
            getAttachmentCompleted()

        }
    }



    function checkIfAttachmentPresent(featurecount)
    {

        _getAttachmentCompleted = false
        attachqueryno = 0
        isAttachmentPresent = false

        isGetAttachmentRunning = true
        if(featurecount < features.length)
        {
            var attachmentListModel = features[featurecount].attachments;
            if(attachmentListModel){
                if(attachmentListModel.count > 0)
                {
                    isAttachmentPresent = true
                    if(!_getAttachmentCompleted)
                    {
                        _getAttachmentCompleted = true
                        getAttachmentCompleted()
                        return
                    }
                }
                else
                {
                    attachmentListModel.fetchAttachmentsStatusChanged.connect(function() {
                        if(attachmentListModel.fetchAttachmentsStatus === Enums.TaskStatusCompleted){
                            attachqueryno +=1

                            //checking if attachment is present in at least one feature identified
                            if(attachmentListModel.count > 0)
                            {
                                isAttachmentPresent = true
                                if(!_getAttachmentCompleted)
                                {
                                    _getAttachmentCompleted = true
                                    getAttachmentCompleted()
                                    return
                                }
                            }
                            if(attachqueryno <  features.length)
                            {
                                if (!isAttachmentPresent)
                                    checkIfAttachmentPresent(featurecount + 1)
                            }
                            else
                            {
                                if(!_getAttachmentCompleted)
                                {
                                    _getAttachmentCompleted = true
                                    getAttachmentCompleted()
                                }
                            }



                        }

                    }

                    )


                    startAttachmentTimer()
                    attachmentListModel.fetchAttachments()

                }

            }
            else
            {
                //console.log("attachments completed")
                isAttachmentPresent = false
                _getAttachmentCompleted = true
                getAttachmentCompleted()
            }

        }
        else
        {
            _getAttachmentCompleted = true
            getAttachmentCompleted()
        }



    }



    function populateIdentifyModel(popupManager,feature,currentFeatureIndex)
    {

        let _featTable = feature.featureTable
        contingencyValues.loadContingentValuesDefinition(_featTable)

        canDeleteFeature =_featTable.canDelete(feature)
        canEditGeometry = _featTable.canEditGeometry(feature)
        if(popupManager.showCustomHtmlDescription)
        {
            populateModelWithCustomHtml(popupManager)

        }
        else
        {
            if(!populateModelCompleted)
                populateModelWithVisibleFields(popupManager,feature,currentFeatureIndex)


        }
    }

    function populateModelWithVisibleFields(popupManager,feature,currentFeatureIndex)
    {
        let visiblefields = fields[currentFeatureIndex]//mapView.identifyProperties.fields[currentPageNumber-1]

        populateModel(feature,visiblefields,popupManager)

        populateModelCompleted  = true

    }

    function populateModel(feature1,visiblefields,popupManager)
    {

        attrListModel.clear()
        let popupModel = popupManager.displayedFields
        if (popupModel.count) {
            var attributeJson1 = feature1.attributes.attributesJson

            var _featuretable  = feature1.featureTable
            var fields = _featuretable.fields

            for(var key in visiblefields)
            {
                var field = visiblefields[key]
                var fldname = ""
                if(field.name)
                    fldname = field.name
                else
                    fldname = field.fieldName

                //check if it is an expression
                //if it is an expression then get it from popupManager
                var popupfieldVal = ""
                var exprfld = fldname.split('/')
                if(exprfld.length > 1)
                {
                    var expr =exprfld[1]
                    var exprResults = popupManager.evaluateExpressionsResults
                    for(var k = 0;k<popupManager.evaluateExpressionsResults.length;k++)
                    {
                        var exprobj = popupManager.evaluateExpressionsResults[k].popupExpression
                        if(exprobj.name === expr)
                        {
                            var val = popupManager.evaluateExpressionsResults[k].result

                            var _type = exprobj.returnType

                            if(_type === Enums.PopupExpressionReturnTypeNumber)
                                popupfieldVal = utilityFunctions.getFormattedFieldValue(val,field.fieldType)
                            else
                                popupfieldVal = val
                            fldname = exprobj.title
                            break;
                        }
                    }
                }

                //get the fieldValue from PopupManager if not populated
                if(!popupfieldVal)
                    popupfieldVal = getPopupFieldValue(popupManager,fldname)


                var _fieldVal = popupfieldVal
                //if not populated get it from attribute Json

                if(!_fieldVal)
                {

                    //var fieldValAttrJson = app.getCodedValue(fields,fldname,attributeJson1[fldname])
                    // _fieldVal = getFormattedFieldValue(fieldValAttrJson)
                    var fieldValAttrJson = utilityFunctions.getCodedValue(fields,fldname,attributeJson1[fldname])
                    var fldType =   field.fieldType//app.getFieldType(fields,key)
                    _fieldVal = utilityFunctions.getFormattedFieldValue(fieldValAttrJson,fldType)

                }

                var _fieldAlias = fldname
                var _fieldType = -1

                if(field.label)
                    _fieldAlias = field.label
                else if(field.alias)
                    _fieldAlias = field.alias
                if(field.type)
                    _fieldType = field.type

                var length = 0

                for(var k1 = 0;k1<fields.length;k1 ++)
                {
                    var fld = fields[k1]
                    if(fld.name === field.fieldName)
                        length = fld.length
                }

                // const fld = fields.filter(_fld => _fld.name === field.fieldName);



                attrListModel.append({
                                         "description":"",
                                         "label": _fieldAlias,
                                         "fieldValue": _fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",
                                         "fieldType":_fieldType,//field.type?field.type:Enums.FieldTypeText,
                                         "editedValue":_fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",
                                         "isEditable":field.editable,
                                         "length":length,//field.length,
                                         "canShowEditIcon":false,
                                         "canShowCalendarIcon":false,
                                         "canShowDomainIcon":false,
                                         "isValid":true


                                     })


            }


            //return popupManager.displayedFields
        } else {
            // This case handles map notes
            // var feature = mapView.identifyProperties.features[currentPageNumber-1]
            let attributeJson = feature1.attributes.attributesJson
            attrListModel.clear()
            if (attributeJson.hasOwnProperty("TITLE")) {
                if (attributeJson["TITLE"]) {
                    attrListModel.append({
                                             "label": "TITLE", //qsTr("Title"),
                                             "fieldValue": attributeJson["TITLE"].toString()
                                         })
                }
            }
            if (attributeJson.hasOwnProperty("DESCRIPTION")) {
                if (attributeJson["DESCRIPTION"]) {
                    attrListModel.append({
                                             "label": "DESCRIPTION", //qsTr("Description"),
                                             "fieldValue": attributeJson["DESCRIPTION"].toString()
                                         })
                }
            }
            if (attributeJson.hasOwnProperty("IMAGE_LINK_URL")) {
                if (attributeJson["IMAGE_LINK_URL"]) {
                    attrListModel.append({
                                             "label": "IMAGE_LINK_URL",
                                             "fieldValue": attributeJson["IMAGE_LINK_URL"].toString()
                                         })
                }
            }

        }

    }

    function getPopupFieldValue(popupManager,fieldName)
    {

        let _popupfield = popupManager.fieldByName(fieldName)
        var popupFieldFormat = ArcGISRuntimeEnvironment.createObject("PopupFieldFormat")
        popupFieldFormat.useThousandsSeparator = true;
        if ( popupManager.fieldType(_popupfield) === Enums.FieldTypeFloat32 || popupManager.fieldType(_popupfield) === Enums.FieldTypeFloat64 ){
            popupFieldFormat.decimalPlaces = 2;
        }
        //popupFieldFormat.decimalPlaces = 2
        if(_popupfield){
            _popupfield.format = popupFieldFormat
            let fieldVal = popupManager.fieldValue(_popupfield) !== null?popupManager.formattedValue(_popupfield):null
            return fieldVal
        }

        return null
    }





    function populateModelWithCustomHtml(popupManager)
    {
        attrListModel.clear()
        var customHtml = popupManager.customHtmlDescription

        var newHtmlText = utilityFunctions.getHtmlSupportedByRichText(customHtml,panelPage.width)


        attrListModel.append({
                                 "description": newHtmlText,
                                 "label":"",
                                 "fieldValue":"",
                                 "canShowEditIcon":false,
                                 "canShowCalendarIcon":false,
                                 "canShowDomainIcon":false



                             })

        populateModelCompleted = true


    }

    function getSubTypeObject(featureTypes, typeId)
    {
        for(let k=0;k < featureTypes.length; k++)
        {
            let _featureType = featureTypes[k]
            if(_featureType.typeId === typeId)
                return _featureType
        }
        return null
    }

    function getAllSymbolUrlsForLayer(layerName,layerId,geometryType)
    {
        let layerLegends = []

        for(let k=0;k< legendManager.unOrderedLegendInfos.count; k++)
        {
            let _legendItem = legendManager.unOrderedLegendInfos.get(k)
            if (_legendItem.layerName === layerName)//  && _legendItem.legendIndex === legendIndex)
            {
                let _modLegendItemItem = Object.assign({"geometryType":geometryType,"layerId":layerId},_legendItem)
                // _legendItem["geometryType"] = geometryType


                layerLegends.push(_modLegendItemItem)

            }

        }
        return layerLegends
    }

    function getLayerSymbolUrl(featureLayer,_feature,layerName)
    {

        let _featureTable =""
        if(!featureLayer && _feature)
            _featureTable = _feature.featureTable
        else if(featureLayer)
            _featureTable = featureLayer.featureTable

        if(_featureTable){
            let _tableName = _featureTable.name
            if(!_tableName){
                if(_featureTable.layer)
                    _tableName = _feature.featureTable.layer.name
            }


            if(_tableName){
                let legendIndex = 0
                let legendName = ""
                let _renderer = null
                if(_featureTable.layer)
                    _renderer = _featureTable.layer.renderer

                if(_renderer &&_renderer.fieldNames)
                {
                    let _fldname_renderer = _renderer.fieldNames[0]
                    legendName = _feature.attributes.attributeValue(_fldname_renderer)
                    let legendName_key =  utilityFunctions.getCodedValue(_featureTable.fields,_fldname_renderer,legendName)

                    for(let k=0;k< legendManager.unOrderedLegendInfos.count; k++)
                    {
                        let _legendItem = legendManager.unOrderedLegendInfos.get(k)
                        if (_legendItem.layerName === _tableName)
                        {

                            if (legendName_key > "" && _legendItem.name === legendName_key)
                                return _legendItem.symbolUrl


                        }

                    }
                }
                else
                {

                    let _featureTypes = _feature.featureTable.featureTypes
                    if(_featureTypes){
                        let _subtypeField = _feature.featureTable.typeIdField
                        let subtypevalue  = _feature.attributes.attributeValue(_subtypeField)
                        if(subtypevalue){
                            let _featureType = getSubTypeObject(_featureTypes, subtypevalue)//_featureTypes.filter(_feat => _feat.typeId === subtypevalue)//_featureTypes[subtypevalue]
                            legendName = _featureType.name
                        }

                    }


                    for(let k=0;k< legendManager.unOrderedLegendInfos.count; k++)
                    {
                        let _legendItem = legendManager.unOrderedLegendInfos.get(k)
                        if (_legendItem.layerName === layerName)//_tableName)//  && _legendItem.legendIndex === legendIndex)
                        {
                            if(_featureTypes && _featureTypes.length > 0){
                                if (legendName > "" && _legendItem.name === legendName)
                                    return _legendItem.symbolUrl
                            }
                            else if (_legendItem.legendIndex === legendIndex)
                            {
                                return _legendItem.symbolUrl
                            }


                        }

                    }
                }

                return null

            }
        }
        return null

    }

    function populateModelForNewFeature(layerId)
    {

        popupTitle = strings.kSelectType
        if(attrListModel.count === 0){

            //get the layer
            if(layerId){
                let lyr = layerManager.getLayerById(layerId)
                let _featureTable = lyr.featureTable
                if(_featureTable){
                    let _newfeature = _featureTable.createFeature()
                    _newfeature.geometry = sketchEditor.geometry
                    let _hasAttachments = _featureTable.hasAttachments
                    sketchEditorManager.createNewFeature(_newfeature,_hasAttachments)
                    let _subtype = sketchEditorManager.currentTypeName

                    currentFeature = _newfeature

                    featuresManager.populateModelForEditAttributesNewFeature(_featureTable,_newfeature,_subtype,attrListModel)
                }
            }
        }
    }

    function checkEditPermission()
    {
        let feature1 = identifyManager.features[identifyBtn.currentPageNumber-1]

        let portalItem = mapPage.portalItem
        let _portal = portalSearch.portal
        isEditable = featuresManager.checkEditPermissions(feature1,portalItem,_portal) //checkEditPermissions()

    }



    /* populates the model for the feature and updates the panelpage title */
    function populateFeaturesModel(currentPageNumber,currentFeatureIndex)
    {
        //console.log("populating populateFeaturesModel")
        attrListModel.clear()

        if(!currentPageNumber)
            currentPageNumber = 1
        if(!currentFeatureIndex)
            currentFeatureIndex = 0

        let feature1 = identifyManager.features[identifyBtn.currentPageNumber-1]
        currentFeature = feature1

        let popupManager = identifyManager.popupManagers[identifyBtn.currentPageNumber-1]//identifyManager.popupManagers[currentFeatureIndex]//[currentPageNumber-1]

        if(popupManager){
            if(popupManager.objectName)
            {

                layerName = popupManager.objectName.toString()
            }
            if(popupManager.title)
            {

                popupTitle = popupManager.title
            }
            else
                popupTitle = layerName

        }

        if(app.isInEditMode)
        {
            featuresManager.populateModelForEditAttributes(feature1,attrListModel,popupManager)
            exitEditModeInProgress = false
            //panelPage.populateModelForEditAttributes(identifyBtn.currentPageNumber)

        }
        else
        {
            attrListModel.clear()
            featureEditorTrackingInfo = null
            bindFeaturesModel(feature1,popupManager)

        }
        //let identifiedFeature = mapView.identifyProperties.features[currentPageNumber-1]
        let portalItem = mapPage.portalItem
        let _portal = portalSearch.portal
        let editPermissionPromise = featuresManager.checkEditPermissions(feature1,portalItem,_portal)
        //isEditable = featuresManager.checkEditPermissions(feature1,portalItem,_portal) //checkEditPermissions()

        editPermissionPromise.then(function(result){
            isEditable = result
            let symbolUrl = getLayerSymbolUrl(null,feature1,layerName)
            featureSymbol = symbolUrl
            featureChanged()

        }
        )



    }




    function bindFeaturesModel(feature,popupManager) {
        populateModelCompleted = false


        if(!app.isInEditMode)
        {
            try {

                if(identifyBtn.currentPageNumber > 0)
                    currentPageNumber = identifyBtn.currentPageNumber
                    currentFeatureIndex = mapView.identifyProperties.currentFeatureIndex


                if(popupManager)
                {
                    // let feature1 = identifyManager.features[mapView.identifyProperties.currentFeatureIndex]
                    let editorInfo = featuresManager.getEditorTrackingInfo(feature)
                    featureEditorTrackingInfo = editorInfo


                    if(popupManager.popup.popupDefinition.expressions)
                    {
                        popupManager.evaluateExpressionsStatusChanged.connect(function()
                        {
                            if(popupManager.evaluateExpressionsStatus === Enums.TaskStatusCompleted)
                            {
                                populateIdentifyModel(popupManager,feature,currentFeatureIndex)
                            }




                        })

                        popupManager.evaluateExpressions()
                    }
                    else
                    {
                        populateIdentifyModel(popupManager)

                    }

                }
            }catch (err) {
                // console.log("error")


            }
        }


    }

    //********************************** related Features functions **************************************//

    function populateRelatedFeaturesModel(currentPageNumber,currentlyEditedPageNumber)
    {
        var _relatedFeatures = relatedFeatures[currentPageNumber - 1]

        if(isInEditMode)
        {

            _relatedFeatures = relatedFeatures[currentlyEditedPageNumber - 1]
        }
        bindRelatedFeaturesModel(_relatedFeatures,relatedFeaturesModel,featureListModel,relatedattrListModel)
        if(relatedFeaturesModel.count === 1 && relatedFeaturesModel.get(0).features.count === 1)
        {
            let feat = relatedFeaturesModel.get(0).features.get(0)
            let editorInfo = feat.editorInfo
            featureEditorTrackingInfo = editorInfo
        }

    }

    function bindRelatedFeaturesModel (relatedFeatures,relatedFeaturesModel,featureListModel,relatedattrListModel) {

        getFeatureList(relatedFeatures,relatedFeaturesModel,featureListModel,relatedattrListModel)

    }


    //get the related features and associate with the main feature
    function getFeatureList(relatedFeatures,relatedFeaturesModel,featureListModel,relatedattrListModel)
    {
        relatedFeaturesModel.clear()

        let sortedFeatures =   getSortedRelatedFeatures(relatedFeatures,featureListModel)
        if(isInEditMode){
            populateEditableRelatedFeaturesWithFeatureCountOne(sortedFeatures,relatedattrListModel,relatedFeatures)
        }
        sortedFeatures.forEach(function(obj){

            relatedFeaturesModel.append((obj))
        }
        )

    }

    function populateEditableRelatedFeaturesWithFeatureCountOne(sortedFeatures,relatedattrListModel,relatedFeatures)
    {
        sortedFeatures.forEach(function(obj){
            if(obj.features.count === 1){
                let _feature = populateModelForRelatedEditAttributes(obj.serviceLayerName,obj.features.get(0).objectid,relatedFeatures)
                _feature.editFields = relatedattrListModel
                obj.editableFeature = _feature

            }

        })
    }

    function populateModelAfterEditForRelatedAttributes(editedFeature)
    {
        relatedattrListModel.clear()
        let feature1 =  editedFeature


        let subtypeField = feature1.featureTable.subtypeField

        let attributeJson1 = feature1.attributes.attributesJson

        let subtype_domain = []
        if(subtypeField)
        {
            let subtypeFieldValue = attributeJson1[subtypeField.toLowerCase()]
            if(!subtypeFieldValue)
                subtypeFieldValue = attributeJson1[subtypeField]
            subtype_domain = featuresManager.populateSubTypeDomains(feature1,subtypeFieldValue)
        }


        let _featuretable  = feature1.featureTable
        let fields = _featuretable.fields
        let noneditableFieldTypes = [3,8,9]
        for(var key in fields)
        {
            let field = fields[key]
            if(field && field.editable && noneditableFieldTypes.indexOf(field.fieldType) < 0 )
            {
                let fldname = ""
                if(field.name)
                    fldname = field.name
                else
                    fldname = field.fieldName

                //check if it is an expression
                //if it is an expression then get it from popupManager
                var popupfieldVal = ""
                var exprfld = fldname.split('/')

                //get the fieldValue from PopupManager if not populated
                //need to check if edit is disabled in popup
                //let isEditEnabledInPopup = isFieldEditable(popupManager,fldname)
                if(!(exprfld.length > 1) && field.editable)
                {

                    let fieldValAttrJson = utilityFunctions.getCodedValue(fields,fldname,attributeJson1[fldname])
                    let fldType =   field.fieldType//app.getFieldType(fields,key)
                    let _fieldVal = utilityFunctions.getFormattedFieldValue(fieldValAttrJson,fldType)

                    let _fieldAlias = fldname

                    if(field.label)
                        _fieldAlias = field.label
                    else if(field.alias)
                        _fieldAlias = field.alias

                    //get the domains if it has a domain

                    let {_nameValues,_codedValues,minValue,maxValue} =  featuresManager.populateDomainValues(field,feature1)

                    let length = 0

                    for(var k1 = 0;k1<fields.length;k1 ++)
                    {
                        let fld = fields[k1]
                        if(fld.name === field.fieldName || fld.name === field.name)
                            length = fld.length
                    }

                    //check if it is invalid based on contingentvalues
                    let fieldValidType  = featuresManager.getFieldValidType(feature1,fldname)



                    //if not check if is a domain field. domain can be at the field level or featuretypes level

                    relatedattrListModel.append({
                                                    "description":"",
                                                    "FieldName":fldname,
                                                    "label": _fieldAlias,
                                                    "FieldValue": _fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",
                                                    "fieldType":field.fieldType,
                                                    "editedValue":_fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",
                                                    "isEditable":field.editable,
                                                    "unformattedValue":attributeJson1[fldname] !== null?attributeJson1[fldname].toString():"",
                                                    "length":length,//field.length,
                                                    "domainName":_nameValues,
                                                    "domainCode":_codedValues,
                                                    "nullableValue":field.nullable,
                                                    "minValue":minValue,
                                                    "maxValue":maxValue,
                                                    "canShowEditIcon":_nameValues.length === 0 && field.fieldType !== Enums.FieldTypeDate,
                                                    "canShowCalendarIcon":field.fieldType === Enums.FieldTypeDate,
                                                    "canShowDomainIcon":_nameValues.length > 0,
                                                    "fieldValidType":fieldValidType


                                                })
                }

            }
        }


        return feature1
    }

    function getFeatureFromLayer(featclass,objectid,relatedFeatures)
    {
        let features =  relatedFeatures.filter(function(featObj) {
            return featObj.serviceLayerName === featclass;
        });

        if(features && features.length > 0)
        {
            let _featureObj =  features.filter(function(featureObj) {
                let objectid_fldname = featuresManager.getUniqueFieldName(featureObj["feature"].featureTable)
                let obj_id = featureObj["feature"].attributes.attributeValue(objectid_fldname)
                return obj_id === objectid;

            })
            let  feature1 = _featureObj[0].feature
            return feature1

        }

        return null


    }

    function populateModelForRelatedEditAttributes(featclass,objectid,relatedFeatures)
    {
        relatedattrListModel.clear()
        let feature1 =  null

        var features =  relatedFeatures.filter(function(featObj) {
            return featObj.serviceLayerName === featclass;
        });

        if(features && features.length > 0)
        {
            let _featureObj =  features.filter(function(featureObj) {

                let objectid_fldname = featuresManager.getUniqueFieldName(featureObj["feature"].featureTable)
                let obj_id = featureObj["feature"].attributes.attributeValue(objectid_fldname)
                return obj_id === objectid;
                // return featureObj.feature.attributes.attributeValue("OBJECTID") === objectid;

            });
            feature1 = _featureObj[0].feature
            let subtypeField = feature1.featureTable.subtypeField

            let attributeJson1 = feature1.attributes.attributesJson

            let subtype_domain = []
            if(subtypeField)
            {
                var subtypeFieldValue = attributeJson1[subtypeField.toLowerCase()]
                subtype_domain = featuresManager.populateSubTypeDomains(feature1,subtypeFieldValue)
            }


            let _featuretable  = feature1.featureTable
            let fields = _featuretable.fields
            let noneditableFieldTypes = [3,8,9]
            for(var key in fields)
            {
                let field = fields[key]
                if(field && field.editable && noneditableFieldTypes.indexOf(field.fieldType) < 0 )
                {
                    let fldname = ""
                    if(field.name)
                        fldname = field.name
                    else
                        fldname = field.fieldName

                    //check if it is an expression
                    //if it is an expression then get it from popupManager
                    var popupfieldVal = ""
                    var exprfld = fldname.split('/')

                    //get the fieldValue from PopupManager if not populated
                    //need to check if edit is disabled in popup
                    //let isEditEnabledInPopup = isFieldEditable(popupManager,fldname)
                    if(!(exprfld.length > 1) && field.editable)
                    {

                        let fieldValAttrJson = utilityFunctions.getCodedValue(fields,fldname,attributeJson1[fldname])
                        let fldType =   field.fieldType//app.getFieldType(fields,key)
                        let _fieldVal = utilityFunctions.getFormattedFieldValue(fieldValAttrJson,fldType)

                        let _fieldAlias = fldname

                        if(field.label)
                            _fieldAlias = field.label
                        else if(field.alias)
                            _fieldAlias = field.alias

                        //get the domains if it has a domain
                        let codedValues = []//field.domain
                        let nameValues = []
                        let minValue=0
                        let maxValue = 0

                        //check if the field is a subtype field
                        // var subtypeField = feature1.featureTable.subtypeField
                        if(subtypeField && subtypeField.toUpperCase() === fldname.toUpperCase())
                        {
                            let codedValues_subtypes = featuresManager.getSubtypes(feature1) //populateSubTypeDomains(feature1)
                            if(codedValues_subtypes.length > 0)
                            {
                                if(field.nullable)
                                {
                                    codedValues.push({"code":"None"})
                                    nameValues.push({"name":"None"})
                                }
                            }
                            codedValues_subtypes.forEach(element => {
                                                             codedValues.push({"code":element.code})
                                                             nameValues.push({"name":element.name})
                                                         }
                                                         )

                        }
                        else
                        {
                            if(field.domain)
                            {
                                //check if it is a range domain

                                if(field.domain.domainType === Enums.DomainTypeRangeDomain)
                                {
                                    minValue = field.domain.minValue
                                    maxValue = field.domain.maxValue
                                }
                                else
                                {
                                    let domainObj = field.domain.codedValues
                                    if(domainObj){
                                        if(domainObj.length > 0)
                                        {
                                            if(field.nullable)
                                            {
                                                codedValues.push({"code":"None"})
                                                nameValues.push({"name":"None"})
                                            }
                                        }

                                        for(var k=0;k<domainObj.length;k++)
                                        {

                                            codedValues.push({"code":domainObj[k].code})
                                            nameValues.push({"name":domainObj[k].name})
                                        }
                                    }

                                }

                            }
                            else
                            {
                                let domain = subtype_domain[field.name]
                                if(domain)
                                {
                                    codedValues = []
                                    nameValues = []

                                    let domainValues = domain.codedValues
                                    for(var k=0;k < domainValues.length;k++){
                                        let subtype = domainValues[k]
                                        {

                                            nameValues.push({"name":subtype.name})
                                            codedValues.push({"code":subtype.code})
                                        }
                                    }
                                }

                            }

                        }

                        let length = 0

                        for(var k1 = 0;k1<fields.length;k1 ++)
                        {
                            let fld = fields[k1]
                            if(fld.name === field.fieldName || fld.name === field.name)
                                length = fld.length
                        }

                        //check if it is invalid based on contingentvalues
                        let fieldValidType  = featuresManager.getFieldValidType(feature1,fldname)

                        //if not check if is a domain field. domain can be at the field level or featuretypes level

                        relatedattrListModel.append({
                                                        "description":"",
                                                        "FieldName":fldname,
                                                        "label": _fieldAlias,
                                                        "FieldValue": _fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",
                                                        "fieldType":field.fieldType,
                                                        "editedValue":_fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",
                                                        "isEditable":field.editable,
                                                        "unformattedValue":attributeJson1[fldname] !== null?attributeJson1[fldname].toString():"",
                                                        "length":length,//field.length,
                                                        "domainName":nameValues,
                                                        "domainCode":codedValues,
                                                        "nullableValue":field.nullable,
                                                        "minValue":minValue,
                                                        "maxValue":maxValue,
                                                        "canShowEditIcon":nameValues.length === 0 && field.fieldType !== Enums.FieldTypeDate,
                                                        "canShowCalendarIcon":field.fieldType === Enums.FieldTypeDate,
                                                        "canShowDomainIcon":nameValues.length > 0,
                                                        "fieldValidType":fieldValidType

                                                    })
                    }

                }
            }



        }

        return feature1
    }



    function getSortedRelatedFeatures(relatedFeaturesList,featureListModel)
    {
        let relatedFeatures = []

        if(relatedFeaturesList)
        {
            relatedFeaturesList.forEach(function(featureObj){
                let fclass = featureObj["serviceLayerName"]
                let displayField = featureObj["displayFieldName"]


                let fclassObject =  relatedFeatures.filter(function(featObj) {
                    return featObj.serviceLayerName === fclass;
                });
                if(fclassObject && fclassObject.length > 0)
                {
                    relatedFeatures.map(function(featObj) {
                        if (featObj["serviceLayerName"] === fclass)
                        {
                            let isPresent = false

                            if(!isPresent)
                            {
                                let feat = {}
                                feat["displayFieldName"] = displayField
                                feat["serviceLayerName"] = fclass
                                let fields = []

                                let _attributes = featureObj["feature"].attributes.attributeNames

                                if(featureObj["feature"].featureTable){
                                    let _fields = featureObj["feature"].featureTable.fields

                                    let feature1 = featureObj["feature"]
                                    let editorInfo = featuresManager.getEditorTrackingInfo(feature1)
                                    if(editorInfo){
                                        feat.isEditorTrackingEnabled = true
                                        feat.editorInfo = editorInfo
                                    }
                                    else
                                    {
                                        feat.isEditorTrackingEnabled = false
                                    }

                                    for(var k = 0;k<_fields.length;k++){

                                        var _field = {}
                                        var fld = _fields[k]
                                        let _value  = featureObj["feature"].attributes.attributeValue(fld.name)
                                        _field.FieldName = fld.name
                                        if(_value)
                                        {

                                            var fieldValAttrJson = utilityFunctions.getCodedValue(_fields,fld.name,_value)
                                            var fldType =   fld.fieldType
                                            var _fieldVal = utilityFunctions.getFormattedFieldValue(fieldValAttrJson,fldType)

                                            if(_fieldVal)
                                                _field.FieldValue = _fieldVal.toString()
                                            else
                                                _field.FieldValue = "null"

                                        }
                                        else
                                            _field.FieldValue = "null"
                                        fields.push(_field)


                                    }

                                    feat.fields = fields

                                    if(featureObj["geometry"])
                                        feat["geometry"] = featureObj["geometry"]
                                    else
                                        feat["geometry"] = ""

                                    let objectid_fldname = featuresManager.getUniqueFieldName(featureObj["feature"].featureTable)

                                    feat["objectid"] = featureObj["feature"].attributes.attributeValue(objectid_fldname)
                                    //feat["objectid"] = featureObj["feature"].attributes.attributeValue("OBJECTID")


                                    featObj.features.append(feat)
                                }

                            }
                        }
                    })
                }
                else
                {
                    fclassObject = {}
                    fclassObject["serviceLayerName"] = fclass
                    fclassObject["showInView"] = false

                    fclassObject.features =  featureListModel.createObject(parent);
                    let feat = {}

                    let fields = []

                    let _attributes = featureObj["feature"].attributes.attributeNames
                    if(featureObj["feature"].featureTable){
                        let _fields = featureObj["feature"].featureTable.fields

                        for(var k = 0;k<_fields.length;k++){
                            var fld = _fields[k]

                            var _field = {}
                            let _value  = featureObj["feature"].attributes.attributeValue(fld.name)
                            _field.FieldName = fld.name


                            var fieldValAttrJson = utilityFunctions.getCodedValue(_fields,fld.name,_value)
                            var fldType =   fld.fieldType//app.getFieldType(fields,key)
                            var _fieldVal = utilityFunctions.getFormattedFieldValue(fieldValAttrJson,fldType)

                            if(_fieldVal)
                                _field.FieldValue = _fieldVal.toString()
                            else
                                _field.FieldValue = "null"

                            fields.push(_field)


                        }

                        feat.fields = fields

                        feat["displayFieldName"] = displayField
                        feat["serviceLayerName"] = fclass
                        if(featureObj["geometry"])
                            feat["geometry"] = featureObj["geometry"]
                        else
                            feat["geometry"] = ""

                        let objectid_fldname = featuresManager.getUniqueFieldName(featureObj["feature"].featureTable)
                        feat["objectid"] = featureObj["feature"].attributes.attributeValue(objectid_fldname)
                        //feat["objectid"] = featureObj["feature"].attributes.attributeValue("OBJECTID")

                        //get the editor date
                        var attributesJson = featureObj["feature"].attributes.attributesJson
                        var editDate = featureObj["feature"].attributes.attributesJson["EditDate"]
                        var editor = featureObj["feature"].attributes.attributesJson["Editor"]

                        var editedDate = utilityFunctions.getTimeDiff(editDate)

                        let feature1 = featureObj["feature"]
                        let editorInfo = featuresManager.getEditorTrackingInfo(feature1)
                        if(editorInfo){
                            feat.isEditorTrackingEnabled = true
                            feat.editorInfo = editorInfo
                        }
                        else
                        {
                            feat.isEditorTrackingEnabled = false
                        }
                        fclassObject.features.append(feat)
                        relatedFeatures.push(fclassObject)
                    }

                }
            }
            )
        }


        return relatedFeatures
    }

    //This is for populating the details of related feature selected in the list under Related tab
    function populateRelatedDetailsObject(serviceLayerName,objectid,isEditorTrackingEnabled,editorInfo,displayFieldName,fields)
    {
        let relatedDetailsObj = {}
        featureEditorTrackingInfo  = null
        let _relatedFeatures = relatedFeatures[identifyBtn.currentPageNumber-1]
        if(app.isInEditMode)
        {

            var _feature = populateModelForRelatedEditAttributes(serviceLayerName,objectid,_relatedFeatures)

            relatedDetailsObj = {
                "model": relatedattrListModel,
                "feature" : _feature,
                "serviceLayerName" : serviceLayerName
            }

            if(_feature.featureTable.editable && _feature.featureTable.featureTableType === Enums.FeatureTableTypeServiceFeatureTable)
            {
                //check ownership-based access
                if(_feature.featureTable.canUpdate(_feature))
                    // identifyRelatedFeaturesViewlst.canEdit = _feature.featureTable.editable
                    relatedDetailsObj["canEdit"] = _feature.featureTable.editable

            }

        }
        else
        {
            relatedDetailsObj = {
                "model": fields,
                "serviceLayerName" : serviceLayerName
            }

            if(isEditorTrackingEnabled)
            {
                let  _editorInfo = editorInfo
                featureEditorTrackingInfo = _editorInfo
            }

        }

        relatedDetailsObj["headerText"] = serviceLayerName + " - " + displayFieldName




        return relatedDetailsObj

    }


    function showErrorMessage(editresult) {

        app.messageDialog.width = messageDialog.units(300)
        app.messageDialog.standardButtons = Dialog.Ok//Dialog.Cancel | Dialog.Yes
        app.messageDialog.show("",strings.error_while_saving.arg(editresult.error))
        exitEditModeInProgress = false
        busyIndicator.visible = false

    }


    function showSuccessfulMessage()
    {
        toastMessage.show(strings.successfully_saved,null,2000)
    }

    function applyEditsAfterDelete()
    {

        let _featuretable  = currentFeature.featureTable

        if (_featuretable.applyEditsStatus === Enums.TaskStatusCompleted) {
            // apply the edits to the service
            _featuretable.onApplyEditsStatusChanged.disconnect(applyEditsAfterDelete)

            if(_featuretable.applyEditsResult)
            {
                let editresult = _featuretable.applyEditsResult[0]
                if(editresult && editresult.error)
                {

                    console.log("error in deleting")
                }
                else
                {

                    featureDeleted()
                    toastMessage.show(strings.successfully_deleted,null,2000)


                }
            }



        }

    }

    function updateFeatureTableAfterDelete()
    {
        let _featuretable  = currentFeature.featureTable

        if(_featuretable.deleteFeatureStatus === Enums.TaskStatusCompleted)
        {
            _featuretable.deleteFeatureStatusChanged.disconnect(updateFeatureTableAfterDelete)
            _featuretable.applyEdits();

        }

        if(_featuretable.deleteFeatureStatus === Enums.TaskStatusErrored)
        {

            //featureDeleted()
            _featuretable.deleteFeatureStatusChanged.disconnect(updateFeatureTableAfterDelete)

            toastMessage.show(strings.failed_to_delete)
        }

    }


    function deleteCurrentFeature() {

        currentFeature = features[identifyBtn.currentPageNumber-1]
        app.messageDialog.width = messageDialog.units(300)
        app.messageDialog.standardButtons = Dialog.Cancel | Dialog.Yes

        app.messageDialog.show("",strings.delete_this_feature)

        app.messageDialog.connectToAccepted(function () {

            let _featuretable  = currentFeature.featureTable
            _featuretable.onApplyEditsStatusChanged.connect(applyEditsAfterDelete)
            _featuretable.deleteFeature(currentFeature);
            _featuretable.deleteFeatureStatusChanged.connect(updateFeatureTableAfterDelete)
        })
    }

}
