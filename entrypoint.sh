#!/bin/sh
set -e

if [ -n "${GITHUB_WORKSPACE}" ] ; then
  cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

misspell -locale="${INPUT_LOCALE}" . \
  | reviewdog -efm="%f:%l:%c: %m" \
      -name="sqfluff (misspell)" \
      -reporter="${INPUT_REPORTER:-github-pr-check}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS}

sqlfluff fix \
  --templater ${INPUT_SQLFLUFF_TEMPLATER} \
  --dialect ${INPUT_SQLFLUFF_DIALECT} \
  | reviewdog -efm="%f:%l:%c: %m" \
      -name="sqlfluff (sqlfluff-fix)" \
      -reporter="${INPUT_REPORTER:-github-pr-check}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS}

