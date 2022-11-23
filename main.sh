#!/usr/bin/env sh

set -e

eval "${INPUT_SETUPSCRIPT}"

cd /www
if [ "${INPUT_NO404}" = true ]; then
    rm 404.md
fi
bundle exec jekyll build

mkdir "/target-${GITHUB_SHA}"
cd "/target-${GITHUB_SHA}"
git init

git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config remote.origin.url "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}"
git pull --depth=1 origin "${INPUT_TARGETBRANCH}" || git checkout -b "${INPUT_TARGETBRANCH}"

rsync -r --delete --exclude=.git/ /www/_site/ ./
git add .
set +e
git commit -m "ci: deploy with paje"
if [ $? -eq 0 ]; then
    git push --set-upstream origin "${INPUT_TARGETBRANCH}"
fi
