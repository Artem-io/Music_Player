import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Item {
    id: root
    width: 250
    height: 500
    property string selectedTab: "Library"
    property color textColor: "white"

    anchors {
        bottom: bottomBar.top
        bottomMargin: 30
        left: parent.left
        leftMargin: 30
    }

    Rectangle {
        id: sideBar
        color: "#2B2B2B"
        radius: 20
        anchors.fill: parent

        Column {
            anchors.fill: parent
            spacing: 10

            Repeater {
                model: ["Library", "Favourites", "Playlists", "Settings"]

                Button {
                    width: parent.width
                    height: 50
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 16
                        color: textColor
                    }
                    flat: true
                    onClicked: root.selectedTab = modelData
                }
            }
        }
    }
}
