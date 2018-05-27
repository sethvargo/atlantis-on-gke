# Atlantis on GKE with Terraform

These Terraform configurations provision an [Atlantis][atlantis] cluster on
[Google Kubernetes Engine][gke] using [HashiCorp Terraform][terraform] as the
provisioning tool.

## Feature Highlights

- **Google Cloud Storage Backend** - Automatically creates a [GSC][gcs] storage
  bucket for use with Terraform.

- **Dedicated Service Account** - There's a dedicated service account with
  access to the storage bucket which can be given to Terraform or attached to
  instances executing Terraform.

- **(Self-signed) TLS** - Automatically generates certificates and secures the
  Atlantis server with them. This could be replaced with real certificates if
  needed.

- **Automatic GitHub Repo Creation & Configuration** - Automatically creates a
  dedicated private GitHub repository with the Atlantis webhook configured
  automatically.

## Requirements
1. A GCP Organization (see https://cloud.google.com/resource-manager/docs/quickstart-organizations)
because these configurations create a new project which (through Terraform) must be associated with an
organization.
2. A GitHub Organization (not a personal account) because the Terraform GitHub provider
does not yet support personal accounts: https://github.com/terraform-providers/terraform-provider-github/issues/45

## Tutorial

1. Download and install [Terraform][terraform]

1. Download, install, and configure the [Google Cloud SDK][sdk]. You will need to configure your default application credentials so Terraform can run. It will run against your default project, but all resources are created in the (new) project that it creates.

1. Run Terraform:

    ```
    $ cd terraform/
    $ terraform init
    $ terraform apply
    ```

    This operation will take some time as it:

    1. Creates a new project
    1. Enables the required services on that project
    1. Creates a bucket for Terraform remote state
    1. Creates a service account with the most restrictive permissions to those resources
    1. Creates a GKE cluster with the configured service account attached
    1. Creates a public IP
    1. Generates a self-signed certificate authority (CA)
    1. Generates a certificate signed by that CA
    1. Configures Terraform to talk to Kubernetes
    1. Creates a Kubernetes secret with the TLS file contents
    1. Submits the Atlantis Pod and Service (LoadBalancer) to the Kubernetes API
    1. Creates a sample "demo" folder with Terraform configurations that are pre-configured to connect to the provisioned Google Cloud Storage backend with customer-provided encryption keys.

## Run Locally

1. Configure local Terraform with the correct credentials

    ```
    cd demo/
    source env.sh
    ```

1. Run some commands

    ```
    $ tf plan
    $ tf apply
    ```

1. Go to GitHub

1. Make a change

    ```
    n1-standard-1 -> n1-standard-1
    ```

1. Open a Pull Request with the changes on a new branch

1. Plan changes

    ```
    atlantis plan
    ```

1. Apply changes

    ```
    atlantis apply
    ```

## Cleaning Up

```
$ terraform destroy
```

Note that this can sometimes fail. Re-run it and it should succeed. If things get into a bad state, you can always just delete the project.

## Security

This set of Terraform configurations is designed to make your life easy. Some data, including the TLS certificates and webhook secrets will be stored in your state file in plain text.

## License & Author

```
Copyright 2018 Google, Inc.
Copyright 2018 Seth Vargo

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

[atlantis]: https://www.runatlantis.io
[gcs]: https://cloud.google.com/storage
[gke]: https://cloud.google.com/kubernetes-engine
[terraform]: https://www.terraform.io
[sdk]: https://cloud.google.com/sdk/
