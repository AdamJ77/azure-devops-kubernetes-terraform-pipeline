# wszystkie resource stworzone dla azure, muszą należeć do jakiejś resource group -> zatem musimy ją najpierw stworzyć
resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resource_group}_${var.environment}"
  location = var.location
}

# azurerm -> azure resource manager
provider "azurerm" {
  //version = "~>2.0.0"
  features {}
}

# pozwala na zarządzania klastrem kubernetes cluster w azure (czyli AKS - Azure Kubernetes Service)
# pamiętamy by związać go z konkretną resource group (którą stworzyliśmy wcześniej)
resource "azurerm_kubernetes_cluster" "terraform-k8s" {
  name                = "${var.cluster_name}_${var.environment}"       # nazwa klastra
  location            = azurerm_resource_group.resource_group.location # dajemy tą samą lokalizację do resource group do którego należy
  resource_group_name = azurerm_resource_group.resource_group.name     # przypisujemy do resource grupy
  dns_prefix          = var.dns_prefix                                 # obowiązkowe

  linux_profile { # tworzymy admina
    admin_username = "ubuntu"

    ssh_key {
      key_data = file(var.ssh_public_key) # aby móc się łączyć poprzez ssh do tego klastra?
    }
  }

  default_node_pool {            # node w kubernetes (ile zasobów obliczeniowych w klastrze)
    name       = "agentpool"     # nazwa noda
    node_count = var.node_count  # ustawiamy na 3 instancje
    vm_size    = "standard_b2ms" # konkretna konfiguracja maszyny wirtualnej
    # vm_size         = "standard_d2as_v5"      CHANGE IF AN ERROR ARISES 
  }

  # potrzebne do komunikacji z Azure (czyli też z klastrem)
  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  tags = {
    Environment = var.environment
  }
}

# Azurerm backend
# używamy specjalnego backendu w azure by móc przechowywać tam pliki .tfstate,
# żeby inni mieli do nich dostęp, żeby nie było wyścigu, itp.
terraform {
  backend "azurerm" {
    # tworzymy storage account, za pomocą którego tworzymy storage account container
    # który będzie przechowywał pliki .tfstate

    # storage_account_name="<<storage_account_name>>" #OVERRIDE in TERRAFORM init
    # access_key="<<storage_account_key>>" #OVERRIDE in TERRAFORM init
    # key="<<env_name.k8s.tfstate>>" #OVERRIDE in TERRAFORM init
    # container_name="<<storage_account_container_name>>" #OVERRIDE in TERRAFORM init
  }
}
