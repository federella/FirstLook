# First Look
FirstLook is a tool for initial malware triage.\nIt quickly gathers some basic info to provide initial context to the analyst.\n

##How it works
Right now the script provides the following information:\n
- File size
- File type (by looking at the __magic bytes__)
- DLLs (also provides basic contextual info for standard libraries)
- Imports
- Interesting strings (IPs, date/time format, URLs...)
## Getting Started
### Usage
Use `firstlook.sh <filename>` to launch the script.

