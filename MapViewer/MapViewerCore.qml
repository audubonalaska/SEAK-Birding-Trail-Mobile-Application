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
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.Authentication 1.0
import ArcGIS.AppFramework.WebView 1.0

import Esri.ArcGISRuntime 100.14


import "controls" as Controls
import "views" as Views




Item {
    id: mapViewerCore


    //--------------------------------------------------------------------------

    function getDate(timestamp)
    {
        var date = new Date(timestamp);
        var jsDateValues = [
                    date.getMonth()+1,
                    date.getDate(),
                    date.getFullYear()
                ]
        return jsDateValues.join("/")
    }

    function getDistance(val)
    {
        var locale = Qt.locale()
        var distance
        var distanceInMeters = val
        if(Qt.locale().measurementSystem !== Locale.MetricSystem)
        {

            var distanceInMiles = (distanceInMeters/1609.34)
            if(distanceInMiles < 0.1)
            {
                var distanceInFeet = distanceInMiles * 5280
                distance = (Math.round(distanceInFeet)).toString() + " ft"
            }
            else
                distance = (distanceInMiles.toFixed(1)).toString() + " mi"
        }
        else
        {
            if(distanceInMeters > 1000)
            {
                var distanceInKm = distanceInMeters/1000
                distance = (distanceInKm.toFixed(1)).toString() + " km"
            }
            else
                distance = (Math.round(distanceInMeters)).toString() + " m"
        }
        return distance

    }


    /* function isNotchAvailable() {
        var unixName = AppFramework.systemInformation.unixMachine;
        if(unixName)
        {
            if (unixName.match(/iPhone(10|\d\d)/)) {
                switch(unixName) {
                case "iPhone10,1":
                case "iPhone10,4":
                case "iPhone10,2":
                case "iPhone10,5":
                    return false;
                default:
                    return true;
                }
            }
        }
        return false;
    }*/

    function deleteOfflineMapArea(mapid,mapareaId)
    {
        var fileName = "mapareasinfos.json"

        var mapAreaPath = offlineMapAreaCache.fileFolder.path + "/"+ mapid
        let mapAreafileInfo = AppFramework.fileInfo(mapAreaPath)
        //fileInfo.folder points to previous folder
        if (mapAreafileInfo.folder.fileExists(fileName)) {
            var   fileContent = mapAreafileInfo.folder.readJsonFile(fileName)
            var results = fileContent.results
            var existingmapareas = results.filter(item => item.id !== mapareaId)
            fileContent.results = existingmapareas

            //delete the folder
            var thumbnailFolder = mapareaId + "_thumbnail"
            var mapareacontentpath = [mapAreaPath,thumbnailFolder].join("/")
            let fileFolder= AppFramework.fileFolder(mapareacontentpath)
            var isthumbnaildeleted = fileFolder.removeFolder()
            var mapareacontents = [mapAreaPath,mapareaId].join("/")
            let mapareafileFolder = AppFramework.fileFolder(mapareacontents)
            var isdeleted = mapareafileFolder.removeFolder()
            if(isdeleted)
                mapAreafileInfo.folder.writeJsonFile(fileName, fileContent)

        }

        portalSearch.populateLocalMapPackages()
        refreshGallery()

    }

    function openUrlInternally(url) {
        var browserView;

        if(url.indexOf("mailto") > -1)
        {
            Qt.openUrlExternally(url)
        }
        else if((url.indexOf("tel:") > -1) && app.isDesktop)
        {
            Qt.openUrlExternally(url)
        }
        else if((url.indexOf("tel:") > -1) && !app.isDesktop)
        {
            Qt.openUrlExternally(url)
        }

        else
        {

            if (Qt.platform.os === "ios" || Qt.platform.os === "android") {
                browserView = safariBrowserComponent.
                createObject(null, {
                                 url: url
                             });
                browserView.show();
            } else {
                browserView = webPageComponent.createObject(app);
                browserView.closed.connect(browserView.destroy)
                browserView.loadPage(url)
            }
        }
    }



    function openUrlInternallyWithWebView (url) {
        var webPage = webComponent.createObject (app)
        webPage.closed.connect(webPage.destroy)
        webPage.loadPage (url)
    }



    function getFileSize(fileSizeInBytes)
    {
        var i = -1;
        var byteUnits = [qsTr("KB"), qsTr("MB"), qsTr("GB")];
        do {
            fileSizeInBytes = fileSizeInBytes / 1024;
            i++;
        } while (fileSizeInBytes > 1024);

        return "%1 %2".arg(Number(Math.max(fileSizeInBytes, 0.1).toFixed(1)).toLocaleString(Qt.locale(), "f", 0)).arg(byteUnits[i]);

    }





    function credentialChanged(token)
    {
        return new Promise(function(resolve,reject){
            if(token)
            {
                resolve(token)
            }
            else
                reject(new Error("invalid token"))
        }
        )
    }



    function setRefreshToken () {
        secureStorage.setContent("oAuthRefreshToken", securedPortal.credential.oAuthRefreshToken)
        app.settings.setValue("tokenServiceUrl", securedPortal.credential.tokenServiceUrl)
        app.settings.setValue("portalUrl", securedPortal.url)
        app.settings.setValue("clientId", securedPortal.credential.oAuthClientInfo.clientId)
        app.settings.setValue("username", securedPortal.portalUser.username)
    }

    function setUserNamePswd () {
        secureStorage.setContent("password", securedPortal.credential.password)
        app.settings.setValue("tokenServiceUrl", securedPortal.credential.tokenServiceUrl)
        app.settings.setValue("portalUrl", securedPortal.url)
        app.settings.setValue("clientId", securedPortal.credential.oAuthClientInfo.clientId)
        app.settings.setValue("username", securedPortal.portalUser.username)
    }

    function clearRefreshToken () {
        secureStorage.clearContent("oAuthRefreshToken")
        secureStorage.clearContent("password")
        app.settings.setValue("tokenServiceUrl", "")
        app.settings.setValue("portalUrl", "")
        app.settings.setValue("clientId", "")
        app.settings.setValue("useBiometricAuthentication", "")
        app.settings.setValue("username","")
    }

    function createCredential (clientId, credentialInfo, tokenServiceUrl) {
        var oAuthClientInfo = ArcGISRuntimeEnvironment.createObject("OAuthClientInfo", {oAuthMode: Enums.OAuthModeUser, clientId: clientId})
        var credential = ArcGISRuntimeEnvironment.createObject("Credential", {oAuthClientInfo: oAuthClientInfo})

        var oAuthRefreshToken = credentialInfo.oAuthRefreshToken;
        var password = credentialInfo.password;
        var username = credentialInfo.username;

        oAuthClientInfo.refreshTokenExpirationInterval = 129600;

        if (tokenServiceUrl > "")
            credential.tokenServiceUrl = tokenServiceUrl;

        if (oAuthRefreshToken > "")
            credential.oAuthRefreshToken = oAuthRefreshToken;
        else{
            if(username > "")
                credential.username = username;
            if(password > "")
                credential.password = password;
        }
        return credential
    }


    function getThumbnailUrl (portalUrl, portalItem, token) {
        if(securedPortal)
            token = securedPortal.credential.token
        try {
            if (portalItem.thumbnailUrl) return portalItem.thumbnailUrl
        } catch (err) {}

        var imgName = portalItem.thumbnail
        if (!imgName) {
            return ""
        }
        var urlFormat = "%1/sharing/rest/content/items/%2/info/%3%4",
        prefix = ""
        if (token) {
            prefix = "?token=%1".arg(token)
        }
        return urlFormat.arg(portalUrl).arg(portalItem.id).arg(imgName).arg(prefix)
    }





    function setSystemProps () {
        var sysInfo = typeof AppFramework.systemInformation !== "undefined" && AppFramework.systemInformation ? AppFramework.systemInformation : ""
        if (!sysInfo) return
        if (Qt.platform.os === "ios" && sysInfo.hasOwnProperty("unixMachine")) {
            var unixName = sysInfo.unixMachine;

            switch(unixName){
                //iPhone X
            case "iPhone10,3":
            case "iPhone10,6":
                //iPhone XS, XR
            case "iPhone11,2":
            case "iPhone11,4":
            case "iPhone11,6":
            case "iPhone11,8":
                //iPhone 11
            case "iPhone12,1":
            case "iPhone12,3":
            case "iPhone12,5":
                //iPhone 12
            case "iPhone13,1":
            case "iPhone13,2":
            case "iPhone13,3":
            case "iPhone13,4":
                app.isIphoneX = true;
            }
        } else if (Qt.platform.os === "windows") {
            var kernelVersionPattern = /^6\.1/
            var osVersionPattern = /^7/
            isWindows7 = kernelVersionPattern.test(AppFramework.kernelVersion) && osVersionPattern.test(AppFramework.osVersion)
        }
    }

//--------------------------------------------------------------------------

    function getProperty (name, fallback) {
        if (!fallback && typeof fallback !== "boolean") fallback = ""
        return app.info.propertyValue(name, fallback) || fallback
    }

    function getClientId (fallback) {
        if (!fallback) fallback = ""
        try {
            return app.info.json.deployment.clientId
        } catch (err) {
            return fallback
        }
    }

    //--------------------------------------------------------------------------

    function randomColor (colortype) {
        var types = {
            "primary": ["#4A148C", "#0D47A1", "#004D40", "#006064", "#1B5E20", "#827717", "#3E2723"],
            "background": ["#F5F5F5", "#EEEEEE"],
            "foreground": ["#22000000"],
            "accent": ["#FF9800", "yellow", "red"]
        },
        type = types[colortype]
        return type[Math.floor(Math.random() * type.length)]
    }

    function isFieldVisible(fields,fieldName)
    {
        for(var k=0;k< fields.length; k++)
        {
            var field = fields[k]
            var name = ""
            if(field.name)
                name = field.name
            else if(field.fieldName)
                name = field.fieldName


            if(name.toUpperCase() === fieldName.toUpperCase())
            {
                if(field.visible)
                    return field.visible
                else
                    return true

            }
        }
        return true
    }

    function getFieldAlias(fields,fieldName)
    {
        for(var k=0;k< fields.length; k++)
        {
            var field = fields[k]
            var name = ""
            if(field.name)
                name = field.name
            else if(field.fieldName)
                name = field.fieldName


            if(name.toUpperCase() === fieldName.toUpperCase())
            {
                if(field.label)
                    return field.label
                else
                {
                    if(field.alias)
                        return field.alias
                }

            }
        }
        return fieldName
    }



    function getCodeIfDomain(fields,fieldName,fieldValue)
    {
        if(fieldValue){
            for(var k=0;k< fields.length; k++)
            {
                let field = fields[k]
                if(field.name === fieldName)
                {
                    let domain = field.domain
                    if(domain && domain.codedValues)
                    {
                        let codedValues = domain.codedValues

                        for(let x=0;x<codedValues.length;x++)
                        {
                            if(codedValues[x].name.toUpperCase()  ===  fieldValue.toUpperCase())
                            {
                                let codedValueObj = codedValues[x]
                                return codedValueObj.code
                            }
                        }


                    }
                    else
                        return fieldValue

                }
            }
        }
        return fieldValue
    }

    function getNameIfDomain(fields,fieldName,fieldValue){
        for(var k=0;k< fields.length; k++){
            let field = fields[k]
            if(field.name === fieldName){
                let domain = field.domain
                if(domain && domain.codedValues){
                    let codedValues = domain.codedValues

                    for(let x=0;x<codedValues.length;x++){
                        if(codedValues[x].code.toString().toUpperCase()  ===  fieldValue.toString().toUpperCase()){
                            let codedValueObj = codedValues[x]
                            return codedValueObj.name
                        }
                    }
                }
                else
                    return fieldValue
            }
        }
        return fieldValue
    }

    function getFormattedFieldValue(_fieldVal){
        var isNotNumber = isNaN(_fieldVal)
        if(_fieldVal && !isNotNumber){
            var formattedVal = _fieldVal.toLocaleString()
            if(formattedVal)
                _fieldVal = formattedVal
        }

        //check if it is a date
        var dt = Date.parse(_fieldVal)
        if(dt){
            var date_ob = new Date(dt)
            // year as 4 digits (YYYY)
            var year = date_ob.getFullYear()
            // month as 2 digits (MM)
            var month = ("0" + (date_ob.getMonth() + 1)).slice(-2);
            // date as 2 digits (DD)
            var day = ("0" + date_ob.getDate()).slice(-2);
            var formattedDateVal= month + "/"+ day + "/" + year

            _fieldVal = formattedDateVal
        }
        return _fieldVal
    }

    function getDomainCodeFromFeatureTable(layerServiceTable,fieldName,fieldValue){
        //let lyr = layerManager.getLayerById(lyrid)
        //let layerServiceTable = lyr.featureTable
        if(layerServiceTable){
            let fields = layerServiceTable.fields
            if(fieldName === layerServiceTable.typeIdField)
            {
                return getCodeFromFeatureTypeName(layerServiceTable,fieldValue)
            }
            else

                return getCodeIfDomain(fields,fieldName,fieldValue)
        }
        else
            return fieldValue
    }

    function getDomainNameFromFeatureTable(layerServiceTable,fieldName,fieldValue){
        //let lyr = layerManager.getLayerById(lyrid)
        //let layerServiceTable = lyr.featureTable
        if(layerServiceTable){
            let fields = layerServiceTable.fields
            if(fieldName === layerServiceTable.typeIdField)
            {
                return getNameFromFeatureTypeCode(layerServiceTable,fieldValue)
            }
            else

                return getDomainNameFromCodeInTable(layerServiceTable,fieldName,fieldValue)
        }
        else
            return fieldValue
    }


    function getDomainCode(lyrid,fieldName,fieldValue){
        let lyr = layerManager.getLayerById(lyrid)
        let layerServiceTable = lyr.featureTable
        if(layerServiceTable){
            let fields = layerServiceTable.fields
            if(fieldName === layerServiceTable.typeIdField)
            {
                return getCodeFromFeatureTypeName(layerServiceTable,fieldValue)
            }
            else

                return getCodeIfDomain(fields,fieldName,fieldValue)
        }
        else
            return fieldValue
    }

    function getNameFromFeatureTypeCode(layerServiceTable,fieldValue)
    {
        let featureTypes = layerServiceTable.featureTypes
        for(let key in featureTypes)
        {
            let _typeObj = featureTypes[key]
            if(_typeObj.typeId === fieldValue)
            {
                let _templates = _typeObj.templates
                if(_templates.length)
                {
                    let templateType = _templates[0].name

                    return templateType
                }
                else
                {
                    return _typeObj.name

                }
            }
        }

    }

    function getCodeFromFeatureTypeName(layerServiceTable,fieldValue)
    {
        let featureTypes = layerServiceTable.featureTypes
        for(let k=0;k<featureTypes.length; k++)
        {
            let _type = featureTypes[k]
            let _templates = _type.templates
            if(_templates.length)
            {
                let templateType = _templates[0].name
                if(templateType === fieldValue)
                    return _type.typeId
            }
            else
            {

                if(_type.name === fieldValue)
                {
                    return _type.typeId
                }
            }
        }
        return fieldValue
    }

    function getDomainNameFromCodeInTable(layerServiceTable,fieldName,fieldValue){

        if(layerServiceTable){
            let fields = layerServiceTable.fields
            return getNameIfDomain(fields,fieldName,fieldValue)
        }
        else
            return fieldValue
    }

    function getDomainNameFromCode(lyrid,fieldName,fieldValue){
        let lyr = layerManager.getLayerById(lyrid)
        let layerServiceTable = lyr.featureTable
        if(layerServiceTable){
            let fields = layerServiceTable.fields
            return getNameIfDomain(fields,fieldName,fieldValue)
        }
        else
            return fieldValue
    }

    function formatDate(date) {
        var d = new Date(date),
        month = '' + (d.getMonth() + 1),
        day = '' + d.getDate(),
        year = d.getFullYear();
        if (month.length < 2)
            month = '0' + month;
        if (day.length < 2)
            day = '0' + day;

        return [year, month, day].join('-');
    }
}
