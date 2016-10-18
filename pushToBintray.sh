#!/bin/bash

#########################################################################################
# modified from https://github.com/vogellacompany/bintray-publish-p2-updatesite
# borrowed idea from http://www.lorenzobettini.it/2016/02/publish-an-eclipse-p2-composite-repository-on-bintray/
#
# Sample Usage: pushToBintray.sh username apikey owner repo version pathToP2Repo
#########################################################################################

BINTRAY_USER=$1
BINTRAY_API_KEY=$2
BINTRAY_OWNER=$3
BINTRAY_REPO=$4
PCK_VERSION=$5
PATH_TO_REPOSITORY=$6

BINTRAY_API_URL=https://api.bintray.com
# make sure the 'updatesites' package was created in the repo on Bintray
DISTS_PCK_NAME=updatesites
# make sure the 'zipped' package was created in the repo on Bintray
ZIPPED_PCK_NAME=zipped
# make sure the 'composite' package was created in the repo on Bintray
COMPOSITE_PCK_NAME=composite

echo "BINTRAY_USER=${BINTRAY_USER}"
echo "BINTRAY_OWNER=${BINTRAY_OWNER}"
echo "BINTRAY_REPO=${BINTRAY_REPO}"
echo "PCK_VERSION=${PCK_VERSION}"
echo "PATH_TO_REPOSITORY=${PATH_TO_REPOSITORY}"


function main() {
deploy_updatesite
deploy_zipped_updatesite
deploy_composite_updatesite
}

function deploy_updatesite() {
local curr=`pwd`
if [ ! -z "$PATH_TO_REPOSITORY" ]; then
   cd $PATH_TO_REPOSITORY/updatesite
fi

local PCK_NAME=${DISTS_PCK_NAME}
local BINTRAY_TARGET_PATH=${PCK_NAME}/${PCK_VERSION}

FILES=./*
PLUGINDIR=./plugins/*
FEATUREDIR=./features/*

for f in $FILES;
do
if [ ! -d $f ]; then
  echo "Processing $f file..."
  curl -v -X PUT -T $f -u ${BINTRAY_USER}:${BINTRAY_API_KEY} "${BINTRAY_API_URL}/content/${BINTRAY_OWNER}/${BINTRAY_REPO}/${BINTRAY_TARGET_PATH}/$f;bt_package=${PCK_NAME};bt_version=${PCK_VERSION};publish=1"
  echo ""
fi
done

echo "Processing features dir $FEATUREDIR file..."
for f in $FEATUREDIR;
do
  echo "Processing feature: $f file..."
  curl -X PUT -T $f -u ${BINTRAY_USER}:${BINTRAY_API_KEY} "${BINTRAY_API_URL}/content/${BINTRAY_OWNER}/${BINTRAY_REPO}/${BINTRAY_TARGET_PATH}/$f;bt_package=${PCK_NAME};bt_version=${PCK_VERSION};publish=1"
  echo ""
done

echo "Processing plugin dir $PLUGINDIR file..."
for f in $PLUGINDIR;
do
   # take action on each file. $f store current file name
  echo "Processing plugin: $f file..."
  curl -X PUT -T $f -u ${BINTRAY_USER}:${BINTRAY_API_KEY} "${BINTRAY_API_URL}/content/${BINTRAY_OWNER}/${BINTRAY_REPO}/${BINTRAY_TARGET_PATH}/$f;bt_package=${PCK_NAME};bt_version=${PCK_VERSION};publish=1"
  echo ""
done

cd $curr
}

function deploy_zipped_updatesite() {
local curr=`pwd`
if [ ! -z "$PATH_TO_REPOSITORY" ]; then
   cd $PATH_TO_REPOSITORY
fi

local PCK_NAME=${ZIPPED_PCK_NAME}
local BINTRAY_TARGET_PATH=${PCK_NAME}/${PCK_VERSION}
local f=updatesite.zip

echo "Processing zipped updatesite ${BINTRAY_TARGET_PATH}/$f"

curl -v -X PUT -T $f -u ${BINTRAY_USER}:${BINTRAY_API_KEY} "${BINTRAY_API_URL}/content/${BINTRAY_OWNER}/${BINTRAY_REPO}/${BINTRAY_TARGET_PATH}/$f;bt_package=${PCK_NAME};bt_version=${PCK_VERSION};publish=1"

cd $curr
}

check_url_status() {
  local url=$1
  local curl_cmd="curl --silent --insecure --connect-timeout 10 --max-time 30 --head"
  curl_cmd="$curl_cmd $url | grep \"HTTP/1.[01]\" | tail -n 1"
  local result=$(eval $curl_cmd)
  eval status=($result)
  echo ${status[1]}
}

function deploy_composite_updatesite() {
local curr=`pwd`
if [ ! -z "$PATH_TO_REPOSITORY" ]; then
   cd $PATH_TO_REPOSITORY
fi

echo "Processing composite updatesite"
local PCK_NAME=$COMPOSITE_PCK_NAME

# download the metadata if exists
local compositeFile=compositeContent.xml
local compositeContentUrl="https://dl.bintray.com/${BINTRAY_OWNER}/${BINTRAY_REPO}/${PCK_NAME}/compositeContent.xml"
if [[ "200" = $(check_url_status $compositeContentUrl) ]]; then
curl -O $compositeContentUrl
else
cat > $compositeFile << EOF
<?compositeMetadataRepository version='1.0.0'?>
<repository name='TestNG Composite P2 Repo' type='org.eclipse.equinox.internal.p2.metadata.repository.CompositeMetadataRepository' version='1.0.0'>
<properties size='2'>
<property name='p2.timestamp' value='1454086165279'/>
<property name='p2.atomic.composite.loading' value='true'/>
</properties>
<children size='3'>
</children>
</repository>
EOF
fi

echo "adding child repo to $compositeFile"

local content=$(sed "/<children size=.*>/a\ 
<child location='../${DISTS_PCK_NAME}/${PCK_VERSION}'/>\ 

" $compositeFile)

echo "$content" > $compositeFile

cat $compositeFile

echo "uploading composite metadata file"
local BINTRAY_TARGET_PATH=${PCK_NAME}

curl -v -X PUT -T $compositeFile -u ${BINTRAY_USER}:${BINTRAY_API_KEY} "${BINTRAY_API_URL}/content/${BINTRAY_OWNER}/${BINTRAY_REPO}/${BINTRAY_TARGET_PATH}/compositeContent.xml;bt_package=${PCK_NAME};bt_version=${PCK_VERSION};publish=1"
curl -v -X PUT -T $compositeFile -u ${BINTRAY_USER}:${BINTRAY_API_KEY} "${BINTRAY_API_URL}/content/${BINTRAY_OWNER}/${BINTRAY_REPO}/${BINTRAY_TARGET_PATH}/compositeArtifacts.xml;bt_package=${PCK_NAME};bt_version=${PCK_VERSION};publish=1"

cd $curr
}

function delete_composite_files() {
local PCK_NAME=$COMPOSITE_PCK_NAME
local BINTRAY_TARGET_PATH=${PCK_NAME}
curl -v -X DELETE -u ${BINTRAY_USER}:${BINTRAY_API_KEY} "${BINTRAY_API_URL}/content/${BINTRAY_OWNER}/${BINTRAY_REPO}/${BINTRAY_TARGET_PATH}/compositeContent.xml;bt_package=${PCK_NAME};bt_version=${PCK_VERSION};publish=1"
curl -v -X DELETE -u ${BINTRAY_USER}:${BINTRAY_API_KEY} "${BINTRAY_API_URL}/content/${BINTRAY_OWNER}/${BINTRAY_REPO}/${BINTRAY_TARGET_PATH}/compositeArtifacts.xml;bt_package=${PCK_NAME};bt_version=${PCK_VERSION};publish=1"
}

main "$@"
