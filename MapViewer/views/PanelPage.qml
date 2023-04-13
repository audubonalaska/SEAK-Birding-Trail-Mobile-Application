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
import QtQuick.Layouts 1.1
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0

import Esri.ArcGISRuntime 100.14

import "../controls" as Controls

import "../../Components/Legend"
import "../../Components/Identify/Layout"

import "../../Components/MapArea"
import "../../Components/Editor"
import "../../Components/Editor/Layout"


Controls.Panel {
    id: panelPage

    property MapView mapView:null
    property string mapTitle:""
    property string mapWelcomeText: ""
    property string owner:""
    property string modifiedDate:""

    property var headerTabNames: []
    //property real headerRowHeight: 0.8 * app.headerHeight + ( panelPage.fullView ? app.notchHeight : 0 )
    property real headerRowHeight: 0.8 * app.headerHeight //+ ( pageView.state === "anchortop" ? app.notchHeight : 0 )
    property real preferredContentHeight:(panelPage.fullView ? (panelPage.isLargeScreen ? panelContent.parent.height - 55 * scaleFactor : parent.height - panelHeaderHeight) : parent.height - panelPage.pageExtent - panelHeaderHeight)
    property real tabButtonHeight: headerRowHeight
    property bool willDockToBottom:false
    property bool screenWidth:app.isLandscape
    property alias tabBar:tabBar
    //property alias relatedDetails:relateddetails
    //property bool isFooterVisibleInRelated:!relateddetails.visible
    property alias panelContent:panelContent
    property bool isFull:false
    property color customColor: app.primaryColor
    // property bool populateModelCompleted:false
    property var featureEditorTrackingInfo:identifyManager.featureEditorTrackingInfo
    property string layerName:""
    property string popupTitle:""
    property bool canShowFooter:true
    property bool isEditable:false
    property string action:""
    property int selectedIndex:0
    property bool attachmentsUpdated:false

    property string symbolUrl//:identifyManager.featureSymbol
    property string measurement


    //property bool isInEditMode:false


    // signal hidepanelPage()
    signal dockToBottom()
    signal dockToLeft()
    signal dockToTop()
    signal dockToTopReduced()
    signal editField(var editObject)
    signal clearXYOnPolyline()


    signal changeLayerVisibility(var identificationIndex,var checked)
    signal zoomToLayer (string lyrname,string identificationIndex)
    //signal updateCheckboxInSortedTreeContentListModel(string identificationIndex,bool checked, string name)
    signal attachmentsDeleted()
    signal attributesSaved(var feature)
    signal relatedAttributesSaved(var layerName,var objectid,var editedFeature)
    signal attachmentAdded(var fileSize)
    signal drawNewSketch(var geometryType,var layerName,var layerId,var subtype)
    signal saveNewFeature()
    signal showFeatureAttributeForm()
    signal showRelatedDetails(var relatedDetailsObject)




    signal expandButtonClicked ()
    signal previousButtonClicked ()
    signal nextButtonClicked ()

    signal backButtonPressed ()
    signal hidePanelPage()
    signal editCurrentFeature(var pageNumber)
    signal changePageNumber(var newPageNumber)
    signal showEditorTrackingInfo(var pageNumber)
    signal populateModelAfterEdit()
    signal showEditorOptionsPopup(var pageNumber)
    signal editAttribute()
    signal editGeometry()
    signal exitShapeEditMode(var action)
    signal sketchComplete()
    signal deleteCurrentFeature()

    signal back()




    separatorColor: app.separatorColor
    panelHeaderHeight: headerRowHeight
    defaultMargin: app.defaultMargin
    appHeaderHeight: app.headerHeight
    headerBackgroundColor: app.backgroundColor
    backgroundColor: "#FFFFFF"
    isLargeScreen: app.isLarge
    isIntermediateScreen:false
    iconSize: app.iconSize
    property string headerText:""
    property int currentIndex:0

    LayoutMirroring.enabled: app.isRightToLeft
    LayoutMirroring.childrenInherit: app.isRightToLeft

    Connections{
        target:attributeEditorManager
        function onAttributesSaved()
        {
            if(app.isInEditMode)
            {
                back()
            }
        }
    }

    Connections{
        target:identifyManager
        function onFeatureChanged(){
            symbolUrl = identifyManager.featureSymbol
            popupTitle = identifyManager.popupTitle
            isEditable = identifyManager.isEditable
            if(_headerLoader.item)
            {
                _headerLoader.item.popupTitle = popupTitle
                if(typeof _headerLoader.item.symbolUrl !== "undefined")
                    _headerLoader.item.symbolUrl = symbolUrl
            }
        }
    }



    onShowRelatedDetails:{
        _relatedDetailsPage.relatedDetailsObj = relatedDetailsObject
        _relatedDetailsPage.open()

    }

    onBack: {
        if(isInShapeCreateMode)
        {
            panelDockItem.dockToEditMode()
            showSketchFooter()

        }
        else if(isInEditMode)
        {
            exitEditModeInProgress = true
            let pageNumber = identifyBtn.currentlyEditedPageNumber
            currentPageNumber = pageNumber
            identifyBtn.currentPageNumber = currentPageNumber
            //currentPageNumber = identifyBtn.currentPageNumber

            isInEditMode = false
            identifyBtn.currentEditTabIndex = 0
            tabBar.currentIndex = 0

            if(app.isExpandButtonClicked)
            {
                panelContent.state = "FULL_VIEW"
                intermediateView = true
            }

            exitEditModeInProgress = true
            identifyManager.checkIfAttachmentPresent(0)
            //identifyBtn.populateTabHeaders(isInEditMode)
            // populateModelAfterEdit()
        }
        else
        {
            collapseFullView()
            app.isExpandButtonClicked = false
        }
    }



    onClearXYOnPolyline: {
        mapView.elevationPtGraphicsOverlay.graphics.clear()

    }

    onShowEditorTrackingInfo: {

        // editorTrackingInfo = identifyManager.featureEditorTrackingInfo//featureEditorTrackingInfo
        //featureEditorInfoPopup.open()

    }
    onShowEditorOptionsPopup:{
        editorOptionsPopup.open()
    }
    onEditAttribute:{
        isInEditMode = true
        // root.currentPageNumber = currentPageNumber
        identifyBtn.currentlyEditedPageNumber = currentPageNumber
        mapView.identifyProperties.isModelBindingInProgress = true
        editCurrentFeature(currentPageNumber)

    }

    onEditGeometry:{
        //footer = sketchFeaturesFooterView
        showSketchFooter()


    }
    onDrawNewSketch: {
        showSketchFooter()



    }

    onShowFeatureAttributeForm:{
        let currentlyrId = sketchEditorManager.currentLayerId
        let lyr = layerManager.getLayerById(currentlyrId )
        let _featureTable = lyr.featureTable
        let _hasAttachments = false
        if(_featureTable)
            _hasAttachments = _featureTable.hasAttachments
        mapPage.showFeatureAttributeForm(_hasAttachments)
        panelPage.title = strings.kCreateNewFeature
        showCreateNewFeatureFooter()
        panelPage.showCreateNewFeatureHeader()

    }

    onExitShapeEditMode: {

    }

    onSketchComplete: {
        if(sketchEditorManager.isSketchValid)
        {

            if(isInShapeEditMode && !isInShapeCreateMode)
            {
                sketchEditorManager.resetDefinitionQueryAndSaveEdits()
                // footer = identifyFeaturesFooterView
            }
            else if(isInShapeCreateMode)
            {
                isInShapeEditMode = false
                showCreateNewFeatureFooter()

            }

            exitShapeEditMode("save")

        }
    }

    onDeleteCurrentFeature: {
        identifyManager.deleteCurrentFeature()

    }


    onEditField: {

        for(let k=0;k<attrListModel.count;k++)
        {
            let obj = attrListModel.get(k)
            if(obj.label === editObject.label)
                attrListModel.setProperty(k,"fieldvalue",editObject.fieldValue)

        }
    }
    onEditCurrentFeature: {

        app.isInEditMode = true
        identifyBtn.currentPageNumber = pageNumber
        identifyBtn.currentEditTabName = typeof headerTabNames[swipeView.currentIndex] === "object" ? headerTabNames[swipeView.currentIndex].name : headerTabNames[swipeView.currentIndex]
        let feature1 = identifyManager.features[identifyBtn.currentlyEditedPageNumber - 1]
        //let feature1 = mapView.identifyProperties.features[currentPageNumber-1]
        let _caneditAttachments = feature1.canEditAttachments
        let hasAttachments = feature1.featureTable.hasAttachments
        let canupdateAttachment = hasAttachments && _caneditAttachments
        contingencyValues.prepareContingentValueList(feature1.featureTable)

        identifyBtn.populateTabHeaders(isInEditMode,canupdateAttachment)
    }

    onAttributesSaved: {

        var feature1 = identifyManager.features[identifyBtn.currentPageNumber - 1]

        var popupManager = identifyManager.popupManagers[mapView.identifyProperties.currentFeatureIndex]//[currentPageNumber-1]

        featuresManager.populateModelForEditAttributes(feature1,attrListModel,popupManager)
        exitEditModeInProgress = false
        editAttributePage.close()
        back()

    }



    onPopulateModelAfterEdit: {

        mapView.identifyProperties.prepareAfterEditFeature()
    }

    onExpandButtonClicked: {

        dockToTop()
    }

    onHidePanelPage: {
        pageView.hidePanelItem()
        pageView.hideSearchItem()
        moreIcon.checked = false
        newFeatureEditBtn.checked  = false
        //isInRouteMode = false
        isInEditMode = false
    }

    onScreenWidthChanged: {
        if ( !app.isLandscape ){
            if ( app.isInEditMode ){
                willDockToBottom = false
                dockToTop()
                panelContent.state = "SMALL"
            } else {
                if(!mapPage.isInShapeCreateMode && !isInShapeEditMode)
                {
                    willDockToBottom = true
                    dockToBottom()
                    panelContent.state = "SMALL"
                }
            }
        } else {
            if(!mapPage.isInShapeCreateMode && !app.isInEditMode && !isInShapeEditMode)
            {
                willDockToBottom = false
                dockToLeft()
            }
            else
            {
                if(app.isInEditMode)
                {
                    willDockToBottom = false
                    dockToLeft()

                }
            }
        }
    }

    function expandFullView()
    {
        pageView.state = "anchortop"
    }

    function showCreateNewFeatureHeader()
    {
        _headerLoader.height = app.headerHeight
        _headerLoader.source =  "../../Components/Editor/Layout/CreateNewFeatureHeaderView.qml"
        isHeaderVisible = true
        _headerLoader.item.popupTitle = title
        _headerLoader.item.backButtonClicked.connect(back)
        _headerLoader.item.collapseFullView.connect(collapseFullView)
        _headerLoader.item.expandFullView.connect(expandFullView)

    }




    function showPanelHeader()
    {
        _headerLoader.height = app.headerHeight //+ (pageView.state === "anchortop" ?app.notchHeight:0)
        _headerLoader.source =  "../../MapViewer/controls/PanelHeader.qml"
        isHeaderVisible = true
        _headerLoader.item.popupTitle = title//identifyManager.popupTitle
        // _headerLoader.y = -app.notchHeight//pageView.state === "anchortop"?-app.notchHeight:0





        _headerLoader.item.closeButtonClicked.connect(hidePanelPage)
        _headerLoader.item.backButtonClicked.connect(back)
        _headerLoader.item.collapseFullView.connect(collapseFullView)
        _headerLoader.item.expandFullView.connect(expandFullView)

    }



    function showIdentifyPageHeader()
    {
        _headerLoader.height = 50
        _headerLoader.source =  "../../Components/Identify/Layout/IdentifyHeaderView.qml"
        isHeaderVisible = true
        _headerLoader.item.popupTitle = identifyManager.popupTitle
        _headerLoader.item.symbolUrl = identifyManager.featureSymbol

        _headerLoader.item.closeButtonClicked.connect(hidePanelPage)
        _headerLoader.item.backButtonClicked.connect(back)
        _headerLoader.item.collapseFullView.connect(collapseFullView)
        _headerLoader.item.expandFullView.connect(expandFullView)

    }





    function showSketchFooter()
    {
        _footerLoader.sourceComponent = sketchFeaturesFooterView
        isFooterVisible = true
        _footerLoader.item.showPopulateFeatureAttributeForm.disconnect(showFeatureAttributeForm)
        _footerLoader.item.showPopulateFeatureAttributeForm.connect(showFeatureAttributeForm)
    }

    function showCreateNewFeatureFooter()
    {

        //_footerLoader.height = app.units(88)
        _footerLoader.source =  "../../Components/Editor/Layout/NewFeatureFooterView.qml"
        _footerLoader.item.hidePanelPage.connect(hidePanelPage)

        isFooterVisible = true
    }



    function showIdentifyPageFooter()
    {

        identifyManager.checkEditPermission()
        let isEditable = supportEditing  && app.isWebMap //&& !isInEditMode

        if(isEditable || identifyManager.popupManagers.length > 1){

            _footerLoader.source =  "../../Components/Identify/Layout/IdentifyFeaturesFooterView.qml"
            _footerLoader.item.showPageCount = identifyManager.popupManagers.length > 1? true:false
            _footerLoader.item.pageCount = identifyManager.popupManagers.length
            _footerLoader.item.currentPageNumber = identifyBtn.currentPageNumber
            _footerLoader.item.changePageNumber.connect(changePageNumber)
            _footerLoader.item.editCurrentFeature.connect(editCurrentFeature)
            _footerLoader.item.editGeometry.connect(editGeometry)
            _footerLoader.item.deleteCurrentFeature.connect(deleteCurrentFeature)
            _footerLoader.item.backButtonClicked.disconnect(back)
            _footerLoader.item.backButtonClicked.connect(back)
            isFooterVisible = true
        }


    }




    content: Item{
        width:parent.width


        ColumnLayout {
            id: panelContent

            height:parent.height
            width:parent.width
            //anchors.fill:parent
            spacing: 0

            TabBar {
                id: tabBar
                Layout.topMargin: pageView.state === "anchortop" ?-app.notchHeight:0
                Layout.fillWidth: true
                clip: true

                visible: true//tabView.model.length > 1
                Layout.preferredHeight: tabView.model.length > 1 ?tabButtonHeight :0

                padding: 0

                Material.primary: app.primaryColor
                currentIndex: swipeView.currentIndex
                position: TabBar.Header
                Material.accent: app.primaryColor
                Material.background: headerBackgroundColor

                property alias tabView: tabView
                Repeater {
                    id: tabView

                    model: panelPage.headerTabNames
                    anchors.horizontalCenter: parent.horizontalCenter

                    TabButton {
                        id: tabButton


                        contentItem:

                            Item{
                            width:parent.width
                            height:parent.height

                            Controls.BaseText {

                                text: modelData.name? modelData.name:modelData
                                color: tabButton.checked ? app.primaryColor : app.subTitleTextColor
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                height:tabView.model.length > 1 ?tabButtonHeight :0//tabButtonHeight
                                visible:!tabiconBtn.visible
                                anchors.centerIn: parent
                                //width:tabBar.width/tabView.model.length
                            }
                            Controls.Icon {
                                id: tabiconBtn
                                visible: modelData.iconUrl? true : false
                                imageSource: modelData.iconUrl ? modelData.iconUrl :""//"../controls/images/back.png"
                                anchors.centerIn: parent
                                Material.background: app.backgroundColor
                                Material.elevation: 0
                                maskColor: tabButton.checked ? app.primaryColor :"#777777"//app.baseTextColor//"#4c4c4c"

                            }
                            MouseArea{
                                anchors.fill:parent
                                onClicked:tabButton.checked = true

                            }

                        }

                        clip: true
                        padding: 0
                        background.height: tabView.model.length > 1 ?tabButtonHeight :0
                        height: tabView.model.length > 1 ?tabButtonHeight :0

                        width: Math.max(100,(panelContent.width)/tabView.model.length)


                    }
                }
            }


            Rectangle{
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: pageView.state === "anchortop" && tabView.model.length === 1?-app.notchHeight:0

                SwipeView {
                    id: swipeView

                    property QtObject currentView

                    clip: true
                    anchors.fill:parent
                    bottomPadding: !panelPage.fullView ? app.heightOffset : 0
                    Material.background:"#FFFFFF"
                    currentIndex: tabBar.currentIndex
                    interactive: false

                    Repeater {
                        id: swipeViewDelegate

                        model: tabBar.tabView.model.length
                        Loader {
                            active: SwipeView.isCurrentItem || SwipeView.isNextItem || SwipeView.isPreviousItem
                            visible: SwipeView.isCurrentItem
                            sourceComponent: swipeView.currentView
                        }
                    }

                    onCurrentIndexChanged: {
                        if(swipeView.currentIndex > -1){
                            // if(isInShapeCreateMode)
                            addDataToSwipeView (swipeView.currentIndex)
                            populateHeaderFooterOfSwipeView(swipeView.currentIndex)
                        }
                    }

                    Component.onCompleted: {
                        //addDataToSwipeView (swipeView.currentIndex)

                        //  populateFooterOfSwipeView(swipeView.currentIndex)
                    }

                    function updatePageNumber()
                    {
                        let currentPageNumber =  _footerLoader.item.currentPageNumber
                        changePageNumber(currentPageNumber)
                    }



                    function populateHeaderFooterOfSwipeView(index)
                    {
                        index = tabBar.currentIndex
                        if (panelPage.headerTabNames.length <= 0) return
                        let tabObject = panelPage.headerTabNames[index]
                        if(tabObject){
                            let tabName = tabObject.name ? tabObject.name : tabObject
                            switch (tabName) {
                            case app.tabNames.kFeatures:
                            case app.tabNames.kAttachments:
                                // case app.tabNames.kRelatedRecords:
                            case app.tabNames.kMedia:
                                if(!isInShapeCreateMode)
                                {
                                    //if(!isInEditMode)
                                    panelPage.showIdentifyPageFooter()

                                    showIdentifyPageHeader()
                                }

                                break


                            case app.tabNames.kCreateNewFeature:
                                // _footer = newFeatureFooterView
                                break
                            case app.tabNames.kRelatedRecords:
                                if(app.isInEditMode)
                                {
                                    if(identifyManager.relatedFeaturesModel.count === 1 && identifyManager.relatedFeaturesModel.get(0).features.count === 1)
                                        panelPage.showIdentifyPageFooter()
                                    else
                                        _footerLoader.source = ""
                                }
                                break

                            default:
                                break

                            }
                        }

                        // isFooterVisible = !isInEditMode && canShowFooter  && (canShowEditBtn || (showPageCount && pageCount > 1) || mapPage.isInShapeEditMode) //|| (featureEditorTrackingInfo !== null && featureEditorTrackingInfo !== undefined)) //&& !identifyRelatedFeaturesViewlst.visible

                    }

                    function addDataToSwipeView (index) {
                        // if(isInShapeCreateMode)
                        //    index = 0
                        // else
                        index = tabBar.currentIndex
                        //isExpandIconVisible = true
                        //isMoreMenuVisible = false


                        if (panelPage.headerTabNames.length <= 0) return

                        let tabObject = panelPage.headerTabNames[index]
                        if(tabObject){
                            let tabName = tabObject.name ? tabObject.name : tabObject

                            switch (tabName) {
                            case app.tabNames.kCreateNewFeature:
                                // swipeView.currentView =  createNewFeatureView

                                swipeView.currentView = createNewFeatureView
                                break
                            case app.tabNames.kMapAreas:
                                identifyProperties.clearHighlightInLayer()
                                swipeView.currentView = mapAreasView
                                break
                            case app.tabNames.kLegend:
                                identifyProperties.clearHighlightInLayer()
                                mapView.populateVisibleLayers()
                                legendManager.initializeLegend()
                                swipeView.currentView = legendView
                                //canShowFooter = false
                                //legendManager.sortLegendContentByLyrIndex()
                                //swipeView.currentView = legendView
                                break
                            case app.tabNames.kContent:
                                identifyProperties.clearHighlightInLayer()
                                mapView.populateVisibleLayers()

                                legendManager.initializetreeControl()

                                swipeView.currentView = contentView
                                break
                            case app.tabNames.kInfo:
                                mapView.updateMapInfo()
                                if(app.appTitle > "")
                                    panelPage.mapTitle = app.appTitle
                                swipeView.currentView = infoView
                                canShowFooter = false
                                break
                            case app.tabNames.kAbout:
                                identifyProperties.clearHighlightInLayer()
                                mapView.updateMapInfo()
                                swipeView.currentView = infoView
                                break
                            case app.tabNames.kBookmarks:
                                identifyProperties.clearHighlightInLayer()
                                swipeView.currentView = bookmarksView
                                break
                            case app.tabNames.kBasemaps:
                                identifyProperties.clearHighlightInLayer()
                                swipeView.currentView = basemapsView

                                break
                            case app.tabNames.kMapUnits:
                                swipeView.currentView = mapunitsView
                                break
                            case app.tabNames.kGraticules:
                                identifyProperties.clearHighlightInLayer()
                                swipeView.currentView = graticulesView
                                break
                            case app.tabNames.kFeatures:
                                featureEditorTrackingInfo = null
                                attributeEditorManager.editedFieldValues = []

                                //identifyManager.setCurrentPageNumberAndIndex(identifyBtn.currentPageNumber,mapView.identifyProperties.currentFeatureIndex)
                                //console.log("called from panelpage adddatatoswipeview")

                                if(app.isInEditMode && !isInShapeCreateMode)
                                {

                                    identifyManager.populateFeaturesModel(identifyBtn.currentPageNumber,mapView.identifyProperties.currentFeatureIndex)
                                }
                                else if(isInShapeCreateMode)
                                {

                                    identifyManager.populateModelForNewFeature(sketchEditorManager.currentLayerId)
                                    // populateFooterOfSwipeView(swipeView.currentIndex)
                                }
                                else
                                    identifyManager.populateFeaturesModel(identifyBtn.currentPageNumber,mapView.identifyProperties.currentFeatureIndex)

                                mapView.identifyProperties.isModelBindingInProgress = false
                                isEditable = identifyManager.isEditable
                                editorTrackingInfo = identifyManager.featureEditorTrackingInfo

                                symbolUrl = identifyManager.featureSymbol
                                measurement = identifyManager.measurement
                                swipeView.currentView = identifyFeaturesView
                                // canShowFooter = true
                                break
                            case app.tabNames.kAttachments:
                                swipeView.currentView = identifyAttachmentsView
                                break
                            case app.tabNames.kRelatedRecords:
                                //featureEditorTrackingInfo = null
                                panelPage.editorTrackingInfo = null
                                attributeEditorManager.editedFieldValues = []
                                identifyManager.populateRelatedFeaturesModel(identifyBtn.currentPageNumber,identifyBtn.currentlyEditedPageNumber)
                                mapView.identifyProperties.isModelBindingInProgress = false
                                if(app.isInEditMode)
                                    isFooterVisible = false
                                else
                                    isFooterVisible = true

                                swipeView.currentView = identifyRelatedFeaturesView
                                //canShowFooter = true
                                break
                            case app.tabNames.kMedia:
                                swipeView.currentView = identifyMediaView
                                break
                            case app.tabNames.kOfflineMaps:
                                identifyProperties.clearHighlightInLayer()
                                swipeView.currentView = offlineMapsView
                                break
                            case app.tabNames.kElevationProfile:
                                mapView.currentFeatureIndexForElevation = mapView.identifyProperties.currentFeatureIndex//currentPageNumber-1
                                swipeView.currentView = profileView
                                canShowFooter = false
                                break



                            default:
                                let _view = mapPage.getCurrentView(panelPage.headerTabNames[index])
                                //isExpandIconVisible = false
                                //isMoreMenuVisible = true
                                swipeView.currentView = _view

                            }
                        }
                    }
                }
            }

            Rectangle{
                id:bottomRect
                Layout.fillWidth: true
                Layout.preferredHeight:app.units(5)
            }

        }
    }






    function hideFullView()
    {
        panelPage.collapseFullView()
    }

    //--------------------------------------------------------------------------
    /* function hideDetailsView()
    {
        relateddetails.visible=false
        panelContent.visible = true
    }*/

    function showFeaturesView()
    {

        //panelContent.visible = true
        panelPage.isHeaderVisible = true
        _footerLoader.source = ""
        if(_relatedDetailsPage.opened)
            _relatedDetailsPage.close()
        popupTitle = identifyManager.popupTitle
        measurement = identifyManager.measurement
        layerName = identifyManager.layerName
        action = identifyManager.action

        identifyBtn.currentEditTabIndex = panelPage.headerTabNames.indexOf(identifyBtn.currentEditTabName)

        if(identifyBtn.currentEditTabIndex > 0)
        {
            tabBar.currentIndex = identifyBtn.currentEditTabIndex
        }
        else
        {           
            tabBar.currentIndex = 0
        }
    }


    function showCreateNewFeature()
    {
        panelContent.visible = true
        panelPage.isHeaderVisible = true
        swipeView.addDataToSwipeView(0)
        tabBar.currentIndex = 0

    }

    function showMapAreas()
    {
        relateddetails.visible=false
        panelContent.visible = true
        panelPage.isHeaderVisible = true
        swipeView.addDataToSwipeView(0)
        tabBar.currentIndex = 0
    }

    onCurrentIndexChanged: {
        swipeView.currentIndex = 0
    }

    onVisibleChanged: {
        if (!visible) {
            app.focus = true
        }
    }

    onNextButtonClicked: {

    }

    onPreviousButtonClicked: {

    }

    Component {
        id: defaultListModel

        ListModel {
        }
    }

    //--------------------------------------------------------------------------

    onChangePageNumber: {
        if (visible) {

            mapView.identifyProperties.highlightFeature(newPageNumber-1,true)
            mapView.identifyProperties.currentFeatureIndex = newPageNumber-1
            //console.log("calling refreshmodel")
            mapView.identifyProperties.refreshModel(newPageNumber)            

        }
    }


    onCurrentPageNumberChanged: {
        if (visible) {
            //mapView.identifyProperties.highlightFeature(currentPageNumber-1,false)

            mapView.identifyProperties.currentFeatureIndex = currentPageNumber - 1
        }
    }

    Connections {
        target: mapView ? mapView.identifyProperties:null


    }


    property alias _relatedDetailsPage: relatedDetailsPage
    RelatedDetailsPopupPage {
        id: relatedDetailsPage
        Connections{
            target:editAttributePage

            function onFieldUpdated(editObject){
                //console.log("panel page....")
                //update the domains if the featureType changes
                //get the CurrentFeature
                let relatedObjectModel = relatedDetailsPage.relatedDetailsObj ? relatedDetailsPage.relatedDetailsObj.model:null

                let currentlyEditedFeature = editObject.feature
                if(currentlyEditedFeature)
                {
                    let featureTable  = currentlyEditedFeature.featureTable
                    let featureTypeField = featureTable.typeIdField

                    var newEditObject = Object.assign({},editObject)
                    //let relatedObjectModel = relatedDetailsObj.model
                    //editedData.clear()
                    if(relatedObjectModel)
                    {
                        for(let k=0;k< relatedObjectModel.count;k++)
                        {
                            //get the old value
                            let existingRecord = relatedObjectModel.get(k)

                            //get the new value from the edited feature
                            let newfldval = featuresManager.getFieldValueFromFeature(currentlyEditedFeature,existingRecord.FieldName)
                            if(existingRecord.FieldValue.toString() !== newfldval.toString())
                            {
                                //mapPage.hasEdits = true
                                //update the model
                                relatedObjectModel.setProperty(k,"FieldValue",newfldval)

                            }

                            //need to check if the user changes a featureType then we need to
                            //update the domain values of other fields which is depended on that
                            // let existingRecord = identifyManager.attrListModel.get(k)//obj
                            if(newEditObject.fieldName === featureTable.typeIdField && existingRecord.FieldName !== newEditObject.fieldName)
                            {


                                let {codedValues, nameValues,_fieldVal,_fieldVal_code} = featuresManager.updateFieldDomain(featureTable,newEditObject.fieldValue,existingRecord.FieldName)
                                //now get the Recommended values and update the domain based on contingent values
                                //get the fieldgroup

                                if(_fieldVal)
                                {
                                    existingRecord["FieldValue"] = _fieldVal.toString()

                                }


                                if(codedValues.length > 0)
                                {
                                    existingRecord["domainCode"] = codedValues
                                    existingRecord["domainName"] = nameValues
                                    existingRecord["unformattedValue"] = typeof _fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null"
                                    existingRecord["editedValue"] = typeof _fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null"


                                }
                            }
                            else if(existingRecord.fieldName === newEditObject.fieldName)
                            {
                                existingRecord["unformattedValue"] = newEditObject.fieldValue.toString()
                                existingRecord["editedValue"] = newEditObject.fieldValue.toString()
                                existingRecord["FieldValue"] = newEditObject.fieldValue.toString()
                            }

                            let fieldRecommendedValues = contingencyValues.getContingentValues(existingRecord.FieldName,currentlyEditedFeature,featureTypeField)
                            let featureTypeFieldValue = currentlyEditedFeature.attributes.attributeValue(featureTypeField)
                            let fielddomainnames = featuresManager.getFieldDomains(featureTable,featureTypeFieldValue,existingRecord.FieldName)//existingRecord["domainName"]
                            //need to get the domainnames for the field
                            if(fieldRecommendedValues.length > 0)
                            {
                                let combinedArray = featuresManager.concatenateDomainValues(fieldRecommendedValues,fielddomainnames)
                                existingRecord["domainName"] = combinedArray
                            }
                            else
                                existingRecord["domainName"] = fielddomainnames

                            // }

                            //check if it is invalid based on contingentvalues
                            let fieldValidType = featuresManager.getFieldValidType(currentlyEditedFeature,existingRecord.FieldName)

                            existingRecord["fieldValidType"] = fieldValidType


                        }
                    }

                    relatedDetailsPage.identifyRelatedFeaturesViewlst.forceLayout()
                }
            }

        }
    }



    Component {
        id: identifyFeaturesView

        IdentifyFeaturesView {
            id: featuresView
            model:identifyManager.attrListModel
            layerName:panelPage.layerName
            popupTitle:panelPage.popupTitle
            featureSymbolUrl: identifyManager.featureSymbol
            measurement : identifyManager.measurement



            Component.onCompleted: {
                //populateFeaturesModel()
                // console.log("model completed")
                //  featuresView.bindModel()
            }

            onHidePanelPage: {
                panelPage.hidePanelPage()
            }


            onHighlightFeature:{
                mapView.setViewpointCenter(feature.geometry.extent.center)
                //identifyProperties.showInMap(feature,false)
            }




            Connections {
                target: panelPage

                function onCurrentPageNumberChanged() {

                    if(identifyBtn.currentPageNumber !== currentPageNumber)
                    {
                        identifyBtn.currentPageNumber = currentPageNumber
                        identifyManager.populateFeaturesModel(identifyBtn.currentPageNumber,mapView.identifyProperties.currentFeatureIndex)
                        symbolUrl = identifyManager.featureSymbol
                        popupTitle = identifyManager.popupTitle
                        identifyManager.populateRelatedFeaturesModel(identifyBtn.currentPageNumber,identifyBtn.currentlyEditedPageNumber)
                    }
                }

            }

            Connections {
                target: mapView.identifyProperties

                function onPopupManagersCountChanged()  {
                    /*attrListModel.clear()
                     populateFeaturesModel()
                    featuresView.bindModel()*/
                }
                function onRefreshModel(pageNumber){
                    currentPageNumber = pageNumber
                    if(identifyBtn.currentPageNumber !== pageNumber || app.isInEditMode){
                        identifyBtn.currentPageNumber = pageNumber
                        //attrListModel.clear()
                        console.log("called from onRefreshModel pagenumber",identifyBtn.currentPageNumber)
                        identifyManager.populateFeaturesModel(identifyBtn.currentPageNumber,mapView.identifyProperties.currentFeatureIndex)
                        editorTrackingInfo = identifyManager.featureEditorTrackingInfo
                        symbolUrl = identifyManager.featureSymbol
                        measurement = identifyManager.measurement

                    }


                }


                // used to populate the identify view with updated data after saving
                function onPrepareAfterEditFeature(){
                    exitEditModeInProgress = true
                    if(!isLargeScreen && !app.isExpandButtonClicked)
                        pageView.state = "anchorbottom"
                    //identifyManager.attrListModel.clear()
                    //identifyBtn.checkIfAttachmentPresent(0)

                    mapView.identifyProperties.currentFeatureIndex = identifyBtn.currentlyEditedPageNumber - 1
                    console.log("called from PrepareAfterEditFeature")
                    identifyManager.populateFeaturesModel(identifyBtn.currentPageNumber,mapView.identifyProperties.currentFeatureIndex)
                    showIdentifyPageFooter()

                }


            }

            Connections{
                target:editAttributePage
                function onClosed(){
                    featuresView.currentIndex = selectedIndex
                }

                function onUpdateAttribute(){

                    featuresView.updateAttributeListModel(editObject)
                    featuresView.currentIndex = selectedIndex

                }
            }

        }


    }


    property alias editAttributePage: editAttributePage
    EditAttributePage {
        id: editAttributePage
    }

    function showErrorMessage(editresult) {

        app.messageDialog.width = messageDialog.units(300)
        app.messageDialog.standardButtons = Dialog.Ok//Dialog.Cancel | Dialog.Yes
        app.messageDialog.show("",("Error while Saving:%1").arg(editresult.error))
        exitEditModeInProgress = false
        //busyIndicator.visible = false

    }



    //--------------------------------------------------------------------------

    Component {
        id: identifyAttachmentsView

        IdentifyAttachmentsView {
            id: attachementsView



            Component.onCompleted: {
                if(isInShapeCreateMode)
                {
                    // attachementsView.model = defaultListModel
                    bindAttachmentsModelForNewFeature()
                    // canAddAttachment = true
                }
                else
                    attachementsView.bindModel()
            }

            Connections {
                target: mapView.identifyProperties

                function onPopupManagersCountChanged() {
                    attachementsView.bindModel()

                }

                function onRefreshModel(pageNumber){
                    currentPageNumber = pageNumber



                }
            }

            Connections {
                target: panelPage

                function onCurrentPageNumberChanged() {
                    identifyBtn.currentPageNumber = currentPageNumber
                    attachementsView.editAttachmentInProgress = true
                    identifyManager.populateFeaturesModel(identifyBtn.currentPageNumber,mapView.identifyProperties.currentFeatureIndex)

                    attachementsView.bindModel()
                    symbolUrl = identifyManager.featureSymbol
                    popupTitle = identifyManager.popupTitle
                    //attachementsView.busyIndicator.visible = true
                }
                function onAttachmentsDeleted(){
                    attachementsView.refreshAttachments()
                }
            }






            function bindAttachmentsModelForNewFeature()
            {
                attachementsView._model = defaultListModel
                attachementsView._model = Qt.binding(function () {
                    try {

                        let feature1 = sketchEditorManager.newFeatureObject["feature"]

                        if(feature1.canEditAttachments)
                            canAddAttachment = true
                        return feature1.attachments

                    } catch (err) {
                        attachementsView.layerName = ""
                        return defaultListModel
                    }
                })
            }




            function bindModel () {

                // attachementsView._model = defaultListModel
                attachementsView._model = Qt.binding(function () {
                    try {
                        if(identifyManager.features.length > 0)
                        {
                            let feature1 = identifyManager.features[currentPageNumber-1]
                            featureEditorTrackingInfo = null

                            if(identifyManager.isInEditMode)
                            {
                                if(!identifyBtn.currentPageNumber)
                                    identifyBtn.currentPageNumber = pageNumber
                                feature1 = identifyManager.features[identifyBtn.currentPageNumber-1]
                            }
                            if(feature1)
                            {
                                if(feature1.canEditAttachments)
                                    canAddAttachment = true
                                else
                                    canAddAttachment = false
                            }
                            var popupManager = identifyManager.popupManagers[currentPageNumber-1]
                            if(popupManager.objectName)
                                attachementsView.layerName = popupManager.objectName.toString()
                            if(popupManager.title)
                                attachementsView.popupTitle = popupManager.title

                            attachementsView.timeOut.start()

                            return feature1.attachments
                        }
                        else
                            return null

                    } catch (err) {
                        attachementsView.layerName = ""
                        return defaultListModel
                    }
                })
            }




        }
    }


    Controls.CustomListModel {
        id: relatedFeaturesModel
    }

    Component{
        id:identifyRelatedFeaturesView
        IdentifyRelatedFeaturesView {
            id:relatedFeaturesView
            width:panelPage.width
            height:panelPage.height
            featureList:identifyManager.relatedFeaturesModel

            onShowDetailsPage:{
                showRelatedDetails(relatedDetailsObject)
            }

            Component.onCompleted: {

            }


            Connections {
                target: mapView.identifyProperties

                function onPopupManagersCountChanged() {
                    identifyManager.populateRelatedFeaturesModel(identifyBtn.currentPageNumber,identifyBtn.currentlyEditedPageNumber)

                }
                function onCurrentFeatureIndexChanged(){
                    // identifyManager.populateRelatedFeaturesModel(identifyBtn.currentPageNumber,identifyBtn.currentlyEditedPageNumber)

                }
                function onRefreshModel(pageNumber){
                    currentPageNumber = pageNumber
                    if(identifyBtn.currentPageNumber !== pageNumber || app.isInEditMode){
                        identifyBtn.currentPageNumber = pageNumber
                        //attrListModel.clear()
                        console.log("called from onRefreshModel pagenumber",identifyBtn.currentPageNumber)
                        identifyManager.populateFeaturesModel(identifyBtn.currentPageNumber,mapView.identifyProperties.currentFeatureIndex)
                        editorTrackingInfo = identifyManager.featureEditorTrackingInfo
                        symbolUrl = identifyManager.featureSymbol
                        measurement = identifyManager.measurement

                    }


                }


            }


            Connections {
                target: panelPage

                function onCurrentPageNumberChanged() {
                    identifyBtn.currentPageNumber = currentPageNumber
                    identifyManager.populateRelatedFeaturesModel(identifyBtn.currentPageNumber,identifyBtn.currentlyEditedPageNumber)
                    identifyManager.populateFeaturesModel(identifyBtn.currentPageNumber,mapView.identifyProperties.currentFeatureIndex)
                    symbolUrl = identifyManager.featureSymbol
                    popupTitle = identifyManager.popupTitle

                }
            }

        }
    }




    Component {
        id: featureListModel
        ListModel {
        }
    }
    //--------------------------------------------------------------------------

    Component {
        id: identifyMediaView

        IdentifyMediaView {
            id: mediaView

            defaultContentHeight: parent ? panelPage.preferredContentHeight : 0
            Component.onCompleted: {
                mediaView.bindModel()
            }

            Connections {
                target: mapView.identifyProperties

                function onPopupManagersCountChanged() {
                    mediaView.bindModel()
                }

                function onRefreshModel(pageNumber){
                    currentPageNumber = pageNumber



                }
            }

            Connections {
                target: panelPage

                function onCurrentPageNumberChanged() {
                    mediaView.busyIndicator.visible = true
                    identifyBtn.currentPageNumber = currentPageNumber

                    identifyManager.populateFeaturesModel(identifyBtn.currentPageNumber,mapView.identifyProperties.currentFeatureIndex)

                    mediaView.bindModel()
                    symbolUrl = identifyManager.featureSymbol
                    popupTitle = identifyManager.popupTitle

                }
            }

            function bindModel () {
                mediaView.busyIndicator.visible = true
                media = Qt.binding(function () {
                    try {
                        //var identifyProperties = mapView.identifyProperties
                        if(identifyManager.popupManagers[identifyBtn.currentPageNumber-1].objectName)
                            layerName = identifyManager.popupManagers[identifyBtn.currentPageNumber-1].objectName.toString()
                        if(identifyManager.popupManagers[identifyBtn.currentPageNumber-1].title)
                            popupTitle = identifyManager.popupManagers[identifyBtn.currentPageNumber-1].title
                        attributes = identifyManager.features[identifyBtn.currentPageNumber-1].attributes.attributesJson
                        fields = identifyManager.fields[identifyBtn.currentPageNumber-1]
                        return identifyManager.popupDefinitions[identifyBtn.currentPageNumber-1].media
                    } catch (err) {
                        layerName = ""
                        return []
                    }
                })
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: bookmarksView

        BookmarksView {

            model: mapView.map.bookmarks
            onBookmarkSelected: {
                mapView.setViewpointWithAnimationCurve(mapView.map.bookmarks.get(index).viewpoint, 2.0, Enums.AnimationCurveEaseInOutCubic)
                //panelPage.collapseFullView()
            }
        }
    }

    Component{
        id:profileView
        ElevationProfileView{
            onPlotXYOnPolyline: {

                mapView.elevationPtGraphicsOverlay.graphics.clear()
                var simpleMarker = ArcGISRuntimeEnvironment.createObject("SimpleMarkerSymbol",
                                                                         {color: "red", size: app.units(12),outline:simpleLineSymbol1,
                                                                             style: Enums.SimpleMarkerSymbolStyleCircle})
                var graphic = ArcGISRuntimeEnvironment.createObject("Graphic",
                                                                    {symbol: simpleMarker, geometry: pointGeometry})

                graphic.zIndex = 9999
                graphic.selected = true
                mapView.elevationPtGraphicsOverlay.graphics.append(graphic)
                var isContained = GeometryEngine.contains(mapView.currentViewpointExtent.extent,mapView.elevationPtGraphicsOverlay.extent)
                if(!isContained)
                    mapView.setViewpointCenter(graphic.geometry)

            }

            onSetTitleWithUnits:{
                mapView.elevationUnits = units

            }
            Connections {
                target: mapView.identifyProperties

                function onRefreshModel(pageNumber){
                    currentPageNumber = pageNumber

                }
            }


            Connections {
                target: panelPage

                function onCurrentPageNumberChanged() {
                    identifyBtn.currentPageNumber = currentPageNumber
                    mapView.currentFeatureIndexForElevation = mapView.identifyProperties.currentFeatureIndex
                    symbolUrl = identifyManager.featureSymbol
                    popupTitle = identifyManager.popupTitle

                }

            }

        }

    }


    //--------------------------------------------------------------------------

    Component {
        id: offlineMapsView

        OfflineMapsView {

            model: mapView.offlineMaps
            onMapSelected: {
                mapView.mapInitialized = false
                mapView.mmpk.loadMmpkMapInMapView(index)
                mapView.updateMapInfo()
                //panelPage.collapseFullView()
            }
        }
    }


    //--------------------------------------------------------------------------

    Component {
        id: infoView

        InfoView {
            titleText: panelPage.mapTitle > ""? panelPage.mapTitle:mapView.mapInfo.title
            ownerText:panelPage.owner > ""? panelPage.owner : ""
            modifiedDateText: panelPage.modifiedDate > ""? panelPage.modifiedDate:""
            snippetText: utilityFunctions.getHtmlSupportedByRichText(mapView.mapInfo.snippet, panelPage.width, "")
            descriptionText: utilityFunctions.getHtmlSupportedByRichText(mapView.mapInfo.description, panelPage.width, "")
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: legendView

        LegendView {

            model: legendManager.orderedLegendInfos_legend


            Component.onCompleted: {
                //legendManager.updateLegendInfos()
            }

        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: createNewFeatureView

        CreateNewFeatureView {

            _model:mapPage.editableLayerList
            isFilterVisible: sketchEditorManager.noOflayerItems > 5

            onDrawNewSketch: {
                panelPage.drawNewSketch(geometryType,layerName,layerId,subtype)

            }
            onEditGeometry:{
                editGeometry()
            }
            onUpdateSketchLayersList:{
                let _text = searchTxt.toLowerCase()
                let filteredModel = []
                for(let k=0;k<mapPage.editableLayerList.length;k++)
                {
                    let _item1  = mapPage.editableLayerList[k]
                    let _item = Object.assign({},_item1)

                    //first check if that substring is presnt in the layernames
                    //if presnt in the layer names then we show all the subtypes under that layer
                    let lyrname = _item.name.toLowerCase()
                    if(_text > "")
                    {

                        if(lyrname.indexOf(_text) >= 0)
                            filteredModel.push(_item)
                        else
                        {
                            let _symbols = _item.symbols.filter(obj => (obj.name.toUpperCase()).indexOf(_text.toUpperCase()) >= 0)
                            if(_symbols.length > 0){

                                _item.symbols = _symbols
                                filteredModel.push(_item)
                            }
                        }
                    }
                    else
                        filteredModel.push(_item)


                }
                _model = filteredModel

            }



        }
    }


    Component {
        id: mapAreasView

        MapAreasView {

            model: mapAreaManager.mapAreasModel
            mapAreas: mapAreaManager.mapAreaslst
            /*onMapAreaSelected: {

            }*/



        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: contentView

        ContentView {

            _model: legendManager.contentTabModel//legendManager.sortedTreeContentListModel

            onZoomTo: {
                panelPage.zoomToLayer(lyrname,identificationIndex)
            }

            onChecked: {
                //update the hecked property of child layers

                changeLayerVisibility(identificationIndex,checked)

                app.focus = true
            }

        }
    }

    //--------------------------------------------------------------------------
    Component {
        id: basemapsView

        BasemapsView {

            property var listModel:app.basemapsGroupId > ""?app.baseMapsModel : app.portal.basemaps

            model: listModel
            onBasemapSelected: {
                var _item = listModel.get(index)
                if(app.basemapsGroupId > "")
                {
                    var newBaseMap = ArcGISRuntimeEnvironment.createObject("Basemap");
                    let basemapItemUrl = "%1/sharing/rest/content/items/%2/data".arg(portal.url).arg(_item.id);
                    newBaseMap.url = basemapItemUrl;
                    newBaseMap.load();
                    newBaseMap.loadStatusChanged.connect(() => {
                                                             if ( newBaseMap.loadStatus === Enums.LoadStatusLoaded ){
                                                                 mapView.map.basemap = newBaseMap
                                                             }
                                                         })

                }
                else
                {
                    mapView.map.basemap = _item

                }


            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapunitsView

        MapUnitsView {
            id: mapUnits

            model: mapView.mapunitsListModel
            onCurrentSelectionUpdated: {
                mapUnitsManager.updateMapUnitsModel()
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: graticulesView

        GraticulesView {
            id: graticules

            model: mapView.gridListModel
            onCurrentSelectionUpdated: {
                mapUnitsManager.updateGridModel()
            }
        }
    }

    Component{
        id:identifyFeaturesHeaderView
        IdentifyHeaderView{

        }
    }

    Component{
        id:panelHeaderView
        Controls.PanelHeader{

        }
    }


    Component{
        id:createNewFeatureHeaderView
        CreateNewFeatureHeaderView{

        }
    }

    Component{
        id:identifyFeaturesFooterView
        IdentifyFeaturesFooterView{

            onChangePageNumber:
            {

                panelPage.changePageNumber(currentPageNumber)
            }
        }
    }

    Component{
        id:sketchFeaturesFooterView
        SketchFooterView{
        }
    }

    Component{
        id:newFeatureFooterView
        NewFeatureFooterView{

        }
    }

}
