# Retire email-alert-monitoring as a separate app

## Summary

Replace the current email-alert-monitoring system with a task built into email-alert-api using the Notify API rather than the current Gmail/App based system, giving us a more stable and testable system and allowing us to retire a repo.

## Problem

email-alert-monitoring is a stand-alone app run as a cronjob (currently on Jenkins, although it's being moved over to EKS). It's designed to confirm that medical and travel alert emails have been sent out on time, and supports an SLA. It's clearly critical that we have some way of knowing that these alerts have gone out, but the current system has a number of problems:

- It relies on a gmail account and a related google cloud console project that are hard to set up
- Its method of matching alerts to emails is brittle
- False alarms well outnumber valid alarms (which causes annoying on-call pages)
- It's not entirely clear how actionable the valid alarms are

## Proposal

We should retire email-alert-monitoring as a separate application, and instead build a system into email-alert-api that can be called by a cron job (as is currently the case for the separate app).

Currently it looks like we're not tracking the id for emails sent out via Notify, but we do store email information for one day. By storing the Notify ID, either for all emails (easier) or just for alert emails, we could then [query Notify as to their current status]. Our cron job could query the current status for the relevant alert emails, and if _one_ email is in the "delivered" state, we have roughly as much proof that they're being delivered as we currently do.

As a side-effect of adding this, we could also potentially query every alert email in the given period to determine how many of our alerts on average are getting delivered (and perhaps identify recipients who no longer exist).

This isn't quite as end-to-end as the current system (if something was delivered, does that mean it's actually in a given person's inbox?), but since any record that Notify deems delivered is at the absolute boundaries of anything actionable by GOV.UK, there seems to be little to gain by tracking the alerts further than that. We can keep the existing subscription to use in cases where we needed to check that emails have been physically seen in the inbox, but those checks can be done manually by second line (and the inboxes in question can be free google group inboxes rather than paid-for gmail accounts, since we won't need the API that gmail accounts have and google groups don't have. This would also simplify access, since we wouldn't need to store and retrieve secrets to access the gmail account when working on second line).

[query notify as to their current status]: https://docs.notifications.service.gov.uk/ruby.html#get-the-status-of-one-message

## Technical Details

### How email-alert-monitoring currently works for Medical Alerts

The app is called as a cronjob once every 30 minutes. It opens the [RSS feed] for medical alert updates, grabs the first 5, then filters out of those five any that were published in the last hour. For the remaining items, if any, it makes a list of the subject lines of the emails that should have gone out. It then uses the GMail API to read the inbox of govuk_email_check@digital.cabinet-office.gov.uk to check for the existence of those emails. If any are missing, an alert happens. Minimum time between publishing and alert is 1 hour.

[RSS feed]: https://www.gov.uk/drug-device-alerts.atom

### How email-alert-monitoring currently works for Travel Advice Alerts

The app is called as a cronjob once every 15 minutes. It opens a [healthcheck URL] on the travel-advice-publisher app, which contains a list of all travel alerts published in the last 2 days, but excluding the last 150 minutes. For these, it makes a list of the subject lines of the emails that should have been sent out, as well as the time (this is because more than one travel advice alert might be issued for the same country in a two day period, so matching purely on the subject line isn't sufficient). It then uses the GMail API to read the inbox of govuk_email_check@digital.cabinet-office.gov.uk to check for the existence of those emails. If any are missing, an alert happens. Minimum time between publishing and alert is 2 and a half hours.

[healthcheck URL]: https://travel-advice-publisher.publishing.service.gov.uk/healthcheck/recently-published-editions

### How the alerts actually happen (Jenkins)

Where we use the phrase "an alert happens" above, the actual mechanism is that the email-alert-monitoring task exits with a fail status (2), and the Jenkins job running the task uses the Failure_Passive_check job to send a passive check to Icinga with a failed status. Icinga handles escalation to PagerDuty.

### Problems with matching subject lines

Problems can occur when trying to match by subject line if the title of the alert is altered after the email has been sent out. The [RSS feed] or [healthcheck URL] will contain a title that differs from the subject line of the email sent out. This will cause a failed match, and an alert will go off, even though for practical purposes the email has been sent. This causes false alarms, and needs someone to add a [hard-coded exception] into the matching code, increasing toil.

[hard-coded execption]: https://github.com/alphagov/email-alert-monitoring/blob/79a865dcd8be07447735ae8ae99b78002241504a/lib/email_verifier.rb#L8-L36

### What Notify API can tell us about the status of an email

Notify API gives us a [current delivery status] for an email, which begins as "sending" and is changed to "delivered" when Notify receives a callback from Amazon SES (the backing service Notify uses to delivery emails) to confirm the mailserver handling emails for the recipient address has accepted the email. This is a reasonably solid assurance that the email has got to the receipient, and is definitely at the point where further handling of the email is outside of our control - the only things that might stop the recipient seeing the email at that point are:
- The mailserver might fail to deliver internally: Valid, but we can't currently test that unless the failure occurs in the exact GMail server handling our account anyway.
- A spam filter might redirect the message: Untestable, relies on idiosyncratic account setup, and out of our control
- The recipient might ignore the message: Untestable, and out of our control.

### How we could replace this with a job internal to email-alert-api

We currently keep a record of every single email sent out via email-alert-api (the Email model). These records are [kept for one week, then deleted]. When emails are sent out, we could save the notify response ID in the Email record. This would allow us to get the [current delivery status] of the email using the Notify API. As long as one email sent in response to an alert has a delivery status of "delivered", we would have roughly the same assurance as we do now that the email alert has been sent successfully. It would also allow us the opportunity (if we wanted) to make a more stringent alert (say, that a certain percentage of the alert emails were delivered successfully) that we can't currently test.

We're rate limited in calls to Notify, so we'd need to make sure these calls were tied into the existing [rate limiting service] used in email-alert-api

We would need some way of matching the emails in the Email model to the emails expected to have been sent out. An MVP would be to use the exact same matching pattern (subject line and optionally time) that we use at the moment. This would get us the same level of reliability as now, but would retain the same problems (that if an alert's title is changed after it is sent out, the match will not work). To combat this, we could retain in Email records the content_id of the item that triggered them, and augment the [RSS feed] and [healthcheck URL] to add the content item into each displayed item. This is already publically available information and has no real security implication, but would require small changes to travel-advice-publisher and finder-frontend.

To trigger an alert, we could either use a Prometheus collector on a reasonable metric, or use the Prometheus push gateway. A collector is probably preferable. The question of raising a PagerDuty alert from a Prometheus metric is already well understood by the platform teams.

### How this would be testable

One of the problems with the current system is that it can only be tested in production, so it's important to consider how the new version could be tested. In integration and staging, emails are only sent to [specific email addresses]. Either we would need to add additional addresses to receive alerts, or sign up the existing ones. This would allow us to test the system working on the happy path (emails would be delivered to them, notify would mark them as delivered, and we could confirm that with the new monitoring code). To test the unhappy path (that alerts actually go off if the email isn't sent), temporarily removing the relevant subscription would cause there to be no detected receipts of any alert generated in that environment. We could possibly create rake tasks to disable/renable the subscriptions to make this easier for developers.

[specific email addresses]: https://docs.publishing.service.gov.uk/repos/email-alert-api/receiving-emails-from-email-alert-api-in-integration-and-staging.html

#### Future Considerations

email-alert-monitoring currently doesn't handle alerting on daily or weekly digests. We can probably safely ignore them for the moment. If we wanted to alert on them too we'd need some additional mechanism to tie the digests to a list of content_ids, and we would need to extend the [RSS Feed] and [healthcheck URL] endpoints in their respective apps to ensure data was available for the past week's worth of updates (currently not guaranteed in the [RSS Feed] and definitely not supplied in the [healthcheck URL])

Currently travel-advice-publisher and specialist-publisher (the publishing tool for medical alerts) talk directly to email-alert-api. The current design philosophy for emails is that publisher apps should not talk directly to the alert API, instead publishing to a queue which email-alert-service consumes, and it then makes the calls. This is captured as technical debt, and we would have to ensure that when we pay down that debt the fix takes into account this mechanism. It's not anticipated that this will particularly complicate the debt, though.

[kept for one week, then deleted]: https://github.com/alphagov/email-alert-api/blob/main/app/workers/email_deletion_worker.rb#L5
[current delivery status]: https://docs.notifications.service.gov.uk/ruby.html#get-the-status-of-one-message
[rate limiting service]: https://github.com/alphagov/email-alert-api/blob/032fe645e62b5d3b26fedba84a3e852a87575a8b/lib/services.rb#L2C1-L4

### Proposed Action Plan

- Create PoC branch for Finder Frontend (to add content item into RSS feed)
- Create PoC branch for Travel Advice Publisher (to add content item into healthcheck URL)
- Create PoC branch for Email-alert-api (to implement current query/matching)
- Test in integration
- Go/No Go
- Retire email-alert-monitoring

It's suggested that Content Interactions on Platform CIOP, as owners of this application, be responsible for implementation.
