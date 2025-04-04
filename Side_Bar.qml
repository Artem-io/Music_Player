import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

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
        color: "#2B2B2B"
        radius: 20
        anchors.fill: parent

        Column {
            anchors.fill: parent
            anchors.topMargin: 15
            spacing: 10

            Repeater {
                id: tabRepeater
                model: ["Library", "Favourites", "Playlists", "Settings"]

                Button {
                    id: tab
                    width: parent.width-50
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
                        color: root.selectedTab === modelData ? "#1F1F1F" : "transparent"
                        anchors.fill: parent
                        radius: 10

                        Behavior on color {
                            ColorAnimation {
                                duration: 50
                                //easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    flat: true
                    onClicked: {
                        root.selectedTab = modelData
                    }

                    Image {
                        id: name
                        scale: 0.45
                        anchors.verticalCenter: parent.verticalCenter
                        source: {
                            switch(modelData) {
                            case "Library": return root.selectedTab==="Library"?
                                                "assets/icons/library_clicked.png" : "assets/icons/library.png"
                            case "Playlists": return root.selectedTab==="Playlists"?
                                                  "assets/icons/playlists_clicked.png" : "assets/icons/playlists.png"
                            case "Settings": return root.selectedTab==="Settings"?
                                                 "assets/icons/settings_clicked.png" : "assets/icons/settings.png"
                            case "Favourites": return root.selectedTab==="Favourites"?
                                                   "assets/icons/favourites_clicked.png" : "assets/icons/favourites.png"
                            }
                        }
                    }
                }
            }
        }
    }
}
