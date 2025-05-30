#ifndef AUDIOPLAYER_H
#define AUDIOPLAYER_H

#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QDebug>
#include <QList>
#include <QMap>
#include <QDateTime>
#include <QFileInfo>
#include <QCoreApplication>
#include <QSettings>
#include <QDir>

using PlayCountMap = QMap<QString, int>;
using LastPlayedMap = QMap<QString, QDateTime>;

Q_DECLARE_METATYPE(PlayCountMap);
Q_DECLARE_METATYPE(LastPlayedMap);

class AudioPlayer: public QObject
{
    Q_OBJECT
    QMediaPlayer *player;
    QAudioOutput *audioOutput;
    QStringList filePaths;
    QList<int> fileDurations;
    QStringList favourites;
    QVariantMap playlists;
    QStringList curSongList;
    int curId;
    PlayCountMap playCounts;
    LastPlayedMap lastPlayed;
    bool m_crossfadeEnabled;
    int m_crossfadeDuration;
    QString m_lastFolderPath;

    Q_PROPERTY(QStringList filePaths READ getFilePaths NOTIFY filePathsChanged)
    Q_PROPERTY(QList<int> fileDurations READ getFileDurations NOTIFY fileDurationsChanged)
    Q_PROPERTY(int position READ getPosition WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(float volume READ getVolume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playingStateChanged)
    Q_PROPERTY(int curId READ getCurId WRITE setCurId NOTIFY curIdChanged)
    Q_PROPERTY(QStringList favourites READ getFavourites NOTIFY favouritesChanged)
    Q_PROPERTY(QVariantMap playlists READ getPlaylists NOTIFY playlistsChanged)
    Q_PROPERTY(QStringList curSongList READ getCurSongList WRITE setCurSongList NOTIFY curSongListChanged)
    Q_PROPERTY(bool crossfadeEnabled READ crossfadeEnabled NOTIFY crossfadeStateChanged)
    Q_PROPERTY(int crossfadeDuration READ crossfadeDuration WRITE setCrossfadeDuration NOTIFY crossfadeDurationChanged)

public:
    explicit AudioPlayer(QObject *parent = nullptr);

    QStringList getFilePaths() { return filePaths; }
    QList<int> getFileDurations() { return fileDurations; }
    int getPosition() { return player->position(); }
    float getVolume() { return audioOutput->volume(); }
    bool isPlaying() { return player->playbackState() == QMediaPlayer::PlayingState; }
    int getCurId() { return curId; }
    QStringList getFavourites() { return favourites; }
    QVariantMap getPlaylists() { return playlists; }
    QStringList getCurSongList() { return curSongList; }
    bool crossfadeEnabled() const { return m_crossfadeEnabled; }
    int crossfadeDuration() const { return m_crossfadeDuration; }
    Q_INVOKABLE QString getLastFolderPath() const { return m_lastFolderPath; }
    Q_INVOKABLE QStringList getPlaylistSongs(const QString& playlistName) const;

public slots:
    void setFiles(const QStringList&);
    void setFolder(const QString& folderPath);
    void setCurId(int);
    void togglePlayPause();
    void setPosition(int);
    void setVolume(float);
    void loadLastFiles();
    void toggleFavourite(const QString&);
    void addPlaylist(const QString&, const QStringList&);
    void removePlaylist(const QString&);
    void setCurSongList(const QStringList&);
    QStringList sortMost();
    QStringList sortLast();
    QStringList sortLength(bool);
    void setCrossfadeEnabled(bool);
    void setCrossfadeDuration(int);
    void stop();

signals:
    void filePathsChanged();
    void fileDurationsChanged();
    void positionChanged(int);
    void volumeChanged();
    void playingStateChanged();
    void curIdChanged();
    void favouritesChanged();
    void playlistsChanged();
    void curSongListChanged();
    void crossfadeStateChanged();
    void crossfadeDurationChanged();

private:
    void saveFilePaths(const QStringList&);
    QStringList getLastFilePaths();
    void saveFavourites();
    void loadFavourites();
    void savePlaylists();
    void loadPlaylists();
    void savePlayData();
    void loadPlayData();
    void saveLastFolderPath(const QString&);
    QString getLastFolderPathFromSettings();
};

#endif
