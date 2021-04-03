# valheim-gcp-ce
Creates a Valheim dedicated server

## Note
This project is primarily a learning exercise on my part with regard to GCP. As such, the templates are in a very rudimentary state at the moment, though I hope to have time to improve them in future. 

## Instructions

1. Clone repo
2. Create project and bucket for backend state and modify `backend.tf` and `versions.tf` accordingly
3. Copy the contents of your worlds directory to `objects/worlds` ie `cp ~/.config/unity3d/IronGate/Valheim/worlds/* objects/worlds/`
4. If using Route53 ensure your AWS CLI credentials are correct
5. Create a `terraform.tfvars` file to specify your desired values for variables
6. `gcloud init`
7. `gcloud auth` etc
8. `terraform init && terraform apply`

## TODO
- Use service account with more fine-grained IAM permissions for instance