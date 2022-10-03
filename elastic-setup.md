## Configure ElasticSearch

### Create f5 metrics conversion pipeline
```
PUT _ingest/pipeline/f5-metrics-pipeline
{
  "description": "My optional pipeline description",
  "processors": [
      {
        "convert": {
          "field": "MaxCpu",
          "type": "double",
          "ignore_missing": true
        }
      },
      {
        "convert": {
          "field": "AvgMemory",
          "type": "double",
          "ignore_missing": true
        }
      },
      {
        "convert": {
          "field": "counters_pkts_in",
          "type": "double",
          "ignore_missing": true
        }
      },
      {
        "convert": {
          "field": "counters_pkts_out",
          "type": "double",
          "ignore_missing": true
        }
      },
      {
        "rename": {
          "field": "system.hostname",
          "target_field": "hostname",
          "ignore_missing": true
        }
      },
      {
        "convert": {
          "field": "transactions",
          "type": "double",
          "ignore_missing": true
        }
      },
      {
        "convert": {
          "field": "server_concurrent_conns",
          "type": "double",
          "ignore_missing": true
        }
      },
      {
        "convert": {
          "field": "client_concurrent_conns",
          "type": "double",
          "ignore_missing": true
        }
      },
      {
        "convert": {
          "field": "latency",
          "type": "double",
          "ignore_missing": true
        }
      },
      {
        "convert": {
          "field": "RTTMin",
          "type": "double",
          "ignore_missing": true
        }
      },
      {
        "convert": {
          "field": "RTTMax",
          "type": "double",
          "ignore_missing": true
        }
      }
    ]
}
```
### Creates a component template for index settings
```
PUT /_component_template/f5-logs-settings?pretty
{
  "template": {
    "settings": {
      "index.default_pipeline": "f5-metrics-pipeline",
      "index.lifecycle.name": "logs"
    }
  }
}
```
### Creates an index template matching `f5-*`
```
PUT /_index_template/f5-logs-template?pretty
{
  "index_patterns": ["f5-*"],
  "priority": 500,
  "composed_of": ["f5-logs-settings"]
}
```
