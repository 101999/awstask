provider "aws" {
      region     = "us-west-2"     
}
resource "aws_vpc" "Shivani-vpc1" {                
   cidr_block       = "10.0.0.0/16"   
   instance_tenancy = "default"
 }
 resource "aws_internet_gateway" "Shiv-nat1"{
    vpc_id =  aws_vpc.Shivani-vpc1.id  
 }        
   resource "aws_subnet" "spublic1" {    
   vpc_id =  aws_vpc.Shivani-vpc1.id
   cidr_block = "10.0.0.0/24"        
 } 

 resource "aws_subnet" "spublic2" {  
   vpc_id =  aws_vpc.Shivani-vpc1.id     
   cidr_block = "10.0.1.0/24"
 }
 resource "aws_subnet" "sprivate1" {   
   vpc_id =  aws_vpc.Shivani-vpc1.id
   cidr_block = "10.0.2.0/24"        
 }
 resource "aws_subnet" "sprivate2" {    
   vpc_id =  aws_vpc.Shivani-vpc1.id
   cidr_block = "10.0.3.0/24"   
 }
 resource "aws_eip" "shiv-eip" {
   vpc   = true
 }
 resource "aws_nat_gateway" "shiv1-nat" {
   allocation_id = aws_eip.shiv-eip.id
   subnet_id = aws_subnet.spublic1.id
 }
 resource "aws_route_table" "shiv1-rt1" {    
    vpc_id =  aws_vpc.Shivani-vpc1.id
         route {
    cidr_block = "0.0.0.0/0"               
    gateway_id = aws_internet_gateway.Shiv-nat1.id
     }
 }
 resource "aws_route_table" "shiv1-rt2" {    
   vpc_id = aws_vpc.Shivani-vpc1.id
   route {
   cidr_block = "0.0.0.0/0"             
   nat_gateway_id = aws_nat_gateway.shiv1-nat.id
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
  