/*
This is to manage the drawing of the sketch in the map for both existing and new feature.

*/


import QtQuick 2.0
import QtQuick.Dialogs 1.2
import Esri.ArcGISRuntime 100.14
import "Stack.js" as SketchStack


Item {
    id:sketchEditorManager
    property   SketchEditor _sketchEditor
    property MapView _mapView
    property bool createMode : false
    property var featureEdited
    property var originalFeature
    // property bool sketchStarted:false
    property bool isSketchValid:false//_sketchEditor.isSketchValid()

    readonly property  string  startEdit:"startedit"
    readonly property  string  vertexSelected:"vertex_selected"
    readonly property  string  edit:"edit"
    readonly property  string  pan:"pan"
    readonly property  string  startNewFeature:"newFeatureStartEdit"
    readonly property  string  finishNewSketch:"finish_new_sketch"




    property string panIconPath:"../../MapViewer/images/panNP.svg"
    property string editIconPath:"../../MapViewer/images/pencilNP.svg"
    property string pointIconPath:"../../MapViewer/images/Feature-pointsNP.svg"
    property string lineIconPath:"../../MapViewer/images/Feature-polylineNP.svg"
    property string polygonIconPath:"../../MapViewer/images/Feature-polygonNP.svg"
    property string originalDefExpr:""

    property var undoStack
    property var redoStack
    property bool canUndo:false
    property bool canRedo:false
    property bool canDelete:_sketchEditor.selectedVertex !== null
    property string currentLayerName:""
    property string currentTypeName:""
    property string currentLayerId:""

    property string currentGeometryType:""
    property bool isSavingInProgress:false

    property var existingGeometry
    property var editableLayers:[]    //it will store objects of the form [layername] = [{subtype/lyrname,legendSwatch,geometryType}]
    //[layername,listOfSublyrs]
    property  int noOflayerItems:0
    property int selectedmeasurementUnitIndex:app.favoriteMeasurementUnits//captureType === "Point":0
    property string symbolUrl

    property string buttonaction:""
    property string captureType: "line"
    property int undoListCount:0
    property int redoListCount:0
    property int initialCount:0
    // property bool sketchStarted:false
    property bool startedEditing:false
    property int selectedDrawMode:editMode.sketch
    property alias _editMode:editMode

    // the new feature to be created is stored in newFeatureObject

    property var newFeatureObject:{
        "geometry":null,
        "notNullableFields":[],
        "feature":null,
        "fldAliasDic":({}),
        "hasAttachments":false
    }

    signal featureUpdated(var feature)
    signal showErrorMessage(var editresult)
    signal showSuccessMessage()
    signal hidePanelPage()

    property string symbolUrlCurrentFeature:""

    QtObject {
        id: editMode

        property int pan: 0
        property int sketch: 1

    }



    QueryParameters {
        id: attributequeryParameters
    }




    SimpleMarkerSymbol {
        id: primarysketchColorSymbol
        color: "#F89927"
        style: Enums.SimpleMarkerSymbolStyleCircle
        size: 18
        outline: SimpleLineSymbol {
            style: Enums.SimpleLineSymbolStyleSolid
            color: "#FFFFFF"
            width: app.units(2)
        }
    }

    SimpleFillSymbol {
        id: simpleSketchFillSymbol
        color: "transparent"
        style: Enums.SimpleFillSymbolStyleSolid

        SimpleLineSymbol {
            style: Enums.SimpleLineSymbolStyleSolid
            color: "cyan"
            width: app.units(2)
        }
    }

    SimpleLineSymbol {
        id: simpleSketchLineSymbol

        style: Enums.SimpleLineSymbolStyleSolid
        color: "cyan"
        width: app.units(2)
    }


    SketchEditConfiguration{
        id:_sketchEditConfiguration
        showMidVertices: true
    }

    Connections{
        target:_mapView
        function onMouseReleased(){
            if(isInShapeEditMode)
            {

                sketchEditorManager.buttonaction = ""
            }
        }
    }

    Connections{
        target:_sketchEditor

        function onGeometryChanged() {
            let _feature = null
            if(!_sketchEditor.geometry || _sketchEditor.geometry.empty)
                canDeleteSketchVertex = false

            if(isInShapeCreateMode)
            {
                _feature = null               
            }
            else
                _feature = identifyManager.features[identifyBtn.currentPageNumber - 1]

            isSketchValid = sketchEditor.isSketchValid()


            switch(buttonaction){
            case "undo":
            case "redo":
                //here undo and redo count count gets updated from undoredo control               
                if(buttonaction === "undo")
                {
                   undoListCount -=1
                   redoListCount +=1
                   }
                   else
                   {
                   undoListCount +=1
                   redoListCount -=1
                   }

                if(_sketchEditor.geometry && !_sketchEditor.geometry.empty && _sketchEditor.selectedVertex)
                    canDeleteSketchVertex = true
                else
                    canDeleteSketchVertex = false
                break
            case   "" :


                if(sketchEditor.geometry && !sketchEditor.geometry.empty)
                {
                    undoListCount +=1
                    redoListCount = 0
                    sketchEditorManager.resetRedoList()
                    sketchEditorManager.canRedo = false
                    if(sketchEditorManager.existingGeometry)
                        sketchEditorManager.addToUndoList(sketchEditorManager.existingGeometry,sketchEditor.selectedVertex)

                    //existing geometry stores the currentGeometry of the sketchEditor to be pushed
                    //into the stack when the geometry changes.
                    sketchEditorManager.existingGeometry = sketchEditor.geometry

                }               
                break

            case "reset":
                buttonaction = ""
                break

            }

            buttonaction = ""

        }


        function onSelectedVertexChanged() {
            canDelete = _sketchEditor.selectedVertex !== null
            if(_sketchEditor.geometry && !_sketchEditor.geometry.empty && _sketchEditor.selectedVertex)
                canDeleteSketchVertex = true
            else
                canDeleteSketchVertex = false
            //let _feature = identifyManager.features[identifyBtn.currentPageNumber - 1]

            mapView._sketchGraphicsOverlay.graphics.clear()

            if(!startedEditing)
                startedEditing = true
        }

    }


    function turnOffDelete()
    {

        sketchEditorManager.canDelete = false

    }

    function turnOnDelete()
    {
        sketchEditorManager.canDelete = _sketchEditor.selectedVertex !== null
    }


    //gets the name of the field from field alias . @fldname is the alias
    function getFieldNameFromAlias(dicObject,fldname)
    {
        let _value = null
        for (const [key, value] of Object.entries(dicObject)) {
            if(value === fldname)
                _value = key
        }
        return _value
    }


    //checks if all the required fields are entered before saving the feature
    function getFeatureValidStatus()
    {
        let isValid = true
        let nullFields = ""
        let fieldsNotNullable = newFeatureObject["notNullableFields"]
        let currentFeature = newFeatureObject["feature"]

        for(let k=0;k<fieldsNotNullable.length; k++)
        {
            let _fldaliasname = fieldsNotNullable[k]
            let _fldname = getFieldNameFromAlias(newFeatureObject["fldAliasDic"],_fldaliasname)
            if(!_fldname)
                _fldname = _fldaliasname

            let _fldVal = currentFeature.attributes.attributeValue(_fldname)
            if(_fldVal === null || typeof _fldVal === "undefined" || (typeof _fldVal === "string" && !_fldVal.trim() > "")){
                isValid = false
                nullFields = newFeatureObject["fldAliasDic"][_fldname]
                break;
            }
        }

        return {status:isValid,inValidFields:nullFields}

    }

    function createNewFeature(newFeature,hasAttachments)
    {
        newFeatureObject = {
            "geometry":null,
            "notNullableFields":[],
            "feature":newFeature,
            "fldAliasDic":({}),
            "hasAttachments":hasAttachments
        }
    }

    //checks if a name is a featureType
    function isPresentInFeatureTypes(_featureTable,typeid)
    {
        let featureTypes = _featureTable.featureTypes
        for(let k=0;k<featureTypes.length;k++)
        {
            let _type = featureTypes[k]
            let _template = _type.templates

            if((_type.name === typeid) || (typeid === _template[0].name))
                return true
        }
        return false

    }


    // gets the list of editable layers to show in the Add New Feature. First we check if legend is configured based on feature Type
    //then we check if it has feature templates. If the legend is configured
    //based on featureType we get the names from the legend list. else we configure based on featureTemplates. display the FeatureTypes
    //and for the symbol we show the symbol corresponding to the first symbol configured in the legend
    //which can be the first item in the domain
    function addLayerToEditableLayers(layer,editableLayerList)
    {

        try{

            if(layer.visible && layer.featureTable && layer.featureTable.editable)
            {
                let _featTable = layer.featureTable
                _featTable.featureRequestMode = Enums.FeatureRequestModeOnInteractionNoCache

                if(_featTable  && _featTable.canAdd()){
                    let cvd = _featTable.contingentValuesDefinition
                    cvd.load()

                    let _geometryType = layer.featureTable.geometryType
                    //get all the symbols configured in legend
                    let symbolItemArray = identifyManager.getAllSymbolUrlsForLayer(layer.name,layer.layerId,_geometryType)
                    //check if the renderer field is same as featureType
                    let featureTypeId = layer.featureTable.typeIdField
                    //renderer can be based on a field or on an expression
                    let rendererField = ""
                    if(layer.renderer)
                        rendererField = layer.renderer ? (layer.renderer.fieldNames ?layer.renderer.fieldNames[0]:"") : ""


                    let islegBasedOnFeatureType = false
                    if(featureTypeId !== rendererField)
                        islegBasedOnFeatureType = isLegendConfiguredForFeatureType(symbolItemArray,layer.featureTable.featureTypes)
                    let symbolAdded = false
                    if((featureTypeId === rendererField )  || islegBasedOnFeatureType || !featureTypeId || featureTypeId === "")
                    {

                        if(featureTypeId > "")
                        {
                            //it is a featureType field and legend is also based on featureType
                            //add the corresponding  symbols for featureTypes
                            let modsymbols = []
                            for (let k=0; k<symbolItemArray.length; k++)
                            {
                                let _symItem = symbolItemArray[k]
                                let isFeatureType = isPresentInFeatureTypes(layer.featureTable,_symItem.name)
                                if(isFeatureType)
                                    modsymbols.push(_symItem)

                            }
                            noOflayerItems += modsymbols.length
                            if(modsymbols.length > 0)
                            {
                                symbolAdded = true
                                editableLayerList.push({
                                                           "name":layer.name,"id":layer.layerId,"geometryType":_geometryType,"symbols":modsymbols})
                            }
                        }

                        if(!symbolAdded)
                        {
                            // if symbols for featuretypes not found above add the default legend symbol
                            if(_featTable.featureTemplates.length)
                            {
                                let _featureTypesymbols = []
                                for(let p=0;p<_featTable.featureTemplates.length; p++)
                                {
                                    let _type = _featTable.featureTemplates[p]
                                    let _typeName = _type.name



                                    let _newFeatureItemSymbol = {
                                        "name":_typeName,//_type.name,
                                        "symbolUrl":symbolItemArray[0].symbolUrl,
                                        "legFieldValue":symbolItemArray[0].name,
                                        "legFieldName":rendererField,
                                        "layerName":layer.name,
                                        "layerId":layer.layerId,
                                        "geometryType":_geometryType


                                    }
                                    _featureTypesymbols.push(_newFeatureItemSymbol)


                                }
                                noOflayerItems += _featureTypesymbols.length
                                if(_featureTypesymbols.length > 0){

                                    editableLayerList.push({
                                                               "name":layer.name,"id":layer.layerId,"geometryType":_geometryType,"symbols":_featureTypesymbols})

                                    symbolAdded = true
                                }

                            }
                            //check for featureTemplates
                            else
                            {


                                if(symbolItemArray.length > 0 && featureTypeId === "")
                                {
                                    noOflayerItems += symbolItemArray.length
                                    symbolAdded = true

                                    editableLayerList.push({
                                                               "name":layer.name,"id":layer.layerId,"geometryType":_geometryType,"symbols":symbolItemArray})
                                }
                            }
                        }
                    }
                    if(!symbolAdded)
                    {
                        //it must have featureTypes and the featureTypeID is not the renderer field
                        //legend not based on featureType. So need to create the fetauretype legend
                        //get the symbol of the first legend
                        let _featSymbolArray = null
                        let _featureTypesymbols = []
                        if(symbolItemArray.length > 0)
                        {
                            let firstDomainValue = getFirstDomainValue(_featTable, rendererField)

                            //get the symbol for the first domain value in the field for which the legend is configured
                            if(firstDomainValue)
                            {
                                _featSymbolArray = symbolItemArray.filter(obj => obj.name === firstDomainValue)

                            }                            
                            if(!_featSymbolArray || _featSymbolArray.length === 0)
                            {
                                _featSymbolArray = symbolItemArray
                            }

                        }
                        for(let x=0;x<_featTable.featureTypes.length; x++)
                        {
                            let _type = _featTable.featureTypes[x]
                            let _typeName = _type.name

                            let _template = _type.templates
                            if(_template && _template[0] && _template[0].name)
                                _typeName = _template[0].name

                            let _newFeatureItemSymbol = {
                                "name":_typeName,//_type.name,
                                "symbolUrl":_featSymbolArray[0].symbolUrl,
                                "legFieldValue":_featSymbolArray[0].name,
                                "legFieldName":rendererField,
                                "layerName":layer.name,
                                "layerId":layer.layerId,
                                "geometryType":_geometryType
                            }
                            _featureTypesymbols.push(_newFeatureItemSymbol)
                        }

                        noOflayerItems += _featureTypesymbols.length

                        editableLayerList.push({
                                                   "name":layer.name,"id":layer.layerId,"geometryType":_geometryType,"symbols":_featureTypesymbols})

                    }
                }

            }
        }
        catch(ex)
        {
            console.log("error in layer:",ex.toString())
        }

    }


    // get the list of editable layers
    function getEditableLayerList()
    {
        let editableLayerList = []
        let featureLayers = mapView.map.operationalLayers
        let canFilterVisible = true

        for (var i=featureLayers.count -1; i>=0; i--) {
            var layer = featureLayers.get(i)
            //check if the layer is visible
            if(layer.objectType !== "GroupLayer")
            {

                addLayerToEditableLayers(layer,editableLayerList)

            }
            else
            {
                processGroupLayer(layer,editableLayerList)
            }

        }

        return editableLayerList
    }



    function processGroupLayer(layer,editableLayerList)
    {
        if(layer.subLayerContents.length)
        {
            for(var x=layer.subLayerContents.length - 1;x >= 0;x--){
                processGroupLayer(layer.subLayerContents[x],editableLayerList)
            }
        }
        else
            addLayerToEditableLayers(layer,editableLayerList)

    }





    // gets the first domain value for the legend field in case the legend is based on a field
    //other than feature Type. This is to show the symbol for the feature types in the feature type list  under Add new feature
    function getFirstDomainValue(_featTable, rendererField)
    {
        let _fields = _featTable.fields
        for(let k=0; k < _fields.length; k++)
        {
            let _field = _fields[k]
            if(_field.name === rendererField)
            {
                let flddomain = _field.domain
                let _codedVal = flddomain.codedValues
                if(_codedVal)
                    return _codedVal[0].name
            }
        }
        return null
    }

    //need to check if legend is configured based on featureTypes. If not
    //then need to get the symbol for the first domain value if the renderer field is a domain field
    //else just use the default symbol. It is used in the  display of the list of featuretypes against which the user
    //can create new feature

    function isLegendConfiguredForFeatureType(symbolItemArray,featureTypes)
    {
        let ispresent = false
        for(let p = 0;p< featureTypes.length; p++)
        {
            let _feattype = featureTypes[0]
            let ispresent = false
            for(let k=0; k<symbolItemArray.length;k++)
            {
                let legsymbol = symbolItemArray[k]
                let _legname = legsymbol.name
                if(_feattype.name === _legname)
                    ispresent = true
            }
            if(!ispresent)
                return false

        }
        return true

    }

    function getSubTypes(layer)
    {
        let subtypeNames = []

        let subtypes = layer.featureTable.featureSubtypes
        for(var k=0;k<subtypes.length;k++){
            let subtype = subtypes[k]
            subtypeNames.push({"name":subtype.name,"code":subtype.code})
        }
        return subtypeNames
    }



    function pauseSketchEditor()
    {
        //get the renderer of the layer

        const graphic = ArcGISRuntimeEnvironment.createObject("Graphic",{geometry: _sketchEditor.geometry});

        if(!isInShapeCreateMode)
        {
            let _renderer = featureEdited.featureTable.layer.renderer
            let _symbol = _renderer.symbolForFeature(featureEdited)
            graphic.symbol = _symbol
        }
        else
        {
            if(_sketchEditor.geometry.objectType === "Point")

                graphic.symbol = primarysketchColorSymbol
            else if(_sketchEditor.geometry.objectType === "Polygon")
                graphic.symbol = simpleSketchFillSymbol
            else
                graphic.symbol = simpleSketchLineSymbol
        }
        _mapView._sketchGraphicsOverlay.graphics.clear()
        _mapView._sketchGraphicsOverlay.graphics.append(graphic)
        _sketchEditor.stop()

    }

    function restartSketchEditor()
    {
        // _sketchEditor.startWithGeometry(featureEdited.geometry)
        let editedGeom = _mapView._sketchGraphicsOverlay.graphics.get(0)
        if(editedGeom)
        existingGeometry = editedGeom.geometry
        //isInPanMode = false
        sketchEditorManager.selectedDrawMode = sketchEditorManager._editMode.sketch

        //featureEdited.geometry
        if(existingGeometry.objectType === "Polygon")
        {
            _sketchEditor.startWithGeometryCreationModeAndEditConfiguration(existingGeometry,Enums.SketchCreationModePolygon,_sketchEditConfiguration)
        }
        else if(existingGeometry.objectType === "Point")

            _sketchEditor.startWithGeometry(existingGeometry)

        else
            _sketchEditor.startWithGeometryCreationModeAndEditConfiguration(existingGeometry,Enums.SketchCreationModePolyline,_sketchEditConfiguration)

        if(!isInShapeCreateMode)
        {
            let lyrid = featureEdited.featureTable.layer.layerId

            setSymbolForSketch(lyrid)
        }

        if(existingGeometry.objectType !== "Point")
            _mapView._sketchGraphicsOverlay.graphics.clear()

    }

    //used to set the vertex size
    function setSymbolForSketch(lyrid)
    {
        if(featureEdited.geometry.objectType === "Point")
        {
            primaryColorSymbol.size = 12
        }
        else
            primaryColorSymbol.size = 16

    }



    function startSketchEditorForNewSketch(geometryType,layerName,layerId,subtype)
    {
        _mapView._sketchGraphicsOverlay.graphics.clear()
        currentLayerName = layerName
        currentTypeName = subtype
        currentLayerId = layerId
        //sketchStarted = true
        SketchStack.clear()
        undoListCount = 0
        redoListCount = 0
        existingGeometry = null
        //initMessageDisplayCount()
        canUndo = false
        canRedo =false
        sketchEditorManager.selectedDrawMode = sketchEditorManager._editMode.sketch
        //isInPanMode = false

        switch(geometryType){
        case Enums.GeometryTypePoint:
            currentGeometryType = "Point"
            _sketchEditor.startWithCreationModeAndEditConfiguration(Enums.SketchCreationModePoint,_sketchEditConfiguration)
            break;
        case Enums.GeometryTypePolygon:
            currentGeometryType = "Polygon"
            _sketchEditor.startWithCreationModeAndEditConfiguration(Enums.SketchCreationModePolygon,_sketchEditConfiguration)
            break;
        case Enums.GeometryTypePolyline:
            currentGeometryType = "Polyline"
            _sketchEditor.startWithCreationModeAndEditConfiguration(Enums.SketchCreationModePolyline,_sketchEditConfiguration)
            break

        }

    }

    //start the sketch editor if paused while still in edit mode for panning or zooming
    //need to reset the sketch geometry
    function startSketchEditor(feature)
    {
        _mapView._sketchGraphicsOverlay.graphics.clear()
        //isInPanMode = false
        sketchEditorManager.selectedDrawMode = sketchEditorManager._editMode.sketch

        featureEdited = feature
        existingGeometry = featureEdited.geometry
        currentGeometryType = featureEdited.geometry.objectType

        if(featureEdited && featureEdited.geometry){
            if(featureEdited.geometry.objectType === "Polygon")
            {
                featureEdited.featureTable.layer.clearSelection()

                _sketchEditor.startWithGeometryCreationModeAndEditConfiguration(featureEdited.geometry,Enums.SketchCreationModePolygon,_sketchEditConfiguration)
                initialCount = _sketchEditor.geometry.parts.part(0).pointCount
            }

            else  if(featureEdited.geometry.objectType === "Point")
            {
                _sketchEditor.startWithGeometry(featureEdited.geometry)
            }
            else
            {
                featureEdited.featureTable.layer.clearSelection()
                //_sketchEditor.startWithGeometry(featureEdited.geometry)
                _sketchEditor.startWithGeometryCreationModeAndEditConfiguration(featureEdited.geometry,Enums.SketchCreationModePolyline,_sketchEditConfiguration)
                initialCount = _sketchEditor.geometry.parts.part(0).pointCount
            }



        }

        //update the definition query
        let lyrid = feature.featureTable.layer.layerId
        if(featureEdited.geometry.objectType === "Point")
        {
            //setFeatureVisibility(lyrid,feature,true)
        }
        else
        {
            primaryColorSymbol.color = mapView.measureSymbolColor
            setFeatureVisibility(lyrid,feature,false)
        }

        setSymbolForSketch(lyrid)


        undoStack = SketchStack.init()
        updateUndoRedoList()

    }

     function setFeatureVisibility(layerId, feature,visibility)
    {

        for (var i=0; i< _mapView.map.operationalLayers.count; i++) {
            var layer = _mapView.map.operationalLayers.get(i)
            if(layer && layer.layerId === layerId)
                layer.setFeatureVisible(feature,visibility)
        }
    }

    function addToUndoList(geometry,_sketchVertex){

        SketchStack.addToUndoList({"geometry":geometry, "selectedVertex":_sketchVertex})
        updateUndoRedoList()

    }

    function resetUndoRedoList()
    {
        SketchStack.init()
    }

    function addToRedoList(geometry,_sketchVertex){

        SketchStack.addToRedoList({"geometry":geometry, "selectedVertex":_sketchVertex})
        updateUndoRedoList()

    }

    function resetRedoList()
    {
      SketchStack.redoList = []
    }


    function removeFromUndoList()
    {
        let sketchObject = SketchStack.removeFromUndoList()
        let _geom = null
        if(sketchObject && sketchObject.geometry)
        {
            _geom = sketchObject.geometry

        }
        updateUndoRedoList()

        return _geom

    }

    function removeFromRedoList()
    {
        let sketchObject = SketchStack.removeFromRedoList()
        let _geom = null
        if(sketchObject && sketchObject.geometry)
        {
            //SketchStack.addToUndoList({"geometry":sketchObject.geometry,"selectedVertex":null})
            _geom = sketchObject.geometry

        }

        updateUndoRedoList()
        return _geom
    }

    function updateUndoRedoList()
    {
        let _redolength = SketchStack.sizeRedoList()
        canRedo = _redolength > 0
        let _undolength = SketchStack.sizeUndoList()
        canUndo = _undolength > 0        
    }

    function isEmpty()
    {
        return  SketchStack.isEmpty()
    }

    function clear()
    {
        SketchStack.clear()
    }

    //this is called for saving the geometry of existing feature
    function resetDefinitionQueryAndSaveEdits()
    {
        let lyrid = featureEdited.featureTable.layer.layerId
        saveEdits()

    }
    //if the geometry of the sketcheditor is null then that means the user has clicked the Apply buttton
    //when the skecthEditor is paused. In that case we have to get the geometry from the
    //graphics overlay

    function saveEdits()
    {
        let geom = _sketchEditor.geometry
        if(!geom)
        {
            let _graphic = _mapView._sketchGraphicsOverlay.graphics.get(0)
            geom = _graphic.geometry
        }

        featureEdited.geometry = geom
        saveGeometry_object()
        _mapView._sketchGraphicsOverlay.graphics.clear()

    }

    function resetSketchEditor()
    {
        _mapView._sketchGraphicsOverlay.graphics.clear()
        canUndo = false
        canRedo = false
        SketchStack.clear()
        existingGeometry = featureEdited ? featureEdited.geometry : null

        if(featureEdited && featureEdited.geometry){
            _sketchEditor.stop()
            if(featureEdited.geometry.objectType === "Polygon")
            {
                featureEdited.featureTable.layer.clearSelection()
                //_sketchEditor.startWithGeometry(featureEdited.geometry)
                _sketchEditor.startWithGeometryCreationModeAndEditConfiguration(featureEdited.geometry,Enums.SketchCreationModePolygon,_sketchEditConfiguration)
                initialCount = _sketchEditor.geometry.parts.part(0).pointCount
            }

            else  if(featureEdited.geometry.objectType === "Point")
            {
                _sketchEditor.startWithGeometry(featureEdited.geometry)
            }
            else
            {
                featureEdited.featureTable.layer.clearSelection()
                //_sketchEditor.startWithGeometry(featureEdited.geometry)
                _sketchEditor.startWithGeometryCreationModeAndEditConfiguration(featureEdited.geometry,Enums.SketchCreationModePolyline,_sketchEditConfiguration)
                initialCount = _sketchEditor.geometry.parts.part(0).pointCount
            }

        }

        if(featureEdited)
        {
            let lyrid = featureEdited.featureTable.layer.layerId
            setSymbolForSketch(lyrid)
        }
        else
            resetNewSketch()

        updateUndoRedoList()

    }

    function resetNewSketch()
    {
        _sketchEditor.stop()
        //sketchStarted = true
        SketchStack.clear()
        existingGeometry = null
        //initMessageDisplayCount()
        canUndo = false
        canRedo =false
        sketchEditorManager.selectedDrawMode = sketchEditorManager._editMode.sketch
        //isInPanMode = false
        switch(currentGeometryType){
        case "Point":

            _sketchEditor.startWithCreationModeAndEditConfiguration(Enums.SketchCreationModePoint,_sketchEditConfiguration)
            break;
        case "Polygon":

            _sketchEditor.startWithCreationModeAndEditConfiguration(Enums.SketchCreationModePolygon,_sketchEditConfiguration)
            break;
        case "Polyline":

            _sketchEditor.startWithCreationModeAndEditConfiguration(Enums.SketchCreationModePolyline,_sketchEditConfiguration)
            break
        }

    }

    function clearSketch()
    {
        _mapView._sketchGraphicsOverlay.graphics.clear()
        canUndo = false
        canRedo = false
        SketchStack.clear()

        updateUndoRedoList()

    }

    function stopSketchEditor()
    {
        if(_sketchEditor.started){
            _sketchEditor.stop();
            resetUndoRedoList()
            isInShapeEditMode = false
            createMode = false;
            if(featureEdited && featureEdited.featureTable)
                featureEdited.featureTable.layer.selectFeature(featureEdited)
        }

    }

    function  applyEdits(){
        let _featureTable = featureEdited.featureTable
        if (_featureTable.applyEditsStatus === Enums.TaskStatusCompleted) {
            // apply the edits to the service

            if(_featureTable.applyEditsResult)
            {
                let editresult = _featureTable.applyEditsResult[0]
                if(editresult && editresult.error)
                {

                    //console.log("error in editing")
                    measureToast.toVar = parent.height - measureToast.height
                    measureToast.show("%1:%2".arg(strings.error).arg(editresult.error.toString()), parent.height-measureToast.height, 1500)

                }
                else
                {
                    _featureTable.onApplyEditsStatusChanged.disconnect(applyEdits)

                    featureUpdated(featureEdited)


                    sketchGraphicsOverlay.graphics.clear()
                    stopSketchEditor()
                    let lyrid = _featureTable.layer.layerId
                    setFeatureVisibility(lyrid,featureEdited,true)

                    let uniqueFieldName = featuresManager.getUniqueFieldName(_featureTable)
                    let attrVal = featureEdited.attributes.attributeValue(uniqueFieldName)
                    let _querystr = `${uniqueFieldName} = ${attrVal}`

                    let promiseToQuery = queryFeatures(_querystr, _featureTable)

                    promiseToQuery.then(function(result){
                        const features = Array.from(result.iterator.features);
                        //construct the popup
                        var popupDefinition = identifyManager.popupDefinitions[identifyBtn.currentPageNumber - 1]//identifyLayerResult.layerContent.popupDefinition
                        if(!popupDefinition)
                            popupDefinition = ArcGISRuntimeEnvironment.createObject("PopupDefinition", {initGeoElement: features[0]})


                        var popUp = ArcGISRuntimeEnvironment.createObject("Popup", {initGeoElement: features[0], initPopupDefinition: popupDefinition})
                        var popupManager = ArcGISRuntimeEnvironment.createObject("PopupManager", {popup: popUp})
                        identifyManager.popupManagers[identifyBtn.currentPageNumber - 1] = popupManager
                        identifyManager.features[identifyBtn.currentPageNumber - 1] = features[0]
                        identifyManager.populateFeaturesModel(identifyBtn.currentPageNumber,_mapView.identifyProperties.currentFeatureIndex)


                    }).catch(error => {
                                 //console.error("error occurred",error.message)
                                 measureToast.toVar = parent.height - measureToast.height
                                 measureToast.show("%1:%2".arg(strings.error).arg(error.message), parent.height-measureToast.height, 1500)

                             })


                }
            }
            else
            {

                _featureTable.onApplyEditsStatusChanged.disconnect(applyEdits)
                toastMessage.show(strings.successfully_saved,null,2000)

            }


        }
    }

    function  updateFeature(){
        let _featureTable = featureEdited.featureTable

        if (_featureTable.updateFeatureStatus === Enums.TaskStatusCompleted) {

            // apply the edits to the service
            _featureTable.onUpdateFeatureStatusChanged.disconnect(updateFeature)
            _featureTable.applyEdits();
        }
        if (_featureTable.updateFeatureStatus === Enums.TaskStatusErrored) {

            //console.log("errored")
            var errorObj = {}
            errorObj.error = _featureTable.error.message
            _featureTable.onUpdateFeatureStatusChanged.disconnect(updateFeature)
            // showErrorMessage(errorObj)
        }
    }

    // this is called for saving existing feature
    function saveGeometry_object()
    {
        let isEdited = false
        let _featuretable  = featureEdited.featureTable
        _featuretable.onApplyEditsStatusChanged.connect(applyEdits)
        _featuretable.onUpdateFeatureStatusChanged.connect(updateFeature)
        _featuretable.updateFeature(featureEdited);
    }

    function isGeometryEdited(feature)
    {
        if(feature === null && _sketchEditor.geometry != null)
            return true
        else if(feature === null && _sketchEditor.geometry === null)
            return false
        else
        {
            let isNotEdited = GeometryEngine.equals(feature.geometry,_sketchEditor.geometry)
            return !isNotEdited
        }
    }


    function queryFeatures(searchString, table){
        return new Promise((resolve, reject)=>{
                               let taskId;
                               if(searchString > ""){
                                   attributequeryParameters.whereClause = searchString;
                               } else{
                                   attributequeryParameters.whereClause = "";
                               }
                               const featureStatusChanged = ()=> {
                                   switch (table.queryFeaturesStatus) {
                                       case Enums.TaskStatusCompleted:
                                       table.queryFeaturesStatusChanged.disconnect(featureStatusChanged);
                                       const result = table.queryFeaturesResults[taskId];
                                       if (result) {
                                           //spatialQueryTimer.stop()
                                           resolve(result);
                                       } else {
                                           reject({message: strings.no_query_result, taskId: taskId});
                                       }
                                       break;
                                       case Enums.TaskStatusErrored:
                                       table.queryFeaturesStatusChanged.disconnect(featureStatusChanged);
                                       attributequeryParameters.whereClause = "";

                                       if (table.error) {
                                           reject(table.error);
                                       } else {
                                           reject({message: table.tableName + ": " + strings.query_task_error});
                                       }
                                       break;

                                       default:
                                       break;
                                   }
                               }

                               table.queryFeaturesStatusChanged.connect(featureStatusChanged);
                               if(table.queryFeaturesWithFieldOptions)
                               taskId = table.queryFeaturesWithFieldOptions(attributequeryParameters, Enums.QueryFeatureFieldsLoadAll);
                               else
                               taskId = table.queryFeatures(attributequeryParameters);

                           });
    }

    function applyFeatureEdits()
    {
        let _currentFeature = newFeatureObject["feature"]
        _currentFeature.geometry = _sketchEditor.geometry

        let  _featTable = _currentFeature.featureTable

        if (_featTable.applyEditsStatus === Enums.TaskStatusCompleted) {
            // apply the edits to the service
            _featTable.onApplyEditsStatusChanged.disconnect(applyFeatureEdits)

            if(_featTable.applyEditsResult)
            {
                let editresult = _featTable.applyEditsResult[0]
                if(editresult && editresult.error)
                {
                    showErrorMessage(editresult)
                    //console.log("error in editing")
                    savingInProgress = false
                }
                else
                {
                    savingInProgress = false

                    showSuccessMessage()

                    clearSketch()

                    _mapView.setViewpointCenter(_currentFeature.geometry.extent.center)

                }
            }
            else
            {
                showSuccessMessage()
                savingInProgress = false

            }

        }

        if (_featTable.applyEditsStatus === Enums.TaskStatusErrored){
            _featTable.onApplyEditsStatusChanged.disconnect(applyFeatureEdits)
            var errorObj = {}
            errorObj.error = _featTable.error.message
            showErrorMessage(errorObj)
            savingInProgress = false
        }

    }


    //saving new sketch
    function saveCurrentFeature()
    {

        if(!savingInProgress)
        {
            savingInProgress = true
            //editBusyIndicator.visible = true

            let _currentFeature = newFeatureObject["feature"]
            _currentFeature.geometry = _sketchEditor.geometry

            let  _featTable = _currentFeature.featureTable

            _featTable.onApplyEditsStatusChanged.connect(applyFeatureEdits)

            _featTable.onAddFeatureStatusChanged.connect(function(){
                if (_featTable.addFeatureStatus === Enums.TaskStatusCompleted) {
                    // apply the edits to the service
                    _featTable.applyEdits();

                }
                if (_featTable.addFeatureStatus === Enums.TaskStatusErrored) {
                    var errorObj = {}
                    errorObj.error = _featTable.error.message
                    showErrorMessage(errorObj)
                    savingInProgress = false
                }
            }
            )

            if(_featTable.addFeatureStatus === Enums.TaskStatusReady || _featTable.addFeatureStatus === Enums.TaskStatusCompleted || Enums.TaskStatusErrored)
            {
                _featTable.addFeature(_currentFeature)
            }

        }

    }

}
