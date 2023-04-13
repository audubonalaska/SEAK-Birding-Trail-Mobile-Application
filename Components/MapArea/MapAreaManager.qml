import QtQuick 2.0
import QtQuick.Controls 2.1
import Esri.ArcGISRuntime 100.14
import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0

Item {
    id:mapAreaManager
    property MapView mapView:null
    property var mapAreasModel:ListModel{}
    property int mapAreasCount:0
    property var mapAreaGraphicsArray:[]
    property var existingmapareas:null
    property var mapAreaslst:[]
    //property alias offlineMapTask:offlineMapTask
    //property bool hasMapArea:false
    property var portalItem
    property var mapProperties: Object
    property Geodatabase offlineGdb:null
    property var  offlineSyncTask:null
    property var _offlineMapTask:null
    property var downloadList:[]
    property var processingList:[]
    property var activeDownloadObject:({})
    property var mapPortalItemId
    property var thumbnailUrl
    property var thumbnailImgName
    property var offlineMapJob
    // property var  mapAreas:[]

    property var mapareaiddownloading:[]

    property var activeJob:null
    property var activeDownloadIndex

    signal mapSyncCompleted(string title)
    signal saveCurrentViewerJson(string appId,bool isUpdate)
    signal mapAreaOpened()

    FileFolder{
        id:mapAreaFolder

    }

    FileFolder{
        id:mapAreaContentFolder


    }
    FileFolder{
        id:mapAreaThumbnailFolder

    }

    Component{
        id: networkRequestComponent
        NetworkRequest{
            id: networkRequest

            property var name;
            property var callback;

            method: "GET"
            ignoreSslErrors: true



            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE ){
                    if(errorCode != 0){
                        fileFolder.removeFile(networkRequest.name);
                        loadStatus = 2;

                    } else {

                        if (callback) {
                            callback();
                        }
                    }
                }
            }

            function downloadImage(downloadedmapareaId,callback){

                var url= thumbnailUrl.split("?")
                if(securedPortal && securedPortal.credential)
                    thumbnailUrl = url[0] + "?token="+ securedPortal.credential.token
                networkRequest.url = thumbnailUrl;
                networkRequest.responsePath = mapAreaThumbnailFolder.path + "/" + downloadedmapareaId + "_thumbnail" + "/" + thumbnailImgName;
                networkRequest.callback = callback;
                networkRequest.send();

            }
        }
    }



    PortalItem {
        id: mapPortalItem
        portal: app.portal
        type: Enums.PortalItemTypeWebMap

        itemId: portalItem ? portalItem.id:null
        onLoadStatusChanged: {
            if(loadStatus === Enums.LoadStatusFailedToLoad)
            {
                console.error("error while loading portal")
            }
            if (loadStatus !== Enums.LoadStatusLoaded)
                return;

            // Load offline map task.
            offlineMapAreaTask.load();
        }

    }

    OfflineMapTask {
        id: offlineMapAreaTask


        portalItem:mapPortalItem
        onCreateDefaultDownloadPreplannedOfflineMapParametersStatusChanged: {
            if (createDefaultDownloadPreplannedOfflineMapParametersStatus !== Enums.TaskStatusCompleted)
                return;
            const result = createDefaultDownloadPreplannedOfflineMapParametersResult;
            processMapAreaParameters(result)


        }

    }


    function processDownloadList()
    {

        if(processingList.length === 0 && downloadList.length > 0)
        {

            let downloadObj = downloadList.pop()
            let downloadIndx = downloadObj.index
            let thumbnailImg = downloadObj.thumbnailImg
            let mapid = downloadObj.mapid
            let appid = downloadObj.appid
            let mapArea = downloadObj.mapArea
            processingList.push(downloadObj)//processingList.push(downloadIndx)
            downloadMapArea(downloadIndx,thumbnailImg,mapid,appid,mapArea)
        }



    }

    function cancelDownloadTask(){
        return  new Promise((resolve, reject) => {
                                if ( !activeJob || activeJob.jobStatus === Enums.JobStatusSucceeded || activeJob.jobStatus === Enums.JobStatusFailed ){
                                    resolve()
                                } else{
                                    cancelActiveJob(resolve,reject)
                                }
                            });
    }

    function cancelActiveJob(resolve,reject){

        app.messageDialog.width = messageDialog.units(300)
        app.messageDialog.standardButtons = Dialog.No | Dialog.Yes

        app.messageDialog.show(strings.cancel_download,strings.cancel_downloading)

        app.messageDialog.connectToAccepted(function () {
            activeJob.cancel()
            processingList = []
            mapAreasModel.setProperty(activeDownloadIndex, "isDownloading", false)
            resolve()
        })
        app.messageDialog.connectToRejected(function () {

            reject()
        })
    }

    function updateMapAreaInfo (storageBasePath) {
        var fileName = "mapareasinfos.json"
        var mapAreafileName = "mobile_map.marea"
        var fileContent = {"results": []}
        var mapAreaFileContent = ""
        //var storageBasePath = offlineMapAreaCache.fileFolder.path + "/"
        //var storageBasePath = outputFilePath + "/"
        //first read the mapareasInfos.json file

        //var mapareacontainerpath = [storageBasePath,mapPortalItemId].join("/")
        let fileInfoMapAreaContainer = AppFramework.fileInfo(storageBasePath)
        let mapAreaContainerFolder = fileInfoMapAreaContainer.folder
        if (mapAreaContainerFolder.fileExists(fileName)) {
            fileContent = mapAreaContainerFolder.readJsonFile(fileName)
        }
        //filter the downloaded maparea from contents
        fileContent.results.map(item => item.id )
        const newArray = fileContent.results.map(item => {
                                                     if(item.id === portalItem.id)
                                                     {
                                                         //var ts = Math.round((new Date()).getTime() / 1000)
                                                         var today = new Date();
                                                         var date = (today.getMonth()+1) + '/'+ today.getDate()+'/'+ today.getFullYear();
                                                         item.modifiedDate = date
                                                     }

                                                 }
                                                 );


        //update the jsonfile
        mapAreaContainerFolder.writeJsonFile(fileName, fileContent)


    }


    function checkExistingAreas(storageBasePath)
    {
        var fileName = "mapareasinfos.json"
        var fileContent = null
        let fileInfoMapAreaContainer = AppFramework.fileInfo(storageBasePath)
        let mapAreaContainerFolder = fileInfoMapAreaContainer.folder

        //if (offlineMapAreaCache.fileFolder.fileExists(fileName)) {
        if (mapAreaContainerFolder.fileExists(fileName)) {
            fileContent = mapAreaContainerFolder.readJsonFile(fileName)

            var results = fileContent.results
            existingmapareas = results.filter(item => item.mapid === portalItem.id)
        }
        return existingmapareas

    }

    function drawMapAreas()
    {
        mapView.polygonGraphicsOverlay.graphics.clear()
        mapAreaGraphicsArray.forEach((graphic)=>{

                                         mapView.polygonGraphicsOverlay.graphics.append(graphic)

                                     }
                                     )

        mapView.setViewpointGeometryAndPadding(mapView.polygonGraphicsOverlay.extent,100)

    }




    function loadUnloadedMapAreas()
    {
        if(mapAreasCount !== mapAreasModel.count)
        {
            //check for the unloaded maparea
            for(var j=0;j< mapAreasCount; j++)
            {
                let mapArea = _offlineMapTask.preplannedMapAreaList.get(j);
                var id = mapArea.portalItem.itemId
                if(!isMapAreaPresentInModel(id))
                {
                    loadMapArea(mapArea)
                }
            }
            mapAreaManager.drawMapAreas()
        }
    }

    function isMapAreaPresentInModel(id)
    {
        for(var p=0;p < mapAreasModel.count;p++)
        {
            var mapAreaObj = mapAreasModel.get(p)
            var portalItem = mapAreaObj.portalItem
            if(portalItem.itemId === id)
                return true
        }
        return false
    }


    function loadMapArea(mapArea)
    {
        var token = null
        var url = ""
        if(portal && app.isSignedIn)
            token = portal.credential.token
        mapArea.loadStatusChanged.connect(function () {
            if (mapArea.loadStatus !== Enums.LoadStatusLoaded)
                return;

            var  mapAreaPolygon = null;
            var mapAreaGeometry = mapArea.areaOfInterest;
            if (mapAreaGeometry.geometryType === Enums.GeometryTypeEnvelope)
                mapAreaPolygon = GeometryEngine.buffer(mapAreaGeometry, 0);
            else
                mapAreaPolygon = mapAreaGeometry;

            const graphic = ArcGISRuntimeEnvironment.createObject("Graphic", { symbol: simpleMapAreaFillSymbol,geometry: mapAreaPolygon });

            mapAreaGraphicsArray.push(graphic)
            var _size = 0
            var _title = ""

            for(let j = 0;j < mapArea.packageItems.count;j++){
                var content_data = mapArea.packageItems.get(j)
                _size += parseInt(content_data.size)
            }

            if(_size < 1024)
                _size = _size + " Bytes"
            else
                _size = mapViewerCore.getFileSize(_size)

            var _portalItem = mapArea.portalItem
            var _areaOfInterest = mapArea.areaOfInterest
            var _mapAreaItemId = _portalItem.itemId
            var mapareajson = _portalItem.json
            var _thumbnailpath = mapareajson.thumbnail

            var _modifiedDate = ""
            if(mapareajson.modified !== null)
            {
                _modifiedDate = mapareajson.modified
            }

            var _createdDate = mapareajson.created
            var _owner = mapareajson.owner


            var _isdownloaded = false
            if(existingmapareas)
            {
                var _existingrecs = existingmapareas.filter(item => item.id === _mapAreaItemId)
                if(_existingrecs.length > 0)
                    _isdownloaded=true
            }

            _title = mapareajson.title
            if(token && _thumbnailpath)
            {
                var prefix = "?token="+ token
                url =  app.portalUrl + ("/sharing/rest/content/items/%1/info/%2%3").arg(_mapAreaItemId).arg(_thumbnailpath).arg(prefix);
            }
            else
            {
                if(_thumbnailpath)
                    url = app.portalUrl + ("/sharing/rest/content/items/%1/info/%2").arg(_mapAreaItemId).arg(_thumbnailpath)
            }

            if(!isMapAreaPresentInModel(mapArea.portalItem.itemId))
            {
                mapAreasModel.append({"mapArea":mapArea,"portalItem":_portalItem,"thumbnailImg":_thumbnailpath,"thumbnailurl":url,"title":_title,"areaOfInterest":_areaOfInterest,"size":_size,"createdDate":_createdDate,"modifiedDate":_modifiedDate,"isPresent":_isdownloaded,"owner":_owner,"isDownloading":false,"isSelected":false})
                mapAreaslst.push({"mapArea":mapArea,"portalItem":_portalItem,"thumbnailImg":_thumbnailpath,"thumbnailurl":url,"title":_title,"areaOfInterest":_areaOfInterest,"size":_size,"createdDate":_createdDate,"modifiedDate":_modifiedDate,"isPresent":_isdownloaded,"owner":_owner})
            }
        });
        mapArea.load();

    }

    function loadMapAreaFromId(id)
    {
        for(var k=0; k<_offlineMapTask.preplannedMapAreaList.count; k++)
        {
            let mapArea = _offlineMapTask.preplannedMapAreaList.get(k);
            var _portalItem = mapArea.portalItem
            if(_portalItem.itemId === id)
            {
                mapAreaManager.loadMapArea(mapArea)
            }

        }

    }


    function loadMapAreaFromIndex(index)
    {
        var i = index
        let mapArea = _offlineMapTask.preplannedMapAreaList.get(i);
        loadMapArea(mapArea)

    }

    function highlightMapArea(index){
        var graphic = mapAreaGraphicsArray[index]

        // mapView.setViewpointGeometryAndPadding(polygonGraphicsOverlay.extent,100)
        //if(app.isLandscape)
        mapView.setViewpointCenterAndScale(graphic.geometry.extent.center,mapView.scale)

        var graphicList = []

        graphicList.push(graphic)

        mapView.polygonGraphicsOverlay.clearSelection()
        mapView.polygonGraphicsOverlay.selectGraphics(graphicList)
    }


    function downloadMapArea(downloadIndx,thumbnailImg,mapid,appid,mapArea)
    {
        Platform.stayAwake = true
        var _mapArea = mapArea//mapAreas[downloadIndx].mapArea
        if(_mapArea)
        {
            var storageBasePath = offlineMapAreaCache.fileFolder.path
            var mapareapath = [storageBasePath,mapid].join("/")
            // var mapareapath = [storageBasePath,mapPage.portalItem.id].join("/")
            // saveCurrentViewerJson(app.currentAppId,false)
            saveCurrentViewerJson(appid,false)


            var lastindex = thumbnailImg.lastIndexOf('/')
            thumbnailImgName = thumbnailImg.substring(lastindex + 1)

            mapPortalItemId = mapid//mapPage.portalItem.id
            // var mapareapath1 = [storageBasePath,mapPage.portalItem.id,_mapArea.portalItem.itemId].join("/")
            var mapareapath1 = [storageBasePath,mapid,_mapArea.portalItem.itemId].join("/")
            mapAreaContentFolder.path = mapareapath


            var mapAreaitemFolder = mapAreaContentFolder.folder(_mapArea.portalItem.itemId)
            var foldermade3 = mapAreaitemFolder.makeFolder()
            var downloadPath = ""
            if(Qt.platform.os === "windows")
                downloadPath = "file:///"+ mapareapath1
            else
                downloadPath = "file://"+ mapareapath1

            let fileInfo_todelete = AppFramework.fileInfo(mapareapath1)
            let fileFolder_todel = fileInfo_todelete.folder
            fileFolder_todel.removeFolder(_mapArea.portalItem.itemId,true)

            fileFolder_todel.removeFolder(_mapArea.portalItem)

            //create the folder for thumbnail
            mapAreaThumbnailFolder.path = mapareapath //mapareapath2
            var mapAreathumbnailFolder1 = mapAreaThumbnailFolder.folder(_mapArea.portalItem.itemId + "_thumbnail")
            var foldermade4 = mapAreathumbnailFolder1.makeFolder()
            createAndStartOfflineJob(_mapArea,downloadPath,downloadIndx)


        }
        else
        {
            showDownloadFailedMessage(qsTr("Offline map area failed to download."))
            // mapAreaToastMessage.display(qsTr("Offline map area failed to download."))
            mapAreasModel.setProperty(downloadIndx,"isDownloading",false)
        }

    }

    function createAndStartOfflineJob(_mapArea,downloadPath,downloadIndx)
    {
        activeDownloadObject["mapArea"] = _mapArea
        activeDownloadObject["downloadPath"] = downloadPath
        activeDownloadObject["downloadIndx"]  = downloadIndx

        var downloadMapParameters = offlineMapAreaTask.createDefaultDownloadPreplannedOfflineMapParameters(_mapArea)

    }

    function processMapAreaParameters(result)
    {
        let downloadPath = activeDownloadObject["downloadPath"]
        let downloadIndx = activeDownloadObject["downloadIndx"]
        mapAreaManager.activeDownloadIndex = downloadIndx
        let _mapArea = activeDownloadObject["mapArea"]

        var offlineMapJob = offlineMapAreaTask.downloadPreplannedOfflineMapWithParameters(result, downloadPath)
        mapAreaManager.activeJob = offlineMapJob
        offlineMapJob.statusChanged.connect(()=> {
                                                if (offlineMapJob.jobStatus === Enums.JobStatusFailed) {
                                                    console.error(offlineMapJob.error.message + " - " + offlineMapJob.error.additionalMessage)
                                                    let   errormsg = offlineMapJob.error.message + "."+ offlineMapJob.error.additionalMessage
                                                    showDownloadFailedMessage(errormsg,_mapArea.portalItem.title)
                                                    mapAreasModel.setProperty(downloadIndx,"isDownloading",false)

                                                    return;
                                                } else if (offlineMapJob.jobStatus !== Enums.JobStatusSucceeded) {
                                                    return;
                                                }
                                            })

        offlineMapJob.resultChanged.connect(() => {

                                                if(offlineMapJob.result){

                                                    if(!offlineMapJob.result.hasErrors)
                                                    {
                                                        let mapareadownloaded = processingList[0].mapArea//mapAreas[downloadIndx]
                                                        downloadThumbnail(_mapArea.portalItem.itemId,saveMapInfo(_mapArea.portalItem.itemId,mapareadownloaded))
                                                    }
                                                    else
                                                    {

                                                        let errormsg = ""
                                                        if(offlineMapJob.result.layerErrors && offlineMapJob.result.layerErrors.length > 0)
                                                        {
                                                            if(offlineMapJob.result.layerErrors.length > 0)
                                                            {

                                                                errormsg = offlineMapJob.result.layerErrors[0].error.message + "."+ offlineMapJob.result.layerErrors[0].error.additionalMessage
                                                            }

                                                        }
                                                        if(errormsg > "")
                                                        {
                                                            showDownloadFailedMessage(errormsg,_mapArea.portalItem.title)

                                                        }
                                                        else
                                                        showDownloadFailedMessage(qsTr("Unknown Error"),_mapArea.portalItem.title)

                                                        mapAreasModel.setProperty(downloadIndx,"isDownloading",false)



                                                    }
                                                }
                                            })
        offlineMapJob.start()
    }




    function downloadThumbnail(downloadedmapareaId,callback)
    {
        var component = networkRequestComponent;
        var networkRequest = component.createObject(parent);
        networkRequest.downloadImage(downloadedmapareaId,callback);
    }
    function saveMapInfo (downloadedmapareaId,mapareadownloaded) {
        var fileName = "mapareasinfos.json"
        var mapAreafileName = "mobile_map.marea"
        var fileContent = {"results": []}
        var mapAreaFileContent = ""
        var gdbpath =""
        var basemaps = []

        var storageBasePath = offlineMapAreaCache.fileFolder.path


        let mapid = processingList[0].mapid
        let appid = processingList[0].appid
        var mapareacontentpath = [storageBasePath,mapid,downloadedmapareaId,"p13",mapAreafileName].join("/")

        // var mapareacontentpath = [storageBasePath,mapPortalItemId,downloadedmapareaId,"p13",mapAreafileName].join("/")
        let fileInfo = AppFramework.fileInfo(mapareacontentpath)
        let mapAreaContentFolder = fileInfo.folder

        var _size = mapAreaContentFolder.size
        //
        if(_size < 1024)
            _size = _size + " Bytes"
        else
            _size = mapViewerCore.getFileSize(_size)


        if (mapAreaContentFolder.fileExists(mapAreafileName)) {
            mapAreaFileContent = mapAreaContentFolder.readJsonFile(mapAreafileName)
        }


        //  var mapareacontainerpath = [storageBasePath,mapPortalItemId].join("/")
        var mapareacontainerpath = [storageBasePath,mapid].join("/")
        let fileInfoMapAreaContainer = AppFramework.fileInfo(mapareacontainerpath)
        let mapAreaContainerFolder = fileInfoMapAreaContainer.folder
        if (mapAreaContainerFolder.fileExists(fileName)) {
            fileContent = mapAreaContainerFolder.readJsonFile(fileName)
        }
        if(mapAreaFileContent.packages)
        {
            for (var i=0; i< mapAreaFileContent["packages"].length; i++)
            {
                var pitem = mapAreaFileContent["packages"][i]
                if(pitem.itemType === "SQLite Geodatabase")
                    gdbpath = pitem.path.split('./')[1]
                else if((pitem.itemType === "Vector Tile Package") || (pitem.itemType === "Tile Package"))
                {
                    var  vtpkpath = pitem.path.split('./')[1]
                    basemaps.push(vtpkpath)
                }

            }
        }

        let _createdDate = new Date(mapareadownloaded.portalItem.created.toString()).toLocaleDateString(AppFramework.localeInfo.name)
        let _modifiedDate = new Date(mapareadownloaded.portalItem.modified.toString()).toLocaleDateString(AppFramework.localeInfo.name)



        var item = {
            "type":"maparea",
            "mapid":mapid,//mapPage.portalItem.id,
            "id":downloadedmapareaId,
            "appId":appid,//app.currentAppId,
            "thumbnailUrl":thumbnailImgName,
            "gdbpath": gdbpath,
            "basemaps": basemaps,
            "title":mapareadownloaded.portalItem.title,
            "createdDate":_createdDate,//mapareadownloaded.portalItem.created,
            "size":_size,
            "owner":mapareadownloaded.portalItem.owner,
            "modifiedDate":_modifiedDate//mapareadownloaded.portalItem.modified

        }

        fileContent.results.push(item)
        mapAreaContainerFolder.writeJsonFile(fileName, fileContent)

        //update the model
        updateModel(downloadedmapareaId,true)

        showDownloadCompletedMessage(mapareadownloaded.title,strings.download_complete)

        mapareaiddownloading = ""


        // portalSearch.populateLocalMapPackages()
        Platform.stayAwake = false
        processingList.pop()

        processDownloadList()

    }



    function updateModel(mapareaId,value)
    {

        for(var k=0;k<mapAreasModel.count; k ++){

            var _mapArea = mapAreasModel.get(k)
            if(_mapArea.portalItem.itemId === mapareaId)
            {
                mapAreasModel.setProperty(k,"isPresent",value)
                mapAreasModel.setProperty(k,"isDownloading",false)
            }

        }



    }




    function checkStatus()
    {
        if(offlineMapJob.result){
            if(!offlineMapJob.hasErrors)
            {
                downloadThumbnail(saveMapInfo)
            }
            else
                console.error("Error:Map Area failed to download")


        }
    }

    function downloadComplete(downloadPreplannedOfflineMapResult)
    {
        if(offlineMapJob.result){
            if(!offlineMapJob.hasErrors)
            {
                downloadThumbnail(saveMapInfo)
            }
            else
                console.error("Error:Map Area failed to download")
        }
    }
    /***** sync *****/

    function getError()
    {
        //console.error("error")
    }

    function checkForUpdates()
    {
        offlineSyncTask = ArcGISRuntimeEnvironment.createObject("OfflineMapSyncTask",{map:mapView.map})
        offlineSyncTask.loadStatusChanged(getError)
        var mapUpdatesInfoTaskId =  offlineSyncTask.checkForUpdates()

        offlineSyncTask.checkForUpdatesStatusChanged.connect(function()
        {
            getUpdates(offlineSyncTask)
        }
        )

    }

    function updateMyMapArea(portalItem)
    {

        //create the map
        var newMap = ArcGISRuntimeEnvironment.createObject("Map",{ item: portalItem });

        syncGeodatabase(portalItem.title,newMap)
        //if updates available then download maparea
    }

    function syncGeodatabase(title,myMap)
    {
        var offlineSyncTask = ArcGISRuntimeEnvironment.createObject("OfflineMapSyncTask",{map:myMap})

        //check for updates
        offlineSyncTask.loadStatusChanged(getError)

        offlineSyncTask.loadErrorChanged(getError)
        //need to test below after updates
        var mapUpdatesInfoTaskId =  offlineSyncTask.checkForUpdates()

        offlineSyncTask.checkForUpdatesStatusChanged.connect(function()
        {
            getUpdates(offlineSyncTask,title)
        }
        )


    }

    function getUpdates(offlineSyncTask,title)
    {
        var updatesInfo = offlineSyncTask.checkForUpdatesResult
        if(offlineSyncTask.checkForUpdatesStatus === Enums.TaskStatusCompleted)
        {
            var isDownloadAvailable = updatesInfo.downloadAvailability
            var isUploadAvailable = updatesInfo.uploadAvailability
            if(isUploadAvailable !== Enums.OfflineUpdateAvailabilityNone || isDownloadAvailable !== Enums.OfflineUpdateAvailabilityNone)
            {
                applyUpdates(offlineSyncTask)
            }
            else
            {
                toastMessage.show(qsTr("There are no updates available at this time."))
                mapareasbusyIndicator.visible = false
                mapSyncCompleted(title,false)
            }
        }
    }

    function applyUpdates(offlineSyncTask)
    {
        var mapsyncTaskId  = offlineSyncTask.createDefaultOfflineMapSyncParameters()
        offlineSyncTask.createDefaultOfflineMapSyncParametersStatusChanged.connect(function(){
            getParameters(offlineSyncTask)
        }
        )
    }

    function getParameters(offlineSyncTask)
    {
        if(offlineSyncTask.createDefaultOfflineMapSyncParametersStatus === Enums.TaskStatusCompleted)
        {
            var defaultMapSyncParams = offlineSyncTask.createDefaultOfflineMapSyncParametersResult
            defaultMapSyncParams.preplannedScheduledUpdatesOption = Enums.PreplannedScheduledUpdatesOptionDownloadAllUpdates

            var offlinemapSyncJob = offlineSyncTask.syncOfflineMap(defaultMapSyncParams)
            offlinemapSyncJob.start()

            offlinemapSyncJob.statusChanged.connect(function(){
                updateMap(offlinemapSyncJob)
            }
            )

        }
    }

    function showDownloadCompletedMessage(message,body)
    {
        toastMessage.isBodySet = true
        toastMessage.display(message,body)
    }

    function showDownloadFailedMessage(message,body)
    {
        if(message > "")
            messageDialog.show(qsTr("Download Failed"),body +": " + message)
    }

    function updateMap(offlinemapSyncJob)
    {
        var status = offlinemapSyncJob.jobStatus
        if(offlinemapSyncJob.jobStatus === Enums.JobStatusSucceeded)
        {
            var syncJobResult =  offlinemapSyncJob.result
            if(!syncJobResult.hasErrors)
            {
                toastMessage.show(qsTr("Offline map area syncing completed."))
                mapareasbusyIndicator.visible = false
                let outputFilePath = offlineMapAreaCache.fileFolder.path + "/"
                mapAreaManager.updateMapAreaInfo(outputFilePath)

            }
            else
            {
                var errorMsg = syncJobResult.layerResults[0].syncLayerResult.error.additionalMessage
            }
        }
    }





    /***end sync *******/

    Component.onCompleted: {
        if(mapPortalItem.loadStatus !== Enums.LoadStatusLoaded && mapPortalItem.loadStatus !== Enums.LoadStatusLoading)
            mapPortalItem.load()

    }



}
