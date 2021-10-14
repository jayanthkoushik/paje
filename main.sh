#!/usr/bin/env sh

set -e

eval "${INPUT_SETUPSCRIPT}"

cp -r /www ${GITHUB_SHA}
cd ${GITHUB_SHA}
if [ "${INPUT_NO404}" = true ]; then
    rm 404.md
fi
bundle exec jekyll build
cd ..

git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config remote.origin.url "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}"

git fetch --depth=1 origin "${INPUT_TARGETBRANCH}" || true
git checkout -t origin/"${INPUT_TARGETBRANCH}" || git checkout -b "${INPUT_TARGETBRANCH}"

rsync -r --delete --exclude=${GITHUB_SHA} --exclude=.git/ "${GITHUB_SHA}/_site/" ./
rm -rf ${GITHUB_SHA}

git add .
set +e
git commit -m "ci: deploy with paje"
if [ $? -eq 0 ]; then
    git push --set-upstream origin "${INPUT_TARGETBRANCH}"
fi
