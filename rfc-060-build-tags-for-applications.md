## Problem

At the moment we identify versions of applications that we want to deploy using incrementing integers. This doesn't scale well and doesn't support moving to a new CI system.

We also have many different number prefixes, like build and release. EFG has zzz for some reason.

## Proposal

I think we should use datetimes to separate deployments. The advantage with these is that they are human readable. Instead of:

[https://github.com/alphagov/govuk-puppet/compare/build\_17859...build\_17861](https://github.com/alphagov/govuk-puppet/compare/build_17859...build_17861) (I'm deploying 2 builds)

You can say:

[https://github.com/alphagov/govuk-puppet/compare/build\_2016-10-10T2359...build\_2016-10-11T1145](https://github.com/alphagov/govuk-puppet/compare/build_17859...build_17861) (I'm deploying half a day's worth of changes)

The timestamp of a build is assigned at the start of a build. This matches the current behaviour we have where the build number is assigned at the start of a build.

The build tag can optionally include a build number after the timestamp, eg build\_2016-10-11T1145\_123

The build tag can optionally include a 7 character SHA after the timestamp, eg build\_2016-10-11T1145\_141ab21 (7 is the git default for short SHAs)

