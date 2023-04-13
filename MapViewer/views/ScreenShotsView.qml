import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.12
import QtQuick.Window 2.2
import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.InterAppCommunication 1.0

import ArcGIS.AppFramework.Platform 1.0

import "../controls" as Controls

Popup {
    id: screenShotsView
    x: backgroundMargin
    y: backgroundMargin
    modal: true
    width: app.width - 2*backgroundMargin
    height: app.height - 2*backgroundMargin
    property var imageUrl
    property var draftImageUrl
    property var sourceFileName
    property real headerOpacity: 0.8
    property int backgroundMargin: 0
    property alias screenShots: screenShots
    //property alias listView: listView
    property string urlPrefix: "screenshot"
    property string urlFormat: urlPrefix + "%1.jpg"
    property color backgroundColor: "#000000"
    property int listCurrentIndex:0
    property int  indexToHighlight:listCurrentIndex
    property var tempImageList:[]
    property QtObject mapView
    property string saveString: app.save_changes
    property bool canUndo:false
    property bool canRedo:false
    property bool isDirty:false
    property bool isSelectionMode:false
    property var selectedScreenshots:({})
    property var screenshotsCache:app.screenShotsCacheFolder
    property bool showGridView:app.isPhone
    property bool isAnyScreenshotSelected:true
    property var panelWidth:0.20 * app.width
    property var gridindex:0

    signal screenShotTaken ()
    signal screenShotDiscarded ()
    signal shareButtonClicked ()
    signal showSaveDialog()

    background: Rectangle {
        color: backgroundColor
    }

    ListModel {
        id: screenShots
    }

    onListCurrentIndexChanged:{
        if(!isSelectionMode)
            loadImageInCanvas()
    }

    onOpened:{
        loadImageInCanvas()
    }


    contentItem:Controls.BasePage {
        padding: 0
        anchors.fill: parent

        header: ToolBar {
            id: pageHeader
            height:app.isNotchAvailable()? app.headerHeight + app.notchHeight : app.headerHeight
            topPadding:app.isNotchAvailable() ? app.notchHeight:0
            width: app.width
            padding: 0
            Material.primary: app.primaryColor

            RowLayout {
                anchors.fill: parent
                Controls.Icon {
                    imageSource: "../images/close.png"
                    Layout.leftMargin: app.widthOffset
                    visible:showGridView || !app.isPhone
                    onClicked:
                    {
                        isSelectionMode = false
                        saveDialog.furtherAction = "close"
                        if(canvas.sketches.length > 0)
                        {
                            saveDialog.open()

                        }
                        else
                        {
                            screenShotsView.close()
                            toolbarrow.visible = true
                        }

                        deleteTempFiles()

                    }
                }
                Controls.Icon {
                    imageSource: "../images/back.png"
                    Layout.leftMargin: app.widthOffset
                    visible:!showGridView && app.isPhone
                    rotation: app.isLeftToRight ? 0 : 180
                    onClicked:
                    {
                        saveDialog.furtherAction = "back"
                        if(canvas.sketches.length > 0)
                        {
                            saveDialog.open()

                        }
                        else
                        {
                            showGridView = true
                            //screenShotsView.close()
                        }

                    }
                }


                Controls.SpaceFiller {
                }

                Controls.Icon {
                    id: leftIcon
                    visible: screenShots.count > 1 && (!showGridView)
                    imageSource: "../images/arrowDown.png"
                    Layout.alignment: Qt.AlignHCenter
                    rotation: app.isLeftToRight ? 90 : -90
                    enabled: listCurrentIndex > 0 && !isSelectionMode
                    opacity: enabled ? 1 : 0.3
                    onClicked: {
                        if (enabled &&  (canvas.sketches.length > 0))
                        {
                            saveDialog.furtherAction = "prev"
                            saveDialog.open()
                        }
                        else
                        {
                            if(enabled)
                            {
                                listCurrentIndex -=1
                                canvas.canUndo = false
                                canvas.canRedo = false
                                flickable.contentY= listCurrentIndex > 3? (listCurrentIndex - 2) * listPanel.width/1.6:0

                            }
                        }
                    }
                }

                Controls.SubtitleText {
                    id: counterText
                    visible: screenShots.count > 1 && (!showGridView)
                    Layout.alignment: Qt.AlignHCenter
                    color: "#FFFFFF"
                    text: qsTr("%L1 of %L2").arg(listCurrentIndex + 1).arg(screenShots.count)
                }

                Controls.Icon {
                    id: rightIcon
                    visible: screenShots.count > 1 && (!showGridView )
                    Layout.alignment: Qt.AlignHCenter
                    imageSource: "../images/arrowDown.png"
                    rotation: app.isLeftToRight ? -90 : 90
                    enabled: listCurrentIndex < screenShots.count - 1 && !isSelectionMode
                    opacity: enabled ? 1 : 0.3
                    onClicked: {
                        if (enabled && (canvas.sketches.length > 0))
                        {
                            saveDialog.furtherAction ="next"
                            saveDialog.open()

                        }
                        else

                            if (enabled)
                            {
                                listCurrentIndex += 1
                                canvas.canUndo = false
                                canvas.canRedo = false
                                flickable.contentY = listCurrentIndex > 3? (listCurrentIndex - 2) * listPanel.width/1.6 + listPanel.width:0

                            }
                    }
                }

                Controls.SpaceFiller {
                }

                Controls.Icon {
                    enabled: !screenShotToast.visible && (isSelectionMode?isAnyScreenshotSelected:true)
                    opacity: enabled ? 1 : 0.3
                    Layout.alignment: Qt.AlignRight
                    imageSource: "../images/delete.png"

                    onClicked: {
                        var discard = discardDialog.createObject(app)
                        indexToHighlight = screenshotsCount
                        var nodeleted = 0
                        var lastIndex = 0
                        discard.connectToAccepted(function () {
                            canvas.sketches = []
                            canvas.undoList = []
                            canvas.canUndo = false
                            if(!screenshotsCache)
                            {
                                var screenshotsBasePath = app.screenshotsCache.storagePath + portalItem.id + "/"
                                screenShotsCacheFolder = AppFramework.fileInfo(screenshotsBasePath).folder
                            }

                            var entries = Object.entries(selectedScreenshots)
                            if(isSelectionMode)
                            {
                                var filesRemoved = 0

                                for (let [key, value] of entries){

                                    if(value)
                                    {
                                        let fileUrl = screenShots.get(key).url
                                        let splits = fileUrl.split("/")
                                        let file = splits[splits.length-1]
                                        screenshotsCache.removeFile(file)
                                        lastIndex = key
                                        filesRemoved ++
                                    }

                                }
                                selectedScreenshots = ({})
                                //in selection mode
                                if(filesRemoved > 1){
                                    listCurrentIndex = 0
                                    indexToHighlight = 0

                                }
                                else
                                {
                                    listCurrentIndex = lastIndex
                                    if(listCurrentIndex < screenshotsCount - 1)
                                        indexToHighlight = listCurrentIndex
                                    else
                                    {
                                        listCurrentIndex = listCurrentIndex - 1
                                        indexToHighlight = listCurrentIndex
                                    }
                                }
                                selectedScreenshots[listCurrentIndex] = 1
                                updateScreenShotsModel(true,"delete")
                                loadImageInCanvas()

                            }
                            else
                            {
                                var urlsplits = screenShots.get(listCurrentIndex).url.split("/")
                                var imagefile = urlsplits[urlsplits.length-1]

                                screenshotsCache.removeFile(imagefile)
                                if(listCurrentIndex < screenshotsCount - 1)
                                    indexToHighlight = listCurrentIndex
                                else
                                    indexToHighlight = listCurrentIndex - 1

                                updateScreenShotsModel(true,"delete")
                            }
                        })
                        discard.connectToAccepted(function () {
                            gridindex = 0
                            screenShotDiscarded()

                        })

                        if(Object.keys(selectedScreenshots).length > 1)
                            discard.show("", qsTr("Do you want to discard screenshots?"))
                        else

                            discard.show("", qsTr("Discard screenshot?"))
                    }
                }

                Controls.Icon {
                    enabled:isSelectionMode?isAnyScreenshotSelected:true
                    opacity: enabled ? 1 : 0.3
                    Layout.alignment: Qt.AlignRight
                    imageSource: "../images/share.png"
                    Layout.rightMargin: app.widthOffset
                    onClicked: {
                        shareButtonClicked()
                    }
                }
            }
        }
        contentItem:Rectangle{
            id: screenshotsPage


            states: [

                State {
                    name: "anchorleft"
                    when:!app.isPhone && !app.isLeftToRight

                    AnchorChanges {
                        target: viewerPanel
                        anchors.left: screenshotsPage.left
                    }

                    PropertyChanges {
                        target: listPanel
                        x:viewerPanel.width
                    }
                    PropertyChanges {
                        target: screenshotsPhoneView
                        width:0
                        visible:false
                    }


                },
                State{
                    name:"smallScreen_selected"
                    when:showGridView && app.isPhone
                    //                    AnchorChanges {
                    //                        target: viewerPanel
                    //                        anchors.left: screenshotsPage.left
                    //                    }
                    PropertyChanges {
                        target: listPanel
                        width:0
                        visible:false

                    }
                    PropertyChanges {
                        target: viewerPanel
                        width:0
                        //visible:false

                    }

                    PropertyChanges {
                        target: screenshotsPhoneView
                        width:app.isLeftToRight?  screenshotsPage.width: screenShotsView.width - app.units(25)//screenShotsView.width - 25//app.width - 2 * app.defaultMargin//screenshotsPage.width

                    }
                },

                State{
                    name:"smallScreen_index"
                    when:!showGridView && app.isPhone
                    AnchorChanges {
                        target: viewerPanel
                        anchors.left: screenshotsPage.left
                    }

                    PropertyChanges {
                        target: listPanel
                        width:0
                        visible:false

                    }
                    PropertyChanges {
                        target: viewerPanel
                        width:screenshotsPage.width
                        //visible:false

                    }

                    PropertyChanges {
                        target: screenshotsPhoneView
                        width:0

                    }
                },

                State{
                    name: "anchorright"
                    when:!app.isPhone
                    AnchorChanges {
                        target: viewerPanel
                        anchors.right: screenshotsPage.right
                    }
                    PropertyChanges {
                        target: listPanel
                        x:0

                    }
                    PropertyChanges {
                        target: screenshotsPhoneView
                        width:0
                        visible:false
                    }

                }

            ]


            Material.background: app.backgroundColor


            Rectangle{
                id:listPanel
                width:panelWidth
                height:app.height - pageHeader.height
                ColumnLayout{
                    id:picturesPanel
                    anchors.fill:parent

                    RowLayout{
                        Layout.preferredHeight: app.units(50)
                        Layout.fillWidth: true
                        Controls.SubtitleText {
                            id: picturescount

                            // Layout.alignment: Qt.AlignLeft
                            color: Qt.darker(app.backgroundColor, 3.8)//"#FFFFFF"
                            //opacity:1
                            text: qsTr("Total: %L1").arg(screenShots.count)
                            leftPadding: app.isLeftToRight ? app.units(16) : 0
                            rightPadding: app.isLeftToRight ?  0 : app.units(16)
                            fontsize: picturesPanel.width < 150 ?app.units(10):app.units(14)//fontScale > 1 ? fontScale * app.units(14):fontScale * app.units(14)
                            //fontsize: fontScale * 10
                            //fontSizeMode: Text.Fit

                        }

                        Item{
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            // Layout.alignment: Qt.AlignRight
                            Controls.SubtitleText {
                                id: select
                                //anchors.centerIn: parent
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                color: app.primaryColor//"#FFFFFF"
                                text: isSelectionMode?qsTr("Cancel"):qsTr("Select")
                                rightPadding: app.isLeftToRight ? app.units(20) : 0
                                leftPadding: app.isLeftToRight ?  0: app.units(20)
                                fontsize: picturesPanel.width < 150 ?app.units(10):app.units(14)
                                fontSizeMode: Text.Fit
                            }
                            MouseArea{
                                anchors.fill:parent
                                onClicked: {

                                    isSelectionMode = !isSelectionMode
                                    updateSelection()

                                }
                            }
                        }

                    }

                    Flickable {
                        id:flickable
                        Layout.fillWidth: true
                        Layout.preferredHeight: parent.height - app.units(50)
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.VerticalFlick
                        interactive: true
                        contentHeight:pictureslist.height
                        clip: true
                        ColumnLayout{
                            id:pictureslist
                            width:parent.width - defaultMargin
                            anchors.left: parent.left
                            spacing:10

                            Repeater {
                                id: repeater
                                model: screenShots
                                delegate:
                                    RowLayout{
                                    Layout.preferredWidth: parent.width
                                    spacing:0

                                    Rectangle{
                                        Layout.preferredWidth:parent.width
                                        Layout.preferredHeight:listPanel.width/1.7
                                        Rectangle{
                                            id: pictureslblcount

                                            width:app.units(35)
                                            height:app.units(100)
                                            anchors.left:parent.left

                                            Controls.SubtitleText {
                                                width: parent.width
                                                Layout.alignment: Qt.AlignTop
                                                color: Qt.darker(app.backgroundColor, 3.8)
                                                text: qsTr("%L1").arg(index + 1)
                                                leftPadding: app.units(16)

                                            }
                                        }

                                        Rectangle{
                                            id:screenshotImg
                                            width: parent.width - pictureslblcount.width
                                            height:listPanel.width/1.7
                                            anchors.right:parent.right
                                            border.width:app.units(2)
                                            border.color:!isSelectionMode ?(screenShots.get(listCurrentIndex) !== undefined?(url === screenShots.get(listCurrentIndex).url?app.primaryColor:"transparent"):"transparent"):"transparent"

                                            Layout.alignment: Qt.AlignTop
                                            ColumnLayout{
                                                //fontsize: parent.width < 150 ?app.units(10):app.units(14)//fontScale > 1 ? fontScale * app.units(14):fontScale * app.units(14)

                                                width:parent.width < 100?parent.width - 1 * defaultMargin:parent.width - 1.5 * defaultMargin
                                                height:parent.width < 100?parent.height - 1 * defaultMargin:parent.height - 1.5 * defaultMargin
                                                anchors.centerIn: parent
                                                spacing:0


                                                Rectangle {
                                                    id:screenshotImgInner
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    border.width:1
                                                    border.color:app.separatorColor //"#f7f8f8"//root.getAppProperty (app.baseTextColor, Qt.darker("#F7F8F8"))
                                                    Image {
                                                        anchors {
                                                            fill: parent
                                                            margins: 1
                                                        }
                                                        fillMode: Image.PreserveAspectCrop//Image.PreserveAspectFit
                                                        //fillMode: Image.PreserveAspectFit
                                                        source:url //{
                                                        cache: false

                                                    }
                                                }
                                                Rectangle{

                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: app.units(16)
                                                    //color:"red"
                                                    Layout.topMargin: app.units(8)

                                                    RowLayout{
                                                        anchors.fill:parent
                                                        spacing:0
                                                        Rectangle
                                                        {
                                                            id:daterect
                                                            //Layout.fillWidth: true
                                                            Layout.preferredWidth: parent.width/2
                                                            Layout.fillHeight: true
                                                            color:"transparent"
                                                            Controls.SubtitleText {
                                                                id: modDate
                                                                Layout.alignment: Qt.AlignLeft
                                                                text: modifiedDate
                                                                fontsize:Qt.platform.os === "windows"?(parent.width < 30?app.units(4): parent.width < 50?app.units(6):parent.width < 100 ?app.units(8):app.units(12)):parent.width < 50 ?app.units(8):app.units(12)
                                                                leftPadding: 0

                                                            }
                                                        }

                                                        Rectangle{
                                                            id:sizerect
                                                            //Layout.fillWidth: true
                                                            Layout.preferredWidth:parent.width/4
                                                            Layout.fillHeight: true
                                                            Layout.alignment: Qt.AlignRight
                                                            //color:"green"
                                                            Controls.SubtitleText {
                                                                // Label{
                                                                id: picsize
                                                                text:size
                                                                horizontalAlignment: Text.AlignRight
                                                                anchors.right:parent.right
                                                                fontsize: modDate.fontsize//parent.width < 25 ?app.units(8):app.units(12)
                                                                //fontSizeMode: Text.Fit
                                                                rightPadding: 0

                                                            }
                                                        }
                                                    }
                                                }

                                            }

                                            MouseArea{
                                                anchors.fill:parent
                                                onClicked: {
                                                    if(!isSelectionMode)
                                                    {

                                                        if (canvas.sketches.length > 0)
                                                        {
                                                            saveDialog.furtherAction = "select"
                                                            saveDialog.selectedIndex = index
                                                            saveDialog.open()
                                                        }
                                                        else
                                                        {
                                                            listCurrentIndex = index
                                                            canvas.canUndo = false
                                                            canvas.canRedo = false

                                                        }
                                                    }
                                                    else
                                                    {
                                                        if(selectedScreenshots[index] > 0)
                                                        {
                                                            parent.border.color = "transparent"
                                                            selectedScreenshots[index] = null
                                                        }
                                                        else
                                                        {

                                                            parent.border.color = app.primaryColor
                                                            selectedScreenshots[index] = 1
                                                        }
                                                        isAnyScreenshotSelected = selectedScreenshots && Object.values(selectedScreenshots).some(x => (x !== null && x !== ''))

                                                    }

                                                }
                                            }
                                            Connections{
                                                target:screenShotsView
                                                function onIsSelectionModeChanged(){

                                                    if(!isSelectionMode)
                                                    {
                                                        screenshotImg.border.color = url === screenShots.get(listCurrentIndex).url?app.primaryColor:"transparent"

                                                    }
                                                    else
                                                    {
                                                        if(url === screenShots.get(listCurrentIndex).url)
                                                            screenshotImg.border.color = app.primaryColor
                                                    }

                                                }
                                                function onListCurrentIndexChanged(){
                                                    screenshotImg.border.color = url === screenShots.get(listCurrentIndex).url?app.primaryColor:"transparent"
                                                }
                                                function onScreenShotDiscarded(){
                                                    if(url === screenShots.get(listCurrentIndex).url)
                                                        screenshotImg.border.color = app.primaryColor

                                                }
                                            }

                                        }
                                        DropShadow {
                                            anchors.fill: screenshotImg
                                            horizontalOffset: 0
                                            verticalOffset: 0
                                            radius:8.0
                                            samples: 16
                                            smooth: true
                                            color: "#20000000"
                                            spread: 0.0
                                            source: screenshotImg

                                        }
                                    }

                                }

                            }

                            Rectangle{
                                Layout.fillWidth:true
                                Layout.preferredHeight: app.units(16)
                            }
                        }

                    }

                }

            }



            Rectangle{
                id:screenshotsPhoneView
                width: app.width - 3 * app.defaultMargin
                height:app.height - pageHeader.height
                color:"transparent"
                anchors.centerIn: parent

                ColumnLayout{
                    width:parent.width
                    spacing:0
                    anchors.horizontalCenter: parent.horizontalCenter

                    Item{
                        Layout.fillWidth:true
                        Layout.preferredHeight:app.units(48)
                        RowLayout{
                            id:gridheader
                            height: parent.height
                            width: parent.width - 2 * app.defaultMargin
                            anchors.centerIn:parent

                            Controls.SubtitleText {
                                id: picturescount_grid
                                Layout.alignment: Qt.AlignLeft
                                text: qsTr("Total: %L1").arg(screenShots.count)
                                fontsize: app.units(14)
                                verticalAlignment: Text.AlignVCenter
                                color: Qt.darker(app.backgroundColor, 3.8)//"#FFFFFF"

                            }

                            Item{
                                Layout.preferredWidth: select1.width
                                Layout.fillHeight: true
                                Layout.alignment: Qt.AlignRight
                                Layout.rightMargin: 0.5 * app.defaultMargin
                                Controls.SubtitleText {
                                    id: select1
                                    anchors.centerIn: parent
                                    color: app.primaryColor//"#FFFFFF"
                                    text: isSelectionMode?qsTr("Cancel"):qsTr("Select")
                                    fontsize: app.units(14)
                                }
                                MouseArea{
                                    anchors.fill:parent
                                    onClicked: {
                                        isSelectionMode = !isSelectionMode
                                        updateSelection()

                                    }
                                }


                            }

                        }
                    }

                    Rectangle{
                        Layout.fillWidth:true
                        Layout.preferredHeight:app.height - pageHeader.height - gridheader.height - app.units(32)

                        Rectangle{
                            id:phonegrid
                            width:parent.width - 2 * app.defaultMargin
                            height:app.height - pageHeader.height - gridheader.height - app.units(32)
                            //anchors.centerIn: parent
                            anchors.horizontalCenter: parent.horizontalCenter


                            opacity: 1


                            GridView {
                                id: gridPhoneView
                                anchors.fill:parent
                                //Layout.topMargin: app.defaultMargin
                                property real columns:2
                                cellWidth:width/columns
                                cellHeight: cellWidth * 0.8
                                flow: GridView.FlowLeftToRight
                                clip: true
                                model:screenShots
                                opacity:1
                                highlightFollowsCurrentItem:true

                                delegate:Pane{
                                    height: GridView.view.cellHeight - 0.5 * app.defaultMargin
                                    width: GridView.view.cellWidth - 0.5 * app.defaultMargin

                                    topPadding: app.units(2)//app.defaultMargin
                                    bottomPadding: 0

                                    contentItem:Rectangle{
                                        anchors.fill:parent

                                        Rectangle{
                                            id:phoneimglbl
                                            width:app.isLeftToRight ? app.units(16): app.units(32)
                                            height:parent.height

                                            anchors.leftMargin: app.isLeftToRight ? 0:app.units(10)

                                            anchors.left:parent.left

                                            Controls.SubtitleText {
                                                id: pictureslblcount_phone
                                                anchors.left: parent.left
                                                color: Qt.darker(app.backgroundColor, 3.8)
                                                text: qsTr("%L1").arg(index + 1)

                                            }
                                        }

                                        Rectangle{
                                            id:phoneRect
                                            width:parent.width - phoneimglbl.width - 0.5 * defaultMargin
                                            height:parent.height
                                            anchors.right:parent.right
                                            border.color:getColor(isSelectionMode,url)
                                            border.width:2

                                            ColumnLayout{
                                                //fontsize: parent.width < 150 ?app.units(10):app.units(14)//fontScale > 1 ? fontScale * app.units(14):fontScale * app.units(14)
                                                width:parent.width - 1.5 * defaultMargin
                                                height:parent.height - 1.5 * defaultMargin
                                                anchors.centerIn: parent
                                                spacing:0
                                                Rectangle{
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    border.color:app.separatorColor
                                                    border.width:1
                                                    Rectangle {
                                                        id:screenshotImg1
                                                        width:parent.width - app.units(2)
                                                        height:parent.height - app.units(2)

                                                        anchors.centerIn: parent

                                                        Image {
                                                            id: thumbnailImg

                                                            source: url
                                                            cache: false
                                                            anchors.fill: parent

                                                            fillMode: Image.PreserveAspectCrop//Image.PreserveAspectFit
                                                            BusyIndicator {
                                                                anchors.centerIn: parent
                                                                running: thumbnailImg.status === Image.Loading
                                                            }

                                                        }


                                                    }

                                                }


                                                Rectangle{
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: app.units(16)
                                                    //color:"red"
                                                    Layout.topMargin: app.units(8)

                                                    RowLayout{
                                                        anchors.fill:parent
                                                        spacing:0
                                                        Rectangle
                                                        {
                                                            id:daterectphone
                                                            //Layout.fillWidth: true
                                                            Layout.preferredWidth: parent.width/2
                                                            Layout.fillHeight: true

                                                            Controls.SubtitleText {
                                                                id: modDatephone
                                                                horizontalAlignment: Text.AlignLeft
                                                                text: modifiedDate
                                                                fontsize: app.units(12)
                                                                leftPadding: 0

                                                            }
                                                        }


                                                        Rectangle{
                                                            id:sizerectphone
                                                            //Layout.fillWidth: true
                                                            Layout.preferredWidth:parent.width/4//app.units(50)//picsize.width //- daterect.width
                                                            Layout.fillHeight: true
                                                            Layout.alignment: Qt.AlignRight
                                                            //color:"green"
                                                            Controls.SubtitleText {
                                                                // Label{
                                                                id: picsizephone
                                                                text:size
                                                                horizontalAlignment: Text.AlignRight
                                                                anchors.right:parent.right
                                                                fontsize: parent.width < 25 ?app.units(8):app.units(12)
                                                                //fontSizeMode: Text.Fit
                                                                rightPadding: 0

                                                            }
                                                        }
                                                    }
                                                }

                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    if(!isSelectionMode)
                                                    {
                                                        showGridView = false
                                                        if(listCurrentIndex !== index)
                                                            listCurrentIndex = index
                                                        loadImageInCanvas()
                                                        canvas.canUndo = false
                                                        canvas.canRedo = false

                                                    }
                                                    else
                                                    {
                                                        if(selectedScreenshots[index] > 0)
                                                        {
                                                            parent.border.color = "transparent"
                                                            selectedScreenshots[index] = null
                                                        }
                                                        else
                                                        {
                                                            parent.border.color = app.primaryColor
                                                            selectedScreenshots[index] = 1

                                                        }
                                                        isAnyScreenshotSelected =selectedScreenshots && Object.values(selectedScreenshots).some(x => (x !== null && x !== ''))

                                                    }

                                                }
                                            }
                                            Connections{
                                                target:screenShotsView
                                                function onIsSelectionModeChanged(){
                                                    if(!isSelectionMode)
                                                    {
                                                        phoneRect.border.color = url === screenShots.get(listCurrentIndex).url?app.primaryColor:"transparent"
                                                    }
                                                    else
                                                    {
                                                        if(url === screenShots.get(listCurrentIndex).url)
                                                            phoneRect.border.color = app.primaryColor
                                                    }
                                                }
                                                function onListCurrentIndexChanged(){
                                                    phoneRect.border.color = url === screenShots.get(listCurrentIndex).url?app.primaryColor:"transparent"
                                                }
                                                function onScreenShotDiscarded(){


                                                }
                                            }
                                        }

                                        SequentialAnimation {
                                            id: fadingAnimation

                                            ScriptAction {
                                                script:
                                                {
                                                    showGridView = false
                                                    loadImageInCanvas();
                                                }
                                            }
                                            PropertyAnimation {
                                                id: fade_away2
                                                target:viewerPanel
                                                properties: "opacity"
                                                from: 0
                                                to: 1
                                                duration: 100
                                            }

                                        }

                                        DropShadow {
                                            anchors.fill:phoneRect
                                            horizontalOffset: 0
                                            verticalOffset: 0
                                            radius:8.0
                                            samples: 16
                                            color: "#20000000"
                                            //spread: 0.0
                                            smooth: true
                                            source: phoneRect

                                        }

                                    }


                                }

                            }

                        }

                    }
                }
            }


            Rectangle{
                id:viewerPanel
                width:parent.width - panelWidth
                height:parent.height
                opacity:1

                SketchCanvas {
                    id: canvas
                    anchors.fill: parent
                    settings: app.settings
                    penColor: isSelectionMode ? "transparent":sketchPanel.colorObject.colorName

                    onPressedChanged: {
                        // if(pressed) sketchPanel.colorController.isSelecting = false;
                    }

                    Component.onDestruction: {
                        //console.log("Destroying sketch canvas")
                        if (imageUrl && isImageLoaded(imageUrl)) {
                            //console.log("Unloading:", imageUrl);
                            unloadImage(imageUrl);
                        }
                    }

                    paintBackground: function (ctx) {

                        //ctx.fillStyle = sketch.color;
                        ctx.fillRect(0, 0, canvas.width, canvas.height);

                        if (imageUrl && isImageLoaded(imageUrl)) {
                            ctx.drawImage(imageUrl, 0, 0);
                        }

                        if (!currentImageObject.empty) {
                            ctx.drawImage(currentImageObject.url, 0, 0);
                        }

                        if (!pasteImageObject.empty) {
                            ctx.drawImage(pasteImageObject.url, pasteImageObject.offsetX, pasteImageObject.offsetY);
                        }
                    }

                    onImageLoaded: {
                        //console.log("onImageLoaded:", imageUrl);
                        requestPaint();
                    }

                    function clear_canvas() {
                        var ctx = getContext("2d");
                        ctx.reset();

                    }

                }

                SketchPanel{
                    id: sketchPanel
                    anchors.bottom: parent.bottom
                    //anchors.bottomMargin:app.isNotchAvailable()?app.units(20):0//app.isIphoneX?app.units(20) * scaleFactor:0
                    visible:!isSelectionMode && !showGridView
                    anchors.horizontalCenter: parent.horizontalCenter

                    Connections {
                        target: screenShotsView

                        function onShowSaveDialog() {

                        }
                    }

                }

                DropShadow {
                    anchors.fill: sketchPanel
                    horizontalOffset: 0
                    verticalOffset: 0
                    radius:5.0
                    samples: 16
                    color: "#20000000"
                    //spread: 0.0
                    smooth:true
                    source: sketchPanel
                    visible: !isSelectionMode && !showGridView
                }


                Pane {
                    id: undoRedoDraw
                    padding: 0
                    width: 2*app.iconSize + clearText.width + 2*app.defaultMargin + 2 * app.baseUnit
                    height: (2/3) * app.headerHeight
                    visible:!isSelectionMode && (canvas.canUndo || canvas.canRedo)
                    Material.elevation: 4
                    Material.background: "#FFFFFF"
                    anchors {
                        right: parent.right
                        top: parent.top
                        topMargin: app.defaultMargin
                        rightMargin: app.defaultMargin
                    }
                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Controls.BaseText {
                            id: clearText
                            text: kClear
                            Layout.topMargin: 0
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignCenter

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    clear()

                                }
                            }

                        }

                        Rectangle {
                            Layout.preferredHeight: parent.height - 2*app.baseUnit
                            Layout.preferredWidth: app.units(2)
                            color: app.backgroundColor
                        }

                        Controls.Icon {
                            imageSource: !app.isLeftToRight ? "../images/redo.png" : "../images/undo.png"
                            Layout.leftMargin: app.baseUnit
                            Layout.alignment: Qt.AlignVCenter
                            maskColor:  canvas.canUndo ? app.darkIconMask : Qt.lighter(app.darkIconMask, 2.5)
                            imageWidth: 0.7 * iconSize
                            imageHeight: 0.7 * iconSize
                            iconSize: 0.8 * app.iconSize
                            onClicked: {
                                undo()

                            }
                        }

                        Controls.Icon {
                            imageSource: !app.isLeftToRight ? "../images/undo.png" : "../images/redo.png"
                            Layout.rightMargin: app.baseUnit
                            Layout.alignment: Qt.AlignVCenter
                            maskColor: canvas.canRedo ? app.darkIconMask : Qt.lighter(app.darkIconMask, 2.5)
                            imageWidth: 0.7 * iconSize
                            imageHeight: 0.7 * iconSize
                            iconSize: 0.8 * app.iconSize
                            onClicked: {
                                redo()

                            }
                        }
                    }
                }
            }

            Component.onCompleted: {
                //copy

                var item = screenShots.get(listCurrentIndex)
                if(item)
                {
                    var pictureUrl = item.url;
                    var pictureUrlInfo = AppFramework.urlInfo(pictureUrl);
                    var picturePath = pictureUrlInfo.localFile;
                    var assetInfo = AppFramework.urlInfo(picturePath);
                    sourceFileName = pictureUrlInfo.fileName
                    var outputFileName;
                    var suffix = AppFramework.fileInfo(picturePath).suffix;
                    var fileName = AppFramework.fileInfo(picturePath).baseName+AppFramework.createUuidString(2);
                    var a = suffix.match(/&ext=(.+)/);
                    if (Array.isArray(a) && a.length > 1) {
                        suffix = a[1];
                    }

                    if (assetInfo.scheme === "assets-library") {
                        pictureUrl = assetInfo.url;
                    }

                    pasteImage(pictureUrl);
                }
            }

        }

    }

    ImageObject {
        id: currentImageObject
    }
    ImageObject {
        id: pasteImageObject


        property int offsetX: 0
        property int offsetY: 0
    }

    ZipWriter {
        id: zipWriter
        path:screenshotsCache != null?screenshotsCache.path + "/" + mapInfo.title + "_Attachments.zip":""
    }

    Component {
        id: discardDialog

        Controls.MessageDialog {

            standardButtons: DialogButtonBox.NoRole
            Component.onCompleted: {
                addButton(qsTr("CANCEL"), DialogButtonBox.RejectRole, app.accentColor)
                addButton(qsTr("DISCARD"), DialogButtonBox.AcceptRole, app.warning_color)
            }

            onCloseCompleted: {
                destroy()
            }
        }
    }

    onScreenShotDiscarded: {
        if(screenshotsCount > 0)
        {
            measureToast.isBodySet = false
            measureToast.toVar = parent.height-measureToast.height
            measureToast.show(qsTr("Screenshot discarded."),parent.height - measureToast.height, 1500)
        }
        if(!isSelectionMode)
            flickable.contentY= listCurrentIndex > 3? (listCurrentIndex - 2) * listPanel.width/1.6 + listPanel.width :0


    }

    Controls.ToastDialog {
        id: screenShotToast
        z: parent.z + 1

        fromVar: parent.height
        enter: Transition {
            NumberAnimation { property: "y";easing.type:Easing.InOutQuad; from:screenShotToast.fromVar; to:screenShotToast.toVar}
        }
        exit:Transition {
            NumberAnimation { property: "y";easing.type:Easing.InOutQuad; from:screenShotToast.toVar; to:screenShotToast.fromVar}
        }
    }

    Connections {
        target: mapView

        function onExportImageUrlChanged() {
            if (mapView.exportImageUrl) {
                updateScreenShotsModel(true)
            }
        }
    }

    BusyIndicator {
        id: busyIndicator
        visible: false
        anchors.centerIn: parent
        Material.accent: app.accentColor
        Material.primary: app.primaryColor
    }

    Timer {
        id: emailComposerLoading

        interval: 3000
        repeat: false
        onTriggered: {
            busyIndicator.visible = false
        }
    }

    EmailComposer {
        id: emailcomposer
        subject: qsTr("%1 screenshot").arg(app.info.title || "Map Viewer")
        body: ""
        html: true

        onErrorChanged: {
            var reason = error.errorCode
            switch (reason) {
            case EmailComposerError.ErrorInvalidRequest:
                app.messageDialog.show("",qsTr("Invalid Request"))
                break;
            case EmailComposerError.ErrorServiceMissing:
                app.messageDialog.show("",app.mail_service_not_configured)
                break;
            case EmailComposerError.ErrorFileRead:
                app.messageDialog.show("",app.invalid_attachment)
                break;
            case EmailComposerError.ErrorPermission:
                app.messageDialog.show("",qsTr("Permission Error"))
                break;
            case EmailComposerError.ErrorNotSupportedFeature:
                messageDialog.open();
                app.messageDialog.show("",app.platform_not_supported)
                break;
            default:
                messageDialog.open();
                app.messageDialog.show("",app.unknown_error)
            }
        }
    }

    Component.onCompleted: {
        updateScreenShotsModel()
        loadImageInCanvas()
    }

    function getColor(isSelectionMode,url)
    {

        if (url === screenShots.get(listCurrentIndex).url)
            return  app.primaryColor
        else
            return "transparent"
    }

    function deletedSelectedScreenshots()
    {
        var entries = Object.entries(selectedScreenshots)
        for (let [key, value] of entries){

            if(value)
            {
                let fileUrl = screenShots.get(key).url
                let splits = fileUrl.split("/")
                let file = splits[splits.length-1]
                screenshotsCache.removeFile(file)

            }

        }
    }

    function updateSelection()
    {
        if(isSelectionMode)
        {
            if (canvas.sketches.length > 0)
            {
                saveDialog.furtherAction = "turnSelectMode"
                saveDialog.selectedIndex = listCurrentIndex
                saveDialog.open()
            }
            else
            {
                selectedScreenshots = ({})
                selectedScreenshots[listCurrentIndex] = 1
            }
            isAnyScreenshotSelected = selectedScreenshots && Object.values(selectedScreenshots).some(x => (x !== null && x !== ''))
        }
        else
        {
            selectedScreenshots = ({})
            canvas.sketches = []
            listCurrentIndex = 0
        }
    }

    function sendCurrentScreenshot()
    {
        var _attachments = []
        var fileurl = screenShots.get(listCurrentIndex).url
        var fileInfourl = AppFramework.resolvedUrl(fileurl)
        var picfileinfo = AppFramework.fileInfo(fileInfourl)

        if(AppFramework.clipboard.supportsShare)
        {
            AppFramework.clipboard.share(picfileinfo.url)
        }
        else
        {
            var localfile = AppFramework.urlInfo(fileurl).localFile
            _attachments.push(localfile)
            var _listattachments = _attachments.join(',')
            emailcomposer.attachments = _listattachments
            emailcomposer.show()
        }
    }

    onShareButtonClicked: {
        if(!screenshotsCache)
        {
            var screenshotsBasePath = app.screenshotsCache.storagePath + portalItem.id + "/"
            app.screenShotsCacheFolder = AppFramework.fileInfo(screenshotsBasePath).folder
            app.screenShotsCacheFolder.makeFolder()

        }
        //get the keys with non empty values

        let no_selectedRec =  Object.values(selectedScreenshots).filter(x => x !== null);
        var attachments = []
        //var attachmentFileUrl=""
        //get the selected attachments
        if(isSelectionMode)
        {
            let zippedFile = AppFramework.fileInfo(zipWriter.path)
            var zippedFileFolder = zippedFile.folder
            if(zippedFile.exists && no_selectedRec.length > 1)
                zippedFileFolder.removeFile(zippedFile.fileName)
            let entries = Object.entries(selectedScreenshots)
            if(no_selectedRec.length > 0)
            {
                for (let [key, value] of entries){
                    if(value)
                    {
                        var fileurl = screenShots.get(key).url
                        var localfile = AppFramework.urlInfo(fileurl).localFile
                        attachments.push(localfile)
                        if (no_selectedRec.length > 1)
                            var isadded = zipWriter.addFile(localfile)
                    }

                }
                if (no_selectedRec.length > 1)
                {
                    zipWriter.close()

                    if(AppFramework.clipboard.supportsShare)
                    {
                        var zipfileinfo = AppFramework.fileInfo(zipWriter.path)
                        AppFramework.clipboard.share(zipfileinfo.url)
                    }
                    else
                    {
                        emailcomposer.attachments = zipWriter.path
                        emailcomposer.show()
                    }
                }
                else
                {
                    if(AppFramework.clipboard.supportsShare)
                    {
                        var attachmentFileUrl = screenshotsCache.fileUrl(attachments[0])
                        AppFramework.clipboard.share(attachmentFileUrl)
                    }
                    else
                    {
                        var listattachments = attachments.join(',')
                        emailcomposer.attachments = listattachments
                        emailcomposer.show()
                    }
                }

            }
            else
            {
                sendCurrentScreenshot()
            }

        }
        else if(showGridView && app.isPhone)
        {
            sendCurrentScreenshot()

        }
        else
        {
            var filePath = screenshotsCache.filePath(AppFramework.urlInfo(imageUrl).localFile);
            var saveFileName = "draft-"+ AppFramework.fileInfo(filePath).fileName;

            draftImageUrl = screenshotsCache.fileUrl(saveFileName);
            var savePath = screenshotsCache.filePath(saveFileName);
            if (!save(savePath)) {
                console.error("Error saving canvas to:", savePath);
            }
            else
                tempImageList.push(saveFileName)

            if(AppFramework.clipboard.supportsShare)
            {
                AppFramework.clipboard.share(draftImageUrl)
            }
            else
            {
                emailcomposer.attachments = AppFramework.urlInfo(draftImageUrl).localFile
                emailcomposer.show()
            }
        }


    }

    function loadImageInCanvas()
    {
        //copy
        var item = screenShots.get(listCurrentIndex)
        if(item)
        {
            var pictureUrl = item.url;
            var pictureUrlInfo = AppFramework.urlInfo(pictureUrl);
            var picturePath = pictureUrlInfo.localFile;
            var assetInfo = AppFramework.urlInfo(picturePath);
            sourceFileName = pictureUrlInfo.fileName
            var outputFileName;
            var suffix = AppFramework.fileInfo(picturePath).suffix;
            var fileName = AppFramework.fileInfo(picturePath).baseName+AppFramework.createUuidString(2);
            var a = suffix.match(/&ext=(.+)/);
            if (Array.isArray(a) && a.length > 1) {
                suffix = a[1];
            }

            if (assetInfo.scheme === "assets-library") {
                pictureUrl = assetInfo.url;
            }

            pasteImage(pictureUrl);
        }
    }

    function updateScreenShotsModel (updateCurrentIndex,action) {
        if(screenshotsCache){
            var allScreenShots = screenshotsCache.fileNames("%1*.jpg".arg(urlPrefix), false).toString().split(",")
            screenShots.clear()
            for (var i=0; i<allScreenShots.length; i++) {
                if (allScreenShots[i]) {
                    //calculate the size
                    var _screenshotfilePath = [screenshotsCache.url, allScreenShots[i]].join("/")
                    var _url = AppFramework.resolvedUrl(_screenshotfilePath)
                    var _screenshotfileInfo = AppFramework.fileInfo(_url)
                    var _filesize = _screenshotfileInfo.size
                    var _modifiedDate = _screenshotfileInfo.lastModified.toString()
                    if(_filesize < 1024)
                        _filesize = _filesize + " Bytes"
                    else
                        _filesize = mapViewerCore.getFileSize(_filesize)

                    var _modDate = new Date(_modifiedDate).toLocaleDateString(Qt.locale(), Qt.DefaultLocaleShortDate)

                    screenShots.append({"url": [screenshotsCache.url, allScreenShots[i]].join("/"), "modifiedDate":_modDate,"size":_filesize})

                }
            }
            if (updateCurrentIndex && screenShots.count) {
                if(!isSelectionMode)
                {
                    if(indexToHighlight >= 0)
                        listCurrentIndex = indexToHighlight
                    else
                    {
                        indexToHighlight = 0
                        listCurrentIndex = 0
                    }
                    loadImageInCanvas()
                }

            }

            if (!screenShots.count) {

                screenShotsView.close()
                toolbarrow.visible = true
            }
            isAnyScreenshotSelected = selectedScreenshots && Object.values(selectedScreenshots).some(x => (x !== null && x !== ''))
        }
    }

    function takeScreenShot () {
        if(!screenshotsCache)
        {
            var screenshotsBasePath = app.screenshotsCache.storagePath + portalItem.id + "/"
            app.screenShotsCacheFolder = AppFramework.fileInfo(screenshotsBasePath).folder
            app.screenShotsCacheFolder.makeFolder()

        }

        var date = (new Date().getTime()).toString()
        var fileUrl = [screenshotsCache.url, urlFormat.arg(date)].join("/")

        //var fileUrl = [screenshotsCache.fileFolder.url, urlFormat.arg(date)].join("/")
        mapView.exportImage(fileUrl)
        screenShotTaken()
    }

    function pasteImage(image) {
        imageUrl = image;
        var selectedImageFilePath = imageUrl.replace("file:///","/");
        var fileInfo = AppFramework.fileInfo(selectedImageFilePath);
        if (!pasteImageObject.load(fileInfo.url)) {
            console.error("Failed to load:", image);
            return;
        }

        resizeImageObject(pasteImageObject);

        canvas.requestPaint();
    }

    function load(path) {
        imageUrl = AppFramework.resolvedPathUrl(path);
        if (useImageObject) {
            if (currentImageObject.load(imageUrl)) {
                loaded = false;
            }

            canvas.requestPaint();
            return;
        }
        //console.log("Loading canvas image:", imageUrl, canvas.isImageLoaded(imageUrl));
        if (canvas.isImageLoaded(imageUrl)) {
            //console.log("Unloading:", imageUrl);
            canvas.unloadImage(imageUrl);
        }

        canvas.loadImage(imageUrl);

        return canvas.isImageLoaded(imageUrl);
    }

    //--------------------------------------------------------------------------

    function loadUrl(url) {
        //console.log("Loading canvas url:", url, canvas.isImageLoaded(url));
        if (canvas.isImageLoaded(imageUrl)) {
            canvas.unloadImage(imageUrl);
        }
        imageUrl = url;
        canvas.loadImage(imageUrl);
    }

    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------

    function resizeImageObject(imageObject) {
        //console.log("Resize:", imageObject.width, "x", imageObject.height, "=>", canvas.width, canvas.height);

        var canvasRatio = (canvas.width) / canvas.height;
        var imageRatio = imageObject.width / imageObject.height;

        //console.log("canvasRatio:", canvasRatio, "imageRatio:", imageRatio);
        if (imageRatio < canvasRatio) {
            imageObject.scaleToHeight(canvas.height, ImageObject.TransformationModeSmooth);
        } else {
            imageObject.scaleToWidth(canvas.width, ImageObject.TransformationModeSmooth);
            imageObject.scaleToHeight((canvas.height), ImageObject.TransformationModeSmooth);
        }

        imageObject.offsetX = (canvas.width - imageObject.width / scaleFactor) / 2;
        imageObject.offsetY = (canvas.height - imageObject.height / scaleFactor) / 2;

        //console.log("Image resized:", imageObject.width, "x", imageObject.height, "offset:", imageObject.offsetX, imageObject.offsetY);
    }

    //--------------------------------------------------------------------------
    Dialog {
        id: saveDialog
        property string furtherAction: ""
        property var selectedIndex:-1

        width: Math.min(0.8 * parent.width, 400*AppFramework.displayScaleFactor)
        x: (parent.width - width)/2
        y: (parent.height - height)/2
        visible: false
        modal: true
        Material.background: "white"//"#424242"
        Material.elevation: 8
        Material.accent: app.accentColor
        Material.foreground: baseTextColor
        closePolicy: Popup.NoAutoClose
        clip: true

        standardButtons: Dialog.No | Dialog.Yes

        Label {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            text: saveString
            wrapMode: Label.Wrap
            padding: 0
            topPadding: defaultMargin/2
            maximumLineCount: 3
            elide: Label.ElideRight
            color: baseTextColor//"white"
        }

        onAccepted: {
            rasterize(furtherAction,selectedIndex);

        }
        onRejected: {
            if((measurePanel.state !== 'MEASURE_MODE') && mapPageHeader.y < 0 && furtherAction === "close")
                mapPageHeader.y = mapPageHeader.y + app.headerHeight
            doNext(furtherAction,selectedIndex)
        }
    }
    function rasterize(furtherAction,selectedIndex) {

        if(!screenshotsCache)
        {
            var screenshotsBasePath = app.screenshotsCache.storagePath + portalItem.id + "/"
            app.screenShotsCacheFolder = AppFramework.fileInfo(screenshotsBasePath).folder
        }
        var filePath = screenshotsCache.filePath(AppFramework.urlInfo(imageUrl).localFile);
        var fileName = AppFramework.fileInfo(filePath).fileName;
        var savePath = screenshotsCache.filePath(fileName);
        //console.log("Rasterizing canvas:", filePath);
        if (!save(savePath)) {
            //console.error("Error saving canvas to:", filePath);
            doNext(furtherAction,selectedIndex)

        } else {
            doNext(furtherAction,selectedIndex)

        }

    }

    function doNext(furtherAction,selectedIndex=0)
    {
        switch(furtherAction){
        case "close":
            canvas.sketches = []
            canvas.undoList = []
            canvas.clear()
            canvas.canUndo = false
            canvas.canRedo = false
            screenShotsView.close()
            toolbarrow.visible = true
            break
        case "next":
            app.focus = true
            listCurrentIndex += 1
            canvas.sketches = []
            canvas.undoList = []
            canvas.clear()
            canvas.canUndo = false
            canvas.canRedo = false
            flickable.contentY= listCurrentIndex > 3? (listCurrentIndex - 2) * listPanel.width/1.6 + listPanel.width:0


            break
        case "prev":
            app.focus = true
            listCurrentIndex -= 1
            canvas.sketches = []
            canvas.undoList = []
            canvas.clear()
            canvas.canUndo = false
            canvas.canRedo = false
            flickable.contentY= listCurrentIndex > 3? (listCurrentIndex - 2) * listPanel.width/1.6:0

            break
        case "select":
            app.focus = true
            if(selectedIndex > -1)
                listCurrentIndex = selectedIndex
            else
                listCurrentIndex = 0
            canvas.sketches = []
            canvas.undoList = []
            canvas.clear()
            canvas.canUndo = false
            canvas.canRedo = false

            break
        case "turnSelectMode":
            app.focus = true
            canvas.sketches = []
            canvas.undoList = []
            canvas.clear()
            canvas.canUndo = false
            canvas.canRedo = false
            isSelectionMode = true
            selectedScreenshots = ({})
            if(listCurrentIndex)
                selectedScreenshots[listCurrentIndex] = 1
            break
        case "back":
            showGridView = true
            app.focus = true
            canvas.sketches = []
            canvas.undoList = []
            canvas.clear()
            canvas.canUndo = false
            canvas.canRedo = false
        }
    }

    function undo()
    {
        if (canvas.sketches.length > 0) {
            canvas.undoList.push(canvas.sketches.pop())
            canvas.canRedo = true
            canvas.requestPaint();
        }
        if (canvas.sketches.length === 0)
            canvas.canUndo = false
    }

    function redo()
    {
        if (canvas.undoList.length > 0) {
            canvas.sketches.push(canvas.undoList.pop())
            canvas.requestPaint();
        }
        if (canvas.undoList.length === 0)
            canvas.canRedo = false
        if(canvas.sketches.length > 0)
            canvas.canUndo = true

    }

    function clear() {

        while(canvas.sketches.length > 0)
            deleteLastSketch()
        canvas.clear()
        canvas.undoList = []
        canvas.sketches = []

    }
    function deleteLastSketch() {
        if (canvas.sketches.length > 0) {
            canvas.sketches.pop();
            canvas.requestPaint();
        }
    }

    function deleteTempFiles()
    {
        tempImageList.forEach(tempfile => {
                                  screenshotsCache.removeFile(tempfile)
                              })
    }

    function save(path) {
        var result = canvas.save(path);
        updateScreenShotsModel(false)

        return result;
    }

}
