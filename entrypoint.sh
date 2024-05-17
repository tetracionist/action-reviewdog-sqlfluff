#!/bin/sh

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

if [ -n "${GITHUB_WORKSPACE}" ] ; then
  cd "${GITHUB_WORKSPACE}/${INPUT_DBT_PROJECT_DIR}" || exit
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

dbt clean && dbt deps

sqlfluff lint --templater ${INPUT_SQLFLUFF_TEMPLATER} --dialect ${INPUT_SQLFLUFF_DIALECT} --disable-progress-bar . --format json > ${GITHUB_WORKSPACE}/lint_output.json

cd "${GITHUB_WORKSPACE}" || exit


python -m json_to_rdjsonl --dbt_project_dir "${INPUT_DBT_PROJECT_DIR}" 

# | reviewdog -efm="%f:%l:%c: %m" \
#     -name="sqlfluff (sqlfluff-fix)" \
#     -reporter="github-pr-check" \
#     -filter-mode="${INPUT_FILTER_MODE}" \
#     -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
#     -level="${INPUT_LEVEL}" \
#     ${INPUT_REVIEWDOG_FLAGS}

