import QtQuick 2.0

Item {
    id:mapPageStates


    states: [
        State{
            name: "shapeEditMode"
            AnchorChanges {
                target: mapView
                anchors.top: parent.top
            }


            PropertyChanges {
                target: mapView
                x:0
                width:pageView.width
                height:pageView.height - app.units(80) - 0.5 * notchHeight //- app.notchHeight//pageView.height * 0.4
                //height:parent.height  - app.units(80) //- notchHeight
            }


            PropertyChanges{
                target: mapPageHeader
                y:-app.headerHeight
                visible:true
                // height: //app.headerHeight + app.notchHeight
            }

            PropertyChanges{
                target: panelDockItem
                x:0
                y:pageView.height //- 50
                width:pageView.width
                height:0//app.notchHeight//pageView.height * 0.05
                color:"transparent"




            }




        },




        State {
            name: "anchorleft"

            AnchorChanges {
                target: mapView
                anchors.left: parent.left
            }
            PropertyChanges {
                target: offlineRouteDockItem
                x:mapView.width

            }
            PropertyChanges {
                target: spatialSearchDockItem
                x:mapView.width

            }
            PropertyChanges {
                target: searchDockItem
                x:mapView.width


            }
            PropertyChanges {
                target: panelDockItem
                x:mapView.width

            }


        },
        State{
            name: "anchorright"
            AnchorChanges {
                target: mapView
                anchors.right: parent.right
            }
            PropertyChanges {
                target: offlineRouteDockItem
                x:0

            }
            PropertyChanges {
                target: spatialSearchDockItem
                x:0

            }
            PropertyChanges {
                target: searchDockItem
                x:0


            }
            PropertyChanges {
                target: panelDockItem
                x:0

            }


        },
        State{
            name: "anchorbottom"
            AnchorChanges {
                target: mapView
                anchors.top: parent.top
                anchors.left:parent.left
            }
            PropertyChanges{
                target: mapView

                width:pageView.width
                height:pageView.height * 0.45//0.6

            }

            AnchorChanges {
                target: offlineRouteDockItem
                anchors.bottom: parent.bottom
            }
            AnchorChanges {
                target: spatialSearchDockItem
                anchors.bottom: parent.bottom
            }
            AnchorChanges {
                target: panelDockItem
                anchors.bottom: parent.bottom
            }
            PropertyChanges{
                target: panelDockItem
                x:0
                width:pageView.width
                height:pageView.height * 0.55
                color:"transparent"

            }


            PropertyChanges {
                target: offlineRouteDockItem
                x:0

                width:pageView.width
                height:pageView.height * 0.55//0.4
                color:"transparent"

            }
            PropertyChanges {
                target: spatialSearchDockItem
                x:0

                width:pageView.width
                height:pageView.height * 0.55//0.4
                color:"transparent"

            }
        },
        State{
            name: "anchorbottomReduced"
            AnchorChanges {
                target: mapView
                anchors.top: parent.top
            }
            AnchorChanges {
                target: offlineRouteDockItem
                anchors.bottom: parent.bottom
            }
            PropertyChanges {
                target: mapView
                x:0
                //y:400
                width:pageView.width
                height:pageView.height - app.units(50)//pageView.height * 0.4
                //color:"transparent"

            }

            PropertyChanges {
                target: pageView
                anchors.bottomMargin: app.isIphoneX ? app.units(16):0

            }


            PropertyChanges {
                target: offlineRouteDockItem
                x:0
                //y:400
                width:pageView.width
                height:app.units(50)//pageView.height * 0.4
                color:"transparent"

            }
        },
        State{
            name: "anchortop"


            AnchorChanges {
                target: offlineRouteDockItem
                anchors.top: parent.top
            }
            AnchorChanges {
                target: spatialSearchDockItem
                anchors.top: parent.top
            }
            AnchorChanges {
                target: searchDockItem
                anchors.top: parent.top
            }
            AnchorChanges {
                target: panelDockItem
                anchors.top: parent.top
            }
            PropertyChanges {
                target: mapView
                x:0
                //y:400
                width:0//pageView.width
                height:0//pageView.height - app.units(50)//pageView.height * 0.4
                //color:"transparent"


            }


            PropertyChanges {
                target: panelDockItem
                x:0
                width:pageView.width
                height:pageView.height

            }

            PropertyChanges {
                target: searchDockItem
                x:0
                width:pageView.width
                height:pageView.height
            }

            PropertyChanges {
                target: offlineRouteDockItem
                x:0
                width:pageView.width
                height:pageView.height


            }

            PropertyChanges {
                target: spatialSearchDockItem
                x:0
                width:pageView.width
                height:pageView.height


            }
        }
        ,

        State{
            name: "anchorTopReduced"


            AnchorChanges {
                target: mapView
                anchors.top: parent.top
            }
            AnchorChanges {
                target: panelDockItem
                anchors.bottom: parent.bottom
            }
            PropertyChanges {
                target: mapView
                x:0

                width:pageView.width
                height:pageView.height * 0.2


            }


            PropertyChanges {
                target: panelDockItem
                x:0
                width:pageView.width
                height:pageView.height * 0.8


            }


        }

    ]


}
