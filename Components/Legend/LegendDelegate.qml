import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import Esri.ArcGISRuntime 100.14

import "../../MapViewer/controls" as Controls

Controls.PanelItem {
    property bool showLegend: true
    
    anchors {
        left: parent ? parent.left : undefined
        leftMargin: 1.5 * app.defaultMargin


    }
    visible: showLegend
   // height: showLegend ? app.units(40) : 0
     height: showLegend ? app.units(48) : 0
    imageSource: symbolUrl
    txt: name
}
