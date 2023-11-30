# Why do we need Terraform Cloud (or another backend) when we use CI/CD?

Terraform Cloud offers features such as Remote Execution and State Locking. With Remote Execution, Terraform operations can be executed on infrastructure without the need for the Terraform binary or local infrastructure access. Concurrently, State Locking prevents multiple users from modifying the state simultaneously, preventing data inconsistencies.

This platform serves as a centralized hub for managing and storing Terraform configurations, fostering collaboration among team members. It enables seamless sharing of infrastructure code and coordinated changes. Additionally, Terraform Cloud enhances the deployment process by providing features like state management, version control integration, and remote execution. This ensures consistency across environments in a CI/CD pipeline.

# In general
 - main.tf corresponds to workshop 3
    - To execute another workshop using Terraform Cloud, simply copy the code into the "main.tf" file.

 - All workshop files are located in the workshop folder
 - Workflow files are located in the .github folder


We have connected our workflow files with Terraform Cloud.

---
```hcl
# Ensure that this Terraform configuration block remains at the top when copying another script into main.tf

terraform {
  backend "remote" {
    organization = "if22b008" # organization of the Terraform Cloud account
    workspaces {
      name = "terraform-fh" # workspace name
    }
  }
}
```

This section of Terraform code needs to be present in the `main.tf` file or any script that is intended to be connected to Terraform Cloud. Adjust the comments and descriptions as needed for your specific documentation.

---

In workshop 3, the Elastic IP of an instance is also displayed, in addition to the load balancer DNS. This is done as a test to check if it is reachable because the load balancer takes approximately 2 minutes after the DNS is displayed to become fully functional.


GitHub Link: https://github.com/fh-technikum-heatwave/terraform