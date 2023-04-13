import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0

import Esri.ArcGISRuntime 100.14


import "../controls" as Controls

Pane {
    id: galleryDelegate

    property bool isOnline: app.isOnline
    property color imageBackgroundColor: app.baseTextColor
    property url url: url
    property bool needsUnpacking: false
    property bool isDownloaded:false

    //

    property string fontNameFallbacks: "Helvetica,Avenir"
    property string baseFontFamily: getAppProperty (app.baseFontFamily, fontNameFallbacks)
    property string titleFontFamily: getAppProperty (app.titleFontFamily, "")
    property string accentColor: getAppProperty(app.accentColor)
    property bool isDownloading:false


    property string subFolder : [app.appId, app.portalSearch.offlineFolder].join("/");
    property string storageBasePath : "~/ArcGIS/AppStudio/Cache"
    property string storagePath : subFolder && subFolder>"" ? storageBasePath + "/" + subFolder : storageBasePath
    property var fileInfo : AppFramework.fileInfo(storagePath)
    property url fileUrl: [fileFolder.url, itemName].join("/")
    property var fileFolder:fileInfo.folder
    property string itemId: id
    property string itemName: itemId > "" ? "%1.mmpk".arg(itemId) : ""
    property string delegateType: type

    height: parent.cellHeight
    width: parent.cellWidth
    padding: 0

    signal clicked ()
    signal entered ()
    signal removeMapArea(var mapid,var mapareaId,var title)
    signal removeOfflineMap(var id,var needsUnpacking)


    Controls.Card {

        headerHeight: 0
        footerHeight: 0
        padding: 0
        highlightColor: "transparent"
        backgroundColor: "transparent"

        anchors {
            horizontalCenter: undefined
            fill: parent
            margins: 0.5 * app.defaultMargin
        }

        Material.elevation: hovered ? app.raisedElevation : app.baseElevation
        hoverEnabled: true

        content: Pane {
            width:parent.width
            height:parent.height
            padding: 0

            RowLayout {
                id: cardContent

                anchors.fill: parent
                spacing: 0

                property int cardMargins: 3/4 * app.defaultMargin

                Image {
                    id: thumbnail

                    property real aspectRatio: (200/133)

                    Layout.preferredHeight: parseInt(parent.height) - 2 * cardContent.cardMargins
                    Layout.preferredWidth: parseInt(aspectRatio * Layout.preferredHeight)
                    Layout.margins: 0
                    Layout.leftMargin: cardContent.cardMargins
                    cache: true
                    fillMode: Image.PreserveAspectFit
                    source : "../images/default-thumbnail.png"



                    Component.onCompleted: {
                        if(type == "maparea")
                        {
                            var storageBasePath = offlineMapAreaCache.fileFolder.path//app.rootUrl //AppFramework.resolvedUrl("./ArcGIS/AppStudio/cache")

                            var mapareapath = [storageBasePath,mapid].join("/")
                            if(thumbnailUrl > ""){
                                if(Qt.platform.os === "windows")
                                    url = "file:///" + mapareapath + "/" + id + "_thumbnail/" + thumbnailUrl
                                else
                                    url = "file://" + mapareapath + "/" + id + "_thumbnail/" + thumbnailUrl
                            }
                            else
                                url = ""

                        }
                        else
                        {
                            if (cardState === 1 && offlineCache.hasFile(thumbnailUrl)) {

                                url = offlineCache.cache(thumbnailUrl, "", {"token": token})
                            } else {
                                //url = onlineCache.cache(thumbnailUrl, "")
                                //url += (isOnline && url.toString().startsWith("http") ? "?token=" + token : "")

                                  url = onlineCache.cache(thumbnailUrl, "", {"token": token})
                                  //url += (isOnline && url.toString().startsWith("http") ? "?token=" + token : "")
                            }
                        }
                        source = url > "" ? url : "../images/default-thumbnail.png"
                    }


                    onStatusChanged: {
                        if (thumbnail.status === Image.Error) {
                            thumbnail.source = "../images/default-thumbnail.png"
                        }
                    }

                    BusyIndicator {
                        anchors.centerIn: parent
                        running: thumbnail.status === Image.Loading
                    }

                    Rectangle {
                        id: thumbnailBackground

                        z: thumbnail.z - 1
                        anchors {
                            fill: parent
                            margins: app.units(1)
                        }
                        color: galleryDelegate.imageBackgroundColor
                    }

                    Image {
                        source: "../images/lock-badge.png"

                        width: 0.7 * app.iconSize
                        height: width
                        fillMode: Image.PreserveAspectFit
                        visible:type !="maparea" ? access!= "public":false
                        mirror: app.isLeftToRight? false : true

                        anchors {
                            right: parent.right
                            top: parent.top
                        }
                    }


                }

                ColumnLayout {
                    Layout.preferredHeight: parent.height
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    Layout.margins: 0
                    spacing: 0.5 * app.textSpacing

                    Controls.SpaceFiller {}

                    Controls.BaseText {
                        text: title
                        maximumLineCount: 2
                        Layout.topMargin: 0
                        Layout.leftMargin: cardContent.cardMargins
                        Layout.rightMargin: cardContent.cardMargins * 0.5
                        Layout.maximumHeight: (app.headerHeight * 3/2) - cardContent.cardMargins
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        horizontalAlignment: Label.AlignLeft
                        Layout.alignment: Qt.AlignLeft
                    }

                    RowLayout{
                        spacing: 0
                        Layout.alignment: Qt.AlignLeft
                        Controls.BaseText {
                            text: {
                                var txt = ""
                                if (type === "maparea")
                                {txt = modifiedDate}
                                else
                                    txt = new Date(modified).toLocaleDateString(Qt.locale(), Qt.DefaultLocaleShortDate)

                                return  txt
                            }
                            opacity: 0.7
                            maximumLineCount: 1
                            Layout.bottomMargin: 0
                            font.pointSize: Qt.platform.os === "windows" ? 0.7 * app.baseFontSize : app.textFontSize
                            Layout.leftMargin: cardContent.cardMargins
                            Layout.rightMargin:5 * scaleFactor
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            id:icon
                            visible:type === "Mobile Map Package" || type === "maparea"
                            Layout.preferredWidth: 4
                            Layout.preferredHeight:4
                            radius: 2
                            color: "grey"//getAppProperty(app.baseTextColor, Qt.lighter("#F7F8F8"))
                            //color: app.subTitleTextColor
                            Layout.alignment: Qt.AlignVCenter

                            Material.accent: accentColor
                        }
                        Controls.BaseText {
                            text: {
                                var txt = ""
                                if (type === "Mobile Map Package") {

                                    if (app.isOnline && portalItem.loadStatus === Enums.LoadStatusLoaded) {
                                        return  portalItem.size > -1
                                                ? ( qsTr("%L1 %2").arg(Math.round((portalItem.size/1000000) * 10) / 10).arg(strings.mb) )
                                                : ""
                                    } else {
                                        var _size = size
                                        return  portalItem.size > -1
                                                ? ( qsTr("%L1 %2").arg(Math.round((_size/1000000) * 10) / 10).arg(strings.mb) )
                                                : ""                                    }
                                }
                                else if (type === "maparea"){
                                    var size_units = size.split(" ");
                                    var sizeval = parseFloat(size_units[0]).toLocaleString(Qt.locale())
                                    var finalsizeString = `${sizeval}  ${size_units[1]}`

                                    txt = finalsizeString

                                }
                                return  txt
                            }
                            opacity: 0.7
                            maximumLineCount: 1
                            Layout.bottomMargin: 0
                            font.pointSize: Qt.platform.os === "windows" ? 0.7 * app.baseFontSize : app.textFontSize
                            Layout.leftMargin: 3 * scaleFactor//cardContent.cardMargins
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                        }
                    }

                    RowLayout{
                        id:maptype

                        spacing:0
                        Layout.topMargin: 0
                        Layout.leftMargin: cardContent.cardMargins
                        visible: isDownloaded && (tabView.model[tabBar.currentIndex] === kSecondTab || doesItContainMapArea())

                        Controls.Icon {
                            id: offlineicon
                            Layout.preferredHeight:mapTypeText.height
                            Layout.preferredWidth: height
                            imageHeight: parent.height
                            imageWidth: height
                            Layout.rightMargin: 0
                            imageSource: "../images/ic_offline_pin.png"
                            maskColor: "green"
                            Layout.alignment: Qt.AlignLeft
                        }

                        Item {
                            Layout.preferredWidth: 5 * scaleFactor
                        }


                        Controls.BaseText {
                            id: mapTypeText
                            text:tabView.model[tabBar.currentIndex] === kSecondTab ? (type === "maparea" ? "Offline area" : "MMPK") : "Offline areas"
                            Layout.topMargin: 0
                            Layout.leftMargin:0
                            Layout.rightMargin: cardContent.cardMargins
                            font.pointSize: Qt.platform.os === "windows" ? 0.7 * app.baseFontSize : app.textFontSize
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                            opacity: 0.7
                        }
                    }


                    Controls.SpaceFiller {}
                }

                Rectangle {
                    id: actionBtnSpace

                    visible: actionBtn.visible
                    Layout.preferredHeight: actionBtn.height
                    Layout.preferredWidth: actionBtn.width
                    Layout.alignment: Qt.AlignVCenter
                    color: "transparent"
                }


            }
        }
    }

    function doesItContainMapArea()
    {
        var item = app.mapsWithMapAreas.filter(id => id === portalItem.itemId)
        if(item.length > 0)
            return true
        else
            return false

    }

    function getAppProperty (appProperty, fallback) {
        if (!fallback) fallback = ""
        try {
            return appProperty ? appProperty : fallback
        } catch (err) {
            return fallback
        }
    }

    PortalItem {
       id:portalItem
        portal:app.portal
        itemId: id
        Component.onCompleted: load()
        onLoadStatusChanged: {
            if (loadStatus === Enums.LoadStatusLoaded) {
                if(index > -1 && index < onlineMapPackages.count)
                onlineMapPackages.setProperty(index, "size", parseInt(portalItem.size))

            }
        }
        onThumbnailUrlChanged: {
            //console.log("thumbnail changed", thumbnailUrl) // populated at this point
            if(typeName === "Web Map" || typeName === "Mobile Map Package")
              thumbnail.source = thumbnailUrl
        }
    }



    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: false

        onClicked: {
            galleryDelegate.clicked()
        }

        onEntered: {
            galleryDelegate.entered()
        }
    }

    Rectangle {
        id:mapareaactionBtn
        visible:type === "maparea"? true:false
        height: app.iconSize
        width: app.iconSize
        color: "transparent"

        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: cardContent.cardMargins/2
        }
        Controls.Icon {
            id: mapareaMoreBtn
            visible:true
            anchors.fill: parent
            imageSource: "../images/more.png"
            maskColor: app.primaryColor
            onClicked: {
                more.open()
            }
        }
    }


    Rectangle {
        id: actionBtn

        visible: type === "maparea" || ((type === "Mobile Map Package" && cardState === -1)  && isOnline)
                 ||  (type === "Mobile Map Package" && cardState === 1) ||  (type === "Mobile Map Package" && cardState === 0) //(((type === "Mobile Map Package" && !mmpkManager.offlineMapExist) && mmpkManager.loadStatus !== 1 && isOnline) ||  mmpkManager.hasOfflineMap()) && !galleryView.isDownloading
        height: app.iconSize
        width: app.iconSize
        color: "transparent"

        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: cardContent.cardMargins/2
        }

        Controls.Icon {
            id: downloadBtn
            visible: (type === "Mobile Map Package" && cardState === -1) && isOnline
            imageSource: "../images/download.png"
            anchors.fill: parent
            maskColor: app.primaryColor
            onClicked: {
                galleryDelegate.clicked()
            }
        }

        Controls.Icon {
            id: moreBtn
            visible: cardState === 0
            anchors.fill: parent
            imageSource: "../images/more.png"
            maskColor: app.primaryColor
            onClicked: {
                more.open()
            }
        }
        BusyIndicator {
            id: busyIndicator

            visible: cardState === 1
            Material.primary: app.primaryColor
            Material.accent: app.accentColor
            width: app.iconSize
            height: app.iconSize
            //anchors.centerIn: parent
            anchors.rightMargin: 15 * scaleFactor
        }


    }

    Controls.PopupMenu {
        id: more

        property string kRemove: qsTr("Remove")

        defaultMargin: app.defaultMargin
        backgroundColor: "#FFFFFF"
        highlightColor: Qt.darker(app.backgroundColor, 1.1)
        textColor: "red"//app.baseTextColor
        primaryColor: app.primaryColor

        menuItems: [
            {"itemLabel": kRemove}
        ]

        Material.primary: app.primaryColor
        Material.background: backgroundColor

        width: app.units(120)
        height: app.units(56)

        x: app.isLeftToRight ? (parent.width - width - app.baseUnit) : app.baseUnit
        y: (parent.height - height)/2 //0 + app.baseUnit

        onMenuItemSelected: {
            switch (itemLabel) {
            case kRemove:
                if(type === "maparea"){
                    processDeleteMapArea(mapid,id,title)
                }else{
                    processDeleteOfflineMap(id)
                }
                break
            }
        }
    }

    function processDeleteMapArea(mapid,mapareaId,title) {
        removeMapArea(mapid,mapareaId,title)
    }


    function processDeleteOfflineMap(id){
        removeOfflineMap(id,localMapPackages.get(index).needsUnpacking)
    }

    function deleteMapInfo (callback) {
        var fileName = "mapinfos.json"
        var currentContent = offlineCache.fileFolder.readJsonFile(fileName)
        var newContent =  {"results": []}

        for (var i=0; i<currentContent.results.length; i++) {
            if (currentContent.results[i].id !== id) {
                newContent.results.push(currentContent.results[i])
            } else {
                offlineCache.clearCache(currentContent.results[i].thumbnailUrl)
            }
        }

        if (newContent.results.length) {
            offlineCache.fileFolder.writeJsonFile(fileName, newContent)
        } else {
            offlineCache.clearAllCache()
        }

        if (callback) callback()
    }
}



