# Problem

Currently detailed guides live at urls like: [https://www.gov.uk/british-forces-overseas-posting-cyprus](https://www.gov.uk/british-forces-overseas-posting-cyprus)  
This can cause problems because editors are able to create documents and claim high-profile slugs which shouldn't really be used for guidance  
Instead they should be published as https://www.gov.uk/guidance/[thing]

Note that currently manuals are also published under `/guidance` so we will need to check using url arbiter or equivalent to ensure the path can be claimed.

# Proposal

1. 

Ensuring new detailed guides are served under /guidance/

  1. 

adding 'guidance/' in front of the detailed\_guides#show route in routes.rb (but keeping the old route live (without 'as:detailed\_guides') to cover deploy time - to be removed 30mn after deploy)

2. 

Data migration

  1. 

check in the console that when adding "guidance/" in front of the existing detailed guides path, there are no duplicates (since manuals also use guidance/), by asking url-arbiter

  2. 

create a data migration that publishes the new routes and the redirect routes to the router

3. 

Tell Content-store about new routes

  1. 

publish the content items with updated routes to content-store, and create redirect items in content store - question for the publishing team: does content-store update placeholder content-items in the router?

&nbsp;

