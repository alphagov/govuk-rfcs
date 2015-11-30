## Problem

Content items can be linked to other content items such as topics, organisations and mainstream browse pages.&nbsp;These links are in the "links" hash in the content item.

To render certain pages we need to retrieve all the&nbsp;items that have links to the content item.&nbsp;For example, the "Buying a cat or dog" page&nbsp;([https://www.gov.uk/guidance/buying-a-cat-or-dog](https://www.gov.uk/guidance/buying-a-cat-or-dog))&nbsp;is linked to the topic page "Pets" ([https://www.gov.uk/topic/animal-welfare/pets](https://www.gov.uk/topic/animal-welfare/pets)). The content item for "Buying a cat or dog" contains a reference to "Pets" in its links hash, but the item for&nbsp;"Pets" doesn't contain a reference to "Buying a cat or dog". We currently use Rummager to serve the list of pages linked to "Pets".

&nbsp;

## Proposal

The content-store should return incoming links as well as outgoing links.

However, we do not wish to do this automatically, because some items have an extreme amount of incoming links (there are almost [10K](https://www.gov.uk/api/search.json?filter_organisations=hm-revenue-customs&count=0) incoming links for the HMRC organisation).

Therefore we propose that each document describes which incoming links should be returned.

&nbsp;

## Example

Given we have a content item, with a 'parent' link to another item:

&nbsp;

We specify the dependencies in the other content item:

&nbsp;

&nbsp;

Which will cause this to be returned from the content-store:

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

  

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

