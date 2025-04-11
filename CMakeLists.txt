cmake_minimum_required(VERSION 3.16)

project(Music_Player_2 VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml Multimedia)

qt_standard_project_setup (REQUIRES 6.8)

qt_add_executable (appMusic_Player_2 main.cpp)

qt_add_qml_module(appMusic_Player_2
    URI Music_Player_2
    VERSION 1.0
    QML_FILES
    Main.qml
    QML_FILES Bottom_Bar.qml
    QML_FILES File_List.qml
    SOURCES audioplayer.h audioplayer.cpp
    QML_FILES Side_Bar.qml
    QML_FILES PlaylistView.qml
    QML_FILES Image_Button.qml

    RESOURCES
    assets/icons/play.png
    assets/icons/play_un.png
    assets/icons/pause.png
    assets/icons/next.png
    assets/icons/next_un.png
    assets/icons/shuffle.png
    assets/icons/shuffle_un.png
    assets/icons/search.png
    assets/icons/volume_full.png
    assets/icons/volume_half.png
    assets/icons/volume_null.png
    assets/icons/heart_empty.png
    assets/icons/heart_filled.png
    assets/icons/back.png
    assets/icons/cross.png
    assets/icons/options.png

    assets/icons/library.png
    assets/icons/library_clicked.png
    assets/icons/playlists.png
    assets/icons/playlists_clicked.png
    assets/icons/settings.png
    assets/icons/settings_clicked.png
    assets/icons/favourites.png
    assets/icons/favourites_clicked.png
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appMusic_Player_2 PROPERTIES
    #    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appMusic_Player_2
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appMusic_Player_2
    PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::Multimedia
)

include(GNUInstallDirs)
install(TARGETS appMusic_Player_2
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
