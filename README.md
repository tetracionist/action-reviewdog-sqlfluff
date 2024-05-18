# action-reviewdog-sqlfluff

<!-- TODO: replace reviewdog/action-template with your repo name -->
[![Test](https://github.com/reviewdog/action-template/workflows/Test/badge.svg)](https://github.com/reviewdog/action-template/actions?query=workflow%3ATest)
[![reviewdog](https://github.com/reviewdog/action-template/workflows/reviewdog/badge.svg)](https://github.com/reviewdog/action-template/actions?query=workflow%3Areviewdog)
[![depup](https://github.com/reviewdog/action-template/workflows/depup/badge.svg)](https://github.com/reviewdog/action-template/actions?query=workflow%3Adepup)
[![release](https://github.com/reviewdog/action-template/workflows/release/badge.svg)](https://github.com/reviewdog/action-template/actions?query=workflow%3Arelease)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/reviewdog/action-template?logo=github&sort=semver)](https://github.com/reviewdog/action-template/releases)
[![action-bumpr supported](https://img.shields.io/badge/bumpr-supported-ff69b4?logo=github&link=https://github.com/haya14busa/action-bumpr)](https://github.com/haya14busa/action-bumpr)

## Get SQLFluff linting code violations as comments or annotations
_Note: any linting violations in the base commit will leave comments in the base commit, annotations will not work_ 
![linting-check-comment](https://github.com/tetracionist/action-reviewdog-sqlfluff/assets/40890820/4574e1d0-d63d-4df7-b1ed-9356f81b5395)
![linting check annotations](https://github.com/tetracionist/action-reviewdog-sqlfluff/assets/40890820/1916c34d-c2fc-46c9-905c-b2dbcf401d27)

## Get SQLFluff fix suggestions as comments 
_Note: that you need to fix linting violations in the base commit first_
![fix-comment](https://github.com/tetracionist/action-reviewdog-sqlfluff/assets/40890820/93b97c79-b1f0-4a56-b9dd-3bf3807ad64e)


This GitHub Action enables you to lint and fix SQL code via [SQLFluff](https://sqlfluff.com/) for different dialects with the dbt templater. 
Primarily I have favoured the Snowflake dialect, but there is also support for other dialects and can be extended by using the profiles.yml located in the `testdata/dbt` folder

If using multiple dialects, for example you might Materialize for real-time data and Snowflake for batch, then please create two separate workflows using this GitHub action. 
I will add examples below on how this can be done. 

Note: If you have existing linting violations in the base commit of a pull request, the action will not create annotations.
Instead, it will make comments on the base commit and will not give you suggestions. 

## Input
```yaml
inputs:
  github_token:
    description: 'GITHUB_TOKEN'
    default: '${{ github.token }}'
  workdir:
    description: 'Working directory relative to the root directory.'
    default: '.'

  ### Flags for reviewdog ###
  level:
    description: 'Report level for reviewdog [info,warning,error]'
    default: 'error'
  reporter:
    description: 'Reporter of reviewdog command [github-pr-check,github-check,github-pr-review].'
    default: 'github-pr-check'
  filter_mode:
    description: |
      Filtering mode for the reviewdog command [added,diff_context,file,nofilter].
      Default is added.
    default: 'added'
  fail_on_error:
    description: |
      Exit code for reviewdog when errors are found [true,false]
      Default is `false`.
    default: 'false'
  reviewdog_flags:
    description: 'Additional reviewdog flags'
    default: ''

  ### Flags for dbt ###
  dbt_adapter: 
    description: |
      The dbt adapter is the dialect (e.g. snowflake)
      This will install the correct adapter version of dbt
    default: snowflake
  dbt_adapter_version:
    description: |
      The dbt adapter version
      This may not match the dbt-core version in some cases
    default: 1.7.4
  dbt_core_version: 
    description: |
      As of dbt version 1.8, the dbt-core version will need to be specified
      Henceforth I have added this as an input
    default: 1.7.14
  dbt_profiles_dir:
    description: | 
      Will also need to set this up in the .sqlfluff file, needs to be relative to your dbt project directory
      Recommend you copy the profiles_linter directory and place this in your dbt project
    default: ./profiles_linter
  dbt_project_dir:
    description: This is where your dbt project directory is located
    default: ./testdata/dbt
  dbt_target: 
    description: | 
      The name of the target you need
      Recommend you copy the profiles_linter directory and place this in your dbt project
    default: snowflake

  ### Flags for sqlfluff ###
  sqlfluff_mode:
    description: | 
      fix or lint: 
       - fix shows suggestions of how to fix your code within your PR
       - lint reports violations will only report the violation
    default: lint
  sqlfluff_templater:
    description: templater for the sql, you probably won't need to change this
    default: dbt
  sqlfluff_version:
    description: Version for sqlfluff
    default: 3.0.6
```

## Usage

By default these are the actions you should use for linting or fixing SQL files within a dbt project
These will execute the Snowflake adapter and releveant profiles within your dbt directory. 


```yaml
name: sqlfluff lint
on: [pull_request]
jobs:
  test-pr-review-lint:
    name: runner / sqlfluff-lint (github-pr-review)
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write 
    env:
      ACCOUNT: ${{ secrets.ACCOUNT }}
      USERNAME: ${{ secrets.USER }}
      PASSWORD: ${{ secrets.PASSWORD }}
      DATABASE: ${{ secrets.DATABASE }}
      SCHEMA: ${{ secrets.SCHEMA }}
      WAREHOUSE: ${{ secrets.WAREHOUSE }}
    steps:
      - uses: actions/checkout@v4
      - uses: tetracionist/action-reviewdog-sqlfluff@v0.1.2
        with:
          github_token: ${{ secrets.github_token }}
          dbt_project_dir: ./testdata/dbt
          level: error 
          reporter: github-pr-review
          sqlfluff_mode: lint


name: sqlfluff fix
on: [pull_request]
jobs:
  test-pr-review-fix:
    name: runner / sqlfluff-fix (github-pr-review)
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write 
    env:
      ACCOUNT: ${{ secrets.ACCOUNT }}
      USERNAME: ${{ secrets.USER }}
      PASSWORD: ${{ secrets.PASSWORD }}
      DATABASE: ${{ secrets.DATABASE }}
      SCHEMA: ${{ secrets.SCHEMA }}
      WAREHOUSE: ${{ secrets.WAREHOUSE }}
    
    steps:
      - uses: actions/checkout@v4
      - uses: tetracionist/action-reviewdog-sqlfluff@v0.1.2
        with:
          github_token: ${{ secrets.github_token }}
          dbt_project_dir: ./testdata/dbt
          level: error 
          reporter: github-pr-review
          sqlfluff_mode: fix

```

If you have multiple adapters, e.g. Snowflake for batch data and Materialize for Real-time, then consider the following to lint these. 

```yaml
name: sqlfluff multi-adapter lint
on: [pull_request]
jobs:
  test-pr-review-lint-snowflake:
    name: runner / sqlfluff-snowflake-lint (github-pr-review)
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write 
    env:
      ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
      USERNAME: ${{ secrets.SNOWFLAKE_USER }}
      PASSWORD: ${{ secrets.SNOWFLAKE_PASSWORD }}
      DATABASE: ${{ secrets.SNOWFLAKE_DATABASE }}
      SCHEMA: ${{ secrets.SNOWFLAKE_SCHEMA }}
      WAREHOUSE: ${{ secrets.SNOWFLAKE_WAREHOUSE }}
    steps:
      - uses: actions/checkout@v4
      - uses: tetracionist/action-reviewdog-sqlfluff@v0.1.2
        with:
          github_token: ${{ secrets.github_token }}
          dbt_project_dir: ./testdata/dbt
          level: error 
          reporter: github-pr-review
          sqlfluff_mode: lint

  test-pr-review-lint-materialize:
    name: runner / sqlfluff-materialize-lint (github-pr-review)
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write 
    env:
      HOSTNAME: ${{ secrets.MATERIALIZE_HOSTNAME }}"
      USERNAME: ${{ secrets.MATERIALIZE_USER }}
      PASSWORD: ${{ secrets.MATERIALIZE_PASSWORD }}
      DATABASE: ${{ secrets.MATERIALIZE_DATABASE }}
      SCHEMA: ${{ secrets.MATERIALIZE_SCHEMA }}
      CLUSTER: ${{ secrets.MATERIALIZE_CLUSTER }}"
    steps:
      - uses: actions/checkout@v4
      - uses: tetracionist/action-reviewdog-sqlfluff@v0.1.2
        with:
          github_token: ${{ secrets.github_token }}
          dbt_adapter: materialize
          dbt_project_dir: ./testdata/dbt
          level: error 
          reporter: github-pr-review
          sqlfluff_mode: lint

name: sqlfluff multi-adapter fix
on: [pull_request]
jobs:
  test-pr-review-fix-snowflake:
    name: runner / sqlfluff-snowflake-fix (github-pr-review)
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write 
    env:
      ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
      USERNAME: ${{ secrets.SNOWFLAKE_USER }}
      PASSWORD: ${{ secrets.SNOWFLAKE_PASSWORD }}
      DATABASE: ${{ secrets.SNOWFLAKE_DATABASE }}
      SCHEMA: ${{ secrets.SNOWFLAKE_SCHEMA }}
      WAREHOUSE: ${{ secrets.SNOWFLAKE_WAREHOUSE }}
    steps:
      - uses: actions/checkout@v4
      - uses: tetracionist/action-reviewdog-sqlfluff@v0.1.2
        with:
          github_token: ${{ secrets.github_token }}
          dbt_project_dir: ./testdata/dbt
          level: error 
          reporter: github-pr-review
          sqlfluff_mode: fix

  test-pr-review-fix-materialize:
    name: runner / sqlfluff-materialize-fix (github-pr-review)
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write 
    env:
      HOSTNAME: ${{ secrets.MATERIALIZE_HOSTNAME }}"
      USERNAME: ${{ secrets.MATERIALIZE_USER }}
      PASSWORD: ${{ secrets.MATERIALIZE_PASSWORD }}
      DATABASE: ${{ secrets.MATERIALIZE_DATABASE }}
      SCHEMA: ${{ secrets.MATERIALIZE_SCHEMA }}
      CLUSTER: ${{ secrets.MATERIALIZE_CLUSTER }}"
    steps:
      - uses: actions/checkout@v4
      - uses: tetracionist/action-reviewdog-sqlfluff@v0.1.2
        with:
          github_token: ${{ secrets.github_token }}
          dbt_adapter: materialize
          dbt_project_dir: ./testdata/dbt
          level: error 
          reporter: github-pr-review
          sqlfluff_mode: fix
```


## Development

### Release

#### [haya14busa/action-bumpr](https://github.com/haya14busa/action-bumpr)
You can bump version on merging Pull Requests with specific labels (bump:major,bump:minor,bump:patch).
Pushing tag manually by yourself also work.

#### [haya14busa/action-update-semver](https://github.com/haya14busa/action-update-semver)

This action updates major/minor release tags on a tag push. e.g. Update v1 and v1.2 tag when released v1.2.3.
ref: https://help.github.com/en/articles/about-actions#versioning-your-action

### Lint - reviewdog integration

This reviewdog action template itself is integrated with reviewdog to run lints
which is useful for Docker container based actions.

![reviewdog integration](https://user-images.githubusercontent.com/3797062/72735107-7fbb9600-3bde-11ea-8087-12af76e7ee6f.png)

Supported linters:

- [reviewdog/action-shellcheck](https://github.com/reviewdog/action-shellcheck)
- [reviewdog/action-hadolint](https://github.com/reviewdog/action-hadolint)
- [reviewdog/action-misspell](https://github.com/reviewdog/action-misspell)

### Dependencies Update Automation
This repository uses [reviewdog/action-depup](https://github.com/reviewdog/action-depup) to update
reviewdog version.

[![reviewdog depup demo](https://user-images.githubusercontent.com/3797062/73154254-170e7500-411a-11ea-8211-912e9de7c936.png)](https://github.com/reviewdog/action-template/pull/6)
