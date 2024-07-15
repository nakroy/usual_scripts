# This is a script to preprocess finetune dataset
# The dataset we use is downloaded from: 
# https://huggingface.co/datasets/tatsu-lab/alpaca/resolve/main/data/train-00000-of-00001-a09b74b3ef9c3b56.parquet
# And after downloading the dataset, we convert the data type into json type


INPUT_FILE=/workspace/dataset/finetune_dataset/train-00000-of-00001-a09b74b3ef9c3b56.json
TOKENIZER_MODEL=/workspace/model_weights/llama2-13b-hf/tokenizer.model
OUTPUT_PREFIX=/workspace/dataset/finetune_dataset/llama-2-13b-hf/alpaca
TOKENIZER_TYPE=Llama2Tokenizer

mkdir -p /workspace/dataset/finetune_dataset/llama-2-13b-hf/

python ./tools/preprocess_data.py \
--input ${INPUT_FILE} \
--output-prefix ${OUTPUT_PREFIX} \
--tokenizer-model ${TOKENIZER_MODEL} \
--workers 4 \
--log-interval 1000 \
--tokenizer-type ${TOKENIZER_TYPE} \
--append-eod
