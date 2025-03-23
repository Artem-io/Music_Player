import QtQuick
import QtQuick.Controls

Rectangle {
    id: sideBar
    width: 200
    height: parent.height
    color: "#333333"

    property string selectedTab: "Library"

    Column {
        anchors.fill: parent
        spacing: 10

        Repeater {
            model: ["Library", "Favourites", "Settings"]

            Button {
                width: parent.width
                height: 50
                text: modelData
                flat: true
                font.pixelSize: 16
                // Use palette for color instead of contentItem
                palette.buttonText: sideBar.selectedTab === modelData ? "white" : "#cccccc"
                // Use Rectangle as an overlay instead of background
                Rectangle {
                    anchors.fill: parent
                    color: sideBar.selectedTab === modelData ? "#555555" : "transparent"
                    z: -1  // Behind the button text
                }
                onClicked: sideBar.selectedTab = modelData
            }
        }
    }
}
