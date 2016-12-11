#!/usr/bin/env bash

cd $(dirname $0)/..
set -x

set -e
npm run bootstrap
npm run build:gulp
set +e


# GITHUB publish
MODULES=$(ls packages)

for module in $MODULES; do
  if [ -e "packages/$module/package.json" ]; then
    IS_PRIVATE=$(echo "console.log(require('./packages/$module/package.json').private)" | node)
    if [[ $IS_PRIVATE == "true" ]]; then
      echo "Skipping private package @blueprintjs/$module"
      continue
    fi

    if [[ $module != "core" ]]; then
      echo "Skipping, now deploying only core"
      continue
    fi

    # VER_TO_PUBLISH=$(echo "console.log(require('./packages/$module/package.json').version)" | node)
    VER_TO_PUBLISH=$(git rev-list HEAD --count)
    # VERSIONS=$(npm info @blueprintjs/$module versions || echo "new_package")

    TAG_NAME=$(echo $module)_v$VER_TO_PUBLISH

    # check if tag exists
    git ls-remote --tags 2>/dev/null | grep $TAG_NAME 1>/dev/null
    if [ "$?" == 0 ]; then
      echo "Git tag $TAG_NAME exists."
    else
      set -e
      BRANCH_NAME=$(git name-rev --name-only HEAD)
      git branch -D build || true
      git checkout --orphan build

      # cleanup files and release to github
      find . -mindepth 1 -maxdepth 1 ! -name "index.js" ! -name ".git" ! -name ".gitignore" ! -name "build" ! -name "dist" ! -name "generated" ! -name "coverage" ! -name "README.md" ! -name "node_modules" ! -name "packages" -exec rm -r "{}" \;
      rm -rf packages/$module/node_modules 
      cp -r packages/$module/* .
      rm -rf packages src test examples .npmignore
      touch .npmignore
      git add .
      # add gitignored
      git add dist --force 
      git commit -m "Release $TAG_NAME"
      git tag -a $TAG_NAME -m "Release $TAG_NAME"
      git push origin $TAG_NAME
      git checkout $BRANCH_NAME
    fi
  fi
done
