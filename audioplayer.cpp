#include "audioplayer.h"

AudioPlayer::AudioPlayer(QObject *parent) : QObject(parent), curId(-1)
{
    audioOutput = new QAudioOutput(this);
    player = new QMediaPlayer(this);
    player->setAudioOutput(audioOutput);
    audioOutput->setVolume(0.2);

    connect(player, &QMediaPlayer::playbackStateChanged, this, &AudioPlayer::playingStateChanged);
    connect(player, &QMediaPlayer::positionChanged, this, &AudioPlayer::positionChanged);

    loadLastFiles();
    loadFavourites();
    loadPlaylists(); // new
    curSongList=filePaths; // whole library by default
}

void AudioPlayer::setFiles(const QStringList& fileUrls)
{
    filePaths.clear();
    fileDurations.clear();

    for (const QString &url : fileUrls) {
        QString localFile;
        if (url.startsWith("file://")) localFile = QUrl(url).toLocalFile();
        else localFile = url;

        if (!localFile.isEmpty() && QFileInfo(localFile).exists()) {
            filePaths.append(localFile);
            player->setSource(QUrl::fromLocalFile(localFile));
            while (player->mediaStatus() != QMediaPlayer::LoadedMedia &&
                   player->mediaStatus() != QMediaPlayer::InvalidMedia) {
                QCoreApplication::processEvents();
            }
            fileDurations.append(player->duration());
            //qDebug() << "Added file:" << localFile << "Duration:" << player->duration();
        }
        else qDebug() << "Skipped invalid or missing file:" << url;
    }

    if (!filePaths.isEmpty()) {
        curId = 0;
        curSongList = filePaths; // Reset to full library when new files are loaded
        player->setSource(QUrl::fromLocalFile(filePaths[curId]));
        saveFilePaths(filePaths);
        emit filePathsChanged();
        emit fileDurationsChanged();
        emit curIdChanged();
        emit curSongListChanged();
    }
    else {
        curId = -1;
        curSongList.clear();
        emit filePathsChanged();
        emit fileDurationsChanged();
        emit curIdChanged();
        emit curSongListChanged();
    }
}

void AudioPlayer::setCurId(int id)
{
    if (curId != id && id >= 0 && id < curSongList.size()) {  // Check against currentPlaylist
        curId = id;
        player->setSource(QUrl::fromLocalFile(curSongList[curId]));
        emit curIdChanged();
    }
}

void AudioPlayer::setCurSongList(const QStringList& playlist)
{
    if (curSongList != playlist) {
        curSongList = playlist;
        curId = -1; // Reset current ID
        if (!curSongList.isEmpty()) {
            setCurId(0); // Start with first song
        }
        emit curSongListChanged();
    }
}

void AudioPlayer::togglePlayPause()
{
    if (player->playbackState() == QMediaPlayer::PlayingState) player->pause();
    else player->play();
    emit playingStateChanged();
}

void AudioPlayer::setPosition(int pos)
{
    player->setPosition(pos);
    emit positionChanged(pos);
}

void AudioPlayer::setVolume(float vol)
{
    audioOutput->setVolume(vol);
    emit volumeChanged();
}

void AudioPlayer::loadLastFiles()
{
    QStringList lastFiles = getLastFilePaths();
    if (!lastFiles.isEmpty()) setFiles(lastFiles);
}

void AudioPlayer::saveFilePaths(const QStringList &filePaths)
{
    QSettings settings;
    settings.setValue("lastFiles", filePaths);
}

QStringList AudioPlayer::getLastFilePaths()
{
    QSettings settings;
    QStringList lastFiles = settings.value("lastFiles", QStringList()).toStringList();
    return lastFiles;
}

void AudioPlayer::toggleFavourite(const QString& filePath)
{
    if (favourites.contains(filePath)) favourites.removeAll(filePath);
    else favourites.append(filePath);

    saveFavourites();
    emit favouritesChanged();
}

void AudioPlayer::saveFavourites()
{
    QSettings settings;
    settings.setValue("favourites", favourites);
}

void AudioPlayer::loadFavourites()
{
    QSettings settings;
    favourites = settings.value("favourites", QStringList()).toStringList();
}

void AudioPlayer::addPlaylist(const QString& name, const QStringList& files)
{
    playlists[name] = files; // Implicitly converts QStringList to QVariant
    savePlaylists();
    emit playlistsChanged();
}

void AudioPlayer::removePlaylist(const QString& name)
{
    playlists.remove(name);
    savePlaylists();
    emit playlistsChanged();
}

void AudioPlayer::savePlaylists()
{
    QSettings settings;
    settings.beginGroup("playlists");
    settings.remove("");
    for (const QString& name : playlists.keys()) {
        settings.setValue(name, playlists[name].toStringList()); // Extract QStringList from QVariant
    }
    settings.endGroup();
}

void AudioPlayer::loadPlaylists()
{
    QSettings settings;
    settings.beginGroup("playlists");
    QStringList playlistNames = settings.childKeys();
    for (const QString& name : playlistNames) {
        playlists[name] = settings.value(name).toStringList(); // Store as QVariant
    }
    settings.endGroup();
}
