# Install the VSDS Task SDK and move it to the folder where it needs to be
if (!(Test-Path "$PSScriptRoot\task\ps_modules")) {
    New-Item -ItemType directory -Path "$PSScriptRoot\task\ps_modules" # create folder for ps_modules
    Save-Module -Name VstsTaskSdk -Path "$PSScriptRoot\task\ps_modules" -RequiredVersion "0.11.0" # install VstsTaskSdk into that folder
    Get-ChildItem "$PSScriptRoot\task\ps_modules\VstsTaskSdk\0.11.0\*" -Force | Move-Item -Destination "$PSScriptRoot\task\ps_modules\VstsTaskSdk" # move files out of version folder (TFS doesn't find them there)
    New-Item -ItemType directory -Path "$PSScriptRoot\dist" # create dist folder
}
# package the extension
tfx extension create --manifest-globs "changelogGeneartor.json" --output-path "$PSScriptRoot\dist"
