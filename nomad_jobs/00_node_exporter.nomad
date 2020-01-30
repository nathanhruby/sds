job "node-exporter" {
  datacenters = ["sds"]
  type = "system"

  group "export" {
    restart {
        attempts = 3
        delay    = "20s"
        mode     = "delay"
    }

    task "node-exporter" {
      artifact {
          source = "https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz"
          options {
              checksum = "sha256:b2503fd932f85f4e5baf161268854bf5d22001869b84f00fd2d1f57b51b72424"
          }
      }
      driver = "raw_exec"
      config {
          command = "local/node_exporter-0.18.1.linux-amd64/node_exporter"
          args = ["--web.listen-address=:9100"]
      }


      service {
        name = "node-exporter"
        tags = ["metrics"]
        check {
            port = "node_exporter"
            type = "http"
            path = "/"
            interval = "10s"
            timeout = "2s"
        }
      }

      resources {
        cpu    = 50
        memory = 100
        network {
          port "node_exporter" {
            static = "9100" 
          }
        }
      }    
    }
  }
}

