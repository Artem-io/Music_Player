import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import AudioPlayer 1.0

Item {
    id: root
    width: 500
    height: 530

    property int textSize: 11
    property color textColor: "#E6E6E6"
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

    TextField {
        id: searchField
        width: parent.width-10
        height: 40
        placeholderText: "Search..."
        color: root.textColor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: roundCorners.top
        anchors.topMargin: 5
        z: roundCorners.z+1

        background: Rectangle {
            color: "#404040"
            radius: 20
            border.color: "transparent"
        }

        onTextChanged: {
            searchQuery = text;
            //audioPlayer.setCurSongList(filteredFiles);
        }

    }

    Rectangle {
        id: roundCorners
        height: 530
        width: 500
        radius: 20
        color: "#2B2B2B"

        ListView {
            id: fileList
            model: filteredFiles
            clip: true
            anchors.topMargin: 50
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5

            delegate: Rectangle {
                width: fileList.width
                height: 40
                radius: 10
                color: audioPlayer.curSongList[audioPlayer.curId] === modelData ? "#595959" : "#2B2B2B"

                Row {
                    anchors.centerIn: parent
                    spacing: 50

                    Text { // index
                        text: index + 1;
                        width: 20
                        color: root.textColor
                        font.pointSize: root.textSize
                    }

                    Text { // song name
                        text: modelData.split('/').pop().substring(0, modelData.split('/').pop().lastIndexOf('.'))
                        width: 200
                        elide: Text.ElideRight
                        color: root.textColor
                        font.pointSize: root.textSize
                    }

                    Image_Button {
                        id: like
                        width: 20
                        height: 20
                        onClicked: audioPlayer.toggleFavourite(modelData)
                        image: audioPlayer.favourites.includes(modelData) ? "assets/icons/heart_filled.png" : "assets/icons/heart_empty.png"
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
                        color: root.textColor
                        font.pointSize: root.textSize
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
                id: control
                size: 0.3
                position: 0.2

                contentItem: Rectangle {
                    width: 6
                    height: 100
                    radius: width / 2
                    color: control.pressed ? "grey" : "lightgrey"
                    opacity: control.policy === ScrollBar.AlwaysOn || (control.active && control.size < 1.0) ? 0.75 : 0
                    Behavior on opacity {
                        NumberAnimation {}
                    }
                }
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
