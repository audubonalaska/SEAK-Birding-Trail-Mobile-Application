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
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0
import "../controls" as Controls

Pane {
    id: root

    property int transitionDuration: 200
    property real pageExtent: 0
    property real base: root.height
    property real panelHeaderHeight:root.units(10)
    property real defaultMargin: root.units(16)
    property real appHeaderHeight: 0
    property real iconSize: units(16)
    property string transitionProperty: "y"
    property string title: ""
    property color backgroundColor: "#FFFFFF"
    property color headerBackgroundColor: "#CCCCCC"
    property color separatorColor: "#4C4C4C"
    property color titleColor: "#4c4c4c"
    property bool fullView: false
    property bool intermediateView: false
    property bool isLargeScreen: false
    property bool isIntermediateScreen:false
    property bool showPageCount: false
    property int pageCount: 1
    property int currentPageNumber: 1

    property bool isHeaderVisible:true
    property bool isCurrentFeatureHighlighted:false
    property Item content: Item {}

    property alias _footerLoader:footerLoader
    property alias _headerLoader:headerLoader


    property alias panelContent: panelContent
    property var panelPageHeight:parent?(fullView ?parent.height:parent.height - root.pageExtent): undefined

    property var editorTrackingInfo:null

    property bool isFooterVisible:false


    contentWidth: parent.width
    contentHeight: 0

    height:parent.height

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: app.isIphoneX?app.units(16):0


    anchors {
        fill: parent
    }

    function getAppProperty (appProperty, fallback) {
        if (!fallback) fallback = ""
        try {
            return appProperty ? appProperty : fallback
        } catch (err) {
            return fallback
        }
    }


   /* Item {
        id: screenSizeState

        states: [

            State {
                name: "LARGE"
                when: isLargeScreen

                PropertyChanges {
                    target: root
                    fullView: true
                    intermediateView:false

                }


            },
            State {
                name: "SMALL_EDIT_EXPAND"
                when: !isLargeScreen && !app.isInEditMode && app.isExpandButtonClicked


                PropertyChanges {
                    target: root
                    fullView: false
                    intermediateView:false
                    width: parent.width
                }

            },


            State {
                name: "SMALL_EDIT"
                when: !isLargeScreen && !app.isInEditMode

                PropertyChanges {
                    target: root
                    fullView: false
                    intermediateView:false


                    width: parent.width
                }

            },


            State {
                name: "SMALL"
                when: !isLargeScreen //&& app.isInEditMode

                PropertyChanges {
                    target: root
                    fullView: false
                    intermediateView:false

                    width: parent.width
                }


            }
            ,

            State {
                name: "INTERMEDIATE"
                when: intermediateView

                PropertyChanges {
                    target: root
                    fullView: false
                    intermediateView:true

                }

            }

        ]
    }
*/

    contentItem:
        BasePage {
        id: panelContent
        contentWidth: parent.width



        header:ColumnLayout{
            width:parent.width
            spacing:0
            //anchors.top:parent.top
            y : pageView.state === "anchortop"?-app.notchHeight:0


            Rectangle{
                Layout.fillWidth: true
                Layout.preferredHeight:pageView.state === "anchortop"?app.notchHeight:0//app.isExpandButtonClicked?app.notchHeight : 0
                color:app.primaryColor
            }

            Item{

                Layout.fillWidth: true
                Layout.preferredHeight:visible ? headerLoader.height  : 0

                Loader {
                    id: headerLoader
                    width:parent.width


                }
            }



        }


        padding: 0


        Material.background: root.backgroundColor


        contentItem:  root.content



        footer:ColumnLayout{
            width:parent.width
            spacing:0

            Item{
                visible: isFooterVisible && panelContent.visible
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? footerLoader.height  : 0

                Loader {
                    id: footerLoader
                    width:parent.width
                    //height:source > ""? implicitHeight : 0

                }
            }

            Item{
                Layout.fillWidth: true
                Layout.preferredHeight:Qt.platform.os === "ios" && app.isNotchAvailable() ?app.units(10):0//app.notchHeight
            }

        }





    }






    function reset () {
        //        root.title = ""
        //        root.showPageCount = false
        //        root.pageCount = 1
        //        root.currentPageNumber = 1
    }

    function collapseFullView () {

        panelContent.state = "INTERMEDIATE"
        dockToBottom()
    }

    function createTransition (transitionProperty, duration, from, to, easingType) {
        var transition = transitionObject.createObject(root)
        transition.transitionProperty = transitionProperty || "y"
        transition.duration = duration || 200
        transition.from = from || root.height
        transition.to = to || 0
        transition.easingType = easingType || Easing.InOutQuad
        return transition
    }

    function toggle () {
        return visible ? close () : open ()
    }

    function units (num) {
        return num ? num * AppFramework.displayScaleFactor : num
    }


}
