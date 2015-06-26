&nbsp;

&nbsp;

---
status: "IN PROGRESS"
notes: " "
---

## **Problem**

Currently all our environments use the same very large internal IP ranges

1. Identical IPs makes using VPNs to talk between orgs within an environment hard
2. We are being really wasteful with IPs

**Proposal**

We will have 3 environments(ENV)(Preview, Staging, Production), Each ENV will have 3 Organizations(ORG)(Live, DR, Licensify). Live and DR ORGs will have 6 Virtual Data Centres(VDC)(Management, Router, Frontend, Backend, API, Redirector). The Licensify ORG will only have one VDC called Licensify.

- Each VDC should have a /23 assinged to it
- Each ORG should have a /16 assinged to it
- Each ENV should have a /13 assinged to it

&nbsp;

&nbsp;

| &nbsp; | Preview | Staging | Production | Notes |
| --- | --- | --- | --- | --- |
| ENV | 10.0.0.1/13 | 10.8.0.1/13 | 10.16.0.1/13 | &nbsp; |
| Live ORG | 10.0.0.1/16 | 10.8.0.1/16 | 10.16.0.1/16 | &nbsp; |
| Licensify ORG | 10.1.0.1/16 | 10.9.0.1/16 | 10.17.0.1/16 | &nbsp; |
| DR ORG | 10.2.0.1/16 | 10.10.0.1/16 | 10.18.0.1/16 | &nbsp; |
| Live - Management VDC | 10.0.0.1/23 | 10.8.0.1/23 | 10.16.0.1/23 | &nbsp; |
| DR - Management VDC | 10.2.0.1/23 | 10.10.0.1/23 | 10.18.0.1/23 | &nbsp; |
| Live - Router VDC | 10.0.2.1/23 | 10.8.2.1/23 | 10.16.2.1/23 | &nbsp; |
| DR - Router VDC | 10.2.2.1/23 | 10.10.2.1/23 | 10.18.2.1/23 | &nbsp; |
| Live - Frontend VDC | 10.0.4.1/23 | 10.8.4.1/23 | 10.16.4.1/23 | &nbsp; |
| DR - Frontend VDC | 10.2.4.1/23 | 10.10.4.1/23 | 10.18.4.1/23 | &nbsp; |
| Live - Backend VDC | 

10.0.6.1/23

 | 10.8.6.1/23 | 10.16.6.1/23 | &nbsp; |
| DR - Backend VDC | 10.2.6.1/23 | 10.10.6.1/23 | 10.18.6.1/23 | &nbsp; |
| Live - API VDC | 10.0.8.1/23 | 10.8.8.1/23 | 10.16.8.1/23 | &nbsp; |
| DR - API VDC | 10.2.8.1/23 | 10.10.8.1/23 | 10.18.8.1/23 | &nbsp; |
| Live - Redirector VDC | 10.0.8.1/23 | 10.8.10.1/23 | 10.16.10.1/23 | &nbsp; |
| DR - Redirector VDC | 10.2.8.1/23 | 10.10.10.1/23 | 10.18.10.1/23 | &nbsp; |
| Licensify - Licensify VDC | 10.1.0.1/23 | 10.9.0.1/23 | 10.17.0.1/23 | &nbsp; |

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

