---
status: accepted
implementation: done
status_last_reviewed: 2024-03-06
---

# Customise call-to-action text on simple Smart Answer start pages

## Problem

According to a colleague people get confused by 'Start now' on some Simple Smart Answers' start pages when it's not related to the thing they're doing, eg paying or contacting a department/agency.

For example, there are roughly 30 contacts per day for 1st line about the contact [dvla](https://www.gov.uk/contact-the-dvla)&nbsp;/&nbsp;[dvsa](https://www.gov.uk/contact-dvsa) Simple Smart Answers. See [feedex entries for /contact-dvsa](https://support.production.alphagov.co.uk/anonymous_feedback?path=%2Fcontact-dvsa) and [/contact-the-dvla](https://support.production.alphagov.co.uk/anonymous_feedback?path=%2Fcontact-the-dvla).

## Proposal

Allow customising the text value on the call to action button in the publisher application. Currently its value is [hard-coded to 'Start now'](https://github.com/alphagov/frontend/blob/d9e2852faf4d47a26c9e9c2192f3747f90a7ed3c/app/views/root/simple_smart_answer.html.erb#L9).&nbsp;

&nbsp;

Introducing this change would affect at least three repos:

&nbsp;

**1) govuk\_content\_models**

Simple Smart Answers would need an additional attribute to store the text value of the action button.&nbsp;Content designers suggest a free-text field limited to ~15 characters.

All existing Simple Smart Answers would need a data migration to set this value to 'Start now'.

&nbsp;

**2) publisher**

Publisher would need to show the new attribute in the UI. I've mocked up what it could look like (Action button):

&nbsp;

**3) frontend**

Frontend would need to show the variable attribute value on the call to action button.

Since the change would touch applications looked after by different teams, I would like to make sure it does not clash with the vision of the future of those applications.

I would also like to receive comments about whether this is the right solution to the problem and I am not violating any user experience guidelines.

&nbsp;

&nbsp;

