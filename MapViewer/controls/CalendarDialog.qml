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

/*
* This file contains the UI and controller for the CalendarDialog component which is used to select Date and time from the XCalendar.qml and XTimePicker.qml files.
* This UI component is mainly used in modifying date and time in Attribute Editing (If available) and in Filters page (If supported) to filter results based on Date
*/
import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Controls.Private 1.0
import QtQuick.Layouts 1.3
import QtQuick.Extras 1.4

import ArcGIS.AppFramework 1.0

import QtQuick.Controls 2.1 as NewControls
import QtQuick.Controls.Material 2.1 as MaterialStyle
import "../widgets"

NewControls.Dialog {
    id: calendarAndTimeDialog

    width: app.width*0.8
    height: Math.min(app.height * 0.8, 400)
    x: (app.width - width) / 2 - parent.x
    y: (app.height - height) / 2 - parent.y
    visible: false
    padding: 0
    spacing: 0
    topPadding: 0
    bottomPadding: 0
    MaterialStyle.Material.theme: theme
    modal: true
    closePolicy: NewControls.Dialog.NoAutoClose
    MaterialStyle.Material.accent: MaterialStyle.Material.theme === MaterialStyle.Material.Dark? "#E0E0E0" : primaryColor
    LayoutMirroring.enabled: app.isRightToLeft
    LayoutMirroring.childrenInherit: app.isRightToLeft

    property bool isMiniMode: calendarAndTimeDialog.height < 399
    property int theme: MaterialStyle.Material.Light

    // Initializing with new Date() causes bugs in apString in the XTimePicker module due to the currentIndexChanged getting reset
    property var selectedDateAndTime: getInitialDateAndTime()
    property real dateMilliseconds: selectedTime ? selectedDateAndTime.valueOf() : 0
    property color primaryColor: "#009688"
    property alias swipeViewIndex: swipeView.currentIndex
    property bool is24HoursFormat: false
    property bool showTimeDialog: false

    Component.onCompleted: {
        // To find out if the current time format of the set region is in 12 or 24 hours format
        is24HoursFormat = Qt.locale().timeFormat().split(":")[0] === "HH" || Qt.locale().timeFormat().split(":")[0] === "H";
    }

    /*
    * desc => set Minimum date for date range validation in Filters page
    * input =>  var minDate (date object)
    */
    function setMinimumDate(minDate){
        if(minDate > ""){
            calendarPickerLoader.item.minimumDate = minDate
        }
    }

    /*
    * desc => set Maximum date for date range validation in Filters page
    * input =>  var maxDate (date object)
    */
    function setMaximumDate(maxDate){
        if(maxDate > ""){
           calendarPickerLoader.item.maximumDate = maxDate
        }
    }

    /*
    * desc => update date and time when modified from the FiltersPage
    */
    function updateDateAndTime(){
        calendarPickerLoader.item.selectedDate = selectedDateAndTime;
        timePickerLoader.item.selectedTime = selectedDateAndTime;
    }

    /*
    * desc => Initialize CalendarDialog with current date and time values
    */
    function getInitialDateAndTime() {
        let initialDateAndTime = new Date();
        initialDateAndTime.setHours(initialDateAndTime.getHours() + 12)
        if ( !is24HoursFormat && initialDateAndTime.getHours() >= 12 ) {
            initialDateAndTime.setHours(initialDateAndTime.getHours() - 12);
        }
        return initialDateAndTime;
    }

    header: Rectangle {
        width: parent.width
        height: calendarAndTimeDialog.height / 6
        color: MaterialStyle.Material.theme === MaterialStyle.Material.Dark? Qt.lighter(app.backgroundColor, 1.2) : primaryColor
        clip: true

        RowLayout{
            anchors.fill: parent
            anchors.margins: 8 * AppFramework.displayScaleFactor
            LayoutMirroring.enabled: app.isRightToLeft
            LayoutMirroring.childrenInherit: app.isRightToLeft

            Item{
                Layout.preferredWidth: parent.width / 5 * 3
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    opacity: swipeView.currentIndex == 0 ? 1 : 0.7
                    clip: true
                    spacing: 0

                    NewControls.Label {
                        Layout.preferredHeight: parent.height / 2.5
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        text: calendarPickerLoader.item.selectedDate.toLocaleDateString(calendarPickerLoader.item.__locale, "yyyy")
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        color: "white"
                        padding: 0
                    }

                    NewControls.Label {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        fontSizeMode: Label.Fit
                        horizontalAlignment: Text.AlignLeft
                        text:calendarPickerLoader.item.selectedDate.toLocaleDateString(calendarPickerLoader.item.__locale, "ddd, MMM d")
                        verticalAlignment: Text.AlignVCenter
                        padding: 0
                        font {
                            bold: true
                        }
                        color: "white"
                    }
                }

                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        if(swipeView.currentIndex === 1) swipeView.decrementCurrentIndex();
                    }
                }
            }

            Item{
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout{
                    anchors.fill: parent
                    opacity: swipeView.currentIndex === 1 ? 1 : 0.7
                    clip: true
                    spacing: 0
                    visible: showTimeDialog

                    NewControls.Label {
                        Layout.preferredHeight: parent.height / 2.5
                        Layout.fillWidth: true

                        text: timePickerLoader.item.apString
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        color: "white"
                        padding: 0
                    }

                    NewControls.Label {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        fontSizeMode: Label.Fit
                        text: timePickerLoader.item.hourString + ":" + timePickerLoader.item.minString
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        padding: 0
                        font {
                            bold: true
                        }

                        color: "white"
                    }
                }

                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        if(swipeView.currentIndex==0) swipeView.incrementCurrentIndex();
                    }
                }
            }
        }

    }

    ColumnLayout {
        anchors.fill: parent

        NewControls.SwipeView{
            id: swipeView

            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0
            padding: 0
            clip: true
            spacing: 0

            Component.onCompleted: {
                swipeView.addItem(calendarPickerLoader)
                if ( showTimeDialog ){
                    swipeView.addItem(timePickerLoader)
                }
            }
        }

        NewControls.PageIndicator {
            id: indicator
            count: swipeView.count
            currentIndex: swipeView.currentIndex
            scale: calendarAndTimeDialog.isMiniMode? 0.5 : 1
            Layout.alignment: Qt.AlignHCenter
            visible: count > 1
        }

        Loader {
            id: timePickerLoader
            sourceComponent: XTimePicker {
                selectedTime: calendarAndTimeDialog.selectedDateAndTime
                primaryColor: calendarAndTimeDialog.primaryColor

                /*
                * @desc => Updates the corresponding required variables when the timeChanged() signal is emitted. This signal is emitted upon time change in the time-picker dialog
                * @param => var selectedTime (date object)
                */
                onTimeChanged: {
                    if ( selectedTime ) {
                        calendarAndTimeDialog.selectedDateAndTime.setHours(selectedTime.getHours());
                        calendarAndTimeDialog.selectedDateAndTime.setMinutes(selectedTime.getMinutes());
                        dateMilliseconds = selectedDateAndTime.valueOf();
                    }
                }
            }
        }

        Loader {
            id: calendarPickerLoader
            sourceComponent: XCalendar{
                isMiniMode: calendarAndTimeDialog.isMiniMode
                selectedDate: calendarAndTimeDialog.selectedDateAndTime
                primaryColor: calendarAndTimeDialog.primaryColor

                /*
                * @desc => Updates the corresponding required variables when the selectedDateChanged() signal is emitted. This signal is emitted upon date change in the date-picker dialog
                */
                onSelectedDateChanged: {
                    calendarAndTimeDialog.selectedDateAndTime.setFullYear(selectedDate.getFullYear());
                    calendarAndTimeDialog.selectedDateAndTime.setDate(selectedDate.getDate());
                    calendarAndTimeDialog.selectedDateAndTime.setMonth(selectedDate.getMonth());
                    dateMilliseconds = selectedDateAndTime.valueOf();
                }
            }
        }
    }

    footer: Rectangle {
        id: item
        width: parent.width
        height: parent.height / 8
        color: "transparent"
        clip: true
        anchors.bottom: parent.Bottom
        radius: 5 * AppFramework.displayScaleFactor

        RowLayout {
            id: footerRow
            anchors.fill: parent
            LayoutMirroring.enabled: app.isRightToLeft
            LayoutMirroring.childrenInherit: app.isRightToLeft

            CustomDialogButton {
                id: todayButton
                primaryColor: calendarAndTimeDialog.primaryColor
                parentHeight: parent.height

                Layout.preferredHeight: parent.height
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 10 * AppFramework.displayScaleFactor
                visible: swipeView.currentIndex === 0
                customText: app.today_string
                onClicked: {
                    calendarPickerLoader.item.selectedDate = new Date();
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            CustomDialogButton {
                id: cancelButton
                parentHeight: parent.height
                Layout.preferredHeight: parent.height
                primaryColor: calendarAndTimeDialog.primaryColor
                customText: app.cancel_string
                onClicked: {
                    calendarAndTimeDialog.reject();
                }
            }

            CustomDialogButton {
                id: okayButton
                parentHeight: parent.height
                Layout.preferredHeight: parent.height
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 10 * AppFramework.displayScaleFactor
                primaryColor: calendarAndTimeDialog.primaryColor
                customText: app.ok_String
                onClicked: {
                if(calendarPickerLoader.item.selectedDate > calendarPickerLoader.item.minimumDate && calendarPickerLoader.item.selectedDate  < calendarPickerLoader.item.maximumDate)
                    calendarAndTimeDialog.accept();
                }
            }
        }
    }
}
