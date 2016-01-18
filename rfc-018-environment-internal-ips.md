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

| &nbsp; | Integration | Staging | Production | Notes |
| --- | --- | --- | --- | --- |
| ENV Carrenza | 10.1.0.1/19 | 10.2.0.1/19 | 10.3.0.1/19 | 10.X.0.1 -\> 10.(X+7).255.255 = 524,288 addresses |
| GOV.UK Org. | 10.1.0.1/21 | 10.2.0.1/21 | 10.3.0.1/21 | 10.X.0.1 -\> 10.X.255.255 = 65,536 addresses |
| DR Org. | 10.1.8.1/21 | 10.2.8.1/21 | 10.3.8.1/21 | &nbsp; |
| GOV.UK - Management VDC | 10.1.0.1/24 | 10.2.0.1/24 | 10.3.0.1/24 | 10.X.Y.1 -\> 10.X.(Y+1).255 = 512 addresses |
| DR - Management VDC | 10.1.8.1/24 | 10.2.8.1/24 | 10.3.8.1/24 | &nbsp; |
| GOV.UK - Router VDC | 10.1.1.1/24 | 10.2.1.1/24 | 10.3.1.1/24 | &nbsp; |
| DR - Router VDC | 10.1.9.1/24 | 10.2.9.1/24 | 10.3.9.1/24 | &nbsp; |
| GOV.UK - Frontend VDC | 10.1.2.1/24 | 10.2.2.1/24 | 10.3.2.1/24 | &nbsp; |
| DR - Frontend VDC | 10.1.10.1/24 | 10.2.10.1/24 | 10.3.10.1/24 | &nbsp; |
| GOV.UK - Backend VDC | 

10.1.3.1/24

 | 10.2.3.1/24 | 10.3.3.1/24 | &nbsp; |
| DR - Backend VDC | 10.1.11.1/24 | 10.2.11.1/24 | 10.3.11.1/24 | &nbsp; |
| GOV.UK - API VDC | 10.1.4.1/24 | 10.2.4.1/24 | 10.3.4.1/24 | &nbsp; |
| DR - API VDC | 10.1.12.1/24 | 10.2.12.1/24 | 10.3.12.1/24 | &nbsp; |
| GOV.UK - Redirector VDC | 10.1.5.1/24 | 10.2.5.1/24 | 10.3.5.1/24 | &nbsp; |
| DR - Redirector VDC | 10.1.13.1/24 | 10.2.13.1/24 | 10.3.13.1/24 | 

&nbsp;

 |

| &nbsp; | Integration | Staging | Production | Notes |
| --- | --- | --- | --- | --- |
| ENV Skyscape (Licensify & EFG) | N/A | 10.0.0.1/8 | 10.0.0.1/8 | &nbsp; |
| EFG Org. | N/A | 10.0.0.1/8 | 10.0.0.1/8 | &nbsp; |
| Licensify Org. | 10.0.0.1/8 | 10.0.0.1/8 | 10.0.0.1/8 | &nbsp; |
| EFG - EFG VDC | N/A | 10.4.0.1/16 | 10.4.0.1/16 | Uses old numbering format |
| Licensify - Licensify VDC | 10.5.0.1/16 | 10.5.0.1/16 | 10.5.0.1/16 | Uses old numbering format |

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

