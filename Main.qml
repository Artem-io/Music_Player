import QtQuick
import QtQuick.Dialogs
import QtQuick.Controls.Material
import AudioPlayer 1.0

Window {
    id: root
    width: 1536
    height: 793
    visible: true
    visibility: Window.Maximized
    title: qsTr("Music Player")
    color: "#1E2124"
    property color textColor: "#E6E6E6"
    property real scaleFactor: Window.width/1536

    AudioPlayer { id: audioPlayer }

    Side_Bar { id: sideBar }

    Loader {
        id: contentLoader
        anchors.bottom: bottomBar.top
        anchors.horizontalCenter: parent.horizontalCenter
        // width: 500 * scaleFactor
        // height: 530 * scaleFactor

        sourceComponent: {
            switch (sideBar.selectedTab) {
            case "Library": return libraryComponent
            case "Favorites": return likedComponent
            case "Playlists": return playlistComponent
            case "Settings": return settings
            default: return libraryComponent
            }
        }

        onLoaded: {
            if (sideBar.selectedTab === "Library") audioPlayer.setCurSongList(audioPlayer.filePaths)
            else if (sideBar.selectedTab === "Favorites")
                audioPlayer.setCurSongList(audioPlayer.favourites)
        }
    }

    Component {
        id: libraryComponent
        File_List {
            id: library
            baseSource: audioPlayer.filePaths
        }
    }

    Component {
        id: likedComponent
        File_List {
            id: liked
            baseSource: audioPlayer.favourites
        }
    }

    Component {
        id: playlistComponent
        PlaylistView {
            anchors.centerIn: parent
        }
    }

    Component {
        id: settings

        Rectangle {
            height: 550
            width: 500
            y: 20
            radius: 20
            color: "#36393F"

            Switch {
                id: crossfade
                checked: audioPlayer.crossfadeEnabled // Bind to audioPlayer.crossfadeEnabled
                Text {
                    anchors.left: parent.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Crossfade"
                    color: root.textColor
                    font.pointSize: 12
                }

                anchors {
                    top: parent.top
                    left: parent.left
                    topMargin: 20
                    leftMargin: 20
                }

                onCheckedChanged: {
                    audioPlayer.setCrossfadeEnabled(checked) // Update audioPlayer.crossfadeEnabled
                }
            }
        }
    }

    Bottom_Bar {
        id: bottomBar
        anchors.bottom: parent.bottom
        width: parent.width
    }

    FileDialog {
        id: fileDialog
        nameFilters: ["Audio Files (*.mp3 *.m4a *.wav *.aac *.opus)"]
        fileMode: FileDialog.OpenFiles
        onAccepted: audioPlayer.setFiles(fileDialog.selectedFiles)
    }

    Button {
        id: addFiles
        text: "Choose Folder"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        onClicked: fileDialog.open()
    }
}
