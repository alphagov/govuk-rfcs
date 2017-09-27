## Problem

Currently, all GOV.UK components live in [static](https://github.com/alphagov/static). When a frontend application includes a component in a partial, the gem [slimmer](https://github.com/alphagov/slimmer) fetches that ERB template via HTTP from static (or cache), and then the frontend application renders the HTML with the relevant variables we pass into the template.

For more complicated components (e.g. related links), we use a gem called [govuk\_navigation\_helpers](https://github.com/alphagov/govuk_navigation_helpers). That gem receives the&nbsp;content-store representation of a content item and generates data suitable for some of those components (in some situations, by using the Search API).

There is an issue with this approach. As you know,&nbsp;when static gets deployed, all frontend apps immediately receive the new component updates (when the 15 minute&nbsp;cache expires). However, to make a data change to one of those components, we need to:

- make changes to&nbsp;govuk\_navigation\_helpers and&nbsp;bump the version;
- release that version;
- upgrade it in all frontend apps;
- deploy all frontend apps.

This means that:&nbsp;

- we have 2 ways of releasing changes to static and its components (one for the layout, another for the data);
- data updates to static components&nbsp;are very time consuming;
- both applications are dependent on each other.

Here is a simplistic version of how it looks:&nbsp;

A page is rendered from a content item from the content store. The content item's metadata is passed into govuk\_navigation\_helpers in order to generate data for the several components being used (breadcrumbs, title, side bar, etc). For the new taxonomy sidebar, we also query the search API for similar documents. We then fetch all relevant components from static via slimmer and render those with the data generated from govuk\_navigation\_helpers.

## Proposal

I would like to propose that:&nbsp;

- we move the functionality of govuk\_navigation\_helpers into static;
- we add the ability for static&nbsp;for respond with HTML blobs (i.e fully rendered components) rather than just ERB templates.

I believe this is an improvement because:&nbsp;

- allowing static to respond with fully rendered components allows us to actually test components in static. Currently, there is no way of reliably test that a component and its data render properly;
- we can re-use those rendered components in other contexts, independent of any programming&nbsp;language being used (e.g. render a sidebar in a prototype);
- we simplify the development workflow by&nbsp;only needing to update static for components changes.

This new workflow would look like this:

In this new diagram, we remove govuk\_navigation\_helpers and let static generate data for each of the components. In this workflow, we only query static once, with either a content item (a bit of data going through each request), or a content ID (and let static query the content store to get the metadata). Static also queries the Search API and builds up all the necessary components for a given content item. It then renders the HTML components and sends those in the response. The frontend application will then insert the necessary HTML components into the page.

The possible drawbacks of this approach are:&nbsp;

- More cache needed; we would no longer be caching a few ERB templates, but rendered components&nbsp;per content item;
- We will either be passing in a full representation of a content item, which means more data being passed through on each HTTP request; or we would be passing in a content ID, meaning static would perform an extra call to the content store to fetch the content item’s metadata.  
  

Note:&nbsp;I consider the auto-deployment of static an issue which is out of scope from this RFC.

What do people think of this approach?

