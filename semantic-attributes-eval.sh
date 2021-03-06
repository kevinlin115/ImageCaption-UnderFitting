#!/bin/bash

model_name="semantic_attention_model_attr_only"
model="SemanticAttentionModel"
#ckpt=520000
ckpt=180973
num_processes=3
gpu_fraction=0.3
device=0

# the script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MODEL_DIR="${DIR}/model/${model_name}"
VALIDATE_IMAGE_DIR="${DIR}/data/ai_challenger_caption_validation_20170910/caption_validation_images_20170910"
CHECKPOINT_PATH="${MODEL_DIR}/model.ckpt-$ckpt"
OUTPUT_DIR="${MODEL_DIR}/model.ckpt-${ckpt}.attributes"
VALIDATE_REFERENCE_FILE="${DIR}/data/ai_challenger_caption_validation_20170910/attributes_reference.json"
ATTRIBUTES_FILE="${DIR}/data/attributes.txt"
rm -rf $OUTPUT_DIR
mkdir $OUTPUT_DIR

cd ${DIR}/im2txt

for prefix in 0 1 2 3 4 5 6 7 8 9 a b c d e f; do
  if [ ! -f ${OUTPUT_DIR}/part-${prefix}.json ]; then
    echo "CUDA_VISIBLE_DEVICES=$device python inference.py \
        --input_file_pattern='${VALIDATE_IMAGE_DIR}/${prefix}*.jpg' \
        --checkpoint_path=${CHECKPOINT_PATH} \
        --vocab_file=${DIR}/data/word_counts.txt \
        --attributes_file=${DIR}/data/attributes.txt \
        --output=${OUTPUT_DIR}/part-${prefix}.json \
        --model=${model} \
        --predict_attributes_only=True \
        --attributes_top_k=20 \
        --gpu_memory_fraction=$gpu_fraction"
  fi
done | parallel -j $num_processes

if [ ! -f ${OUTPUT_DIR}/out.json ]; then
  python ${DIR}/tools/merge_json_lists.py ${OUTPUT_DIR}/part-?.json > ${OUTPUT_DIR}/out.json
  echo output saved to ${OUTPUT_DIR}/out.json
fi

if [ ! -f ${OUTPUT_DIR}/out.eval ]; then
  python ${DIR}/tools/eval/run_attributes_evaluations.py --submit ${OUTPUT_DIR}/out.json --ref $VALIDATE_REFERENCE_FILE --attr $ATTRIBUTES_FILE | tee ${OUTPUT_DIR}/out.eval
fi

echo eval result saved to ${OUTPUT_DIR}/out.eval
