provider "aws" {
   region     = "us-east-1"     
}

resource "aws_vpc" "Shivani-vpc1" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Shivani-vpc"
  }
}

 resource "aws_internet_gateway" "Shiv-nat1"{
    vpc_id =  aws_vpc.Shivani-vpc1.id

    tags = {
    Name = "Shiv-nat"
  }  
 }    

   resource "aws_subnet" "spublic1" {    
   vpc_id =  aws_vpc.Shivani-vpc1.id
   cidr_block= var.public_subnet1_cidr_block  
   availability_zone = var.availability_zone_2 

   tags = {
    Name = "shivpublic1"
  }
 } 

 resource "aws_subnet" "spublic2" {  
   vpc_id =  aws_vpc.Shivani-vpc1.id     
   cidr_block = var.public_subnet2_cidr_block
   availability_zone = var.availability_zone_1

   tags = {
    Name = "shivpublic2"
  }
 }

 resource "aws_subnet" "sprivate1" {  
   vpc_id =  aws_vpc.Shivani-vpc1.id
   cidr_block = var.private_subnet1_cidr_block 
   availability_zone = var.availability_zone_2

   tags = {
    Name = "shivprivate1"
  }
 } 
 
 resource "aws_subnet" "sprivate2" {   
   vpc_id =  aws_vpc.Shivani-vpc1.id
   cidr_block = var.private_subnet2_cidr_block
  availability_zone = var.availability_zone_1

  tags = {
    Name = "shivprivate2"
  }
 } 

 resource "aws_eip" "shiv-eip" {
   vpc   = true

   tags = {
    Name = "shiv-eip1"
  }
 }

 resource "aws_nat_gateway" "shiv1-nat" {
   allocation_id = aws_eip.shiv-eip.id
   subnet_id = aws_subnet.spublic1.id

   tags = {
    Name = "shiv-nat"
  }
 }

 data "aws_iam_role" "iam-shiv" {
  name = "codedeployforECS-BG"
}

 resource "aws_route_table" "shiv1-rt1" {    
    vpc_id =  aws_vpc.Shivani-vpc1.id
         route {
    cidr_block = var.route_cidr_block               
    gateway_id = aws_internet_gateway.Shiv-nat1.id
     }
     tags = {
    Name = "shiv-rt1"
  }
 }

 resource "aws_route_table" "shiv1-rt2" {  
   vpc_id = aws_vpc.Shivani-vpc1.id
   route {
   cidr_block = var.route_cidr_block           
   nat_gateway_id = aws_nat_gateway.shiv1-nat.id
   }
   tags = {
    Name = "shiv-rt2"
  }
 }

  resource "aws_route_table_association" "PublicRTassociation1" {
    subnet_id = aws_subnet.spublic1.id
    route_table_id = aws_route_table.shiv1-rt1.id
 }

 resource "aws_route_table_association" "PublicRTassociation2" {
    subnet_id = aws_subnet.sprivate1.id
    route_table_id = aws_route_table.shiv1-rt2.id
 }

 resource "aws_security_group" "shiv-sec" {
  vpc_id      = aws_vpc.Shivani-vpc1.id

tags = {
    Name = "shiv-sec1"
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [var.sec_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.sec_cidr_block]
  } 
 }

 resource "aws_lb" "shiv-lb" {
  name = "shiv-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.shiv-sec.id]
  subnets            = [aws_subnet.spublic1.id , aws_subnet.spublic2.id]

  enable_deletion_protection = false
}
output "ip" {
  value = aws_lb.shiv-lb.dns_name
}
resource "aws_lb_listener" "shiv_lb_listener_1" {  
  load_balancer_arn =  aws_lb.shiv-lb.arn
  port              =  "80"  
  protocol          = "HTTP"

  default_action { 
  type = "forward"
  target_group_arn = aws_lb_target_group.shiv_target_group_1.arn
  }
  }
resource "aws_lb_listener" "shiv_lb_listener_2" {  
  load_balancer_arn =  aws_lb.shiv-lb.arn
  port              =  "8080"  
  protocol          = "HTTP"

  default_action { 
  type = "forward"
  target_group_arn = aws_lb_target_group.shiv_target_group_2.arn
  }
  }
  
resource "aws_lb_target_group" "shiv_target_group_1"{
  name = "shiv-target-group-1"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.Shivani-vpc1.id  
 }
resource "aws_lb_target_group" "shiv_target_group_2"{
  name = "shiv-target-group-2"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.Shivani-vpc1.id  
 }


 /* resource "aws_lb_target_group_attachment" "shiv_tg_attachment" {
  target_group_arn = aws_lb_target_group.shiv_target_group.arn
  target_id = aws_lb.shiv-lb.id
  port = "80"
 } */

resource "aws_ecr_repository" "ecr" {
  name                 = "shivani-1"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
 }
}
resource "aws_ecr_repository_policy" "demo-repo-policy" {
  repository = "shiv10"
  policy  =<<EOF
  {
    "Version": "2008-10-17",
    "Statement": [
     {
        "Sid": "adds full ecr access to the demo repository",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:*",
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
    ]
   }
  ]
 }
 EOF
}

resource "aws_ecs_cluster" "shiv_cluster" {
 name = "shiv_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
resource "aws_ecs_task_definition" "Shiv_Taskdef" {
  family = "ServiceforFargate1"
  requires_compatibilities =  ["FARGATE"]
  cpu = "1024"
  memory =  "2048"
  network_mode =  "awsvpc"
  execution_role_arn  = data.aws_iam_role.iam-shiv.arn

   container_definitions = file("./ServiceforFargate.json")

  #jsonencode([
    #{
      #name      = "first"
      #image     = "service-first"
      #cpu       = 10
      #memory    = 512
    #  essential = true
     # portMappings = [
      #  {
       #   containerPort = 8080
        #  hostPort      = 8080
        #}
     # ])#
    #},
   }
   

resource "aws_security_group" "shiv-sec2" {
  vpc_id      = aws_vpc.Shivani-vpc1.id

tags = {
    Name = "shiv-sec2"
  }

  ingress {
    description      = "TLS from VPC"
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = [var.sec_cidr_block]
    security_groups  = [aws_security_group.shiv-sec.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.sec_cidr_block]
  } 
}
resource "aws_ecs_service" "shiv-ecs-service" {
  name = "shiv-ecs-service"
  cluster              = aws_ecs_cluster.shiv_cluster.id
  task_definition      = aws_ecs_task_definition.Shiv_Taskdef.id
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 2
  force_new_deployment = true

  network_configuration {
    subnets          = [aws_subnet.sprivate1.id , aws_subnet.sprivate2.id ]
    assign_public_ip = true
    security_groups = [aws_security_group.shiv-sec2.id]
  }

load_balancer{
  target_group_arn = aws_lb_target_group.shiv_target_group_1.arn
  container_name = "shivcontainerfargate"
  container_port = 80
}
}
resource "aws_codedeploy_app" "codedeploy_shiv" {
  compute_platform = "ECS"
  name             = "codedeploy-ss"
  }

  resource "aws_codedeploy_deployment_group" "codedeployment_shiv" {
  app_name               = "aws_codedeploy_app.codedeploy_shiv.name"
  deployment_group_name  = "codedeployment-shiv"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = data.aws_iam_role.iam-shiv.arn
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  terminate_blue_instances_on_deployment_success {
    action = "TERMINATE"
    termination_wait_time_in_minutes = 5
    }
  }
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
  ecs_service {
    cluster_name = aws_ecs_cluster.shiv_cluster.name
    service_name = aws_ecs_service.shiv-ecs-service.name
  }
  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.shiv_lb_listener_1.arn]
      }
      target_group {
        name = "aws_lb_target_group.shiv_target_group_1.name"
      }
      target_group {
        name = "aws_lb_target_group.shiv_target_group_2.name"
      }
      test_traffic_route {
        listener_arns = [aws_lb_listener.shiv_lb_listener_2.arn]
      }
    }
  }
}

resource "aws_route53_zone" "shivani" {
  name = "shivani.tk"
}
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.shivani.zone_id
  name    = "shivani.tk"
  type    = "A"

  alias {
  name                   = aws_lb.shiv-lb.dns_name
 zone_id                = aws_lb.shiv-lb.zone_id
 evaluate_target_health = true
}
}

