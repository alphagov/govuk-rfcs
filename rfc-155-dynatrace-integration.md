# RFC 155 Dynatrace Integration Design

## Summary

The Dynatrace SaaS (coincidently hosted on AWS) has been purchased to improve the observability of the OneLogin programme; from both a live-ops/support perspective and also a development lifecycle perspective (e.g. testing, pipeline, build maturity etc).

## Problem
This RFC sets out the design for the integration of Dynatrace into the OneLogin programme. As Dynatrace offers many different integration (data, network, security) approaches and tooling, this document considers what is required, possible options and an associated recommendation.

Dynatrace broadly supports the collection of the following data types;

| Data Type  | Description |
|------------------|:----------------|
|Lambda / Container Specific Metrics |	Data about the lambda function being executed, e.g. execution latency, executions/sec |
|Generic / Cloud Metrics|Metrics from AWS services, or those pushed to CloudWatch metrics from custom apps. Some of these include aspects of other data types (e.g. for synthetic transactions, AWS Canaries publish data to CloudWatch metrics)|
|Pipeline Metrics|Metrics related to pipeline activities (e.g. DORA)|
|Logs|Out of scope for OneLogin|
|Synthetic Transactions / Journeys|Metrics relating to the performance of synthetic agents/transactions|
|Tracing Events|Instrumentation of code, spanning multiple distributed components/services into a coherent view of end to end performance.|

## Proposal

### Dynatrace SSO

Dynatrace SaaS supports the integration of a SSO provider, including Google docs and therefore this shall be configured. Detailed design shall be conducted into specific role names/permissions (potentially aligned to Grafana roles).


### Invocation Metrics

#### Lambda
In order to instrument lambda functions, the Dynatrace OneAgent layer needs to be incorporated into lambda execution configuration. OneAgent is required to be configured with an API key, stored in Secrets Manager.  

###	Generic / Cloud Metrics

**Option 1**

Dynatrace SaaS can scrape CloudWatch metrics and import these into the relevant Dynatrace environment. We’re not sure if there’s a maximum number of accounts that can be supported by this route. 

**Option 2**

Each AWS account where CloudWatch metrics are required to be imported in from is configured with a Fargate hosted container, which scrapes CloudWatch metrics and pushes these into the relevant Dynatrace environment.

**Option 3**

Each AWS account where CloudWatch metrics are required to be imported in the Dynatrace metric stream client is deployed. This client essentially is a kinesis firehose which streams metrics directly from CloudWatch metrics to Dynatrace.

**Comparison** 

| Dimension  | Option 1 | Option 2 | Option 3 |
|------------------|:----------------|:----------------|:----------------|
|Time for metrics to be visible	|[configurable] scraping schedule (frequency TBC)|[configurable] scraping schedule (frequency TBC)|	Near real time|
|Security|	Dynatrace assumes a role to retrieve data (TBC)|	Data is pushed from Team AWS account to Dynatrace|	Data is pushed from Team AWS account to Dynatrace|
|Cost|$1 per 100k metric API requests ($17 per day for 100 accounts/5secs)|$1 per 100k metric API requests ($17 per day for 100 accounts/5secs) + $40 per AWS account for container charges.|1000 records/sec ~ $15 per day|

The recommendation is to deploy the metricstream client as it offers a better security posture and metrics in near realtime. However, if the firehose charges start to become material, non-critical metric sets should be delivered via option 1.

###	Pipeline Metrics

**Github**
Dev Teams can configure the Dynatrace github action ‘DynatraceAction’ to push CI metrics into Dynatrace SaaS. 

**AWS Code Pipeline**
AWS Code Pipeline metric can be retrieved from CloudWatch metrics as per above.

###	Synthetic Transactions / Journeys

Dynatrace supports synthetic transaction, which can be executed from outside of the team accounts (i.e. over the internet) or through an agent deployed into the account. 

###	Tracing Events

To gain insight into the performance of a single user journey, the OneAgent hooks into lambda code to establish a tracing framework without any further developer work.

###	Other

There are further Dynatrace data collection capabilities, both within the OneAgent tool (such as the statsd server) as well as from the community. 

### Data Aggregation

Where metricstream or OneAgent is used to push data to the Dynatrace SaaS, Dynatrace provides an optional (no cost) aggregation/proxy product ‘ActiveGate’, which can run either on an EC2 instance or in a container. Sending data through an ActiveGate consolidates and compresses the data, aggregeates connections from metricstream/oneagents and can make network design/policy simpler (e.g. instead of having many lambdas all sending to Dynatrace, they send to a single ActiveGate which forwards the data on).

**Option 1**

No ActiveGates 

![Option 1](<rfc-155/Option 1.png>)

**Option 2**

Each AWS account hosts their own ActiveGate container (e.g. in Fargate) 

![Option 2](<rfc-155/Option 2.png>)

**Option 3**

The platform team provide a small cluster of ActiveGates

![Option 3](<rfc-155/Option 3.png>)

**Comparison**

| Dimension  | Option 1 - No Active Gates| 	Option 2 - Per AWS Account	| Option 3 – Shared ActiveGate Cluster| 
|------------------|:----------------|:----------------|:----------------|
|Security	|Direct (outbound) TCP socket from Lambda to Dynatrace.	|TCP socket terminated in Project VPC, new socket established to Dynatrace SaaS	|TCP socket terminated in Platform VPC, new socket established to Dynatrace SaaS|
|Network Design / Policy|More effort to whitelist each ENI (i.e. each lambda) which needs to send data to Dynatrace|More control over source IP addresses egressing (i.e. just the fargate container). Each account needs to whitelist Dynatrace as a destination and maintain it | Simplest approach as egress points within AWS accounts can be configured to only send traffic to the platform ActiveGate cluster|
|Cost|	Lowest cost, just egress to the send the data (e.g. data transfer charges & NAT GW bandwidth) expected to be negligible|	High cost to run a dedicated ActiveGate container in each AWS account. Egress to the send the data (e.g. data transfer charges & NAT GW bandwidth) expected to be negligible.|Small cost to run a couple of containers, NAT GW and a load balancer. Double AWS egress charges, but these ought to be negligible|

The recommendation is that assuming project teams have the existing capabilities to whitelist ENI traffic to the Dynatrace SaaS, then this should be adopted (i.e. Option 1 -No ActiveGate) as the cost and security benefits are not commensurate with the cost of deploying ActiveGates. However, if there is considerable work required for each account, then the shared platform model provides the best balance of cost and ease of network design.

### Data Segregation

Data ingested into / processed by the Dynatrace SaaS service shall be segregated as follows.

### Environments

Two Dynatrace environments shall be configured; Production and Test. The production environment shall host all data produced from the Developer Team’s Production AWS accounts. The test environment shall host all data from Developer Team’s Test & Dev AWS accounts as well as Github related data. Note: there might be a need for certain metrics (e.g. pipeline related) in dev accounts to feed into the production Dynatrace SaaS environment. These will be handled on a case by case basis.

Data cannot be shared across environments.

###	Management Zones

Dynatrace SaaS supports the ability to restrict users to viewing certain datasets, potentially by team or application or other criteria. For instance a support user might want to see all datasets but a developer team might only be interested in their metrics.
This level of segregation within management zones is provided through rules associated with tagging. E.g. a tag associated with a given Lambda OneAgent (e.g. ‘team’) can be used to group Lambdas together. 
