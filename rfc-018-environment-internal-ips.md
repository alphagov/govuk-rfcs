&nbsp;

&nbsp;

---
status: "IN PROGRESS"
notes: " "
---

## **Problem**

Currently all our environments use the same very large internal IP ranges

1. Identical IPs makes using VPNs to talk between Org.s within an environment hard
2. We are being really wasteful with IPs

**Proposal**

We will have three environments - preview, staging and production. Each envirionment will have three organisations - GOV.UK, Disaster Recovery and Licensify. GOV.UK and DR organisations will contain six vDCs - management, router, frontend, backend, API and redirector. The Licensify org will contain one vDC called Licensify.

- Each VDC should have a /24 assigned to it
- Each Org. should have a /21&nbsp;assigned to it
- Each ENV should have a /19 assigned to it

&nbsp;

&nbsp;

| &nbsp; | Preview | Staging | Production | Notes |
| --- | --- | --- | --- | --- |
| ENV | 10.0.0.1/19 | 10.8.0.1/19 | 10.16.0.1/19 | 10.X.0.1 -\> 10.(X+7).255.255 = 524,288 addresses |
| GOV.UK Org. | 10.0.0.1/21 | 10.8.0.1/21 | 10.16.0.1/21 | 10.X.0.1 -\> 10.X.255.255 = 65,536 addresses |
| Licensify Org. | 10.1.0.1/21 | 10.9.0.1/16 | 10.17.0.1/21 | &nbsp; |
| DR Org. | 10.2.0.1/21 | 10.10.0.1/21 | 10.18.0.1/21 | &nbsp; |
| GOV.UK - Management VDC | 10.0.0.1/24 | 10.8.0.1/24 | 10.16.0.1/24 | 10.X.Y.1 -\> 10.X.(Y+1).255 = 512 addresses |
| DR - Management VDC | 10.2.0.1/24 | 10.10.0.1/24 | 10.18.0.1/24 | &nbsp; |
| GOV.UK - Router VDC | 10.0.2.1/24 | 10.8.2.1/24 | 10.16.2.1/24 | &nbsp; |
| DR - Router VDC | 10.2.2.1/24 | 10.10.2.1/24 | 10.18.2.1/24 | &nbsp; |
| GOV.UK - Frontend VDC | 10.0.4.1/24 | 10.8.4.1/24 | 10.16.4.1/24 | &nbsp; |
| DR - Frontend VDC | 10.2.4.1/24 | 10.10.4.1/24 | 10.18.4.1/24 | &nbsp; |
| GOV.UK - Backend VDC | 

10.0.6.1/24

 | 10.8.6.1/24 | 10.16.6.1/24 | &nbsp; |
| DR - Backend VDC | 10.2.6.1/24 | 10.10.6.1/24 | 10.18.6.1/24 | &nbsp; |
| GOV.UK - API VDC | 10.0.8.1/24 | 10.8.8.1/24 | 10.16.8.1/24 | &nbsp; |
| DR - API VDC | 10.2.8.1/24 | 10.10.8.1/24 | 10.18.8.1/24 | &nbsp; |
| GOV.UK - Redirector VDC | 10.0.8.1/24 | 10.8.10.1/24 | 10.16.10.1/24 | &nbsp; |
| DR - Redirector VDC | 10.2.8.1/24 | 10.10.10.1/24 | 10.18.10.1/24 | &nbsp; |
| Licensify - Licensify VDC | 10.1.0.1/24 | 10.9.0.1/24 | 10.17.0.1/24 | &nbsp; |

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

