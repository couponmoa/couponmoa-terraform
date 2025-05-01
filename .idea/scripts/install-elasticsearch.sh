 #!/bin/bash
 apt update
 apt install -y openjdk-17-jdk wget apt-transport-https
 wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
 echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" > /etc/apt/sources.list.d/elastic-8.x.list
 apt update && apt install -y elasticsearch
 sed -i 's/#network.host: .*/network.host: 0.0.0.0/' /etc/elasticsearch/elasticsearch.yml
 echo "discovery.type: single-node" >> /etc/elasticsearch/elasticsearch.yml
 systemctl enable elasticsearch
 systemctl start elasticsearch