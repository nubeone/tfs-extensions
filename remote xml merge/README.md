# Replace tokens task for Visual Studio Team Services
This extension contains a remote XML merge task for VS Team Services to merge an XML file from build or file system into an XML file on a target server.

# How to use the build/release task
1. After installing the extension, upload your project to VSTS.
2. Go to your VSTS project, click on the **Release** tab, and create a new release definition.
3. Click **Add tasks** and select **Remote XML Merge** from the **Utility** category.
4. Configure the step.

# Configuration
## Source XML File
The source of the new XML to merge. Usually an XML file in the build output.
### New XML file
Path to the local XML file.
Example: $(System.DefaultWorkingDirectory)/$(Build.DefinitionName)/drop/$(Build.BuildNumber)/Config.xml

## Target XML file
The target of the XML merge.
### Existing XML file
Path to the XML file on the target machine.
Example: C:\inetpub\wwwroot\myProject\Config.xml
### Server Name
Name of the machine where the target file is located. 
### Username
Name of a user with read/write permission on the target XML file
### Password
Password of the user.

# More information
See our Wiki: https://github.com/nubeone/tfs-extensions/wiki

# Release notes
**Release 1.0.0**
Extension released