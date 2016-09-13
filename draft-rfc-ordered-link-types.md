# How links work now

The publishing API allows us to represent links between content items by posting a links hash containing arrays of content ids.

In our current model, a link stores 3 pieces of information about the relationship between two items:

We have [many link types](https://gist.github.com/MatMoore/e047a2807807c960e1f7c5fc3a7e34e3), which are used in different ways by the frontend applications.

Links can be updated as part of the publishing workflow, or they can updated separately (for example through content tagger). When we change the links originating from a content item, we make a PATCH request to its links URL, with a JSON object describing&nbsp;_link sets_.&nbsp;For example:

Content items aren't required to have an HTML representation, and not everything has a base path (for example contacts can be base-path-less).

The ordering of items within the arrays is arbitrary in these requests: the publishing API deliberately ignores the ordering.

# Problem

As we've migrated more things to the new publishing platform, we've come across use cases where ordering of links matters, and have had to implement error-prone workarounds.

[ link type. There is a natural ordering around age of the child, which helps the user identify the section they need more quickly.

Without the manual override, the sections would be sorted alphabetically, which is generally not very useful unless the user knows the exact name of the section they need. In the absence of more content-specific metadata to order by, manual ordering gets the job done.

&nbsp;

_ **&nbsp;the links are manually ordered by relevance rather than A-Z.

# Proposal&nbsp;

It should be possible to define, for each link type, whether the links are ordered or unordered.

Unordered link sets will be handled in the same way we handle all link sets now.

When a patch links request operates on ordered links, the publishing API must retain the ordering of the array when persisting the links to its database and loading them, and the expanded links passed to the content store should retain this ordering.

Whether the link type is ordered or unordered should be conveyed to the frontend applications. We suggest that the ordered/unordered distinction is conveyed by a naming convention: link types are unordered by default unless they start with the string "ordered\_". For example, to introduce ordering on related links, we would introduce a new link type, "ordered\_related\_links".

Using an ordered link type should not place any restrictions on frontend rendering. It is possible for the rendering app to sort the links in different ways depending on context.

When using ordered link types it should be clear to the user&nbsp;

## Semantics

Ordered links are intended to be used as a curation mechanism when there is a natural ordering to a link set that is not possible to infer from content item metadata.

Ordered links should not be used if the ordering can be inferred from the content itself by examining the expanded links hash, for example, A-Z ordering by title.

Frontend applications shouldn't make any assumptions about what ordered links are ordered by; publishers should be free to order links differently depending on the content.

The PATCH semantics of publishing API will be unchanged: it is not possible to change part of a link set without sending the entire thing to the publishing API.

Ordered link types should not contain unordered link sets. In cases where the publisher doesn't need to order the links in all cases, we recommend making this clear in the user interface, and using separate link types for ordered/unordered link sets. For example, collections publisher presents ordering as an extra step:

# Alternatives rejected by this proposal

## Making all link arrays ordered

Essentially reverting&nbsp;

- This has fuzzy semantics - it becomes unclear if the ordering is something the user intended or just the order they happened to enter it

## Changing the format of the links hash to include additional metadata

Previously rejected in&nbsp;

This is more flexiblebut also more work to implement.&nbsp;

- Difficult to make backwards compatible
- Lots of publishing apps would need to change
- Lots of frontend apps would need to change

## Keeping links unordered and adding a new container for ordered links

For example, adding a links\_metadata hash to the content store representation, while supporting the existing links hash as a fallback.

- 

Apps are forced to handle both cases separately, so there is more room for error

- 

Doesn't provide any additional benefit over RFC 38

# Related RFCs

- 
- 
- 

