## Problem

Publishing apps store change history for content items in a variety of different ways. As we move to a more centralised workflow, we need a consistent way of recording this data in the publishing-api and providing it for display to editors in publishing apps and to users in the frontends.

## Current behaviour

Content history is usefully split into two mostly separate types. Public change history is exposed to users on the front end, and usually consists of a list of major update dates and manually entered change notes. Version history is shown to users in the publishing apps, and consists of dates when the content was changed or versioned; it might also include notes to other editors or fact checkers.

The existing apps support a mixture of these history types:

**Whitehall**

- Public change note: note, public timestamp - one per edition
- Fact check requests: instructions (i.e. note from editor), comments (i.e. response from fact-checker)
- Editorial remarks: body, author
- Versions: event (create, update), state (draft, published, submitted), user

**Travel Advice Publisher**

- Version history and public change notes only

**Publisher**

- Public change note is available as a field to edit but it is not displayed anywhere
- Important note, edition note and action are all the same model: recipient, requester, comment, request type (new\_version, assign, request\_review, important\_note...)
- Fact check responses are stored as actions but requests are not currently stored

**Specialist Publisher**

- Public change history only: date, change note (currently being sent embedded in details, built up manually)

**Service Manual Publisher**

- Public change history: date, change summary, reason for change
- State change events: new draft, assign author, add comment, request review, approve, publish

**Content tagger**

- No history

## Proposal

###   
Public change history

The&nbsp;`change_history`&nbsp;element will be deprecated in the publisher schemas; apps will stop building up this history themselves, and instead just send the current public change note.&nbsp;

Publishing API will record, in a separate table, the set of **change notes**associated with a specific content ID. The&nbsp;`publish` command will, for major versions only, add an entry in this table with the contents of the&nbsp;`change_note`&nbsp;in the ContentItem to be published and the publish time. To support Service Manual Publisher,&nbsp;`reason_for_change` will be accepted in the schemas directly at the same level as&nbsp;`change_note`&nbsp;and recorded alongside it in the change notes table.

The downstream presenters will assemble the public content history from the list of change notes.

### Version history

Publishing API should support the concept of **actions**. An action will link to a ContentItem or LinkSet and record all the activity that happens to that version - create, update, publish, unpublish etc - along with the ID of the user who performed that action, the email address of any recipient, and the text of any note/remark. Actions could also link to the Event that caused the change.

&nbsp;will be each create an action when they are called. In addition, we could store the diff between the current and previous versions on each change; a&nbsp;[spike into this](https://github.com/alphagov/publishing-api/compare/content_history) already exists.

The list of action types will be a superset of all those supported by the publishing apps, and no extra validation will be carried out to ensure that the action makes sense given the current state; at this point we are only recording history, we are not providing workflow or a state machine.

Whitehall (and Publisher once we start migrating it) will also need to start sending data specifically for those actions that do not result from existing commands - eg add note/remark, send for fact check, etc. This will probably need to be on a new&nbsp;`action` endpoint; we might later decide to split these out into separate endpoints when we start implementing the workflow itself, but it will be helpful to start storing the data now.

