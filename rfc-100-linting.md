# RFC 💯: Update linting system

## Summary

Update the way we do linting by using Rubocop directly and using NPM-packages to lint CSS and JS.

## Background

At present, we use a gem called [govuk-lint][] for linting in our projects.

- It's a wrapper around [rubocop], a community driven styleguide for Ruby, so that we can have [central configuration files][rules] that specify our linting rules
- It also adds the [--diff --cached commands][commands] to rubocop, which allow us to lint only the changed files
- It provides a wrapper for [scss_lint][] to provide [shared rules][css-rules] for CSS. These tools are used by the Design System team, are well maintained and have an autocorrect feature.

We [wrote about introducing linting](https://gdstechnology.blog.gov.uk/2016/09/30/easing-the-process-of-pull-request-reviews/) in 2016.

[govuk-lint]: https://github.com/alphagov/govuk-lint
[rubocop]: https://github.com/rubocop-hq/rubocop
[scss_lint]: https://github.com/brigade/scss-lint
[rules]: https://github.com/alphagov/govuk-lint/tree/master/configs/rubocop
[commands]: https://github.com/alphagov/govuk-lint#ruby
[css-rules]: https://github.com/alphagov/govuk-lint/blob/9c501a15824a156718d58e7e1a107a7d78171c5f/configs/scss_lint/gds-sass-styleguide.yml

## Issues

1. Rubocop now has a native way of sharing rules: you include rules by specifing `inherit_gem` in `.rubocop.yml`. This has been successfully [trialed in content-performance-manager](https://github.com/alphagov/content-performance-manager/pull/1082). As mentioned in that PR, this makes the linting faster and makes it compatible with developer environments (see [this issue from 2016](https://github.com/alphagov/govuk-lint/issues/61) for evidence of a need).
1. A lot of hard work has gone into fixing older Ruby linting violations ([for example in finder-frontend](https://github.com/alphagov/finder-frontend/pull/579)). This has allowed us to [turn off the "diffing" behaviour](https://github.com/alphagov/finder-frontend/pull/581) for most projects - we now lint all of the code all of the time.
1. We currently do not lint our Javascript. This is a gap first raised [in 2016](https://github.com/alphagov/govuk-lint/issues/51) and further discussed in an [issue talking about Standard.js](https://github.com/alphagov/govuk-lint/issues/63).
1. The [scss_lint tool is being deprecated](https://github.com/alphagov/govuk-lint/issues/70). The authors suggest using a different library.
1. The CSS linting hasn't been fully adopted in GOV.UK projects - only a few frontend applications have it enabled. Others [explicitly disable it](https://github.com/search?q=org%3Aalphagov+sassLint%3A+false&type=Code). The main reason for this is that `scss_lint` does not have an autocorrect feature, so it's a significant (and boring) investment to adopt the linting for older projects.
1. While govuk-lint has been adopted by [a lot of Ruby projects in GDS and wider government](https://github.com/alphagov/govuk-lint/network/dependents), the CSS linting feature isn't always used. Projects that don't use CSS still need to pull in the `scss_lint` dependency.
1. Last year, [GOV.UK Frontend](https://github.com/alphagov/govuk-frontend) (part of the [Design System](https://design-system.service.gov.uk/)) was officially launched. Since this is the defacto standard for building frontend things in government, GOV.UK should be adopting the same tools it uses. This will allow us to easily push things upstream and re-use GOV.UK Frontend patterns.
1. There's been a shift in the Ruby community regarding the use of Javascript packages. Where previously it was preferred to use tools written in Ruby like `scss_lint`, Rails now [ships with Yarn](https://guides.rubyonrails.org/5_1_release_notes.html#yarn-support) and supports [Webpack](https://guides.rubyonrails.org/5_1_release_notes.html#optional-webpack-support).

## Proposal

1. Retire the `govuk-lint` gem
2. Create a new gem called `govuk_rubocop` that includes all rules configuration and a dependency on the `rubocop` gem
3. Adopt NPM modules [standard](https://www.npmjs.com/package/standard) for Javascript linting and [sass-lint](https://www.npmjs.com/package/sass-lint) for CSS linting

## Consequences

### Impact

- All applications that provide a frontend will have a development / CI dependency on Yarn.

### Implementation

1. Create new `govuk_rubocop` gem
2. Update all GOV.UK repos to switch out `govuk-lint` for `govuk_rubocop`,  add `inherit_gem` to `.rubocop.yml`, and add a `package.json` with standard and sass-lint and tasks defined. We would probably be able to automate this.
3. Update [govuk-jenkinslib](https://github.com/alphagov/govuk-jenkinslib) to automatically `yarn install` and run the linting tasks
4. Update documentation
5. Enable Dependabot for NPM modules in repos
