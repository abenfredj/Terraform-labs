# Terraform-labs

## Use Terraform to deploy WordPress in kubernetes 

1- Introduction:
The are some notes how to provision wordpress/mariadb in kubernetes using Terraform.
also we will see how to configure postgresql as backend to store state files which can be excellent thing to share the state file between team members

2- Environement:

our Environnement is composed bye following component (5 Vms in total , you can run it on 3Vms only):

- Cluster k8s  is composed by 3 nodes (1 master, and 2 workers) => just we need to get the kube config file to add it to our tf sourcecode.
- Backend host => the only role for this host is to run pg inside container docker and create pg user and database for terraform state file
- Admin machine => have already kubectl and the terraform tool installed and the kube config file.

3- Preparation of environment

