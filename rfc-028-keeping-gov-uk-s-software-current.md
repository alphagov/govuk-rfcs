---
status: superseded
implementation: superseded
status_last_reviewed: 2024-03-06
status_notes: 'GOV.UK has a policy on keeping software current: https://docs.publishing.service.gov.uk/manual/keeping-software-current.html'
---

# Keeping GOV.UK's software current

One of our core values is to use secure and up to date software. This document lays out the recommendations for keeping our Ruby on Rails software current.

## Introduction

We run a lot of Rails applications. This means that we have dependencies on both Rails and Ruby versions.

## Upgrading Rails

It's very important that we're running a currently supported version of Rails for all applications, otherwise we **aren't covered** &nbsp;by [security fixes](http://rubyonrails.org/security/). We should:

- Be running on the current major version - this currently means `4.y.z`
- Maintain our applications at the latest current bugfix release for the minor version we're on (expressed in Gemfile syntax as: `~> X.Y.Z`) - this currently means `4.1.8` and `4.2.3`
- Keep abreast of breaking changes for the next major version (`5.y.z`), and have a plan to migrate our apps before `4.2.x` is deprecated

## Upgrading Ruby

New versions of Ruby bring us improved performance and nicer syntax for certain things, but also can cause issues with the libraries etc. we use. We should:

- Be running on the current major version - this currently means `2.y.z`
- Maintain our applications at the current or next-to-current minor version - this means `2.2.z` or `2.1.z`, depending on your app's dependencies

## Current state

The current state of the Ruby and Rails versions is:

- [Listed in this versions spreadsheet](https://docs.google.com/spreadsheets/d/1FJmr39c9eXgpA-qHUU6GAbbJrnenc0P7JcyY2NB9PgU/edit#gid=1480786499) by&nbsp;alext
- [Another spreadsheet with team ownership](https://docs.google.com/a/digital.cabinet-office.gov.uk/spreadsheets/d/17SaFqFqVEMoabq-FjEeCHpUmA5yAjqLr_Vt-lDeXMsE/edit?usp=sharing) by&nbsp;alexandria.jackson.

