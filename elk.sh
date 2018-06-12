#!/usr/bin/env bash
set -x

logDirectoryPath="/Users/aravindbargurhiriyannaiah/Downloads/logs"
rootDirectory="/Users/aravindbargurhiriyannaiah/Downloads/elk"

# Start an elasticsearch server and kibana server
# Start a filebeat process to poll a directory having the log files and post its contents directly to elasticsearch.
# We are not using logstash - we are contents directly to elasticsearch.

# Stop containers
echo -e "Stopping all elk containers"
docker stop elasticsearch
docker stop kibana
docker stop filebeat

echo -e "Removing all exited containers"
docker ps -a | grep Exit | cut -d ' ' -f 1 | xargs docker rm

# Pull docker images (Do not pull from docker hub)
echo -e "Pulling elk related images"
docker pull docker.elastic.co/elasticsearch/elasticsearch:6.2.2
docker pull docker.elastic.co/kibana/kibana:6.2.2
docker pull docker.elastic.co/beats/filebeat:6.2.2

mkdir -p "$rootDirectory"/esdata
mkdir -p "$rootDirectory"/filebeat

# Do not change the formatting - yml files are very sensitive to indentation.
cat << EOF > "$rootDirectory"/filebeat/filebeat.yml
# List of prospectors to fetch data.
filebeat.prospectors:
- type: log
  enabled: true
  paths:
    - /usr/share/filebeat/logs/*.log
  # json.keys_under_root: true
  # multiline.pattern: ^\[


output.elasticsearch:
  enabled: true
  hosts: ["http://elasticsearch:9200"]

#================================ Logging ======================================
logging.level: info
logging.selectors: ['*']
EOF

# Start docker containers
echo -e "Start the containers"
docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 -v "$rootDirectory"/esdata:/usr/share/elasticsearch/data docker.elastic.co/elasticsearch/elasticsearch:6.2.2
docker run --name kibana --link elasticsearch:elasticsearch -p 5601:5601 -d docker.elastic.co/kibana/kibana:6.2.2
docker run -d --name filebeat --link elasticsearch:elasticsearch -v "$rootDirectory"/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml -v "$logDirectoryPath":/usr/share/filebeat/logs docker.elastic.co/beats/filebeat:6.2.2 -e

echo -e "See the running containers"
docker ps -a

# -------------- Useful information------------------
# Logstash related commands
# docker pull docker.elastic.co/logstash/logstash:6.2.2
# docker run -d --name logstash -p 5044:5044 --link elasticsearch:elasticsearch -v /Users/aravindbargurhiriyannaiah/Downloads/elk/logstash/pipeline:/usr/share/logstash/pipeline/ docker.elastic.co/logstash/logstash:6.2.2

# How to delete an index
# curl -XDELETE http://localhost:9200/.monitoring\*

# How to see what data exists in elastic search
# localhost:9200/_search?pretty

# How to check if elastic search is running.
# curl -X GET http://localhost:9200