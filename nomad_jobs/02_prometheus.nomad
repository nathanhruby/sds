job "prometheus" {
  datacenters = ["sds"]
  type = "service"

  group "monitoring" {
    count = 1

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "prometheus" {
      template {
        change_mode = "noop"
        destination = "local/alerts.yml"
        data = <<EOH
---
groups:
- name: prometheus_alerts
  rules:
  - alert: Webserver down
    expr: absent(up{job="webserver"})
    for: 10s
    labels:
      severity: critical
    annotations:
      description: "Our webserver is down."
EOH
      }

      template {
        change_mode = "noop"
        destination = "local/prometheus.yml"
        data = <<EOH
---
global:
  scrape_interval:     5s
  evaluation_interval: 5s

alerting:
  alertmanagers:
  - consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['alertmanager']

rule_files:
  - "alerts.yml"

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
      # - targets: ['{{ env "NOMAD_IP_prometheus_ui" }}:{{ env "NOMAD_HOST_PORT_prometheus_ui" }}']

  - job_name: 'consul_metrics'
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['consul']
    relabel_configs:
    # consul registers the rpc port, but we want the http port, which we expose to the public port via config
    - source_labels: ['__address__']
      action: replace
      regex: '([^:]+)(?::\d+)?'
      replacement: ${1}:8500
      target_label: __address__
    scrape_interval: 5s
    metrics_path: /v1/agent/metrics
    params:
      format: ['prometheus']

  - job_name: 'nomad_metrics'
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['nomad-client', 'nomad']
    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep
    scrape_interval: 5s
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']

  - job_name: 'node_metrics'
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['node-exporter']
    relabel_configs:
    - source_labels: ['__address__']
      action: replace
      regex: '([^:]+)(?::\d+)?'
      replacement: ${1}:9100
      target_label: __address__
    scrape_interval: 5s
    metrics_path: /metrics

  - job_name: 'portworx_metrics'
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['portworx']
    relabel_configs:
    - source_labels: ['__address__']
      action: replace
      regex: '([^:]+)(?::\d+)?'
      replacement: ${1}:9001
      target_label: __address__
    scrape_interval: 5s
    metrics_path: /metrics

EOH
      }
      driver = "docker"
      config {
        image = "prom/prometheus:latest"
        mounts = [
            {
                type = "bind"
                target = "/etc/prometheus/prometheus.yml"
                source = "local/prometheus.yml"
            },
            {
                type = "bind"
                target = "/etc/prometheus/alerts.yml"
                source = "local/alerts.yml"
            },
            {
                type = "volume"
                target = "/prometheus"
                source =  "name=prometheus,size=5G,repl=1"
                volume_options {
                    driver_config {
                        name = "pxd"
                    }
                }
            }
        ]
        port_map {
          prometheus_ui = 9090
        }
      }
      resources {
        network {
          mbits = 10
          port "prometheus_ui" {}
        }
      }
      service {
        name = "prometheus"
        tags = ["urlprefix-/"]
        port = "prometheus_ui"
        check {
          name     = "prometheus_ui port alive"
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }

  group "alerting" {
    count = 1
    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }
    ephemeral_disk {
      size = 300
    }

    task "alertmanager" {
      driver = "docker"
      config {
        image = "prom/alertmanager:latest"
        port_map {
          alertmanager_ui = 9093
        }
      }
      resources {
        network {
          mbits = 10
          port "alertmanager_ui" {}
        }
      }
      service {
        name = "alertmanager"
        tags = ["urlprefix-/alertmanager strip=/alertmanager"]
        port = "alertmanager_ui"
        check {
          name     = "alertmanager_ui port alive"
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
