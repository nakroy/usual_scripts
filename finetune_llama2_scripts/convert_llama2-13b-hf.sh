# This is a script to convert llama-2-13b-hf model downloaded from huggingface into mcore(megatron) type checkpoint
# TP=8, PP=2 were used in 2 nodes 16 GPUs, change these two arguments if you use different amounts of GPUs
# params dtype: torch.float32(default), torch.float16(--fp16), torch.bfloat16(--bf16)

TP=8

PP=2

MODEL_SIZE=llama2-13B

HF_FORMAT_DIR=/workspace/model_weights/llama2-13b-hf

MEGATRON_FORMAT_DIR=/workspace/model_weights/llama2-13b-hf-tp${TP}-pp${PP}

TOKENIZER_MODEL=/workspace/model_weights/llama2-13b-hf/tokenizer.model


python tools/checkpoint/convert.py \
--model-type GPT \
--loader llama_mistral \
--saver mcore \
--checkpoint-type hf \
--model-size ${MODEL_SIZE} \
--load-dir ${HF_FORMAT_DIR} \
--save-dir ${MEGATRON_FORMAT_DIR} \
--tokenizer-model ${TOKENIZER_MODEL} \
--target-tensor-parallel-size ${TP} \
--target-pipeline-parallel-size ${PP} \
--fp16
