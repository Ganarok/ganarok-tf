#!/bin/bash

# This script is used to deploy a docker image on an EC2 instance
# The docker image must be built and pushed to docker hub before running this script
# with the name : $REPO_NAME-$BRANCH
#
# Required globals:
#   DOCKER_USER
#   DOCKER_PASSWORD
#   BRANCH
#   REPO_NAME
#   PORT
#
# Optional globals:
#   SLACK_TEAM_ID
#   SLACK_WEBHOOK_IDENTIFIER
#   SLACK_WEBHOOK_TOKEN
#   LOKI_URL
#  

# exit when any command fails
set -e

DOCKER_USER=${1}
DOCKER_PASSWORD=${2}
BRANCH=${3}
REPO_NAME=${4}
PORT=${5}
SLACK_TEAM_ID=${6}
SLACK_WEBHOOK_IDENTIFIER=${7}
SLACK_WEBHOOK_TOKEN=${8}
LOKI_URL=${9}

# Function called when an error occurs during the execution of the script
on_error() {
    echo "An error occured during the execution of the deploy script"

    if [[ -n "$SLACK_TEAM_ID" ]]; then
        curl -X POST -H 'Content-type: application/json' --data '{"text":"An error occured during the deployment of the '"${BRANCH}"' branch with docker image '"${REPO_NAME}"'-'"${BRANCH}"' "}' https://hooks.slack.com/services/$SLACK_TEAM_ID/$SLACK_WEBHOOK_IDENTIFIER/$SLACK_WEBHOOK_TOKEN
    fi
}

trap 'on_error' ERR

echo Updating $REPO_NAME Docker container with image $REPO_NAME-$BRANCH ...

echo "Logging in to Docker Hub... password = $DOCKER_PASSWORD & user = $DOCKER_USER"
sudo docker login -u $DOCKER_USER -p $DOCKER_PASSWORD
sudo docker image pull $DOCKER_USER/images:$REPO_NAME-$BRANCH

# If the container is already running, stop it
if sudo docker ps --format "{{.Names}}" | grep -q $REPO_NAME-$BRANCH; then
    echo Stopping container $REPO_NAME-$BRANCH
    sudo docker stop $REPO_NAME-$BRANCH
    echo Remove container $REPO_NAME-$BRANCH
    sudo docker rm $REPO_NAME-$BRANCH
fi

# If a Grafana Loki URL is provided, launch the container with the Loki driver
if [[ -n "$LOKI_URL" ]]; then
    echo $LOKI_URL
    echo Loki URL found, launchin logs to it...
    sudo docker run --log-driver=loki --log-opt loki-url=$LOKI_URL --log-opt loki-retries=5 --log-opt loki-batch-size=400 --detach --restart unless-stopped -p ${PORT}:${PORT} --network caddy --name $REPO_NAME-$BRANCH $DOCKER_USER/images:$REPO_NAME-$BRANCH
else
    echo No Loki URL found.
    sudo docker run --detach --restart unless-stopped -p ${PORT}:${PORT} --network caddy --name $REPO_NAME-$BRANCH $DOCKER_USER/images:$REPO_NAME-$BRANCH
fi

echo Container $REPO_NAME-$BRANCH is running...

# If Slack credentials are provided, send a notification to the Slack channel
if [[ -n "$SLACK_TEAM_ID" ]]; then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Docker Image '"${REPO_NAME}"'-'"${BRANCH}"' now running"}' https://hooks.slack.com/services/$SLACK_TEAM_ID/$SLACK_WEBHOOK_IDENTIFIER/$SLACK_WEBHOOK_TOKEN
fi
