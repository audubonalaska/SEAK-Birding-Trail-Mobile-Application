import QtQuick 2.5
import QtQuick.Controls 1.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0
import Esri.ArcGISRuntime 100.14


Item {
    id: mmpkManager
    property string itemId: ""
    property string itemName: itemId > "" ? "%1.mmpk".arg(itemId) : ""
    property string token: ""
    property string rootUrl: "http://www.arcgis.com/sharing/rest/content/items/"
    property url fileUrl: [fileFolder.url, itemName].join("/")
    property string subFolder: "MapViewer"
    property int loadStatus: -1 //unknow = -1, loaded = 0, loading = 1, failed to load = 2
    property bool offlineMapExist: hasOfflineMap()
    property real size: fileFolder.fileInfo(itemName).size
    property int idx

    property string errorText: ""

    property var fileFolder:fileInfo.folder
    property string storageBasePath: "~/ArcGIS/AppStudio/Cache"
    property string storagePath: subFolder && subFolder>"" ? storageBasePath + "/" + subFolder : storageBasePath
    property var fileInfo : AppFramework.fileInfo(storagePath);

    Component.onCompleted: {

        fileFolder.path = storagePath
        if(!fileFolder.exists){
            fileFolder.makeFolder(storagePath);
        }
        if (!fileFolder.fileExists(".nomedia") && Qt.platform.os === "android") {
            fileFolder.writeFile(".nomedia", "")
        }

        hasOfflineMap();
    }

    onItemIdChanged: {
        itemName = itemId > "" ? "%1.mmpk".arg(itemId) : "";
    }

    function downloadOfflineMap(callback){
    downloadOfflineMap_runtime(callback)
       /* mmpkManager.errorText = ""
        if(itemId >""){
            Platform.stayAwake = true
            var component = typeNetworkRequestComponent;
            var networkRequest = component.createObject(parent);
            var url = rootUrl+itemId+"?f=json&token="+token;
            networkRequest.checkType(url, callback);
        }*/

    }

    function downloadOfflineMap_runtime(callback)
    {

         var _mmpkPath = ""
         var _itemPath;
         var _json = [];
         var _thumbnailPath = "";
          var _jsonPath = "";
          var _thumbnail

         var portalItem = ArcGISRuntimeEnvironment.createObject("PortalItem",{
                                                                                   portal: app.portal,
                                                                                   itemId: itemId
                                                                               });
           portalItem.load()
           _jsonPath = [_itemPath, "info.json"].join("/");

           portalItem.loadStatusChanged.connect(function(){
                            if (portalItem.loadStatus === Enums.LoadStatusLoaded){
                            _itemPath = [fileFolder.path, itemName].join("/");

                                var mmpkName = "%1.mmpk".arg(itemId);
                                _json = portalItem.json;
                                if (_json.hasOwnProperty("name"))
                                        mmpkName = _json.name;

                                var _mmpkInfo = AppFramework.fileInfo(_itemPath)
                                var _mmpkUrl = _mmpkInfo.url;
                                    _mmpkPath = _mmpkInfo.filePath;
                                    if (_json.hasOwnProperty("thumbnail"))
                                    {
                                        _thumbnail = _json.thumbnail;
                                       var _thumbnailFileInfo  = AppFramework.fileInfo([_itemPath, _thumbnail].join("/"));
                                       _thumbnailPath = _thumbnailFileInfo.filePath

                                        }

                                        loadStatus = 1;
                                        onlineMapPackages.setProperty(idx, "cardState", 1);
                                        Platform.stayAwake= true
                                        portalItem.fetchData(_mmpkUrl);


                                }

                                     portalItem.fetchDataStatusChanged.connect(function(){

                                        if(portalItem.fetchDataStatus === Enums.TaskStatusCompleted) {
                                           galleryView.isDownloading = false
                                           onlineMapPackages.setProperty(idx, "cardState", 0);
                                            callback()

                                        }

                                        if(portalItem.fetchDataStatus === Enums.TaskStatusErrored) {
                                            loadStatus = 2;
                                            onlineMapPackages.setProperty(idx, "cardState", -1);
                                            Platform.stayAwake= false

                                        }


                                    })

                                    })

    }


    function updateOfflineMap(callback){
        if(offlineMapExist){
            downloadOfflineMap(callback);
        }
    }

    function hasOfflineMap(){

        if(itemName)
            offlineMapExist = fileInfo.folder.fileExists(itemName)
        else offlineMapExist = false
        getSize()
        return offlineMapExist;
    }

    function deleteOfflineMap(callback){

        if(fileFolder.fileExists("~"+itemName))fileFolder.removeFile("~"+itemName);
        if(fileFolder.fileExists(itemName))fileFolder.removeFile(itemName);
        hasOfflineMap();
        if (callback) callback()
    }

    Component{
        id: typeNetworkRequestComponent
        NetworkRequest{
            id: typeNetworkRequest

            property var callback

            method: "GET"
            ignoreSslErrors: true

            onErrorTextChanged: mmpkManager.errorText = errorText

            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE ){

                    if(errorCode != 0){
                        loadStatus = 2;
                        onlineMapPackages.setProperty(idx, "cardState", -1);
                        //console.log(errorCode, errorText);
                    } else {
                        //console.log("Type Response", responseText)
                        var root = JSON.parse(responseText);
                        if(root.type === "Mobile Map Package"){
                            loadStatus = 1;
                            onlineMapPackages.setProperty(idx, "cardState", 1);
                            var component = networkRequestComponent;
                            var networkRequest = component.createObject(parent);
                            var url = rootUrl+itemId+"/data?token="+token;

                            var path = [fileFolder.path, "~"+itemName].join("/");

                            networkRequest.downloadFile("~"+itemName, url, path, typeNetworkRequest.callback);
                        } else {
                            loadStatus = 2;
                            onlineMapPackages.setProperty(idx, "cardState", -1);
                        }
                    }

                }
            }
            onError:{
                Platform.stayAwake=false
            }

            function checkType(url, callback){
                typeNetworkRequest.url = url;
                typeNetworkRequest.callback = callback;
                typeNetworkRequest.send();
                loadStatus = 1;
                onlineMapPackages.setProperty(idx, "cardState", 1);
            }
        }
    }

    Component{
        id: networkRequestComponent
        NetworkRequest{
            id: networkRequest

            property var name;
            property var callback;

            method: "GET"
            ignoreSslErrors: true

            onErrorTextChanged: mmpkManager.errorText = errorText

            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE ){

                    if(errorCode != 0){

                        fileFolder.removeFile(networkRequest.name);
                        loadStatus = 2;
                        onlineMapPackages.setProperty(idx, "cardState", -1);
                        //console.log(errorCode, errorText);
                    } else {
                        loadStatus = 0;
                        onlineMapPackages.setProperty(idx, "cardState", 0);
                        if(hasOfflineMap()) fileFolder.removeFile(itemName);
                        fileFolder.renameFile(name, itemName);

                        hasOfflineMap();

                        if (callback) {
                            callback();
                        }
                    }
                }
            }

            function downloadFile(name, url, path, callback){
                networkRequest.name = name;
                networkRequest.url = url;
                networkRequest.responsePath = path;
                networkRequest.callback = callback;
                networkRequest.send();
                loadStatus = 1;
                onlineMapPackages.setProperty(idx, "cardState", 1);
            }
        }
    }

    function getSize () {
        size = fileFolder.fileInfo(itemName).size
    }
}
