## Configure ElasticSearch


### Create ingest pipeline
```
PUT _ingest/pipeline/f5-avr-pipeline
{
  "description": "ingest pipeline for adding timestamp field to AVR data",
  "processors": [
    {
      "date": {
        "field": "data.EOCTimestamp",
        "formats": [
          "UNIX"
        ],
        "ignore_failure": true
      }
    }
  ]
}
```

### Creates an index template
```
PUT _index_template/f5-avr-index-template
{
  "template": {
    "settings": {
      "index": {
        "default_pipeline": "f5-avr-pipeline"
      }
    },
    "mappings": {
      "_routing": {
        "required": false
      },
      "numeric_detection": true,
      "_source": {
        "excludes": [],
        "includes": [],
        "enabled": true
      },
      "dynamic": true,
      "dynamic_templates": [],
      "date_detection": false,
      "properties": {
        "@timestamp": {
          "type": "date"
        },
        "data.EOCTimestamp": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        },
        "data.errdefs_msgno": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        },
        "data.SlotId": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        },
        "data.POOLPort": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        },
        "data.ResponseCode": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        }
      }
    }
  },
  "index_patterns": [
    "f5avr*"
  ],
  "composed_of": []
}
```