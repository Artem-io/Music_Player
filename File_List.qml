import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Effects
import AudioPlayer 1.0

Item {
    id: root
    width: 500 * widthFactor
    height: 530 * heightFactor

    property int textSize: 11
    property color textColor: "#E6E6E6"
    property string searchQuery: ""
    property string sortMode: "default"
    property var baseSource: audioPlayer.filePaths
    property real widthFactor: Window.width / 1536
    property real heightFactor: Window.height / 793

    property var filteredFiles: {
        let baseList
        switch(sortMode) {
        case "mostPlayed":
            baseList = audioPlayer.sortMost().filter(file => baseSource.includes(file))
            break
        case "lastPlayed":
            baseList = audioPlayer.sortLast().filter(file => baseSource.includes(file))
            break
        case "lengthAsc":
            baseList = audioPlayer.sortLength(true).filter(file => baseSource.includes(file))
            break
        case "lengthDesc":
            baseList = audioPlayer.sortLength(false).filter(file => baseSource.includes(file))
            break
        default: baseList = baseSource
        }

        if (searchQuery === "") return baseList
        else {
            return baseList.filter(function(filePath) {
                let fileName = filePath.split('/').pop().toLowerCase()
                return fileName.includes(searchQuery.toLowerCase())
            })
        }
    }

    onFilteredFilesChanged: {
        let currentSong = audioPlayer.curId >= 0 && audioPlayer.curId < audioPlayer.curSongList.length ?
                audioPlayer.curSongList[audioPlayer.curId] : ""

        if (filteredFiles.length > 0) {
            audioPlayer.setCurSongList(filteredFiles)
            if (currentSong && filteredFiles.includes(currentSong)) {
                let newIndex = filteredFiles.indexOf(currentSong)
                if (newIndex !== audioPlayer.curId) {
                    audioPlayer.curId = newIndex
                    audioPlayer.curIdChanged()
                }
            }
            else if (audioPlayer.curId >= filteredFiles.length) audioPlayer.setCurId(0)
        }
        else {
            if (!(audioPlayer.isPlaying && currentSong)) {
                audioPlayer.setCurSongList([]);
                audioPlayer.setCurId(-1);
            }
        }
    }

    TextField {
        id: searchField
        width: 300 * widthFactor
        height: 40
        placeholderText: "Search..."
        color: root.textColor
        z: roundCorners.z+1

        background: Rectangle {
            color: "#36393F"
            radius: 20
            border.color: "transparent"
        }
        onTextChanged: searchQuery = text
    }

    ComboBox {
        id: sortCombo
        width: 185 * widthFactor
        height: searchField.height
        anchors.left: searchField.right
        anchors.leftMargin: 15 * widthFactor
        model: [
            "Default",
            "Most Played",
            "Last Played",
            "Shortest First",
            "Longest First"
        ]
        currentIndex: 0
        onCurrentIndexChanged: {
            switch(currentIndex) {
            case 0: sortMode = "default"; break
            case 1: sortMode = "mostPlayed"; break
            case 2: sortMode = "lastPlayed"; break
            case 3: sortMode = "lengthAsc"; break
            case 4: sortMode = "lengthDesc"; break
            }
        }

        background: Rectangle {
            color: "#36393F"
            radius: 20
        }
        clip: true

        contentItem: Text {
            text: sortCombo.displayText
            color: root.textColor
            font.pointSize: 13
            verticalAlignment: Text.AlignVCenter
            leftPadding: 15
            rightPadding: sortCombo.indicator.width + sortCombo.spacing
        }

        popup: Popup {
            y: sortCombo.height + 5
            width: sortCombo.width
            implicitHeight: contentItem.implicitHeight + 10
            padding: 5

            contentItem: ListView {
                id: popupList
                clip: true
                implicitHeight: contentHeight
                model: sortCombo.model
                currentIndex: sortCombo.currentIndex
                spacing: 2

                delegate: ItemDelegate {
                    width: parent.width
                    height: 40

                    contentItem: Text {
                        text: modelData
                        color: root.textColor
                        font.pointSize: 13
                        verticalAlignment: Text.AlignVCenter
                        scale: hovered? 1.05 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    background: Rectangle {
                        color: hovered? "#343840" : "#424752"
                        radius: 16
                    }

                    onClicked: {
                        sortCombo.currentIndex = index
                        sortCombo.popup.close()
                    }
                }
            }

            background: Rectangle {
                color: "#424752"
                radius: 20
            }
        }
    }

    Rectangle {
        id: roundCorners
        height: 550
        width: parent.width
        radius: 20
        clip: true
        color: "#36393F"
        anchors.top: searchField.bottom
        anchors.topMargin: 10

        ListView {
            id: fileList
            model: filteredFiles
            anchors {
                fill: parent
                topMargin: 20
                bottomMargin: 80
                leftMargin: 17 * widthFactor * widthFactor
            }

            Text {
                anchors.centerIn: parent
                text: "No results found"
                color: root.textColor
                font.pointSize: root.textSize + 2
                visible: filteredFiles.length === 0
            }

            delegate: Rectangle {
                width: fileList.width-20
                height: 40
                radius: 10
                color: audioPlayer.curSongList[audioPlayer.curId] === modelData ? "#2E3136" : "#36393F"
                scale: audioPlayer.curSongList[audioPlayer.curId] === modelData ? 1.04 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 110
                        easing.type: Easing.InOutQuad
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    spacing: 50 * Math.pow(widthFactor, 4)

                    Text { // index
                        text: index + 1
                        width: 5
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
                        width: 22
                        height: 22
                        onClicked: audioPlayer.toggleFavourite(modelData)
                        image: audioPlayer.favourites.includes(modelData) ?
                                   "assets/icons/heart_filled.png" : "assets/icons/heart_empty.png"
                    }

                    Text { // duration
                        text: {
                            let originalIndex = audioPlayer.filePaths.indexOf(modelData)
                            if (originalIndex >= 0 && originalIndex < audioPlayer.fileDurations.length) {
                                let duration = audioPlayer.fileDurations[originalIndex]
                                if (duration > 0) return formatTime(duration)
                                else if (duration === -2) return "Invalid"
                                else return "Loading..."
                            }
                            return "0:00"
                        }
                        width: 60
                        color: root.textColor
                        font.pointSize: root.textSize
                    }
                }

                MouseArea {
                    id: mArea
                    width: 315 * widthFactor
                    height: parent.height
                    onClicked: {
                        audioPlayer.setCurSongList(filteredFiles)
                        let newId = filteredFiles.indexOf(modelData)
                        bottomBar.crossfadeStarted=false
                        bottomBar.fadeOutAudioPlayer.stop()
                        bottomBar.fadeInAudioPlayer.stop()
                        bottomBar.fadeInPlayer2.stop()
                        bottomBar.fadeOutPlayer2.stop()
                        audioPlayer.setCurId(newId)
                        if (bottomBar.currentPlayer === "audioPlayer") {
                            if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause()
                            bottomBar.player2.stop()
                            audioPlayer.setVolume(bottomBar.userVolume)
                            bottomBar.audioOutput2.volume = 0
                        } else {
                            bottomBar.player2.source = audioPlayer.curSongList[newId]
                            if (!bottomBar.player2.playing) bottomBar.player2.play()
                            audioPlayer.stop()
                            bottomBar.audioOutput2.volume = bottomBar.userVolume
                            audioPlayer.setVolume(0)
                        }
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
        let seconds = Math.floor(ms / 1000)
        let minutes = Math.floor(seconds / 60)
        seconds = seconds % 60
        return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds)
    }
}
