# packer
Creates a self-extracting batch script with an embedded cabinet containing multiple files.

# Usage
`packer.bat <input_folder>`

# Notes
Put all desired source files in the same folder, then pass that folder as a parameter to the script. Due to limitations with `makecab`, subfolders are not supported.
