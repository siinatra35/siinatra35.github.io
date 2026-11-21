#!/usr/bin/env bash
# Move a blog post and its images into retired/, and find orphaned images.
#
# Usage:
#   scripts/retire-post.sh <post>              # dry run: show what would move
#   scripts/retire-post.sh <post> --apply      # actually move the files
#   scripts/retire-post.sh --orphans           # list images no page references
#
# <post> can be a filename (2024-03-08-htb-forest.md) or a path to it.
#
# How references are found: every text file in the repo is searched for the
# exact image path (e.g. /assets/img/posts/<folder>/01.png), so references
# in _drafts/, layouts, index.html, etc. count too. Skipped: _site/, .git/,
# vendor/, .bundle/, .jekyll-cache/, retired/.
#
# Retiring:
#   - An image folder with no other users moves whole.
#   - An image folder still used elsewhere: only files this post references
#     AND nothing else references move. Everything else stays and is reported.

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
POSTS="$REPO/_posts"
RETIRED="$REPO/retired"
IMG_ROOT="$REPO/assets/img/posts"
EXCLUDES=(--exclude-dir=_site --exclude-dir=.git --exclude-dir=retired \
          --exclude-dir=scripts --exclude-dir=vendor --exclude-dir=.bundle \
          --exclude-dir=.jekyll-cache)

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-1}"; }

# Text files that contain an exact string, minus one file (if given).
users_of() {
  local needle="$1" ignore="${2:-}"
  # grep exits 1 when nothing matches; that is not an error here.
  { grep -rIlF "${EXCLUDES[@]}" -- "$needle" "$REPO" 2>/dev/null || true; } \
    | { if [[ -n "$ignore" ]]; then grep -vxF -- "$ignore" || true; else cat; fi; }
  return 0
}

# ---------- orphan report ----------
if [[ "${1:-}" == "--orphans" ]]; then
  count=0
  while IFS= read -r f; do
    rel="/${f#"$REPO"/}"
    if [[ -z "$(users_of "$rel")" ]]; then
      echo "$rel"
      count=$((count + 1))
    fi
  done < <(find "$IMG_ROOT" -type f | sort)
  echo
  echo "$count orphaned image(s)."
  exit 0
fi

[[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]] && usage 0

APPLY=0
POST_ARG=""
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    *) POST_ARG="$arg" ;;
  esac
done

POST_NAME="$(basename "$POST_ARG")"
POST_PATH="$POSTS/$POST_NAME"
if [[ ! -f "$POST_PATH" ]]; then
  echo "error: no post named '$POST_NAME' in _posts/" >&2
  exit 1
fi

# Image paths this post references
mapfile -t REFS < <(grep -oE '/assets/img/posts/[^)"'"'"' ]+' "$POST_PATH" | sort -u)
declare -A FOLDERS=()
for ref in "${REFS[@]}"; do
  rel="${ref#/assets/img/posts/}"
  FOLDERS["${rel%%/*}"]=1
done

run() {
  if [[ $APPLY -eq 1 ]]; then
    "$@"
  else
    printf '  would run: %s\n' "$*"
  fi
}

echo "Post: _posts/$POST_NAME"
[[ $APPLY -eq 0 ]] && echo "(dry run, pass --apply to move files)"
echo

# Post itself
run mkdir -p "$RETIRED/_posts"
run mv "$POST_PATH" "$RETIRED/_posts/$POST_NAME"
echo

if [[ ${#FOLDERS[@]} -eq 0 ]]; then
  echo "No image references found in this post."
fi

for folder in "${!FOLDERS[@]}"; do
  src="$IMG_ROOT/$folder"
  dst="$RETIRED/assets/img/posts/$folder"

  # Anything else using this folder (any text file, not this post)?
  others="$(users_of "/assets/img/posts/$folder/" "$POST_PATH")"

  if [[ -z "$others" ]]; then
    echo "Image folder: assets/img/posts/$folder/ (no other users, moving whole folder)"
    run mkdir -p "$RETIRED/assets/img/posts"
    run mv "$src" "$dst"
    echo
    continue
  fi

  echo "Image folder: assets/img/posts/$folder/ is still used elsewhere:"
  echo "$others" | sed 's/^/    /'
  echo "  moving only files this post uses and nothing else uses:"
  for ref in "${REFS[@]}"; do
    [[ "$ref" == "/assets/img/posts/$folder/"* ]] || continue
    file="$REPO/${ref#/}"
    [[ -f "$file" ]] || { echo "    missing on disk: $ref"; continue; }
    shared="$(users_of "$ref" "$POST_PATH")"
    if [[ -n "$shared" ]]; then
      echo "    keep (shared): $ref"
    else
      run mkdir -p "$dst"
      run mv "$file" "$dst/${ref#/assets/img/posts/$folder/}"
    fi
  done
  echo
done

[[ $APPLY -eq 0 ]] && echo "Dry run complete. Re-run with --apply to move these files."
[[ $APPLY -eq 1 ]] && echo "Done. Retired files are in retired/ (gitignored)."
exit 0
