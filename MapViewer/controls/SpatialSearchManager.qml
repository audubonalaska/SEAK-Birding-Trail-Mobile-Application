import QtQuick 2.9

import Esri.ArcGISRuntime 100.14
import ArcGIS.AppFramework 1.0

Item {
    property MapView _mapView:null
    property var searchLayers:[]
    property var searchLayersOrdered : []


    function updateOrderedLegendInfos()
    {
        let valueChanged = false
        for(let k=0;k< legendManager.orderedLegendInfos_spatialSearch.count;k++)
        {
            let item = legendManager.orderedLegendInfos_spatialSearch.get(k)
            if(!item.isSelected){
                valueChanged = true
                legendManager.orderedLegendInfos_spatialSearch.set(k,{"isSelected":true})
            }
        }
        return valueChanged


    }




    function addAllLayersToSearch()
    {
        if(_mapView.spatialSearchConfig)
            _mapView.spatialSearchConfig.searchLayers = []

        for(let k=0;k< legendManager.orderedLegendInfos_spatialSearch.count;k++)
        {
            let item = legendManager.orderedLegendInfos_spatialSearch.get(k)


            if(_mapView.spatialSearchConfig && _mapView.spatialSearchConfig.searchLayers){
                let userConfiguredSearchLayers = _mapView.spatialSearchConfig.searchLayers
                let  result = userConfiguredSearchLayers.filter(lyr =>

                                                                lyr.layerName === item.layerName


                                                                )
                if(result.length === 0){
                    let isAdded =  addSubLayerToSearch(item.rootLayerName,item.layerName,item.layerIndex,item.name)

                }


            }
            else
            {
                addSubLayerToSearch(item.rootLayerName,item.layerName,item.layerIndex,item.name)


            }

        }

    }



    function addSubLayerToSearch(rootLayerName,layerName,layerIndex,legendName)
    {

        let isAdded = false

        if(legendName && legendName !== "<all other values>")
        {

            let lyrs = searchLayers.filter(lyr => lyr.rootLayerName === rootLayerName &&  lyr.layerName === layerName);
            if(lyrs.length === 0)
            {
                searchLayers.push({"rootLayerName":rootLayerName,"layerName":layerName,"hasCategories":true,"legendName":[legendName],"layerIndex":layerIndex})
                isAdded = true
            }
            else
            {
                let lyrs2 = searchLayers.map(item => {
                                                 if(item.rootLayerName === rootLayerName &&  item.layerName === layerName)
                                                 {
                                                     if(!item.legendName.includes(legendName))
                                                     {
                                                         // console.log("pushed legend to",item.layerName,"-",legendName)
                                                         item.legendName.push(legendName)
                                                         item.hasCategories = true
                                                     }

                                                 }
                                                 return item


                                             }
                                             )

                searchLayers = lyrs2
                isAdded = true

            }
        }
        else
        {
            let  result1 = null

            result1 = searchLayers.filter(item => item.layerName === layerName && item.rootLayerName === rootLayerName);
            if(result1.length === 0)
            {

                searchLayers.push({"rootLayerName":rootLayerName,"layerName":layerName,"hasCategories":false,"legendName":[],"layerIndex":layerIndex})
            }
            isAdded = true

        }

        return isAdded

    }


    function removeSubLayerFromSearch(rootLayerName,layerName,layerIndex,legendName)
    {

        if(legendName && legendName !== "<all other values>")
        {

            let lyrs2 = searchLayers.map(item => {
                                             if(item.rootLayerName === rootLayerName &&  item.layerName === layerName)
                                             {
                                                 if(item.legendName.includes(legendName))
                                                 {
                                                     let sublegends = item.legendName.filter(legnd => legnd !== legendName);
                                                     item.legendName = sublegends
                                                 }



                                             }
                                             return item


                                         }
                                         )

            let  result = lyrs2.filter(lyr =>(!lyr.hasCategories ||(lyr.hasCategories &&  lyr.legendName.length > 0)));

            searchLayers = result


        }
        else
        {
            var  result1 = null
            if(rootLayerName === layerName)
            {
                result1 = searchLayers.filter(item => item.layerName !== layerName);

            }
            else
            {

                result1 = searchLayers.filter(item => item.layerName !== layerName);

            }

            searchLayers = result1


        }

        updateunOrderedLegendInfos(rootLayerName,layerName,layerIndex,legendName,false)
        updateorderedLegendInfos_spatialSearch(rootLayerName,layerName,layerIndex,legendName,false)
        _mapView.spatialSearchInitialized = true
    }

    function updateunOrderedLegendInfos(rootLayerName,layerName,layerIndex,legendName,isSelected)
    {
        for (var k =0; k<legendManager.unOrderedLegendInfos.count;k++)
        {
            var item = legendManager.unOrderedLegendInfos.get(k)
            if(item.rootLayerName === rootLayerName && item.layerName === layerName && item.name ===legendName)
                legendManager.unOrderedLegendInfos.setProperty(k, "isSelected", isSelected)

        }
    }

    function updateorderedLegendInfos_spatialSearch(rootLayerName,layerName,layerIndex,legendName,isSelected)
    {
        for (var k =0; k<legendManager.orderedLegendInfos_spatialSearch.count;k++)
        {
            var item = legendManager.orderedLegendInfos_spatialSearch.get(k)
            if(item.rootLayerName === rootLayerName && item.layerName === layerName && item.name ===legendName)
                legendManager.orderedLegendInfos_spatialSearch.setProperty(k, "isSelected", isSelected)

        }
    }





    function saveSearchConfig(distance,measurementUnits)
    {

        if(_mapView){
            let spatialSearchConfig = {}
            let dist = distance //parseInt(amount.text)
            let distanceInMeters = _mapView.getDistanceInMeters(dist, measurementUnits)
            spatialSearchConfig.distance = distanceInMeters


            spatialSearchConfig.searchLayers = spatialSearchManager.searchLayers
            if(_mapView && _mapView.spatialSearchConfig)
            {
                spatialSearchConfig.location = _mapView.spatialSearchConfig.location

            }

            _mapView.spatialSearchConfig = spatialSearchConfig
            updateModel()
            //mapPage.showSpatialSearchSettingsSavedMessage("",qsTr("Search settings saved."))
        }

        //orderSearchLayers()
    }

    function orderSearchLayers()
    {
        searchLayersOrdered = []
        let _test = []

        if(_mapView)
        {
            let isGrpLyr = false
            if(_mapView.map && _mapView.map.operationalLayers){

                for (let k=0;k< _mapView.map.operationalLayers.count; k++)
                {
                    let lyr = _mapView.map.operationalLayers.get(k)
                    if(lyr){
                        if(lyr.subLayerContents.length > 0)
                        {
                            isGrpLyr = true

                            for(let p =lyr.subLayerContents.length; p--;)
                            {
                                let sublyr = lyr.subLayerContents[p]
                                if(sublyr){
                                    let searchsublyrItem = getItemFromSearchLayers(sublyr) //this will return an array of sublayers

                                    if(searchsublyrItem && searchsublyrItem.length > 0)
                                        searchsublyrItem.forEach(sublyr => searchLayersOrdered.push(sublyr))

                                }


                            }
                        }
                        else
                        {

                            let searchItems = getItemFromSearchLayers(lyr)


                            searchItems.forEach(sublyr => searchLayersOrdered.push(sublyr))

                        }
                    }

                }

            }
            _mapView.spatialSearchConfig.searchLayers = searchLayersOrdered
        }


    }

    function getItemFromSearchLayers(item)
    {
        //var result = null
        let orderedsearchLayers = []

        if(item.subLayerContents.length > 0)
        {
            for(let p =item.subLayerContents.length; p--;)
            {
                let sublyr = item.subLayerContents[p]

                if(sublyr){
                let searchsublyrs = getItemFromSearchLayers(sublyr)
                if(searchsublyrs && searchsublyrs.length > 0)
                    searchsublyrs.forEach(sublyr => orderedsearchLayers.push(sublyr))
                    }

            }

        }
        else
        {
            let result = searchLayers.filter(obj => obj.layerName === item.name);
            if(result && result.length > 0)
                orderedsearchLayers.push(result[0])
        }

        return orderedsearchLayers

    }

    function updateModel()
    {
        for (let k =0; k<legendManager.orderedLegendInfos_spatialSearch.count;k++)
        {
            let item = legendManager.orderedLegendInfos_spatialSearch.get(k)
            if(isItemPresentInSearchList(item))
                legendManager.orderedLegendInfos_spatialSearch.setProperty(k, "isSelected", true)
            else
                legendManager.orderedLegendInfos_spatialSearch.setProperty(k, "isSelected", false)

        }
    }



    function isItemPresentInSearchList(item)
    {

        let result = searchLayers.filter(obj => obj.layerName === item.layerName && obj.rootLayerName === item.rootLayerName);

        if(result.length > 0){
            if(result[0].legendName.length > 0)
            {
                if(result[0].legendName.includes(item.name))
                    return true
                else
                    return false
            }
            else
            {
                if(item.name === "")
                    return true
                else
                    return false
            }

        }
        else
            return item.isSelected

    }



}
