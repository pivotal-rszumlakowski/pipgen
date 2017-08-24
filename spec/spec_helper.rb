require 'yaml'

EMPTY_JOB = {}

JOB_WITH_ONLY_NAME = YAML.load "name: awesome_job"

JOB_WITH_EMPTY_PLAN = YAML.load "name: empty_plan_job\nplan:"

JOB_WITH_GETS_AND_NO_PASSED = YAML.load("
---
name: simple_job
plan:
- get: get1
- get: get2
- get: get3")

JOB_WITH_AGGREGATE_GETS_AND_NO_PASSED = YAML.load("
---
name: aggregate_simple_job
plan:
- aggregate:
  - get: get4
  - get: get5
  - get: get6")

JOB_WITH_THREE_AGGREGATE_BLOCKS = YAML.load("
---
name: aggregated_big_job
plan:
- aggregate:
  - get: get1
  - get: get2
  - get: get3
- aggregate:
  - get: get4
  - get: get5
  - get: get6
- aggregate:
  - get: get7
  - get: get8
  - get: get9")

JOB_WITH_MANY_GETS = YAML.load("
---
name: very_big_job
plan:
- aggregate:
  - get: get1
  - get: get2
  - get: get3
- get: get13
- get: get14
- get: get15
- aggregate:
  - get: get4
  - get: get5
  - get: get6
- aggregate:
  - get: get7
  - get: get8
  - get: get9
- get: get10
- get: get11
- get: get12")

JOB_WITH_ONE_PASSED_GET = YAML.load("
---
name: easy_job
plan:
- get: the_only_get
  passed: [job_dependency1, job_dependency2, job_dependency3]")

JOB_WITH_TWO_PASSED_GETS_AND_UNIQUE_DEPENDENCIES = YAML.load("
---
name: also_easy_job
plan:
- get: the_first_get
  passed: [job_dependency1, job_dependency2, job_dependency3]
- get: the_second_get
  passed: [job_dependency4, job_dependency5, job_dependency6]")

JOB_WITH_TWO_PASSED_GETS_AND_SHARED_DEPENDENCIES = YAML.load("
---
name: slightly_more_complex_job
plan:
- get: the_first_get
  passed: [job_dependency1, job_dependency2, job_dependency3]
- aggregate:
  - get: the_second_get
    passed: [job_dependency1, job_dependency2, job_dependency4]")
