#!/bin/bash
# Save as youtube-download-sync.sh

# Configuration
URL="$1"
QUALITY="$2"
COOKIES_FILE="/home/ubuntu/ytdl/cookies.txt"
DOWNLOAD_DIR="/tmp/youtube_download/congliulyc@gmail.com"
LOG_FILE="/tmp/youtube_download/youtube_download.log"

# Generate timestamp for filename
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to get format selector based on quality
get_format_selector() {
    local quality="$1"
    case "$quality" in
        1|"480p")
            echo "b[ext=mp4][height<=480]/bv*[ext=mp4][height<=480]+ba[ext=m4a]/bv*[height<=480]+ba/b"
            ;;
        2|"720p")
            echo "b[ext=mp4][height<=720]/bv*[ext=mp4][height<=720]+ba[ext=m4a]/bv*[height<=720]+ba/b"
            ;;
        3|"1080p")
            echo "b[ext=mp4][height<=1080]/bv*[ext=mp4][height<=1080]+ba[ext=m4a]/bv*[height<=1080]+ba/b"
            ;;
        *)
            echo "b[ext=mp4]/bv*[ext=mp4]+ba[ext=m4a]/bv*+ba/b"
            ;;
    esac
}

# Check if parameters are provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <YouTube_URL> [quality]"
    echo "Quality options:"
    echo "  1 or 480p - Lower than 480p"
    echo "  2 or 720p - Lower than 720p"
    echo "  3 or 1080p - Lower than 1080p"
    echo "  (no parameter) - Best available quality"
    echo "Example: $0 https://www.youtube.com/watch?v=VIDEO_ID 720p"
    echo "Example: $0 https://www.youtube.com/watch?v=VIDEO_ID 2"
    URL="https://www.youtube.com/watch?v=Z99Njl3Fra0"
    QUALITY=""
elif [ $# -eq 1 ]; then
    QUALITY=""
fi

# Get format selector based on quality
FORMAT_SELECTOR=$(get_format_selector "$QUALITY")


# Log start
log "=== DOWNLOAD STARTED ==="
log "URL: $URL"
log "Quality: ${QUALITY:-best}"
log "Timestamp: $TIMESTAMP"


# Check if yt-dlp is installed
YTDLP_PATH="$HOME/.local/bin/yt-dlp"
if [ ! -f "$YTDLP_PATH" ]; then
    log "ERROR: yt-dlp not found"
    echo "ERROR: yt-dlp not found"
    exit 1
fi

# Check if cookies file exists and fix permissions
if [ ! -f "$COOKIES_FILE" ]; then
    log "ERROR: Cookies file does not exist"
    echo "ERROR: Cookies file does not exist"
    exit 1
fi


log "Starting download with subtitles..."

# Log quality setting
if [ -n "$QUALITY" ]; then
    case "$QUALITY" in
        1|"480p") log "Quality setting: Lower than 480p" ;;
        2|"720p") log "Quality setting: Lower than 720p" ;;
        3|"1080p") log "Quality setting: Lower than 1080p" ;;
        *) log "Quality setting: Unknown quality '$QUALITY', using best available" ;;
    esac
else
    log "Quality setting: Best available quality"
fi

log "Format selector: $FORMAT_SELECTOR"

# Execute download with subtitle options
    "$YTDLP_PATH" \
    --cookies "$COOKIES_FILE" \
    -f "$FORMAT_SELECTOR" \
    --write-sub \
    --write-auto-sub \
    --sub-lang "zh,zh-Hans,zh-CN,en" \
    --sub-format "srt" \
    --embed-subs \
    --embed-metadata \
    --add-metadata \
    --no-progress \
    --mark-watched \
    --embed-thumbnail \
    -o "$DOWNLOAD_DIR/${TIMESTAMP}.%(ext)s" \
    "$URL" >> "$LOG_FILE" 2>&1

# Capture exit code
DOWNLOAD_EXIT_CODE=$?

# Log result
if [ $DOWNLOAD_EXIT_CODE -eq 0 ]; then
    log "=== DOWNLOAD WITH SUBTITLES COMPLETED ==="
    log "SUCCESS: Download with subtitles completed"
    
    # Find the downloaded files
    DOWNLOADED_VIDEO=$(find "$DOWNLOAD_DIR" -name "${TIMESTAMP}.*" -type f | grep -E '\.(mp4|mkv|avi)$' | head -1)
    DOWNLOADED_SUBTITLES=$(find "$DOWNLOAD_DIR" -name "${TIMESTAMP}.*" -type f | grep -E '\.(srt|vtt)$')
    
    if [ -n "$DOWNLOADED_VIDEO" ] && [ -f "$DOWNLOADED_VIDEO" ]; then
        # Extract video information and save in variables
        VIDEO_TITLE=$("$YTDLP_PATH"  --cookies "$COOKIES_FILE" --get-title "$URL" 2>/dev/null)
        # VIDEO_DURATION=$("$YTDLP_PATH" --get-duration "$URL" 2>/dev/null)
        # VIDEO_UPLOADER=$("$YTDLP_PATH" --get-uploader "$URL" 2>/dev/null)
        # VIDEO_VIEW_COUNT=$("$YTDLP_PATH" --get-view-count "$URL" 2>/dev/null)

        log "Video title: $VIDEO_TITLE"
        # log "Video duration: $VIDEO_DURATION"
        # log "Video uploader: $VIDEO_UPLOADER"
        # log "Video view count: $VIDEO_VIEW_COUNT"



        # Get file information
        FILE_SIZE=$(du -h "$DOWNLOADED_VIDEO" | cut -f1)
        FILE_NAME=$(basename "$DOWNLOADED_VIDEO")
        FILE_PATH="$DOWNLOADED_VIDEO"
        
        log "Downloaded video: $FILE_NAME"
        log "Video size: $FILE_SIZE"
        log "Video path: $FILE_PATH"
        
        # Check for subtitles
        if [ -n "$DOWNLOADED_SUBTITLES" ]; then
            log "Subtitles found:"
            for sub in $DOWNLOADED_SUBTITLES; do
                SUB_NAME=$(basename "$sub")
                SUB_SIZE=$(du -h "$sub" | cut -f1)
                log "  - $SUB_NAME ($SUB_SIZE)"
            done
        else
            log "No separate subtitle files found (may be embedded)"
        fi
        
        DOWNLOAD_HTTP_URL="http://47.128.3.198/files/$FILE_NAME"

        # Return file information
        log "SUCCESS: Download with subtitles completed"
        log "Video: $FILE_NAME"
        log "Size: $FILE_SIZE"
        log "Path: $FILE_PATH"
        log "Title: $VIDEO_TITLE"
	log "DOWNLOAD HTTP URL: $DOWNLOAD_HTTP_URL"
        log "SMB Path: //47.128.3.198/YoutubeDownload/$FILE_NAME"
        
        # List subtitle files if any
        if [ -n "$DOWNLOADED_SUBTITLES" ]; then
            log "Subtitles:"
            for sub in $DOWNLOADED_SUBTITLES; do
                SUB_NAME=$(basename "$sub")
                log "  - $SUB_NAME"
            done
        else
            log "Subtitles: Embedded in video file"
        fi
        
        # echo "http://47.128.3.198/files/$FILE_NAME"

       # echo "{\"title\": \"$VIDEO_TITLE\", \"download_link\": $DOWNLOAD_HTTP_URL, \"VIDEO_SOURCE_URL\": \"$URL\"}"
        echo "{\"title\": \"$VIDEO_TITLE\", \"download_link\": \"$DOWNLOAD_HTTP_URL\", \"video_source_url\": \"$URL\"}"
               
        exit 0
    else
        log "ERROR: Downloaded video file not found"
        echo "ERROR: Downloaded video file not found"
        exit 1
    fi
else
    log "=== DOWNLOAD WITH SUBTITLES FAILED ==="
    log "ERROR: Download with subtitles failed (exit code: $DOWNLOAD_EXIT_CODE)"
    echo "ERROR: Download with subtitles failed (exit code: $DOWNLOAD_EXIT_CODE)"
    exit 1
fi
