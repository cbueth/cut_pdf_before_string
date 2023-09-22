#!/bin/bash
# cut_contents.sh: Remove contents from pdfs.
# Usage: cut_contents.sh /path/to/folder/with/pdfs
# The script will create a subfolder called "cut" in the folder with the respective pdf.
# The cut pdfs will be saved in that subfolder.
# Dependencies: pdftk, pdfgrep, some pdf viewer (evince, okular, ...)


## =================================================
## Variables
## =================================================

# SEARCH_STRING: String to search for in pdfs
SEARCH_STRING="Kommentare"
# APPENDIX:      String that is appended to the filename of the cut pdfs
APPENDIX="_ohnekommentare"
# EXPECTED_LENS: Array of expected page numbers, if the page number is not in the array,
#                a warning is printed. Leave empty to disable this feature.
EXPECTED_LENS=(6 7)
# PDF_VIEWER:    Viewer for pdfs, e.g. evince, okular, ...
PDF_VIEWER=evince
# PARALLEL:      Number of pdfs that are processed in parallel,
#                set to 1 to process pdfs sequentially
PARALLEL=20
# ASK_FOR_PAGE:  If set to 1, the script will ask for the page number of the first page
#                that contains $SEARCH_STRING if `pdfgrep` does not find any page.
#                If set to 0, the script will copy the whole pdf to the subfolder.
ASK_FOR_PAGE=1

## =================================================
## Description
## =================================================

#  It works like this:
#  1. Find the first page number that contains the $SEARCH_STRING.
#     If the pdf is only one page long, no cut is needed.
#     Elif no page contains the string, open the pdf and ask the user for the page
#     number.
#  2. Cut the pdf before that page.
#  3. Save the result in a subfolder.


## =================================================
## Functions
## =================================================

# Get first page number that contains a string
# $1: path to pdf
# $2: string to search for
#
# Returns the page number
get_page_number() {
    local page_number
    page_number=$(pdfgrep -n "$2" "$1" | head -n 1 | cut -d: -f1)

    if [ -z "$page_number" ]; then
        page_number=0
    fi
    echo "$page_number"
}

# Get number of pages in pdf
# $1: path to pdf
#
# Returns the number of pages
get_number_of_pages() {
    local number_of_pages
    number_of_pages=$(pdftk "$1" dump_data | grep NumberOfPages | cut -d: -f2)
    echo "$number_of_pages"
}

# Process file
# $1: path to pdf
#
# Returns 0 if pdf was processed successfully
process_pdf() {
    # Get filename without extension
    filename=$(basename "$1" .pdf)
    echo "Processing pdf $1."
    folder=$(dirname "$1")
    # create subfolder "cut" if it does not exist
    mkdir -p "$folder"/cut
    # Get number of pages (returned with leading space)
    number_of_pages=$(get_number_of_pages "$1")

    # If pdf is only one page long, no cut is needed
    if [ "$number_of_pages" -eq 1 ]; then
        echo "Pdf $1 is only one page long. No cut needed, saving it in subfolder."
        cp "$1" "$folder"/cut/"$filename""$APPENDIX".pdf
        return 0
    fi
    # Get page number of first page that contains $SEARCH_STRING
    page_number=$(get_page_number "$1" "$SEARCH_STRING")
    # ASK_FOR_PAGE: If no page contains "$SEARCH_STRING", open pdf and ask for page
    # number
    if [ "$page_number" -eq 0 ] && [ "$ASK_FOR_PAGE" -eq 1 ]; then
        echo "No page contains the string \"$SEARCH_STRING\"."
        # Pdf is opened automatically in background, after closing the viewer the script
        # continues and waits for the user to enter the page number
        $PDF_VIEWER "$1" &
        echo "Please enter the page number of the first page that contains \"$SEARCH_STRING\"."
        read -r page_number
        # Check if page number is valid
        if [ "$page_number" -lt 1 ] || [ "$page_number" -gt "$number_of_pages" ]; then
            echo "Invalid page number, skipping pdf $1."
            return 1
        fi
    elif [ "$page_number" -eq 0 ] && [ "$ASK_FOR_PAGE" -eq 0 ]; then
        echo "No page contains the string \"$SEARCH_STRING\"."
        echo "No cut needed, saving pdf in subfolder."
        cp "$1" "$folder"/cut/"$filename""$APPENDIX".pdf
        return 0
    fi
    # If page_number is not in the expected range, print a warning
    # and EXPECTED_LENS is empty, no warning is printed
    if [ -n "${EXPECTED_LENS[*]}" ] && ! [[ " ${EXPECTED_LENS[*]} " =~ ${page_number} ]]; then
        echo -e "\e[33mWarning: Unusual page number $page_number in pdf $1.\e[0m"
    fi
    # Cut pdf before page number
    echo "Cutting pdf $1 before page $page_number."
    pdftk "$1" cat 1-"$((page_number-1))" output "$folder"/cut/"$filename""$APPENDIX".pdf
    return 0
}

## =================================================
## Main
## =================================================

# Check if folder was given as argument
if [ -z "$1" ]; then
    echo "Usage: cut_contents.sh /path/to/folder/with/pdfs"
    exit 1
fi
# Check if folder exists
if [ ! -d "$1" ]; then
    echo "Folder $1 does not exist."
    exit 1
fi
# Check recursively if folder contains pdfs - max depth of 3
if [ -z "$(find "$1" -maxdepth 3 -type f -name "*.pdf" -print -quit)" ]; then
    echo "Folder $1 does not contain any pdfs."
    exit 1
fi

# as pdfs are created while the script is running, first create a list of pdfs
# and then loop over that list
pdfs=$(find "$1" -maxdepth 3 -type f -name "*.pdf" -print)
# discard pdfs that are already in subfolder "cut"
pdfs=$(echo "$pdfs" | grep -v "/cut/")
echo "Will process $(echo "$pdfs" | wc -l) pdfs..."

# Loop over pdfs recursively in folder $1
if [ "$PARALLEL" -le 1 ]; then
    echo "Processing pdfs sequentially."
    for pdf in $pdfs; do
        process_pdf "$pdf"
    done
else
    # The for loop can be parallelized with xargs -P
    echo "Processing pdfs in parallel."
    export PDF_VIEWER
    # export functions so they can be used by xargs
    export -f get_page_number
    export -f get_number_of_pages
    export -f process_pdf
    echo "$pdfs" | xargs -I {} -P "$PARALLEL" bash -c 'process_pdf "$@"' _ {}
fi

echo "Done."
