#!/bin/sh
# shellcheck shell=sh
# ============================================================================
# lib/plugins.sh — Plugin Engine (discovery, metadata, and scoped synchronization)
# ============================================================================

find_plugin_dir() {
  _query="$1"
  _sdir="$(dirname "$SCRIPT_LOCATION")"
  for _cand in \
    "$NEXUS_DIR/.rnex/plugins/$_query" \
    "$NEXUS_DIR/.nexus/plugins/$_query" \
    "$NEXUS_DIR/plugins/$_query" \
    "$NEXUS_DIR/toolkit/plugins/$_query" \
    "$SCRIPT_LOCATION/toolkit/plugins/$_query" \
    "$_sdir/toolkit/plugins/$_query"; do
    if [ -f "$_cand/plugin.yaml" ]; then
      printf '%s' "$_cand"
      return 0
    fi
  done
  return 1
}

list_all_available_plugin_dirs() {
  _sdir="$(dirname "$SCRIPT_LOCATION")"
  _dirs=""
  for _parent in \
    "$SCRIPT_LOCATION/toolkit/plugins" \
    "$_sdir/toolkit/plugins" \
    "$NEXUS_DIR/toolkit/plugins" \
    "$NEXUS_DIR/.rnex/plugins" \
    "$NEXUS_DIR/.nexus/plugins" \
    "$NEXUS_DIR/plugins"; do
    if [ -d "$_parent" ]; then
      for _sub in "$_parent"/*; do
        if [ -d "$_sub" ] && [ -f "$_sub/plugin.yaml" ]; then
          _b="$(basename "$_sub")"
          case " $_dirs " in
            *" $_b "*) ;;
            *)
              _dirs="$_dirs $_b"
              printf '%s\n' "$_sub"
              ;;
          esac
        fi
      done
    fi
  done
}

plugin_get_field() {
  _pdir="$1"; _fld="$2"
  [ -f "$_pdir/plugin.yaml" ] || return 1
  awk -v fld="$_fld" '
    $0 ~ ("^" fld ":") {
      sub("^" fld ":[ ]*", "");
      sub(/[ ]*#.*/, "");
      print
    }
  ' "$_pdir/plugin.yaml"
}

plugin_list_rules() {
  _pdir="$1"
  [ -f "$_pdir/plugin.yaml" ] || return 0
  awk '
    /^(rules|instructions|ai_files):[ ]*(#.*)?$/ { in_sec = 1; next }
    in_sec && /^[^ #]/ { in_sec = 0 }
    in_sec && /^[ ]*-[ ]*/ {
      line = $0
      sub(/^[ ]*-[ ]*/, "", line)
      sub(/[ ]*#.*/, "", line)
      if (length(line) > 0) print line
    }
  ' "$_pdir/plugin.yaml"
}

plugin_list_templates() {
  _pdir="$1"
  [ -f "$_pdir/plugin.yaml" ] || return 0
  awk '
    /^templates:/ { t=1; next }
    t && /^[^ #]/ { exit }
    t && /^[ ]*-[ ]*/ {
      sub(/^[ ]*-[ ]*/, "");
      sub(/[ ]*#.*/, "");
      if (length($0) > 0) print $0
    }
  ' "$_pdir/plugin.yaml"
}

# Sync plugins into scoped directories: .rnex/plugins/<plugin-name>/
sync_plugins() {
  yaml_list_plugins | while read -r _pname; do
    [ -n "$_pname" ] || continue
    _pdir="$(find_plugin_dir "$_pname" 2>/dev/null || true)"
    if [ -z "$_pdir" ]; then
      log_warn "Plugin '$_pname' declared in config but not found on disk"
      continue
    fi

    _scoped_dest="$NEXUS_DIR/.rnex/plugins/$_pname"
    if [ "$_pdir" != "$_scoped_dest" ]; then
      mkdir -p "$_scoped_dest"

      # Copy rules, workflows, instructions, prompts, skills, agents into scoped plugin directory
      for _sub in rules workflows instructions prompts skills agents; do
        if [ -d "$_pdir/$_sub" ]; then
          mkdir -p "$_scoped_dest/$_sub"
          cp -r "$_pdir/$_sub"/* "$_scoped_dest/$_sub"/ 2>/dev/null || true
        fi
      done
      if [ -f "$_pdir/plugin.yaml" ]; then
        cp "$_pdir/plugin.yaml" "$_scoped_dest/plugin.yaml"
      fi
    fi

    # Initialize templates declared in plugin (functional external dirs like raw/, wiki/)
    plugin_list_templates "$_pdir" | while read -r _item; do
      [ -n "$_item" ] || continue
      _s="${_item%%:*}"
      _d="${_item#*:}"
      _s="$(printf '%s' "$_s" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      _d="$(printf '%s' "$_d" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      _src_path="$_pdir/$_s"
      _dest_path="$NEXUS_DIR/$_d"

      if [ -f "$_src_path" ] && [ ! -f "$_dest_path" ]; then
        mkdir -p "$(dirname "$_dest_path")"
        cp "$_src_path" "$_dest_path"
        [ -x "$_src_path" ] && chmod +x "$_dest_path" 2>/dev/null || true
        log_ok "Initialized template: $_d"
      fi
    done
  done
}
