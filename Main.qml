import QtQuick
import QtQuick.Dialogs
import QtQuick.Controls.Material
import AudioPlayer 1.0

Window {
    id: root
    width: 1536
    minimumWidth: 672
    height: 793
    minimumHeight: 386
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
            if (sideBar.selectedTab === "Library") {
                audioPlayer.setCurSongList(audioPlayer.filePaths);
            }
            else if (sideBar.selectedTab === "Favorites") {
                audioPlayer.setCurSongList(audioPlayer.favourites);
            }
            else if (sideBar.selectedTab === "Playlists") {
            }
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

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 15

                Text {
                    text: "Crossfade"
                    color: root.textColor
                    font.pointSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }

                Switch {
                    id: crossfade
                    checked: audioPlayer.crossfadeEnabled
                    anchors.verticalCenter: parent.verticalCenter
                    onCheckedChanged: audioPlayer.setCrossfadeEnabled(checked)
                }

                Text {
                    text: "Duration: " + (crossfadeDurationSlider.value / 1000).toFixed(1) + "s"
                    color: root.textColor
                    font.pointSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }

                Slider {
                    id: crossfadeDurationSlider
                    width: 150
                    from: 1000
                    to: 10000
                    value: audioPlayer.crossfadeDuration
                    stepSize: 1000
                    enabled: audioPlayer.crossfadeEnabled
                    anchors.verticalCenter: parent.verticalCenter
                    onPressedChanged: if (!pressed) audioPlayer.setCrossfadeDuration(value)
                }
            }
        }
    }

    Bottom_Bar {
        id: bottomBar
        anchors.bottom: parent.bottom
        width: parent.width
    }

    FolderDialog {
        id: folderDialog
        title: "Select Music Folder"
        onAccepted: {
            audioPlayer.setFolder(folderDialog.selectedFolder.toString())
        }
    }

    Button {
        id: addFiles
        text: "Choose Folder"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        onClicked: folderDialog.open()
    }
}
