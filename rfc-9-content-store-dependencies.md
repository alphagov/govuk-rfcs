## **Aims**

An aim of the "publishing 2.0" design is that frontend apps should need to make a single call to the "content store" to get all the information they need to render a particular page.&nbsp;We've modified this slightly to say that in some cases (eg, finders, search pages) the frontend app might need to make a separate call to a "search api" (currently rummager), but this should only be necessary where there's an unbounded, user-generated, set of options to be displayed, and pre-calculating all the pages is implausible or impossible.

A separate aim is that "publishing" apps should be decoupled from the frontend world; all they should need to do is keep the content store updated with information about the pages they "own".

## **Problem**

In the "publishing 2.0" design as currently being implemented, it is currently difficult to model dependencies between pieces of content. &nbsp;Some examples:

&nbsp;

**Proposal**

&nbsp;

&nbsp;

&nbsp;

**Note:** &nbsp;there are also other, relatively minor problems with the current publishing 2.0 design, which I don't want to consider in detail here, but which would also be solved or partially solved by this proposal. &nbsp;In particular:

- The publishing tools are currently being encouraged by the design to pre-render HTML and store that in the content store. &nbsp;This is additional complexity, makes them slower to republish their content, and
- Ideally, we would b

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

