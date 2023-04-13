import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.15
import QtQml.Models 2.15

import "../../MapViewer/controls"


Item {
    id: floorSearchDialog

    visible: false

    anchors.fill: parent
    clip: true

    //--------------------------------------------------------------------------

    required property FloorFilterController floorFilterController

    readonly property int maxNumberResults: 5

    readonly property real resultDelegateHeight: 48 * scaleFactor

    property int currentVisibileListView: FloorSearchDialog.VisibleListView.Site

    property color backgroundColor: colors.white

    property int selectedSiteIndex: -1

    property string selectedSiteId: ""
    property string selectedSiteName: ""

    property int selectedFacilityIndex: -1

    property string selectedFacilityId: ""
    property string selectedFacilityName: ""

    //--------------------------------------------------------------------------

    enum VisibleListView {
        Site = 0,
        Facility = 1
    }

    //--------------------------------------------------------------------------
    function setSelectedFacilityId()
    {
        //if(selectedFacilityIndex === -1)
        //{
        let _selectedFacilityId = floorFilterController.selectedFacilityId
        if(_selectedFacilityId > "")
        {
            for(let k=0;k<floorFilterController.facilities.count; k++)
            {
                if (_selectedFacilityId === floorFilterController.facilities.get(k).modelId)
                {
                    selectedFacilityIndex = k
                    selectedFacilityId = _selectedFacilityId
                    break
                }
            }
        }
        else
            selectedFacilityId = ""
        //}
    }
    function setSelectedSiteId()
    {
        //if(selectedSiteIndex === -1)
        //{
        let _selectedSiteId = floorFilterController.selectedSiteId
        for(let k=0;k<floorFilterController.sites.count; k++)
        {
            if (_selectedSiteId === floorFilterController.sites.get(k).modelId)
            {
                selectedSiteIndex = k
                selectedSiteId = _selectedSiteId
                break
            }
        }
        // }
    }
    //selectedFacilityId

    Connections {
        target: floorSearchDialog

        function onVisibleChanged() {
            if (!visible) {
                Qt.inputMethod.hide();

                return;
            }

            setSelectedSiteId()
            setSelectedFacilityId()

            listView.positionViewAtSelectedIndex();

            forceActiveFocus();
        }


        function onCurrentVisibileListViewChanged() {
            listView.positionViewAtSelectedIndex();
        }

        function onSelectedSiteIdChanged() {
            selectedFacilityIndex = -1;

            selectedFacilityId = "";
            selectedFacilityName = "";
        }
    }

    Connections {
        target: floorFilterController

        function onSelectedSiteChanged() {
            if (!floorFilterController.selectedSite)
                resetDialog();
        }
    }

    //--------------------------------------------------------------------------
    // backbutton handling

    Keys.onReleased: {
        if (!visible)
            return;

        if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
            event.accepted = true;

            close();
        }
    }

    //--------------------------------------------------------------------------
    // mask

    Rectangle {
        anchors.fill: parent

        color: colors.mask

        MouseArea {
            anchors.fill: parent

            preventStealing: true

            onWheel: {}

            onClicked: {
                close();
            }
        }
    }

    //--------------------------------------------------------------------------

    Item {
        width: 328 * scaleFactor
        height: container.height
        anchors.centerIn: parent

        MouseArea {
            anchors.fill: parent

            preventStealing: true
        }

        ColumnLayout {
            id: container

            width: parent.width
            height: containerContent.height + notch.height
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0

            Rectangle {
                id: containerContent

                Layout.fillWidth: true
                Layout.preferredHeight: containerContentColumnLayout.height

                color: backgroundColor

                ColumnLayout {
                    id: containerContentColumnLayout

                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24 * scaleFactor
                    }

                    Item {
                        Layout.preferredWidth: parent.width - 48 * scaleFactor
                        Layout.preferredHeight: 24 * scaleFactor
                        Layout.alignment: Qt.AlignHCenter

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Item {
                                Layout.preferredWidth: 8 * scaleFactor
                                Layout.fillHeight: true
                            }

                            Item {
                                visible: currentVisibileListView !== FloorSearchDialog.VisibleListView.Site

                                Layout.preferredWidth: 24 * scaleFactor
                                Layout.fillHeight: true

                                IconImage {
                                    width: 24 * scaleFactor
                                    height: width
                                    anchors.centerIn: parent

                                    source: "../../MapViewer/images/back.png"//sources.arrow_back
                                    color: colors.black_54
                                    rotation: app.isRightToLeft ? 180 : 0
                                }

                                MouseArea {
                                    hoverEnabled: app.isDesktop

                                    width: 32 * scaleFactor
                                    height: width
                                    anchors.centerIn: parent

                                    //radius: width / 2

                                    onClicked: {
                                        floorFilterController.zoomToSite(selectedSiteId);

                                        currentVisibileListView = FloorSearchDialog.VisibleListView.Site;
                                    }
                                }
                            }

                            Item {
                                visible: currentVisibileListView !== FloorSearchDialog.VisibleListView.Site

                                Layout.preferredWidth: 16 * scaleFactor
                                Layout.fillHeight: true
                            }

                            Label {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                LayoutMirroring.enabled: false
                                padding: 0

                                text: {
                                    if (selectedSiteName > "")
                                        return selectedFacilityName > "" ? "%1: %2".arg(selectedSiteName).arg(selectedFacilityName) : selectedSiteName;

                                    return strings.select_site;
                                }

                                // font.family: fonts.demi_fontFamily
                                font.bold: true
                                font.pixelSize: 16 * scaleFactor
                                font.letterSpacing: 0
                                color: colors.black_87

                                lineHeightMode: Label.FixedHeight
                                lineHeight: 24 * scaleFactor

                                horizontalAlignment: app.isRightToLeft ? Label.AlignRight : Label.AlignLeft
                                verticalAlignment: Label.AlignVCenter
                                elide: app.isRightToLeft ? Label.ElideLeft : Label.ElideRight
                            }

                            Item {
                                Layout.preferredWidth: 8 * scaleFactor
                                Layout.fillHeight: true
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16 * scaleFactor
                    }

                    Rectangle {
                        opacity: 0.12

                        Layout.preferredWidth: parent.width - 48 * scaleFactor
                        Layout.preferredHeight: scaleFactor
                        Layout.alignment: Qt.AlignHCenter

                        color: colors.black
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56 * scaleFactor

                        RowLayout {
                            width: parent.width - 48 * scaleFactor
                            height: parent.height
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 0

                            Item {
                                Layout.preferredWidth: 8 * scaleFactor
                                Layout.fillHeight: true
                            }

                            IconImage {
                                Layout.preferredWidth: 24 * scaleFactor
                                Layout.preferredHeight: width
                                Layout.alignment: Qt.AlignVCenter

                                source: "../../MapViewer/images/search.png"//sources.search
                                color: colors.black_54
                            }

                            Item {
                                Layout.preferredWidth: 16 * scaleFactor
                                Layout.fillHeight: true
                            }

                            TextField {
                                id: textField

                                Layout.fillWidth: true
                                Layout.preferredHeight: 24 * scaleFactor
                                Layout.alignment: Qt.AlignVCenter
                                leftPadding: 0
                                rightPadding: leftPadding
                                topPadding: 0
                                bottomPadding: topPadding

                                Material.accent: colors.primary
                                selectByMouse: true
                                placeholderText:"search" //strings.search
                                placeholderTextColor: colors.black_38
                                echoMode: TextInput.Normal

                                font.pixelSize: 16 * scaleFactor
                                //font.family: text > "" ? fonts.demi_fontFamily : fonts.regular_fontFamily
                                font.bold: text > ""
                                color: colors.black_87

                                horizontalAlignment: TextField.AlignLeft
                                verticalAlignment: TextField.AlignVCenter

                                background: Rectangle {
                                    anchors.fill: parent
                                    color: colors.transparent
                                }

                                onTextChanged: {
                                    const items = delegateModel.items;

                                    const searchText = text.toLowerCase();

                                    if (searchText > "") {
                                        let item;

                                        for (let _i = 0, _count = items.count; _i < _count; _i++) {
                                            item = items.get(_i);

                                            if (item.model.name.toLowerCase().includes(searchText))
                                                item.inFiltered = true;
                                            else
                                                item.inFiltered = false;
                                        }
                                    } else {
                                        for (let i = 0, count = items.count; i < count; i++)
                                            items.get(i).inFiltered = true;
                                    }

                                    listView.visible = delegateFilteredGroup.count > 0;
                                }

                                Component.onCompleted: {
                                    // Workarounds.checkInputMethodHints(textField, app.locale);
                                }
                            }

                            Item {
                                Layout.preferredWidth: 8 * scaleFactor
                                Layout.fillHeight: true
                            }

                            Item {
                                visible: textField.text > ""

                                Layout.preferredWidth: 24 * scaleFactor
                                Layout.fillHeight: true

                                IconImage {
                                    visible: textField.text > ""

                                    width: 24 * scaleFactor
                                    height: width
                                    anchors.centerIn: parent

                                    source: "../../MapViewer/images/close.png"//sources.cancel
                                    color: colors.black_54
                                }

                                RippleMouseArea {
                                    // MouseArea {
                                    hoverEnabled: app.isDesktop//app.deviceManager.isDesktop

                                    width: 32 * scaleFactor
                                    height: width
                                    anchors.centerIn: parent

                                    radius: width / 2

                                    onClicked: {
                                        if (textField.text > "")
                                            textField.clear();
                                    }
                                }
                            }

                            Item {
                                Layout.preferredWidth: 8 * scaleFactor
                                Layout.fillHeight: true
                            }
                        }
                    }

                    Rectangle {
                        opacity: 0.12

                        Layout.preferredWidth: parent.width - 48 * scaleFactor
                        Layout.preferredHeight: scaleFactor
                        Layout.alignment: Qt.AlignHCenter

                        color:"black" //colors.black
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16 * scaleFactor
                    }

                    ListView {
                        id: listView

                        Layout.preferredWidth: parent.width - 48 * scaleFactor
                        Layout.preferredHeight: (count > maxNumberResults ? maxNumberResults + 0.5 : count) * resultDelegateHeight
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 0
                        clip: true

                        boundsBehavior: ListView.StopAtBounds

                        model: delegateModel

                        function positionViewAtSelectedIndex() {
                            let selectedIndex = -1;

                            switch (currentVisibileListView) {
                            case FloorSearchDialog.VisibleListView.Site:
                                selectedIndex = selectedSiteIndex;

                                break;

                            case FloorSearchDialog.VisibleListView.Facility:
                                selectedIndex = selectedFacilityIndex;

                                break;

                            default:
                                break;
                            }

                            if (selectedIndex > -1)
                                positionViewAtIndex(selectedIndex, ListView.Center);
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16 * scaleFactor
                    }
                }
            }

            Item {
                id: notch

                Layout.fillWidth: true
                Layout.preferredHeight: Qt.inputMethod.visible ? 168 * scaleFactor : 0
            }
        }
    }

    DelegateModel {
        id: delegateModel

        model: switch (currentVisibileListView) {
               case FloorSearchDialog.VisibleListView.Site:
                   return floorFilterController.sites;

               case FloorSearchDialog.VisibleListView.Facility:
                   return floorFilterController.facilities;

               default:
                   return 0;
               }

        filterOnGroup: "filtered"

        groups: [
            DelegateModelGroup {
                id: delegateFilteredGroup

                name: "filtered"
                includeByDefault: true
            }
        ]

        items.onChanged: {
            if (currentVisibileListView === FloorSearchDialog.VisibleListView.Facility) {
                let elements = [];

                for (let i = 0, count = delegateFilteredGroup.count; i < count; i++)
                    elements.push(delegateFilteredGroup.get(i));

                elements.sort((a, b) => {
                                  if (a.model.name < b.model.name)
                                  return -1;

                                  if (a.model.name > b.model.name)
                                  return 1;

                                  return 0;
                              });

                for (let _i = 0, length = elements.length; _i < length; _i++)
                    delegateFilteredGroup.move(elements[_i].filteredIndex, _i, 1);
            }
        }

        delegate: Item {
            id: delegate

            width: ListView.view.width
            height: resultDelegateHeight

            readonly property bool selected: switch (currentVisibileListView) {
                                             case FloorSearchDialog.VisibleListView.Site:
                                                 return model.modelId === selectedSiteId;

                                             case FloorSearchDialog.VisibleListView.Facility:
                                                 return model.modelId === selectedFacilityId;

                                             default:
                                                 return false;
                                             }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.preferredWidth: 8 * scaleFactor
                    Layout.fillHeight: true
                }

                IconImage {
                    Layout.preferredWidth: 24 * scaleFactor
                    Layout.preferredHeight: width
                    Layout.alignment: Qt.AlignVCenter

                    source: delegate.selected ? "../../MapViewer/images/radio_button_checked-white-24dp.svg" : "../../MapViewer/images/radio_button_unchecked-white-24dp.svg"
                    color: delegate.selected ? primaryColor : colors.black_87
                }

                Item {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 24 * scaleFactor
                }

                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    padding: 0

                    text: (model.name ?? "")
                    font.pixelSize: 16 * scaleFactor
                    font.letterSpacing: 0
                    //  font.family: fonts.regular_fontFamily
                    color: colors.black_87

                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter
                    elide: app.isRightToLeft ? Label.ElideLeft : Label.ElideRight
                }

                Item {
                    Layout.preferredWidth: 8 * scaleFactor
                    Layout.fillHeight: true
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    Qt.inputMethod.hide();

                    switch (currentVisibileListView) {
                    case FloorSearchDialog.VisibleListView.Site:
                        selectedSiteIndex = index;

                        selectedSiteId = model.modelId;
                        selectedSiteName = model.name;

                        floorFilterController.setSelectedSiteId(selectedSiteId);
                        floorFilterController.zoomToSite(selectedSiteId);

                        currentVisibileListView = FloorSearchDialog.VisibleListView.Facility;

                        break;

                    case FloorSearchDialog.VisibleListView.Facility:
                        selectedFacilityIndex = index;

                        selectedFacilityId = model.modelId;
                        selectedFacilityName = model.name;

                        floorFilterController.setSelectedFacilityId(selectedFacilityId);
                        floorFilterController.zoomToFacility(selectedFacilityId);

                        break;

                    default:
                        break;
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function resetDialog() {
        selectedSiteIndex = -1;

        selectedSiteId = "";
        selectedSiteName = "";

        selectedFacilityIndex = -1;

        selectedFacilityId = "";
        selectedFacilityName = "";

        currentVisibileListView = FloorSearchDialog.VisibleListView.Site;
    }

    function open() {
        visible = true;
    }

    function close() {
        visible = false;
    }
}
