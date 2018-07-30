# To Build:
npm install
npm run build

# Notes:

A "contribution" is a task as it appears in the build/release definition. An extension can define multiple such contributions.
In the extension manifest (here: test.json) the contributions.properties.name MUST be identical to the name of the folder containing that contribution. Else installing the extension will work, but (silently) fail to actually add any contributions (tasks) to TFS.