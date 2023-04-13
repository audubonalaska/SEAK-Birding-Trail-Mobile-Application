import QtQuick 2.0

/*
This file is used as a utility to translate supported basemaps' name for different languages
This file is open to extension - new basemap names and their corresponding translations can be added here  (And in Strings.qml file)
for robust translation
*/
Item {
    property var basemapTranslatorDict: ({})

    Component.onCompleted: {
        init();
    }

    // Function that initializes and assigns values to the Dictionary - This is called only when required (only when the basemapsView is initialized)
    function init(){
        basemapTranslatorDict["USA Topo Maps"] = strings.basemapUSATopoMaps;

        basemapTranslatorDict["Imagery"] = strings.basemapImagery;
        basemapTranslatorDict["Imagery Hybrid"] = strings.basemapImageryHybrid;
        basemapTranslatorDict["Imagery (WGS84)"] = strings.basemapImageryWGS84;
        basemapTranslatorDict["Imagery Hybrid (WGS84)"] = strings.basemapImageryHybridWGS84;

        basemapTranslatorDict["USGS National Map"] = strings.basemapUSGSNationalMap;

        basemapTranslatorDict["National Geographic"] = strings.basemapNationalGeographic;

        basemapTranslatorDict["Oceans"] = strings.basemapOceans;

        basemapTranslatorDict["OpenStreetMap"] = strings.basemapOSM;
        basemapTranslatorDict["OpenStreetMap Vector Basemap"] = strings.basemapOSMVector;
        basemapTranslatorDict["OpenStreetMap Vector Basemap (WGS84)"] = strings.basemapOSMVectorWGS84;

        basemapTranslatorDict["Topographic"] = strings.basemapTopographic;
        basemapTranslatorDict["Topographic (WGS84)"] = strings.basemapTopographicWGS84;

        basemapTranslatorDict["Streets"] = strings.basemapStreets;
        basemapTranslatorDict["Streets (Night)"] = strings.basemapStreetsNight;
        basemapTranslatorDict["Streets (with Relief)"] = strings.basemapStreetsWithRelief;

        basemapTranslatorDict["Imagery with Labels"] = strings.basemapImageryWithLabels;
        basemapTranslatorDict["Terrain with Labels"] = strings.basemapTerrainWithLabels;

        basemapTranslatorDict["Dark Gray Canvas"] = strings.basemapDarkGrayCanvas;
        basemapTranslatorDict["Light Gray Canvas"] = strings.basemapLightGrayCanvas;
        basemapTranslatorDict["Light Gray Canvas (WGS84)"] = strings.basemapLightGrayCanvasWGS84;

        basemapTranslatorDict["Nova Map"] = strings.basemapNovamap;
        basemapTranslatorDict["Nova Map (WGS84)"] = strings.basemapNovamapWGS84;

        basemapTranslatorDict["Mid-Century Map"] = strings.basemapMidCenturyMap;
        basemapTranslatorDict["Mid-Century Map (WGS84)"] = strings.basemapMidCenturyMapWGS84;

        basemapTranslatorDict["Navigation"] = strings.basemapNavigation;
        basemapTranslatorDict["Navigation (Dark Mode)"] = strings.basemapNavigationDarkMode;
        basemapTranslatorDict["Navigation (WGS84)"] = strings.basemapNavigationWGS84;

        basemapTranslatorDict["Community Map"] = strings.basemapCommunityMap;

        basemapTranslatorDict["Human Geography Map"] = strings.basemapHumanGeographyMap;
    }
}
