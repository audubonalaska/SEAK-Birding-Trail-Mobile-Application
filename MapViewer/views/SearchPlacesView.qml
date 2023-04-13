import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import "../controls" as Controls

SearchView {
    id: searchPlacesView

    property var suggestionsModel: ListModel {}
    property string locatorErrorMessage:mapView.getLocatorErrorMessage(locatorTask)

    signal searchSuggestionSelected (string suggestion)

    objectName: "searchPlacesView"
    defaultSearchViewTitleText: locatorTask.loadError !== null  ? locatorErrorMessage  :qsTr("Search for places")
    searchViewTitleText:searchResultTitleText ? searchResultTitleText: defaultSearchViewTitleText
    //sectionPropertyAttr: "resultExtent"
    hideResults: suggestions.visible

    listView.delegate: SearchResultsDelegate {
        title: typeof place_label !== "undefined" ? place_label : ""
        description: typeof place_addr !== "undefined" ? place_addr : ""

        onClicked: {
            listView.model.currentIndex = initialIndex
            searchResultSelected(listView.model.features[initialIndex], initialIndex, sizeState === "")
        }
    }


    Pane {
        id: suggestions

        padding: 0
        Material.elevation: 2
        Layout.fillWidth: true
        Layout.fillHeight: true
        //Layout.margins: app.baseUnit
        //Layout.topMargin: app.baseUnit/2

        background: Rectangle {
            anchors.fill: parent
            Material.background: "#F4F4F4"
        }

        visible: suggestionsModel.count > 0 && listView.count === 0

        ListView {
            clip: true
            anchors.fill: parent
            model: suggestionsModel
            spacing: 0

            delegate: Pane {
                height: app.units(50)
                width: parent ? parent.width : 0
                padding: 0

                background: Rectangle {
                    anchors.fill: parent
                }
                LayoutMirroring.enabled: !app.isLeftToRight
                LayoutMirroring.childrenInherit: !app.isLeftToRight
                RowLayout {
                    anchors.fill: parent

                    Controls.Icon {
                        id: suggestionSearchIcon
                        imageSource: "../images/search.png"
                        maskColor: app.subTitleTextColor
                    }

                    Controls.BaseText {
                        id: suggestionText

                        Layout.preferredWidth: parent.width - suggestionSearchIcon.width
                        Layout.fillHeight: true
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        text: label
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                    }
                }

                Rectangle {
                    id: separator

                    visible: index !== suggestionsModel.count - 1
                    color: app.separatorColor
                    anchors {
                        bottom: parent.bottom
                        right: parent.right
                    }
                    width: suggestionText.width
                    height: app.units(0.5)
                    opacity: 0.5
                }

                Controls.Ink {
                    anchors.fill: parent

                    onClicked: {
                        searchSuggestionSelected(label)
                    }
                }
            }
        }
    }
}
