# This is a script for using huggingface-cli to download files from huggingface
# python requirement:
# pip install -U huggingface-hub

# usage explanation: 
# download model from huggingface: bash hf_download.sh [remote-model-dir] [local-save-dir]
# download dataset from huggingface: bash hf_download.sh [remote-dataset-dir] [local-save-dir] [repo_type]
# download model needed token from huggingface: bash hf_download.sh [remote-model-dir] [local-save-dir] [huggingface user access tokens]

# usage example:
# download Qwen1.5-14B-Chat model from huggingface: bash hf_download.sh Qwen/Qwen1.5-14B-Chat qwen1_5-14b-chat
# download tatsu-lab/alpaca dataset from huggingface: bash hf_download.sh tatsu-lab/alpaca alpaca dataset
# download meta-Llama3-Instruct model from huggingface: bash hf_download.sh meta-llama/Meta-Llama-3-8B-Instruct llama3-8b-instruct hf****
# where hf**** is your huggingface access tokens


# use mirror address to speed up for Chinese users
export HF_ENDPOINT=https://hf-mirror.com

# get input params
remote_dir="$1"
local_dir="$2"
repo_type="$3"
token="$4"

# construct token type argument
if [ "$token" != "" ]; then
    token_type_arg="--token {$token}"
else
    token_type_arg=""
fi

# construct repo type argument
if [ "$repo_type" == "dataset" ]; then
    repo_type_arg="--repo-type dataset"
else
    repo_type_arg=""
fi

# execute huggingface-cli download command
while true; do
    # read all file names under the local folder, and output the file name as a variable exclude_files
    exclude_files=$(ls "$local_dir" | tr '\n' ' ')
    if huggingface-cli download $token_type_arg $repo_type_arg --resume-download "$remote_dir" --local-dir "$local_dir" --exclude $exclude_files --local-dir-use-symlinks False; then
        echo "download finish"
        break
    else
        echo "download interrupt, waiting for next retry"
        sleep 5  # waiting for next retry in 5s
    fi
done
