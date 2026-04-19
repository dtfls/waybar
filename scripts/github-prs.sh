#!/usr/bin/env sh

set -u

limit="${GITHUB_PR_LIMIT:-100}"

emit_status() {
  text="$1"
  tooltip="$2"
  class_name="$3"

  jq -cn \
    --arg text "$text" \
    --arg tooltip "$tooltip" \
    --arg class "$class_name" \
    '{text: $text, tooltip: $tooltip, class: $class}'
}

fetch_prs() {
  gh search prs "$1" @me --state open --limit "$limit" \
    --json number,title,url,repository 2>/dev/null || printf '[]'
}

if ! command -v gh >/dev/null 2>&1; then
  emit_status "GH ?" "GitHub CLI nao encontrado" "error"
  exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
  emit_status "GH ?" "GitHub CLI sem autenticacao" "error"
  exit 0
fi

authored_json=$(fetch_prs --author)
assigned_json=$(fetch_prs --assignee)
review_json=$(fetch_prs --review-requested)

jq -cn \
  --argjson authored "$authored_json" \
  --argjson assigned "$assigned_json" \
  --argjson review "$review_json" '
    def title_text:
      .title
      | gsub("[\r\n]+"; " ")
      | if length > 72 then .[0:69] + "..." else . end;

    def item_line($prefix):
      "\($prefix) \(.repository.nameWithOwner)#\(.number) - \(title_text)";

    def section($label; $items; $prefix):
      if ($items | length) == 0 then
        []
      else
        ["", "\($label) (\($items | length))"]
        + ($items[:3] | map(item_line($prefix)))
        + if ($items | length) > 3 then
            ["... +\(($items | length) - 3) a mais"]
          else
            []
          end
      end;

    ($authored | unique_by(.url)) as $authored_unique |
    ($assigned | unique_by(.url)) as $assigned_unique |
    ($review | unique_by(.url)) as $review_unique |
    (($authored_unique + $assigned_unique + $review_unique) | unique_by(.url)) as $all |

    {
      text: " \($all | length)",
      tooltip: (
        [
          "GitHub PRs",
          "",
          "Total unico: \($all | length)",
          "Abertos por mim: \($authored_unique | length)",
          "Designados a mim: \($assigned_unique | length)",
          "Review solicitado: \($review_unique | length)",
          "",
          "Um PR pode aparecer em mais de uma secao abaixo."
        ]
        + section("Abertos por mim"; $authored_unique; "OWN")
        + section("Designados a mim"; $assigned_unique; "ASG")
        + section("Review solicitado"; $review_unique; "REV")
        | join("\n")
      ),
      class: (
        if ($review_unique | length) > 0 then
          "attention"
        elif ($assigned_unique | length) > 0 or ($authored_unique | length) > 0 then
          "active"
        else
          "idle"
        end
      )
    }
  '
