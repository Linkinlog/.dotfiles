#!/usr/bin/env bash

# ANSI escape sequences for colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

# Emojis
CHECK_MARK="\xE2\x9C\x94"
CROSS_MARK="\xE2\x9D\x8C"
ROCKET="\xF0\x9F\x9A\x80"
FIRE="\xF0\x9F\x94\xA5"

# Check if unrar is installed
if ! command -v unrar >/dev/null 2>&1; then
  echo -e "${RED}Error:${RESET} 'unrar' is not installed ${CROSS_MARK}. Please install it and try again ${FIRE}.\n"
  exit 1
fi

# Check for environment variables and use them first
if [ -n "$sonarr_episodefile_sourcefolder" ]; then
  download_path="$sonarr_episodefile_sourcefolder"
elif [ -n "$radarr_moviefile_sourcefolder" ]; then
  download_path="$radarr_moviefile_sourcefolder"
elif [ -n "$1" ]; then
  download_path="$1"
else
  printf "Usage: %s /path/to/rar_archive/directory\n" "$0"
  exit 1
fi

# Use a for loop to process the output of the find command
mapfile -d '' archive_files < <(find "$download_path" -type f -iname "*.rar" -print0)

for archive_path in "${archive_files[@]}"; do
  output_dir="$(dirname "$archive_path")"
  log_file="${output_dir}/archive_extraction_$(date +"%Y%m%d").log"

  separator="${YELLOW}$(printf '*%.0s' {1..50})${RESET}"
  log_entry="\n$separator\n$CYAN$ROCKET Starting extraction process on: $(date) $ROCKET$RESET\n$separator"
  echo -e "$log_entry" | tee -a "$log_file"

  echo -e "${CYAN}Extracting: $archive_path $RESET" | tee -a "$log_file"

  if unrar x -y "$archive_path" "$output_dir" >> "$log_file" 2>&1; then
    success_entry="${GREEN}Extraction successful: $archive_path $CHECK_MARK$RESET\n$separator"
    echo -e "$success_entry" | tee -a "$log_file"
  else
    failure_entry="${RED}Extraction failed: $archive_path $CROSS_MARK$RESET\n$separator"
    echo -e "$failure_entry" | tee -a "$log_file"
  fi
  finish_entry="${CYAN}$FIRE Extraction process finished on: $(date) $FIRE$RESET"
  echo -e "$finish_entry" | tee -a "$log_file"
done
