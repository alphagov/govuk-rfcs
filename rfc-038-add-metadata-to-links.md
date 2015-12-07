## Problem

The links hash for content items do not store information about the relationship between the two content items. Examples of information that are lost include:

- Topical Events have featured documents which are explicitly ordered.
- Documents may be published by organisations. Some are marked as "lead" organisations and some are marked as "supporting". The default image for a document is generally taken from the first lead organisation, but this could be inferred as being the "primary" organisation.
- Documents may be published by Governments. It's important to be able to distinguish between the Government that published a document, and a Government that updated it.
- Document Collections are an explicitly ordered, explicitly grouped collection of documents. The information about what order within which group each document is in is required by the rendering app.
- The Person that a document is related to should have their role at the time of publishing linked to them. This could be solved however by linking to a Role Appointment instead.

These problems could be solved by storing the related content ids in the details hash instead of the links hash. However, this would mean the inverse relationships couldn't be found using the `/incoming-links` endpoints, something that is required for Topical Events and Document Collections.

The ordering problem is a recent addition since the from a json blob in the content item into separate `link_sets`&nbsp;and `links` tables, which means that ordering of the links arrays is no longer preserved. The fact that the API and schemas use arrays to represent links implies that the ordering will be preserved, which is confusing.&nbsp;

## Proposal

Change the API and schema to allow metadata for links, represented as a hash. This would be a decoration of the link itself which describes the relationship between the two items.

A simple example document:

```
{ "base_path": "/government/news/foobar", "content_id": "47d3205a-36df-410f-be25-7efac60c4952", "links": { "organisations": { "cf9cebf1-6fa6-48c3-8773-51d54cac812d": { "primary": true, "relationship": "lead", }, "c11f9ad7-807b-4749-a227-de7aaf0207fb": { "primary": false, "relationship": "lead", }, "12a63d3d-9360-46b7-ba1f-d1904305e5fa": { "primary": false, "relationship": "supporting" } }, "topical_events": { "a7f438bd-2454-47d1-ac3e-8b253fbdd0c8": {} } }}
```

Its related Topical Event would have its documents stored along with their explicit order:

```
{ "base_path": "/government/topical-events/autumn-statement-and-spending-review-2015", "content_id": "a7f438bd-2454-47d1-ac3e-8b253fbdd0c8", "links": { "documents": { "47d3205a-36df-410f-be25-7efac60c4952": { "ordering": 1 }, "c058d693-4b4c-415c-8066-2273abef3e36": { "ordering": 2 } } }}
```

Representing a links collection as a hash also removes the implication that the ordering of elements will be retained.&nbsp;The metadata can be stored in the Publishing API database in a json field on the&nbsp;`links`&nbsp;table record.&nbsp;

We can support this within content schema using the [patternProperties](http://spacetelescope.github.io/understanding-json-schema/reference/object.html#patternproperties) property, which accepts a regular expression in order to define dynamic properties. Here is a (pseudo-)snippet from how we'd define the example "organisations" links from above:

```
{
  "links": {
    "type": "object",
    "properties": {
      "organisations": {
        "type": "object",
```

```
        "additionalProperties": false,
```

```
"patternProperties": {
          "^[a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$": {
            "type": "object",
            "required": [
              "primary",
              "relationship"
            ],
            "properties": {
              "primary": {
                "type": "boolean"
              },
              "relationship": {
                "enum": [
                  "lead",
                  "supporting"
                ],
              }
            }
          }
        }
      }
    }
  }
}
```

Using JSON Schema to define the metadata that is available for each link type allows us to be strict about the format, and prevent metadata becoming a dumping ground of unorganised information.

&nbsp;

&nbsp;

&nbsp;

