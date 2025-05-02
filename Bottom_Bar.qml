import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Effects
import AudioPlayer 1.0

Item {
    id: root
    width: parent.width
    height: 100
    anchors.bottom: parent.bottom
    property color textColor: "#D9D9D9"
    property bool repeatEnabled: false

    Rectangle {
        id: bottomBar
        anchors.fill: parent
        color: "#272A2E"
        property int butWidth: 30
        property int butHeight: 32

        Row {
            id: row
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20
            spacing: 27

            Image_Button {
                id: repeat
                width: bottomBar.butWidth
                height: bottomBar.butHeight
                scale: 0.65
                image: root.repeatEnabled? "assets/icons/repeat.png" : "assets/icons/repeat_dis.png"
                onClicked: repeatEnabled = !repeatEnabled
            }

            Image_Button {
                id: prev
                enabled: audioPlayer.curId > 0 && sideBar.selectedTab != "Settings"
                width: bottomBar.butWidth
                height: bottomBar.butHeight
                scale: -next.scale

                image: enabled? "assets/icons/next.png" : "assets/icons/next_un.png"
                onClicked: {
                    audioPlayer.setCurId(audioPlayer.curId - 1)
                    if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause()
                }
            }

            Item {
                width: bottomBar.butWidth
                height: bottomBar.butHeight
                MultiEffect {
                    id: glowEffect
                    anchors.fill: playPause
                    source: playPause
                    blurEnabled: true
                    blurMax: 25
                    blur: 2.0
                    colorization: 1.0
                    colorizationColor: "#E63555"
                    brightness: audioPlayer.isPlaying ? 0.5 : 0.35
                    opacity: playPause.enabled? 1 : 0
                }

                Image_Button {
                    id: playPause
                    enabled: audioPlayer.curSongList.length > 0 && sideBar.selectedTab != "Settings"
                    width: bottomBar.butWidth
                    height: bottomBar.butHeight
                    scale: 1.4

                    image: {
                        if(enabled) audioPlayer.isPlaying ? "assets/icons/pause.png" : "assets/icons/play.png"
                        else "assets/icons/play_un.png"
                    }
                    onClicked: audioPlayer.togglePlayPause()
                }
            }

            Image_Button {
                id: next
                enabled: audioPlayer.curId < audioPlayer.curSongList.length - 1 &&
                         audioPlayer.curSongList.length > 0 && sideBar.selectedTab != "Settings"
                width: bottomBar.butWidth
                height: bottomBar.butHeight
                scale: 0.8

                image: enabled? "assets/icons/next.png" : "assets/icons/next_un.png"
                onClicked: {
                    audioPlayer.setCurId(audioPlayer.curId + 1)
                    if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause()
                }
            }

            Image_Button {
                id: shuffle
                enabled: audioPlayer.curSongList.length > 1 && sideBar.selectedTab != "Settings"
                width: bottomBar.butWidth
                height: bottomBar.butHeight
                scale: repeat.scale
                image: enabled? "assets/icons/shuffle.png" : "assets/icons/shuffle_un.png"

                onClicked: {
                    let randomIndex
                    do randomIndex = Math.floor(Math.random() * audioPlayer.curSongList.length)
                    while (randomIndex === audioPlayer.curId)
                    audioPlayer.setCurId(randomIndex)
                    if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause()
                }
            }
        }

        Slider {
            id: progressSlider
            width: 550
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            from: 0
            to: audioPlayer.curId >= 0 && audioPlayer.curId < audioPlayer.curSongList.length ?
                    audioPlayer.fileDurations[audioPlayer.filePaths.indexOf(audioPlayer.curSongList[audioPlayer.curId])] : 0
            value: audioPlayer.position >= 0 ? audioPlayer.position : 0
            onMoved: audioPlayer.setPosition(value)

            background: Rectangle {
                x: progressSlider.leftPadding
                y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                width: progressSlider.availableWidth
                height: 8
                radius: 20
                color: "#0D0D0D"

                Rectangle {
                    width: progressSlider.visualPosition * parent.width
                    height: parent.height
                    color: "#D9D9D9"
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
                font.bold: true
                font.pointSize: 11
                anchors.right: progressSlider.left
                anchors.rightMargin: 10
                anchors.verticalCenter: progressSlider.verticalCenter
            }

            Text {
                id: totalTime
                color: textColor
                font.pointSize: 11
                font.bold: true
                text: audioPlayer.curId >= 0 && audioPlayer.curId < audioPlayer.curSongList.length ?
                          formatTime(audioPlayer.fileDurations[audioPlayer.filePaths.indexOf(audioPlayer.curSongList[audioPlayer.curId])])
                        : "0:00"
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
                color: "#0D0D0D"

                Rectangle {
                    width: volumeSlider.visualPosition * parent.width
                    height: parent.height
                    color: "#D9D9D9"
                    radius: 20
                }

                Image_Button {
                    image: {
                        if(volumeSlider.value === 0) "assets/icons/volume_null.png"
                        else volumeSlider.value<0.5? "assets/icons/volume_half.png" : "assets/icons/volume_full.png"
                    }
                    width: 25
                    height: 25
                    anchors.right: parent.left
                    anchors.rightMargin: 20
                    y: -7

                    onClicked: audioPlayer.volume? audioPlayer.setVolume(0) : audioPlayer.setVolume(0.2)
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
                    if (repeatEnabled) audioPlayer.togglePlayPause()
                    else if (audioPlayer.curId < audioPlayer.curSongList.length - 1) {
                        audioPlayer.setCurId(audioPlayer.curId + 1)
                        audioPlayer.togglePlayPause()
                    }
                }
            }
        }
    }

    function formatTime(ms) {
        if (isNaN(ms) || ms <= 0) return "0:00"
        let seconds = Math.floor(ms / 1000)
        let minutes = Math.floor(seconds / 60)
        seconds = seconds % 60
        return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds)
    }
}
