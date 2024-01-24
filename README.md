# JupyterLab
Provide some dockerfile templates and scripts allowing users to build and run their own JupyterLab images on SaladCloud.

## Pre-built images
The three pre-built JupyterLab container images designed to meet general requirements, are available on the Docker Hub:
https://hub.docker.com/repository/docker/saladtechnologies/jupyterlab/tags

You have the option to run these images directly on SaladCloud for your AI/ML tasks. Alternatively, you can customize them to meet specific needs by utilizing the provided dockerfiles in this repository.

1)saladtechnologies/jupyterlab:1.0.0-pytorch-gpu-aws-azure-gcp

The dockerfile: Dockerfile_PyTorch_GPU

2)saladtechnologies/jupyterlab:1.0.0-tensorflow-gpu-aws-azure-gcp

The dockerfile: Dockerfile_TensorFlow_GPU

3)saladtechnologies/jupyterlab:1.0.0-pytorch-tensorflow-cpu-aws-azure-gcp

The dockerfile: Dockerfile_PyTorch_TensorFlow_CPU

## How it works
SaladCloud is designed to execute stateless container workloads. To ensure data persistence while using JupyterLab on SaladCloud, you can leverage storage services from public cloud platforms. The integration with AWS, Azure, and GCP has already been implemented into these images.
Initial setup involves provisioning cloud storage in the chosen cloud platform, followed by using environment variables to pass the storage resource name and its access credentials to the container during launch.

For AWS, you can provision a S3 bucket and a folder inside the S3 bucket, and create the access key ID/secret access key that can exclusively access the S3 bucket folder.

For Azure, you can create a container inside a storage account, and generate the Blob SAS token with all permissions for the container.

For GCP, you can provision a Cloud Storage bucket and a folder inside the bucket, and create a service account taking the Storage Admin role to access the bucket.

We will soon provide detailed information on the cloud storage provision and some best practices.

To preserve data, we create a folder named 'data' within the /root directory of the container, acting as the current working directory that needs the data persistence.
During the initial launch of the instance, the script file named ‘start.sh’ is executed, and all data is synchronized from the chosen cloud platform to the /root/data directory by use of Cloud-specific CLIs and credentials.
Following this, the script continuously monitors the /root/data directory, and any changes (create, delete or modify) in this directory or its subfolders trigger the synchronization back to the cloud.

Models and datasets that are dynamically downloaded from Hugging Face or TensorFlow Hub are stored in the /root/.cache or /root/.keras hidden folders; and these data will be not synchronized to the cloud platform unless they are explicitly saved into the /root/data directory.

For utilizing these images, specific environment variables are required to pass information to containers.
The Cloud-related environment variables can be omitted if data persistence is not required.

### Password
JUPYTERLAB_PW

It is to define the password for JupyterLab; if omitted, the default password will be 'data'.

### AWS
AWS_S3_BUCKET_FOLDER

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

### Azure
AZURE_CONTAINER_URL

AZURE_BLOB_SAS_TOKEN

### GCP
GOOGLE_BUCKET_FOLDER

GOOGLE_APPLICATION_CREDENTIALS

GOOGLE_PROJECT_ID

## Build and test the images locally
You can use these pre-built images directly, or you may modify these dockerfiles and then build and push your own images to the Docker Hub.

docker image build -t YOUR_DOCKERHUB_USERNAME/jupyterlab:1.0.0 -f YOUR_DOCKEFILE_NAME .

docker login -u YOUR_DOCKERHUB_USERNAME

docker push YOUR_DOCKERHUB_USERNAME/jupyterlab:1.0.0

Test the images locally if you have a GPU-capable environment with the NIVIDIA Container Toolkit installed.

### AWS as the backend storage
export JUPYTERLAB_PW=*****************

export AWS_ACCESS_KEY_ID=*****************

export AWS_SECRET_ACCESS_KEY=*****************

export AWS_S3_BUCKET_FOLDER=BUCKETNAME/FOLDER_NAME

docker run --rm --gpus all -p 8000:8000 -it
--env JUPYTERLAB_PW=$JUPYTERLAB_PW
--env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY --env AWS_S3_BUCKET_FOLDER=$AWS_S3_BUCKET
YOUR_DOCKERHUB_USERNAME/jupyterlab:1.0.0

### Azure as the backend storage
export JUPYTERLAB_PW=*****************

export AZURE_CONTAINER_URL=https://storage_account_name.blob.core.windows.net/contaienr_name

export AZURE_BLOB_SAS_TOKEN='*****************' # Need the quotation marks or double quotation marks here because it contains many equal signs.

docker run --rm --gpus all -p 8000:8000 -it
--env JUPYTERLAB_PW=$JUPYTERLAB_PW
--env AZURE_CONTAINER_URL=$AZURE_CONTAINER_URL --env AZURE_BLOB_SAS_TOKEN=$AZURE_BLOB_SAS_TOKEN
YOUR_DOCKERHUB_USERNAME/jupyterlab:1.0.0

### GCP as the backend storage
export JUPYTERLAB_PW=*****************

export GOOGLE_APPLICATION_CREDENTIALS=$(cat *****************.json) # The json file contains the key of service account downloaded from GCP.

export GOOGLE_BUCKET_FOLDER=BUCKETNAME/FOLDER_NAME

export GOOGLE_PROJECT_ID=*****************

docker run --rm --gpus all -p 8000:8000 -it
--env JUPYTERLAB_PW=$JUPYTERLAB_PW
--env GOOGLE_APPLICATION_CREDENTIALS="$GOOGLE_APPLICATION_CREDENTIALS" 
--env GOOGLE_BUCKET_FOLDER=$GOOGLE_BUCKET_FOLDER --env GOOGLE_PROJECT_ID=$GOOGLE_PROJECT_ID
YOUR_DOCKERHUB_USERNAME/jupyterlab:1.0.0

Need the double quotation marks because $GOOGLE_APPLICATION_CREDENTIALS contains a complex JSON data structure.

## Run the JupyterLab images on SaladCloud
To run a JupyterLab instance on SaladCloud, you can Log in the SaladCloud Console and deploy the JupyterLab instance by selecting 'Deploy a Container Group' with the following parameters:

Image Source: the provided images or your own images

Replica Count: 1

vCPU: 2

Memory: 4 GB

GPU: RTX 1650 (4 GB), RTX 2080 (8 GB), RTX 3060 (12 GB) or others # You can choose multiple GPU types simultaneously, and SaladCloud will then select a node that matches one of the selected types.

Networking: Enable, Port 8000, No Use Authentication 

Environment Variables # Provide the corresponding environment variables based on your needs.

SaladCloud would take a few minutes to download the image to the selected node and run the container. Using the SaladCloud Console, you can determine whether the JupyterLab instance is ready to use.

After the instance is running, you can type the generated Access Domain Name in the browser’s address bar, enter the password provided by the JUPYTERLAB_PW environment variable, and begin using the JupyterLab service.
