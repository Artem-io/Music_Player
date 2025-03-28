import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import AudioPlayer 1.0

Item {
    id: root
    width: 500
    height: 400

    property string searchQuery: ""
    property var filteredFiles: {
        if (searchQuery === "") return audioPlayer.filePaths;
        else {
            return audioPlayer.filePaths.filter(function(filePath) {
                let fileName = filePath.split('/').pop().toLowerCase();
                return fileName.includes(searchQuery.toLowerCase());
            });
        }
    }

    Rectangle {
        id: fileListContainer
        anchors.fill: parent

        TextField {
            id: searchField
            width: parent.width
            height: 40
            placeholderText: "Search..."
            onTextChanged: {
                searchQuery = text;
                audioPlayer.setCurSongList(filteredFiles);
            }
        }

        ListView {
            id: fileList
            anchors {
                top: searchField.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            model: filteredFiles
            clip: true

            delegate: Rectangle {
                width: fileList.width
                height: 40
                color: audioPlayer.curSongList[audioPlayer.curId] === modelData ? "lightblue" : "white"
                border.color: "gray"

                Row {
                    anchors.centerIn: parent
                    spacing: 20

                    Text { text: index + 1; width: 20 } // index
                    Text { // song name
                        text: modelData.split('/').pop().substring(0, modelData.split('/').pop().lastIndexOf('.'))
                        width: 200
                        elide: Text.ElideRight
                    }

                    Image_Button {
                        id: like
                        width: 30
                        height: 30
                        onClicked: audioPlayer.toggleFavourite(modelData)
                        image: audioPlayer.favourites.includes(modelData)? "assets/icons/heart_filled.png":"assets/icons/heart_empty.png"
                    }

                    Text { // duration
                        text: {
                            let originalIndex = audioPlayer.filePaths.indexOf(modelData);
                            if (originalIndex >= 0 && originalIndex < audioPlayer.fileDurations.length) {
                                let duration = audioPlayer.fileDurations[originalIndex];
                                if (duration > 0) return formatTime(duration);
                                else if (duration === -2) return "Invalid";
                                else return "Loading...";
                            }
                            return "0:00";
                        }
                        width: 60
                    }
                }

                MouseArea {
                    width: parent.width - like.x
                    height: parent.height

                    onClicked: {
                        audioPlayer.setCurId(filteredFiles.indexOf(modelData));
                        audioPlayer.togglePlayPause();
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 20
            }
        }
    }

    function formatTime(ms) {
        let seconds = Math.floor(ms / 1000);
        let minutes = Math.floor(seconds / 60);
        seconds = seconds % 60;
        return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds);
    }
}
