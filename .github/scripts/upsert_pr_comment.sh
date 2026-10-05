#!/usr/bin/env bash
# Posts body_file as a comment on PR pr_number, or edits its own previous comment in place if
# one already exists (identified by an HTML marker comment, invisible when rendered) -- so
# repeated on-demand CI runs update a single comment instead of piling up new ones each time.
#
# Usage: upsert_pr_comment.sh <pr_number> <marker> <body_file>
# Requires: GH_TOKEN (or gh auth), GITHUB_REPOSITORY set (both present by default in Actions).
set -euo pipefail

pr_number="$1"
marker="$2"
body_file="$3"
marker_tag="<!-- ci-comment-marker: ${marker} -->"

existing_id=$(gh api "repos/${GITHUB_REPOSITORY}/issues/${pr_number}/comments" --paginate \
  --jq ".[] | select(.body | startswith(\"${marker_tag}\")) | .id" | head -n1)

if [ -n "$existing_id" ]; then
  gh api "repos/${GITHUB_REPOSITORY}/issues/comments/${existing_id}" -X PATCH -F body=@"${body_file}" >/dev/null
  echo "Updated existing comment ${existing_id} on PR #${pr_number}"
else
  gh api "repos/${GITHUB_REPOSITORY}/issues/${pr_number}/comments" -X POST -F body=@"${body_file}" >/dev/null
  echo "Created new comment on PR #${pr_number}"
fi
