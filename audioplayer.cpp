#include "audioplayer.h"

AudioPlayer::AudioPlayer(QObject *parent) : QObject(parent), curId(-1), m_crossfadeEnabled(false)
{
    qDebug() << "AudioPlayer: Constructor called";
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
    curSongList = filePaths;

    QSettings settings(QCoreApplication::organizationName(), QCoreApplication::applicationName());
    m_crossfadeEnabled = settings.value("crossfadeEnabled", false).toBool();
}

void AudioPlayer::setCrossfadeEnabled(bool enabled)
{
    if (m_crossfadeEnabled != enabled) {
        m_crossfadeEnabled = enabled;
        QSettings settings(QCoreApplication::organizationName(), QCoreApplication::applicationName());
        settings.setValue("crossfadeEnabled", m_crossfadeEnabled);
        emit crossfadeStateChanged();
    }
}

void AudioPlayer::setFiles(const QStringList& fileUrls)
{
    filePaths.clear();
    fileDurations.clear();

    for (const QString &url : fileUrls) {
        QString localFile;
        if (url.startsWith("file:")) localFile = QUrl(url).toLocalFile();
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
        else qDebug() << "AudioPlayer: Skipped invalid or missing file:" << url;
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
        qDebug() << "AudioPlayer: Set curId to 0, curSongList size:" << curSongList.size();
    }
    else {
        curId = -1;
        curSongList.clear();
        emit filePathsChanged();
        emit fileDurationsChanged();
        emit curIdChanged();
        emit curSongListChanged();
        qDebug() << "AudioPlayer: No valid files, cleared lists";
    }
}

void AudioPlayer::setCurId(int id)
{
    if (curId != id && id >= 0 && id < curSongList.size()) {
        curId = id;
        QUrl newSource = QUrl::fromLocalFile(curSongList[curId]);
        if (player->source() != newSource) player->setSource(newSource);
        playCounts[curSongList[curId]] = playCounts.value(curSongList[curId], 0) + 1;
        lastPlayed[curSongList[curId]] = QDateTime::currentDateTime();
        savePlayData();
        emit curIdChanged();
        qDebug() << "AudioPlayer: setCurId to" << id << ", source:" << newSource.toString();
    }
}

void AudioPlayer::setCurSongList(const QStringList& playlist)
{
    if (curSongList != playlist) {
        curSongList = playlist;
        emit curSongListChanged();
        qDebug() << "AudioPlayer: setCurSongList, new size:" << curSongList.size();
    }
}

void AudioPlayer::togglePlayPause()
{
    if (player->playbackState() == QMediaPlayer::PlayingState) {
        player->pause();
        qDebug() << "AudioPlayer: togglePlayPause - Paused";
    }
    else {
        player->play();
        if (curId >= 0 && curId < curSongList.size()) {
            playCounts[curSongList[curId]] = playCounts.value(curSongList[curId], 0) + 1;
            lastPlayed[curSongList[curId]] = QDateTime::currentDateTime();
            savePlayData();
        }
        qDebug() << "AudioPlayer: togglePlayPause - Playing, curId:" << curId;
    }
    emit playingStateChanged();
}

void AudioPlayer::stop()
{
    qDebug() << "AudioPlayer: stop called";
    player->stop();
    emit playingStateChanged();
}

QStringList AudioPlayer::sortMost()
{
    qDebug() << "AudioPlayer: sortMost called";
    QStringList sortedList = filePaths;
    std::sort(sortedList.begin(), sortedList.end(), [&](const QString& a, const QString& b) {
        return playCounts.value(a, 0) > playCounts.value(b, 0);
    });
    return sortedList;
}

QStringList AudioPlayer::sortLast()
{
    qDebug() << "AudioPlayer: sortLast called";
    QStringList sortedList = filePaths;
    std::sort(sortedList.begin(), sortedList.end(), [&](const QString& a, const QString& b) {
        return lastPlayed.value(a, QDateTime()) > lastPlayed.value(b, QDateTime());
    });
    return sortedList;
}

QStringList AudioPlayer::sortLength(bool ascending)
{
    qDebug() << "AudioPlayer: sortLength called, ascending:" << ascending;
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
    qDebug() << "AudioPlayer: savePlayData called";
    QSettings settings;
    settings.beginGroup("playData");
    settings.setValue("playCounts", QVariant::fromValue(playCounts));
    settings.setValue("lastPlayed", QVariant::fromValue(lastPlayed));
    settings.endGroup();
}

void AudioPlayer::loadPlayData()
{
    qDebug() << "AudioPlayer: loadPlayData called";
    QSettings settings;
    settings.beginGroup("playData");

    QVariant playCountsVariant = settings.value("playCounts");
    if (playCountsVariant.isValid() && playCountsVariant.canConvert<PlayCountMap>()) {
        playCounts = playCountsVariant.value<PlayCountMap>();
    }
    else {
        playCounts.clear();
        qDebug() << "AudioPlayer: playCounts not found";
    }

    QVariant lastPlayedVariant = settings.value("lastPlayed");
    if (lastPlayedVariant.isValid() && lastPlayedVariant.canConvert<LastPlayedMap>()) {
        lastPlayed = lastPlayedVariant.value<LastPlayedMap>();
    }
    else {
        lastPlayed.clear();
        qDebug() << "AudioPlayer: lastPlayed not found";
    }

    settings.endGroup();
}

void AudioPlayer::setPosition(int pos)
{
    qDebug() << "AudioPlayer: setPosition called with pos:" << pos;
    player->setPosition(pos);
    emit positionChanged(pos);
}

void AudioPlayer::setVolume(float vol)
{
    qDebug() << "AudioPlayer: setVolume called with vol:" << vol;
    audioOutput->setVolume(vol);
    emit volumeChanged();
}

void AudioPlayer::loadLastFiles()
{
    qDebug() << "AudioPlayer: loadLastFiles called";
    QStringList lastFiles = getLastFilePaths();
    if (!lastFiles.isEmpty()) setFiles(lastFiles);
}

void AudioPlayer::saveFilePaths(const QStringList &filePaths)
{
    qDebug() << "AudioPlayer: saveFilePaths called with" << filePaths.size() << "files";
    QSettings settings;
    settings.setValue("lastFiles", filePaths);
}

QStringList AudioPlayer::getLastFilePaths()
{
    qDebug() << "AudioPlayer: getLastFilePaths called";
    QSettings settings;
    QStringList lastFiles = settings.value("lastFiles", QStringList()).toStringList();
    return lastFiles;
}

void AudioPlayer::toggleFavourite(const QString& filePath)
{
    qDebug() << "AudioPlayer: toggleFavourite called for" << filePath;
    if (favourites.contains(filePath)) favourites.removeAll(filePath);
    else favourites.append(filePath);

    saveFavourites();
    emit favouritesChanged();
}

void AudioPlayer::saveFavourites()
{
    qDebug() << "AudioPlayer: saveFavourites called";
    QSettings settings;
    settings.setValue("favourites", favourites);
}

void AudioPlayer::loadFavourites()
{
    qDebug() << "AudioPlayer: loadFavourites called";
    QSettings settings;
    favourites = settings.value("favourites", QStringList()).toStringList();
}

void AudioPlayer::addPlaylist(const QString& name, const QStringList& files)
{
    qDebug() << "AudioPlayer: addPlaylist called for" << name;
    playlists[name] = files;
    savePlaylists();
    emit playlistsChanged();
}

void AudioPlayer::removePlaylist(const QString& name)
{
    qDebug() << "AudioPlayer: removePlaylist called for" << name;
    playlists.remove(name);
    savePlaylists();
    emit playlistsChanged();
}

void AudioPlayer::savePlaylists()
{
    qDebug() << "AudioPlayer: savePlaylists called";
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
    qDebug() << "AudioPlayer: loadPlaylists called";
    QSettings settings;
    settings.beginGroup("playlists");
    QStringList playlistNames = settings.childKeys();
    for (const QString& name : playlistNames) {
        playlists[name] = settings.value(name).toStringList();
    }
    settings.endGroup();
}
