# RFC 117: Use a container runtime

## Summary

Use a container runtime for hosting GOV.UK applications. This will provide a number of benefits, including:
* Removing our dependency on a version of Ubuntu (Trusty) which is in extended support (which ends in April 2022)
* Removing legacy infrastructure code which is difficult to maintain and extend
* Providing better value for money by using cloud resources more effectively
* Improving development velocity by reducing the difference between production and development environments
* Making it easier to adopt higher velocity deployment approaches (such as continuous deployment)

## Problem

GOV.UK currently hosts the majority of its applications and services using virtual machines running Ubuntu 14.04 LTS (Trusty Tahr).

Trusty is out of date, it was released in April 2014 and standard support ended in April 2019. At this time GOV.UK signed up for [Extended Security Maintenance](https://ubuntu.com/esm) (ESM) which provides continued security fixes for high and critical common vulnerabilities and exposures (CVEs) for the [most commonly used packages](https://wiki.ubuntu.com/SecurityTeam/ESM/14.04#A14.04_Infrastructure_ESM_Packages). ESM will end in April 2022.

Running an old operating system is preventing GOV.UK from upgrading key components of our technology stack (MongoDB, Puppet, Python, ...).

Upgrading Ubuntu in the existing infrastructure is difficult for a number of reasons, including but not limited to:

- Multiple applications share the operating system of the same virtual machine. This means it’s not easy to upgrade a single application at a time. Furthermore, the way our [Puppet code](http://github.com/alphagov/govuk-puppet/) is written makes supporting virtual machines on different operating systems at the same time hard to support.
- Ubuntu Trusty uses upstart as its init system, but newer versions switch to systemd - this could make some aspects of an upgrade more tricky.
- Our current version of Puppet is 3.8, which is no longer supported (the current version is 6.13). Support for newer operating system versions is likely to be lacking in unsupported versions of Puppet.
- Other infrastructure as code tools in use (e.g. [Fabric](https://github.com/alphagov/fabric-scripts)) are also currently using very old versions which are very likely to have problems with newer operating systems.

## Proposal

GOV.UK will use a managed, container based hosting environment, such as [GOV.UK PaaS](https://www.cloud.service.gov.uk). The choice of hosting environment is out of scope for this RFC.

GOV.UK applications and their dependencies will be built into container images. This may be done using buildpacks or other means - this decision is also out of scope for this RFC.

Non-application concerns (such as deployments, cross application scheduled tasks, monitoring, metrics, traffic replay etc.) currently handled by the Trusty virtual machines will be moved to managed platforms wherever possible. If it is not possible to use a mangaed platform in some cases, GOV.UK will provision hosting for these cases using up-to-date operating systems and tools.

### Benefits of this approach

The most immediate benefit of this approach is that it will allow us to offload upgrades of the host operating system to whomever manages the container runtime, and only have to manage updates to the applications' dependencies within the containers. By using containers to manage application dependencies more tightly, GOV.UK can enable a much lower risk upgrade path. Future upgrades should be easier to prioritise, because they will be smaller, lower risk pieces of work.

Moving to a container based hosting environment will allow us to remove much of our legacy Puppet and Fabric code. This code is hard to maintain, and hard to hire people with the experience required to improve and upgrade. With industry and government overwhelmingly moving towards container based platforms, it should be much easier to hire people with these skills.

Containerised hosting environments can generally provide much better value for money in terms of resource usage, both because many small applications can be “bin-packed” onto the same infrastructure, and because it is much easier to autoscale applications.

Running containers in production allows for a reduction in the difference between development environments and production. For example, it can allow developers to test some configuration changes locally, without having to deploy to an environment. This can lead to bugs being found more quickly, and faster development cycles.

Other improvements to GOV.UK’s development lifecycle (such as moving to continuous deployment) will be easier to implement on a container based infrastructure than they would in the current virtual machine based infrastructure.

A container runtime aligns with the [GOV.UK Infrastructure Architecture Goals for 2021](
https://docs.google.com/document/d/1ooN7wkYhEGvceGe9Qz_HNZa-GPtrjzK_vA4vfWYVn4c/edit#heading=h.cdrr7rv9t98f) to isolate applications through containers. This will give us better control of how resources are matched to applications.

The TechOps strategy is to use common components where available. GOV.UK has been following the strategy by using hosted versions of software ([ElasticSearch](https://aws.amazon.com/elasticsearch-service/) and [Postgres](https://aws.amazon.com/rds/)) and services ([Notify](https://www.notifications.service.gov.uk)) where available. Using a container runtime is a continuation of this policy.

GOV.UK has already containerised its development environment ([rfc-106](https://www.github.com/alphagov/govuk-rfcs/106)) and uses production-like containers in the [publishing-e2e-tests](https://github.com/alphagov/publishing-e2e-tests). A container runtime will narrow the gap between development, test and production.

### Risks of this approach

GOV.UK has not yet estimated the length of time this work will take, our current assumption is that it will take much less than 2 years to complete. There is a risk that the “unknown unknowns” GOV.UK discovers will prevent GOV.UK from finishing the containerisation work before support ends for Trusty. If this happens, GOV.UK may need to refocus our efforts to upgrade from Trusty in the existing infrastructure.

GOV.UK infrastructure has been in a transitory state for several years and containerisation will prolong this state. In addition in the short term GOV.UK will be adding complexity making supporting the platform hard for RE-GOV.UK and 2nd line.

The current migration (lift-and-shift to AWS) has been a complex and challenging piece of work. This has led to several engineers reporting feelings of burnout and exhaustion. If we fail to learn the lessons that GDS' past migration experiences have to offer there is a risk that doing this work could have significant negative consequences for the team, and for individuals' well-being. We should carefully consider how we structure teams, and how we can ensure that the teams have the time to do the work properly, get the training they need to learn new technologies, and have the agency they need to feel that they fully own their platform.

Focusing on containerisation will mean fewer people will be available to work on improving other parts of the platform.

GOV.UK has a significant amount of infrastructure outside of the applications themselves. In moving to a container based hosting platform, it’s possible that some existing behaviour may be missed, resulting in bugs.

GOV.UK will still need to continuously upgrade some infrastructure dependencies. There is a risk that this work will not be prioritised, leaving GOV.UK with a different set of out-of-date infrastructure in the future. Moving to managed platforms wherever possible helps mitigate this, but there will always be some maintenance work that needs to be prioritised.

### Risks of not doing this

Choosing not to move to a container runtime will mean that GOV.UK will have to upgrade from Ubuntu Trusty "in place" (i.e. by making significant changes to govuk-puppet). This will require significant effort for limited benefit, and is potentially wasted work as once the upgrade is done GOV.UK will still want to consider if running VMs is the right approach.

GOV.UK will also have to tackle a number of difficult tooling upgrades (Puppet, in particular) if GOV.UK wants to return to a situation where GOV.UK does not use unsupported dependencies.

GOV.UK will be harder for the rest of GDS to support, because its infrastructure will be significantly different. Almost all other service teams in GDS are using a container based hosting environment of some kind (mostly [CloudFoundry](https://www.cloudfoundry.org) or AWS ECS).

This work may cause a high degree of disruption for developers (e.g. it may include new processes for deployments, CI, interacting with apps, etc). This could reduce the pace of delivery, or cause confusion which could potentially lead to user-affecting mistakes.

Having applications manage their own dependencies may lead to a wider range of versions of software in use. This may increase the work involved in keeping software up-to-date and auditing which software versions are in use.

### Follow up work

GOV.UK will commit to doing these things:

- Investigate the practicalities involved in using different managed, container based hosting environments for GOV.UK (including how difficult will it be to run a hybrid containerised / non-containerised environment)
- Understand how containerising will affect GOV.UK's build and deployment process, metrics & alerting, and support models.
