## Problem

There has been recent confusion about the processes under which we merge Pull Requests (PRs). We have one application (Whitehall) that uses a different set of rules to other applications, and this is confusing for new starters. The only documentation about our PR review process is Whitehall specific and is two years old.

## Proposed Standard

There are just two rules of merging PRs:

1. 

`master` must be able to be released at any time

2. The change must have two reviews from people from GDS (preferably GOV.UK). This can (and normally will) include the author.

These rules apply to all applications, including Whitehall. As long as these rules are followed, PRs can be reviewed and merged in a way best suited to the situation.

### Example scenarios

#### A simple change

A small PR against a well-understood application, written by someone with good knowledge of the problem domain and with a well defined scope. When a PR is raised, someone with similar understanding of the application and change can just merge the PR. Both people are reasonably confident that master will be deployable once this PR is merged.

#### A simple change for a repository that has a long running test suite

Similar to the above. If a PR is against a repository that has a long running test suite and you've approved the change and are confident that the suite will pass, the reviewer can reply with something like "👍 merge when green". This allows the reviewer to carry on with other work rather than waiting for the test suite to pass to merge the PR. The author of the PR now has approval to merge the PR themselves once the test suite has passed.

#### A change where a reviewer doesn't have the full context or knowledge required

Some changes require different levels of context and knowledge. For example, a PR which involves a lot of CSS changes may not be easily reviewable by a backend developer. They may have the product context required to be able to review the before and after screenshots and say "this looks good to me", but not understand the implications of the code changes. In this instance you can reply with something like "👍 looks good to me, but I'd appreciate an additional review from someone with more frontend knowledge". If you can, you should also&nbsp;@mention someone who you think may be better placed to review it. This is essentially registering your review as a half review. Someone else with the other half of the knowledge (or full knowledge) can then merge the PR once they've reviewed it.

#### A change that has timing or dependency implications

If a change is ready to be reviewed but must wait to be merged for some other event, the title should be prefixed with&nbsp;`[Do not merge]`. A description of what the PR is waiting for should be included in the main description of the PR. When a change like this is reviewed, you can simply comment with a "👍" to approve the change. It's then up to the author to merge that PR when the correct conditions are met.

#### A change from an external contributor

We occasionally receive PRs from external contributors who use our code. These will come from forks of the main repo. In the majority of cases, our test suite will not run automatically against these PRs. First, review the code carefully for anything that might be malicious and damaging if run inside our infrastructure. Once you're satisfied, follow Github's instructions to pull the forked branch locally, then push it to origin. This will cause the test suite to run with the original commits, which will cause Github to (hopefully, eventually) green light the original PR. Two people from GDS should review this PR. The first reviewer should comment with a "👍", and the second reviewer should merge. You should also thank the contributor with an amount of emoji proportional to the time they're saving GDS developers.

### Other considerations

1. It's ok for someone other than the author to merge a PR in the "merge when green" or "[Do not merge]" scenarios above, particularly if the author is off work
2. If a PR is particularly good, remember to praise the author for it. Emoji are a great way of showing appreciation for a PR that fixes a problem you've been having, or implements something you've wanted to do for a while.
3. It's sometimes ok for merges to happen when test suites are failing. This ability is limited to repo administrators and account owners, so ask them if you need them to force a merge. This is particularly useful in a catch-22 situation of two repos with failing test suites that depend on each other.

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

