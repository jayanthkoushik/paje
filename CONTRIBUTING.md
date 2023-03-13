# Releasing a new version

Run `standard-version -r <major/minor/patch>`. This will created a tagged commit
bumping the version. Pushing the commit will start a GitHub actions workflow
which will upload the latest Docker image with the version tag. The major
version tag will need to be force pushed to update the repository.

If major version is bumped, update example in README.
