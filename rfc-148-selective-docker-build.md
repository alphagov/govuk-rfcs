# Build Docker images selectively rather than on every push to any branch.

## Summary

For app repos with Dockerfiles, we currently build and push a Docker image on
every push to any branch, even though the resulting images are seldom used.
This RFC proposes to speed up the push/test turnaround time and save carbon by
building images only on push to `main` and on push to other branches where
`Dockerfile`s are modified.

## Problem

* The `continuous-integration/jenkins/branch` CI job, which runs on every push
  to any branch, is currently quite slow.  The `docker build` and `docker
  push` steps add approximately two minutes to the job. This is a source of
  frustration when raising PRs, particularly on occasions when other tests fail
  and subsequent pushes are required to resolve the issue.
* The images built from non-default branches are seldom used, yet these are the
  majority of the images being built. The images for the upcoming Kubernetes
  deployments are built separately in GitHub Actions. The images for
  development use are built separately in [govuk-docker].
* We still want to pick up any obvious breakage of the image build pre-merge
  where we can, but not regardless of cost to developers' time or CO₂e.

[govuk-docker]: https://github.com/alphagov/govuk-docker/

## Proposal

Build Docker images only when:

* Pushing to the default branch, i.e. `main`.
*

Describe your proposal, with a focus on clarity of meaning. You MAY use [RFC2119-style](https://www.ietf.org/rfc/rfc2119.txt) MUST, SHOULD and MAY language to help clarify your intentions.
