terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.70.0" # Фиксируем версию провайдера
    }
  }
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "buckex"
    region     = "ru-central1-a"
    key        = "./terraform.tfstate"
    access_key = "HFZO_4xMjYN59VdLrQac"
    secret_key = "mapZRHYRGN9rYWdVEQIPEIVXNwohXU73QcYQ5Xs1"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

# Настраиваем the Yandex.Cloud provider
provider "yandex" {
  token     = "AQAAAAAACjJSAATuwf9jq5pJzkRQnh-4L68UKu0"
  cloud_id  = "b1ge5d39qn1okmafikgb"
  folder_id = "b1g38f6qroeviem1bhv2"
  zone      = "ru-central1-a"
}

#Создание сети
resource "yandex_vpc_network" "network" {
  name = "network"
}
#Cоздание подсетей
resource "yandex_vpc_subnet" "nw1" {
  name           = "nw1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.2.0.0/16"]
}

resource "yandex_vpc_subnet" "nw2" {
  name           = "nw2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.3.0.0/16"]
}
#Создание группы для балансировки
resource "yandex_lb_target_group" "srvgroup" {
  name      = "srvgroup"
  region_id = "ru-central1"

  target {
    subnet_id = yandex_vpc_subnet.nw1.id
    address   = module.vm1.internal_ip_address_vm
  }

  target {
    subnet_id = yandex_vpc_subnet.nw2.id
    address   = module.vm2.internal_ip_address_vm
  }
}
#Создание балансировщика
resource "yandex_lb_network_load_balancer" "bal" {
  name = "bal"

  listener {
    name = "my-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.srvgroup.id

    healthcheck {
      name = "http"
      http_options {
        port = 80
      }
    }
  }
}

module "vm1" {
  source                = "./modules/instance/"
  instance_family_image = "lemp"
  vpc_subnet_id         = yandex_vpc_subnet.nw1.id
  instance_zone         = "ru-central1-a"
}

module "vm2" {
  source = "./modules/instance/"
  #instance_family_image = "lamp" #Оно ведь задано по дефолту?
  vpc_subnet_id = yandex_vpc_subnet.nw2.id
  instance_zone = "ru-central1-b"
}
