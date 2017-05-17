## Problem

So far, we've been describing the progress of Migration using the terms "phase 1" and "phase 2". These terms have no formal definition, have become overloaded and can incorrectly imply the intent for our work. They were born out of casual conversation when Migration started, but are now used formally in our roadmap. There is confusion about the definition of the terms, and they are mis-applied to applications rather than formats. The terms also mask additional complexity, "phase 1" is more complicated than a single stage of work.

## Proposal

Firstly, we should stop applying these states to entire applications. The only time we're able to refer to an application as a single state on the migration journey is when all of its formats are fully migrated, at which point we can stop talking about it altogether. A publishing application is responsible for a range of formats, and due to the process of migration these formats can and will be in different states.

Our proposed terminology is:

| Name | Description |
| --- | --- |
| **Pre-migration** | Publishing API is unaware of the existence of this format. The publishing app does not send this content to the API. |
| **Placeholder** | Placeholders are sent to the Publishing API to represent the existence of documents of this format. They have at least a base path (where appropriate) and a title. |
| **Content complete** | The Publishing API has everything needed for a frontend application to render the static content of documents of this format. The frontend application does not yet use this content to render documents. |
| **Rendered** | As above, but a frontend application makes a request to the content store in order to render the static content. The publishing application is still the source of truth for the content, not the Publishing API. |
| **Migrated** | The Publishing API is the canonical source of truth for the content for this format. The publishing application treats the Publishing API as its database, and the content can be removed from the publishing application's database. |

