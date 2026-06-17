#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
DB="$HOME/GitHub/mk-brain/bookmarks.db"

if [ ! -f "$DB" ]; then
  echo "bookmarks.db not found: $DB" >&2
  exit 1
fi

echo "Exporting bookmarks (signal >= 60)..."
sqlite3 "$DB" "
SELECT json_group_array(json_object(
  'url', url,
  'domain', domain,
  'title', COALESCE(note, ''),
  'insight', COALESCE(core_insight, ''),
  'signal', signal_score,
  'route', COALESCE(route_to, ''),
  'date', COALESCE(timestamp, created_at),
  'blog_score', COALESCE(blog_potential_score, 0),
  'lab', COALESCE(lab_recommendation, '')
))
FROM bookmarks
WHERE signal_score >= 60 AND status != 'rejected'
ORDER BY signal_score DESC, timestamp DESC
" > "$DIR/data.json"

COUNT=$(python3 -c "import json; print(len(json.load(open('$DIR/data.json'))))")
echo "Exported $COUNT bookmarks"

cd "$DIR"
if git diff --quiet data.json 2>/dev/null; then
  echo "No changes, skip commit"
  exit 0
fi

git add data.json
git commit -m "data: update bookmarks ($COUNT entries, $(date +%Y-%m-%d))"
git push origin main
echo "Pushed to GitHub. Pages will redeploy automatically."
