#include "audioplayer.h"

AudioPlayer::AudioPlayer(QObject *parent) : QObject(parent), curId(-1)
{
    audioOutput = new QAudioOutput(this);
    player = new QMediaPlayer(this);
    player->setAudioOutput(audioOutput);
    audioOutput->setVolume(0.2);

    connect(player, &QMediaPlayer::playbackStateChanged, this, &AudioPlayer::playingStateChanged);
    connect(player, &QMediaPlayer::positionChanged, this, &AudioPlayer::positionChanged);

    qRegisterMetaType<PlayCountMap>("PlayCountMap");
    qRegisterMetaType<LastPlayedMap>("LastPlayedMap");

    loadLastFiles();
    loadFavourites();
    loadPlaylists();
    loadPlayData();
    curSongList=filePaths;
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
        }
        else qDebug() << "Skipped invalid or missing file:" << url;
    }

    if (!filePaths.isEmpty()) {
        curId = 0;
        curSongList = filePaths;
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
    if (curId != id && id >= 0 && id < curSongList.size()) {
        curId = id;
        player->setSource(QUrl::fromLocalFile(curSongList[curId]));
        playCounts[curSongList[curId]] = playCounts.value(curSongList[curId], 0) + 1;
        lastPlayed[curSongList[curId]] = QDateTime::currentDateTime();
        savePlayData();
        emit curIdChanged();
    }
}

void AudioPlayer::setCurSongList(const QStringList& playlist)
{
    if (curSongList != playlist) {
        curSongList = playlist;
        emit curSongListChanged();
    }
}

void AudioPlayer::togglePlayPause()
{
    if (player->playbackState() == QMediaPlayer::PlayingState) player->pause();
    else {
        player->play();
        if (curId >= 0 && curId < curSongList.size()) {
            playCounts[curSongList[curId]] = playCounts.value(curSongList[curId], 0) + 1;
            lastPlayed[curSongList[curId]] = QDateTime::currentDateTime();
            savePlayData();
        }
    }
    emit playingStateChanged();
}

QStringList AudioPlayer::sortMost()
{
    QStringList sortedList = filePaths;
    std::sort(sortedList.begin(), sortedList.end(), [&](const QString& a, const QString& b) {
        return playCounts.value(a, 0) > playCounts.value(b, 0);
    });
    return sortedList;
}

QStringList AudioPlayer::sortLast()
{
    QStringList sortedList = filePaths;
    std::sort(sortedList.begin(), sortedList.end(), [&](const QString& a, const QString& b) {
        return lastPlayed.value(a, QDateTime()) > lastPlayed.value(b, QDateTime());
    });
    return sortedList;
}

QStringList AudioPlayer::sortLength(bool ascending)
{
    QStringList sortedList = filePaths;
    std::sort(sortedList.begin(), sortedList.end(), [&](const QString& a, const QString& b) {
        int indexA = filePaths.indexOf(a);
        int indexB = filePaths.indexOf(b);
        int durationA = (indexA >= 0 && indexA < fileDurations.size()) ? fileDurations[indexA] : 0;
        int durationB = (indexB >= 0 && indexB < fileDurations.size()) ? fileDurations[indexB] : 0;
        return ascending ? (durationA < durationB) : (durationA > durationB);
    });
    return sortedList;
}

void AudioPlayer::savePlayData()
{
    QSettings settings;
    settings.beginGroup("playData");
    settings.setValue("playCounts", QVariant::fromValue(playCounts));
    settings.setValue("lastPlayed", QVariant::fromValue(lastPlayed));
    settings.endGroup();
}

void AudioPlayer::loadPlayData()
{
    QSettings settings;
    settings.beginGroup("playData");

    QVariant playCountsVariant = settings.value("playCounts");
    if (playCountsVariant.isValid() && playCountsVariant.canConvert<PlayCountMap>()) {
        playCounts = playCountsVariant.value<PlayCountMap>();
    }
    else {
        playCounts.clear();
        qDebug() << "playCounts not found";
    }

    QVariant lastPlayedVariant = settings.value("lastPlayed");
    if (lastPlayedVariant.isValid() && lastPlayedVariant.canConvert<LastPlayedMap>()) {
        lastPlayed = lastPlayedVariant.value<LastPlayedMap>();
    }
    else {
        lastPlayed.clear();
        qDebug() << "lastPlayed not found";
    }

    settings.endGroup();
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
    playlists[name] = files;
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
        settings.setValue(name, playlists[name].toStringList());
    }
    settings.endGroup();
}

void AudioPlayer::loadPlaylists()
{
    QSettings settings;
    settings.beginGroup("playlists");
    QStringList playlistNames = settings.childKeys();
    for (const QString& name : playlistNames) {
        playlists[name] = settings.value(name).toStringList();
    }
    settings.endGroup();
}
