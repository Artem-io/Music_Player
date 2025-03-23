// import QtQuick
// import QtQuick.Controls

// Item {
//     id: root
//     width: Math.min(500, parent.width * 0.8)
//     height: Math.min(400, parent.height * 0.5)

//     property string searchQuery: ""

//     property var filteredFiles: {
//         if (searchQuery === "") return audioPlayer.filePaths;
//         else {
//             return audioPlayer.filePaths.filter(function(filePath) {
//                 let fileName = filePath.split('/').pop().toLowerCase();
//                 return fileName.includes(searchQuery.toLowerCase());
//             });
//         }
//     }

//     Rectangle {
//         id: fileListContainer
//         anchors.fill: parent

//         TextField {
//             id: searchField
//             width: parent.width
//             height: 40
//             placeholderText: "Search..."
//             onTextChanged: searchQuery = text;
//         }

//         ListView {
//             id: fileList
//             anchors.top: searchField.bottom
//             anchors.bottom: parent.bottom
//             anchors.left: parent.left
//             anchors.right: parent.right
//             model: filteredFiles
//             clip: true

//             delegate: Rectangle {
//                 width: fileList.width
//                 height: 40
//                 color: audioPlayer.curId === audioPlayer.filePaths.indexOf(modelData) ? "lightblue" : "white"
//                 border.color: "gray"

//                 Row {
//                     anchors.centerIn: parent
//                     spacing: 20

//                     Text { // Index
//                         text: index + 1
//                         width: 20
//                     }

//                     Text { // File Name
//                         text: {
//                             let filename = modelData.split('/').pop();
//                             return filename.substring(0, filename.lastIndexOf('.'));
//                         }
//                         width: 200
//                         elide: Text.ElideRight
//                     }

//                     Button {
//                         id: like
//                         text: "Like"
//                         onClicked: {
//                             //console.log("Like clicked");
//                             mouse.accepted = true;  // Ensure the event is consumed
//                             onClicked: audioPlayer.toggleFavourite(modelData) // may need changes
//                         }
//                     }

//                     Text { // Song Duration
//                         text: {
//                             let originalIndex = audioPlayer.filePaths.indexOf(modelData);
//                             if (originalIndex >= 0 && originalIndex < audioPlayer.fileDurations.length) {
//                                 let duration = audioPlayer.fileDurations[originalIndex];
//                                 if (duration > 0) return formatTime(duration);
//                                 else if (duration === -2) return "Invalid";
//                                 else return "Loading...";
//                             }
//                             return "0:00";
//                         }
//                         width: 60
//                     }
//                 }

//                 MouseArea {
//                     anchors.fill: parent
//                     propagateComposedEvents: true
//                     onPressed: {
//                         if (!like.hovered) {
//                             //console.log("Song clicked");
//                             let originalIndex = audioPlayer.filePaths.indexOf(modelData);
//                             audioPlayer.setCurId(originalIndex);
//                             audioPlayer.togglePlayPause();
//                             mouse.accepted=true
//                         }
//                         else mouse.accepted=false
//                     }
//                 }
//             }

//             ScrollBar.vertical: ScrollBar {
//                 policy: ScrollBar.AsNeeded
//                 width: 20
//             }
//         }
//     }

//     function formatTime(ms) {
//         let seconds = Math.floor(ms / 1000);
//         let minutes = Math.floor(seconds / 60);
//         seconds = seconds % 60;
//         return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds);
//     }
// }


// File_List.qml
import QtQuick
import QtQuick.Controls
import AudioPlayer 1.0

Item {
    id: root
    width: Math.min(500, parent.width * 0.8)
    height: Math.min(400, parent.height * 0.5)

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
            onTextChanged: searchQuery = text
        }

        ListView {
            id: fileList
            anchors.top: searchField.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            model: filteredFiles
            clip: true

            delegate: Rectangle {
                width: fileList.width
                height: 40
                color: audioPlayer.curId === audioPlayer.filePaths.indexOf(modelData) ? "lightblue" : "white"
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
                        width: 200
                        elide: Text.ElideRight
                    }

                    Button {
                        id: like
                        text: audioPlayer.favourites.includes(modelData) ? "★" : "☆"
                        width: 30
                        height: 30
                        onClicked: audioPlayer.toggleFavourite(modelData)
                    }

                    Text { // Song Duration
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
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onPressed: {
                        if (!like.hovered) {
                            let originalIndex = audioPlayer.filePaths.indexOf(modelData);
                            audioPlayer.setCurId(originalIndex);
                            audioPlayer.togglePlayPause();
                            mouse.accepted = true
                        } else {
                            mouse.accepted = false
                        }
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
