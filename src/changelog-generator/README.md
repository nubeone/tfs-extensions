# Changelog Generator task for Visual Studio Team Services
This extension contains a Changelog Generator task for VS Team Services to generate a changelog from git commits and write it to a file.

# How to use the build/release task
1. After installing the extension, upload your project to VSTS.
2. Go to your VSTS project, click on the **Release** tab, and create a new release definition.
3. Click **Add tasks** and select **Changelog Generator** from the **Utility** category.
4. Configure the step.

# Configuration
## Working Directory
Home directory of the repository
## Filename
How the changelog file will be named.
## Commits
Whether a complete changelog or only back to the last tag should be created.


# More information
https://github.com/nubeone/tfs-extensions