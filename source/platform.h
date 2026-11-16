#ifndef UAPLAY_PLATFORM_H
#define UAPLAY_PLATFORM_H

#include <sys/stat.h>

/* Storage roots per console. Host-side tests keep the Switch layout. */
#if defined(__vita__)
#define UAPLAY_CONSOLE 1
#define UAPLAY_DATA_ROOT "ux0:data"
#define UAPLAY_ROMFS "app0:romfs/"
/* OpenSSL on the Vita has no system trust store; ship Mozilla's bundle. */
#define UAPLAY_CA_BUNDLE UAPLAY_ROMFS "cacert.pem"
#elif defined(__TRIMUI__)
#define UAPLAY_CONSOLE 1
#define UAPLAY_DATA_ROOT "/mnt/SDCARD/.userdata/tg5040"
#define UAPLAY_ROMFS "romfs/"
#define UAPLAY_CA_BUNDLE UAPLAY_ROMFS "cacert.pem"
#else
#ifdef __SWITCH__
#define UAPLAY_CONSOLE 1
#endif
#define UAPLAY_DATA_ROOT "sdmc:/switch"
#define UAPLAY_ROMFS "romfs:/"
#endif
#define UAPLAY_DATA_DIR UAPLAY_DATA_ROOT "/uaplay"

static inline void uaplay_ensure_data_dirs(void) {
#if defined(__TRIMUI__)
    mkdir("/mnt/SDCARD/.userdata", 0777);
#elif !defined(__vita__) && !defined(__SWITCH__)
    mkdir("sdmc:", 0777);
#endif
    mkdir(UAPLAY_DATA_ROOT, 0777);
    mkdir(UAPLAY_DATA_DIR, 0777);
}

#endif
