terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "> 2.16.0"
    }
  }
  required_version = "> 1.3.4"
  backend "pg" {
    conn_str = "postgres://terraform:terraform@192.168.1.250/tfbdb?sslmode=disable"

  }

}

provider "kubernetes" {
  config_path = "~/.kube/config"

}
data "kubernetes_secret" "mysecret" {
  metadata {
    name      = "wppass"
    namespace = data.kubernetes_namespace.webapp.metadata.0.name
  }

}

data "kubernetes_secret" "wpsettings" {
  metadata {
    name      = "wpsettings"
    namespace = data.kubernetes_namespace.webapp.metadata.0.name
  }
}
data "kubernetes_namespace" "webapp" {
  metadata {
    name = "webapp"
  }

}
data "kubernetes_persistent_volume_claim" "pvcdb" {
  metadata {
    name      = "pvcdb"
    namespace = data.kubernetes_namespace.webapp.metadata.0.name
  }
}

data "kubernetes_persistent_volume_claim" "pvcwp" {
  metadata {
    name      = "pvcwp"
    namespace = data.kubernetes_namespace.webapp.metadata.0.name
  }

}

resource "kubernetes_deployment" "mariadb" {
  metadata {
    name      = "db-webapp"
    namespace = data.kubernetes_namespace.webapp.metadata.0.name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "dbwebapp"
      }
    }
    template {
      metadata {
        labels = {
          app = "dbwebapp"
        }
      }
      spec {
        container {
          name  = "contdb"
          image = "mariadb:10.5"
          port {
            container_port = 3306
          }
          env_from {
            secret_ref {
              name = data.kubernetes_secret.mysecret.metadata.0.name
            }
          }
          volume_mount {
            name       = "dbvol"
            mount_path = "/var/lib/mysql"
          }

        }
        volume {
          name = "dbvol"
          persistent_volume_claim {
            claim_name = data.kubernetes_persistent_volume_claim.pvcdb.metadata.0.name
          }
        }
      }

    }

  }
}

resource "kubernetes_service" "svcdb" {
  metadata {
    name      = "svcdb"
    namespace = data.kubernetes_namespace.webapp.metadata.0.name
  }
  spec {
    selector = {
          app = kubernetes_deployment.mariadb.spec.0.template.0.metadata.0.labels.app
    }
    type = "ClusterIP"
    port {
      port        = 3306
      target_port = 3306
      protocol    = "TCP"
    }

  }
}

resource "kubernetes_deployment" "wordpress" {
  metadata {
    name      = "wordpress-webapp"
    namespace = data.kubernetes_namespace.webapp.metadata.0.name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        webapp = "wordpress"
      }
    }
    template {
      metadata {
        labels = {
          webapp = "wordpress"
        }
      }
      spec {
        volume {
          name = "wpvol"
          persistent_volume_claim {
            claim_name = data.kubernetes_persistent_volume_claim.pvcwp.metadata.0.name
          }
        }
          container {
            name  = "contwordpress"
            image = "wordpress"
            
            env_from {
              secret_ref {
                name = data.kubernetes_secret.wpsettings.metadata.0.name
              }
            }
            volume_mount {
              name       = "wpvol"
              mount_path = "/var/www/html"
            }
            port {
              container_port = 80
            }

          }
        }
      }
    }
  }



resource "kubernetes_service" "svcwordpress" {
  metadata {
    name      = "svcwordpress"
    namespace = data.kubernetes_namespace.webapp.metadata.0.name
  }
  spec {
    selector = {
      webapp= kubernetes_deployment.wordpress.spec.0.template.0.metadata.0.labels.webapp

    }
  
  type = "NodePort"
  port {
    port        = 80
    target_port = 80
    node_port    = 32088
  }

}
}
