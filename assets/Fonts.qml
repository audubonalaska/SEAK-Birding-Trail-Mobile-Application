import QtQuick 2.0

Item {
 property var mediumFontPath: app.info.propertyValue("mediumFontTTF", "assets/fonts/OpenSans-Regular.ttf")
 property var regularFontPath: app.info.propertyValue("regularFontTTF", "assets/fonts/OpenSans-Regular.ttf")
     property alias bodyAccent: bodyAccent
    property alias bodyRegular: bodyRegular
    property alias bodySecondary: bodySecondary

  property alias subtitle: subtitle
  property alias headerAccent: headerAccent


// Regular
    FontLoader {
        id: fontFamily_Regular
        source: app.folder.fileUrl(regularFontPath)
    }
 // Medium
    FontLoader {
        id: fontFamily_Medium
        source: app.folder.fileUrl(mediumFontPath)
    }

    Item {
        id: headerAccent
        readonly property alias textFontFamily: fontFamily_Medium.name
        readonly property real textSize: 20 * scaleFactor
        readonly property color textColor: "#2B2B2B"
    }
     Item {
        id: bodyAccent
        readonly property alias textFontFamily: fontFamily_Medium.name
        readonly property real textSize: 14 * scaleFactor
        readonly property color textColor: "#2B2B2B"
    }

    Item {
        id: bodyRegular
        readonly property alias textFontFamily: fontFamily_Regular.name
        readonly property real textSize: 14 * scaleFactor
        readonly property color textColor: "#2B2B2B"
    }

    Item {
        id: bodySecondary
        readonly property alias textFontFamily: fontFamily_Regular.name
        readonly property real textSize: 14 * scaleFactor
        readonly property color textColor: "#6A6A6A"
    }

 Item {
        id: subtitle
        readonly property alias textFontFamily: fontFamily_Medium.name
        readonly property real textSize: 16 * scaleFactor
        readonly property color textColor: "#2B2B2B"
    }

}
