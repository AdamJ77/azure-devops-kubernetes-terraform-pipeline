# Uses default VPC and Subnet. Create Your Own VPC and Private Subnets for Prod Usage.


# konfiguracja backendu w s3
terraform {
  backend "s3" {
    bucket = "mybucket"       # Te wartości zostaną i tak nadpisane przez Azure Devops
    key    = "path/to/my/key" # Te wartości zostaną i tak nadpisane przez Azure Devops
    region = "us-east-1"
  }
}

resource "aws_default_vpc" "default" {

}

data "aws_subnets" "subnet_ids" {
  filter { # należy zdefiniować z jakiego VPC mają pochodzić podsieci (bierzemy z VPC domyślnego)
    name   = "vpc-id"
    values = [aws_default_vpc.default_vpc_value.id]
  }
}

provider "kubernetes" {
  //>>Uncomment this section once EKS is created - Start
  # host                   = data.aws_eks_cluster.cluster.endpoint
  # cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  # token                  = data.aws_eks_cluster_auth.cluster.token
  # version                = "~> 2.12"
  //>>Uncomment this section once EKS is created - End
}

module "in28minutes-cluster" {                      # korzystamy z modułu by stworzyć klaster k8s
  source          = "terraform-aws-modules/eks/aws" # moduł udostępniony przez samego Terraforma do stworzenia EKS
  cluster_name    = "project2-eks-cluster"
  cluster_version = "1.27"
  subnet_ids      = ["subnet-0945d29a182b2c243", "subnet-0c4c0437af075b65e"] # wersja statyczna z naszymi podsieciami będącymi w domyślnym VPC, # Donot choose subnet from us-east-1e
  # subnet_ids = data.aws_subnets.subnet_ids.ids  # wersja z dynamicznym wyborem podsieci
  vpc_id = aws_default_vpc.default.id # ustawiamy w jakim VPC ma powstać klaster [w środowisku produkcyjnym normalnie byśmy skorzystali z customowego VPC]

  #vpc_id         = "vpc-1234556abcdef"

  cluster_endpoint_public_access = true # to allow connection to the api server

  # informacje o nodach w klastrze | EKS Managed Node Group(s)
  # Jest to sposób na dostarczanie i zarządzanie worker nodes w klastrze EKS.
  # Node group - 1 lub więcej instancji EC2, które są deployed na EC2 Auto Scalling

  eks_managed_node_group_defaults = { # domyślna konifugracja nodami (użyta zostanie jeśli nie będzie nadpisana przez eks_managed_node_groups)
    instance_types = ["t2.small", "t2.medium"]
  }

  eks_managed_node_groups = {
    # podział na blue i green oznacza prawdopodobnie dwa środowiska
    blue = {} # nie ma zdefiniowanego, a zatem będzie użyta domyślna konfiguracja
    green = {
      min_size     = 1  # minimalna liczba nodów jaka musi być ciągle
      max_size     = 10 # maksymalna liczba nodów jaka może być dodana do node groupa
      desired_size = 1

      instance_types = ["t2.micro"]
    }
  }
}

//>>Uncomment this section once EKS is created - Start

# data providery
# data "aws_eks_cluster" "cluster" {
#   name = module.in28minutes-cluster.cluster_id
# }

# data "aws_eks_cluster_auth" "cluster" {
#   name = module.in28minutes-cluster.cluster_id
# }



# # We will use ServiceAccount to connect to K8S Cluster in CI/CD mode
# # ServiceAccount needs permissions to create deployments and services in default namespace
# # Ustawiamy pozwolenia dla default service account by miał dostęp do deployments i services
# # chcemy stworzyc pipeline cicd za pomocą którego możemy tworzyć nowe deploymenty i deployować nowe aplikacje
# resource "kubernetes_cluster_role_binding" "example" {
#   metadata {
#     name = "fabric8-rbac"
#   }

#   # w środowisku produkcyjnym możemy dać niższe pozwolenia, niekoniecznie admina
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#   }
#   subject {
#     kind      = "ServiceAccount"
#     name      = "default"
#     namespace = "default"
#   }
# }

//>>Uncomment this section once EKS is created - End

# Needed to set the default region
provider "aws" {
  region = "us-east-1"
}
