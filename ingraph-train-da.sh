#!/bin/bash

# the script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

INCEPTION_CHECKPOINT="${DIR}/pretrained_model/inception_v3/inception_v3.ckpt"
TFRECORD_DIR="${DIR}/data/Aug_TFRecord_data"
MODEL_DIR="${DIR}/model"
model=ShowAndTellInGraphModel

model_dir_name=show_and_tell_in_graph_model_da

cd im2txt && CUDA_VISIBLE_DEVICES=0 python train.py \
  --input_file_pattern="${TFRECORD_DIR}/train-?????-of-?????.tfrecord" \
  --inception_checkpoint_file="${INCEPTION_CHECKPOINT}" \
  --train_dir="${MODEL_DIR}/${model_dir_name}" \
  --model=${model} \
  --support_ingraph=True \
  --number_of_steps=420000 \
  --support_flip=True
