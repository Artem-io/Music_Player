import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Effects

Item {
    id: root
    width: 250
    height: 500
    property string selectedTab: "Library"
    property color textColor: "#E6E6E6"

    anchors {
        bottom: bottomBar.top
        bottomMargin: 30
        left: parent.left
        leftMargin: 30
    }

    Rectangle {
        id: sideBar
        anchors.fill: parent
        color: "#36393F"
        radius: 20

        Column {
            anchors.fill: parent
            anchors.topMargin: 15
            spacing: 10

            Repeater {
                id: tabRepeater
                model: ["Library", "Favorites", "Playlists", "Settings"]

                Button {
                    id: tab
                    width: parent.width - 50
                    height: 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    scale: root.selectedTab === modelData ? 1.05 : 1.15

                    Behavior on scale {
                        NumberAnimation {
                            duration: 100
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 17
                        color: textColor
                        font.bold: true
                    }

                    background: Rectangle {
                        id: back
                        color: root.selectedTab === modelData ? Qt.rgba(0.1, 0.1, 0.1, 0.5) : "transparent"
                        anchors.fill: parent
                        radius: 10

                        Behavior on color {
                            ColorAnimation {
                                duration: 50
                            }
                        }
                    }

                    flat: true
                    onClicked: root.selectedTab = modelData

                    Image {
                        scale: 0.45
                        anchors.verticalCenter: parent.verticalCenter
                        source: {
                            switch(modelData) {
                            case "Library": return root.selectedTab === "Library" ?
                                                "assets/icons/library_clicked.png" : "assets/icons/library.png"
                            case "Playlists": return root.selectedTab === "Playlists" ?
                                                  "assets/icons/playlists_clicked.png" : "assets/icons/playlists.png"
                            case "Settings": return root.selectedTab === "Settings" ?
                                                 "assets/icons/settings_clicked.png" : "assets/icons/settings.png"
                            case "Favorites": return root.selectedTab === "Favorites" ?
                                                  "assets/icons/favourites_clicked.png" : "assets/icons/favourites.png"
                            }
                        }
                    }
                }
            }
        }
    }
}
