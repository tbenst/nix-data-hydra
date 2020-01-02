let
  region = "us-west-2";
  accessKeyId = "d-lab"; # symbolic name looked up in ~/.ec2-keys or a ~/.aws/credentials profile name
  # We must declare an AWS Subnet for each Availability Zone
  # because Subnets cannot span AZs.
  subnets = [
    { name = "nixops-vpc-subnet-a"; cidr = "10.0.0.0/19"; zone = "${region}a"; }
    { name = "nixops-vpc-subnet-b"; cidr = "10.0.32.0/19"; zone = "${region}b"; }
    { name = "nixops-vpc-subnet-c"; cidr = "10.0.64.0/19"; zone = "${region}c"; }
    { name = "nixops-vpc-subnet-d"; cidr = "10.0.96.0/19"; zone = "${region}d"; }
  ];
  domain = "hydra.tylerbenster.com";
  ec2 = { resources, ... }: {
    deployment.targetEnv = "ec2";
    deployment.ec2.accessKeyId = accessKeyId;
    deployment.ec2.region = region;
    deployment.ec2.subnetId = resources.vpcSubnets.nixops-vpc-subnet-c;
    deployment.ec2.instanceType = "t2.medium";
    deployment.ec2.keyPair = resources.ec2KeyPairs.my-key-pair;
    deployment.ec2.associatePublicIpAddress = true;
    deployment.ec2.ebsBoot = true;
    deployment.ec2.ebsInitialRootDiskSize = 100;
    deployment.ec2.elasticIPv4 = resources.elasticIPs.eip;
    deployment.ec2.securityGroupIds = [ "allow-ssh" "allow-http" ];

    /* deployment.route53.hostName = domain; */
  };
  lib = (import <nixpkgs> {}).lib;
in
{
  hydra-server = ec2;

  resources = {
    # Provision an EC2 key pair.
    ec2KeyPairs.my-key-pair =
      { inherit region accessKeyId; };

    # create security groups
    ec2SecurityGroups.allow-ssh = { resources, ... }: {
      inherit region accessKeyId;
      name = "allow-ssh";
      description = "allow-ssh";
      vpcId = resources.vpc.nixops-vpc;
      rules = [
        { fromPort = 22; toPort = 22; sourceIp = "0.0.0.0/0"; }
      ];
    };

    ec2SecurityGroups.allow-http = { resources, ... }: {
      inherit region accessKeyId;
      name = "allow-http";
      description = "allow-http";
      vpcId = resources.vpc.nixops-vpc;
      rules = [
        { fromPort = 80; toPort = 80; sourceIp = "0.0.0.0/0"; }
        { fromPort = 443; toPort = 443; sourceIp = "0.0.0.0/0"; }
      ];
    };

    # configure VPC
    vpc.nixops-vpc = {
      inherit region accessKeyId;
      instanceTenancy = "default";
      enableDnsSupport = true;
      enableDnsHostnames = true;
      cidrBlock = "10.0.0.0/16";
      tags.Source = "NixOps";
    };

    vpcSubnets =
      let
        makeSubnet = {cidr, zone}:
          { resources, ... }: {
            inherit region zone accessKeyId;
            vpcId = resources.vpc.nixops-vpc;
            cidrBlock = cidr;
            mapPublicIpOnLaunch = true;
            tags.Source = "NixOps";
        };
      in
        builtins.listToAttrs
          (map
            ({ name, cidr, zone }: lib.nameValuePair name (makeSubnet { inherit cidr zone; }) )
            subnets
          );

    vpcRouteTables = {
      route-table = { resources, ... }: {
        inherit accessKeyId region;
        vpcId = resources.vpc.nixops-vpc;
      };
    };

    vpcRoutes = {
      igw-route = { resources, ... }: {
        inherit region accessKeyId;
        routeTableId = resources.vpcRouteTables.route-table;
        destinationCidrBlock = "0.0.0.0/0";
        gatewayId = resources.vpcInternetGateways.nixops-igw;
      };
    };

    vpcRouteTableAssociations =
      let
        association = subnetName: { resources, ... }: {
          inherit accessKeyId region;
          subnetId = resources.vpcSubnets."${subnetName}";
          routeTableId = resources.vpcRouteTables.route-table;
        };
      in
        builtins.listToAttrs
          (map
            ({ name, ... }: lib.nameValuePair "association-${name}" (association name) )
            subnets
          );
    vpcInternetGateways.nixops-igw = { resources, ... }: {
      inherit accessKeyId region;
      vpcId = resources.vpc.nixops-vpc;
    };

    elasticIPs.eip = {
      inherit region accessKeyId;
      vpc = true;
    };

    /* resources.vpcNatGateways.nat = { resources, ... }: {
        inherit region accessKeyId;
        allocationId = elasticIPs.eip;
        subnetId = vpcSubnets.nixops-vpc-subnet-f;
    }; */

  };
}