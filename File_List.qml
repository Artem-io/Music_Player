import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: Math.min(500, parent.width * 0.8)
    height: Math.min(400, parent.height * 0.5)

    Rectangle {
        id: fileListContainer
        anchors.fill: parent

        ListView {
            id: fileList
            anchors.fill: parent
            model: audioPlayer.filePaths
            clip: true

            delegate: Rectangle {
                width: fileList.width
                height: 40
                color: index === audioPlayer.curId ? "lightblue" : "white"
                border.color: "gray"

                Row {
                    anchors.centerIn: parent
                    spacing: 20

                    Text { // Index
                        text: index + 1
                        width: 20
                    }

                    Text { // File Name
                        text: {
                            let filename = modelData.split('/').pop();
                            return filename.substring(0, filename.lastIndexOf('.'));
                        }
                        width: 360
                        elide: Text.ElideRight
                    }

                    Text { // Song Duration
                        text: {
                            if (index >= 0 && index < audioPlayer.fileDurations.length) {
                                let duration = audioPlayer.fileDurations[index];
                                if (duration > 0) {
                                    return formatTime(duration);
                                }
                                else if (duration === -2) {
                                    return "Invalid";
                                }
                                else {
                                    return "Loading...";
                                }
                            }
                            return "0:00";
                        }
                        width: 60
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        audioPlayer.setCurId(index);
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
