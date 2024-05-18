#!/bin/sh

# use git to find any changed sql files
git config --global --add safe.directory "${GITHUB_WORKSPACE}"

git fetch --prune --unshallow --no-tags
changed_files=$(cd "${INPUT_DBT_PROJECT_DIR}" && git diff --name-only --diff-filter=AM --relative \
  $GITHUB_SHA "origin/$GITHUB_BASE_REF" -- '*.sql')


# if we find no changed files then terminate the program 
if [ -z "$changed_files" ]; then
  echo "No SQL files changed or added"
  exit 0
fi


# create and activate a virtual environment and install the requirements
# version numbers will be based off of dbt_adapter_version, dbt_core_version and sqfluff_version
# adapter that will install will be based off the dbt_adapter 
cd ${GITHUB_WORKSPACE} || exit

python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt

cd "${GITHUB_WORKSPACE}/${INPUT_DBT_PROJECT_DIR}" || exit



# create an environment variable that we can use to connect to Reviewdog
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# install any dbt dependencies
dbt clean --profiles-dir "${INPUT_DBT_PROFILES_DIR}" && dbt deps --profiles-dir "${INPUT_DBT_PROFILES_DIR}" 


if [[ "${INPUT_SQLFLUFF_MODE}" == "lint" ]]; then

  # run linting and output to a JSON file
  sqlfluff lint --templater "${INPUT_SQLFLUFF_TEMPLATER}" \
    --dialect "${INPUT_DBT_ADAPTER}" \
    --disable-progress-bar $changed_files \
    --format json > "${GITHUB_WORKSPACE}"/lint_output.json

  # navigate back to the top of the workspace
  cd "${GITHUB_WORKSPACE}" || exit

  # run a python script to convert into a JSON structure that Reviewdog can understand
  # the format will use is rdjsonl – https://github.com/reviewdog/reviewdog/tree/master/proto/rdf#rdjsonl
  python -m json_to_rdjsonl --dbt_project_dir "${INPUT_DBT_PROJECT_DIR}" 

  # feed this into Reviewdog and this will now create annotations
  cat < "${GITHUB_WORKSPACE}"/"violations.rdjsonl"| reviewdog -f=rdjsonl \
      -name="sqlfluff (sqlfluff-lint)" \
      -reporter="${INPUT_REPORTER:-github-pr-check}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS}

elif [[ "${INPUT_SQLFLUFF_MODE}" == "fix" ]]; then

  # for fix mode run the fix command
  sqlfluff fix --templater "${INPUT_SQLFLUFF_TEMPLATER}" \
    --dialect "${INPUT_DBT_ADAPTER}" $changed_files

  # navigate to the top of the workspace or we will not be able to 
  cd "${GITHUB_WORKSPACE}" || exit

  # send the git working changes to a temporary file and then discard any working changes
  # Reviewdog use the differences between these to generate comments on linting violations and suggest fixes 
  TMPFILE=$(mktemp)
  git diff >"${TMPFILE}"
  git stash -u && git stash drop
  reviewdog -name="sqlfluff (sqlfluff-fix)" \
    -f=diff \
    -f.diff.strip=1 \
    -reporter="${INPUT_REPORTER:-github-pr-review}" < "${TMPFILE}"

fi

