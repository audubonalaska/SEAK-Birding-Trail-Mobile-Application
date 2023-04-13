import QtQuick 2.9

import Esri.ArcGISRuntime 100.14
import ArcGIS.AppFramework 1.0

Item {
      property MapView mapView:null

    function updateMapUnitsModel () {
        if (!mapView || !mapView.currentViewpointCenter || !mapView.currentViewpointCenter.center) return
        var isEmpty = mapView.mapunitsListModel.count === 0,
        DD = CoordinateFormatter.toLatitudeLongitude(mapView.currentViewpointCenter.center, Enums.LatitudeLongitudeFormatDecimalDegrees, 3),
        DM = CoordinateFormatter.toLatitudeLongitude(mapView.currentViewpointCenter.center, Enums.LatitudeLongitudeFormatDegreesDecimalMinutes, 3),
        DMS = CoordinateFormatter.toLatitudeLongitude(mapView.currentViewpointCenter.center, Enums.LatitudeLongitudeFormatDegreesMinutesSeconds, 3),
        MGRS = CoordinateFormatter.toMgrs(mapView.currentViewpointCenter.center, Enums.MgrsConversionModeAutomatic, 3, true),
        mapUnitsObjects = [
                    { "name": "%1 (wkid: %2, %3)".arg(qsTr("Default")).arg(mapView.spatialReference.wkid).arg(getUnitNameFromWkText(mapView.spatialReference.wkText)),
                        "value": "%1 %2".arg(mapView.currentViewpointCenter.center.y.toFixed(4)).arg(mapView.currentViewpointCenter.center.x.toFixed(4)),
                        "isChecked": false,
                    },
                    { "name": "DD",
                        "value": parseDecimalCoordinate(DD),
                        "isChecked": false,
                    },
                    { "name": "DM",
                        "value": parseDecimalCoordinate(DM),
                        "isChecked": true,
                    },
                    { "name": "DMS",
                        "value": parseDecimalCoordinate(DMS),
                        "isChecked": false,
                    },
                    { "name": "MGRS",
                        "value": MGRS,
                        "isChecked": false,
                    }
                ]

        for (var i=0; i<mapUnitsObjects.length; i++) {
            if (isEmpty) {
                mapView.mapunitsListModel.append(mapUnitsObjects[i])
            } else {
                for (var key in mapUnitsObjects[i]) {
                    if (mapUnitsObjects[i].hasOwnProperty(key) && key !== "isChecked") {
                        mapView.mapunitsListModel.setProperty(i, key, mapUnitsObjects[i][key])
                    }
                }
            }
            var currentItem = mapView.mapunitsListModel.get(i)
        }
    }

    function updateGridModel () {
        var isEmpty = mapView.gridListModel.count === 0,
        gridObjects = [
                    { "name": "None ",
                        "value": "",

                        "isChecked": true,
                    },
                    { "name": "Lat/Long Grid",
                        "value": "",
                        "gridObject" : "LatitudeLongitudeGrid",
                        "isChecked": false,
                    },
                    { "name": "UTM Grid",
                        "value": "",
                        "gridObject" :"UTMGrid",
                        "isChecked": false,
                    },
                    { "name": "USNG Grid",
                        "value": "",
                        "gridObject" : "USNGGrid",
                        "isChecked": false,
                    },

                    { "name": "MGRS Grid",
                        "value": "",
                        "gridObject": "MGRSGrid",
                        "isChecked": false,
                    }
                ]

        for (var i=0; i<gridObjects.length; i++) {
            if (isEmpty) {
                mapView.gridListModel.append(gridObjects[i])
            } else {
                for (var key in gridObjects[i]) {
                    if (gridObjects[i].hasOwnProperty(key) && key !== "isChecked") {
                        mapView.gridListModel.setProperty(i, key, gridObjects[i][key])
                    }
                }
            }
            var currentItem = mapView.gridListModel.get(i)
            if (currentItem.isChecked) {
                mapView.grid = ArcGISRuntimeEnvironment.createObject(currentItem.gridObject, {labelPosition: Enums.GridLabelPositionAllSides})
            }
        }
    }

    function getUnitNameFromWkText (wkText) {
        var unit
        try {
            unit = JSON.parse("[" + wkText.split("UNIT")[2])[0][0].split(",")
        } catch (err) {
            unit = wkText
        }
        return unit[0]
    }

    function parseDecimalCoordinate (coord) {
        switch (coord.split(" ").length) {
        case (2):
            return parseDD (coord)
        case (4):
            return parseDM (coord)
        case (6):
            return parseDMS (coord)
        default:
            return coord
        }
    }

    function replaceDirectionStrings (originalText, replacement) {
        var directions = ["N", "S", "E", "W"]
        for (var i=0; i<directions.length; i++) {
            originalText = originalText.replace(directions[i],
                                                "%1 %2".arg(replacement).arg(directions[i]))
        }
        return originalText
    }

    function parseDD (DD) {
        var DDSplit = DD.split(" ")
        DD = "%1  %2".arg(DDSplit[0]).arg(DDSplit[1])
        return replaceDirectionStrings(DD, "°")
    }

    function parseDM (DM) {
        var DMSplit = DM.split(" ")
        DM = "%1° %2  %3° %4".arg(DMSplit[0]).arg(DMSplit[1]).arg(DMSplit[2]).arg(DMSplit[3])
        return replaceDirectionStrings(DM, "'")
    }

    function parseDMS (DMS) {
        var DMSSplit = DMS.split(" ")
        DMS = "%1° %2' %3  %4° %5' %6".arg(DMSSplit[0]).arg(DMSSplit[1]).arg(DMSSplit[2]).arg(DMSSplit[3]).arg(DMSSplit[4]).arg(DMSSplit[5])
        return replaceDirectionStrings(DMS, "''")
    }


}
