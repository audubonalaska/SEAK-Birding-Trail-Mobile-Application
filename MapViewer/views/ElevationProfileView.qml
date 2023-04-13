import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1 as QtControls
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1
import ArcGIS.AppFramework 1.0
import QtCharts 2.1


import Esri.ArcGISRuntime 100.14

import "../../MapViewer/controls" as Controls

import "../../assets"

QtControls.Page {
    id: elevationProfileView

    width: parent.width
    height: parent.height
    Material.background: "white"
    // Elevation chart
    property double mMin: 0
    property double mMax: 10
    property double zMin: 0
    property double zMax: 100
    property var trailLength:""
    // Conversions
    property real metersToMiles: 0.000621371
    property real metersToFeet: 3.28084
    property var distanceVal:0
    property var elevationVal:0
    property var mapLocationDic:({})
    property var feature
    property var elevSummaryJobObject
    property var jobstatus:""
    readonly property url units_select:"../../MapViewer/images/check.png"
    property  var selectedMeasurementUnits:measurementUnits.imperial
    property var elevationSummary:null
    property var chartData:null
    property var indicatorY:null
    property bool screenWidth:app.isLandscape
    property var distanceArray: []
    property var elevationArray: []

    signal plotXYOnPolyline(var pointGeometry)
    signal failed(var err)
    signal setTitleWithUnits(var units)
    //signal openMoreMenu(var x,var y)
    //signal clearXYOnPolyline()

    QtObject {
        id: measurementUnits

        property int metric: 0
        property int imperial: 1

    }


    Connections{
        target:panelPageLoader.item
        function onDockToTop(){
            clearDottedLines()
        }
        function onDockToBottom(){
            clearDottedLines()
        }
    }




    onSelectedMeasurementUnitsChanged: {

        if(chartData)
        {
            //chartView.removeAllSeries()
            xPositionerX.clear()
            positionery.clear()
            xMagText.text = ""
            yMagText.text = ""

            processChartData(chartData)
        }

        if(elevationSummary){
            populateProfileSummary(elevationSummary)
            datagrid.forceLayout()
        }
        if(selectedMeasurementUnits === measurementUnits.imperial)
            setTitleWithUnits("ft")
        else
            setTitleWithUnits("m")
    }



    Connections{
        target:mapView

        function onCurrentFeatureIndexForElevationChanged()
        {

            summaryModel.clear()
            xPositionerX.clear()
            positionery.clear()
            datagrid.forceLayout()
            drawElevationChart()
        }


    }


    Timer{
        id:elapsedTimer
        interval:500
        repeat:true
        onTriggered:checkJobStatus()
    }


    NetworkRequest {
        id: networkRequestElevation
        url: "http://elevation.arcgis.com/arcgis/rest/services/Tools/ElevationSync/GPServer/Profile/execute"
        method: "POST"
        responseType: "json"

        onReadyStateChanged: {
            if (readyState !== NetworkRequest.ReadyStateComplete) {
                return;
            }
            if (errorCode) {
                elevationProfileView.failed(strings.elevation_request_network_error.arg(errorCode))


                return;
            }
            if (status < 200 || status >= 300) {
                console.log(statusText,status)
                elevationProfileView.failed(strings.elevation_request_http_error.arg(status))


                return;
            }

            try{
                if (response) {
                    chartData = response
                    processChartData(response)
                    if(!app.isSignedIn)
                        populateProfileSummaryUnsignedUser()

                }
            }
            catch (err) {
                //console.log(err.message)
                elevationProfileView.failed(strings.elevation_request_json_error)


            }

        }
    }


    NetworkRequest {
        id: networkRequestElevationSummary
        url: "https://elevation.arcgis.com/arcgis/rest/services/Tools/Elevation/GPServer/SummarizeElevation/submitJob?f=pjson"
        method: "POST"
        responseType: "json"

        onReadyStateChanged: {
            if (readyState !== NetworkRequest.ReadyStateComplete) {
                return;
            }
            if (errorCode) {
                elevationProfileView.failed(strings.elevation_summary_request_network_error.arg(errorCode))

                return;
            }
            if (status < 200 || status >= 300) {
                // console.log(statusText,status)
                elevationProfileView.failed(strings.elevation_summary_request_http_error.arg(status))


                return;
            }

            try{
                if (response) {
                    let responseObj = response
                    elevSummaryJobObject = responseObj
                    //checkJobStatus
                    elapsedTimer.start()

                }
            }
            catch (err) {
                //console.log(err.message)
                elevationProfileView.failed(strings.elevation_request_json_error)
                return;
            }

        }
    }

    NetworkRequest {
        id: networkRequestElevationJobStatus

        method: "POST"
        responseType: "json"

        onReadyStateChanged: {
            if (readyState !== NetworkRequest.ReadyStateComplete) {
                return;
            }
            if (errorCode) {
                elevationProfileView.failed(strings.elevation_summary_request_network_error.arg(errorCode))

                return;
            }
            if (status < 200 || status >= 300) {
                //console.log(statusText,status)
                elevationProfileView.failed(strings.elevation_summary_request_http_error.arg(status))


                return;
            }
            // if (readyState === NetworkRequest.ReadyStateComplete) {
            try{
                if (response) {
                    if(response.jobStatus === "esriJobSucceeded"){
                        elapsedTimer.stop()
                        jobstatus === "esriJobSucceeded"
                        if (!networkRequestElevationSummaryResult.busy) {
                            //networkRequestElevationSummary.abort();
                            var obj = {}
                            obj["token"] = portalSearch.token
                            obj["f"] = "pjson"
                            networkRequestElevationSummaryResult.url = "https://elevation.arcgis.com/arcgis/rest/services/Tools/Elevation/GPServer/SummarizeElevation/jobs/" + elevSummaryJobObject.jobId + "/results/OutputSummary"

                            networkRequestElevationSummaryResult.send(obj)
                        }
                    }
                    else if(response.jobStatus === "esriJobFailed")
                    {
                        elapsedTimer.stop()

                        toastMessage.show(strings.fetchdata_error)
                        //show a toastMessage
                        populateProfileSummaryUnsignedUser()
                    }

                    else
                    {

                        //console.log("jobstatus:",response.jobStatus )
                        return;
                    }



                }
            }
            catch (err) {
                //console.log(err.message)
                elevationProfileView.failed(strings.elevation_summary_request_json_error)

                return;
            }

        }
    }



    NetworkRequest {
        id: networkRequestElevationSummaryResult
        method: "POST"
        responseType: "json"

        onReadyStateChanged: {
            if (readyState !== NetworkRequest.ReadyStateComplete) {
                return;
            }
            if (errorCode) {
                elevationProfileView.failed(strings.elevation_summary_request_network_error.arg(errorCode))

                return;
            }
            if (status < 200 || status >= 300) {
                //console.log(statusText,status)
                elevationProfileView.failed(strings.elevation_request_http_error.arg(status))
                return;
            }

            try{
                if (response) {

                    elevationSummary = response.value
                    populateProfileSummary(response.value)


                }
            }
            catch (err) {

                elevationProfileView.failed(strings.elevation_summary_request_json_error)

                return;
            }

        }
    }


    onFailed: {
        console.error(err)
        if(err)
            busyIndicatorText.text = err
        busyIndicatorText.visible = true
        busyIndicator.visible = false

    }

    function clearDottedLines(){
        xMagText.text = ""
        yMagText.text = ""
        xPositionerX.visible = false
        positionery.visible = false

    }

    function processChartData(chartData)
    {
        lineSeries.clear()
        lineSeries2.clear()
        elevationpointGraphicsOverlay.graphics.clear()
        // Create elevation profile
        var xyzm
        var dist
        var elev
        distanceArray = []
        elevationArray = []
        var responseObj = chartData

        if(chartData.results[0].value){
            busyIndicator.visible = false


            for (var i = 0; i < chartData.results[0].value.features[0].geometry.paths.length; i++) {
                for (var j = 0; j < chartData.results[0].value.features[0].geometry.paths[i].length; j++) {
                    xyzm = chartData.results[0].value.features[0].geometry.paths[i][j]
                    if(selectedMeasurementUnits === measurementUnits.imperial)
                    {

                        dist = ((xyzm[3])* metersToMiles ).toFixed(4)

                        elev = (xyzm[2] * metersToFeet).toFixed(2)
                    }
                    else
                    {
                        dist = (xyzm[3] / 1000) .toFixed(4) //convert to Km
                        elev = (xyzm[2]).toFixed(2)
                    }

                    lineSeries.append(dist, elev)
                    lineSeries2.append(dist, elev)
                    let key = dist.toString() //+ "_" + elev.toString()
                    //mapLocationDic.push()
                    mapLocationDic[key] = {x:xyzm[0],y:xyzm[1]}
                    // mapLocationArray.push({x:xyzm[0],y:xyzm[1]})
                    distanceArray.push(dist)
                    elevationArray.push(elev)
                }
            }

            // Calculate x an y axis min/max to update the chart view
            mMin = (Math.min.apply(Math, distanceArray)).toFixed(3)
            mMax = (Math.max.apply(Math, distanceArray)).toFixed(3)
            zMin = (Math.min.apply(Math, elevationArray)).toFixed(2)
            zMax = (Math.max.apply(Math, elevationArray)).toFixed(2)


            drawProfileStartMarker()
            // drawProfileEndMarker()

            if(!portalSearch.token > "")
                populateProfileSummaryUnsignedUser()
        }
        else
        {

        }

    }

    function drawProfileEndMarker()
    {
        let dist  = distanceArray[distanceArray.length - 1]
        let key = dist.toString()

        let endPoint = mapLocationDic[key]


        var mercator = Factory.SpatialReference.createWebMercator()

        let projectedmappoint = ArcGISRuntimeEnvironment.createObject("Point", {
                                                                          x: endPoint.x,
                                                                          y: endPoint.y,
                                                                          spatialReference:mercator
                                                                      });


        //project it back to map projection
        if(mapView.spatialReference.wkid !== projectedmappoint.spatialReference.wkid)
        {

            let mappoint = GeometryEngine.project(projectedmappoint.geometry,mapView.spatialReference)
            plotXYOnPolyline(mappoint)
        }
        else
            plotXYOnPolyline(projectedmappoint)

        let startPointOnProfile = lineSeries.at(lineSeries.count - 1)//lineSeries.at(0)

        scatter1.clear()

        scatter1.append(startPointOnProfile .x,startPointOnProfile .y)

    }


    function drawProfileStartMarker()
    {
        let startPoint = mapLocationDic[distanceArray[0]]//mapLocationDic["0.0000"]

        var mercator = Factory.SpatialReference.createWebMercator()

        let projectedmappoint = ArcGISRuntimeEnvironment.createObject("Point", {
                                                                          x: startPoint.x,
                                                                          y: startPoint.y,
                                                                          spatialReference:mercator
                                                                      });


        //project it back to map projection
        if(mapView.spatialReference.wkid !== projectedmappoint.spatialReference.wkid)
        {

            let mappoint = GeometryEngine.project(projectedmappoint.geometry,mapView.spatialReference)
            plotXYOnPolyline(mappoint)
        }
        else
            plotXYOnPolyline(projectedmappoint)


        let startPointOnProfile = lineSeries.at(0)

        scatter1.clear()
        // scatter1.append(0.001,zMin)
        scatter1.append(startPointOnProfile .x,startPointOnProfile .y)

        initializeDottedLine(startPointOnProfile)



    }

    function checkJobStatus()
    {
        if(jobstatus !== "esriJobSucceeded")
        {
            if (!networkRequestElevationJobStatus.busy) {
                //networkRequestElevationSummary.abort();
                var obj = {}
                obj["token"] = portalSearch.token
                obj["f"] = "pjson"
                networkRequestElevationJobStatus.url = "https://elevation.arcgis.com/arcgis/rest/services/Tools/Elevation/GPServer/SummarizeElevation/jobs/" + elevSummaryJobObject.jobId

                networkRequestElevationJobStatus.send(obj)
            }
        }
    }

    function getXY(measure,startPoint)
    {


        let pointIndex = 0
        let deltaDistance = 0
        for(let k=0;k< distanceArray.length;k++)
        {

            if(measure >= distanceArray[k] && measure < distanceArray[k+1])
            {
                if( distanceArray[k+1] - measure < .003)
                    pointIndex = k+1
                else if(measure  - distanceArray[k] < .003)
                    pointIndex = k

                else
                {
                    pointIndex = k
                    deltaDistance = measure - distanceArray[k]
                }

                break

            }



        }

        //calculate the geodesic distance
        if(deltaDistance > 0)
        {
            //
            //calculate the geodesic distance between start and k
            let point2X = mapLocationDic[distanceArray[pointIndex]].x
            let point2Y = mapLocationDic[distanceArray[pointIndex]].y

            var mercator = Factory.SpatialReference.createWebMercator()

            let point1 = ArcGISRuntimeEnvironment.createObject("Point", {
                                                                   x: startPoint.x,
                                                                   y: startPoint.y,
                                                                   spatialReference:mercator //Factory.SpatialReference.createWgs84()
                                                               });

            let point2 = ArcGISRuntimeEnvironment.createObject("Point", {
                                                                   x: point2X,
                                                                   y: point2Y,
                                                                   spatialReference:mercator //Factory.SpatialReference.createWgs84()
                                                               });


            //  let geodesicDistance1 = GeometryEngine.distanceGeodetic(point2,point1,Enums.LinearUnitIdMeters,Enums.AngularUnitIdRadians,Enums.GeodeticCurveTypeGeodesic)
            let distance1 = GeometryEngine.distance(point2,point1)

            //calculate the geodesic distance of the other segment
            let point3X = mapLocationDic[distanceArray[pointIndex + 1]].x
            let point3Y = mapLocationDic[distanceArray[pointIndex + 1]].y
            let point3 = ArcGISRuntimeEnvironment.createObject("Point", {
                                                                   x: point3X,
                                                                   y: point3Y,
                                                                   spatialReference:mercator //Factory.SpatialReference.createWgs84()
                                                               });
            //let geodesicDistance_segment = GeometryEngine.distanceGeodetic(point3,point2,Enums.LinearUnitIdMeters,Enums.AngularUnitIdRadians,Enums.GeodeticCurveTypeGeodesic)
            let segment_distance = GeometryEngine.distance(point3,point2)

            let partdistance = (deltaDistance/(distanceArray[pointIndex + 1] - distanceArray[pointIndex])) * segment_distance

            //get the new point1
            let totaldistance = parseFloat(partdistance + distance1)
            feature = identifyManager.features[mapView.currentFeatureIndexForElevation]
            // let mercator = Factory.SpatialReference.createWebMercator()
            let  projectedFeature = GeometryEngine.project(feature.geometry, mercator)

            let calculatedPoint = GeometryEngine.createPointAlong(projectedFeature,totaldistance)
            return({x:calculatedPoint.x,y:calculatedPoint.y})

        }
        else
        {


            let newX = mapLocationDic[distanceArray[pointIndex]].x
            let newY = mapLocationDic[distanceArray[pointIndex]].y

            return({x:newX,y:newY})
        }


    }
    function getConvertedValue(value,targetUnits)
    {
        let convertedValue = value
        switch (targetUnits){
        case strings.ft:
            convertedValue = parseFloat((3.28084 * value).toFixed(2)).toLocaleString(Qt.locale())
            break
        case strings.mi:
            convertedValue = parseFloat((0.000621371 * value).toFixed(2)).toLocaleString(Qt.locale())
            break
        case strings.km:
            convertedValue = parseFloat((value / 1000).toFixed(2)).toLocaleString(Qt.locale())
            break
        }
        return convertedValue


    }

    function calculateGainOrLoss(){
        let gain = 0
        let loss = 0
        for(let k=0;k< elevationArray.length - 1;k++)
        {
            let elevation_from = elevationArray[k]
            let elevation_to = elevationArray[k+1]
            if(elevation_to > elevation_from)
            {
                gain = parseFloat(gain) + parseFloat((Math.abs(elevation_to) - Math.abs(elevation_from)))
            }
            else
            {
                loss = parseFloat(loss) + parseFloat((Math.abs(elevation_from) - Math.abs(elevation_to)))
            }


        }
        if(gain > 0)
            gain = parseFloat(gain.toFixed(2)).toLocaleString(Qt.locale())
        if(loss > 0)
            loss = parseFloat(loss.toFixed(2)).toLocaleString(Qt.locale())

        return {"gain":gain,"loss":loss}

    }



    function populateProfileSummaryUnsignedUser(){
        if(!elevationSummary){
            summaryModel.clear()


            let elevationUnits = strings.ft
            let lengthUnits = strings.mi
            let trail = 0

            if(selectedMeasurementUnits === measurementUnits.metric)
            {
                elevationUnits = strings.m
                lengthUnits = strings.km
            }


            let minElev = parseFloat(zMin).toLocaleString(Qt.locale())
            let maxElev = parseFloat(zMax).toLocaleString(Qt.locale())
            let gainlossObj = calculateGainOrLoss()
            let gain = gainlossObj.gain
            let loss = gainlossObj.loss
            let trail_inMeasurementUnits = getTrailLength()



            summaryModel.append({name:strings.min_elevation,value:`${minElev}`,measureunits: `${elevationUnits}`})
            summaryModel.append({name:strings.max_elevation,value:`${maxElev}`,measureunits: `${elevationUnits}`})
            summaryModel.append({name:strings.gain,value:`${gain}`, measureunits: `${elevationUnits}`})
            summaryModel.append({name:strings.loss,value:`${loss}`,measureunits: `${elevationUnits}`})
            summaryModel.append({name:strings.trail_length,value:`${trail_inMeasurementUnits}`, measureunits:`${elevationUnits}`})


        }

    }

    function getTrailLength()
    {
        let trail = 0
        if(selectedMeasurementUnits === measurementUnits.metric)
        {
            let length_kms = parseFloat((mMax).toFixed(2))
            let length_meters = (length_kms * 1000).toFixed(2)
            trail = length_meters

        }
        else
        {
            let length_miles = parseFloat((mMax).toFixed(2))
            let length_feet = (length_miles * 5280).toFixed(2)
            trail = length_feet
        }
        let trail_inMeasurementUnits = parseFloat(trail).toLocaleString(Qt.locale())
        return trail_inMeasurementUnits
    }


    function populateProfileSummary(responseValue)
    {

        summaryModel.clear()

        let elevationUnits = strings.ft
        let lengthUnits = strings.mi

        if(selectedMeasurementUnits === measurementUnits.metric)
        {
            elevationUnits = strings.m
            lengthUnits = strings.km
        }

        if(responseValue && responseValue.features.length > 0)
        {
            let summaryObj = responseValue.features[0].attributes
            let degreesymbol = "\xB0"
            if (summaryObj.hasOwnProperty("MinElevation"))
            {

                if(selectedMeasurementUnits === measurementUnits.imperial)
                {
                    let min_elev_meters = parseFloat(summaryObj["MinElevation"]).toFixed(2)
                    //convert into ft
                    let min_elev_ft = getConvertedValue(min_elev_meters,'ft')
                    summaryModel.append({name:strings.min_elevation,value:`${min_elev_ft}`,measureunits:`${elevationUnits}`})

                }
                else
                {
                    let minElev = parseFloat(summaryObj["MinElevation"].toFixed(2)).toLocaleString(Qt.locale())
                    summaryModel.append({name:strings.min_elevation,value:`${minElev}`,measureunits:`${elevationUnits}`})
                }
            }
            if (summaryObj.hasOwnProperty("MaxElevation"))
            {
                if(selectedMeasurementUnits === measurementUnits.imperial)
                {
                    let _value_meters = parseFloat(summaryObj["MaxElevation"]).toFixed(2)
                    //convert into ft
                    let value = getConvertedValue(_value_meters,'ft')
                    summaryModel.append({name:strings.max_elevation,value:`${value}`,measureunits:`${elevationUnits}`})



                }
                else
                {
                    let maxElev = parseFloat(summaryObj["MaxElevation"].toFixed(2)).toLocaleString(Qt.locale())

                    summaryModel.append({name:strings.max_elevation,value:`${maxElev}`,measureunits:`${elevationUnits}`})
                }
            }

            if (summaryObj.hasOwnProperty("MinSlope"))
            {
                let minslope = parseFloat(summaryObj["MinSlope"].toFixed(2)).toLocaleString(Qt.locale())

                summaryModel.append({name:strings.min_slope,value:`${minslope}`,measureunits:`${degreesymbol}`})

            }

            if (summaryObj.hasOwnProperty("MaxSlope"))
            {
                let maxslope = parseFloat(summaryObj["MaxSlope"].toFixed(2)).toLocaleString(Qt.locale())

                summaryModel.append({name:strings.max_slope,value:`${maxslope}`,measureunits:`${degreesymbol}`})
            }
            if (summaryObj.hasOwnProperty("MeanSlope"))
            {

                let meanslope = parseFloat(summaryObj["MeanSlope"].toFixed(2)).toLocaleString(Qt.locale())

                summaryModel.append({name:strings.avg_slope,value:`${meanslope}`,measureunits:`${degreesymbol}`})

            }

            let gainlossObj = calculateGainOrLoss()
            let gain = gainlossObj.gain
            let loss = gainlossObj.loss

            summaryModel.append({name:strings.gain,value:`${gain}`,measureunits: `${elevationUnits}`})
            summaryModel.append({name:strings.loss,value:`${loss}`,measureunits: `${elevationUnits}`})
            let trail_inMeasurementUnits = getTrailLength()
            summaryModel.append({name:strings.trail_length,value:`${trail_inMeasurementUnits}`, measureunits:`${elevationUnits}`})

        }

    }



    function drawElevationChart()
    {
        //busyIndicator.visible = true
        //busyIndicatorText.visible = false
        xMagText.text = ""
        yMagText.text = ""
        indicator.visible = false
        if(mapView.currentFeatureIndexForElevation > -1){

            feature = identifyManager.features[mapView.currentFeatureIndexForElevation]
            //      mapView.currentFeatureIndexForElevation = _featureIndex
            //draw the profile
            let projectedFeature
            if(feature.geometry.objectType === "Polyline")
            {
                busyIndicator.visible = true
                busyIndicatorText.visible = false
                unitsList.visible = true

                chartView.visible = true
                // chartView.removeAllSeries()
                if(feature.geometry.spatialReference.wkid !== 3857)
                {
                    let mercator = Factory.SpatialReference.createWebMercator()
                    projectedFeature = GeometryEngine.project(feature.geometry, mercator)
                    // Get trail length for sampling size
                    //var trailLength = GeometryEngine.length(GeometryEngine.project(feature.geometry, mercator))
                }
                else
                    projectedFeature =feature

                let _trailLength = GeometryEngine.length(projectedFeature.geometry)
                if(selectedMeasurementUnits === measurementUnits.metric)
                    trailLength  = ((_trailLength / 1000).toFixed(2)).toString() + "Km"
                else
                    trailLength  = (_trailLength * metersToMiles).toFixed(2).toString() + "Mi"

                // Pull elevation information from GP Service
                let noOfsegments = Math.round(_trailLength)//Math.round(40/711 * _trailLength)
                let maxDistanceSampleSize = 0//_trailLength/19//0//_trailLength/noOfsegments //_trailLength/30

                //If the number of vertices is from 200 to the maximum of 1,024, the input line feature will not be densified
                // if the Maximum Sample Distance parameter is empty or not specified.

                let no_vertices =  0
                for(var k=0;k < feature.geometry.json.paths.length; k++)
                {
                    let path = feature.geometry.json.paths[k]
                    no_vertices = no_vertices + path.length

                }
                if(no_vertices > 200 && no_vertices < 1024)
                    maxDistanceSampleSize = _trailLength/1500




                let inputLineFeatures = {fields: [{name: "OID", type: "esriFieldTypeObjectID", alias: "OID"}],
                    geometryType: "esriGeometryPolyline", attributes: {OID: 1}, sr: {wkid: 102100, latestWkid: 3857}}

                let geometryWithoutZ = GeometryEngine.removeZAndM(feature.geometry)
                inputLineFeatures.features = [{geometry: geometryWithoutZ.json}]
                //inputLineFeatures.features = [{geometry: feature.geometry.json}]
                let paramsObject

                if(maxDistanceSampleSize > 0)
                {
                    paramsObject = {InputLineFeatures: JSON.stringify(inputLineFeatures), ProfileIDField: "OID", DEMResolution: "FINEST",
                        MaximumSampleDistance: maxDistanceSampleSize.toString(), MaximumSampleDistanceUnits: "Meters", returnZ: "true",
                        returnM: "true", f: "json"}
                }
                else
                {

                    paramsObject = {InputLineFeatures: JSON.stringify(inputLineFeatures), ProfileIDField: "OID", DEMResolution: "FINEST",
                        MaximumSampleDistanceUnits: "Meters", returnZ: "true",
                        returnM: "true", f: "json"}
                }



                // console.log(JSON.stringify(paramsObject))
                networkRequestElevation.send(paramsObject)


                fetchSummary(feature)
            }
            else
            {
                unitsList.visible = false
                chartView.visible = false
                 mapView.elevationPtGraphicsOverlay.graphics.clear()
                //clearXYOnPolyline()

                //summaryModel.clear()

            }
        }

    }

    function fetchSummary(feature)
    {
        let geometryWithoutZ = GeometryEngine.removeZAndM(feature.geometry)
        var _inFeatures = {
            geometryType:"esriGeometryPolyline",
            spatialReference:{wkid: 102100, latestWkid: 3857},
            fields: [{name: "OBJECTID", type: "esriFieldTypeOID", alias: "OBJECTID"}],
            features: [{geometry: geometryWithoutZ.json}]

        }

        var paramObj = {InputFeatures :JSON.stringify(_inFeatures),DEMResolution: "FINEST",IncludeSlopeAspect:true}

        if(app.isSignedIn)
        {
            paramObj["token"] = portalSearch.token

            if (!networkRequestElevationSummary.busy && portalSearch.token > "") {

                networkRequestElevationSummary.send(paramObj)
            }
        }


    }

    function getXYOnProfile(measure)
    {
        let pointIndex = 0
        for(let k=0;k< distanceArray.length;k++)
        {

            if(measure >= distanceArray[k] && measure < distanceArray[k+1])
            {
                pointIndex = k
                break

            }
        }
        let firstpointX = distanceArray[pointIndex]
        let firstpointY = elevationArray[pointIndex]
        let secondpointX = distanceArray[pointIndex + 1]
        let secondpointY = elevationArray[pointIndex + 1]
        let measureDiff = (measure - firstpointX)
        let slope = (secondpointY - firstpointY) / (secondpointX - firstpointX)

        let newX = measure
        let newY = (slope *(newX - firstpointX) + parseFloat(firstpointY))


        return({x:newX,y:newY})

    }


    function initializeDottedLine(startPoint)
    {
        xPositionerX.append(startPoint.x,0)
        xPositionerX.append(startPoint.x,startPoint.y)

        positionery.append(0,startPoint.y)
        positionery.append(startPoint.x,startPoint.y)
    }

    function drawXYDottedLines(targetPoint,mouseX, mouseY){
        // var p = Qt.point(mouse.x, mouse.y)
        var cp = targetPoint//chartView.mapToValue(p, areaSeries)



        xPositionerX.replace(xPositionerX.at(0).x,
                             xPositionerX.at(0).y,
                             cp.x, 0)

        xPositionerX.replace(xPositionerX.at(1).x,
                             xPositionerX.at(1).y,
                             cp.x, cp.y)

        positionery.replace(positionery.at(0).x, positionery.at(0).y,
                            0, cp.y)

        positionery.replace(positionery.at(1).x, positionery.at(1).y,
                            cp.x, cp.y)
        if(mouseX)
        {

            xMagView.x = mouseX - xMagView.width/2 //+ app.units(16)

            if(cp.x < mMax && cp.x > mMin)
                xMagText.text = parseFloat((cp.x).toFixed(2)).toLocaleString(Qt.locale())
            else
                xMagText.text = ""

            yMagView.y = mouseY - yMagView.height/2  - chartContent.contentY
            if(cp.y < zMax && cp.y > zMin)
                yMagText.text = parseFloat((cp.y).toFixed(1)).toLocaleString(Qt.locale())

            else
                yMagText.text = ""
        }
        xPositionerX.visible = true
        positionery.visible = true
    }

    ListModel {
        id: summaryModel
    }


    contentItem:Item{
        anchors.fill:parent
        Controls.BaseText {
            id: message

            visible: !chartView.visible && !busyIndicator.visible
            maximumLineCount: 5
            elide: Text.ElideRight
            width: parent.width
            height: visible ? parent.height:0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            anchors.centerIn: parent
            text: qsTr("Elevation Profile not supported.")
        }


        ColumnLayout{
            anchors.fill:parent


            RowLayout{
                Layout.preferredHeight: app.units(32)
                Layout.fillWidth: true



                ListView {
                    id:unitsList
                    Layout.fillWidth: true

                    Layout.preferredHeight: app.units(40)
                    currentIndex: selectedMeasurementUnits === measurementUnits.imperial ? 1 :0
                    model: unitsModel
                    orientation:ListView.Horizontal
                    rightMargin: 20
                    leftMargin: 16
                    spacing: 8
                    layoutDirection: Qt.RightToLeft

                    delegate:Item{
                        width:app.iconSize + lbl.width
                        height: 50


                        Item {
                            id:radioBtnCtrl
                            height:parent.height
                            width:app.iconSize
                            anchors.left:parent.left


                            QtControls.RadioButton {
                                id: radioButton
                                anchors.centerIn: parent
                                checkable: true
                                checked: unitsList.currentIndex === index? true : false
                                Material.primary: app.primaryColor
                                Material.accent: app.accentColor
                                Material.theme:Material.Light

                                onClicked: {
                                    unitsList.currentIndex = index
                                    selectedMeasurementUnits = value

                                }
                            }
                        }

                        Controls.SubtitleText {
                            id: lbl
                            objectName: "label"

                            height: parent.height
                            anchors.right:parent.right

                            visible: text.length > 0
                            text: name
                            verticalAlignment: Text.AlignVCenter
                            color: radioButton.checked ? app.baseTextColor : app.subTitleTextColor
                            elide: Text.ElideMiddle
                            wrapMode: Text.NoWrap
                            leftPadding: 0
                            rightPadding:0

                        }




                    }
                }

            }


            Flickable {
                id:chartContent
                Layout.fillHeight: true
                Layout.fillWidth: true
                //anchors.fill: parent
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                interactive: true
                contentHeight:pageContent.height
                clip:true

                states: State {
                    name: "autoscroll"
                    PropertyChanges {
                        target: xMagView
                        y: chartView.plotArea.y + chartView.plotArea.height - chartContent.contentY//contentY//messageArea.height - height
                    }

                }
                onMovementEnded: {

                    if (contentY > 0) {
                        state = "autoscroll"
                    }
                    else {
                        state = ""  // default state
                    }
                }

                onMovementStarted: {
                    xMagText.text = ""
                    yMagText.text = ""
                    xPositionerX.visible = false
                    positionery.visible = false
                }



                QtControls.BusyIndicator {
                    id: busyIndicator
                    Material.primary: app.primaryColor
                    Material.accent: app.accentColor
                    visible: false
                    width: 5 * app.baseUnit
                    height: 5 * app.baseUnit
                    anchors.centerIn: parent

                }

                QtControls.Label {
                    id: busyIndicatorText

                    width: parent.width
                    visible: false
                    text: strings.loading
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.bold: true
                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                }


                ColumnLayout{
                    id:pageContent
                    width:parent.width

                    spacing:0

                    Item{
                        Layout.preferredHeight: app.units(200)
                        Layout.fillWidth: parent
                        ChartView {
                            id: chartView
                            width: parent.width + app.units(8)
                            height: parent.height
                            //x:-10
                            legend.visible: false
                            margins.bottom:0
                            margins.left:0//app.defaultMargin
                            margins.right:0//app.defaultMargin
                            margins.top:0
                            visible:!busyIndicator.visible && !busyIndicatorText.visible
                            localizeNumbers:true
                            anchors.centerIn: parent

                            MouseArea{
                                anchors.fill: parent
                                cursorShape: Qt.CrossCursor
                                propagateComposedEvents:true
                                // acceptedButtons:Qt.RightButton

                                onClicked:{
                                    var p = Qt.point(mouse.x, mouse.y)
                                    var cp = chartView.mapToValue(p, areaSeries)
                                    var xdistance = parseFloat(cp.x).toFixed(5)
                                    let XY = getXYOnProfile(xdistance)
                                    let  targetPoint = Qt.point(XY.x, XY.y)

                                    let mousePos = chartView.mapToPosition(targetPoint,lineSeries2)

                                    scatter1.clear()
                                    scatter1.append(targetPoint.x,targetPoint.y)
                                    drawXYDottedLines(targetPoint,mousePos.x, mousePos.y)


                                    let distanceInMeters = cp.x
                                    if(selectedMeasurementUnits === measurementUnits.imperial)
                                        distanceInMeters = cp.x /metersToMiles
                                    let startPoint = mapLocationDic[distanceArray[0]]

                                    let mapPointObject = getXY(cp.x,startPoint)


                                    var mercator = Factory.SpatialReference.createWebMercator()

                                    let projectedmappoint = ArcGISRuntimeEnvironment.createObject("Point", {
                                                                                                      x: mapPointObject.x,
                                                                                                      y: mapPointObject.y,
                                                                                                      spatialReference:mercator
                                                                                                  });


                                    //project it back to map projection
                                    if(mapView.spatialReference.wkid !== projectedmappoint.spatialReference.wkid)
                                    {

                                        let mappoint = GeometryEngine.project(projectedmappoint.geometry,mapView.spatialReference)
                                        plotXYOnPolyline(mappoint)
                                    }
                                    else
                                        plotXYOnPolyline(projectedmappoint)




                                }


                                hoverEnabled: true
                            }

                            ValueAxis {
                                id: xAxis
                                min: mMin
                                max: mMax
                                titleText: selectedMeasurementUnits === measurementUnits.imperial ? strings.distance_mi:strings.distance_km


                                titleFont.pixelSize: 12
                                labelsFont: Qt.font({pixelSize:12})

                                gridVisible: false
                                labelFormat: "%.2f"


                            }

                            ValueAxis {
                                id: yAxis
                                min: zMin
                                max: zMax
                                labelFormat: "%.0f"
                                labelsFont: Qt.font({pixelSize:12})
                                //titleText: "Elevation (ft)"
                                titleFont.pixelSize: 12
                            }

                            LineSeries {
                                name: "xPositioner"
                                id: xPositionerX
                                axisX: xAxis
                                axisY: yAxis


                                style: Qt.DashLine



                            }

                            LineSeries {
                                name: "LineSeries"
                                id: positionery
                                style: Qt.DashLine
                                axisX: xAxis
                                axisY: yAxis

                            }



                            LineSeries {
                                id: lineSeries2
                                style:Qt.SolidLine
                                width:4
                                color:app.primaryColor//"darkgreen"//"#F79056"//"orange"
                                onClicked: {


                                    var cp = point//chartView.mapToValue(p, areaSeries)
                                    let distanceInMeters = cp.x + 0.004
                                    if(selectedMeasurementUnits === measurementUnits.imperial)
                                        distanceInMeters = cp.x/metersToMiles


                                    let startPoint = mapLocationDic[distanceArray[0]]//mapLocationDic["0.0000"]
                                    var mousePos  =  chartView.mapToPosition(cp,lineSeries2)

                                    indicator.x = mousePos.x - 15//indicator.width/2
                                    indicator.y = mousePos.y - indicator.height/2 - chartContent.contentY
                                    indicatorY = indicator.y
                                    indicator.visible = true
                                    let mapPointObject = getXY(distanceInMeters,startPoint)

                                    var mercator = Factory.SpatialReference.createWebMercator()

                                    let projectedmappoint = ArcGISRuntimeEnvironment.createObject("Point", {
                                                                                                      x: mapPointObject.x,
                                                                                                      y: mapPointObject.y,
                                                                                                      spatialReference:mercator //Factory.SpatialReference.createWgs84()
                                                                                                  });


                                    //project it back to map projection
                                    if(mapView.spatialReference.wkid !== projectedmappoint.spatialReference.wkid)
                                    {

                                        let mappoint = GeometryEngine.project(projectedmappoint.geometry,mapView.spatialReference)
                                        plotXYOnPolyline(mappoint)
                                    }
                                    else
                                        plotXYOnPolyline(projectedmappoint)


                                }


                            }
                            AreaSeries {
                                id:areaSeries
                                axisX: xAxis
                                axisY: yAxis
                                color:app.primaryColor //"#FFEFE6"//"green"
                                opacity: 0.5
                                borderColor:app.primaryColor //"#F79056"//"darkgreen"
                                borderWidth: 1
                                upperSeries:LineSeries {
                                    id: lineSeries
                                    onClicked: {
                                        // console.log("clicked")
                                    }


                                }
                                //upperSeries: lineSeries
                                //pointLabelsVisible: true
                                onClicked: {

                                }
                            }
                            ScatterSeries {
                                id: scatter1
                                name: "Scatter1"
                                color: "red"
                                markerSize: 12
                                // borderColor: "red"


                            }

                        }
                    }



                    RowLayout{
                        Layout.fillWidth: parent
                        Layout.preferredHeight: (busyIndicator.visible || busyIndicatorText.visible) ? 0 :(summaryModel.count > 5 ? 252 : 196)
                        visible: summaryModel.count > 0 ? true : false
                        spacing:0
                        Rectangle{
                            Layout.preferredWidth:5
                            Layout.fillHeight: parent

                        }

                        Rectangle{
                            Layout.preferredWidth:5
                            Layout.fillHeight: parent
                            color:app.primaryColor//"orange"
                        }

                        Rectangle{
                            Layout.fillWidth: parent
                            Layout.preferredHeight: parent.height
                            color:"#50CCCCCC"


                            GridView {
                                id:datagrid
                                anchors.fill:parent
                                topMargin: 24
                                leftMargin: app.defaultMargin
                                rightMargin: app.defaultMargin
                                cellWidth: (parent.width - 2 * defaultMargin)/2
                                cellHeight: 56
                                interactive: false
                                flow:GridView.FlowLeftToRight
                                LayoutMirroring.enabled: true
                                layoutDirection:app.isLeftToRight ? Qt.RightToLeft : Qt.LeftToRight

                                model: summaryModel
                                delegate: ColumnLayout {
                                    width:datagrid.cellWidth

                                    spacing:4
                                    Text {
                                        text: name
                                        Layout.alignment:Qt.AlignHCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        color:colors.blk_140//"#6A6A6A"
                                        font.pixelSize: 12

                                    }
                                    RowLayout{
                                        Layout.preferredHeight: app.units(20)
                                        Layout.alignment:Qt.AlignHCenter

                                        spacing:1

                                        Text
                                        {
                                            text: value;
                                            color:colors.blk_200
                                            font.pixelSize: 12
                                            //Layout.alignment:Qt.AlignHCenter
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        Text
                                        {
                                            text: measureunits
                                            color:colors.blk_200
                                            font.pixelSize: 12
                                            //Layout.alignment:Qt.AlignHCenter
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }
                        Rectangle{
                            Layout.preferredWidth:5
                            Layout.fillHeight: parent

                        }

                    }
                }

                Rectangle {
                    id: xMagView
                    width:xMagText.width + 8
                    clip: true
                    height: 20
                    color:"#90000000"//"#592e2e2e"

                    y:chartView.plotArea.height + 20//chartView.plotArea.y + chartView.plotArea.height
                    x: chartView.plotArea.x + app.units(16)
                    Material.elevation: 100
                    visible: xMagText.text > ""

                    Text {
                        clip: true
                        id: xMagText
                        //anchors.fill: parent
                        wrapMode: Text.WrapAnywhere
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        //text:"x-ax"
                        color: "white"
                        visible:text > ""
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    id: yMagView
                    width:yMagText.width + 8
                    clip: true
                    height: 20
                    color: "#90000000"//"#592e2e2e"
                    y: chartView.plotArea.y
                    x: elevationProfileView.x + 5//chartView.plotArea.x  - 9//+ 2
                    Material.elevation: 100
                    visible:yMagText.text > ""
                    radius:2

                    Text {
                        clip: true
                        id: yMagText
                        //anchors.fill: parent
                        wrapMode: Text.WrapAnywhere
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        //text:"y-ax"
                        color:"white"
                        font.pixelSize: 12
                        padding: 2
                        //visible:text > ""
                    }
                }



            }
        }

        Rectangle {
            id: indicator
            radius: 16
            width: radius / 2
            height: width
            color: "red"
            visible:false
            property real parentWidth: chartView.width
            property real parentHeight: chartView.height
        }
    }
    ListModel {
        id:unitsModel
        ListElement {
            name: qsTr("Metric")
            value: 0
        }
        ListElement {
            name: qsTr("Imperial")
            value: 1
        }
    }


    Component.onCompleted: {
        drawElevationChart()

    }
    Component.onDestruction:{
        //mapView.identifyProperties.zoomToPreviousExtent()
    }



}
