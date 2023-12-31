#!/bin/bash
# Copyright 2021 Huawei Technologies Co., Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================

echo "=============================================================================================================="
echo "Please run the script as: "
echo "bash run_distribute_train.sh DEVICE_NUM EPOCH_SIZE LR DATASET RANK_TABLE_FILE PRE_TRAINED PRE_TRAINED_EPOCH_SIZE"
echo "for example: bash run_distribute_train.sh 8 500 0.2 coco /data/hccl.json /opt/ssd-300.ckpt(optional) 200(optional)"
echo "It is better to use absolute path."
echo "================================================================================================================="

if [ $# != 6 ] && [ $# != 8 ]
then
    echo "Usage: bash run_distribute_train.sh [CONFIG_FILE] [DEVICE_NUM] [EPOCH_SIZE] [LR] [DATASET] \
[RANK_TABLE_FILE] [PRE_TRAINED](optional) [PRE_TRAINED_EPOCH_SIZE](optional)"
    exit 1
fi

# Before start distribute train, first create mindrecord files.
BASE_PATH=$(cd "$(dirname "$0")" || exit; pwd)
cd "$BASE_PATH"/../ || exit
python train.py --only_create_dataset=True --dataset="$4"

echo "After running the script, the network runs in the background. The log will be generated in LOGx/log.txt"

CONFIG_PATH=$1
export RANK_SIZE=$2
EPOCH_SIZE=$3
LR=$4
DATASET=$5
export RANK_TABLE_FILE=$6
PRE_TRAINED=$7
PRE_TRAINED_EPOCH_SIZE=$8

for((i=0;i<RANK_SIZE;i++))
do
    export DEVICE_ID=$i
    rm -rf LOG"$i"
    mkdir ./LOG"$i"
    cp ./*.py ./LOG"$i"
    cp -r ./src ./LOG"$i"
    cp -r ./scripts ./LOG"$i"
    cp -r ./config/*.yaml ./LOG"$i"
    cd ./LOG"$i" || exit
    export RANK_ID=$i
    echo "start training for rank $i, device $DEVICE_ID"
    env > env.log
    if [ $# == 5 ]
    then
        python train.py  \
        --config_path="$CONFIG_PATH" \
        --distribute=True  \
        --lr="$LR" \
        --dataset="$DATASET" \
        --device_num="$RANK_SIZE"  \
        --device_id="$DEVICE_ID"  \
        --epoch_size="$EPOCH_SIZE" > log.txt 2>&1 &
    fi

    if [ $# == 7 ]
    then
        python train.py  \
        --config_path="$CONFIG_PATH" \
        --distribute=True  \
        --lr="$LR" \
        --dataset="$DATASET" \
        --device_num="$RANK_SIZE"  \
        --device_id="$DEVICE_ID"  \
        --pre_trained="$PRE_TRAINED" \
        --pre_trained_epoch_size="$PRE_TRAINED_EPOCH_SIZE" \
        --epoch_size="$EPOCH_SIZE" > log.txt 2>&1 &
    fi

    cd ../
done
