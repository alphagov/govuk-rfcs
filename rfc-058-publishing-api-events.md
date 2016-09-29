## Problem

An event is created for every request that comes into the publishing API.  
These events are used as a form of Event Sourcing to track the application state  
as a series of events over time, and can be used to reconstruct past states.

One of the problems is the sheer number of events that go through the  
publishing API, roughly growing at 600MB a month, currently sitting at 6GB,  
4.2 million events, which has implications for replication, and for developers  
copying that data to their local environments.

The other problem being that the event information, as it stands, starts losing its effectiveness  
over time, with code changes, schema changes and API version changes, the ability  
of being able to replay the events from scratch gets lost.

## Proposal

The event information is useful for replaying events and debugging but we would

like to archive the events in the events table, but with still having ability to:

1. &nbsp; Easily search through events for debugging
2. &nbsp; The ability to retrieve events, to replay in the case of failure.
3. &nbsp; Store future events

------------------------------------------------------------------------------------------------------------------  
Option A:  
Start storing events in Elasticsearch.

This would imply that we no longer store events in the Publishing API, but rather  
every time an event occurs, we asynchronously store it in elasticsearch. We would  
need to decouple events from any command, and store the event in the same transaction.  
Which has further implications of sending versioned data downstream to the  
content store, which currently is managed by the event id.

pros:

- Ease of storing and retrieving events and rich query language makes this useful for debugging
- No development time needed to build an interface (Kibana)
- Already part of our infrastructure
- Easily retrieve events to replay

cons:

- Reliability, if someone accidentally deletes the index
- Effectively becomes the primary data source of events
- Might also need archiving as a backup

------------------------------------------------------------------------------------------------------------------  
Option B:  
Log payload params directly to logstash

This would mean simply logging the request params in the log,  
and loses any concept of an event

pros:

- Very little work initially
- No other elasticsearch clusters

cons:

- Difficult to backdate events
- More difficult to replay events
- Not as easy to query since it will be interspersed with other data

------------------------------------------------------------------------------------------------------------------  
Option C:  
Another Postgres DB in the Publishing API

By establishing a different connection in the Events model  
[http://api.rubyonrails.org/classes/ActiveRecord/Base.html](http://api.rubyonrails.org/classes/ActiveRecord/Base.html)

pros:

- Same infrastructure as current publishing API
- Little to change

cons:

- Doesn't solve the problem of data replication
- Increases complexity

------------------------------------------------------------------------------------------------------------------  
Other Options:  
 Archive to S3 and carry on as normal

