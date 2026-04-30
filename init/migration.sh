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
#     <host>/.aiac/tasks/,
#   - relocates host-owned state from earlier ai-agent-core layouts
#     (ai-agent-core/local/, ai-agent-core/generated/) into <host>/.aiac/,
#     keeping the vendor tree (ai-agent-core/) read-only,
#   - removes legacy AGENT-CORE-PROVIDED scaffolding that has been
#     replaced (agent-spec/ shell, etc.),
#   - reports staleness of host-root entrypoints (AGENTS.md, CLAUDE.md)
#     without overwriting them — those may carry user customisation.
#
# Default mode is DRY RUN. Pass --apply to perform actions.
# All destructive moves go through a timestamped backup directory:
#     <host>/.aiac/migration-backup-<UTC timestamp>/
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

# New host-owned layout: <host>/.aiac/...
AIAC_DIR="$TARGET_DIR/.aiac"
TASKS_DIR="$AIAC_DIR/tasks"
INPUTS_DIR="$AIAC_DIR/inputs"
AIAC_CONFIG="$AIAC_DIR/config.yml"

# Earlier layouts (still found in the wild on upgraded installs).
LEGACY_VENDOR_GENERATED_DIR="$CORE_ROOT/generated"
LEGACY_VENDOR_LOCAL_DIR="$CORE_ROOT/local"

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="$AIAC_DIR/migration-backup-$TIMESTAMP"
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

Backups (when --apply): .aiac/migration-backup-<UTC>/
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

dir_has_content () {
  local path="$1"
  [[ -d "$path" ]] && [[ -n "$(find "$path" -mindepth 1 -print -quit 2>/dev/null)" ]]
}

########################################
# Step 1 — legacy host/tasks/ → .aiac/tasks/
########################################
#
# Older versions of bootstrap.sh placed tasks/ at the host project
# root. The current layout puts it inside <host>/.aiac/tasks/.
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
# Step 2 — legacy host/agent-works/ → .aiac/tasks/legacy-agent-works/
########################################

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
# Step 3 — legacy host/agent-spec/ + WORK_STATE.md
########################################

migrate_legacy_agent_spec () {
  local src_dir="$TARGET_DIR/agent-spec"
  if [[ ! -d "$src_dir" ]]; then return 0; fi

  say ""
  say "[Step 3] Legacy host/agent-spec/ detected (replaced by ai-agent-core/)"

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
# Step 4 — legacy host/agent-input/ → .aiac/inputs/
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
# Step 5 — relocate ai-agent-core/local/ → .aiac/
########################################
#
# Earlier versions placed host-owned customisations
# (ai-agent-core.yml, host skills, prompts, references) under the
# vendor tree at ai-agent-core/local/. The current layout puts them
# at <host>/.aiac/, keeping the vendor tree read-only.
#
# The previous config filename was ai-agent-core.yml; the current
# name is config.yml. Move the file with the new name. Other
# entries are moved with their relative paths preserved.

migrate_legacy_vendor_local () {
  local src_dir="$LEGACY_VENDOR_LOCAL_DIR"
  if [[ ! -d "$src_dir" ]]; then return 0; fi

  local non_gitkeep_count
  non_gitkeep_count="$(find "$src_dir" -mindepth 1 ! -name '.gitkeep' -print -quit 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$non_gitkeep_count" == "0" ]]; then
    return 0
  fi

  say ""
  say "[Step 5] Legacy ai-agent-core/local/ detected — relocating to .aiac/"

  while IFS= read -r src; do
    local rel="${src#$src_dir/}"
    [[ "$rel" == ".gitkeep" ]] && continue

    # Rename the legacy config file to its new name.
    local target_rel="$rel"
    if [[ "$rel" == "ai-agent-core.yml" ]]; then
      target_rel="config.yml"
    fi
    local dst="$AIAC_DIR/$target_rel"

    if [[ -e "$dst" ]]; then
      ensure_backup_dir
      plan "preserve $dst (already exists); back up legacy $src → $BACKUP_DIR/local/$rel"
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$(dirname "$BACKUP_DIR/local/$rel")"
        cp "$src" "$BACKUP_DIR/local/$rel"
        rm "$src"
      fi
    else
      plan "move $src → $dst"
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$(dirname "$dst")"
        mv "$src" "$dst"
      fi
    fi
  done < <(find "$src_dir" -type f)

  if [[ $DRY_RUN -eq 0 ]]; then
    find "$src_dir" -type f -name '.gitkeep' -delete 2>/dev/null || true
    find "$src_dir" -depth -type d -empty -delete 2>/dev/null || true
  fi
  if [[ ! -d "$src_dir" ]] || [[ -z "$(ls -A "$src_dir" 2>/dev/null)" ]]; then
    plan "remove $src_dir/ (now empty)"
    run_rm_rf "$src_dir"
  fi
}

########################################
# Step 6 — relocate ai-agent-core/generated/ → .aiac/
########################################
#
# The previous layout put runtime state at ai-agent-core/generated/tasks/
# and inputs at ai-agent-core/generated/inputs/. The current layout
# drops the `generated/` intermediate: tasks live at .aiac/tasks/ and
# inputs at .aiac/inputs/. migration-backup-* directories also move.

migrate_legacy_vendor_generated () {
  local src_dir="$LEGACY_VENDOR_GENERATED_DIR"
  if [[ ! -d "$src_dir" ]]; then return 0; fi

  if [[ -z "$(ls -A "$src_dir" 2>/dev/null)" ]]; then
    return 0
  fi

  say ""
  say "[Step 6] Legacy ai-agent-core/generated/ detected — relocating to .aiac/"

  while IFS= read -r src; do
    local rel="${src#$src_dir/}"
    # Drop the `tasks/`, `inputs/`, `migration-backup-*/` top-level
    # prefix mapping: these sit directly under .aiac/ now.
    local dst="$AIAC_DIR/$rel"

    if [[ -e "$dst" ]]; then
      ensure_backup_dir
      plan "preserve $dst (already exists); back up legacy $src → $BACKUP_DIR/generated/$rel"
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$(dirname "$BACKUP_DIR/generated/$rel")"
        cp "$src" "$BACKUP_DIR/generated/$rel"
        rm "$src"
      fi
    else
      plan "move $src → $dst"
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$(dirname "$dst")"
        mv "$src" "$dst"
      fi
    fi
  done < <(find "$src_dir" -type f)

  if [[ $DRY_RUN -eq 0 ]]; then
    find "$src_dir" -depth -type d -empty -delete 2>/dev/null || true
  fi
  if [[ ! -d "$src_dir" ]] || [[ -z "$(ls -A "$src_dir" 2>/dev/null)" ]]; then
    plan "remove $src_dir/ (now empty)"
    run_rm_rf "$src_dir"
  fi
}

########################################
# Step 7 — host-root entrypoints (AGENTS.md / CLAUDE.md) refresh
########################################

is_generated_marker_present () {
  local file="$1"
  [[ -f "$file" ]] && grep -q '^Generated by ai-agent-core' "$file"
}

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
        while (stop > 0 && (lines[stop] == "---" || lines[stop] == "")) stop--
      }
      for (i = 1; i <= stop; i++) print lines[i]
    }
  ' "$file"
}

write_fresh_entrypoint () {
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
    say "[Step 7] $file is missing at the host root"
    plan "create $file from scaffold"
    if [[ $DRY_RUN -eq 0 ]]; then
      write_fresh_entrypoint "$scaffold" "$src"
    fi
    return 0
  fi

  if ! is_generated_marker_present "$src"; then
    local src_body scaffold_body
    src_body="$(cat "$src")"
    scaffold_body="$(cat "$scaffold")"
    if [[ "$src_body" == "$scaffold_body" ]]; then
      note "$file matches the current scaffold (no marker, no drift)"
    else
      say ""
      say "[Step 7] $file has no AI Agent Core marker — assumed user-authored"
      advise "review $scaffold and reconcile $file manually if needed"
      advise "(not auto-replaced because the file looks user-authored)"
    fi
    return 0
  fi

  local src_body scaffold_body
  src_body="$(strip_generated_footer "$src")"
  scaffold_body="$(cat "$scaffold")"

  if [[ "$src_body" == "$scaffold_body" ]]; then
    local current_stamp
    current_stamp="$(grep -m 1 '^Generated by ai-agent-core' "$src" || true)"
    if [[ "$current_stamp" != "Generated by ai-agent-core v$VERSION" ]]; then
      say ""
      say "[Step 7] $file body matches scaffold; version stamp is older"
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

  if [[ $REFRESH_ENTRYPOINTS -eq 0 ]]; then
    say ""
    say "[Step 7] $file differs from the current scaffold (--keep-entrypoints in effect)"
    say "        scaffold: $scaffold"
    say "        current:  $src"
    advise "review the new scaffold and update $file manually"
    return 0
  fi

  say ""
  say "[Step 7] $file differs from the current scaffold"
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
# Step 8 — provision new scaffold files added in later versions
########################################
#
# When upgrading from an older ai-agent-core, the host may not yet
# have project.yml, docs/, or .aiac/config.yml. Create them from
# the current scaffold without overwriting any existing files the
# host has already authored.

provision_new_scaffold () {
  local provisioned=0

  local project_yml="$TARGET_DIR/project.yml"
  if [[ -f "$SCAFFOLD_DIR/project.yml" && ! -e "$project_yml" ]]; then
    say ""
    say "[Step 8a] project.yml missing at host root"
    plan "create $project_yml from scaffold"
    if [[ $DRY_RUN -eq 0 ]]; then
      cp "$SCAFFOLD_DIR/project.yml" "$project_yml"
    fi
    provisioned=1
  fi

  local docs_src="$SCAFFOLD_DIR/docs"
  local docs_dst="$TARGET_DIR/docs"
  if [[ -d "$docs_src" ]]; then
    local missing_count=0
    while IFS= read -r src_path; do
      local rel="${src_path#$docs_src/}"
      [[ -e "$docs_dst/$rel" ]] || missing_count=$((missing_count + 1))
    done < <(find "$docs_src" -type f)

    if [[ $missing_count -gt 0 ]]; then
      say ""
      say "[Step 8b] docs/ scaffold missing $missing_count file(s) at host root"
      plan "create missing files under $docs_dst/ from scaffold (existing files preserved)"
      if [[ $DRY_RUN -eq 0 ]]; then
        while IFS= read -r src_path; do
          local rel="${src_path#$docs_src/}"
          local dst="$docs_dst/$rel"
          if [[ ! -e "$dst" ]]; then
            mkdir -p "$(dirname "$dst")"
            cp "$src_path" "$dst"
          fi
        done < <(find "$docs_src" -type f)
      fi
      provisioned=1
    fi
  fi

  if [[ -f "$SCAFFOLD_DIR/.aiac/config.yml" && ! -e "$AIAC_CONFIG" ]]; then
    say ""
    say "[Step 8c] .aiac/config.yml missing"
    plan "create $AIAC_CONFIG from scaffold"
    if [[ $DRY_RUN -eq 0 ]]; then
      mkdir -p "$AIAC_DIR"
      cp "$SCAFFOLD_DIR/.aiac/config.yml" "$AIAC_CONFIG"
    fi
    provisioned=1
  fi

  if [[ $provisioned -eq 0 ]]; then
    note "all current scaffold files already provisioned"
  fi
}

########################################
# Step 9 — clean stale .gitignore entries
########################################
#
# Older migration runs added `ai-agent-core/generated/` to the host's
# .gitignore. With the new layout that path no longer exists; the
# entry is harmless but stale. Remove it if present so the .gitignore
# stays accurate. We do NOT add any .aiac/* gitignore advisory here:
# .aiac/ is committed by default; hosts that want per-developer
# task state add `.aiac/tasks/` themselves.

clean_host_gitignore () {
  local gi="$TARGET_DIR/.gitignore"
  [[ -f "$gi" ]] || return 0

  if ! grep -qE '(^|/)ai-agent-core/generated/?(\s|$)' "$gi" 2>/dev/null; then
    return 0
  fi

  say ""
  say "[Step 9] Host .gitignore mentions stale 'ai-agent-core/generated/'"
  plan "remove stale ai-agent-core/generated/ entry from $gi"
  if [[ $DRY_RUN -eq 0 ]]; then
    local tmp
    tmp="$(mktemp)"
    awk '
      BEGIN { skip_next_blank = 0 }
      /^# ai-agent-core runtime state/ { next }
      /(^|\/)ai-agent-core\/generated\/?[[:space:]]*$/ { skip_next_blank = 1; next }
      skip_next_blank && /^$/ { skip_next_blank = 0; next }
      { skip_next_blank = 0; print }
    ' "$gi" > "$tmp"
    mv "$tmp" "$gi"
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
migrate_legacy_vendor_local
migrate_legacy_vendor_generated
check_entrypoints_staleness
provision_new_scaffold
clean_host_gitignore

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
