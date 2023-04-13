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
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0

ToolButton {
    id: root

    property bool isDebug: false
    property int iconSize: root.getAppProperty(app.iconSize, root.units(24))
    property color maskColor:root.getAppProperty(app.iconMaskColor, "transparent")
    property url imageSource: ""
    property real imageWidth: 0.5 * root.width
    property real imageHeight: 0.5 * root.height
    property color checkedColor:"red"
    property int circleWidth:0
    property bool _checked : false
    property bool isSVGImage:imageSource.toString() > ""? (imageSource.toString()).split('.')[1].toUpperCase() === "SVG":false


    Layout.preferredHeight:root.visible ? root.iconSize : 0
    Layout.preferredWidth: root.visible ? root.iconSize : 0
    highlighted: checked

    Rectangle {
        anchors.centerIn: parent
        width: circleWidth > 0 ? circleWidth:0.8 * parent.width
        height: width
        radius: width/2
        color:circleWidth > 0 ?(checked ? app.primaryColor : "#40FFFFFF") :(checked ? "#40FFFFFF" : "transparent")

    }

    indicator: Image {
        id: image
        width: imageWidth
        height: imageHeight
        sourceSize: isSVGImage ? Qt.size(width, height) : undefined
        anchors.centerIn: parent
        source: root.imageSource
        mipmap: true
    }

    ColorOverlay {
        id: mask

        anchors.fill: image
        source: image
        color: circleWidth > 0 ? (checked ? "white":root.maskColor): root.maskColor
        //color: circleWidth > 0 ? (_checked ? "white":root.maskColor): root.maskColor //enabled ? root.maskColor : "grey"

    }

    function getAppProperty (appProperty, fallback) {
        if (!fallback) fallback = ""
        try {
            return appProperty
        } catch (err) {
            return fallback
        }
    }

    function units(num) {
        return num ? num * AppFramework.displayScaleFactor : num
    }

}
