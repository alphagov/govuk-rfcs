# GOV.UK Request For Comments

GOV.UK staff use this repository as a forum to discuss and make technical decisions. The outcomes of these discussions can be either an action plan, or a new standard that GOV.UK should follow. This repository is open as a reference for other teams within GDS and wider government.

## Process

1. Create a new branch on this repo and copy `rfc-000-template.md` to `rfc-000-my-proposal.md` and edit.
2. Include any images etc in a separate directory named `rfc-000` and link to them.
3. Make a Pull Request (PR) for your branch and open as a draft.
4. Rename your file and directory with the number of the PR and push changes.
5. When your RFC is ready to be commented on, mark you PR as "Ready for review" and set a deadline for comments (2 weeks is a common choice) and record that in the PR description.
5. Post a link to your PR in #govuk-developers on Slack and to the [govuk-tech-members][govuk-tech-members] Google Group.
6. GOV.UK members discuss your proposal using both inline comments against your RFC document and the general PR comments section. Non-technical staff will need to create a free Github account in order to comment.
7. As changes are requested and agreed in comments, make the changes in your RFC and push them as new commits.
8. Stay active in the discussion and encourage other relevant people to participate. If you’re unsure who should be involved in a discussion, ask your Tech Lead or a Lead Developer. If you start an RFC it’s up to you to push it through the process and engage people.
9. Once the deadline is reached you are able to merge if the PR has been approved by a member of GOV.UK Senior Tech (if they haven't or you're not sure, you can contact them on Slack with @govuk-senior-tech-people) - this action is the accepting of an RFC.

### If consensus isn't reached

Should consensus not be reached by the deadline, an RFC can either have the deadline extended or the RFC can be closed as something not approiate for accepting now. For a deadline extension, you should make an effort to inform #govuk-developers about this status and request extra input. If the RFC is being closed, leave a comment explaining the status and close the PR.

### If the proposal is no longer needed

If the proposal is no longer applicable the RFC PR can be closed. Please include a comment explaining why to help anyone considering the problem in future.

## Managing Standards

Standards RFCs shouldn’t be substantially altered after they are accepted, although it’s fine to correct typos and other mistakes via a new PR. In order to change a Standard, the original RFC must be superseded by a new one. The process for this is:

1. Create a new RFC PR as above, noting in the summary which RFC it is superseding.
2. In the same branch, mark the old RFC as superseded and link to the new RFC and move (using `git mv`) it into the archived directory.
3. When the new RFC is accepted and the PR is merged, the old RFC will no longer be active.

## Managing Action Plans
For RFCs where the outcome is an agreed Action Plan, you may want to update the RFC with meaningful status updates in new PRs. Once the plan is either complete or no longer relevant, it should be moved to the archived directory in a new PR.

## Historical RFCs

Some RFCs in this repository were migrated from Confluence. They’ve been automatically converted to Markdown, so some formatting might be incorrect. Please fix any issues as you find them in new PRs.

## RFC metadata as YAML frontmatter

Some RFCs have YAML frontmatter which allows us to track their status / implementation etc.

<details>
<summary>Script to list all RFC metadata</summary>

```ruby
#!/usr/bin/env ruby

require "csv"
require "yaml"

frontmatter_columns = %w[status implementation status_last_reviewed status_notes]
CSV do |csv|
  csv << ["filename", *frontmatter_columns]
  Dir.glob("rfc-*.md") do |filename|
    first_line = File.readlines(filename).first
    frontmatter = {}
    frontmatter = YAML.load_file(filename, permitted_classes: [Date]) if first_line =~ /^---$/
    csv << [filename, *frontmatter.values_at(*frontmatter_columns)]
  end
end
```

</details>

[govuk-tech-members]: https://groups.google.com/a/digital.cabinet-office.gov.uk/forum/#!forum/govuk-tech-members
