import QtQuick 2.15

import Esri.ArcGISRuntime 100.14

Item {
    id: floorFilterController

    required property GeoView geoView

    property GeoModel geoModel: {
        if (!geoView)
            return null;

        if (geoView instanceof MapView)
            return geoView.map;

        if (geoView instanceof SceneView)
            return geoView.scene;

        return null;
    }

    property FloorManager floorManager: geoModel ? geoModel.floorManager : null

    property int automaticSelectionMode: FloorFilterController.AutomaticSelectionMode.Always
    property int updateLevelsMode: FloorFilterController.UpdateLevelsMode.AllLevelsMatchingVerticalOrder

    property bool selectedSiteRespected: true

    readonly property alias selectedSiteId: internal.selectedSiteId
    readonly property alias selectedFacilityId: internal.selectedFacilityId
    readonly property alias selectedLevelId: internal.selectedLevelId
    readonly property alias selectedSite: internal.selectedSite
    readonly property alias selectedFacility: internal.selectedFacility
    readonly property alias selectedLevel: internal.selectedLevel

    readonly property ListModel sites: ListModel {}
    readonly property ListModel facilities: ListModel {}
    readonly property ListModel levels: ListModel {}

    readonly property double zoom_padding: 1.5

    property bool isLoaded: false

    signal doneViewpointChanged()
    signal loaded()

    //--------------------------------------------------------------------------

    QtObject {
        id: internal

        property string selectedSiteId: ""
        property string selectedFacilityId: ""
        property string selectedLevelId: ""

        property FloorSite selectedSite
        property FloorFacility selectedFacility
        property FloorLevel selectedLevel

        property bool singleSite: false
    }

    //--------------------------------------------------------------------------

    enum UpdateLevelsMode {
        AllLevelsMatchingVerticalOrder = 0
    }

    enum TypeElement {
        Level = 0,
        Facility = 1,
        Site = 2
    }

    enum AutomaticSelectionMode {
        Never = 0,
        Always = 1,
        AlwaysNonClearing = 2
    }

    //--------------------------------------------------------------------------

    Connections {
        id: geoViewConnections

        enabled: false

        target: geoView

        function onViewpointChanged() {
            tryUpdateSelection();
        }
    }

    Connections {
        target: floorManager

        function onLoadStatusChanged() {
            if (floorManager.loadStatus !== Enums.LoadStatusLoaded)
                return;

            if (floorManager.sites.length > 0)
                populateSites(floorManager.sites);
            else
                populateAllFacilities();

            geoViewConnections.enabled = true;

            loaded();
        }
    }

    Connections {
        target: floorFilterController

        function onSelectedSiteIdChanged() {
            const index = findElementIndexById(internal.selectedSiteId, FloorFilterController.TypeElement.Site);

            if (index === -1) {
                internal.selectedSite = null;

                facilities.clear();

                internal.selectedSiteId = "";

                return;
            }

            internal.selectedSite = floorManager.sites[index];

            if (!selectedSiteRespected && facilities.count === floorManager.facilities.length)
                return;

            internal.selectedFacilityId = "";

            populateFacilities(floorManager.sites[index].facilities);
        }

        function onSelectedSiteRespectedChanged() {
            if (!selectedSiteRespected)
                populateAllFacilities();
        }

        function onSelectedFacilityIdChanged() {
            const index = findElementIndexById(internal.selectedFacilityId, FloorFilterController.TypeElement.Facility);

            if (index === -1) {
                internal.selectedFacility = null;

                levels.clear();

                internal.selectedLevelId = "";

                return;
            }

            internal.selectedFacility = floorManager.facilities[index];

            populateLevels(floorManager.facilities[index].levels);

            resetLevelsVisibility(0);
        }

        function onSelectedLevelIdChanged() {
            if (internal.selectedLevelId === "")
                setVisibilityCurrentLevel(false);

            const index = findElementIndexById(internal.selectedLevelId, FloorFilterController.TypeElement.Level);

            if (index === -1) {
                if (internal.selectedLevel)
                    internal.selectedLevel.visible = false;

                internal.selectedLevel = null;
                internal.selectedLevelId = "";

                return;
            }

            const level = floorManager.levels[index];

            if (internal.selectedLevel)
                internal.selectedLevel.visible = false;

            internal.selectedLevel = level;
            internal.selectedLevel.visible = true;

            if (updateLevelsMode === FloorFilterController.UpdateLevelsMode.AllLevelsMatchingVerticalOrder)
                resetLevelsVisibility(internal.selectedLevel.verticalOrder);
        }

        function onIsLoadedChanged() {
            if (isLoaded)
                tryUpdateSelection();
        }

        function onDoneViewpointChanged() {
            geoViewConnections.enabled = true;

            geoView.onSetViewpointCompleted.disconnect(floorFilterController.doneViewpointChanged);
        }

        function onLoaded() {
            isLoaded = true;
        }
    }

    //--------------------------------------------------------------------------

    function tryUpdateSelection() {
        const viewpointCenter = geoView.currentViewpointCenter;

        if (automaticSelectionMode === FloorFilterController.AutomaticSelectionMode.Never
                || !viewpointCenter
                || isNaN(viewpointCenter.targetScale))
            return;

        const floorManager = floorFilterController.floorManager;

        let targetScale = floorManager && floorManager.siteLayer ? floorManager.siteLayer.minScale : 0;

        if (targetScale === 0)
            targetScale = 10000;

        if (viewpointCenter.targetScale > targetScale) {
            if (automaticSelectionMode === FloorFilterController.AutomaticSelectionMode.Always) {
                setSelectedSiteId("");
                setSelectedFacilityId("");
                setSelectedLevelId("");
            }

            return;
        }

        if (!floorManager)
            return;

        let selectSite = null;

        for (let i = 0, length = floorManager.sites.length; i < length; i++) {
            if (!GeometryEngine.intersects(floorManager.sites[i].geometry.extent, viewpointCenter.center))
                continue;

            selectSite = floorManager.sites[i];
            setSelectedSiteId(selectSite.siteId);

            break;
        }

        if (!selectSite && automaticSelectionMode === FloorFilterController.AutomaticSelectionMode.Always)
            setSelectedSiteId("");

        targetScale = floorManager.facilityLayer ? floorManager.facilityLayer.minScale : 0;

        if (targetScale === 0)
            targetScale = 4000;

        if (viewpointCenter.targetScale > targetScale)
            return;

        let selectFacility = null;

        for (let _i = 0, _length = floorManager.facilities.length; _i < _length; _i++) {
            if (!GeometryEngine.intersects(floorManager.facilities[_i].geometry.extent, viewpointCenter.center))
                continue;

            selectFacility = floorManager.facilities[_i];
            setSelectedFacilityId(selectFacility.facilityId);

            break;
        }

        if (!selectFacility && automaticSelectionMode === FloorFilterController.AutomaticSelectionMode.Always) {
            setSelectedFacilityId("");
            setSelectedLevelId("");
        }
    }

    function setSelectedSiteId(siteId) {
        internal.selectedSiteId = siteId;
    }

    function setSelectedFacilityId(facilityId) {
        if (facilityId === "") {
            internal.selectedFacilityId = facilityId;

            return;
        }

        const index = findElementIndexById(facilityId, FloorFilterController.TypeElement.Facility);

        if (index === -1) {
            internal.selectedFacilityId = "";

            return;
        }

        const facility = floorManager.facilities[index];

        if (facility.site && (!internal.selectedSite || facility.site.siteId !== internal.selectedSite.siteId))
            internal.selectedSiteId = facility.site.siteId;

        internal.selectedFacilityId = facilityId;
    }

    function setSelectedLevelId(levelId) {
        internal.selectedLevelId = levelId;
    }

    //--------------------------------------------------------------------------

    function setVisibilityCurrentLevel(visibility) {
        if (internal.selectedLevel)
            internal.selectedLevel.visible = visibility;
    }

    function resetLevelsVisibility(verticalOrder) {
        let level;

        for (let i = 0, length = floorManager.levels.length; i < length; i++) {
            level = floorManager.levels[i];
            level.visible = level.verticalOrder === verticalOrder;
        }
    }

    //--------------------------------------------------------------------------

    function populateSites(listSites) {
        sites.clear();

        let site;

        for (let i = 0, length = listSites.length; i < length; i++) {
            site = listSites[i];

            sites.append({
                             "name": site.name,
                             "modelId": site.siteId
                         });
        }

        if (listSites.length === 1) {
            internal.singleSite = true;

            site = listSites[0];

            setSelectedSiteId(site.siteId);
        }
    }

    function populateFacilities(listFacilities) {
        facilities.clear();

        const facilitiesExtracted = Array.from(listFacilities);

        facilitiesExtracted.forEach(facility => {
                                        let obj = {
                                            "name": facility.name,
                                            "modelId": facility.facilityId
                                        };

                                        if (facility.site) {
                                            obj["parentSiteName"] = facility.site.name;
                                            obj["parentSiteId"] = facility.site.siteId;
                                        }

                                        facilities.append(obj);
                                    });

        if (listFacilities.length === 1)
            internal.selectedFacilityId = listFacilities[0].facilityId;
    }

    function populateAllFacilities() {
        populateFacilities(floorManager.facilities);
    }

    function populateLevels(listLevels) {
        levels.clear();

        let selectedLevel = "";

        let levelsExtracted = [];

        let level;

        for (let i = listLevels.length - 1; i >= 0; i--) {
            level = listLevels[i];
            levelsExtracted.push(level);

            if (level.verticalOrder === 0) {
                selectedLevel = level.levelId;

                internal.selectedLevelId = level.levelId;
            }
        }

        levelsExtracted.sort((a, b) => {
                                 return b.verticalOrder - a.verticalOrder;
                             });

        levelsExtracted.forEach((levelExtracted) => {
                                    levels.append({
                                                      "shortName": levelExtracted.shortName,
                                                      "longName": levelExtracted.longName,
                                                      "modelId": levelExtracted.levelId
                                                  });
                                });

        if (selectedLevel === "")
            internal.selectedLevelId = listLevels.length ? listLevels[0].levelId : "";
    }

    //--------------------------------------------------------------------------

    function zoomToSite(siteId) {
        const index = findElementIndexById(siteId, FloorFilterController.TypeElement.Site);

        if (index === -1)
            return;

        const site = floorManager.sites[index];

        const extent = site.geometry.extent;

        zoomToEnvelope(extent);
    }

    function zoomToFacility(facilityId) {
        const index = findElementIndexById(facilityId, FloorFilterController.TypeElement.Facility);

        if (index === -1)
            return;

        const facility = floorManager.facilities[index];

        const extent = facility.geometry.extent;

        zoomToEnvelope(extent);
    }

    function zoomToEnvelope(envelope) {
        const builder = ArcGISRuntimeEnvironment.createObject("EnvelopeBuilder", { "geometry": envelope });

        builder.expandByFactor(zoom_padding);

        const newViewpoint = ArcGISRuntimeEnvironment.createObject("ViewpointExtent", { "extent": builder.geometry });

        geoViewConnections.enabled = false;

        geoView.onSetViewpointCompleted.connect(floorFilterController.doneViewpointChanged);
       // geoView.setViewpointGeometryAndPadding(newViewpoint,24)
        geoView.setViewpoint(newViewpoint);
    }

    //--------------------------------------------------------------------------

    function findElementIndexById(id, typeElement) {
        let model;

        let variableIdName;

        switch (typeElement) {
        case FloorFilterController.TypeElement.Level:
            model = floorManager.levels;

            variableIdName = "levelId";

            break;

        case FloorFilterController.TypeElement.Facility:
            model = floorManager.facilities;

            variableIdName = "facilityId";

            break;

        case FloorFilterController.TypeElement.Site:
            model = floorManager.sites;

            variableIdName = "siteId";

            break;

        default:
            return -1;
        }

        for (let i = 0, length = model.length; i < length; i++) {
            if (model[i][variableIdName] !== id)
                continue;

            return i;
        }

        return -1;
    }
}
