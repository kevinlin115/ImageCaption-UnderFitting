#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sub_dir=$1

model_name="top_down_attention_model"
num_processes=1
device=1
model=TopDownAttentionModel

VALIDATE_TFRECORD_FILE="${DIR}/data/Newloc_TFRecord_data/validate*.tfrecord"
VALIDATE_REFERENCE_FILE="${DIR}/data/ai_challenger_caption_validation_20170910/reference.json"

MODEL_DIR="${DIR}/model/${model_name}/${sub_dir}"
for ckpt in $(ls ${MODEL_DIR} | python ${DIR}/tools/every_n_step.py 20000 | tail -n 10 | tac); do 
  # the script directory

  CHECKPOINT_PATH="${MODEL_DIR}/model.ckpt-$ckpt"
  OUTPUT_DIR="${MODEL_DIR}/model.ckpt-${ckpt}.eval"

  mkdir $OUTPUT_DIR

  cd ${DIR}/im2txt

  if [ ! -f ${OUTPUT_DIR}/out.json ]; then
    CUDA_VISIBLE_DEVICES=$device python batch_inference.py \
      --input_file_pattern="$VALIDATE_TFRECORD_FILE" \
      --checkpoint_path=${CHECKPOINT_PATH} \
      --vocab_file=${DIR}/data/word_counts.txt \
      --output=${OUTPUT_DIR}/out.json \
      --model=${model} \
      --num_lstm_units=512 \
      --num_attention_depth=512 \
      --embedding_size=512 \
      --localization_attention=True \
      --reader=ImageCaptionTestReader \
      --cropping_images=False \
      --batch_size=10 \
      --swap_memory=True \
      --inception_return_tuple=True \
      --support_ingraph=True
    echo output saved to ${OUTPUT_DIR}/out.json
  fi

  if [ ! -f ${OUTPUT_DIR}/out.eval ]; then
    python ${DIR}/tools/eval/run_evaluations.py --submit ${OUTPUT_DIR}/out.json --ref $VALIDATE_REFERENCE_FILE | tee ${OUTPUT_DIR}/out.eval | grep ^Eval
    echo eval result saved to ${OUTPUT_DIR}/out.eval
  fi
done
