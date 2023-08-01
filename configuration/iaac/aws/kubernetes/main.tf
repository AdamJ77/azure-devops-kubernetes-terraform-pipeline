# aws --version
# aws eks --region us-east-1 update-kubeconfig --name in28minutes-cluster
# Uses default VPC and Subnet. Create Your Own VPC and Private Subnets for Prod Usage.
# terraform-backend-state-in28minutes-123
# AKIA4AHVNOD7OOO6T4KI

# konfiguracja backendu w s3
terraform {
  backend "s3" {
    bucket = "mybucket"       # Will be overridden from build
    key    = "path/to/my/key" # Will be overridden from build
    region = "us-east-1"
  }
}

resource "aws_default_vpc" "default" {

}

data "aws_subnet_ids" "subnets" {
  vpc_id = aws_default_vpc.default.id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  version                = "~> 2.12"
}

module "in28minutes-cluster" {                      # korzystamy z modułu by stworzyć klaster k8s
  source          = "terraform-aws-modules/eks/aws" # moduł udostępniony przez samego Terraforma do stworzenia EKS
  cluster_name    = "project2-eks-cluster"
  cluster_version = "1.27"
  subnets         = ["subnet-0945d29a182b2c243", "subnet-0c4c0437af075b65e"] # wersja statyczna z naszymi podsieciami będącymi w domyślnym VPC
  # subnets = data.aws_subnet_ids.subnets.ids  # wersja z dynamicznym wyborem podsieci
  vpc_id = aws_default_vpc.default.id # ustawiamy w jakim VPC ma powstać klaster [w środowisku produkcyjnym normalnie byśmy skorzystali z customowego VPC]

  #vpc_id         = "vpc-1234556abcdef"

  # informacje o nodach w klastrze
  node_groups = [
    {
      instance_type    = "t2.micro"
      max_capacity     = 5
      desired_capacity = 3
      min_capacity     = 3
    }
  ]
}

# data providery
data "aws_eks_cluster" "cluster" {
  name = module.in28minutes-cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.in28minutes-cluster.cluster_id
}


# We will use ServiceAccount to connect to K8S Cluster in CI/CD mode
# ServiceAccount needs permissions to create deployments and services in default namespace
# Ustawiamy pozwolenia dla default service account by miał dostęp do deployments i services
# chcemy stworzyc pipeline cicd za pomocą którego możemy tworzyć nowe deploymenty i deployować nowe aplikacje
resource "kubernetes_cluster_role_binding" "example" {
  metadata {
    name = "fabric8-rbac"
  }

  # w środowisku produkcyjnym możemy dać niższe pozwolenia, niekoniecznie admina
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }
}

# Needed to set the default region
provider "aws" {
  region = "us-east-1"
}
