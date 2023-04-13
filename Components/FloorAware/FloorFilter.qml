import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12

import Esri.ArcGISRuntime 100.14


import "../../MapViewer/controls"


Item {
    id: floorFilter

    visible: opacity > 0
    opacity: isShown ? 1 : 0

    anchors.fill: parent
    clip: true

    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }

    required property GeoView geoView

    readonly property FloorSite selectedSite: floorFilterController.selectedSite
    readonly property FloorFacility selectedFacility: floorFilterController.selectedFacility
    readonly property FloorLevel selectedLevel: floorFilterController.selectedLevel

    readonly property int maxNumberLevels: 3
    readonly property int levelsCount: listView.count

    readonly property bool floorSearchDialogOpened: floorSearchDialog.visible

    property bool showTools: true
    property bool showLevelsInfo: false
    property bool isShown: true//false

    //--------------------------------------------------------------------------

    Connections{
        target:geoView.map
        function onLoadStatusChanged()
        {
            if(geoView.map.floorManager)
                geoView.map.floorManager.load()
        }
    }

    Connections {
        target: floorFilter

        function onIsShownChanged() {
            if (isShown)
                return;

            closeLevelsInfo();

            floorSearchDialog.close();
        }
    }

    Connections {
        target: floorFilterController

        function onSelectedSiteChanged() {
            closeLevelsInfo();
        }

        function onSelectedFacilityChanged() {
            const selectedFacility = floorFilterController.selectedFacility;

            if (!selectedFacility)
                return;

            if (selectedFacility.levels.length > 0) {
                if (listView.visible)
                    listView.positionViewAtSelectedIndex();
            } else {
                closeLevelsInfo();
            }
        }
    }

    //--------------------------------------------------------------------------

    FloorFilterController {
        id: floorFilterController

        geoView: floorFilter.geoView
    }

    //--------------------------------------------------------------------------

    Item {
        visible: floorFilterController.isLoaded
        anchors.left:parent.left
        anchors.leftMargin: 16 * scaleFactor
        width: filterControl.width
        height:filterControl.height


        ColumnLayout {
            id:filterControl
            width:contentColumnLayout.width
           // anchors.fill: parent
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 10 * scaleFactor//22 * scaleFactor
                // Layout.topMargin: app.isIphoneX ? app.notchHeight : 0
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: contentColumnLayout.height

                color: colors.white
                radius: height / 2

                Behavior on height {
                    SmoothedAnimation { duration: 100 }
                }

                MouseArea {
                    anchors.fill: parent

                    preventStealing: true
                }

                ColumnLayout {
                    id: contentColumnLayout

                    width: Math.max(control.width,56 * app.scaleFactor)//control.width//parent.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 0

                    Item {
                        visible: showTools || (showLevelsInfo && levelsCount > 1)
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20 * scaleFactor
                    }

                   IconButton {
                        visible: showTools
                        enabled: switch (floorSearchDialog.currentVisibileListView) {
                                 case FloorSearchDialog.VisibleListView.Site:
                                     return floorFilterController.selectedSiteId > "";

                                 case FloorSearchDialog.VisibleListView.Facility:
                                     return floorFilterController.selectedFacilityId > "";

                                 default:
                                     return false;
                                 }

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48 * scaleFactor

                        imageSource: "../../MapViewer/images/zoom_in_map_white_24dp.svg"
                        imageColor: enabled ? colors.black_54 : colors.black_38

                        onClicked: {
                            //app.deviceManager.checkHapticFeedback();

                            switch (floorSearchDialog.currentVisibileListView) {
                            case FloorSearchDialog.VisibleListView.Site:
                                floorFilterController.zoomToSite(floorFilterController.selectedSiteId);

                                break;

                            case FloorSearchDialog.VisibleListView.Facility:
                                floorFilterController.zoomToFacility(floorFilterController.selectedFacilityId);

                                break;

                            default:
                                break;
                            }
                        }
                    }

                    RoundTextButton {
                        id:control
                        visible:buttonText > "" && !showLevelsInfo

                        //Layout.fillWidth: true
                        Layout.preferredHeight: 48 * scaleFactor
                        Layout.preferredWidth: Math.max(implicitWidth,56 * app.scaleFactor)//implicitWidth

                        buttonText: floorFilterController.selectedLevel ? floorFilterController.selectedLevel.shortName : ""
                        textColor: primaryColor                      

                        onClicked: {
                            // app.deviceManager.checkHapticFeedback();

                            openLevelsInfo();
                        }
                    }

                    ListView {
                        id: listView

                        visible: showLevelsInfo

                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(contentHeight, (levelsCount > maxNumberLevels ? maxNumberLevels + 0.5 : levelsCount) * 48 * scaleFactor)
                        spacing: 0
                        clip: true

                        boundsBehavior: ListView.StopAtBounds

                        model: floorFilterController.levels

                        onVisibleChanged: {
                            if (visible)
                                positionViewAtSelectedIndex();
                        }

                        delegate: RoundTextButton {
                            id:control1
                            width: Math.max(implicitWidth,56 * app.scaleFactor)//implicitWidth//48 * scaleFactor
                            height: width

                            buttonText: model.shortName
                            textColor: selected ? primaryColor : colors.black_54

                            readonly property bool selected: floorFilterController.selectedLevelId === model.modelId




                            onClicked: {
                                //app.deviceManager.checkHapticFeedback();

                                floorFilterController.setSelectedLevelId(model.modelId);

                                openLevelsInfo();
                            }
                        }

                        function positionViewAtSelectedIndex() {
                            let selectedIndex = -1;

                            let item;

                            for (let i = 0, count = model.count; i < count; i++) {
                                item = model.get(i);

                                if (floorFilterController.selectedLevelId === item.modelId)
                                    selectedIndex = i;
                            }

                            if (selectedIndex > -1)
                                positionViewAtIndex(selectedIndex, ListView.Center);
                        }
                    }

                    IconButton {
                        visible: showTools

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48 * scaleFactor

                        imageSource: "../../MapViewer/images/search.png"
                        imageColor:  colors.black_54

                        onClicked: {
                            // app.deviceManager.checkHapticFeedback();
                            floorSearchDialog.open();
                        }
                    }

                    Item {
                        visible: showTools || (showLevelsInfo && levelsCount > 1)
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8 * scaleFactor

                    }
                }

                layer.enabled: true

                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: scaleFactor
                    radius: 8 * scaleFactor
                    samples: 16
                    color: colors.shadowDark
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    //--------------------------------------------------------------------------

    FloorSearchDialog {
        id: floorSearchDialog

        floorFilterController: floorFilterController
    }

    //--------------------------------------------------------------------------

    function openLevelsInfo() {
        showLevelsInfo = true;
    }

    function closeLevelsInfo() {
        showLevelsInfo = false;
    }
}
