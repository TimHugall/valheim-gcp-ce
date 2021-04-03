# valheim-gcp-ce
Creates a Valheim dedicated server

## Note
This project is primarily a learning exercise on my part to start learning GCP. As such, the templates are in a very rudimentary state at the moment, though I hope to have time to improve them in future. 

## Instructions

1. Create project and bucket for backend state
2. Clone repo
3. Copy the contents of your worlds directory to `objects/worlds` ie
    ```
    mkdir -p objects/worlds
    cd objects/worlds
    cp ~/.config/unity3d/IronGate/Valheim/worlds/* .
    ```
4. If using Route53 ensure you're using correct creds in CLI
5. Create a `terraform.tfvars` file to specify your desired values for variables
6. Modify `backend.tf` and set provider details in `versions.tf`
7. `gcloud init`
8. `gcloud auth` etc
9. `terraform init && terraform apply`

## TODO
- Use specific service account
- Fix TIMEZONE