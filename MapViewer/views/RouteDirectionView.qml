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


// You can run your app in Qt Creator by pressing Alt+Shift+R.
// Alternatively, you can run apps through UI using Tools > External > AppStudio > Run.
// AppStudio users frequently use the Ctrl+A and Ctrl+I commands to
// automatically indent the entirety of the .qml file.


import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import Esri.ArcGISRuntime 100.14

import "../controls"
import "../../assets"


Item {
    id: directionView

    property bool errorView: false
    property bool direView: false
    property var scaleFactor
    //property var directionListModel: null
    readonly property url directionsIcon: "../images/baseline_directions_white_48dp.png"
    readonly property url alertIcon: "../images/alert.png"

    Rectangle {
        id: directionViewRec
        anchors.fill: parent




        ColumnLayout {
            anchors.fill: parent
            spacing: 0

                BaseText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16 * scaleFactor
                    Layout.bottomMargin: 16 * scaleFactor
                   // Layout.margins: 8 * scaleFactor
                    visible: totalLength > ""
                    text: qsTr("Total Distance: %1").arg(totalLength)

                }


            Item{
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width


                Rectangle {
                    id:directionBtn2
                    height: 48 * scaleFactor
                    width: parent.width
                    anchors.top: parent.top
                    anchors.topMargin: 0 * scaleFactor
                    color: "transparent"
                    visible: directionView.errorView

                    RowLayout {
                        id: errorComp
                        anchors.fill: parent
                        spacing: 0

                        Item {
                            Layout.preferredWidth: 16 * scaleFactor
                        }

                        Item {
                            Layout.preferredHeight: 24 * scaleFactor
                            Layout.preferredWidth: 24 * scaleFactor

                            Image {
                                id: errorIcon
                                anchors.fill: parent
                                source: alertIcon

                                mipmap: true
                                width: 24 * scaleFactor
                                height: 24 * scaleFactor
                            }

                            ColorOverlay {
                                anchors.fill: errorIcon
                                source: errorIcon
                                color: "#D54550"
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            BaseText {
                                anchors.verticalCenter: parent.verticalCenter
                                Layout.alignment: Qt.AlignLeft
                                text: qsTr("No Route Returned")
                                color:  "#D54550"
                                elide: Text.ElideLeft
                            }
                        }

                        Item {
                            Layout.preferredWidth: 16 * scaleFactor
                        }
                    }
                }

                ListView {
                    id: directionListView
                    visible:direView
                    width: parent.width
                    height: isLarge?parent.height - directionBtn2.height - app.units(16):parent.height - app.units(16)
                    clip:true
                    spacing: 0
                    model: directionListModel
                    delegate: Rectangle {
                        height: 50 * scaleFactor
                        width: parent.width

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Item {
                                Layout.preferredWidth: 16 * scaleFactor
                            }

                            Rectangle {
                                id:iconrect
                                Layout.preferredHeight: 18 * scaleFactor
                                Layout.preferredWidth: 18 * scaleFactor
                                color:directionManeuverType === 18? "green": (directionManeuverType === 1?"red":"transparent")
                                radius:directionManeuverType === 18 || directionManeuverType === 1?iconrect.width * 0.5:0

                                Image {
                                    id: directionIcon
                                    source:getDirectionIcon(directionManeuverType) //directionsIcon
                                    width: directionManeuverType === 18 || directionManeuverType === 1?14 * scaleFactor:25 * scaleFactor
                                    height: width
                                    anchors.centerIn: parent
                                    mipmap: true
                                }

                                ColorOverlay {
                                    anchors.fill: directionIcon
                                    source: directionIcon
                                    color: directionManeuverType === 18 || directionManeuverType === 1 ? "yellow":"#848484"
                                    //rotation: getIconRotation(directionManeuverType)
                                }

                            }


                            Item {
                                Layout.preferredWidth: 16 * scaleFactor
                            }

                            Item {
                                id:direction
                                Layout.fillWidth: true
                                Layout.preferredHeight: parent.height

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 0

                                    RowLayout{
                                        Layout.fillWidth: true
                                        //Layout.fillHeight: true
                                        spacing:app.units(8)

                                        Label {
                                            id: directionLabel
                                            text: directionText
                                            Layout.preferredWidth: direction.width - app.units(70)
                                            font.bold: false
                                            font.pixelSize: baseFontSize
                                            //font.family: titleFontFamily
                                            Layout.alignment: Qt.AlignLeft
                                            maximumLineCount: 2
                                            wrapMode: Text.Wrap
                                            elide:Text.ElideRight
                                            color: getAppProperty (app.baseTextColor, Qt.darker("#F7F8F8"))

                                        }

                                        Label {
                                            id: distanceLabel
                                            text: length
                                            visible:length !== 0.00
                                            font.bold: false
                                            font.pixelSize: baseFontSize
                                            //font.family: titleFontFamily
                                            Layout.alignment: Qt.AlignRight
                                            color: getAppProperty (app.baseTextColor, Qt.darker("#F7F8F8"))

                                        }

                                    }


                                    Rectangle {
                                        Layout.preferredWidth: parent.width
                                        Layout.preferredHeight: 1 * scaleFactor
                                        color: "#D0D0D0"
                                        Layout.alignment: Qt.AlignRight
                                        visible:index < directionListModel.count - 1
                                    }
                                }
                            }
                        }
                        MouseArea {

                            anchors.fill: parent
                            onClicked: {
                                if(prevLabel)
                                   prevLabel.font.bold = false
                                directionLabel.font.bold = true
                                prevLabel = directionLabel
                                highlightRouteSegment(geometry,directionManeuverType)

                                if (prevDistanceLabel)
                                    prevDistanceLabel.font.bold = false
                                distanceLabel.font.bold = true
                                prevDistanceLabel = distanceLabel


                            }
                        }

                    }

                }
            }
        }

    }

//    DropShadow {
//        anchors.fill: directionViewRec
//        horizontalOffset: 0
//        verticalOffset: 0
//        radius:18
//        samples: 25
//        color: "#20000000"
//        spread: 0.0
//        source: directionViewRec
//    }
}
