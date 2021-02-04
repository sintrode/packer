# packer
Creates a self-extracting batch script with an embedded cabinet containing multiple files.

# Usage
`packer.bat <input_folder>`

# Notes
Put all desired source files in the same folder, then pass that folder as a parameter to the script. The folder may hold up to 65535 files (total file count includes subfolders). Source folder size is limited to 2 GB.
