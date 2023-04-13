import QtQuick 2.0

Item {
    property color blk_000: "#FFFFFF"//app.isDarkMode ? "#2B2B2B" : "#FFFFFF"
    property color blk_010: "#F3F3F4"//app.isDarkMode ? "#353535" : "#F3F3F4"
    property color blk_140: "#6A6A6A"//app.isDarkMode ? "#BFBFBF" : "#6A6A6A"
    property color blk_200: "#2B2B2B" //app.isDarkMode ? "#FFFFFF" : "#2B2B2B"
    property color blk_020: "#EAEAEA"//app.isDarkMode ? "#353535" : "#EAEAEA"
    readonly property color black_100: "#000000"
    readonly property color black_87: "#DE000000"
    readonly property color black_54: "#8A000000"
    readonly property color black_38: "#61000000"
    readonly property color black_12: "#1F000000"

    // White
    readonly property color white: "#FFFFFFFF"
    readonly property color white_100: "#FFFFFFFF"
    readonly property color white_70: "#B3FFFFFF"
    readonly property color white_50: "#80FFFFFF"
    readonly property color white_copy_icon_background: "#FFD1D1D1"

    // Grey
    readonly property color grey: "#EFEFEF"
    readonly property color grey_100 : "#808080"

    property string defaultPrimaryColor:app.primaryColor > "" ? app.primaryColor : "#8F499C"
    property color primary_color:(app.primaryColor > "" ? app.primaryColor : defaultPrimaryColor)
    //app.isDarkMode ? "#DFA8FF" : (appPrimaryColor > "" ? appPrimaryColor : defaultPrimaryColor)
    // gradient colors
    property color gradient_start: app.primaryColor > "" ? app.primaryColor : "#3023AE"
    property color gradient_end:  app.primaryColor > "" ? app.primaryColor : "#C86DD7"

    // loader gradient colors
    property color loader_gradient_start: "#6D23AE"
    property color loader_gradient_end: "#C86DD7"
    readonly property color mask: "#66000000"
    readonly property color black: "#000000"
    readonly property color transparent: "transparent"
    readonly property color shadowDark: "#c5c5c5"
    readonly property color ripple: "#14000000"


}
