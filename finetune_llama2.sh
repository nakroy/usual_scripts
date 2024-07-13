# finetune_llama2.sh
# Setting the environment variables
export OMP_NUM_THREADS=1
export CUDA_DEVICE_MAX_CONNECTIONS=1
export NCCL_DEBUG=WARN
export NCCL_SOCKET_IFNAME=eth0
export TORCH_CUDA_ARCH_LIST=Hooper

# Distributed training variables
NNODES=2
GPUS_PER_NODE=8
GPU_NUM=$((${GPUS_PER_NODE}*${NNODES}))
WORLD_SIZE=$((${GPUS_PER_NODE}*${NNODES}))
NODE_RANK=0
MASTER_PORT=6000
MASTER_ADDR="10.0.1.2"

# Parallelism variables
TP=8
PP=2
DP=$((${GPU_NUM}/${TP}/${PP}))

# Network size variables
MODEL_SIZE=13

if   [[ ${MODEL_SIZE} == 7 ]];   then HIDDEN_SIZE=4096;  NUM_HEAD=32; NUM_QUERY_GROUP=32; NUM_LAYERS=32; FFN_HIDDEN_SIZE=11008; NORM_EPS=1e-5;
elif [[ ${MODEL_SIZE} == 13 ]];  then HIDDEN_SIZE=5120;  NUM_HEAD=40; NUM_QUERY_GROUP=40; NUM_LAYERS=40; FFN_HIDDEN_SIZE=13824; NORM_EPS=1e-5;
elif [[ ${MODEL_SIZE} == 70 ]];  then HIDDEN_SIZE=8192;  NUM_HEAD=64; NUM_QUERY_GROUP=8;  NUM_LAYERS=80; FFN_HIDDEN_SIZE=28672; NORM_EPS=1e-5;
elif [[ ${MODEL_SIZE} == "tiny" ]]; then HIDDEN_SIZE=128;  NUM_HEAD=4; NUM_QUERY_GROUP=4; NUM_LAYERS=4; FFN_HIDDEN_SIZE=512; NORM_EPS=1e-5;
else echo "invalid MODEL_SIZE: ${MODEL_SIZE}"; exit 1
fi

# base path
BASE_PATH=/workspace
RESULT_SAVE_PATH=/workspace/megatron_train_result
SRC_PATH=/workspace/megatron/pretrain_gpt.py

# log dir & log save paths
LOG_NAME=llama2-${MODEL_SIZE}b_pretrain_WS${WORLD_SIZE}_TP${TP}_PP${PP}
LOG_PATH=${RESULT_SAVE_PATH}/log/${LOG_NAME}/node${NODE_RANK}.log
mkdir -p ${RESULT_SAVE_PATH}/log/${LOG_NAME}

# dataset path
DATA_PATH=${BASE_PATH}/dataset/finetune_dataset/llama-2-13b-hf/alpaca_text_document

# ckpt load path & save path
CKPT_LOAD_PATH=${BASE_PATH}/model_weights/llama2-13b-hf-tp${TP}-pp${PP}/iter_0000001
CKPT_SAVE_PATH=${RESULT_SAVE_PATH}/ckpt/${LOG_NAME}
mkdir -p ${RESULT_SAVE_PATH}/ckpt/

# tokenizer path
TOKENIZER_PATH=${BASE_PATH}/model_weights/llama2-13b-hf/tokenizer.model

# training args
MICRO_BATCH_SIZE=4
GLOBAL_BATCH_SIZE=512
DROP_OUT=0.0
MAX_LR=1e-6
MIN_LR=1e-8
MAX_SEQ_LEN=4096
MAX_POSITION_EMBEDDINGS=4096

# Set training command
LAUNCHER=" \
       torchrun \
       --nproc_per_node ${GPUS_PER_NODE} \
       --nnodes ${NNODES} \
       --node_rank ${NODE_RANK} \
       --master_addr ${MASTER_ADDR} \
       --master_port ${MASTER_PORT} \
       "
       
DISTRIBUTED_ARGS=" \
       --tensor-model-parallel-size ${TP} \
       --pipeline-model-parallel-size ${PP} \
       --distributed-backend nccl \
       --use-distributed-optimizer \
       --sequence-parallel \
       --overlap-grad-reduce \
       "  

NETWORK_SIZE_ARGS=" \
       --num-layers ${NUM_LAYERS} \
       --hidden-size ${HIDDEN_SIZE} \
       --num-attention-heads ${NUM_HEAD} \
       --group-query-attention \
       --num-query-groups ${NUM_QUERY_GROUP} \
       --ffn-hidden-size ${FFN_HIDDEN_SIZE} \
       --position-embedding-type rope \
       --max-position-embeddings ${MAX_POSITION_EMBEDDINGS} \
       --make-vocab-size-divisible-by 1 \
       --norm-epsilon ${NORM_EPS} \
       --normalization RMSNorm \
       --swiglu \
       --untie-embeddings-and-output-weights \
       --use-flash-attn \
       --attention-softmax-in-fp32 \
       "

LOGGING_ARGS=" \
       --log-timers-to-tensorboard \
       --log-validation-ppl-to-tensorboard \
       --log-memory-to-tensorboard \
       --log-interval 1 \
       "

REGULATIZATION_ARGS=" \
       --attention-dropout ${DROP_OUT} \
       --hidden-dropout ${DROP_OUT} \
       --weight-decay 1e-1 \
       --clip-grad 1.0 \
       --adam-beta1 0.9 \
       --adam-beta2 0.95 \
       --adam-eps 1e-8 \
       --no-gradient-accumulation-fusion \
       "
 
TRAINING_ARGS=" \
       --micro-batch-size ${MICRO_BATCH_SIZE} \
       --global-batch-size ${GLOBAL_BATCH_SIZE} \
       --train-iters 200 \
       --disable-bias-linear \
       --no-bias-gelu-fusion \
       --optimizer adam \
       --recompute-activations \
       --recompute-granularity selective \
       "

INITIALIZATION_ARGS=" \
       --seed 2024 \
       --init-method-std 0.01 \
       --initial-loss-scale 4096 \
       "

LEARNING_RATE_ARGS=" \
       --lr ${MAX_LR} \
       --lr-decay-style cosine \
       --lr-warmup-fraction 0.1 \
       --min-lr ${MIN_LR} \
       --weight-decay 1e-1 \
       "

CHECKPOINTING_ARGS=" \
       --load ${CKPT_LOAD_PATH} \
       --finetune \
       
       --no-load-optim \
       --no-load-rng \
       --save ${CKPT_SAVE_PATH} \
       --save-interval 200 \
       "
 
MIXED_PRECISION_ARGS=" \
       --bf16 \
       "
 
VALIDATION_ARGS=" \
       --eval-interval 100 \
       --eval-iters 0 \
       "

DATA_ARGS=" \
       --data-path ${DATA_PATH} \
       --split 100,0,0 \
       --seq-length ${MAX_SEQ_LEN} \
       --num-workers 0 \
       --tokenizer-type Llama2Tokenizer \
       --tokenizer-model ${TOKENIZER_PATH} \
       "
 
CMD="${LAUNCHER} \
       ${SRC_PATH} \
       ${DISTRIBUTED_ARGS} \
       ${NETWORK_SIZE_ARGS} \
       ${LOGGING_ARGS} \
       ${REGULATIZATION_ARGS} \
       ${TRAINING_ARGS} \
       ${INITIALIZATION_ARGS} \
       ${LEARNING_RATE_ARGS} \
       ${CHECKPOINTING_ARGS} \
       ${MIXED_PRECISION_ARGS} \
       ${VALIDATION_ARGS} \
       ${DATA_ARGS} \
       ${MOE_ARGS} \
       "
echo ${CMD}
${CMD} 2>&1 | tee ${LOG_PATH}
