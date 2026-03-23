#!/bin/bash
# Watch a GitHub Actions build and notify via openclaw when done
# Usage: watch-build.sh <run_id> <channel_id>

RUN_ID=$1
CHANNEL=${2:-"1482838821426172048"}
REPO="Chase-Xuu/Adv360-Pro-ZMK"

if [ -z "$RUN_ID" ]; then
    echo "Usage: $0 <run_id> [channel_id]"
    exit 1
fi

echo "⏳ Monitoring build $RUN_ID..."

while true; do
    STATUS=$(gh api "repos/$REPO/actions/runs/$RUN_ID" --jq '.status' 2>/dev/null)
    if [ "$STATUS" = "completed" ]; then
        CONCLUSION=$(gh api "repos/$REPO/actions/runs/$RUN_ID" --jq '.conclusion' 2>/dev/null)
        SHA=$(gh api "repos/$REPO/actions/runs/$RUN_ID" --jq '.head_sha[:7]' 2>/dev/null)
        
        if [ "$CONCLUSION" = "success" ]; then
            # Download firmware
            cd /home/chixu/Adv360-Pro-ZMK
            gh run download "$RUN_ID" --dir firmware-output/ 2>/dev/null
            
            # Notify via openclaw
            openclaw message send --channel discord --target "$CHANNEL" --message "✅ 固件编译完成！commit $SHA，已下载。准备好刷的时候说一声，我帮你刷入。" --account daily-bot
        else
            openclaw message send --channel discord --target "$CHANNEL" --message "❌ 固件编译失败（$CONCLUSION），commit $SHA。我来看看哪里出了问题。" --account daily-bot
        fi
        break
    fi
    sleep 20
done
