#!/bin/bash
# Save as bilibili-download-pro.sh
# Bilibili video downloader based on yt-dlp

# Configuration
URL="$1"
QUALITY="$2"
COOKIES_FILE="/home/ubuntu/ytdl/cookies-bilibili.txt"  # 用户需要提供bilibili的cookie文件
DOWNLOAD_DIR="/tmp/video_download/congliulyc@gmail.com"
# DOWNLOAD_DIR="/tmp/bilibili_download/jackliuangel"
LOG_FILE="/tmp/bilibili_download/bilibili_download.log"

# Generate timestamp for filename
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to get quality label for filename
get_quality_label() {
    local quality="$1"
    case "$quality" in
        1|"360p")
            echo "360p"
            ;;
        2|"720p")
            echo "720p"
            ;;
        3|"1080p")
            echo "1080p"
            ;;
        4|"4k")
            echo "4k"
            ;;
        *)
            echo "best"
            ;;
    esac
}

# Function to get format selector based on quality for Bilibili
get_format_selector() {
    local quality="$1"
    case "$quality" in
        1|"360p")
            echo "bv*[height<=360]+ba/b[height<=360]/worst"
            ;;
        2|"720p")
            echo "bv*[height<=720]+ba/b[height<=720]/b"
            ;;
        3|"1080p")
            echo "bv*[height<=1080]+ba/b[height<=1080]/b"
            ;;
        4|"4k")
            echo "bv*[height<=2160]+ba/b[height<=2160]/best"
            ;;
        *)
            echo "bv*+ba/b/best"
            ;;
    esac
}

# Create download directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Check if parameters are provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <Bilibili_URL> [quality]"
    echo "Quality options:"
    echo "  1 or 360p - Up to 360p quality (small file size)"
    echo "  2 or 720p - Up to 720p quality (balanced)"
    echo "  3 or 1080p - Up to 1080p quality (high quality)"
    echo "  4 or 4k - Up to 4K quality (highest quality)"
    echo "  (no parameter) - Best available quality"
    echo ""
    echo "Example: $0 https://www.bilibili.com/video/BV1xx411c7mD 720p"
    echo "Example: $0 https://www.bilibili.com/video/BV1xx411c7mD 2"
    echo ""
    echo "Note: Make sure to provide the bilibili cookies file at: $COOKIES_FILE"
    exit 1
elif [ $# -eq 1 ]; then
    QUALITY=""
fi

# Get format selector and quality label based on quality
FORMAT_SELECTOR=$(get_format_selector "$QUALITY")
QUALITY_LABEL=$(get_quality_label "$QUALITY")

# Log start
log "=== BILIBILI DOWNLOAD STARTED ==="
log "URL: $URL"
log "Quality: ${QUALITY:-best} ($QUALITY_LABEL)"
log "Timestamp: $TIMESTAMP"

# Check if yt-dlp is installed
YTDLP_PATH="$HOME/.local/bin/yt-dlp"
if [ ! -f "$YTDLP_PATH" ]; then
    # Try system installation
    if command -v yt-dlp >/dev/null 2>&1; then
        YTDLP_PATH=$(which yt-dlp)
        log "Using system yt-dlp at: $YTDLP_PATH"
    else
        log "ERROR: yt-dlp not found"
        echo "ERROR: yt-dlp not found. Please install it first:"
        echo "pip install --user yt-dlp"
        exit 1
    fi
fi

# Check if cookies file exists
if [ ! -f "$COOKIES_FILE" ]; then
    log "WARNING: Cookies file does not exist at $COOKIES_FILE"
    echo "WARNING: Cookies file not found at $COOKIES_FILE"
    echo "Some bilibili videos may not be accessible without cookies."
    echo "Please export your bilibili cookies and save to: $COOKIES_FILE"
    echo ""
    echo "Continuing without cookies..."
    COOKIES_OPTION=""
else
    log "Using cookies file: $COOKIES_FILE"
    COOKIES_OPTION="--cookies $COOKIES_FILE"
fi

log "Starting bilibili download..."

# Log quality setting
if [ -n "$QUALITY" ]; then
    case "$QUALITY" in
        1|"360p") log "Quality setting: Up to 360p quality (small file size) - Label: $QUALITY_LABEL" ;;
        2|"720p") log "Quality setting: Up to 720p quality (balanced) - Label: $QUALITY_LABEL" ;;
        3|"1080p") log "Quality setting: Up to 1080p quality (high quality) - Label: $QUALITY_LABEL" ;;
        4|"4k") log "Quality setting: Up to 4K quality (highest quality) - Label: $QUALITY_LABEL" ;;
        *) log "Quality setting: Unknown quality '$QUALITY', using best available - Label: $QUALITY_LABEL" ;;
    esac
else
    log "Quality setting: Best available quality"
fi

log "Format selector: $FORMAT_SELECTOR"

# Validate Bilibili URL
if [[ ! "$URL" =~ bilibili\.com ]]; then
    log "ERROR: Invalid Bilibili URL format"
    echo "ERROR: Please provide a valid Bilibili URL"
    echo "Example: https://www.bilibili.com/video/BV1xx411c7mD"
    exit 1
fi

# Execute download with bilibili-specific options
YTDLP_CMD="$YTDLP_PATH"
if [ -n "$COOKIES_OPTION" ]; then
    YTDLP_CMD="$YTDLP_CMD $COOKIES_OPTION"
fi

$YTDLP_CMD \
    -f "$FORMAT_SELECTOR" \
    --write-sub \
    --write-auto-sub \
    --sub-lang "zh-Hans,zh-Hant,zh,en" \
    --sub-format "srt" \
    --embed-subs \
    --embed-metadata \
    --add-metadata \
    --replace-in-metadata title "\\s+$" "" \
    --replace-in-metadata title "\\s+" "_" \
    --replace-in-metadata title "[,!，！]+" "" \
    --replace-in-metadata title "[|｜]+" "" \
    --replace-in-metadata title "[;；]+" "" \
    --replace-in-metadata title "[?？]+" "" \
    --replace-in-metadata title "[.。]+" "" \
    --replace-in-metadata title "[#]+" "" \
    --replace-in-metadata title '[<>《》]+' "" \
    --replace-in-metadata title '[:：]+' "" \
    --replace-in-metadata title '["「」"]+' "" \
    --replace-in-metadata title '[/／]+' "" \
    --replace-in-metadata title '[\\]+' "" \
    --replace-in-metadata title '[*]+' "" \
    --replace-in-metadata title "[\x00-\x1F]+" "" \
    --replace-in-metadata title "[\\u3001-\\u303F\\uFF01-\\uFF60\\uFFE0-\\uFFEE]+" "" \
    --no-progress \
    --extractor-args "bilibili:sessdata=" \
    -o "$DOWNLOAD_DIR/%(title).120B_${QUALITY_LABEL}_${TIMESTAMP}.%(ext)s" \
    "$URL" >> "$LOG_FILE"  2>&1

# Capture exit code
DOWNLOAD_EXIT_CODE=$?

# Log result
if [ $DOWNLOAD_EXIT_CODE -eq 0 ]; then
    log "=== BILIBILI DOWNLOAD COMPLETED ==="
    log "SUCCESS: Bilibili download completed"
    
    # Find the downloaded files
    log "Searching for downloaded files with quality: ${QUALITY_LABEL}, timestamp: ${TIMESTAMP}"
    log "Search directory: $DOWNLOAD_DIR"
    log "Search pattern: *_${QUALITY_LABEL}_${TIMESTAMP}.*"
    
    # List all files in download directory for debugging
    log "All files in download directory:"
    find "$DOWNLOAD_DIR" -type f -name "*${TIMESTAMP}*" | while read file; do
        log "Found file: $file"
    done
    
    DOWNLOADED_VIDEO=$(find "$DOWNLOAD_DIR" -name "*_${QUALITY_LABEL}_${TIMESTAMP}.*" -type f | grep -E '\.(mp4|mkv|avi|flv)$' | head -1)
    DOWNLOADED_SUBTITLES=$(find "$DOWNLOAD_DIR" -name "*_${QUALITY_LABEL}_${TIMESTAMP}.*" -type f | grep -E '\.(srt|vtt)$')
    
    log "Found video file: $DOWNLOADED_VIDEO"
    log "Found subtitle files: $DOWNLOADED_SUBTITLES"
    
    if [ -n "$DOWNLOADED_VIDEO" ] && [ -f "$DOWNLOADED_VIDEO" ]; then
        # Extract video information and save in variables
        VIDEO_TITLE=$("$YTDLP_PATH" $COOKIES_OPTION --get-title "$URL" 2>/dev/null)
        VIDEO_UPLOADER=$("$YTDLP_PATH" $COOKIES_OPTION --get-uploader "$URL" 2>/dev/null)
        
        log "Video title: $VIDEO_TITLE"
        log "Video uploader: $VIDEO_UPLOADER"
        
        # Get file information
        FILE_SIZE=$(du -h "$DOWNLOADED_VIDEO" | cut -f1)
        FILE_NAME=$(basename "$DOWNLOADED_VIDEO")
        FILE_PATH="$DOWNLOADED_VIDEO"
        
        log "Downloaded video: $FILE_NAME (Quality: $QUALITY_LABEL)"
        log "Video size: $FILE_SIZE"
        log "Video path: $FILE_PATH"
        
        # Overwrite Title metadata with the video URL using exiftool if available
        if command -v exiftool >/dev/null 2>&1; then
            log "Retagging title metadata with URL via exiftool..."
            exiftool -overwrite_original -Title="$URL" "$FILE_PATH" >> "$LOG_FILE" 2>&1 && log "exiftool retagging succeeded"
        else
            log "exiftool not available; skipping metadata overwrite"
        fi
        
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
        log "SUCCESS: Bilibili download completed"
        log "Video: $FILE_NAME"
        log "Size: $FILE_SIZE"
        log "Path: $FILE_PATH"
        log "Title: $VIDEO_TITLE"
        log "Uploader: $VIDEO_UPLOADER"
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
        
        echo "{\"title\": \"$VIDEO_TITLE\", \"uploader\": \"$VIDEO_UPLOADER\", \"download_link\": \"$DOWNLOAD_HTTP_URL\", \"video_source_url\": \"$URL\", \"platform\": \"bilibili\"}"
        exit 0
    else
        log "ERROR: Downloaded video file not found with pattern *_${QUALITY_LABEL}_${TIMESTAMP}.*"
        log "Trying alternative search patterns..."
        
        # Try broader search patterns
        DOWNLOADED_VIDEO=$(find "$DOWNLOAD_DIR" -name "*${TIMESTAMP}*" -type f | grep -E '\.(mp4|mkv|avi|webm|flv)$' | head -1)
        
        if [ -n "$DOWNLOADED_VIDEO" ] && [ -f "$DOWNLOADED_VIDEO" ]; then
            log "Found video with broader search: $DOWNLOADED_VIDEO"
            # Continue with the same processing logic
            VIDEO_TITLE=$("$YTDLP_PATH" $COOKIES_OPTION --get-title "$URL" 2>/dev/null)
            VIDEO_UPLOADER=$("$YTDLP_PATH" $COOKIES_OPTION --get-uploader "$URL" 2>/dev/null)
            FILE_SIZE=$(du -h "$DOWNLOADED_VIDEO" | cut -f1)
            FILE_NAME=$(basename "$DOWNLOADED_VIDEO")
            FILE_PATH="$DOWNLOADED_VIDEO"
            
            log "Downloaded video: $FILE_NAME (Quality: $QUALITY_LABEL)"
            log "Video size: $FILE_SIZE"
            log "Video path: $FILE_PATH"
            
            DOWNLOAD_HTTP_URL="http://47.128.3.198/files/$FILE_NAME"
            echo "{\"title\": \"$VIDEO_TITLE\", \"uploader\": \"$VIDEO_UPLOADER\", \"download_link\": \"$DOWNLOAD_HTTP_URL\", \"video_source_url\": \"$URL\", \"platform\": \"bilibili\"}"
            exit 0
        else
            log "ERROR: Downloaded video file not found even with broader search"
            log "All files in download directory:"
            ls -la "$DOWNLOAD_DIR" | while read line; do
                log "$line"
            done
            echo "ERROR: Downloaded video file not found"
            exit 1
        fi
    fi
else
    log "=== BILIBILI DOWNLOAD FAILED ==="
    log "ERROR: Bilibili download failed (exit code: $DOWNLOAD_EXIT_CODE)"
    echo "ERROR: Bilibili download failed (exit code: $DOWNLOAD_EXIT_CODE)"
    echo "This might be due to:"
    echo "1. Missing or invalid cookies file"
    echo "2. Private or restricted video"
    echo "3. Network connectivity issues"
    echo "4. Invalid video URL"
    exit 1
fi
