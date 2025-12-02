terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

variable "site_name" {
  description = "The name of the site to deploy"
  type        = string
}

resource "kubernetes_namespace" "site_ns" {
  metadata {
    name = var.site_name
  }
}

resource "kubernetes_deployment" "app_deployment" {
  metadata {
    name      = "${var.site_name}-deployment"
    namespace = kubernetes_namespace.site_ns.metadata[0].name
    labels = {
      app = var.site_name
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.site_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.site_name
        }
      }

      spec {
        container {
          image = "hashicorp/http-echo"
          name  = "http-echo"
          args  = ["-text=hello ${var.site_name}", "-listen=:5678"]

          port {
            container_port = 5678
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app_service" {
  metadata {
    name      = "${var.site_name}-service"
    namespace = kubernetes_namespace.site_ns.metadata[0].name
  }

  spec {
    selector = {
      app = var.site_name
    }

    port {
      port        = 80    
      target_port = 5678  
    }

    type = "NodePort"
  }
}