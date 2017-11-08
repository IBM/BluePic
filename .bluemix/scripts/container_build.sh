#!/bin/bash
#set -x

echo -e "Build environment variables:"
echo "REGISTRY_URL=${REGISTRY_URL}"
echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}"
echo "IMAGE_NAME=${IMAGE_NAME}"
echo "CHART_NAME=${CHART_NAME}"
echo "BUILD_NUMBER=${BUILD_NUMBER}"
echo "ARCHIVE_DIR=${ARCHIVE_DIR}"

# Learn more about the available environment variables at:
# https://console.bluemix.net/docs/services/ContinuousDelivery/pipeline_deploy_var.html#deliverypipeline_environment

# To review or change build options use:
# bx cr build --help

echo "=========================================================="
echo "Checking for Dockerfile at the repository root"
if [ -f Dockerfile ]; then
   echo "Dockerfile found"
else
    echo "Dockerfile not found"
    exit 1
fi

echo "=========================================================="
echo "Checking registry current plan and quota"
bx cr plan
bx cr quota
echo "If needed, discard older images using: bx cr image-rm"

# TODO this check for namespace is not enough, namespace has to be unique per region.
# This only checks for existence of namespace in user's account. When creating namespace,
# need to handle case where it's already taken, and perhaps generate a unique one.
# Rules for namespace:
# The namespace must be unique and not taken in registry region.
# The namespace must be 4-30 characters long.
# The namespace must start with at least one letter or number.
# The namespace can only contain lowercase letters, numbers or underscores (_).
#echo "Checking registry namespace: ${REGISTRY_NAMESPACE}"
#ns=$( bx cr namespaces | grep ${REGISTRY_NAMESPACE} ||: )
#if [ -z $ns ]; then
#    echo "Registry namespace ${REGISTRY_NAMESPACE} not found, creating it."
#    bx cr namespace-add ${REGISTRY_NAMESPACE}
#    echo "Registry namespace ${REGISTRY_NAMESPACE} created."
#else
#    echo "Registry namespace ${REGISTRY_NAMESPACE} found."
#fi

echo -e "Existing images in registry"
bx cr images

echo "=========================================================="
echo -e "Building container image: ${IMAGE_NAME}:${BUILD_NUMBER}"
set -x
bx cr build -t $REGISTRY_URL/$REGISTRY_NAMESPACE/$IMAGE_NAME:$BUILD_NUMBER .
set +x
bx cr image-inspect $REGISTRY_URL/$REGISTRY_NAMESPACE/$IMAGE_NAME:$BUILD_NUMBER

echo "=========================================================="
echo "Copying artifacts needed for deployment and testing"

echo -e "Checking archive dir presence"
mkdir -p $ARCHIVE_DIR

# IMAGE_NAME from build.properties is used by Vulnerability Advisor job to reference the image qualified location in registry
echo "IMAGE_NAME=${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}:${BUILD_NUMBER}" >> $ARCHIVE_DIR/build.properties

# RELEASE_NAME from build.properties is used in Helm Chart deployment to set the release name
echo "RELEASE_NAME=${CHART_NAME}" >> $ARCHIVE_DIR/build.properties

# REGISTRY_HOST from build.properties is used to create imagePullSecret, ex: registry.ng.bluemix.net
echo "REGISTRY_HOST=${REGISTRY_URL}" >> $ARCHIVE_DIR/build.properties

# Copy scripts (incl. deploy scripts)
if [ ! -d $ARCHIVE_DIR/$SCRIPTS_DIR ]; then # no need to copy if working in ./ already
    echo "Copying scripts to ${ARCHIVE_DIR}/${SCRIPTS_DIR}"
    mkdir -p $ARCHIVE_DIR/$SCRIPTS_DIR
    cp -r $SCRIPTS_DIR/ $ARCHIVE_DIR/$SCRIPTS_DIR/
fi

if [ -f ./chart/${CHART_NAME}/values.yaml ]; then
    #Update Helm chart values.yml with image name and tag
    echo "UPDATING CHART VALUES:"
    sed -i "s~^\([[:blank:]]*\)repository:.*$~\1repository: ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}~" ./chart/${CHART_NAME}/values.yaml
    sed -i "s~^\([[:blank:]]*\)tag:.*$~\1tag: ${BUILD_NUMBER}~" ./chart/${CHART_NAME}/values.yaml
    cat ./chart/${CHART_NAME}/values.yaml
    if [ ! -d $ARCHIVE_DIR/chart/ ]; then # no need to copy if working in ./ already
        echo "Copying chart to ${ARCHIVE_DIR}"
        cp -r ./chart/ $ARCHIVE_DIR/
    fi
else
    echo -e "${red}Helm chart values for Kubernetes deployment (/chart/${CHART_NAME}/values.yaml) not found.${no_color}"
    exit 1
fi