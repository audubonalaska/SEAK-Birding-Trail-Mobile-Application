import QtQuick 2.0
import QtQuick.Layouts 1.1
import Esri.ArcGISRuntime 100.14

import "../MapViewer/controls" as Controls

Rectangle {
    id:measurementUnitPanel
    width:measurementPanel.width//parent.width
    height:parent.height
    property int maxWidth:120 * scaleFactor
    property string value: ""
    property string coordinates:""
    property real iconSize: app.units(40)
    property real defaultMargin: app.defaultMargin/2
    property real defaultHeight: 3*app.defaultMargin + app.heightOffset
    property string captureType : ""
    readonly property string kDistance: qsTr("Distance")
    readonly property string kArea: qsTr("Area")
    property alias _measurementUnit:measurementUnit
    property var geometryToMeasure:null
    property real _menuBottomMargin:app.units(100)//2 * app.defaultMargin
    property real _menuLeftMargin: (2*defaultMargin + (app.width - width))/2
    property int selectedIndex:sketchEditorManager.selectedmeasurementUnitIndex
    property alias measurementLabel :label


    signal measurementUnitChanged (int index)

    QtObject {
        id: distanceUnits
        readonly property string kMeters: qsTr("%L1 m")
        readonly property string kMiles: qsTr("%L1 mi")
        readonly property string kKilometers: qsTr("%L1 km")
        readonly property string kFeet: qsTr("%L1 ft")
        readonly property string kYards: qsTr("%L1 yd")
    }

    QtObject {
        id: areaUnits
        property string defaultUnit: kSqMeters
        property real defaultValue: 0
        readonly property string kSqMeters: qsTr("%L1 sq m")
        readonly property string kSqMiles: qsTr("%L1 sq mi")
        readonly property string kSqKilometers: qsTr("%L1 sq km")
        readonly property string kSqYards: qsTr("%L1 sq yd")
        readonly property string kSqFeet: qsTr("%L1 sq ft")

    }

    property alias lengthUnits: lengthUnits
    QtObject {
        id: lengthUnits
        property string m: strings.m
        property string mi:strings.mi
        property string km: strings.km
        property string ft: strings.ft
        property string yd: strings.yd
    }

    property string pointIconPath:"../MapViewer/images/Feature-pointsNP.svg"
    property string lineIconPath:"../MapViewer/images/Feature-polylineNP.svg"
    property string polygonIconPath:"../MapViewer/images/Feature-polygonNP.svg"
    property string pointUrlTag:`<img width:50  src=${pointIconPath} />`
    property string lineUrlTag:`<img width:50  src=${lineIconPath} />`
    property string polygonUrlTag:`<img width:50  src=${polygonIconPath} />`
    property bool canShowInValidGeometryString:false
    property string inValidGeometryString:(captureType === "Polygon"?strings.invalid_geometry.arg(polygonUrlTag) : (captureType === "Polyline"? strings.invalid_geometry.arg(lineUrlTag) : ""))


    onGeometryToMeasureChanged: {
        canShowInValidGeometryString = (sketchEditorManager.canUndo || sketchEditorManager.canRedo) && sketchEditor.geometry  && !sketchEditor.isSketchValid() && !isInShapeCreateMode
        measureUnits(geometryToMeasure)
    }

    function measureUnits(_geom)
    {
        if(_geom){
            if(_geom.objectType === "Polygon")
            {
                captureType = "Polygon"
                coordinates = ""
                measurementUnit.value = Number(Math.abs(GeometryEngine.area(_geom)))
            }
            else if(_geom.objectType === "Polyline")
            {
                captureType = "Polyline"
                coordinates= ""
                measurementUnit.value = Number(Math.abs(GeometryEngine.length(_geom)))
            }
            else
            {
                captureType = "Point"
                let  DD = CoordinateFormatter.toLatitudeLongitude(_geom.extent.center, Enums.LatitudeLongitudeFormatDecimalDegrees, 3)
               if(DD > "")
                measurementUnit.value = measurementUnit.parseDecimalCoordinate(DD)
                else
                measurementUnit.value = ""
            }

        }
        else
        {
            measurementUnit.value = 0
            coordinates = ""

        }

        if(measurementUnit.value === 0 || measurementUnit.value === "")
           measurementUnitPanel._measurementUnit.model.clear()

        if(_geom && !(measurementUnit.value  > 0 || measurementUnit.value > "") && !isInShapeCreateMode)
            canShowInValidGeometryString = true

    }


    RowLayout{
        id:measurementPanel
        //width:parent.width
        height:parent.height


        Item {
            id: spaceFiller
            Layout.preferredWidth: app.units(16)
            Layout.fillHeight: true
        }

        Controls.BaseText {
            id: label
            padding: 0
            leftPadding: visible ?app.baseUnit : 0
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 1
            verticalAlignment: Text.AlignVCenter
            font.pointSize: app.units(14)
            Layout.leftMargin: 0
            Layout.alignment: Qt.AlignHCenter//Qt.AlignRight
            Layout.fillHeight: true
            text:canShowInValidGeometryString ? inValidGeometryString :""
            visible:text > ""
            Layout.preferredWidth: visible ? implicitWidth:0

        }

        Controls.ComboBox {
            id: measurementUnit
            property var value: measurementUnitPanel.value
            Layout.alignment:Qt.AlignHCenter
            iconSize: measurementUnitPanel.iconSize
            maxLabelWidth:maxWidth

            //menu.x: 0//(menu.parent.width-menu.width-defaultMargin)/2
            //menu.y: app.units(200)
            menu.modal: true
            selectedIndex:measurementUnitPanel.selectedIndex
            menuBottomMargin: _menuBottomMargin//app.units(50)
            menuLeftMargin: _menuLeftMargin
           // menuLeftMargin: app.units(10)
            color: "transparent"
            visible: !label.visible

            Connections {
                target: measurementUnit.listView

                function onCurrentIndexChanged() {
                    if (measurementUnit.listView.currentIndex >= 0) {
                        measurementUnitChanged (measurementUnit.listView.currentIndex)

                    }
                }
            }



            onValueChanged: {

                if (captureType === "Polyline") {
                    updateDistance(value)
                } else if(captureType === "Polygon") {
                    updateArea(value)
                }
                else
                {
                    if(geometryToMeasure)
                    {
                        let pt = geometryToMeasure.extent.center
                        updateMapUnitsModel (pt)
                    }
                }

            }

            function updateDistance (realValue) {
                if (!realValue) realValue = 0
                var index = sketchEditorManager.selectedmeasurementUnitIndex//measurementUnit.listView.currentIndex
                measurementUnit.model.clear()
                if(realValue > 0)
                {
                    measurementUnit.model.append({itemLabel: distanceUnits.kMeters.arg(realValue<1000000? parseFloat(realValue.toFixed(2)).toLocaleString(Qt.locale()):parseFloat(realValue.toExponential(3)).toLocaleString(Qt.locale())), unit: lengthUnits.m})
                    measurementUnit.model.append({itemLabel: distanceUnits.kMiles.arg((realValue*0.000621371)<1000000?parseFloat((realValue*0.000621371).toFixed(2)).toLocaleString(Qt.locale()): parseFloat((realValue*0.000621371).toExponential(3)).toLocaleString(Qt.locale())), unit: lengthUnits.mi})
                    measurementUnit.model.append({itemLabel: distanceUnits.kKilometers.arg((realValue*0.001)<10000000? parseFloat((realValue*0.001).toFixed(2)).toLocaleString(Qt.locale()):parseFloat((realValue*0.001).toExponential(3)).toLocaleString(Qt.locale())), unit: lengthUnits.km})
                    measurementUnit.model.append({itemLabel: distanceUnits.kFeet.arg((realValue*3.28084)<1000000?parseFloat((realValue*3.28084).toFixed(2)).toLocaleString(Qt.locale()):parseFloat((realValue*3.28084).toExponential(3)).toLocaleString(Qt.locale())), unit: lengthUnits.ft})
                    measurementUnit.model.append({itemLabel: distanceUnits.kYards.arg((realValue*1.09361)<1000000?parseFloat((realValue*1.09361).toFixed(2)).toLocaleString(Qt.locale()):parseFloat((realValue*1.09361).toExponential(3)).toLocaleString(Qt.locale())), unit: lengthUnits.yd})

                    measurementUnit.listView.currentIndex = sketchEditorManager.selectedmeasurementUnitIndex

                }
                measurementUnit.updateLabel(realValue)

            }

            function updateArea (realValue) {
                if (!realValue) realValue = 0
                var index = sketchEditorManager.selectedmeasurementUnitIndex//measurementUnit.listView.currentIndex
                measurementUnit.model.clear()
                if(realValue > 0){
                    measurementUnit.model.append({itemLabel: areaUnits.kSqMeters.arg(realValue<1000000?parseFloat(realValue.toFixed(2)).toLocaleString(Qt.locale()):parseFloat(realValue.toExponential(3)).toLocaleString(Qt.locale())),unit:areaUnits.kSqMeters})
                    measurementUnit.model.append({itemLabel: areaUnits.kSqMiles.arg((realValue/2589990)<1000000?parseFloat((realValue/2589990).toFixed(2)).toLocaleString(Qt.locale()):parseFloat((realValue/2589990).toExponential(3)).toLocaleString(Qt.locale())), unit:areaUnits.kSqMiles})
                    measurementUnit.model.append({itemLabel: areaUnits.kSqKilometers.arg((realValue/1000000)<1000000?parseFloat((realValue/1000000).toFixed(2)).toLocaleString(Qt.locale()):parseFloat((realValue/1000000).toExponential(3)).toLocaleString(Qt.locale())),unit:areaUnits.kSqKilometers})
                    measurementUnit.model.append({itemLabel: areaUnits.kSqFeet.arg((realValue/0.092903)<1000000?parseFloat((realValue/0.092903).toFixed(2)).toLocaleString(Qt.locale()):parseFloat((realValue/0.092903).toExponential(3)).toLocaleString(Qt.locale())),unit:areaUnits.kSqFeet})
                    measurementUnit.model.append({itemLabel: areaUnits.kSqYards.arg((realValue/0.836128)<1000000?parseFloat((realValue/0.836128).toFixed(2)).toLocaleString(Qt.locale()):parseFloat((realValue/0.836128).toExponential(3)).toLocaleString(Qt.locale())),unit:areaUnits.kSqYards})

                    measurementUnit.listView.currentIndex = sketchEditorManager.selectedmeasurementUnitIndex

                }
                measurementUnit.updateLabel(realValue)

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

            function replaceDirectionStrings (originalText, replacement) {
                var directions = ["N", "S", "E", "W"]
                for (var i=0; i<directions.length; i++) {
                    originalText = originalText.replace(directions[i],
                                                        "%1 %2".arg(replacement).arg(directions[i]))
                }
                return originalText
            }


            function updateMapUnitsModel (pt) {
                if (!pt) return
                var index = measurementUnit.listView.currentIndex
                measurementUnit.model.clear()
                //var isEmpty = mapView.mapunitsListModel.count === 0,
                let  DD = CoordinateFormatter.toLatitudeLongitude(pt, Enums.LatitudeLongitudeFormatDecimalDegrees, 3)
                let  DM = CoordinateFormatter.toLatitudeLongitude(pt, Enums.LatitudeLongitudeFormatDegreesDecimalMinutes, 3)
                let DMS = CoordinateFormatter.toLatitudeLongitude(pt, Enums.LatitudeLongitudeFormatDegreesMinutesSeconds, 3)
                let MGRS = CoordinateFormatter.toMgrs(pt, Enums.MgrsConversionModeAutomatic, 3, true)
                let mapUnitsObjects = [

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

                    measurementUnit.model.append({itemLabel: mapUnitsObjects[i].value,unit:mapUnitsObjects[i].name})

                }
                measurementUnit.listView.currentIndex = index < 0 ? 0 : index
                measurementUnit.updateLabel(1)
            }

        }

        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: app.units(16)
        }
    }

}
