#configure aws provider
provider "aws" {
  region    = var.region
  profile   = "terraform-user"  
}

# create vpc
module "vpc" {
    source                          = "../modules/vpc"  
    region                          = var.region
    project_name                    = var.project_name
    vpc_cidr                        = var.vpc_cidr
    public_subnet_az1_cidr          = var.public_subnet_az1_cidr
    public_subnet_az2_cidr          = var.public_subnet_az2_cidr
    private_app_subnet_az1_cidr     = var.private_app_subnet_az1_cidr
    private_app_subnet_az2_cidr     = var.private_app_subnet_az2_cidr
    private_data_subnet_az1_cidr    = var.private_data_subnet_az1_cidr
    private_data_subnet_az2_cidr    = var.private_data_subnet_az2_cidr
}

# create nat gateway
module "nat_gateway" {
  source                      = "../modules/nat_gateway"
  public_subnet_az1_id        = module.vpc.public_subnet_az1_id
  public_subnet_az2_id        = module.vpc.public_subnet_az2_id
  internet_gateway            = module.vpc.internet_gateway
  vpc_id                      = module.vpc.vpc_id
  private_app_subnet_az1_id   = module.vpc.private_app_subnet_az1_id
  private_data_subnet_az1_id  = module.vpc.private_data_subnet_az1_id
  private_app_subnet_az2_id   = module.vpc.private_app_subnet_az2_id
  private_data_subnet_az2_id  = module.vpc.private_data_subnet_az2_id
}

# create security groups
module "security_groups" {
  source                      = "../modules/security_groups"
  vpc_id                      = module.vpc.vpc_id
}

# create ecs task execution role
module "ecs_task_execution_role" {
  source        = "../modules/ecs_task_execution_role"
  project_name  = module.vpc.project_name
}

# create ssl certificate from ACM
module "acm" {
  source            = "../modules/acm"
  domain_name       = var.domain_name
  alternative_name  = var.alternative_name
}

# create application load balancer
module "alb" {
  source                  = "../modules/alb"
  project_name            = module.vpc.project_name
  alb_security_group_id   = module.security_groups.alb_security_group_id
  public_subnet_az1_id    = module.vpc.public_subnet_az1_id
  public_subnet_az2_id    = module.vpc.public_subnet_az2_id
  vpc_id                  = module.vpc.vpc_id
  certificate_arn         = module.acm.certificate_arn
}

# create ecs service
module "ecs" {
  source                        = "../modules/ecs"
  project_name                  = module.vpc.project_name
  ecs_tasks_execution_role_arn  = module.ecs_task_execution_role.ecs_tasks_execution_role_arn
  container_image               = var.container_image
  region                        = module.vpc.region
  private_app_subnet_az1_id     = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id     = module.vpc.private_app_subnet_az2_id
  ecs_security_group_id         = module.security_groups.ecs_security_group_id
  alb_target_group_arn          = module.alb.alb_target_group_arn
}

# create ecs service
module "asg" {
  source           = "../modules/asg"
  ecs_cluster_name = module.ecs.ecs_cluster_name
  ecs_service_name = module.ecs.ecs_service_name  
}

# create route 53 reccord
module "route53" {
  source        = "../modules/route53"
  domain_name   = module.acm.domain_name
  reccord_name  = var.reccord_name
  alb_dns_name  = module.alb.alb_dns_name
  alb_zone_id   = module.alb.alb_zone_id 
}

output "website_url" {
  value = join ("", ["https://", var.reccord_name, ".", var.domain_name] )
}

