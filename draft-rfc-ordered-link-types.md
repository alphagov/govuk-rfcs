# TL;DR

Links should be ordered again, but only when the name of the link type communicates that they're ordered.

# How links work now

The publishing API allows us to represent links between content items by posting a links hash containing arrays of content ids.

In our current model, a link stores 3 pieces of information about the relationship between two items:

We have [many link types](https://gist.github.com/MatMoore/e047a2807807c960e1f7c5fc3a7e34e3), which are used in different ways by the frontend applications.

Links can be updated as part of the publishing workflow, or they can updated separately (for example through content tagger). When we change the links originating from a content item, we make a PATCH request to its links URL, with a JSON object describing&nbsp;_link sets_.&nbsp;For example:

The ordering of items within the arrays is arbitrary in these requests: the publishing API deliberately ignores the ordering.

# Problem

As we've migrated more things to the new publishing platform, we've come across use cases where ordering of links matters, and have had to implement error-prone workarounds.

1. [ link type. There is a natural ordering around age of the child, which helps the user identify the section they need more quickly.  
  
Without the manual override, the sections would be sorted alphabetically, which is generally not very useful unless the user knows the exact name of the section they need. In the absence of more content-specific metadata to order by, manual ordering gets the job done.  
&nbsp;
2. &nbsp;  
&nbsp;
3. _ **&nbsp;the links are manually ordered by relevance rather than A-Z.

# Proposal&nbsp;

1. It should be possible to define, for each link type, whether the links are ordered or unordered.  
&nbsp;
2. Unordered link sets will be handled in the same way we handle all link sets now.  
&nbsp;
3. When a patch links request operates on ordered links, the publishing API must retain the ordering of the array when persisting the links to its database and loading them, and the expanded links passed to the content store should retain this ordering.  
&nbsp;
4. Whether the link type is ordered or unordered should be conveyed to the frontend applications. We suggest that the ordered/unordered distinction is conveyed by a naming convention: link types are unordered by default unless they start with the string "ordered\_". For example, to introduce ordering on related links, we would introduce a new link type, "ordered\_related\_links".

## Semantics

- Ordered links are intended to be used as a curation mechanism when there is a natural ordering to a link set that is not possible to infer from metadata of the target content items.  
&nbsp;
- Ordered links should not be used if the ordering can be inferred from the content itself by examining the expanded links hash, for example, A-Z ordering by title.  
&nbsp;
- Frontend applications shouldn't make any assumptions about what ordered links are ordered by; publishers should be free to choose an appropriate ordering for their content; for example, "early years comes before schools".  
&nbsp;
- Using an ordered link type should not place any restrictions on frontend rendering. It is possible for the rendering app to sort the links differently; for example, by providing alternate views that show recently updated pages first.  
&nbsp;
- The PATCH semantics of publishing API will be unchanged: it is not possible to change part of a link set without sending the entire thing to the publishing API.  
&nbsp;
- Frontend applications should use _ordered\_foo_ over&nbsp;_foo_ if both are available.&nbsp;  
&nbsp;
- Setting a link\_set of type&nbsp;_ordered\_foo_&nbsp;should automatically clear links with type&nbsp;_foo.  
&nbsp;_  
- Setting a link\_set of type&nbsp;_foo_ when a link set of type&nbsp;_ordered\_foo_ exists is allowed, so that publishing apps have the option to capture the ordering in a separate step.  
&nbsp;

- Ordered link types should not contain unordered link sets. Instead, use two link types, one ordered and one unordered. It should be obvious from the user interface what is being captured; for example, collections publisher presents ordering as an extra step:

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

