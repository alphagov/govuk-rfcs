# Case insensitive routing on GOV.UK

## Summary

Make lowercase base paths canonical and redirect any uppercase or mixed-case base paths to their lowercase equivalent, except the final part if it is a filename.

## Problem

Our stack currently regards all base paths to be case-sensitive. The router carries out routing on this basis. Although nginx has a configuration that redirects all-uppercase base paths to their lowercase equivalent, there are no rules for mixed-case base paths.

In addition, publishing-api allows multiple content items where the base paths are only differentiated by case.

This has the potential to cause confusion for end users if they try to visit a page using a mixed-case path. In most circumstances, it results in a 404 error, but in the case of prefix routes, the result can be unpredictable since the routing is handled by the backend application.

It can be argued that most end users do not understand and do not care about case sensitivity, and would be surprised to learn that there is the potential for www.gov.uk/education to lead to a navigation page whereas www.gov.uk/Education leads to a 404 error, or even worse, can be claimed by a completely different app displaying a different page.

Case sensitivity as a general rule made sense when all requests were for files stored on a file system which was itself case sensitive. However, given that most of our base paths are virtual and routed to apps, this argument does not apply. It can, however, still apply to paths to attachments which are actual files stored on a file system. There should be a way to preserve the case of these filenames.

## Proposal

* The router should redirect all mixed-case and uppercase base paths to their lowercase equivalent (except for the filename portions of base paths) with a 301 redirect
* publishing-api should be audited to find any existing content that differs only in the case of the base path, and these should be resolved
* publishing-api should either not accept publishing to base paths that are not in lowercase or should lowercase the base path itself before publishing
