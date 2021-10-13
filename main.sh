#!/usr/bin/env sh

set -e

git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config remote.origin.url "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}"

eval "${INPUT_SETUPSCRIPT}"

git fetch origin "${INPUT_TARGETBRANCH}" || true
git checkout -t origin/"${INPUT_TARGETBRANCH}" || git checkout -b "${INPUT_TARGETBRANCH}"
git rm -rf "*" ".*" --ignore-unmatch

cd /www
if [ "${INPUT_NO404}" = true ]; then
    rm 404.md
fi

bundle exec jekyll build -d "${GITHUB_WORKSPACE}"

cd "${GITHUB_WORKSPACE}"
git add .

set +e
git commit -m "Deploy using paje"
if [ $? -eq 0 ]; then
    git push --set-upstream origin "${INPUT_TARGETBRANCH}"
fi
