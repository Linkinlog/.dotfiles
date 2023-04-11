#!/usr/bin/env bash

# Check if unrar is installed
if ! command -v unrar >/dev/null 2>&1; then
  printf "\033[31mError:\033[0m 'unrar' is not installed. Please install it and try again.\n"
  exit 1
fi

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

verbose=false
while getopts ":v" option; do
  case "$option" in
    v)
      verbose=true
      ;;
    *)
      printf "Usage: %s [-v] /path/to/download/directory\n" "$0"
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

download_path="$1"

find "$download_path" -type f -iname "*.rar" -print0 \
  | while IFS= read -r -d '' archive_path; do
      output_dir="$(dirname "$archive_path")"
      log_file="${output_dir}/archive_extraction_$(date +"%Y%m%d").log"
      
      separator="${YELLOW}$(printf '*%.0s' {1..50})${RESET}"
      echo -e "\n$separator\n$CYAN$ROCKET Starting extraction process on: $(date) $ROCKET$RESET\n$separator" | tee -a "$log_file"
      
      if $verbose; then
        echo -e "${CYAN}Extracting: $archive_path $RESET"
      fi
      echo -e "${CYAN}Extracting: $archive_path $RESET" >> "$log_file"

      if unrar x -y "$archive_path" "$output_dir" >> "$log_file" 2>&1; then
        if $verbose; then
          echo -e "${GREEN}Extraction successful: $archive_path $CHECK_MARK$RESET$CYAN\n$separator $RESET"
        fi
        echo -e "${GREEN}Extraction successful: $archive_path $CHECK_MARK$RESET\n$separator" >> "$log_file"
      else
        if $verbose; then
          echo -e "${RED}Extraction failed: $archive_path $CROSS_MARK$RESET$CYAN\n$separator $RESET"
        fi
        echo -e "${RED}Extraction failed: $archive_path $CROSS_MARK$RESET\n$separator" >> "$log_file"
      fi

      echo -e "${CYAN}$FIRE Extraction process finished on: $(date) $FIRE$RESET"
      echo -e "$separator" | tee -a "$log_file"
    done
