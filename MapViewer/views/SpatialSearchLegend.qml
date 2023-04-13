
import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0
//import Esri.ArcGISRuntime 100.14

import "../controls" as Controls

ListView {
    id: spatialsearchView
    interactive: false
    width:parent.width - 16 * scaleFactor
    anchors.centerIn: parent
    height:app.searchLegendListHeight

    property string itemClicked : ""
    //property var modelConfigured:"legend"

    signal rootLayerSelected(var layerName,bool checked)
    signal legendSelected(var layerName,var legendname,bool checked)
    signal resetLegend(var isValueChanged)


    footer:Rectangle{
        height:isIphoneX?36 * scaleFactor :16 * scaleFactor
        width:spatialsearchView.width
        color:"transparent"
    }

    clip: true


    delegate:
        Controls.SpatialSearchPanelItem {
        width: spatialsearchView.width
        property bool showLegend: name !== "<all other values>" ?true:false

        anchors {
            left: parent ? parent.left : undefined
            leftMargin: 34 * scaleFactor //2 * app.defaultMargin
            //topMargin: 16
        }
        visible: showLegend

        height: showLegend ? ((!showInLegend && name === "")? 0:app.units(40)): 0//showLegend ? app.units(40) : 0
        imageSource: symbolUrl
        txt: name
        isChecked:isSelected

        onClicked: {
            itemClicked = ""
        }

        onChecked: {
            valueChanged = true
            var distance = parseInt(amount.text);
            for(var k=0;k<_mapView.orderedLegendInfos_spatialSearch.count; k++)
            {
                var item = _mapView.orderedLegendInfos_spatialSearch.get(k)
                if(item.rootLayerName === rootLayerName && item.layerName === layerName && item.name === name)
                {
                    mapView.orderedLegendInfos_spatialSearch.set(k,{isSelected:checked})
                }

            }
            if(checked)
            {
                spatialSearchManager.addSubLayerToSearch(rootLayerName,layerName,layerIndex,name)
                spatialSearchManager.saveSearchConfig(distance,measurementUnits)
                //spatialSearchContent.saveSearchConfig(distance)

            }
            else
            {
                spatialSearchManager.removeSubLayerFromSearch(rootLayerName,layerName,layerIndex,name)
                spatialSearchManager.saveSearchConfig(distance,measurementUnits)
                //spatialSearchContent.saveSearchConfig(distance)
                // spatialsearchView.legendSelected(layerName,name,checked)
            }
            legendSelected(layerName,name,checked)

        }

        onIsCheckedChanged: {
            //valueChanged = true
            var distance = parseInt(amount.text)
            for(var k=0;k<_mapView.orderedLegendInfos_spatialSearch.count; k++)
            {
                var item = _mapView.orderedLegendInfos_spatialSearch.get(k)
                if(item.rootLayerName === rootLayerName && item.layerName === layerName && item.name === name)
                {
                    _mapView.orderedLegendInfos_spatialSearch.set(k,{isSelected:isChecked})
                }

            }

            if(isChecked)
            {



                spatialSearchManager.addSubLayerToSearch(rootLayerName,layerName,layerIndex,name)
                spatialSearchManager.saveSearchConfig(distance,measurementUnits)
                //spatialSearchContent.saveSearchConfig(distance)
            }
            else
            {
                spatialSearchManager.removeSubLayerFromSearch(rootLayerName,layerName,layerIndex,name)
                spatialSearchManager.saveSearchConfig(distance,measurementUnits)
                //spatialSearchContent.saveSearchConfig(distance)
                //spatialsearchView.legendSelected(layerName,name,checked)
            }
        }




        Connections{
            target:spatialSearchView
            function onRootLayerSelected(layerName,checked){
                if(layerName === displayName){
                    isChecked = checked
                    let distance = parseInt(amount.text)
                    if(isChecked)
                    {
                        spatialSearchManager.addSubLayerToSearch(rootLayerName,layerName,layerIndex,name)
                        spatialSearchManager.saveSearchConfig(distance,measurementUnits)

                    }
                    else
                    {
                        spatialSearchManager.removeSubLayerFromSearch(rootLayerName,layerName,layerIndex,name)
                        spatialSearchManager.saveSearchConfig(distance,measurementUnits)

                    }

                }
            }
        }



    }


    section {
        property: "displayName"
        delegate:Controls.SpatialSearchSectionDelegate{
            width:parent.width
            height:40 * scaleFactor

            onChecked: {

                valueChanged = true

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
