#!/bin/sh

PAK_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$PAK_DIR" || exit 1

PLATFORM="${PLATFORM:-tg5040}"
SDCARD_PATH="${SDCARD_PATH:-/mnt/SDCARD}"
SYSTEM_PATH="${SYSTEM_PATH:-$SDCARD_PATH/.system/$PLATFORM}"
USERDATA_PATH="${USERDATA_PATH:-$SDCARD_PATH/.userdata/$PLATFORM}"
LOGS_PATH="${LOGS_PATH:-$USERDATA_PATH/logs}"

mkdir -p \
    "$USERDATA_PATH/uaplay/posters" \
    "$USERDATA_PATH/uaplay/downloads" \
    "$USERDATA_PATH/uaplay/subtitles" \
    "$USERDATA_PATH/uaflix" \
    "$LOGS_PATH"

if [ -z "${DEVICE:-}" ] && [ -f /usr/trimui/bin/MainUI ]; then
    TRIMUI_MODEL="$(strings /usr/trimui/bin/MainUI 2>/dev/null | grep '^Trimui' | head -n 1)"
    case "$TRIMUI_MODEL" in
        "Trimui Brick") export DEVICE="brick" ;;
        "Trimui Brick Pro") export DEVICE="brickpro" ;;
        "Trimui Smart Pro") export DEVICE="smartpro" ;;
    esac
fi

export HOME="$USERDATA_PATH"
export SSL_CERT_FILE="$PAK_DIR/romfs/cacert.pem"
export CURL_CA_BUNDLE="$PAK_DIR/romfs/cacert.pem"
export LD_LIBRARY_PATH="$SYSTEM_PATH/lib:/usr/trimui/lib:/usr/lib:/lib:$PAK_DIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

if [ -f "$SYSTEM_PATH/bin/governor.sh" ]; then
    sh "$SYSTEM_PATH/bin/governor.sh" performance >/dev/null 2>&1
fi

./uaplay >"$LOGS_PATH/UAPlay.txt" 2>&1
RET=$?
sync
exit $RET
