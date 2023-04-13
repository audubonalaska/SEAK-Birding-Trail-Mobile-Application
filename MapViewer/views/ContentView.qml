import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import "../controls" as Controls

Rectangle{
    id: contentView
    property var _model:[]
    //color:"grey"
    anchors.fill:parent

    signal checked(string name,bool checked, string identificationIndex)
    signal zoomTo (string lyrname,string identificationIndex)
    Controls.TreeControl {
        anchors.fill: parent
        maxWidth: parent.width
        //anchors.margins: 10
        anchors
        {
            topMargin:0
            rightMargin:0
            leftMargin:0
            bottomMargin:0
        }


        model:_model

        onChecked: {
            contentView.checked(lyrname,checked, identificationIndex)
        }
        onZoomTo: {
            contentView.zoomTo (lyrname,identificationIndex)
        }



    }

}


