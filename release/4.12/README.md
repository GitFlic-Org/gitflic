**4.12.1 What's new:**

## Added:

+ CI/CD variable with project UUID
+ CI/CD variable with local ID of task and event (MR)

## Fixed:
+ Display of registry repository management buttons on the instance for all users
+ Links to view file history via blame
+ Null Pointer error when importing an archive from GitLab
+ Getting refs for projects in groups
+ Creation of proxying registry repositories in a company and projects

---

**4.12.0 What's new:**

## Added:

+ Routing rules for the proxying repository registry and package registry (Enterprise / Atlas)
+ Support for OpenSearch versions 2 and 3 (Enterprise)
+ Predefined variable CI_MERGE_REQUEST_LOCAL_ID

## Fixed:

+ Code highlighting when viewing a SAST report in the security tab
+ Searching for approvers when creating an MR rule in a project
+ Validation of the regular expression for the project when creating a Jira integration. Now numbers can be used.
