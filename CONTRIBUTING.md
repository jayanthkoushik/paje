# Releasing a new version

Run `standard-version -r <major/minor/patch>`. This will created a tagged commit
bumping the version. Pushing the commit will start a GitHub actions workflow
which will upload the latest Docker image with the version tag.
