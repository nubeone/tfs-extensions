# Replace tokens task for Visual Studio Team Services
This extension contains a remote XML merge task for VS Team Services to merge two XML files (local or remote) and write the result in a third file (local or remote).

# How to use the build/release task
1. After installing the extension, upload your project to VSTS.
2. Go to your VSTS project, click on the **Release** tab, and create a new release definition.
3. Click **Add tasks** and select **Remote XML Merge** from the **Utility** category.
4. Configure the step.

# Configuration
### For conflicts, use
When a value, node or list exists in both XML files, the Value from the file selected here will be used.

## XML file1 & XML file 2
### File location
Whether the file is on a local or a remote machine. 
### File Path
Path to the XML file on the machine.
### Server Name
Name of the machine where the file is located. 
### Username
Name of a user with read/write permission on the machine.
### Password
Password of the user.

## Target XML file
### File location
Whether the merged result should overwrite file1, file2, saved in a third file local or remote. 


# More information
https://github.com/nubeone/tfs-extensions

# Release notes
**Release 1.1.0**
