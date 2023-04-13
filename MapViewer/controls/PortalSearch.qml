/* Copyright 2022 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
import QtQuick 2.7

import ArcGIS.AppFramework 1.0

import Esri.ArcGISRuntime 100.14

//TODO: creating a portal item isn't the best option. Continue with json

Item {
    id: root

    property string portalUrl: "http://www.arcgis.com" //NB: This is reset in the method findItems()
    property Portal portal:app.portal
    property var findItemsResults: []
    property bool isBusy: false
    property bool isOnline: Networking.isOnline
    property string token: ""
    property string referer: ""
    property string subFolder: "MapViewer"
    property string onlineFolder: "onlinecache"
    property string offlineFolder: "offlinecache"
    property string offlineMapAreaFolder: "mapareas"
    property string screenShotsCacheFolder:"screenshotsCache"


    signal updateModel()

    //    signal requestSuccess(var results, int errorCode, string errorMsg)
    signal requestError(int errorCode, string errorMsg)

    onRequestError: {
        root.isBusy = false
    }

    MmpkManager {
        id: mmpkManager

        rootUrl: "%1/sharing/rest/content/items/".arg(portalUrl)
        subFolder: offlineCacheManager.subFolder
    }

    NetworkCacheManager {
        id: onlineCacheManager

        referer: root.referer
        subFolder: [root.subFolder, onlineFolder].join("/")
    }

    NetworkCacheManager {
        id: offlineCacheManager

        referer: root.referer
        subFolder: [root.subFolder, offlineFolder].join("/")
    }

    function clearResults()
    {
        findItemsResults = []
    }

    function findItems (portal, queryParameters) {
        if(!portal) return;

        root.isBusy = true;
        root.portalUrl = portal.url;

        if (isOnline) {
            onlineCacheManager.clearAllCache()//Cache(url)
        }

        portal.findItems(queryParameters);


    }




    function searchEventHandler(){
        if (portal.findItemsStatus !== Enums.TaskStatusCompleted)
            return;
        app.findItemsCompleted = true
        var isModelUpdated = false

        var resultsArray = []
        var _findItemResult = portal.findItemsResult;
        if(_findItemResult)
            _findItemResult.itemResults.forEach(function(element) {

                var portalItem = element.json;
                if(element.portal.credential)
                    if(element.portal.credential.token) root.token = element.portal.credential.token;

                if (!portalItem.url) portalItem.url = "%1/sharing/rest/content/items/%2".arg(portal.url).arg(portalItem.id)

                if(app.portalItemTypeCurrentlySearching === "BaseMap")
                {
                    let addToken = true
                     portalItem.thumbnailUrl = root.getThumbnailUrl(portalUrl, portalItem, root.token,addToken)
                     portalItem.itemType = app.portalItemTypeCurrentlySearching // based on the itemType we will know if it is loaded as a basemap, web map or mmpk
                    resultsArray.push(portalItem)
                }
                else
                {
                    var _url = onlineCacheManager.cache(root.getThumbnailUrl(portalUrl, portalItem, root.token), "", {"token": token}, null)

                    portalItem.thumbnailUrl = onlineCacheManager.cache(root.getThumbnailUrl(portalUrl, portalItem, root.token), "", {"token": token}, null)

                    portalItem.itemType = app.portalItemTypeCurrentlySearching
                    if (isOnline) {
                        resultsArray.push(portalItem)
                    } else if (portalItem.type === "Mobile Map Package") {
                        mmpkManager.itemId = portalItem.id
                        if (mmpkManager.hasOfflineMap()) {
                            resultsArray.push(portalItem)
                        }
                    }
                }
            })

        resultsArray.forEach(function(element) {
            var obj = findItemsResults.filter(item => item.id === element.id)
            if(obj.length === 0)
            {
                findItemsResults.push(element);
                isModelUpdated = true
            }
        });
        root.isBusy = false

        if(isModelUpdated || portalItemTypesToSearch.length === 0)
            updateModel()


        app.searchNextPortalItem()

    }



    Connections{
        target:portal

        function onFindItemsStatusChanged(){
            searchEventHandler();
        }
    }


    //-------------------------------------------------------------------------------
    property string url
    property var obj

    function refresh () {
        updateModel()


    }

    //-------------------------------------------------------------------------------

    function constructUrlSuffix (obj) {
        var urlSuffix = ""
        for (var key in obj) {
            if (obj.hasOwnProperty(key)) {
                if (obj[key]) {
                    urlSuffix += "%1=%2&".arg(key).arg(obj[key])
                }
            }
        }
        return urlSuffix.slice(0, -1)
    }

    function constructQuery (searchString, itemTypes) {

        var query = '-type:"Tile Package" -type:"Web Mapping Application" ' +
                '-type:"Map Service" -type:"Map Template" -type:"Type Map Package"' +
                ' type:Maps AND type:'

        for (var i=0; i<itemTypes.length; i++) {
            if (i !== 0) query += ' OR type:'
            switch (itemTypes[i]) {
            case Enums.PortalItemTypeMobileMapPackage:
                query += '"Mobile Map Package"'
                break
            case Enums.PortalItemTypeWebMap:
                query += '"Web Map"'
                break
            }
        }

        if (searchString) query += " %1".arg(searchString)

        return query
    }


    function getThumbnailUrl (portalUrl, portalItem, token,addToken) {
        if(!addToken)
            addToken = false
        try {
            if (portalItem.thumbnailUrl) return portalItem.thumbnailUrl
        } catch (err) {

        }

        var imgName = portalItem.thumbnail
        if (!imgName) {
            return ""
        }
        var urlFormat = "%1/sharing/rest/content/items/%2/info/%3%4",
        prefix = ""
        if (token) {
            if(addToken)
                prefix = "?token=%1".arg(token) // Ignoring the token. Letting NetworkCacheManager handle it
        }
        return urlFormat.arg(portalUrl).arg(portalItem.id).arg(imgName).arg(prefix)
    }
}
