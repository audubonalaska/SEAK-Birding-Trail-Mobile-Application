import QtQuick 2.7
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0
import Esri.ArcGISRuntime 100.14


import "../../MapViewer/controls" as Controls

ListView {
    id: mapAreasView

    //signal mapAreaSelected (int index)
    signal currentMapAreaSelectionUpdated ()

    property var  mapAreas:[]

    property string fontNameFallbacks: "Helvetica,Avenir"


    topMargin: 16 * scaleFactor
    leftMargin: 16 * scaleFactor

    anchors.fill:parent
    footer:Rectangle{
        height:70 * scaleFactor
        width:mapAreasView.width
        color:"transparent"
    }
    clip: true
    spacing: 10 * scaleFactor
    focus:true

    property real columns: app.isLarge ? 2 : 3

    delegate: Pane {
        id: container

        padding: 10 * scaleFactor
        height: app.units(80)
        width: parent.width - 32 * scaleFactor
        Material.elevation: 1


        Rectangle {
            width:parent.width
            height:parent.height
            z:1
            MouseArea {


                anchors.fill: parent
                onClicked: {

                    cardContent.updateSelectionInModel(index)
                    mapAreaManager.highlightMapArea(index)
                }
            }

            RowLayout {
                id: cardContent
                anchors.fill: parent
                spacing: 0

                property int cardMargins: 3/4 * app.defaultMargin

                function updateSelectionInModel(index)
                {
                    for(var k=0;k<mapAreasView.model.count;k++)
                    {
                        if(k === index)
                        {

                            mapAreasView.model.setProperty(k, "isSelected", true)
                        }
                        else
                        {

                            mapAreasView.model.setProperty(k, "isSelected", false)
                        }

                    }


                }
                Rectangle {

                    property real aspectRatio: (200/133)
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: aspectRatio * Layout.preferredHeight// parent.width//thumbnail.width + 2 * app.baseUnit
                    Layout.margins: 0

                    Image {
                        id: thumbnail
                        anchors.fill: parent
                        Layout.margins: 0
                        cache: true
                        source: thumbnailurl > "" ? thumbnailurl : "../images/default-thumbnail.png"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                cardContent.updateSelectionInModel(index)
                                mapAreaManager.highlightMapArea(index)
                            }
                        }
                    }
                }

                Item {
                    Layout.preferredWidth: 10 * scaleFactor
                }

                Rectangle {
                    id:rect
                    Layout.preferredHeight:cols.height
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft

                    ColumnLayout {
                        id:cols
                        spacing: 0
                        width:parent.width - 30 * scaleFactor

                        Text{

                            id: lbl
                            objectName: "label"
                            visible: text.length > 0
                            text: title

                            color: app.baseTextColor
                            Layout.preferredWidth:rect.width
                            Layout.alignment: Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                            font.bold:isSelected?true:false
                            font.pixelSize: 1.0 * app.baseFontSize

                            maximumLineCount: 2


                            elide: Text.ElideRight
                            wrapMode: Text.WordWrap
                        }



                        RowLayout{
                            spacing: 5 * app.scaleFactor
                            Layout.alignment: Qt.AlignLeft

                            Text{
                                font.pixelSize: app.textFontSize
                                font.family: app.baseFontFamily
                                color: app.subTitleTextColor

                                text: {
                                    let txt = ""
                                    let date = modifiedDate > "" ? modifiedDate : createdDate
                                    txt = new Date(date).toLocaleDateString(Qt.locale(), Locale.ShortFormat)
                                    return  txt
                                }
                            }
                            Rectangle {
                                id:icon
                                Layout.preferredWidth: 4
                                Layout.preferredHeight:4
                                radius: 2
                                color: "grey"
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Text{
                                text:size
                                font.pixelSize: app.textFontSize
                                font.family: app.baseFontFamily
                                color: app.subTitleTextColor
                            }


                        }

                    }
                    MouseArea {

                        anchors.fill: parent
                        onClicked: {

                            cardContent.updateSelectionInModel(index)
                            mapAreaManager.highlightMapArea(index)
                        }
                    }
                }

                Item{
                    Layout.preferredHeight: 50 * scaleFactor//app.iconSize//downloadBtn.height//10 * scaleFactor
                    Layout.preferredWidth: 50 * scaleFactor //app.iconSize//downloadBtn.width//10 * scaleFactor
                    Layout.alignment: Qt.AlignCenter
                    //Material.elevation: 100
                    z:100

                    Controls.Icon {
                        anchors.fill: parent

                        id: downloadBtn
                        visible: !isDownloading
                        imageSource: isPresent ? "../../MapViewer/images/more.png":"../../MapViewer/images/download.png"
                        // imageSource: isPresent?"../images/more.png":"../images/download.png"
                        enabled: !isPresent?(size > "0 Bytes"?true:false):true
                        anchors.centerIn: parent
                        maskColor: app.primaryColor

                        MouseArea {
                            anchors.fill: parent
                            z:200

                            onClicked: {
                                if(isPresent)
                                {
                                    more.close()
                                    more.open()
                                }
                                else
                                {
                                    more.close()
                                    let thumbnailUrl = thumbnailurl
                                    cardContent.updateSelectionInModel(index)

                                    mapView.setViewpointGeometryAndPadding(polygonGraphicsOverlay.extent,100)
                                    mapAreaManager.highlightMapArea(index)
                                    var _mapArea = mapAreas[index].mapArea
                                    var downloadObj = {
                                        "index" : index,
                                        "thumbnailImg" : thumbnailUrl,
                                        "appid" : app.currentAppId,
                                        "mapid" : mapPage.portalItem.id,
                                        "mapArea":_mapArea
                                    }


                                    mapAreaManager.downloadList.push(downloadObj)

                                    mapAreaManager.mapAreasModel.setProperty(index, "isDownloading", true)
                                    mapAreaManager.processDownloadList()

                                }
                            }
                        }
                    }

                    BusyIndicator {
                        id: busyIndicator
                        height: app.iconSize
                        width: height
                        visible:isDownloading
                        Material.primary: app.primaryColor
                        Material.accent: app.primaryColor
                        anchors.centerIn: parent
                    }

                }
            }




        }




        //popup Menu
        Controls.PopupMenu {
            id: more
            isInteractive: false

            property string kRefresh: qsTr("Remove")

            defaultMargin: app.defaultMargin
            backgroundColor: "#FFFFFF"
            highlightColor: Qt.darker(app.backgroundColor, 1.1)
            textColor: app.baseTextColor
            primaryColor: app.primaryColor


            menuItems: [
                {"itemLabel": qsTr("Open"),"lcolor":""},
                // {"itemLabel": qsTr("Update"),"lcolor":""},

                {"itemLabel": qsTr("Remove"),"lcolor":"red"},

            ]

            Material.primary: app.primaryColor
            Material.background: backgroundColor

            height: app.units(88)

            x: app.isRightToLeft ? (0 + app.baseUnit) : (parent.width - width - app.baseUnit)
            y: 0

            onMenuItemSelected: {
                switch (itemLabel) {
                case qsTr("Remove"):
                    processDeleteMapArea(mapAreas[index].mapArea.portalItem.itemId,mapAreas[index].mapArea.portalItem.title)
                    break

                case qsTr("Open"):

                    mapAreaManager.mapAreaOpened()

                    openMapArea(index)
                    panelDockItem.removeDock("mapareas")
                    break
                }
            }

            function openMapArea()
            {
                var fileName = "mapareasinfos.json"
                //iterate through the subfolders


                if (offlineMapAreaCache.fileFolder.fileExists(fileName)) {
                    var fileContent = offlineMapAreaCache.fileFolder.readJsonFile(fileName)
                    var maparea = fileContent.results.filter(item => item.id === mapAreas[index].mapArea.portalItem.itemId)
                    if(maparea !== null && maparea.length > 0){

                        var furl = offlineMapAreaCache.fileFolder.path + "/" + mapPage.portalItem.id +"/" + mapAreas[index].mapArea.portalItem.itemId // + "/p13/"


                        var mapProperties = {"fileUrl":furl, "gdbpath":maparea[0].gdbpath,
                            "basemaps":maparea[0].basemaps,"isMapArea":true,
                            "title":maparea[0].title,"owner":maparea[0].owner,"modifiedDate":maparea[0].modifiedDate,"extent":mapAreas[index].areaOfInterest.extent}
                        mapPage.portalItem_main = mapPage.portalItem
                        mapPage.mapProperties_main = mapPage.mapProperties
                        mapPage.mapProperties_main["isMapArea"] = false


                        mapPage.mapProperties = mapProperties
                        mapPage.portalItem = maparea[0]

                    }

                }
            }

            function processDeleteMapArea(mapareaId,title) {


                app.messageDialog.width = messageDialog.units(300)
                app.messageDialog.standardButtons = Dialog.Cancel | Dialog.Ok


                app.messageDialog.show(qsTr("Remove offline area"),qsTr("This will remove the downloaded offline map area %1 from the device. Would you like to continue?").arg(title))

                app.messageDialog.connectToAccepted(function () {
                    deleteMapArea(mapareaId)
                })
            }

            function deleteMapArea(mapareaId)
            {
                var fileName = "mapareasinfos.json"

                var mapAreaPath = offlineMapAreaCache.fileFolder.path + "/"+ mapPage.portalItem.id
                let mapAreafileInfo = AppFramework.fileInfo(mapAreaPath)
                //fileInfo.folder points to previous folder
                if (mapAreafileInfo.folder.fileExists(fileName)) {
                    var   fileContent = mapAreafileInfo.folder.readJsonFile(fileName)
                    var results = fileContent.results
                    existingmapareas = results.filter(item => item.id !== mapareaId)
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
                    {
                        mapAreafileInfo.folder.writeJsonFile(fileName, fileContent)

                        mapAreaManager.updateModel(mapareaId,false)
                        portalSearch.populateLocalMapPackages()


                    }

                }

            }



            function titleCase(str) {
                return str.toLowerCase().split(" ").map(function(word) {
                    return (word.charAt(0).toUpperCase() + word.slice(1));
                }).join(" ");
            }
        }



       /* Component.onCompleted: {
            if(mapPortalItem.loadStatus !== Enums.LoadStatusLoaded && mapPortalItem.loadStatus !== Enums.LoadStatusLoading)
                mapPortalItem.load()

        }*/
    }


    Controls.BaseText {
        id: message

        visible: model.count <= 0 && text > ""
        maximumLineCount: 5
        elide: Text.ElideRight
        width: parent.width
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: qsTr("There are no offline map areas.")
    }

    function units (num) {
        return num ? num * AppFramework.displayScaleFactor : num
    }


}


