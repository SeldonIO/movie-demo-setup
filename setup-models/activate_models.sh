#!/bin/bash

set -o nounset
set -o errexit

STARTUP_DIR="$( cd "$( dirname "$0" )" && pwd )"

if [[ $# < 2 ]]; then
    echo "Need <client db name> <model to activate>"
    exit 1
fi

set_zk_node() {
    local ZK_NODE_PATH="$1"
    local ZK_NODE_VALUE="$2"

    python $SELDON_SERVER_HOME/vm/bin/zkcmd.py --zk-hosts ${ZOOKEEPER_HOST} --cmd set --cmd-args "${ZK_NODE_PATH}" "${ZK_NODE_VALUE}"
}

do_matrix_factorization() {
    set_zk_node '/config/mf' "${CLIENT}"
}

do_item_similarity() {
    : # Not needed as the creating the model will activate it
}

do_semantic_vectors() {
    set_zk_node '/config/svtext' "${CLIENT}"
}

do_word2vec() {
    set_zk_node '/config/word2vec' "${CLIENT}"
}

CLIENT=$1
MODEL=$2

SELDON_SERVER_HOME=${STARTUP_DIR}/../../seldon-server
export ZOOKEEPER_HOST=localhost
if [[ "$(uname)" == "Darwin" ]]; then
    BOOT2DOCKER_HOST=$(boot2docker ip)
    export ZOOKEEPER_HOST=$BOOT2DOCKER_HOST
fi

echo "-- Activating model[${MODEL}] -- "

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

