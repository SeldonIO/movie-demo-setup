#!/bin/bash

set -o nounset
set -o errexit

if [[ $# < 1 ]]; then
	echo "Need RAW_DATA_DIR"
	exit 1
fi

get_movielens_10m_dataset() {
    #Get movielens 10m dataset
    if [ ! -d "${RAW_DATA_DIR}/ml-10M100K" ]; then
        cd "${RAW_DATA_DIR}"
        wget http://files.grouplens.org/datasets/movielens/ml-10m.zip
        unzip ml-10m.zip
        rm ml-10m.zip
    fi
}

get_hetrec_dataset() {
    #get hetrec dataset
    if [ ! -d "${RAW_DATA_DIR}/hetrec2011-movielens" ]; then
        mkdir -p ${RAW_DATA_DIR}/hetrec2011-movielens
        cd ${RAW_DATA_DIR}/hetrec2011-movielens
        wget http://files.grouplens.org/datasets/hetrec2011/hetrec2011-movielens-2k-v2.zip
        unzip hetrec2011-movielens-2k-v2.zip
        rm hetrec2011-movielens-2k-v2.zip
    fi
}

get_freebase_json() {
    if [ ! -f "${RAW_DATA_DIR}/freebase.json" ]; then
        cd ${RAW_DATA_DIR}
        wget http://s3-eu-west-1.amazonaws.com/static.seldon.io/datasets/freebase-movies/freebase.json
    fi
}

STARTUP_DIR="$( cd "$( dirname "$0" )" && pwd )"
PROJ_DIR=${STARTUP_DIR}/..

RAW_DATA_DIR=${PROJ_DIR}/local_data/raw_data
RAW_DATA_DIR=$1

mkdir -p ${RAW_DATA_DIR}
get_movielens_10m_dataset
get_hetrec_dataset
get_freebase_json

