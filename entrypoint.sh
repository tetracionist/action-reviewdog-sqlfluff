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


if [[ "${INPUT_SQLFLUFF_MODE}" == "lint" ]]; then
  sqlfluff lint --templater "${INPUT_SQLFLUFF_TEMPLATER}" --dialect "${INPUT_SQLFLUFF_DIALECT}" --disable-progress-bar . --format json > "${GITHUB_WORKSPACE}"/lint_output.json

  cd "${GITHUB_WORKSPACE}" || exit

  python -m json_to_rdjsonl --dbt_project_dir "${INPUT_DBT_PROJECT_DIR}" 

  cat < "${GITHUB_WORKSPACE}"/"violations.rdjsonl"| reviewdog -f=rdjsonl \
      -name="sqlfluff (sqlfluff-lint)" \
      -reporter="${INPUT_REPORTER:-github-pr-check}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      "${INPUT_REVIEWDOG_FLAGS}"

elif [[ "${INPUT_SQLFLUFF_MODE}" == "fix" ]]; then
  sqlfluff fix --templater dbt --dialect snowflake --disable-progress-bar .

  TMPFILE=$(mktemp)
  git diff >"${TMPFILE}"
  git stash -u && git stash drop
  reviewdog -f=diff \
    -f.diff.strip=1 \
    -reporter="${INPUT_REPORTER:-github-pr-check}"< "${TMPFILE}"

fi

