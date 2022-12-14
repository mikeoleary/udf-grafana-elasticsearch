# Troubleshooting Tips

## ElasticSearch commands

```curl -k -u elastic:F5demonet! https://localhost:9200/_cat/allocation?v``` - _this command will give you the disk space used by the indices in ElasticSearch, as well as the disk used. This can be handy if you are running out of disk, but wondering if ElasticSearch is taking up the disk space, or something else._

```GET /_cat/indices/``` - _this will list indices_

```DELETE /_all``` - _be careful with this, it can system indexes also_

## Linux commands
```sudo du -cha --max-depth=1 / | grep -E "M|G"``` - _this command will list which directories are using the most space. Helpful if you need to perform some disk clean up. After running this command at the root directory /, edit the command and run to see what is taking up space in your biggest directories. For example, if /var was your biggest directory, you could run_ ```sudo du -cha --max-depth=1 / | grep -E "M|G"```

## Log locations and other locations on disk to be aware of

```/var/log/elasticsearch/elasticsearch.log```  
```/var/log/logstash/logstash-plain.log```
```/var/log/kibana/kibana.log```  
```/var/lib/docker/containers``` - _in my experience this directory is filled up quickly if you run the demo containers and a script to continuously send web requests to them._

````