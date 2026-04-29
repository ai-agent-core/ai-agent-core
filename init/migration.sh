#!/usr/bin/env bash

set -euo pipefail

#
# AI Agent Core migration
#
# Run from the host project root (one level above ai-agent-core/) when an
# older version of AI Agent Core has been replaced or upgraded.
#
# The script:
#   - relocates legacy USER content (tasks/, agent-works/, agent-spec/
#     WORK_STATE, agent-input/) into the new locations under
#     ai-agent-core/generated/,
#   - removes legacy AGENT-CORE-PROVIDED scaffolding that has been
#     replaced (agent-spec/ shell, etc.),
#   - reports staleness of host-root entrypoints (AGENTS.md, CLAUDE.md)
#     without overwriting them — those may carry user customisation.
#
# Default mode is DRY RUN. Pass --apply to perform actions.
# All destructive moves go through a timestamped backup directory:
#     ai-agent-core/generated/migration-backup-<UTC timestamp>/
# so any move can be undone manually.
#
# The script is idempotent — running it twice on the same tree should
# produce no further changes after the first --apply.
#

########################################
# Resolve paths
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="$(pwd)"
SCAFFOLD_DIR="$SCRIPT_DIR/scaffold"

GENERATED_DIR="$CORE_ROOT/generated"
TASKS_DIR="$GENERATED_DIR/tasks"
INPUTS_DIR="$GENERATED_DIR/inputs"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="$GENERATED_DIR/migration-backup-$TIMESTAMP"
CORE_JSON="$CORE_ROOT/ai-agent-core.json"

# Read ai-agent-core version (used when refreshing entrypoint generation
# stamp). Falls back to "unknown" if the JSON cannot be read.
if [[ -f "$CORE_JSON" ]]; then
  VERSION="$(grep -m 1 '"version"' "$CORE_JSON" | sed -E 's/.*"([^"]+)".*/\1/' || echo unknown)"
else
  VERSION="unknown"
fi

########################################
# Args
########################################

DRY_RUN=1
VERBOSE=0
REFRESH_ENTRYPOINTS=1

usage () {
  cat <<USAGE
Usage: $(basename "$0") [--apply] [--keep-entrypoints] [--verbose] [--help]

  (default)               Dry run — print the plan, change nothing.
  --apply                 Execute the plan.
  --keep-entrypoints      Do NOT refresh AGENTS.md / CLAUDE.md from the
                          current scaffold; report drift only. By default
                          they are refreshed when an AI Agent Core
                          generation marker is present.
  --verbose               Extra detail in output.
  --help                  This message.

Run from the host project root (the directory containing ai-agent-core/).

Backups (when --apply): ai-agent-core/generated/migration-backup-<UTC>/
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --apply)             DRY_RUN=0 ;;
    --keep-entrypoints)  REFRESH_ENTRYPOINTS=0 ;;
    --verbose)           VERBOSE=1 ;;
    --help|-h)           usage; exit 0 ;;
    *) echo "Unknown argument: $arg"; usage; exit 2 ;;
  esac
done

########################################
# Helpers
########################################

CHANGES=0
ADVISORIES=0
BACKUP_CREATED=0

say () { echo "$*"; }
note () { [[ $VERBOSE -eq 1 ]] && echo "  · $*" || true; }
# `plan` denotes an action that will be (or has been) executed.
# `advise` denotes a manual-review hint that this script will NOT
# action — it does not affect idempotency.
plan ()    { echo "  → $*"; CHANGES=$((CHANGES + 1)); }
advise ()  { echo "  ⚠ $*"; ADVISORIES=$((ADVISORIES + 1)); }

ensure_backup_dir () {
  if [[ $DRY_RUN -eq 0 && $BACKUP_CREATED -eq 0 ]]; then
    mkdir -p "$BACKUP_DIR"
    BACKUP_CREATED=1
  fi
}

run_mv () {
  local src="$1" dst="$2"
  if [[ $DRY_RUN -eq 1 ]]; then return 0; fi
  mkdir -p "$(dirname "$dst")"
  mv "$src" "$dst"
}

run_cp_r () {
  local src="$1" dst="$2"
  if [[ $DRY_RUN -eq 1 ]]; then return 0; fi
  mkdir -p "$dst"
  # Trailing /. copies contents including dotfiles
  cp -R "$src/." "$dst/"
}

run_rm_rf () {
  local path="$1"
  if [[ $DRY_RUN -eq 1 ]]; then return 0; fi
  rm -rf "$path"
}

run_mkdir_p () {
  local path="$1"
  if [[ $DRY_RUN -eq 1 ]]; then return 0; fi
  mkdir -p "$path"
}

dir_has_content () {
  # returns 0 if path is a non-empty directory
  local path="$1"
  [[ -d "$path" ]] && [[ -n "$(find "$path" -mindepth 1 -print -quit 2>/dev/null)" ]]
}

backup_path_for () {
  # backup destination for a given source path within TARGET_DIR
  local src="$1"
  local rel="${src#$TARGET_DIR/}"
  echo "$BACKUP_DIR/$rel"
}

backup_then_remove () {
  local src="$1"
  local dst
  dst="$(backup_path_for "$src")"
  ensure_backup_dir
  plan "backup $src → $dst"
  if [[ $DRY_RUN -eq 0 ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -R "$src" "$dst"
    rm -rf "$src"
  fi
}

########################################
# Step 1 — legacy host/tasks/ → ai-agent-core/generated/tasks/
########################################
#
# Older versions of bootstrap.sh placed tasks/ at the host project
# root. The new layout puts it inside ai-agent-core/generated/tasks/.
# Move user content, then remove the old directory.

migrate_legacy_host_tasks () {
  local src_dir="$TARGET_DIR/tasks"
  if [[ ! -d "$src_dir" ]]; then return 0; fi

  say ""
  say "[Step 1] Legacy host/tasks/ detected"

  for f in todo.md lessons.md; do
    local src="$src_dir/$f"
    local dst="$TASKS_DIR/$f"
    [[ -f "$src" ]] || continue

    if [[ -f "$dst" ]]; then
      # Conflict — preserve current content at destination.
      ensure_backup_dir
      plan "preserve $dst (already populated); back up legacy $src → $BACKUP_DIR/tasks-$f"
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$src" "$BACKUP_DIR/tasks-$f"
        rm "$src"
      fi
    else
      plan "move $src → $dst"
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$TASKS_DIR"
        mv "$src" "$dst"
      fi
    fi
  done

  # Anything else inside host/tasks/ is unexpected — preserve it.
  if dir_has_content "$src_dir"; then
    ensure_backup_dir
    plan "preserve other files in $src_dir → $BACKUP_DIR/tasks/"
    if [[ $DRY_RUN -eq 0 ]]; then
      mkdir -p "$BACKUP_DIR/tasks"
      cp -R "$src_dir/." "$BACKUP_DIR/tasks/"
    fi
  fi

  if [[ -d "$src_dir" ]]; then
    plan "remove $src_dir/"
    run_rm_rf "$src_dir"
  fi
}

########################################
# Step 2 — legacy host/agent-works/ → ai-agent-core/generated/tasks/legacy-agent-works/
########################################
#
# Pre-tasks/ versions used agent-works/ as the working-state tree. It
# was a mix of agent output and ad-hoc user notes. Treat all of it as
# user content and preserve it under generated/.

migrate_legacy_agent_works () {
  local src_dir="$TARGET_DIR/agent-works"
  if [[ ! -d "$src_dir" ]]; then return 0; fi

  say ""
  say "[Step 2] Legacy host/agent-works/ detected"

  if dir_has_content "$src_dir"; then
    local dst_dir="$TASKS_DIR/legacy-agent-works"
    plan "copy $src_dir/ → $dst_dir/"
    run_cp_r "$src_dir" "$dst_dir"
  fi
  plan "remove $src_dir/"
  run_rm_rf "$src_dir"
}

########################################
# Step 3 — legacy host/agent-spec/ (AI Agent Core-provided shell) + WORK_STATE.md
########################################
#
# The agent-spec/ folder was AI Agent Core-provided scaffolding. It is
# replaced entirely by the ai-agent-core/ tree. Inside it, WORK_STATE.md
# was the prior plan surface — this is user content; archive it.
# Anything else looks like user customisation; back it up before
# removing the directory.

migrate_legacy_agent_spec () {
  local src_dir="$TARGET_DIR/agent-spec"
  if [[ ! -d "$src_dir" ]]; then return 0; fi

  say ""
  say "[Step 3] Legacy host/agent-spec/ detected (replaced by ai-agent-core/)"

  # 1. WORK_STATE.md → archive into tasks/legacy-work-state.md
  local work_state="$src_dir/WORK_STATE.md"
  if [[ -f "$work_state" ]]; then
    local dst="$TASKS_DIR/legacy-work-state.md"
    if [[ -f "$dst" ]]; then
      ensure_backup_dir
      plan "preserve $dst (already exists); back up legacy WORK_STATE.md → $BACKUP_DIR/agent-spec-WORK_STATE.md"
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$work_state" "$BACKUP_DIR/agent-spec-WORK_STATE.md"
        rm "$work_state"
      fi
    else
      plan "archive WORK_STATE.md → $dst"
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$TASKS_DIR"
        mv "$work_state" "$dst"
      fi
    fi
  fi

  # 2. Anything remaining: back up before removal.
  if dir_has_content "$src_dir"; then
    ensure_backup_dir
    plan "back up remaining contents of $src_dir/ → $BACKUP_DIR/agent-spec/"
    if [[ $DRY_RUN -eq 0 ]]; then
      mkdir -p "$BACKUP_DIR/agent-spec"
      cp -R "$src_dir/." "$BACKUP_DIR/agent-spec/"
    fi
  fi

  plan "remove $src_dir/ (AI Agent Core-provided shell, replaced by ai-agent-core/)"
  run_rm_rf "$src_dir"
}

########################################
# Step 4 — legacy host/agent-input/ → ai-agent-core/generated/inputs/
########################################

migrate_legacy_agent_input () {
  local src_dir="$TARGET_DIR/agent-input"
  if [[ ! -d "$src_dir" ]]; then return 0; fi

  say ""
  say "[Step 4] Legacy host/agent-input/ detected"

  if dir_has_content "$src_dir"; then
    plan "copy $src_dir/ → $INPUTS_DIR/"
    run_cp_r "$src_dir" "$INPUTS_DIR"
  fi
  plan "remove $src_dir/"
  run_rm_rf "$src_dir"
}

########################################
# Step 5 — host-root entrypoints (AGENTS.md / CLAUDE.md) refresh
########################################
#
# AGENTS.md and CLAUDE.md at the host root are AI Agent Core-managed by
# default. When they carry the "Generated by ai-agent-core" marker AND
# differ from the current scaffold, refresh them — backing the old
# version up so any user additions are recoverable.
#
# When the marker is absent, the file is assumed user-authored from
# scratch; we report drift but never replace.
#
# Pass --keep-entrypoints to disable refresh entirely (report only).

is_generated_marker_present () {
  local file="$1"
  [[ -f "$file" ]] && grep -q '^Generated by ai-agent-core' "$file"
}

# Strip the trailing "---\nGenerated by ai-agent-core ..." footer (added
# by bootstrap) so we compare the body only.
strip_generated_footer () {
  local file="$1"
  awk '
    BEGIN { footer_start = -1 }
    /^Generated by ai-agent-core/ { footer_start = NR; }
    { lines[NR] = $0; total = NR }
    END {
      stop = total
      if (footer_start > 0) {
        stop = footer_start - 1
        # also drop the preceding "---" separator and a blank line if any
        while (stop > 0 && (lines[stop] == "---" || lines[stop] == "")) stop--
      }
      for (i = 1; i <= stop; i++) print lines[i]
    }
  ' "$file"
}

write_fresh_entrypoint () {
  # Replicate the layout bootstrap.sh produces: scaffold body + blank
  # line + "---" + "Generated by ai-agent-core vX.Y.Z".
  local scaffold="$1" dst="$2"
  cat "$scaffold" > "$dst"
  {
    echo ""
    echo "---"
    echo "Generated by ai-agent-core v$VERSION"
  } >> "$dst"
}

handle_entrypoint () {
  local file="$1"
  local src="$TARGET_DIR/$file"
  local scaffold="$SCAFFOLD_DIR/$file"

  if [[ ! -f "$scaffold" ]]; then
    return 0
  fi

  if [[ ! -f "$src" ]]; then
    say ""
    say "[Step 5] $file is missing at the host root"
    plan "create $file from scaffold"
    if [[ $DRY_RUN -eq 0 ]]; then
      write_fresh_entrypoint "$scaffold" "$src"
    fi
    return 0
  fi

  if ! is_generated_marker_present "$src"; then
    # User-authored from scratch (or marker stripped intentionally).
    # Never overwrite. Report drift only.
    local src_body scaffold_body
    src_body="$(cat "$src")"
    scaffold_body="$(cat "$scaffold")"
    if [[ "$src_body" == "$scaffold_body" ]]; then
      note "$file matches the current scaffold (no marker, no drift)"
    else
      say ""
      say "[Step 5] $file has no AI Agent Core marker — assumed user-authored"
      advise "review $scaffold and reconcile $file manually if needed"
      advise "(not auto-replaced because the file looks user-authored)"
    fi
    return 0
  fi

  # Marker present — compare body.
  local src_body scaffold_body
  src_body="$(strip_generated_footer "$src")"
  scaffold_body="$(cat "$scaffold")"

  if [[ "$src_body" == "$scaffold_body" ]]; then
    # Body matches scaffold; only the version stamp may differ. If so,
    # refresh the stamp; otherwise no-op.
    local current_stamp
    current_stamp="$(grep -m 1 '^Generated by ai-agent-core' "$src" || true)"
    if [[ "$current_stamp" != "Generated by ai-agent-core v$VERSION" ]]; then
      say ""
      say "[Step 5] $file body matches scaffold; version stamp is older"
      plan "refresh $file (rewrite stamp → v$VERSION; body unchanged)"
      if [[ $DRY_RUN -eq 0 ]]; then
        ensure_backup_dir
        cp "$src" "$BACKUP_DIR/$file"
        write_fresh_entrypoint "$scaffold" "$src"
      fi
    else
      note "$file matches the current scaffold"
    fi
    return 0
  fi

  # Body differs from scaffold.
  if [[ $REFRESH_ENTRYPOINTS -eq 0 ]]; then
    say ""
    say "[Step 5] $file differs from the current scaffold (--keep-entrypoints in effect)"
    say "        scaffold: $scaffold"
    say "        current:  $src"
    advise "review the new scaffold and update $file manually"
    return 0
  fi

  say ""
  say "[Step 5] $file differs from the current scaffold"
  say "        scaffold: $scaffold"
  say "        current:  $src"
  ensure_backup_dir
  plan "back up current $file → $BACKUP_DIR/$file"
  plan "rewrite $file from scaffold (stamp v$VERSION)"
  advise "(your additions, if any, are recoverable from the backup)"
  if [[ $DRY_RUN -eq 0 ]]; then
    cp "$src" "$BACKUP_DIR/$file"
    write_fresh_entrypoint "$scaffold" "$src"
  fi
}

check_entrypoints_staleness () {
  handle_entrypoint AGENTS.md
  handle_entrypoint CLAUDE.md
}

########################################
# Step 6 — verify host .gitignore mentions ai-agent-core/generated/
########################################
#
# When ai-agent-core is vendored (not a submodule), the host project's
# .gitignore should also exclude ai-agent-core/generated/.

check_host_gitignore () {
  local gi="$TARGET_DIR/.gitignore"
  # If the host has no .gitignore at all, do nothing — that is the host's
  # decision, not ours.
  [[ -f "$gi" ]] || return 0

  if grep -qE '(^|/)ai-agent-core/generated/?(\s|$)' "$gi" 2>/dev/null \
     || grep -qE '^\s*generated/?\s*$' "$gi" 2>/dev/null; then
    note ".gitignore already mentions ai-agent-core/generated/"
    return 0
  fi

  say ""
  say "[Step 6] Host .gitignore does not mention ai-agent-core/generated/"
  plan "add line 'ai-agent-core/generated/' to $gi (only if ai-agent-core is vendored, not a submodule)"
  if [[ $DRY_RUN -eq 0 ]]; then
    {
      echo ""
      echo "# ai-agent-core runtime state (vendored install only — submodules manage their own .gitignore)"
      echo "ai-agent-core/generated/"
    } >> "$gi"
  fi
}

########################################
# Run
########################################

say "AI Agent Core migration"
say "  ai-agent-core: $CORE_ROOT"
say "  host root:  $TARGET_DIR"
if [[ $DRY_RUN -eq 1 ]]; then
  say "  mode:       DRY RUN  (re-run with --apply to execute)"
else
  say "  mode:       APPLY"
fi

migrate_legacy_host_tasks
migrate_legacy_agent_works
migrate_legacy_agent_spec
migrate_legacy_agent_input
check_entrypoints_staleness
check_host_gitignore

say ""
if [[ $CHANGES -eq 0 ]]; then
  if [[ $ADVISORIES -gt 0 ]]; then
    say "No migration actions required. ($ADVISORIES advisory note(s) above for manual review.)"
  else
    say "No migration actions required."
  fi
  exit 0
fi

if [[ $BACKUP_CREATED -eq 1 ]]; then
  say "Backups: $BACKUP_DIR"
fi

if [[ $DRY_RUN -eq 1 ]]; then
  say ""
  say "Dry run: $CHANGES action(s) planned. Re-run with --apply to perform them."
else
  say ""
  say "Migration complete: $CHANGES action(s) executed."
fi
