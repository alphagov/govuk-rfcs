# Related RFCs

- 
- 

# How links work now

The publishing API allows us to represent links between content items by posting a links hash containing arrays of content ids.

In our current model a link encodes stores 3 pieces of information about the relationship between the two items:

We have many link types, which are used in different ways by the front end:

- active\_top\_level\_browse\_page
- children
- content\_owners
- document\_collections
- documents
- email\_alert\_signup
- lead\_organisations
- linked\_items
- mainstream\_browse\_pages
- manual
- ministers
- organisations
- parent
- parent\_taxons
- people
- policy\_areas
- press\_releases
- related
- related\_guides
- related\_mainstream
- related\_policies
- related\_statistical\_data\_sets
- related\_topics
- second\_level\_browse\_pages
- sections
- service\_manual\_topics
- supporting\_organisations
- taxons
- topical\_events
- topics
- top\_level\_browse\_pages
- working\_groups
- world\_locations
- worldwide\_organisations
- worldwide\_priorities

Links can be updated as part of the publishing workflow, or they can updated separately (for example through content tagger). When we change the links originating from a content item, we make a PATCH request to its links URL, with a JSON object mapping link types to arrays of content ids.&nbsp;For example:

Content items aren't required to have an HTML representation, and not everything has a base path (for example contacts can be base-path-less).

# The case for publisher-controlled ordering

# Proposal

## Semantics

# Alternatives rejected by this proposal

## Making all link arrays ordered

Essentially reverting&nbsp;

- Fuzzy semantics - unclear if the ordering is intended or not

## Changing the format of the links hash to include additional metadata

&nbsp;Previously rejected in&nbsp;

- More flexible
- Difficult to make backwards compatible
- Lots of publishing apps would need to change
- Lots of frontend apps would need to change

## Keeping links unordered and adding a new container for ordered links

- 

Apps are forced to handle both cases separately

---
status: "DRAFT"
notes: "Not yet complete"
---

## Problem

## Proposal

