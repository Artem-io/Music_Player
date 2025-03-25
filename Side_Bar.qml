import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: 250
    height: 500
    property string selectedTab: "Library"

    anchors {
        bottom: bottomBar.top
        bottomMargin: 30
        left: parent.left
        leftMargin: 30
    }

    Rectangle {
        id: sideBar
        color: "grey"
        radius: 20
        anchors.fill: parent

        Column {
            anchors.fill: parent
            spacing: 10

            Repeater {
                model: ["Library", "Favourites", "Playlists", "Settings"] // Added Playlists

                Button {
                    width: parent.width
                    height: 50
                    text: modelData
                    flat: true
                    font.pixelSize: 16
                    palette.buttonText: root.selectedTab === modelData ? "white" : "#cccccc"
                    Rectangle {
                        anchors.fill: parent
                        color: root.selectedTab === modelData ? "#555555" : "transparent"
                        z: -1
                    }
                    onClicked: root.selectedTab = modelData
                }
            }
        }
    }
}
