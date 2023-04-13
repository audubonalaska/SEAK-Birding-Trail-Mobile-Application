import QtQuick 2.9
import "../../MapViewer/controls" as Controls

import Esri.ArcGISRuntime 100.14
import ArcGIS.AppFramework 1.0

Item {
    property MapView mapView:null
    property var uidRequested:[]
    property ListModel contentListModel: ListModel {}
    property ListModel treeContentListModel: ListModel {}
    property ListModel sortedTreeContentListModel: ListModel {}
    property ListModel contentTabModel: ListModel {}

    property var listOfLayersToProcess:[]
    property ListModel unOrderedLegendInfos: Controls.CustomListModel {}
    property ListModel orderedLegendInfos: Controls.CustomListModel {} // model used in view

    property ListModel orderedLegendInfos_spatialSearch: Controls.CustomListModel {} // model used in view
    property ListModel orderedLegendInfos_legend: Controls.CustomListModel {}
    property int noSwatchRequested:0
    property int noSwatchReceived:0
    property int countOflegendItemsPopulatedInTree:0
    property var spatialSearchConfig:null
    property var layerLegendDic: ({})
    property var visibleLayersList : []
    property var opLayers:[]
    property var layerList



    function initializeLegend()
    {
        //get items from contentlistModel
         if((sortedTreeContentListModel.count === 0 || sortedTreeContentListModel.count !== treeContentListModel.count))// || !isContentFetched)
         {
        sortLayersInContentView()
        populateContentListBasedOnVisibility()
        sortUnorderedLegendInfos()
        populateLegendInTreeView()
        populateModelForContentTab(mapPage.selectedLayers)

         }
        if(orderedLegendInfos.count === 0 || orderedLegendInfos.count !== unOrderedLegendInfos.count)
        sortUnorderedLegendInfos()

        populatelegendModel()

    }

    function initializetreeControl()
    {
        if((contentTabModel.count === 0 || sortedTreeContentListModel.count === 0 || sortedTreeContentListModel.count !== treeContentListModel.count))// || !isContentFetched)
        {
            sortLayersInContentView()
            populateContentListBasedOnVisibility()
            sortUnorderedLegendInfos()
            populateLegendInTreeView()
            populateModelForContentTab(mapPage.selectedLayers)

        }

        if(countOflegendItemsPopulatedInTree !== unOrderedLegendInfos.count)
            populateLegendInTreeView()
    }



    function procLayers (layers, callback) {
        console.log("inside proclayers")
        unOrderedLegendInfos.clear()
        orderedLegendInfos.clear()
        orderedLegendInfos_legend.clear()
        orderedLegendInfos_spatialSearch.clear()
        treeContentListModel.clear()
        contentTabModel.clear()
        sortedTreeContentListModel.clear()
        treeContentListModel.clear()
        countOflegendItemsPopulatedInTree = 0
        //contentTabModel.dynamicRoles = true

        if (!layers) layers = mapView.map.operationalLayers

        var count = layers.count || layers.length
        var rootlyrindx = -1

        for (var i=count; i--;) {
            try {
                var   layer = mapView.map.operationalLayers.get(i)
                if(layer.featureTable)
                    layer.featureTable.featureRequestMode = Enums.FeatureRequestModeOnInteractionNoCache
            } catch (err) {
                layer = layers[i]
            }
            if (!layer)
            {
                continue
            }
            rootlyrindx = i

            loadSubLayers(layer,rootlyrindx)

            //addLayerToContentAndFetchLegend(layer,rootlyrindx)

        }
        //sortLegendContent()

    }



    function createChildNode(layer,lyrIdentificationIndexArray)
    {
        let _rendererField = ""
        let rootLayer = mapView.map.operationalLayers.get(lyrIdentificationIndexArray[0])


        // console.log("layer name", layer.name, " renderer:", JSON.stringify(layer.renderer), " load status:",layer.loadStatus)
        if(layer.renderer)
            _rendererField = layer.renderer.fieldNames ? layer.renderer.fieldNames[0] : ""
        if(layer.featureTable && _rendererField > "")
        {
            let fields = layer.featureTable.fields
            _rendererField = utilityFunctions.getFieldLabelFromPopup(layer.featureTable,_rendererField)


        }


        let   _child = {
            "name" : layer.name,
            "lyrid":layer.layerId ? layer.layerId : layer.sublayerId,
            "lyrIdentificationIndex" : lyrIdentificationIndexArray.join(),
            "checkBox": layer.visible,
            "layerType":rootLayer.layerType, //? rootLayer.layerType : layer.objectType,
            "_children": [],
            "legendItems": [],
            "rendererField":_rendererField,
            "isVisibleAtScale":layer.isVisibleAtScale(mapView.mapScale)
        }

        return _child
    }


    function processSubLayers(layer,subLayers,rootLayerName,rootlyrindx,subLyrIds,isSiblingSublayer,level,subLyrIdentificationIndex,lyrIdentificationIndexArray,rootlayerType,_children)
    {
        if(!rootlayerType)
            rootlayerType = layer.layerType

        if(!subLyrIdentificationIndex)
            subLyrIdentificationIndex = []

        if(!lyrIdentificationIndexArray)
        {
            lyrIdentificationIndexArray = []
            lyrIdentificationIndexArray.push(rootlyrindx)

            level = 0
        }
        if(!subLyrIds)
            subLyrIds = []


        if(layer)
        {
            if(!_children)
            {
                _children = createChildNode(layer,lyrIdentificationIndexArray)

            }
            if(layer.subLayerContents.length > 0)
            {
                level = level + 1

                if(rootlayerType === Enums.LayerTypeArcGISMapImageLayer || rootlayerType === Enums.LayerTypeArcGISTiledLayer){

                    for(var x=0;x<layer.subLayerContents.length;x++){

                        lyrIdentificationIndexArray.push(x)
                        let _sublyr = layer.subLayerContents[x]
                        let _childObject = null
                        if(_sublyr.subLayerContents.length > 0){

                            _childObject = createChildNode(_sublyr,lyrIdentificationIndexArray)

                        }

                        let lyrWithSublyrs = processSubLayers(layer.subLayerContents[x],subLayers,rootLayerName,rootlyrindx,subLyrIds,false,level,subLyrIdentificationIndex,lyrIdentificationIndexArray,rootlayerType,_childObject)

                        _children["_children"].push(lyrWithSublyrs._children)



                    }

                }

                else
                {
                    //for mmpk
                    for(var x1=layer.subLayerContents.length - 1;x1 >=0;x1--){

                        lyrIdentificationIndexArray.push(x1)
                        let _sublyr1 = layer.subLayerContents[x1]
                        if(_sublyr1){
                            let _childObject = null
                            if(_sublyr1.subLayerContents.length > 0){

                                _childObject = createChildNode(_sublyr1,lyrIdentificationIndexArray)

                            }

                            let lyrWithSublyrs = processSubLayers(layer.subLayerContents[x1],subLayers,rootLayerName,rootlyrindx,subLyrIds,false,level,subLyrIdentificationIndex,lyrIdentificationIndexArray,rootlayerType,_childObject)
                            _children["_children"].push(lyrWithSublyrs._children)
                        }

                    }



                }
                level = level - 1
                lyrIdentificationIndexArray.pop()
                return {subLayers,subLyrIds,subLyrIdentificationIndex,_children}

            }
            else
            {


                subLayers.push(layer.name)

                if(layer.id)
                    subLyrIds.push(layer.id)
                else
                    subLyrIds.push(layer.layerId)
                subLyrIdentificationIndex.push(lyrIdentificationIndexArray.join())

                if(layer.sublayerId)

                    fetchLegendInfos(layer, layer.sublayerId,rootLayerName,rootlyrindx)

                else if(layer.layerId)

                    fetchLegendInfos(layer, layer.layerId,rootLayerName,rootlyrindx)
                else
                {
                    //sublayer of a featureCollectionlayer may not have a sublayerid
                    fetchLegendInfos(layer, layer.name,rootLayerName,rootlyrindx)
                }

                lyrIdentificationIndexArray.pop()


            }

        }




        return {subLayers,subLyrIds,subLyrIdentificationIndex,_children}

    }

    function addFeatureCollectionLayers(layer,rootlyrindx)
    {
        //console.log("processing featureCollection layers")
        let lyrs = layer.layers
        for(let k=0;k<lyrs.length;k++)
        {
            let lyr = lyrs[k]
            var subLayers = []
            var subLyrIds = []
            var sublyrIdentificationIndex = []
            let children = {}
            var obj = processSubLayers(layer,subLayers,layer.name,rootlyrindx,subLyrIds)
            subLayers = obj.subLayers
            subLyrIds = obj.subLyrIds
            children = obj._children
            sublyrIdentificationIndex = obj.subLyrIdentificationIndex
            addToContentList(layer,subLayers,subLyrIds,sublyrIdentificationIndex,children)

        }


    }


    //To get the typeid field to show in the legend we need to look at the renderer Field
    //Then get the field alias from the PopUp. Since the renderer object of a sublayer does not get populated
    //unless the sublayer is loaded we need to check if the sublayers of a layer is loaded or not.
    //Then load the sublayers which are not loaded

    function loadSubLayers(layer,rootlyrindx) {
        let visited = []
        let queue = []
        let _childItems = []
        let current = layer
        let unloadedLayers = []

        queue.push(current)

        while (queue.length) {
            current = queue.shift()
            visited.push(current)
            for(let k=0;k<current.subLayerContents.length; k++){
                let child = current.subLayerContents[k]
                queue.push(child)
                if (child.loadStatus !== Enums.LoadStatusLoaded)
                {
                    unloadedLayers.push(child)
                }
            }

        }
        loadUnloadedLayers(layer,rootlyrindx,unloadedLayers)
    }


    function loadUnloadedLayers(layer,rootlyrindx,unloadedLayers)
    {
        if(unloadedLayers.length > 0)
        {
            let _lyr = unloadedLayers.pop()
            if (_lyr.loadStatus === Enums.LoadStatusLoaded)
            {
                loadUnloadedLayers(layer,rootlyrindx,unloadedLayers)
            }
            else
            {
                _lyr.loadStatusChanged.connect(function(){
                    if (_lyr.loadStatus === Enums.LoadStatusLoaded){
                        loadUnloadedLayers(layer,rootlyrindx,unloadedLayers)

                    }
                }
                )

                _lyr.load()
            }

        }
        else
        {
            //console.log("fetching legend for ",layer.name)
            addLayerToContentAndFetchLegend(layer,rootlyrindx)
        }
    }




    /*
              if it is a group layer then the rootlyrindx is the index of the group layer
              If it is not a group layer then the rootlayerName is empty and the rootLyrIndex
              is same as the layer index

              */
    function addLayerToContentAndFetchLegend(layer,rootlyrindx)
    {

        // console.log('adding layer to content')

        var subLayers = []
        var subLyrIds = []
        var sublyrIdentificationIndex = []
        let _children = {}

        var sublyrindx = []
        sublyrindx.push(rootlyrindx)

        if(layer.loadStatus === Enums.LoadStatusLoaded)
        {


            if(layer.layerType !== Enums.LayerTypeFeatureCollectionLayer && layer.subLayerContents.length > 0)
            {


                var obj = processSubLayers(layer,subLayers,layer.name,rootlyrindx,subLyrIds)
                subLayers = obj.subLayers
                subLyrIds = obj.subLyrIds
                _children = obj._children
                sublyrIdentificationIndex = obj.subLyrIdentificationIndex

                addToContentList(layer,subLayers,subLyrIds,sublyrIdentificationIndex,_children)
            }
            else
            {
                if(layer.layerType === Enums.LayerTypeFeatureCollectionLayer)

                    addFeatureCollectionLayers(layer,rootlyrindx)
                else
                {
                    let _rendererField  = ""
                    if(layer.renderer)
                        _rendererField = layer.renderer.fieldNames ? layer.renderer.fieldNames[0] : ""

                    _children = {
                        "name" : layer.name,
                        "lyrid" : layer.layerId,
                        "lyrIdentificationIndex" : rootlyrindx.toString(),
                        "checkBox" : layer.visible,
                        "layerType":layer.layerType,
                        "_children" : [],
                        "legendItems" : [],
                        "rendererField:":_rendererField,
                        "isVisibleAtScale" : layer.isVisibleAtScale(mapView.mapScale)
                    }
                console.log("fetcching legendinfos :", layer.name)
                    fetchLegendInfos(layer, rootlyrindx,"",rootlyrindx)
                    addToContentList(layer,subLayers,subLyrIds,sublyrIdentificationIndex,_children)
                }
            }


        }
        else
        {
            //console.log("loading layer")
            loadLayerAndPopulateLegend(layer,rootlyrindx)
        }
    }

    function loadLayer(layer,lyrindex)
    {
        var subLayers = []
        var subLyrIds = []
        var sublyrIdentificationIndex = []


        if(layer.loadStatus === Enums.LoadStatusLoaded){

            prepareToAddLayerToContentList(layer,lyrindex)
            if(listOfLayersToProcess.length > 0){
                var lyrObj = listOfLayersToProcess.pop()
                loadLayer(lyrObj.layer,lyrObj.lyrindx)
            }

        }
        else
        {
            mapView.mapInitialized = true
            if(layer.loadError)
            {

                mapView.mapInitialized = true
            }
            else
            {
                layer.loadStatusChanged.connect(function(){
                    if (layer.loadStatus === Enums.LoadStatusLoaded){
                        prepareToAddLayerToContentList(layer,lyrindex)

                    }

                }
                )
                layer.load()
            }
        }



    }


    function prepareToAddLayerToContentList(layer,lyrindex)
    {
        let subLayers = []
        let subLyrIds = []
        let sublyrIdentificationIndex = []
        let  _children = {}
        let _rendererField = (layer.renderer && layer.renderer.fieldNames) ? layer.renderer.fieldNames[0] : ""
        if(layer.featureTable && _rendererField > "")
        {
            let fields = layer.featureTable.fields
            _rendererField = utilityFunctions.getFieldLabelFromPopup(layer.featureTable,_rendererField)//utilityFunctions.getFieldAlias(fields,_rendererField)
        }

        if(layer.subLayerContents.length > 0)
        {
            let obj = processSubLayers(layer,subLayers,layer.name,lyrindex,subLyrIds)
            subLayers = obj.subLayers
            subLyrIds = obj.subLyrIds
            _children = obj._children
            sublyrIdentificationIndex = obj.subLyrIdentificationIndex

        }
        else
        {
            _children = {
                "name" : layer.name,
                "lyrid" : layer.layerId,
                "lyrIdentificationIndex" : lyrindex.toString(), //lyrindex ? lyrindex.toString() : "0",
                "checkBox" : layer.visible,
                "_children" : [],
                "legendItems" : [],
                "layerType" : layer.layerType,
                "isVisibleAtScale" : layer.isVisibleAtScale(mapView.mapScale),
                "rendererField":_rendererField
            }
            fetchLegendInfos(layer, lyrindex,"",lyrindex)
        }
        addToContentList(layer,subLayers,subLyrIds,sublyrIdentificationIndex,_children)
        //now load any layers not loaded yet

    }


    /*
      added a timer to resolve the crash issue for some mmpk using 3D symbols

      */
    Timer {
        id: timer
    }

    function loadLayerAndPopulateLegend(layer,lyrindx)
    {
        listOfLayersToProcess.push({layer,lyrindx})
        if(!timer.running)
        {
            timer.interval = 100
            timer.repeat = true
            timer.triggered.connect(function () {
                if(listOfLayersToProcess.length > 0){
                    var lyrObj = listOfLayersToProcess.pop()
                    loadLayer(lyrObj.layer,lyrObj.lyrindx)
                }
                else
                    timer.stop()
            })
            timer.start();
        }

    }

    function getSubLayerVisibility(identificationIndex){
        var layerIndexes = identificationIndex.split(',')

        var lyr = mapView.map.operationalLayers.get(layerIndexes[0])// this is the root layer
        for(var k=1;k<layerIndexes.length;k++)
        {
            if(lyr && lyr.subLayerContents[layerIndexes[k]])
                lyr = lyr.subLayerContents[layerIndexes[k]]
        }
        if(lyr)
            return lyr.visible
        else
            return false
    }

    function isSublayerVisible(layer, sublayer,sublyrIdentificationIndex)
    {

        let sublyrVisibility = getSubLayerVisibility(sublyrIdentificationIndex)

        return sublyrVisibility
    }


    /*
      This is modified in version 4.1 to resolve the bug in earlier version
      where some of the layers were duplicated in the content.

      */

    function addToContentList(layer,sublayers,subLyrIds,sublyrIdentificationIndex,children)
    {

        var sublayersString = sublayers.join(',')
        //console.log(layer.name,":",sublayersString)
        var sublayersTxt = sublayers.join(',')
        var sublayerIds=""
        if(subLyrIds)
            sublayerIds = subLyrIds.join(',')

        if(!find(treeContentListModel,layer.name))
        {
            var isGroupLayer = sublayers.length > 0?true:false

            var isVisibleAtScale = isGroupLayer?sublayers.length > 0?true:false:layer.isVisibleAtScale(mapView.mapScale)
            var lyrname = layer.name
            //loop through sublayers and add the checkbox visibility
            var sublayersChkBoxList = []
            var sublayersIdentificationList = []
            //layerType 4 is ArcGISTiledLayer

            for(var k=0;k<sublayers.length;k++)
                // for(var k=sublayers.length - 1;k >= 0;k--)
            {
                var sublyrchkbox = {}

                var sublyr = sublayers[k]
                sublyrchkbox["sublyrname"]= sublyr
                //check for sublayer visibility
                // if(layer.layerType !== 4)
                sublyrchkbox["checkbox"] = isSublayerVisible(layer, sublyr,sublyrIdentificationIndex[k])//true
                //sublyrchkbox["layerType"] = layer.layerType

                sublyrchkbox["isVisibleAtScale"] = isSublayerVisible(layer, sublyr,sublyrIdentificationIndex[k])
                sublayersChkBoxList.push(sublyrchkbox)
                var identificationIndex = {}
                identificationIndex["identificationIndex"] = sublyrIdentificationIndex[k]
                sublayersIdentificationList.push(identificationIndex)

            }

            if(layer && lyrname &&!isLayerPresentInContentList(layer))
                treeContentListModel.append(children)


            //sort the list when all the layers has been added to the contentlist
            if(mapView.map)
            {

                if((mapView.layersNotLoadedAtStart + treeContentListModel.count) >= mapView.map.operationalLayers.count)
                    mapView.mapInitialized = true

            }
        }
    }

    function isLayerPresentInContentList(layer)
    {
        for(var k=0;k< treeContentListModel.count; k++)
        {
            var lyrObj = treeContentListModel.get(k)
            if(lyrObj["lyrid"] === layer.layerId)
                return true
        }

        return false
    }


    function find(model,layername)
    {
        for(var i=0;i<model.count;i++)
        {
            var item = model.get(i)
            if(item.lyrname === layername)
                return true
        }
        return false
    }


    function processSubLayerLegend(layer,subLayers,rootLayer)

    {
        if(layer.subLayerContents.length > 0)
        {
            for(var x=0; x<layer.subLayerContents.length;x++){
                var sublyr = layer.subLayerContents[x]
                if(sublyr)
                {

                    if(sublyr !== null)
                    {
                        if(sublyr.subLayerContents && sublyr.subLayerContents.length > 0)
                        {
                            for(var ks = 0;ks<sublyr.subLayerContents.length; ks++)
                            {
                                processSubLayers(sublyr.subLayerContents[ks],subLayers,rootLayer.name,rootLayer.index)
                            }
                        }
                        else{
                            var lyrname = sublyr.name

                            var issublyrVisible = sublyr.isVisibleAtScale(mapView.mapScale)

                            if(issublyrVisible && layer.visible && layer.showInLegend && rootLayer.visible)
                            {
                                subLayers.push(lyrname)

                                sortAndAddLegendForLayer(sublyr,true,layer.name)
                            }

                        }
                    }

                }

            }
        }
        else
        {
            var issublyrVisible1 = layer.isVisibleAtScale(mapView.mapScale)


            if(issublyrVisible1 && layer.visible && layer.showInLegend && rootLayer.visible)

            {
                subLayers.push(layer.name)

                sortAndAddLegendForLayer(layer,true,rootLayer.name)
            }


        }
        return subLayers
    }



    /*
    This sorting functionality is new in version 4.1. Since the layers can load in any order
    we need to sort the layers based on the order they are added to the map.
    In addition we need to  also sort the legend based on legend index.


    */

    function sortAndAddLegendForLayer(layer1,isSublayer,rootLayerName){
        let legendArray = []
        let _showinlegend = layer1.showInLegend

        for(let k=0;k<unOrderedLegendInfos.count;k++)
        {
            let item = unOrderedLegendInfos.get(k)

            if(isSublayer)
            {
                if(layer1.sublayerId)
                {
                    if (item.layerName === layer1.name && item.rootLayerName === rootLayerName && parseInt(item.layerIndex) === parseInt(layer1.sublayerId))
                    {
                        legendArray.push(item)
                    }
                }
                else
                {
                    if ((item.layerName === layer1.name) && (item.rootLayerName === rootLayerName))
                    {
                        legendArray.push(item)
                    }
                }
            }
            else
            {
                if ((item.layerName === layer1.name)|| (item.rootLayerName === layer1.name))
                {
                    legendArray.push(item)

                }
            }
        }
        legendArray.sort((a, b) => (a.legendIndex > b.legendIndex) ? 1 : -1)
        legendArray.forEach(function(element){

            let updatedelement  = updateModelForSpatialSearchConfig(element)
            updatedelement =  updateModelForFeatureTypes(updatedelement,layer1)
            updatedelement.showInLegend = layer1.showInLegend
            orderedLegendInfos.addIfUnique(updatedelement,"uid")

        })


    }

    function updateModelForFeatureTypes(element,layer)
    {
        var _featureTable = layer.table
        if(!_featureTable)
            _featureTable = layer.featureTable
        if(layer.featureTable){

            if(_featureTable.featureTypes){

                var _featureTypes = _featureTable.featureTypes

                for(var k=0;k<_featureTypes.length;k++)
                {
                    var _featType = _featureTypes[k]
                    let _template = _featType.templates


                    if(_featType.name === element.name || (_template && _template[0].name === element.name))
                        element.isFeatureType = true

                }
            }


        }
        return element


    }


    function updateModelForSpatialSearchConfig(item)
    {

        if(spatialSearchConfig && spatialSearchConfig.searchLayers){
            const result = spatialSearchConfig.searchLayers.filter(obj => obj.layerName === item.layerName && obj.rootLayerName === item.rootLayerName);

            if(result.length > 0)
            {
                if(result[0].legendName.length > 0)
                {
                    if(result[0].legendName.includes(item.name))
                        item.isSelected = true
                    else
                        item.isSelected = false

                }

                else
                {
                    if(item.name > "" && item.name !== "<all other values>")
                        item.isSelected = false
                    else
                        item.isSelected = true
                }



            }

            else if(mapView.spatialfeaturesModel.count > 0)// || spatialQueryGraphicsOverlay.graphics.count > 0)
                item.isSelected = false
            else
                item.isSelected = false


        }


        return item
    }




    function promiseToLoadLayer(lyr)
    {
        return new Promise((resolve, reject) =>{


                               if(lyr.loadStatus === Enums.LoadStatusLoaded) {
                                   resolve(lyr)

                               }
                               else
                               {
                                   lyr.onLoadStatusChanged.connect(function () {

                                       if(lyr.loadStatus === Enums.LoadStatusLoaded) {
                                           resolve(lyr)

                                       }
                                   })
                                   lyr.load()
                               }

                           })
    }

    /*
             This function gets to the last sublayer of any branch by following the path
             contained in layerIndexes

            */

    function getLeafLayer(layerIndexes,lyrindex,subLayerContents,resolve)
    {

        if(subLayerContents.length > 0)
        {
            var sublyrs = subLayerContents
            var newrootlayer = sublyrs[layerIndexes[lyrindex + 1]]

            if(newrootlayer && newrootlayer.subLayerContents.length > 0)
                return getLeafLayer(layerIndexes,lyrindex + 1,newrootlayer.subLayerContents)
            else

                resolve(newrootlayer)
        }



    }



    function fetchLeafLayer(layerIndexes,lyrindex,subLayerContents)
    {
        return new Promise((resolve, reject) => {

                               var layersProcessed = 0
                               var lyrindex = 0

                               getLeafLayer(layerIndexes,lyrindex,subLayerContents,resolve)
                           })

    }

    /*
              item.sublyrIdentificationIndex contains the path to the end sublayer item for
              each of the sublayers . It iterates through each of the sublayer and process the
              legend. This function is added in v5

            */

    function populateLegendIteminTreeView(rootlayer,contentItem)
    {
        if(contentItem._children.count > 0)
        {
            for(let k=0;k<contentItem._children.count; k++){

                let child = contentItem._children.get(k)
                populateLegendIteminTreeView(rootlayer,child)
            }


        }
        else
        {
            //populate the legend
            let sublyr = contentItem.name
            if(typeof layerLegendDic[rootlayer] !== "undefined")
            {
                let legendItems = layerLegendDic[rootlayer][sublyr]
                contentItem["legendItems"].clear()

                let _contentlegendItems = []
                if(legendItems && legendItems.length > 0)
                {
                    for (let element of legendItems)  {

                        let legItem = {
                            "symbolUrl":element.symbolUrl,
                            "legendName":element.name
                        }


                        contentItem["legendItems"].append(legItem)


                    }
                    countOflegendItemsPopulatedInTree += legendItems.length
                }
            }

        }
    }


    function populateLegendInTreeView()
    {

        for(let k=0;k< sortedTreeContentListModel.count;k++){

            let contentItem = sortedTreeContentListModel.get(k)
            let rootlayer = contentItem.name

            populateLegendIteminTreeView(rootlayer,contentItem)

        }

    }

    function populatelegendModel()
    {

        orderedLegendInfos_legend.clear()
        for(var k=0;k< legendManager.orderedLegendInfos.count;k++)
        {
            var item = legendManager.orderedLegendInfos.get(k)
            if(item.showInLegend)
            {
                let rootLayerName = item.rootLayerName
                let lyrname = item.layerName
                let key = rootLayerName
                if(key > "")
                    key = rootLayerName + "_" + lyrname
                else
                    key = lyrname

                if(visibleLayersList.includes(key))
                {

                    if(item.rendererField > "")
                        item.displayName = item.displayName.split("\n")[0]

                    orderedLegendInfos_legend.append(item)
                }
                //mapView.orderedLegendInfos_legend.addIfUnique(item,"uid")

            }

        }
    }



    function updateLegendInfos () {
        // sortLegendInfosByLyrIndex()

        /*if (mapView.map.legendInfos.count > mapView.legendProcessingCountLimit) return mapView.map.legendInfos
      mapView.orderedLegendInfos.clear()
      for (var i=mapView.map.operationalLayers.count; i--;) {
          var lyr = mapView.map.operationalLayers.get(i)
          if (!lyr.visible || !lyr.showInLegend) continue
          var other = null
          for (var j=0; j<lyr.legendInfos.count; j++) {
              var ol = lyr.legendInfos.get(j)
              var ul = mapView.unOrderedLegendInfos.getItemByAttributes({"name": ol.name, "layerIndex": i})
              if (["Other", "other"].indexOf(ol.name) !== -1) {
                  other = ul
                  continue
              }
              if (ul) mapView.orderedLegendInfos.addIfUnique(ul, "uid")
          }
          if (other) mapView.orderedLegendInfos.addIfUnique(other, "uid")
      }
      return mapView.orderedLegendInfos*/
    }


    /* This function is modified in version 4.1 as sometimes the grouped layers can take some time to load
    This was causing the legend to show sometimes in random order.

    */

    function updateLayers () {
        mapView.contentListModel.clear()
        mapView.layersWithErrorMessages.clear()

        legendManager.mapView = mapView
        legendManager.uidRequested = []
        legendManager.procLayers()

        //mapView.procLayers()
        /*mapView.procLayers(null, function () {
          if (mapView.map.legendInfos.count <= mapView.legendProcessingCountLimit) {
              mapView.fetchAllLegendInfos()
          }
      })*/
    }

    function fetchAllLegendInfos () {
        unOrderedLegendInfos.clear()
        for (var i=mapView.map.operationalLayers.count; i--;) {
            var lyr = mapView.map.operationalLayers.get(i)
            fetchLegendInfos(lyr, i)
        }
    }

    function fetchLegendInfos (lyr,layerIndex,rootLayerName,rootLayerIndex) {

        lyr.legendInfos.fetchLegendInfosStatusChanged.connect(function () {
            switch (lyr.legendInfos.fetchLegendInfosStatus) {
            case Enums.TaskStatusCompleted:
                fetchLayerLegends(lyr, layerIndex,rootLayerName,rootLayerIndex)
            }
        })
        lyr.legendInfos.fetchLegendInfos(true)
    }

    function fetchLayerLegends (lyr, layerIndex,rootLayerName,rootLayerIndex) {
        for (var i=0; i<lyr.legendInfos.count; i++) {
            if(lyr.sublayerId)
                layerIndex = lyr.sublayerId
            mapView.noSwatchRequested ++
            let _rendererField = lyr.renderer.fieldNames ? lyr.renderer.fieldNames[0] : ""
            if(lyr.featureTable && _rendererField > "")
            {
                let fields = lyr.featureTable.fields
                _rendererField = utilityFunctions.getFieldLabelFromPopup(lyr.featureTable,_rendererField)//utilityFunctions.getFieldAlias(fields,_rendererField)
            }


            createSwatchImage(lyr.legendInfos.get(i), lyr.name,lyr.objectType, i, layerIndex,rootLayerName,rootLayerIndex,lyr.showInLegend,_rendererField)


        }
    }

    /*
    This function is modified in  version 4.1 to sort the legend after we get the image.

    */
    function createSwatchImage(legend, layerName,layerType, legendIndex, layerIndex,rootLayerName,rootLayerIndex,showInLegend,rendererField) {
        let responseRecvd = false
        let sym = legend.symbol
        let uid = ""
        if(layerIndex === undefined)
            layerIndex = -1
        if(layerName !== rootLayerName && rootLayerName > "")
            uid = rootLayerName + "_" + layerName + "_" + layerIndex + "_" + legendIndex
        else
            uid = layerName + "_" + legendIndex

        if(!uidRequested.includes(uid))
        {
            uidRequested.push(uid)

            if(sym.swatchImage && sym.json.url){

                populateUnOrderedLegendInfos(uid,sym.json.url,legend, layerName,layerType, legendIndex, layerIndex,rootLayerName,rootLayerIndex,showInLegend,rendererField)

            }
            else
                sym.createSwatch()

            sym.swatchImageChanged.connect(function () {

                if (sym.swatchImage) {

                    populateUnOrderedLegendInfos(uid,sym.swatchImage.toString(),legend, layerName,layerType, legendIndex, layerIndex,rootLayerName,rootLayerIndex,showInLegend,rendererField)

                }

            })

        }

    }

    function populateLegendItem(lyrname,treeItem)
    {
        if(treeItem._children && treeItem._children.count > 0)
        {
            for(let k=0;k < treeItem._children.count;k++){
                let sublyrItem = treeItem._children.get(k)
                populateLegendItem(lyrname,sublyrItem)
            }

        }
        else
        {
            let legendItems = layerLegendDic[lyrname][treeItem.name]
            if(legendItems){

                for (var element of legendItems) {

                    orderedLegendInfos.addIfUnique(element,"uid")
                }
            }

        }
    }

    function prepareSublyrLegend()
    {
        for(let i=0;i< sortedTreeContentListModel.count;i++)
        {
            let contentItem = sortedTreeContentListModel.get(i)

            let lyrname = contentItem.name
            if(contentItem._children.count > 0)
            {

                for(let k=0;k<contentItem._children.count;k++)
                {
                    let sublyr = contentItem._children.get(k)

                    populateLegendItem(lyrname,sublyr)

                }

            }
            else
            {
                let _legendItems = layerLegendDic[lyrname][lyrname]

                for (let element of _legendItems) {

                    orderedLegendInfos.addIfUnique(element,"uid")
                }

            }

        }
    }

    function populateOrderedLegendInfos()
    {
        // if(!layerList)
        //populateLayerList()
        orderedLegendInfos.clear()

        prepareSublyrLegend()

    }

    function prepareSublyrLegendStructure()
    {
        for(let i=0;i<treeContentListModel.count;i++)
        {
            let contentItem = treeContentListModel.get(i)
            if(contentItem){
                let lyrname = contentItem.name
                if(contentItem._children.count > "")
                {

                    for(let k =0;k<contentItem._children.count;k++)
                    {
                        let subitem = contentItem._children.get(k)
                        let sublyr = getlayer(subitem.lyrIdentificationIndex)
                        layerLegendDic[lyrname] = {}
                        if(sublyr && sublyr.name)
                            layerLegendDic[lyrname][sublyr.name] = []
                        else
                        {
                            layerLegendDic[lyrname][lyrname] = []
                        }
                    }


                }
                else
                {
                    layerLegendDic[lyrname] ={}
                    layerLegendDic[lyrname][lyrname] = []
                }
            }

        }

    }


    function sortUnorderedLegendInfos()
    {

        //if(!layerList)
        //populateLayerList()
        layerList = mapView.map.operationalLayers
        if(unOrderedLegendInfos.count !== Object.keys(layerLegendDic).length) {
            prepareSublyrLegendStructure()


            for(let x= 0;x < unOrderedLegendInfos.count; x++)
            {
                let legitem = unOrderedLegendInfos.get(x)
                let key = ""
                let rootlyrname = legitem.rootLayerName
                if(rootlyrname === "")
                    key = legitem.layerName
                else
                    key = rootlyrname


                if(key in layerLegendDic)
                {

                    if(layerLegendDic[key][legitem.layerName])
                        layerLegendDic[key][legitem.layerName].push(legitem)
                    else
                    {
                        layerLegendDic[key][legitem.layerName] = []
                        layerLegendDic[key][legitem.layerName].push(legitem)

                    }

                }

            }

            //sort them based on Sublayers


            //then sort them based on legendindex
            Object.keys(layerLegendDic).forEach(function(sublyrDictKey){
                Object.keys(layerLegendDic[sublyrDictKey]).forEach(function(key){
                    layerLegendDic[sublyrDictKey][key].sort(function(a, b){return a.legendIndex - b.legendIndex})
                })
            })


            populateOrderedLegendInfos()
        }


    }

    //

    function getItemFromTreeContentListModel(layerName)
    {
        for(let i=0;i< treeContentListModel.count;i++)
        {
            let item = treeContentListModel.get(i)
            if(item.name === layerName)
            {
                return item

            }
        }

    }
    function populateModelForContentTab(layersToBeIncludedInContent)
    {
        if(!layersToBeIncludedInContent)
            layersToBeIncludedInContent = []
        contentTabModel.clear()
        for(let k=0;k<sortedTreeContentListModel.count;k++)
        {
            let _item = sortedTreeContentListModel.get(k)
            let canInclude = true
            //check if the layer should be included in the list
            if(layersToBeIncludedInContent.length > 0)
            {

                let isLyrPresent = layersToBeIncludedInContent.filter(layer => layer.id === _item.lyrid)
                //need to check for sublayers
                let _modTreeItem = updateContentTreeItem(layersToBeIncludedInContent,_item)
                canInclude = isLyrPresent.length > 0
                if(canInclude)
                {
                    contentTabModel.append(_modTreeItem)
                    let _it = contentTabModel.get(contentTabModel.count - 1)
                    if(typeof _it.legendItems === "undefined")
                    {
                        _it.legendItems = []
                        for(let p=0;p<_modTreeItem.legendItems.count;p++)
                        {
                            let _legname = _modTreeItem.legendItems.get(p).legendName
                            let _sym = _modTreeItem.legendItems.get(p).symbolUrl
                            _it.legendItems.append({legendName:_legname.toString(), symbolUrl:_sym.toString()})
                        }
                    }

                }

            }
            else
            {
                contentTabModel.append(_item)
            }

        }
    }

    function bfs(item) {
        let visited = []
        let queue = []
        let _childItems = []
        let current = item

        queue.push(current)

        while (queue.length) {
            current = queue.shift()
            visited.push(current)
            for(let k=0;k<current._children.count; k++){
                let child = current._children.get(k)
                queue.push(child)
            }

        }

        return visited
    }

    function isSubLyrPresent(layersToBeIncludedInContent,lyrid,sublyrid)
    {
        let issubLyrPresent = layersToBeIncludedInContent.filter(layer => layer.id.toString() === lyrid && layer.sublayerId.toString() === sublyrid)
        return issubLyrPresent.length > 0

    }



    function updateItem(layersToBeIncludedInContent,lyrid,item,newItem)
    {

        if(!newItem)
        {
            newItem = Object.assign({},item)
            newItem._children = []
        }
        else
            newItem._children = []


        for(let k=0;k<item._children.count; k++){

            let child = item._children.get(k)
            let childrenArray = bfs(child)
            let isChildIncluded = false
            for(let p = 0;p<childrenArray.length;p++)
            {
                let _item = childrenArray[p]
                let isPresent = isSubLyrPresent(layersToBeIncludedInContent,lyrid,_item.lyrid)
                if(isPresent)
                {
                    isChildIncluded = true
                    let childCopy = Object.assign({},child)
                    newItem._children.push(childCopy)
                    break
                }

            }

            if(isChildIncluded === true)
                updateItem(layersToBeIncludedInContent,lyrid,child,newItem._children[newItem._children.length - 1])



        }

        return newItem


    }




    /*  function isAnyChildrenIncludedInSelectedLayers(layersToBeIncludedInContent,lyrid,newItem,item)
    {
        if(!newItem)
        {
            newItem = Object.assign({},item)
        }
        else
        {
            let _childItem = Object.assign({},item)
            _childItem.children = []
            newItem._children.push(_childItem)
        }

        newItem._children = []
        if(item._children.count > 0)
        {
            for(let k=0;k<item._children.count; k++){

                let child = item._children.get(k)

                populateLegendIteminTreeView(layersToBeIncludedInContent,lyrid,newItem,child)
            }


        }
        else
        {

        }

        for(let k=0;k<layersToBeIncludedInContent.length;k++)
        {
            let selectedlyr = layersToBeIncludedInContent[k]
            if(selectedlyr.id === lyrid && selectedlyr.sublayerid === subLyrId)
                return true

        }
        return isAnyChildrenIncludedInSelectedLayers(layersToBeIncludedInContent,lyrid,subLyrId,item)
        // return false




    }
*/

    function updateContentTreeItem(layersToBeIncludedInContent,item)
    {
        //check if the layerId is included in the selectedlayers
        //if not included loop through the children recursively and include it if any children is listed
        //if included check the same for sublayers
        //if it has no children then include it if listed

        if(layersToBeIncludedInContent.length > 0)
        {
            let _item =  updateItem(layersToBeIncludedInContent,item.lyrid,item,null)
            return _item
        }
        else
            return item

    }

    function sortLayersInContentView()
    {

        sortedTreeContentListModel.clear()

        layerList = mapView.map.operationalLayers
        for(let k = layerList.count - 1; k >= 0; k--)
        {
            let lyr = layerList.get(k)
            if(lyr)
            {
                let contentItem = getItemFromTreeContentListModel(lyr.name)
                if(contentItem)
                {
                    sortedTreeContentListModel.append(contentItem)

                }
            }


        }

    }

    function populateContentListBasedOnVisibility()
    {

        for(let k =0;k<contentTabModel.count;k++)
        {
            let item = contentTabModel.get(k)

            let lyr = getlayer(item.lyrIdentificationIndex)
            if(lyr)
            {

                item["isVisibleAtScale"] = lyr.isVisibleAtScale(mapView.mapScale)
                updateSubLayerVisibility(item,item["isVisibleAtScale"])
            }
        }

    }


    function updateSubLayerVisibility(item,parentItemVisibility)
    {
        for(let k =0;k<item._children.count;k++)
        {
            let subitem = item._children.get(k)
            let lyr = getlayer(subitem.lyrIdentificationIndex)
            if(parentItemVisibility && lyr)
                subitem["isVisibleAtScale"] = lyr.isVisibleAtScale(mapView.mapScale)
            else
                subitem["isVisibleAtScale"] = false

            updateSubLayerVisibility(subitem,subitem["isVisibleAtScale"])
        }

    }

    function getlayer(identificationIndex)
    {
        let layerIndexes = identificationIndex.split(',')
        let lyr = {}
        if(!opLayers[layerIndexes[0]])
            opLayers[layerIndexes[0]] = mapView.map.operationalLayers.get(layerIndexes[0])

        lyr = opLayers[layerIndexes[0]]

        let lyrs = lyr.subLayerContents

        for(let k=1;k<layerIndexes.length;k++)
        {

            if(lyrs && lyrs.length > 1)
            {

                lyr = lyrs[layerIndexes[k]]
                if(lyr && lyr.subLayerContents)
                    lyrs = lyr.subLayerContents
            }


        }
        if(layerIndexes.length === 1)
        {
            lyr = mapView.map.operationalLayers.get(layerIndexes[0])
        }
        return lyr

    }







    function populateUnOrderedLegendInfos(uid,url,legend, layerName,layerType, legendIndex, layerIndex,rootLayerName,rootLayerIndex,showInLegend,rendererField){
        var isSelected = true

        if(!layerType)
            layerType = "-1" //grouplayer
            //console.log("adding to legendinfos",layerName, unOrderedLegendInfos.count)

        unOrderedLegendInfos.replaceOrAppendUnique(
                    {
                        "uid": uid,
                        "legendIndex": legendIndex,
                        "layerIndex": parseInt(layerIndex),
                        "layerName": layerName,
                        "layerType":layerType,
                        "name": legend.name,
                        "symbolUrl": url,//sym.swatchImage.toString(),
                        "rootLayerName":rootLayerName,
                        "rootLayerIndex":rootLayerIndex,
                        "isSelected":isSelected,//false,
                        "isFeatureType":false,
                        "showInLegend":showInLegend,

                        "displayName":rootLayerName?"<b>"+ rootLayerName + "</b>" + "<br/>" +  layerName:layerName,
                        "rendererField": rendererField ,
                        "layerHeaderName":  (rootLayerName?"<b>"+ rootLayerName + "</b>" + "<br/><br/>" +  layerName:layerName)  + (rendererField > ""? "<br/><br/>&nbsp;&nbsp;" +  rendererField:"")


                    }, "uid")

        noSwatchReceived++

        //sortLegendContent()
    }

    function isLegendPresentInLegendList(uid)
    {
        for(var k=0;k< unOrderedLegendInfos.count; k++)
        {
            var legendObj = unOrderedLegendInfos.get(k)
            if(legendObj["uid"] === uid)
                return true
        }

        return false
    }




}
