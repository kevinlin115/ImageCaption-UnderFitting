#!/bin/bash

# the script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

INCEPTION_CHECKPOINT="${DIR}/pretrained_model/inception_v3/inception_v3.ckpt"
TFRECORD_DIR="${DIR}/data/TFRecord_data"
MODEL_DIR="${DIR}/model"
model=ReviewNetworkModel

model_dir_name=review_network_model

cd im2txt && CUDA_VISIBLE_DEVICES=0 python train.py \
  --input_file_pattern="${TFRECORD_DIR}/train-?????-of-?????.tfrecord" \
  --inception_checkpoint_file="${INCEPTION_CHECKPOINT}" \
  --train_dir="${MODEL_DIR}/${model_dir_name}" \
  --model=${model} \
  --support_ingraph=True \
  --vocab_file="${DIR}/data/word_counts.txt" \
  --inception_return_tuple=True \
  --discriminative_loss_weights=1.0 \
  --initial_learning_rate=1.0 \
  --learning_rate_decay_factor=0.66 \
  --train_inception_with_decay=True \
  --number_of_steps=500000
