terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}

# Réseau commun sinon réseau bridge par défaut 
resource "docker_network" "monitoring" {
  name = "monitoring"
}

# Volumes persistants comme demandé 
resource "docker_volume" "grafana_data" {
  name = "grafana-data"
}

resource "docker_volume" "prometheus_data" {
  name = "prometheus-data"
}

# Mon image ETHexporter 
resource "docker_container" "ethexporter" {
  name  = "ethexporter"
  image = "hunterlong/ethexporter"

  ports {
    internal = 9015
    external = 9015
  }

  env = [
    "GETH=https://sepolia.infura.io/v3/2a4fada943da45a0b232775d1951d0a2"
  ]

  mounts {
    target = "/app/addresses.txt"
    source = abspath("${path.module}/mon_adresse.txt")
    type   = "bind"
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }
}

# Mon prometheus
resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = "prom/prometheus"

  ports {
    internal = 9090
    external = 9090
  }

  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/prometheus"
  }

  mounts {
    target = "/etc/prometheus/prometheus.yml"
    source = abspath("${path.module}/prometheus.yml")
    type   = "bind"
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }
}

# Mon Grafana
resource "docker_container" "grafana" {
  name  = "grafana"
  image = "grafana/grafana"

  env = [
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_SECURITY_ADMIN_PASSWORD=admin" # A mettre en variable ou utiliser sops encrypt 
  ]

  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }

  depends_on = [docker_container.prometheus]

  networks_advanced {
    name = docker_network.monitoring.name
  }

  # Labels Traefik (un bloc par label)
  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.grafana.rule"
    value = "Host(`localhost`)"
  }

  labels {
    label = "traefik.http.routers.grafana.entrypoints"
    value = "websecure"
  }

  labels {
    label = "traefik.http.routers.grafana.tls"
    value = "true"
  }
}



# Mon Traefik je laisse le ports 80 mais possibillité de l'enlevé 
resource "docker_container" "traefik" {
  name  = "traefik"
  image = "traefik:v2.10"

  command = [
    "--api.insecure=true",
    "--providers.docker=true",
    "--providers.file.directory=/etc/traefik/dynamic",
    "--entrypoints.web.address=:80",
    "--entrypoints.websecure.address=:443",
    "--entrypoints.websecure.http.tls=true"
  ]

  ports {
    internal = 80
    external = 80
  }

  ports {
    internal = 443
    external = 443
  }

  ports {
    internal = 8080
    external = 8080
  }

  mounts {
    target = "/var/run/docker.sock"
    source = "/var/run/docker.sock"
    type   = "bind"
  }

  mounts {
    target = "/certs"
    source = abspath("${path.module}/certs")
    type   = "bind"
  }

  mounts {
    target = "/etc/traefik/dynamic/dynamic.yml"
    source = abspath("${path.module}/dynamic.yml")
    type   = "bind"
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }
}
