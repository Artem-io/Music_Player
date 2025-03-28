import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import AudioPlayer 1.0

Item {
    id: root
    width: parent.width
    height: 100
    anchors.bottom: parent.bottom
    property color textColor: "white"

    Rectangle {
        id: bottomBar
        anchors.fill: parent
        color: "#171717"
        property int butWidth: 30
        property int butHeight: 32

        Row {
            id: row
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8
            spacing: 30

            Image_Button {
                id: prev
                enabled: audioPlayer.curId > 0
                width: bottomBar.butWidth
                height: bottomBar.butHeight
                scale: -1

                image: enabled? "assets/icons/next_track.png" : "assets/icons/next_track_unavailable.png"
                onClicked: {
                    audioPlayer.setCurId(audioPlayer.curId - 1);
                    if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause();
                }
            }

            Image_Button {
                id: playPause
                enabled: audioPlayer.curSongList.length > 0
                width: bottomBar.butWidth
                height: bottomBar.butHeight

                image: {
                    if(enabled) audioPlayer.isPlaying ? "assets/icons/pause.png" : "assets/icons/play.png"
                    else "assets/icons/play_unavailable.png"
                }

                onClicked: audioPlayer.togglePlayPause()
            }

            Image_Button {
                id: next
                enabled: audioPlayer.curId < audioPlayer.curSongList.length - 1 &&
                         audioPlayer.curSongList.length > 0
                width: bottomBar.butWidth
                height: bottomBar.butHeight

                image: enabled? "assets/icons/next_track.png" : "assets/icons/next_track_unavailable.png"
                onClicked: {
                    audioPlayer.setCurId(audioPlayer.curId + 1);
                    if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause();
                }
            }
        }

        // Image_Button {
        //     id: shuffle
        //     enabled: audioPlayer.curSongList.length > 1
        //     width: bottomBar.butWidth
        //     height: bottomBar.butHeight
        //     image: enabled? "assets/icons/shuffle.png" : "assets/icons/shuffle_unavailable.png"

        //     onClicked: {
        //         let randomIndex;
        //         do randomIndex = Math.floor(Math.random() * audioPlayer.curSongList.length);
        //         while (randomIndex === audioPlayer.curId)
        //         audioPlayer.setCurId(randomIndex);
        //         audioPlayer.togglePlayPause();
        //     }
        // }

        Slider {
            id: progressSlider
            width: 550
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            from: 0
            to: audioPlayer.curId >= 0 ?
                    audioPlayer.fileDurations[audioPlayer.filePaths.indexOf(audioPlayer.curSongList[audioPlayer.curId])] : 0
            value: audioPlayer.position >= 0 ? audioPlayer.position : 0
            onMoved: audioPlayer.setPosition(value)

            background: Rectangle {
                x: progressSlider.leftPadding
                y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                width: progressSlider.availableWidth
                height: 8
                radius: 20
                color: "black"

                Rectangle {
                    width: progressSlider.visualPosition * parent.width
                    height: parent.height
                    color: "white"
                    radius: 20
                }
            }

            handle: Rectangle {
                color: "transparent"
            }

            Text {
                id: elapsedTime
                color: textColor
                text: formatTime(audioPlayer.position)
                anchors.right: progressSlider.left
                anchors.rightMargin: 10
                anchors.verticalCenter: progressSlider.verticalCenter
            }

            Text {
                id: totalTime
                color: textColor
                text: audioPlayer.curId >= 0 ?
                          formatTime(audioPlayer.fileDurations[audioPlayer.filePaths.indexOf(audioPlayer.curSongList[audioPlayer.curId])]) : "0:00"
                anchors.left: progressSlider.right
                anchors.leftMargin: 10
                anchors.verticalCenter: progressSlider.verticalCenter
            }
        }

        Slider {
            id: volumeSlider
            width: 250
            anchors.right: parent.right
            anchors.rightMargin: 40
            anchors.verticalCenter: progressSlider.verticalCenter
            from: 0
            to: 1
            value: audioPlayer.volume
            onMoved: audioPlayer.setVolume(value)

            background: Rectangle {
                x: volumeSlider.leftPadding
                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                width: volumeSlider.availableWidth
                height: 8
                radius: 20
                color: "black"

                Rectangle {
                    width: volumeSlider.visualPosition * parent.width
                    height: parent.height
                    color: "white"
                    radius: 20
                }
            }

            handle: Rectangle {
                color: "transparent"
            }
        }

        Connections {
            target: audioPlayer
            function onPlayingStateChanged() {
                if (!audioPlayer.isPlaying && audioPlayer.curSongList.length > 0 &&
                        audioPlayer.position >= audioPlayer.fileDurations[audioPlayer.filePaths.indexOf(audioPlayer.curSongList[audioPlayer.curId])] - 100) {
                    if (audioPlayer.curId < audioPlayer.curSongList.length - 1) {
                        audioPlayer.setCurId(audioPlayer.curId + 1);
                        audioPlayer.togglePlayPause();
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
