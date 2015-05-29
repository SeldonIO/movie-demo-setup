#!/bin/bash

set -o nounset
set -o errexit

STARTUP_DIR="$( cd "$( dirname "$0" )" && pwd )"

if [[ $# < 2 ]]; then
    echo "Need <client db name> <model to create>"
    exit 1
fi

set_zk_node() {
    local ZK_NODE_PATH="$1"
    local ZK_NODE_VALUE="$2"

    python $SELDON_SERVER_HOME/vm/bin/zkcmd.py --zk-hosts ${ZOOKEEPER_HOST} --cmd set --cmd-args "${ZK_NODE_PATH}" "${ZK_NODE_VALUE}"
}

do_matrix_factorization() {
    echo " -- creating model [${CLIENT}] [matrix_factorization] --"
    set_zk_node "/all_clients/${CLIENT}/offline/matrix-factorization" \
        '{"activate":true,"alpha":1,"days":1,"inputPath":"'${DATA_FOLDER}'","iterations":5,"lambda":0.01,"local":true,"outputPath":"'${DATA_FOLDER}'","rank":30,"startDay":1}'

    JOB_OUTPUT_DIR_NAME=matrix-factorization
    rm -rf ${DATA_FOLDER}/${CLIENT}/${JOB_OUTPUT_DIR_NAME}/1
    JOB_CLASS=io.seldon.spark.mllib.MfModelCreation
    ${STARTUP_DIR}/do-spark-job.sh $CLIENT $JOB_CLASS
}

do_item_similarity() {
    echo " -- creating model [${CLIENT}] [item-similarity] --"
    set_zk_node "/all_clients/${CLIENT}/offline/similar-items" \
        '{"inputPath":"'${DATA_FOLDER}'","outputPath":"'${DATA_FOLDER}'","days":1,"sample":0.25,"limit":100,"dimsum_threshold":0.5}'

    JOB_OUTPUT_DIR_NAME=item-similarity
    rm -rf ${DATA_FOLDER}/${CLIENT}/${JOB_OUTPUT_DIR_NAME}/1
    JOB_CLASS=io.seldon.spark.mllib.SimilarItems
    ${STARTUP_DIR}/do-spark-job.sh $CLIENT $JOB_CLASS

    ${STARTUP_DIR}/upload-item-similarity-sql
}

do_semantic_vectors() {
    echo " -- creating model [${CLIENT}] [svtext] --"

    JOB_CONFIG='{"inputPath":"'${DATA_FOLDER}'","outputPath":"'${DATA_FOLDER}'","startDay":1,"days":1,"activate":true,"itemType":1,"itemLimit":10000,"tagAttrs":"movielens_tags_full","jdbc":"jdbc:mysql://'${MYSQL_HOST}':3306/'${CLIENT}'?user=root&password='${MYSQL_ROOT_PASSWORD}'&characterEncoding=utf8"}'
    set_zk_node "/all_clients/${CLIENT}/offline/semvec" "${JOB_CONFIG}"

    JOB_OUTPUT_DIR_NAME=svtext
    ##rm -rf ${DATA_FOLDER}/${CLIENT}/${JOB_OUTPUT_DIR_NAME}/1

    docker run --rm -i -t \
        --name="semvec_container" \
        -v ${DATA_FOLDER}:${DATA_FOLDER} \
        seldonio/semantic-vectors-for-seldon bash -c "rm -rfv ${DATA_FOLDER}/${CLIENT}/${JOB_OUTPUT_DIR_NAME}/1"

    docker run --rm -i -t \
        --name="semvec_container" \
        -v ${DATA_FOLDER}:${DATA_FOLDER} \
        seldonio/semantic-vectors-for-seldon bash -c "./semvec/semantic-vectors.py --client ${CLIENT} --zookeeper ${ZOOKEEPER_HOST}:2181"
}

do_word2vec() {
    echo " -- creating model [${CLIENT}] [word2vec] --"

    set_zk_node "all_clients/${CLIENT}/offline/sessionitems" \
        '{"inputPath":"'${DATA_FOLDER}'","outputPath":"'${DATA_FOLDER}'","startDay":1,"days":1,"maxIntraSessionGapSecs":-1,"minActionsPerUser":0,"maxActionsPerUser":100000}'

    JOB_OUTPUT_DIR_NAME=sessionitems
    rm -rf ${DATA_FOLDER}/${CLIENT}/${JOB_OUTPUT_DIR_NAME}/1
    JOB_CLASS=io.seldon.spark.topics.SessionItems
    ${STARTUP_DIR}/do-spark-job.sh $CLIENT $JOB_CLASS

    set_zk_node "all_clients/${CLIENT}/offline/word2vec" \
        '{"inputPath":"'${DATA_FOLDER}'","outputPath":"'${DATA_FOLDER}'","activate":true,"startDay":1,"days":1,"activate":true,"minWordCount":50,"vectorSize":200}'

    JOB_OUTPUT_DIR_NAME=word2vec
    rm -rf ${DATA_FOLDER}/${CLIENT}/${JOB_OUTPUT_DIR_NAME}/1
    JOB_CLASS="io.seldon.spark.features.Word2VecJob"
    ${STARTUP_DIR}/do-spark-job.sh $CLIENT $JOB_CLASS
}

CLIENT=$1
MODEL=$2
SELDON_SERVER_HOME=${STARTUP_DIR}/../../seldon-server
DATA_FOLDER=~/seldon-models

export ZOOKEEPER_HOST=unkown_zookeeper_host
if [[ "$(uname)" == "Darwin" ]]; then
    BOOT2DOCKER_HOST=$(boot2docker ip)
    export ZOOKEEPER_HOST=$BOOT2DOCKER_HOST
fi
if [[ "$(uname)" == "Linux" ]]; then
    ZOOKEEPER_HOST=$(hostname --all-ip-addresses | awk '{print $1}')
fi

MYSQL_HOST=unkown_mysql_host
if [[ "$(uname)" == "Darwin" ]]; then
    BOOT2DOCKER_HOST=$(boot2docker ip)
    MYSQL_HOST=$BOOT2DOCKER_HOST
fi
if [[ "$(uname)" == "Linux" ]]; then
    MYSQL_HOST=$(hostname --all-ip-addresses | awk '{print $1}')
fi
MYSQL_ROOT_PASSWORD=mypass

case $MODEL in
    matrix_factorization)
        do_matrix_factorization
        ;;
    item_similarity)
        do_item_similarity
        ;;
    semantic_vectors)
        do_semantic_vectors
        ;;
    word2vec)
        do_word2vec
        ;;
    *)
        echo "ignoring unkown model[$MODEL]"
        ;;
esac

