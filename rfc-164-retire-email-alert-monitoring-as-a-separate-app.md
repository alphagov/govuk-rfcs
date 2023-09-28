# Retire email-alert-monitoring as a separate app

## Summary

Replace the current email-alert-monitoring system with a task built into email-alert-api using the Notify API rather than the current Gmail/App based system, giving us a more stable and testable system and allowing us to retire a repo.

## Problem

Email-alert-monitoring is a stand-alone app run as a cronjob (currently on Jenkins, although it's being moved over to EKS). It's designed to confirm that medical and travel alert emails have been sent out on time, and supports an SLA. It's clearly critical that we have some way of knowing that these alerts have gone out, but the current system has a number of problems:

- It relies on a slightly heath-robinson collection of google accounts
- Its method of matching alerts to emails is brittle
- False alarms well outnumber valid alarms (which causes annoying on-call pages)
- It's not entirely clear how actionable the valid alarms are

## Proposal

We should retire email-alert-monitoring as a separate application, and instead build a system into email-alert-api that can be called by a cron job (once every 15 minutes for travel advice, and 30 minutes for medial alerts).

Currently it looks like we're not tracking the id for emails sent out via notify, but we do store email information for one day. By storing the notify ID, either for all emails (easier) or just for alert emails, we could then [query notify as to their current status]. Our cron job could query the current status for the relevant alert emails, and if _one_ email is in the "delivered" state, we have roughly as much proof that they're being delivered as we currently do.

As a side-effect of adding this, we could also potentially query every alert email in the given period to determine how many of our alerts on average are getting delivered (and perhaps identify recipients who no longer exist).

This isn't quite as end-to-end as the current system (if something was delivered, does that mean it's actually in a given person's inbox?), but since any record that Notify deems delivered is at the absolute boundaries of anything actionable by GOV.UK, there seems to be little to gain by tracking the alerts further than that.

[query notify as to their current status]: https://docs.notifications.service.gov.uk/ruby.html#get-the-status-of-one-message
