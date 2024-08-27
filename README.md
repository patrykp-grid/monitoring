## Monitoring Part

### Docker image rebuild to run with JMX

```dockerfile
COPY jmx_prometheus_javaagent-0.16.1.jar /app/jmx_prometheus_javaagent.jar
COPY config.yml /app/config.yml

ENTRYPOINT ["java", "-javaagent:/app/jmx_prometheus_javaagent.jar=1234:/app/config.yml", "-jar", "/app/app.jar"]
```

Run docker container:

```bash
docker run -d --name jmx-exporter --network spring-petclinic_default -p 1234:1234 spring-petclinic-jmx
```

### Validate that exporter endpoint is accessible

![JMX exporter](exporter-endpoint.png)

### Run Prometheus Docker container scrapping JMX metrics

```bash
docker run -d --name prometheus --network spring-petclinic_default -p 9090:9090 -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
```

### Validate that Prometheus gathers data by running the following queries

![Prometheus](prometheus-query.png)

### Run Grafana container

```bash
docker run -d --name grafana --network spring-petclinic_default -p 3000:3000 grafana/grafana
```

### Create Prometheus data source in the user interface

![Prometheus data source](prometheus-datasource.png)

### Import dashboard with its id - 10519

![Import dashboard](dashboard.png)

## Logging Part 

### Run spring-boot binary locally

```bash
java -jar spring-petclinic-3.3.0-SNAPSHOT.jar > spring-petclinic-3.3.0-SNAPSHOT.log
```

### Run Loki with the default configuration

```bash
docker run -d --name=loki --network spring-petclinic_default -p 3100:3100 grafana/loki:2.8.1
```

### Prepare Promtail config to read logs from <app>.log and send logs to Loki, then run Promtail

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 9095

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: 'spring-boot-logs'
    static_configs:
      - targets:
          - localhost
        labels:
          job: spring-boot
          __path__: spring-petclinic-3.3.0-SNAPSHOT.log
```

```bash
docker run -d --name=promtail  --network spring-petclinic_default  -v ${ABSOLUTE_PATH}/promtail-config.yml:/etc/promtail/promtail-config.yml  -v ${ABSOLUTE_PATH}/spring-petclinic-3.3.0-SNAPSHOT.log:/var/log/spring-petclinic.log  grafana/promtail:2.8.1 -config.file=/etc/promtail/promtail-config.yml
```

### Log in to grafana and add Loki as a data source

![Loki data source](loki-datasource.png)






