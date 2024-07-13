# This is a script for using huggingface-cli to download files from huggingface
# python requirement: pip install -U huggingface-hub

##################################################################################
# Usage Explanation: 
# --------------------------------------------------------------------------------
# download model from huggingface     :  bash hf_download.sh -r [remote-model-dir] -l [local-save-dir]
# --------------------------------------------------------------------------------
# download dataset from huggingface   :  bash hf_download.sh -r [remote-dataset-dir] -l [local-save-dir] -y [repo_type]
# --------------------------------------------------------------------------------
# download model needed token         :  bash hf_download.sh -r [remote-model-dir] -l [local-save-dir] -t [access tokens]
# --------------------------------------------------------------------------------
# command usage help                  :  bash hf_download.sh -h
# --------------------------------------------------------------------------------
##################################################################################
# Usage Examples:
# --------------------------------------------------------------------------------
# download Qwen1.5-14B-Chat model     :  bash hf_download.sh -r Qwen/Qwen1.5-14B-Chat -l qwen1_5-14b-chat 
# --------------------------------------------------------------------------------
# download tatsu-lab/alpaca dataset   :  bash hf_download.sh -r tatsu-lab/alpaca -l alpaca -y dataset
# --------------------------------------------------------------------------------
# download meta-Llama3-Instruct model :  bash hf_download.sh -r meta-llama/Meta-Llama-3-8B-Instruct -l llama3-8b-instruct -t hf****
# Notes: hf**** is your huggingface access tokens
# --------------------------------------------------------------------------------
##################################################################################

# use mirror address to speed up for Chinese users
export HF_ENDPOINT=https://hf-mirror.com

# initialzing arguments
token=""
remote_dir=""
local_dir=""
repo_type=""

# command usage help
show_help() {
    echo "Usage: $0 [-t token] -r remote_dir -l local_dir [-y repo_type]"
    echo
    echo "Options:"
    echo "  -t    Token for authentication (optional)"
    echo "  -r    Remote directory (required)"
    echo "  -l    Local directory (required)"
    echo "  -y    Repository type, e.g., 'dataset' (optional)"
    echo "  -h    Show this help message"
}


while getopts ":t:r:l:y:h" opt; do
  case $opt in
    t) token="$OPTARG"
    ;;
    r) remote_dir="$OPTARG"
    ;;
    l) local_dir="$OPTARG"
    ;;
    y) repo_type="$OPTARG"
    ;;
    h) show_help
       exit 0
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        show_help
        exit 1
    ;;
  esac
done

# check required arguments
if [ -z "$remote_dir" ] || [ -z "$local_dir" ]; then
  echo "Error: Remote directory (-r) and local directory (-l) are required."
  show_help
  exit 1
fi

# construct token argument
if [ -n "$token" ]; then
    token_type_arg="--token $token"
else
    token_type_arg=""
fi

# construct repo_type argument
if [ "$repo_type" == "dataset" ]; then
    repo_type_arg="--repo-type dataset"
else
    repo_type_arg=""
fi

#  execute huggingface-cli command
while true; do
     # read all file names under the local folder, and output the file name as a variable exclude_files
    if [ -d "$local_dir" ]; then
        exclude_files=$(ls "$local_dir" | tr '\n' ' ')
    else
        exclude_files=""
    fi
    
    if huggingface-cli download $token_type_arg $repo_type_arg --resume-download "$remote_dir" --local-dir "$local_dir" --exclude $exclude_files --local-dir-use-symlinks False; then
        echo "Download finished"
        break
    else
        echo "Download interrupted, waiting for next retry"
        sleep 5  # waiting for next retry in 5 seconds
    fi
done
