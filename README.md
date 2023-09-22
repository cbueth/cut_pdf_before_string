[![Shellcheck](https://github.com/cbueth/cut_pdf_before_string/actions/workflows/lint-sh.yml/badge.svg?branch=main)](https://github.com/cbueth/cut_pdf_before_string/actions/workflows/lint-sh.yml)

# PDF Cut Script

This is a bash script that uses `pdfgrep` and `pdftk` to cut pdfs before the first page,
containing a given string.

This script takes the pdfs from a folder recursively and cuts them at the right page,
saving the result in the same location at a subfolder:
`cut/{filename}{appendix}.pdf`.

It works like this:
1. Find the first page number that contains the `$SEARCH_STRING`.
   If the pdf is only one page long, no cut is needed.
   Elif no page contains the string, open the pdf and ask the user for the page
   number (can be deactivated).
2. Cut the pdf before that page.
3. Save the result in a subfolder.

## Requirements

The script is written in `bash`.
To identify the page number, we use the `pdfgrep` tool.
To cut the pdf, we use `pdftk`.
The pdfs need to include text, rasterized pdfs will not work.

## Usage

The script takes one argument: the path to the folder containing the pdfs.
It will recursively (three levels deep) search for pdfs and cut them.

```bash
./cut_contents.sh <path>
```

Further variables can be set in the script.
Specifically, the string to search for can be changed,
and the appendix sting can be changed.
It is also possible to give an expected number of pages.
If the cut is made at a different page, the script will print a warning.
A default PDF viewer can be set, which will be used to open the pdfs.
Lastly, parallel processing can be enabled, which can speed up the process.

## Check Cut PDFs

To check the cut pdfs, the script `check_cut_pdfs.sh` can be used.
Using `evince`, it will open the original pdfs at the last page.

```bash
./check_cut_pdfs.sh <path>
```

## License

As `pdfgrep` and `pdftk` are licensed under the GPL, this script is licensed under the GPL as well.
GPLv3 is used, see [LICENSE](LICENSE) for details.
