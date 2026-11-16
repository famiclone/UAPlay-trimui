PLATFORM ?= trimui

ifeq ($(PLATFORM),switch)

ifeq ($(strip $(DEVKITPRO)),)
$(error Set DEVKITPRO to the devkitPro installation directory)
endif

DEVKITA64 ?= $(DEVKITPRO)/devkitA64
PORTLIBS := $(DEVKITPRO)/portlibs/switch
LIBNX := $(DEVKITPRO)/libnx
CC := $(DEVKITA64)/bin/aarch64-none-elf-gcc

PKG_CONFIG_LIBDIR := $(PORTLIBS)/lib/pkgconfig
export PKG_CONFIG_LIBDIR

TARGET := UAPlay
ARCH := -march=armv8-a+crc+crypto -mtune=cortex-a57 -fPIE
COMMON := -O2 -g -Wall -Wextra -ffunction-sections -fdata-sections $(ARCH)
CFLAGS := $(COMMON) -D__SWITCH__ -I$(LIBNX)/include -I$(PORTLIBS)/include $(shell pkg-config --cflags sdl2 SDL2_ttf SDL2_image mpv libcurl)
LDFLAGS := -specs=$(LIBNX)/switch.specs $(ARCH) -Wl,--gc-sections
LIBS := $(shell pkg-config --libs mpv sdl2 SDL2_ttf SDL2_image libcurl) -lGLESv2 -lharfbuzz -lfreetype -ljpeg -lwebp -llzma -lzstd -L$(LIBNX)/lib -lnx -lm

.PHONY: all clean
all: $(TARGET).nro

%.o: source/%.c
	$(CC) $(CFLAGS) -c $< -o $@

OBJS := main.o catalog.o posters.o library.o playback.o downloads.o i18n.o movy_stream.o

$(TARGET).elf: $(OBJS)
	$(CC) $(LDFLAGS) $^ $(LIBS) -o $@

$(TARGET).nacp:
	nacptool --create "UAPlay" "Small182" "0.5.1" $@

$(TARGET).nro: $(TARGET).elf $(TARGET).nacp
	elf2nro $< $@ --nacp=$(TARGET).nacp --icon=icon.jpg --romfsdir=romfs

clean:
	rm -f $(OBJS) $(TARGET).elf $(TARGET).nacp $(TARGET).nro

else

# TrimUI Brick / Smart Pro (NextUI tg5040) target
CROSS_PREFIX ?= aarch64-nextui-linux-gnu-
CC := $(CROSS_PREFIX)gcc
STRIP := $(CROSS_PREFIX)strip
DOCKER ?= $(shell command -v docker 2>/dev/null || command -v /opt/homebrew/bin/docker 2>/dev/null || echo docker)
DOCKER_IMAGE ?= uaplay-tg5040-builder:latest

HAVE_CROSS := $(shell command -v $(CC) 2>/dev/null)

BUILD_DIR := build/tg5040
PAK_NAME := UAPlay.pak
PAK_DIR := dist/Tools/tg5040/$(PAK_NAME)
PAK_ZIP := $(PAK_NAME).zip
TARGET_BIN := uaplay

SRCS := \
	source/main.c \
	source/catalog.c \
	source/posters.c \
	source/library.c \
	source/playback.c \
	source/downloads.c \
	source/i18n.c \
	source/movy_stream.c

OBJS := $(patsubst source/%.c,$(BUILD_DIR)/%.o,$(SRCS))

ifneq ($(strip $(HAVE_CROSS)),)

SYSROOT ?= /opt/aarch64-nextui-linux-gnu/aarch64-nextui-linux-gnu/libc
PKG_CONFIG_SYSROOT_DIR := $(SYSROOT)
PKG_CONFIG_LIBDIR := $(SYSROOT)/usr/lib/pkgconfig:$(SYSROOT)/usr/share/pkgconfig
export PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_LIBDIR

comma := ,
PKG_CFLAGS := $(shell pkg-config --cflags sdl2 mpv libcurl openssl)
PKG_LIBS := $(filter-out -Wl$(comma)-rpath%,$(shell pkg-config --static --libs mpv libcurl))

CFLAGS := -O2 -mcpu=cortex-a53 -Wall -Wextra -ffunction-sections -fdata-sections \
	-D_GNU_SOURCE -D__TRIMUI__ $(PKG_CFLAGS)
ifneq ($(strip $(TMDB_API_KEY)),)
CFLAGS += -DUAPLAY_TMDB_BUILD_KEY=\"$(TMDB_API_KEY)\"
endif

LDFLAGS := -Wl,--gc-sections \
	-Wl,--enable-new-dtags \
	-Wl,-rpath,'$$ORIGIN/lib' \
	-Wl,-rpath-link,$(SYSROOT)/usr/lib \
	-Wl,-rpath-link,$(SYSROOT)/lib
LIBS := $(PKG_LIBS) -lSDL2_ttf -lSDL2_image -lSDL2 -lGLESv2 -lEGL -lssl -lcrypto -lasound -lfreetype -lfontconfig -lexpat -lz -lbz2 -llzma -latomic -lpthread -ldl -lrt -lm

FALLBACK_SOS := \
	$(SYSROOT)/usr/lib/liblzma.so.5 \
	$(SYSROOT)/usr/lib/libfontconfig.so.1 \
	$(SYSROOT)/usr/lib/libexpat.so.1 \
	$(SYSROOT)/usr/lib/libbz2.so.1.0 \
	$(SYSROOT)/lib/libatomic.so.1

.PHONY: all pak clean
all: pak

$(BUILD_DIR)/%.o: source/%.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET_BIN): $(OBJS)
	$(CC) $(LDFLAGS) $^ $(LIBS) -o $@
	$(STRIP) --strip-unneeded $@

pak: $(TARGET_BIN)
	rm -rf "$(PAK_DIR)" "$(PAK_ZIP)"
	mkdir -p "$(PAK_DIR)/romfs" "$(PAK_DIR)/lib"
	install -m 755 $(TARGET_BIN) "$(PAK_DIR)/$(TARGET_BIN)"
	install -m 755 launch.sh "$(PAK_DIR)/launch.sh"
	install -m 644 pak.json "$(PAK_DIR)/pak.json"
	install -m 644 icon.png "$(PAK_DIR)/icon.png"
	for so in $(FALLBACK_SOS); do \
		cp -L "$$so" "$(PAK_DIR)/lib/$$(basename "$$so")"; \
		chmod 755 "$(PAK_DIR)/lib/$$(basename "$$so")"; \
		$(STRIP) --strip-unneeded "$(PAK_DIR)/lib/$$(basename "$$so")"; \
	done
	cp -R romfs/. "$(PAK_DIR)/romfs/"
	cd "$(PAK_DIR)" && zip -r -9 "$(CURDIR)/$(PAK_ZIP)" .

clean:
	rm -rf build dist $(TARGET_BIN) $(PAK_ZIP)

else

.PHONY: all pak docker-image clean
all: pak

docker-image:
	@if ! $(DOCKER) image inspect $(DOCKER_IMAGE) >/dev/null 2>&1; then \
		$(DOCKER) build -f Dockerfile.tg5040 -t $(DOCKER_IMAGE) .; \
	fi

pak: docker-image
	$(DOCKER) run --rm -v "$(CURDIR):/root/workspace" -w /root/workspace \
		-e TMDB_API_KEY="$(TMDB_API_KEY)" $(DOCKER_IMAGE) make -j4 PLATFORM=trimui

clean:
	rm -rf build dist $(TARGET_BIN) $(PAK_ZIP)

endif

HOST_CC ?= cc
OFFLINE_SMOKE_TESTS := \
	country_filter_smoke \
	date_sort_smoke \
	details_metadata_smoke \
	new_sources_smoke \
	player_tracks_smoke \
	playerjs_playlist_smoke

.PHONY: test
test:
	@rm -rf build/tests && mkdir -p build/tests/lib1 build/tests/lib2 build/tests/bin
	$(HOST_CC) -O2 -Isource source/library.c tests/library_smoke.c -o build/tests/bin/library_smoke
	(cd build/tests/lib1 && ../bin/library_smoke)
	$(HOST_CC) -O2 -Isource source/library.c tests/library_migration_smoke.c -o build/tests/bin/library_migration_smoke
	(cd build/tests/lib2 && ../bin/library_migration_smoke)
	set -e; for t in $(OFFLINE_SMOKE_TESTS); do \
		$(HOST_CC) -O2 -Isource tests/$$t.c source/i18n.c source/movy_stream.c -lcurl -o build/tests/bin/$$t; \
		build/tests/bin/$$t; \
	done
	$(HOST_CC) -O2 -Isource source/catalog.c source/i18n.c source/movy_stream.c tests/source_ranking_smoke.c -lcurl -o build/tests/bin/source_ranking_smoke
	build/tests/bin/source_ranking_smoke
	@rm -rf build/tests

endif
