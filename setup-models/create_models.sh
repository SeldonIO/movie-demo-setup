#!/bin/bash

set -o nounset
set -o errexit

STARTUP_DIR="$( cd "$( dirname "$0" )" && pwd )"

if [[ $# < 2 ]]; then
    echo "Need <client db name> <model to create>"
    exit 1
fi

CLIENT=$1
MODEL=$2
SELDON_SERVER_HOME=${STARTUP_DIR}/../../seldon-server
DATA_FOLDER=~/seldon-models
export ZOOKEEPER_HOST=localhost
if [[ "$(uname)" == "Darwin" ]]; then
    BOOT2DOCKER_HOST=$(boot2docker ip)
    export ZOOKEEPER_HOST=$BOOT2DOCKER_HOST
fi

set_zk_node() {
    local ZK_NODE_PATH="$1"
    local ZK_NODE_VALUE="$2"

    python $SELDON_SERVER_HOME/vm/bin/zkcmd.py --zk-hosts ${ZOOKEEPER_HOST} --cmd set --cmd-args "${ZK_NODE_PATH}" "${ZK_NODE_VALUE}"
}

do_matrix_factorization() {
    echo " -- creating model [${CLIENT}] [matrix_factorization] --"
    set_zk_node "/all_clients/${CLIENT}/offline/matrix-factorization" \
        '{"activate":true,"alpha":1,"days":1,"inputPath":"'${DATA_FOLDER}'","iterations":5,"lambda":0.1,"local":true,"outputPath":"'${DATA_FOLDER}'","rank":30,"startDay":1}'

    JOB_OUTPUT_DIR_NAME=matrix-factorization
    rm -rf ${DATA_FOLDER}/${CLIENT}/${JOB_OUTPUT_DIR_NAME}/1
    JOB_CLASS=io.seldon.spark.mllib.MfModelCreation
    ${STARTUP_DIR}/do-spark-job.sh $CLIENT $JOB_CLASS
}

case $MODEL in
    matrix_factorization)
        do_matrix_factorization
        ;;
    *)
        echo "ignoring unkown model[$MODEL]"
        ;;
esac

