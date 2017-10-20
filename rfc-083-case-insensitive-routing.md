# Case insensitive routing on GOV.UK

## Summary

Make base paths case insensitive for routing purposes, and only allow one case of a base path to be registered with the router and publishing-api.

## Problem

Our stack currently regards all base paths to be case-sensitive. The router carries out routing on this basis. Although nginx has a configuration that redirects all-uppercase base paths to their lowercase equivalent, there are no rules for mixed-case base paths.

In addition, publishing-api allows multiple content items where the base paths are only differentiated by case.

This has the potential to cause confusion for end users if they try to visit a page using a mixed-case path. In most circumstances, it results in a 404 error, but in the case of prefix routes, the result can be unpredictable since the routing is handled by the backend application.

It can be argued that most end users do not understand and do not care about case sensitivity, and would be surprised to learn that there is the potential for www.gov.uk/education to lead to a navigation page whereas www.gov.uk/Education leads to a 404 error, or even worse, can be claimed by a completely different app displaying a different page.

Case sensitivity as a general rule made sense when all requests were for files stored on a file system which was itself case sensitive. However, given that most of our base paths are virtual and routed to apps, this argument does not apply.

## Proposal

* The router should only allow one case (uppercase, lowercase or mixed case) of a base path to be registered as a route (so `/education` can be registered but `/Education` will be regarded to be a duplicate)
* The router should match requested base paths to routes in a case insensitive manner (so a request for `/EDUCATION` will match `/education`)
* The router should redirect requested base paths that match a route lexically but not in case with a 301 redirect to the route in the case is it registered with (so a request for `/EDUCAtion` will result in a 301 redirect to `/education`)
* publishing-api should be audited to find any existing content that differs only in the case of the base path, and these issues should be resolved
* publishing-api should only allow one case of a base path to be registered
