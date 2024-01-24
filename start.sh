#!/bin/bash
 

state_cloud=false      # Whether the cloud storage is available
state_aws=false        # Whether AWS is available
state_azure=false      # Whether Azure is available
state_gcp=false        # Whether GCP is available


# Create the JupyerLab password by the environment variable – ‘JUPYTERLAB_GW’
# Disable the delete-to-trash feature and allow deleting folders with files
echo -e "\n------------------------------------------> Set up the Jupyterlab password based on the env JUPYTERLAB_PW"
python3 -c "from jupyter_server.auth import passwd; import os; jupyterlab_pw = os.getenv('JUPYTERLAB_PW',default='data'); print(\"c.ServerApp.password = u'\" +  passwd(jupyterlab_pw) + \"'\")" >> ~/.jupyter/jupyter_lab_config.py
echo "c.FileContentsManager.delete_to_trash = False" >> ~/.jupyter/jupyter_lab_config.py
echo "c.FileContentsManager.always_delete_dir = True" >> ~/.jupyter/jupyter_lab_config.py


# Enable the sync from AWS if AWS-related environment variables are provided
if test $AWS_S3_BUCKET_FOLDER;then
    echo -e "\n------------------------------------------> Synchronize data from AWS to the $target_dir folder"
#   aws s3 sync s3://$AWS_S3_BUCKET_FOLDER $target_dir --delete
#   The --delete option will delete files that exist in the destination but not in the source.
    aws s3 sync s3://$AWS_S3_BUCKET_FOLDER $target_dir

    if [ $? -eq 0 ]; then
        state_aws=true
        state_cloud=true
        message="AWS Cloud Storage is available - s3://$AWS_S3_BUCKET_FOLDER ."
        echo -e "\n"
        echo $message
        echo $message >> /root/welcome.txt.backup
    fi
fi


# Enable the sync from Azure if Azure-related environment variables are provided
if test $AZURE_CONTAINER_URL;then
    echo -e "\n------------------------------------------> Synchronize data from Azure to the $target_dir folder"
#   azcopy sync $AZURE_CONTAINER_URL?$AZURE_BLOB_SAS_TOKEN $target_dir --recursive=true --delete-destination=true
#   The --delete-destination option will delete files that exist in the destination but not in the source.
    azcopy sync $AZURE_CONTAINER_URL?$AZURE_BLOB_SAS_TOKEN $target_dir --recursive=true

    if [ $? -eq 0 ]; then
        state_azure=true
        state_cloud=true
        message="Azure Cloud Storage is available - $AZURE_CONTAINER_URL ."
        echo -e "\n"
        echo $message
        echo $message >> /root/welcome.txt.backup
    fi
fi


# Enable the sync from GCP if GCP-related environment variables are provided
if test $GOOGLE_BUCKET_FOLDER;then
    echo -e "\n------------------------------------------> Synchronize data from GCP to the $target_dir folder"
    echo $GOOGLE_APPLICATION_CREDENTIALS > /root/gcp.json
    gcloud auth activate-service-account --key-file=/root/gcp.json --project $GOOGLE_PROJECT_ID
#   gsutil rsync -r -d gs://$GOOGLE_BUCKET_FOLDER $target_dir
#   The -d option will delete files that exist in the destination but not in the source.
    gsutil rsync -r gs://$GOOGLE_BUCKET_FOLDER $target_dir

    if [ $? -eq 0 ]; then
        rm /root/gcp.json
        state_gcp=true
        state_cloud=true
        message="GCP Cloud Storage is available - gs://$GOOGLE_BUCKET_FOLDER ."
        echo -e "\n"
        echo $message
        echo $message >> /root/welcome.txt.backup
    fi
fi


echo -e "\n------------------------------------------> Output"
message="The current working directory is configured to the /root/data ."
echo $message
echo $message >> /root/welcome.txt.backup
if [ $state_cloud == true ]; then
    message="The auto-sync service is running and any changes in this directory and its subfolders will be automatically synchronized back to the cloud."
else
    message="The Cloud Storage is not available and the auto-sync service is disabled."
fi
echo $message
echo $message >> /root/welcome.txt.backup
mv /root/welcome.txt.backup $target_dir/welcome.txt


echo -e "\n------------------------------------------> Run the Jupyterlab"
nohup jupyter lab --no-browser --port=8000 --ip=* --allow-root > /root/jupyterlab.log 2>&1 &


echo -e "\n------------------------------------------> Auto Sync"
while true
do

    echo -e "\n---------> Monitoring the $target_dir folder ..."
    inotifywait -rq --timefmt '%d/%m/%y %H:%M' --format '%T %w %f %e' --event create,delete,modify $target_dir

    echo -e "\n---------> Some changes, waiting 5 seconds until the all related changes have finished"
    sleep 5

    # No cloud storage is available
    if [ $state_cloud == false ]; then
      echo -e "\n---------> No cloud storage, and the changes are not saved."
      continue
    fi

    # Sync back to AWS
    if [ $state_aws == true ]; then
      echo -e "\n---------> Synchronize the changes to AWS ..."
      aws s3 sync $target_dir s3://$AWS_S3_BUCKET_FOLDER --delete
    fi

    # Sync back to Azure
    if [ $state_azure == true ]; then
      echo -e "\n---------> Synchronize the changes to Azure ..."
      azcopy sync $target_dir $AZURE_CONTAINER_URL?$AZURE_BLOB_SAS_TOKEN --recursive=true --delete-destination=true
    fi

    # Sync back to GCP
    if [ $state_gcp == true ]; then
      echo -e "\n---------> Synchronize the changes to GCP ..."
      gsutil rsync -r -d $target_dir gs://$GOOGLE_BUCKET_FOLDER
    fi

done




