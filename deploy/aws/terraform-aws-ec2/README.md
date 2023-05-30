# Raspberry Pi 2 Build Environment

This project aims to create a build environment for Raspberry Pi 2 in the AWS cloud, allowing you to generate an SD card output for your Raspberry Pi 2 device.

## Features

- Provisioning of necessary AWS resources using Terraform
- Creation of a virtual private cloud (VPC)
- Configuration of a security group to allow SSH access
- Deployment of an Amazon EC2 instance with the latest Ubuntu 20.04 LTS ARM64 AMI, suitable for building and deploying to Raspberry Pi 2
- Automatic output of the public IP address of the created instance

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) installed on your computer
- An [AWS account](https://aws.amazon.com/) with an access key and secret key

## Usage

1. Clone this repository and navigate to the project directory.

2. Initialize Terraform:

   ```sh
   terraform init
   ```

3. Update the `main.tf` file with your desired AWS region, VPC CIDR block, subnet CIDR block, instance type, and key pair. Replace the placeholders accordingly.

4. Apply the Terraform configuration:

   ```sh
   make all
   ``
