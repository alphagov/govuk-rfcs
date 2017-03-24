## Problem

I would like to propose moving away from manual deployments into a continuous deployment pipeline. I understand this is ambitious, but I would like to at least start the process. Here is some context for this RFC.

### **Background**

As you probably all now, in GOV.UK we roughly&nbsp;follow this process:

- A developer submits a pull request on GitHub with some code changes to a repository, linking to a Trello card which explains the feature;
- CI then runs the tests amongst other things and either fails or accepts the build;
- Someone manually reviews the code changes and approves those changes if everything is looking good;
- The developer (or the reviewer) then merge the pull request;
- CI builds a new release and makes it available&nbsp;to deploy.

At this stage everyone should be pretty happy that this change can go live. In the vast majority of cases, someone eventually deploys this change and we don’t really have to do anything else.

This all sounds good, but was happens in between a feature being merged and it being live?

What normally happens is:

- The developer opens up the release calendar and tries to find a 30 min/ 1 hour slot to deploy the app. That usually can only be done the next day or 2 days form&nbsp;now (or they ask someone if they have free time at the end of a deploy so they can do it);
- In the meantime, potentially&nbsp;a bunch of other pull requests have been reviewed/merged on top;
- When the time to release comes, the developer goes over to the release app and realises there are commits form a number of developers;
- We open up slack and check with all those developers if it’s ok to put those changes live;
- We also need to remember again everything that we need to check, since we might have lost the context for it a few days later (extra effort);
- When everybody is happy we push the code to staging, hopefully check icinga and errbit, do a bit of manual integration testing to see if everything is fine;
- We then finally deploy the code to production, again checking icinga, errbit and that the feature is live.

In most cases, everything is fine.&nbsp;

### **The problem**

As you can see from the steps above, I think there are a number of issues with this approach:

- We roughly waste the time of 1 developer per day deploying code (the deploy slots are usually fully booked between 9.30 and 5.30);
- We waste other people’s time by interrupting their work day asking if their feature can go live;
- We have to regain context of what we are deploying and testing, since the deployment doesn't happen straight away;
- We increase the risk of each deploy because we are pushing a large number of commits in one go (if something goes wrong, which feature broke it?);
- We rely on people to check that everything is ok (checking errbit/icinga/smokey);
- We rely on people with production access to deploy code. In a team where very few developers have production access, we either need to ask 2nd line or the tech lead to deploy code for us, which means we are wasting the time of 2 developers and not just one.

I think there is very little that can’t be automated from the steps above, though, which leads me into the actual&nbsp;proposal.&nbsp;

## Proposal

I think we should try to move towards automated deployments. Some of the reasons for this are:

- Release small changes more frequently, which reduces risk;
- Stop spending time and energy&nbsp;deploying code;
- Think more&nbsp;about&nbsp;backward compatibility and how to build features that won’t break;
- Think more about testing and integration testing.

The ideal scenario, in my mind and in a very simplistic way, is:

1. Open a new&nbsp;PR;
2. CI runs tests, linters, etc;
3. On green, PR gets deployed to temporary app, link attached to PR;
4. Reviewer checks the PR and the temporary app;
5. On a successful review,&nbsp;PR gets merged into master;
6. CI builds a new&nbsp;release and&nbsp;deploys release to integration;
7. CI runs smokey and perhaps app-specific integration tests;
8. If everything is ok in integration, CI deploys to staging, runs smokey and perhaps app-specific integration tests;
9. When all is ok in staging (including no abnormal system-level errors and errbit spikes), CI deploys to production;
10. A slack channel is notified with all the above steps so we can keep an eye on it if needed.

If anything breaks along the way, we need the responsible&nbsp;team to get notified straight away (slack?)&nbsp;and come up with a process in order to know how to unblock the CD pipeline.

I understand we can’t \*just\* do that for a number of reasons. For example:

- we need our infrastructure to support it;
- we need to map out how to deal with abnormal scenarios;
- we might need to adjust development processes so we don’t write interdependent code that can’t be deployed independently;
- and I think we need to fix some other bits and pieces first before we do it.

Which is why&nbsp;I would like to propose starting this process in the following areas.

#### **Allow multiple deployments to happen at once (manually)**

Right now there are apps that can be&nbsp;deployed&nbsp;concurrently. Pretty much any publishing app can be deployed at the same time of a frontend app. CDN changes can also be deployed independently too, amongst other things.

I suggest we:

- make a list of applications that cannot be deployed together with something else and take that into account when booking a release slot;
- make a list of applications we don’t trust to automatically deploy and the reasons for that, so we can prioritise fixing those issues;
- retire the badger or get a few twins to help out;
- allow for multiple applications to be deployed at the same time.

#### **Change our error notification framework**

I think we have a bit of an issue in this area. Very few developers are Watchers in errbit, which means we don’t necessarily have visibility over what errors we have in production until a user either complains on Zendesk; our tech leads find get notified; we see spikes in 2nd line.

I think errbit is quite basic and we could do with a better error tracker. Furthermore, I think we need to have visibility about errors not just on email but perhaps on other channels, so they are treated as a priority and are visible by product teams.

I suggest we:

- replace errbit with a better system (sentry, app signal, etc);
- make sure every app has watchers for the team responsible for it;
- expose errors in other channels (slack?) and make&nbsp;sure errors are prioritised within the product teams.

#### **Map out what changes would be needed in our infrastructure to allow for CD**

I’m sure our infrastructure would need to be changed in order to support this. I suggest we:

- come up with a list of&nbsp;what is missing from an infrastructure perspective and see if we can prioritise some of that work. This includes&nbsp;how we could have sandbox apps per pull request up to how we can stop continuous deployments when system level alerts pop up due to a deployment (I’m sure I’m forgetting a lot more things here, please feel free to comment on it).

#### **Map out what would need to happen when something goes wrong in the CD pipeline**

In parallel with the above, I suggest we:

- get a small team together to spend some time designing how the CD pipeline would work. I described one possible scenario above, but it would be good to have a discussion on this and also understand what things could go wrong and how we expect the system to behave when it does. This team could then start prioritising the work needed to be done before we can enable CD in GOV.UK;
- think about how we could temporary block the CD pipeline for a given app, in case dependencies are unavoidable for a reason;
- think how we could do this progressively - maybe start adding a couple of low-impact apps to the new CD pipeline and slowly roll it out to every app.

Open questions so far:

- Are there any legal impacts to consider?

Apologies for the very long RFC. I understand this is a big effort, but I think we should start talking about it.

If people are happy with this or bits of it, I’m happy to help out as much as I can, but would also need support from other teams as a lot of this has big implications across GOV.UK and also because I don’t necessarily know how to implement it all.

Thoughts?

