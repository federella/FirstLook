# First Look
FirstLook is a tool for initial malware triage.

It offers a way to quickly gather some basic contextual info before starting the actual reversing process.

## How it works
Right now the script provides the following information:
- File size, file type, MD5/SHA256
- DLLs (also provides basic contextual info for standard libraries)
- Imports
- Interesting strings (IPs, date/time format, URLs...)
- **NEW!** support for packers indicators
- **NEW!** bitcoin addresses check (thanks to __serhack__) 
- **NEW!** optimized code (thanks to __Enrico204__)
## Getting Started
### Usage
Use `firstlook.sh <filename>` to launch the script.

