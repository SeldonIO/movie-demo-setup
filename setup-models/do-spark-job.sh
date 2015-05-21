#!/bin/bash

set -o nounset
set -o errexit

STARTUP_DIR="$( cd "$( dirname "$0" )" && pwd )"

if [[ $# < 2 ]]; then
    echo "Need <client name> <job class>"
    exit 1
fi

setup_jar_file() {
    echo "-- setting up jar file --"
    if [[ ! -d "${SELDON_SERVER_HOME}/offline-jobs/spark/target" ]]; then
        (cd ${SELDON_SERVER_HOME}/offline-jobs/spark && mvn package)
    fi

    JARFILE_PATH=$(ls ${SELDON_SERVER_HOME}/offline-jobs/spark/target/seldon-spark-*-with-dependencies.jar)
    JARFILE=$(basename ${JARFILE_PATH})
    JARFILE_VERSION=$(echo ${JARFILE}|sed -e 's/seldon-spark-//' -e 's/-jar-with-dependencies.jar//')

    #echo "JARFILE_PATH[${JARFILE_PATH}]"
    #echo "JARFILE[${JARFILE}]"
    #echo "JARFILE_VERSION[${JARFILE_VERSION}]"
}

run_spark_job() {
    rm -rf ${DATA_FOLDER}/${CLIENT}/matrix-factorization/${START_DAY}

    echo "jar = ${JARFILE_PATH}"
    echo "Running with executor-memory ${MEM}"

    ${SPARK_HOME}/bin/spark-submit \
        --class "${JOB_CLASS}" \
        --master "local" \
        --executor-memory ${MEM} \
        --driver-memory ${MEM} \
        ${JARFILE_PATH} \
            --client ${CLIENT} \
            --zookeeper ${ZOOKEEPER_HOST} \
            --startDay ${START_DAY}
}

CLIENT=$1
JOB_CLASS=$2

SELDON_SERVER_HOME=${STARTUP_DIR}/../../seldon-server
export ZOOKEEPER_HOST=localhost
if [[ "$(uname)" == "Darwin" ]]; then
    BOOT2DOCKER_HOST=$(boot2docker ip)
    export ZOOKEEPER_HOST=$BOOT2DOCKER_HOST
fi
DATA_FOLDER=~/seldon-models
START_DAY=1
MEM="2g"

setup_jar_file
run_spark_job

