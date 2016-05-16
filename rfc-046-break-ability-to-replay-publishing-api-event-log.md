## Problem

The Event Log is a log of all requests received by the publishing api. Theoretically, we should be able to replay each of these events in turn against a blank database and end up with the same content as in the current live publishing api database.

In practice, this replaying of events takes too long to be useful for disaster recovery. It also prevents in situ changes to data via data migrations and the Rails console, as these changes are not recorded in the event log, and thus wouldn't be replayed. There have already been data migrations and instances of "devopsing" in production which has broken the integrity of the Event log.

## Proposal

In order to allow for more flexibility to developers to make ad hoc changes to data in time pressured situations, we're proposing we remove the implied contract that the event log can be replayed at any time. In practice, it is unlikely we'll ever need to do this. The event log is still very important as an audit trail of actions that have occurred in the publishing API, so this change will enable us to change how the log is stored long term. There are already almost 1.5m events in the log, and postgresql is not the most efficient solution for storing these.

The event log needs to be retained for now as the primary key for the table is used as an atomic counter for content items lock versions. We could in future archive events into cold storage after a certain time period.

&nbsp;

&nbsp;

