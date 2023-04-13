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

import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3


import "../controls" as Controls

import "../widgets" as Widgets

Controls.PopupPage {
    id: aboutAppPage

    property string poweredby:qsTr("Powered by")
    property bool isLicenseInfoTextAvailable: app.info.licenseInfo.replace(/<[^>]+>/g, '').trim() > ""
    property bool isCreditsTextAvailable: app.info.accessInformation.trim() > ""

    contentItem: Controls.BasePage {

        LayoutMirroring.enabled: !app.isLeftToRight
        LayoutMirroring.childrenInherit: !app.isLeftToRight
        header: ToolBar {

            id: header

           // height: app.headerHeight
            height:app.isNotchAvailable()? app.headerHeight + app.notchHeight : app.headerHeight
            topPadding:app.isNotchAvailable() ? app.notchHeight:0 //app.isNotchAvailable()?40:0

            width: parent.width

            RowLayout {
                anchors.fill: parent

                Controls.Icon {
                    id: closeBtn

                    visible: true
                    imageSource: "../controls/images/close.png"
                    Layout.alignment: Qt.AlignLeft
                    onClicked: {
                        aboutAppPage.close()
                    }
                }

                Controls.BaseText {
                    text: qsTr("About the App")
                    maximumLineCount: 1
                    fontSizeMode: Text.Fit
                    color: "#FFFFFF"
                    font {
                        pointSize: app.subtitleFontSize
                    }
                    Layout.alignment: Qt.AlignLeft
                }

                Controls.SpaceFiller {
                    Layout.fillWidth: true
                }

            }
        }

        contentItem: Flickable {
            id: flickable

            anchors.fill: parent
            contentWidth: parent.width
            contentHeight: aboutPageColumn.height
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: aboutPageColumn

                width: Math.min(parent.width,  app.maximumScreenWidth)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72 * scaleFactor
                }

                Pane {
                    Layout.preferredWidth: 80 * scaleFactor
                    Layout.preferredHeight: 80 * scaleFactor
                    Layout.alignment: Qt.AlignHCenter
                    Material.elevation: 2
                    padding: 0

                    Image {
                        anchors.fill: parent
                        source: app.info.thumbnail
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16 * scaleFactor
                }

                Label {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28 * scaleFactor

                    text: app.info.title
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 2
                    elide: Label.ElideRight

                    font.pixelSize: 20 * scaleFactor
                    font.family: app.baseFontFamily
                    font.weight: Font.DemiBold
                    color: app.black_87

                    horizontalAlignment: Label.AlignHCenter
                    verticalAlignment: Label.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8 * scaleFactor
                }

                Label {
                    Layout.fillWidth: true

                    text: qsTr("App Version") + ": %1".arg(app.info.version)

                    font.pixelSize: 14 * scaleFactor
                    font.family: app.baseFontFamily
                    color: app.black_87

                    horizontalAlignment: Label.AlignHCenter
                    verticalAlignment: Label.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24 * scaleFactor
                }

                Label {
                    Layout.fillWidth: true

                    text: app.info.description
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                    elide: Label.ElideRight

                    font.pixelSize: 14 * scaleFactor
                    font.family: app.baseFontFamily
                    color: app.black_87
                    linkColor: app.primaryColor

                    leftPadding: 16 * scaleFactor
                    rightPadding: 16 * scaleFactor
                    bottomPadding: 14 * scaleFactor
                    topPadding: 0

                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    onLinkActivated: {
                        app.openUrlInternally(link);
                    }
                }

                Button {
                    id: accessAndUseConstraintsButtonControl
                    visible: isLicenseInfoTextAvailable

                    Layout.fillWidth: true
                    Layout.preferredHeight: 56 * scaleFactor

                    Material.foreground: app.black_87
                    text: qsTr("Access and Use Constraints")
                    font.pixelSize: 16 * scaleFactor
                    font.family: app.baseFontFamily
                    font.weight: Font.DemiBold

                    contentItem: Item {
                        anchors.fill: parent

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Item {
                                Layout.fillHeight: true
                                Layout.preferredWidth: 16 * scaleFactor
                            }

                            Label {
                                Layout.fillWidth: true

                                text: accessAndUseConstraintsButtonControl.text

                                font: accessAndUseConstraintsButtonControl.font
                                elide: Label.AlignRight

                                horizontalAlignment: Label.AlignLeft
                                verticalAlignment: Label.AlignVCenter
                            }

                            Item {
                                Layout.preferredHeight: 24 * scaleFactor
                                Layout.preferredWidth: 24 * scaleFactor

                                Widgets.Icon {
                                    anchors.fill: parent

                                    source: "../images/baseline_expand_less_white_48dp.png"
                                    indicatorColor: app.primaryColor
                                    rotation: termsLabel.isOpen ? 0:180
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                                Layout.preferredWidth: 16 *  scaleFactor
                            }
                        }
                    }

                    background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                    }

                    onClicked: {
                        termsLabel.isOpen = !termsLabel.isOpen;
                    }
                }

                Label {
                    id: termsLabel

                    property bool isOpen: false

                    Layout.preferredHeight: isOpen? implicitHeight : 0

                    Behavior on Layout.preferredHeight {
                        NumberAnimation { duration: app.normalDuration }
                    }

                    Layout.fillWidth: true

                    text: isLicenseInfoTextAvailable ? app.info.licenseInfo.trim() : ""
                    linkColor: app.primaryColor
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                    clip: true

                    font.pixelSize: 14 * scaleFactor
                    font.family: app.baseFontFamily
                    color: app.black_87

                    leftPadding: 16 * scaleFactor
                    rightPadding: 16 * scaleFactor

                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    onLinkActivated: {
                        app.openUrlInternally(link);
                    }
                }

                Button {
                    id: creditsButtonControl
                    visible: isCreditsTextAvailable

                    Layout.fillWidth: true
                    Layout.preferredHeight: 56 * scaleFactor

                    Material.foreground: app.black_87
                    text: qsTr("Credits")
                    font.pixelSize: 16 * scaleFactor
                    font.family: app.baseFontFamily
                    font.weight: Font.DemiBold

                    contentItem: Item {
                        anchors.fill: parent

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Item {
                                Layout.fillHeight: true
                                Layout.preferredWidth: 16 * scaleFactor
                            }

                            Label {
                                Layout.fillWidth: true

                                text: creditsButtonControl.text

                                font: creditsButtonControl.font

                                elide: Label.AlignRight

                                horizontalAlignment: Label.AlignLeft
                                verticalAlignment: Label.AlignVCenter
                            }

                            Item {
                                Layout.preferredHeight: 24 *  scaleFactor
                                Layout.preferredWidth: 24 *  scaleFactor

                                Widgets.Icon {
                                    anchors.fill: parent

                                    source: "../images/baseline_expand_less_white_48dp.png"
                                    indicatorColor: app.primaryColor
                                    rotation: creditsSection.isOpen ? 0:180
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                                Layout.preferredWidth: 16 *  scaleFactor
                            }
                        }
                    }

                    background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                    }

                    onClicked: {
                        creditsSection.isOpen = !creditsSection.isOpen;
                    }
                }

                Item {
                    id: creditsSection

                    Layout.fillWidth: true
                    Layout.preferredHeight: isOpen ? creditsColumn.height : 0
                    clip: true

                    Behavior on Layout.preferredHeight {
                        NumberAnimation { duration: app.normalDuration }
                    }

                    property bool isOpen: false

                    ColumnLayout {
                        id: creditsColumn

                        width: parent.width

                        spacing: 0


                        Label {
                            Layout.fillWidth: true

                            text: isCreditsTextAvailable ? app.info.accessInformation.trim() : ""
                            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                            clip: true
                            horizontalAlignment: Label.AlignLeft

                            font.pixelSize: 14 * scaleFactor
                            font.family: app.baseFontFamily
                            color: app.black_87
                            linkColor: app.primaryColor

                            leftPadding: 16 * scaleFactor
                            rightPadding: 16 * scaleFactor
                            bottomPadding: 24 * scaleFactor
                            topPadding: 0

                            onLinkActivated: {
                                app.openUrlInternally(link);
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24 * scaleFactor
                }
            }
        }

        footer:Widgets.Footer {
            id:footer
            content: Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 24 * scaleFactor
                Layout.margins: 8
                Layout.bottomMargin:app.isNotchAvailable() ? app.units(20):app.units(8)


                RowLayout {
                    id: powerByRow
                    anchors.horizontalCenter: parent.horizontalCenter

                    spacing:0

                    Item {
                        Layout.preferredWidth: 16 * scaleFactor
                        Layout.fillHeight: true
                    }

                    Label {
                        Layout.fillHeight: true

                        text: poweredby
                        clip: true

                        font.pixelSize: 12 * scaleFactor
                        //font.family: fonts.system
                        color: app.black_87

                        horizontalAlignment: Label.AlignLeft
                        verticalAlignment: Label.AlignVCenter
                    }

                    Item {
                        Layout.preferredWidth: 8 * scaleFactor
                        Layout.fillHeight: true
                    }

                    Item {
                        Layout.preferredWidth: 24 * scaleFactor
                        Layout.preferredHeight: 24 * scaleFactor

                        Widgets.Icon {
                            anchors.fill: parent

                            source: "../images/appstudio.png"

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    openAppStudioUrl();
                                }
                            }
                        }
                    }

                    Item {
                        Layout.preferredWidth: 4 * scaleFactor
                        Layout.fillHeight: true
                    }

                    Label {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        text: "ArcGIS AppStudio"
                        elide: Label.ElideRight
                        clip: true

                        font.pixelSize: 12 * scaleFactor
                        //font.family: fonts.system
                        font.weight: Font.DemiBold
                        color: app.black_87

                        horizontalAlignment: Label.AlignLeft
                        verticalAlignment: Label.AlignVCenter

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                openAppStudioUrl();
                            }
                        }
                    }

                    Item {
                        Layout.preferredWidth: 16 * scaleFactor
                        Layout.fillHeight: true
                    }

                }
            }
        }
    }

    function openAppStudioUrl() {
        var _url = "https://www.esri.com/en-us/arcgis/products/appstudio-for-arcgis/overview";
        app.openUrlInternally(_url);
    }

    onVisibleChanged: {
        app.focus = true
    }

}
