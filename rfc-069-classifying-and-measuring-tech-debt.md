# Classifying and measuring tech debt in GOV.UK

While planning for the the work we’re doing on GOV.UK in Q4 and 2017-18, we need a common language between technologists and product people to describe the scale and scope of technical debt. The language should enable communication of the benefits of individual pieces of work that pay down tech debt. It should also enable us to be clearer about the consequences of not doing something, or leaving a piece of work in a certain state. It should also allow us to track the reduction or accumulation of technical debt over time. It should not add significant overhead to planning, and assigning a rating to a piece of technical debt should be quick and simple.

### Example consequences of tech debt

- Harder to patch security vulnerabilities
- Harder to implement new features
- Harder to onboard new developers
- Consumes too many compute resources
- Too closely coupled to an architecture
- Causes too many support tickets
- Creates too much chore work
- Difficult to debug issues
- Inconsistent architecture

### Example causes of tech debt

- Out of date dependencies
- Hardcoded configuration
- Component has too many responsibilities
- Long running test suite
- Manual deployment task
- Missing documentation
- No admin interface
- Not using lessons learnt since build

### Examples of things that are tech debt

- Whitehall has its own upload management system (inconsistent)
- Organisations can’t be renamed without developer input (chore)
- Manuals Publisher uses complex patterns (harder to work on)

### Examples of things that are not tech debt

- Whitehall (scope too large)
- Router written in Go (reasonable choice of tool for problem)
- Signon 2SV doesn’t support SMS (product decision)
- Router API functionality isn’t built into Content store (no significant ongoing cost)
- Transition configures Errbit with a deployment secret instead of env var (too small)

### Classifying and measuring

Classifying tech debt uses two factors: the impact of the consequence and the effort required to remove the cause. Both are subjectively measured as high (red), medium (amber) or low (green) with a justification and explanation of the cause and consequence. These are subjectively combined into an overall high/medium/low risk rating, with the reason for the relative weighting also recorded. This rating signifies the risk and associated cost with not dealing with the item right now. In some circumstances (such as an upcoming planned rewrite or retirement) we would accept a high risk as the item would go away naturally anyway. For this reason, the risks don't necessarily map directly to priorities.

This is similar to how risks are recorded in a Risk Register. High, medium and low ratings are given for impact and likelihood along with a combined overall rating based on a decision about the relative importance of the impact and likelihood. The higher the overall rating, the more the programme should be concerned about it.

The more specific you can be about the impact that is being felt, the easier it will be to make good decisions about the priority of fixing those. Examples of metrics that make it easy to talk about value:

* we are spending two days per month working around this
* our cycle time for every release is 30 minutes longer than it should be
* it takes fifteen minutes longer to diagnose problems with this than it should

### Process

Items of Technical Debt will be recorded on a [Trello board](https://trello.com/b/oPnw6v3r/gov-uk-tech-debt). Any member of GOV.UK can suggest an item by adding a card to the “Proposed” list. Members of GOV.UK senior tech leadership will triage these on a fortnightly basis, agree the assigned ratings and add them to the correct category. They should also review each item every 3 months.

Technical leadership across GOV.UK (Technical Architects, Technical Leads and Lead Developers) should use these lists during conversations with Product and Delivery Managers when prioritising work. Technical debt existing on the register doesn’t necessarily mean it will be paid down at any point, only that GOV.UK is conscious of its existence and will take it into account in product decisions.

Tracking debt as it gets created will follow the same process, with a link to a Trello card on a team’s backlog for the story that created it. The debt review process doesn’t make decisions on whether the creation of the debt is the correct thing to do, that decision stays with the product team.

If something is too small in scope to be included on the board, it should be recorded in the relevant repository's Github issues. Tech leads should review these regularly as part of prioritisation.

### Examples

#### Whitehall has its own upload management system

**Cause**: Whitehall’s system for handling uploads of PDFs, CSVs and images from publishing users is different to the Asset Manager application used by Specialist Publisher and others. This is due to it being developed in isolation from another system.

**Consequences**:

- Inconsistent architecture
- Too closely coupled to physical disk
- Causes support tickets due to delay in processing attachments

Impact of debt: **High** due to confusion, operational restrictions and support burden.

Effort to pay down: **High** due to the technical effort involved in changing Whitehall to talk to Asset Manager, implementing missing features in Asset Manager and migrating existing assets.

Overall rating: **High**

---

#### Organisations can’t be renamed without developer input

**Cause**: Reslugging an organisation is a multi step process across a number of applications. Some steps are not required depending on how much content exists for an organisation.

**Consequences**:

- Creates too much chore work

Impact of debt: **Low** due to volume of requests

Effort to pay down: **High** due to the work required across all apps to simplify this process.

Overall rating: **Low** due to relative support burden.

---

#### Manuals Publisher uses complex design patterns

**Cause**: Manuals Publisher is written in a style that is unfamiliar to many Rails developers, and requires alterations in many areas of the code base to deliver a story.

**Consequences**:

- Harder to patch security vulnerabilities
- Harder to implement new features
- Harder to onboard new developers
- Harder to fully migrate

Impact of debt: **Medium** due to the impact of these consequences. The application is not often worked on, so the ongoing cost to maintain it is low. Full migration would likely necessitate a rewrite or significant refactor.

Effort to pay down: **Medium** as the actual functionality is relatively small and good prior art exists elsewhere for best practices for a simple publishing application (eg. specialist publisher), however removing this pattern would be a significant refactor or rewrite.

Overall rating: **Medium**

