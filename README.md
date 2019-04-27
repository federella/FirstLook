# First Look
FirstLook is a tool for initial malware triage.

It offers a way to quickly gather some basic contextual info before starting the actual reversing process.

## How it works
Right now the script provides the following information:
- File size
- File type (by looking at the __magic bytes__)
- DLLs (also provides basic contextual info for standard libraries)
- Imports
- Interesting strings (IPs, date/time format, URLs...)
## Getting Started
### Usage
Use `firstlook.sh <filename>` to launch the script.

