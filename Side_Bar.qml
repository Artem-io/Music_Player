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
                        font.pixelSize: 17
                        color: textColor
                        font.bold: true
                    }
                    flat: true
                    onClicked: root.selectedTab = modelData

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
