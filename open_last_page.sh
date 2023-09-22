#!/bin/bash
# open_last_page.sh: Look at the last page of a pdf.
# Usage: open_last_page.sh /path/to/folder/with/pdfs
# The script will open the cut pdfs, one after another on the last page.
# Dependencies: evince

NUM_OPEN_AT_ONCE=5

# Get all pdfs in the folder if they are in a subfolder called "cut",
# recursively till depth 4
pdfs=$(find "$1" -maxdepth 4 -type f -name "*.pdf" -path "*/cut/*")

open_last_page() {
    # ask evince to open the pdf on the last page
    evince "$1" -p "$(pdftk "$1" dump_data | grep "NumberOfPages" | awk '{print $2}')"
}

export -f open_last_page
echo "$pdfs" | xargs -I {} -P "$NUM_OPEN_AT_ONCE" bash -c 'open_last_page "$@"' _ {}

echo "Done."