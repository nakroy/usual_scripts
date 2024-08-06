# This is a script for using modelscope to download files from modelscope
# python requirement: pip install -U modelscope

#########################################################################################################################################################
# Usage Explanation: 
# -------------------------------------------------------------------------------------------------------------------------------------------------------
# download model from modelscope        :  bash modelscope_download.sh -m [remote-model-dir] -l [local-save-dir]
# -------------------------------------------------------------------------------------------------------------------------------------------------------
# download dataset from modelscope      :  bash modelscope_download.sh -d [remote-dataset-dir] -l [local-save-dir]
# -------------------------------------------------------------------------------------------------------------------------------------------------------
# download model of specific revision   :  bash modelscope_download.sh -m [remote-model-dir] -r [revision] -l [local-save-dir]
# -------------------------------------------------------------------------------------------------------------------------------------------------------
# command usage help                    :  bash modelscope_download.sh -h
# -------------------------------------------------------------------------------------------------------------------------------------------------------
#########################################################################################################################################################
# Usage Examples:
# -------------------------------------------------------------------------------------------------------------------------------------------------------
# download Qwen1.5-14B-Chat model       :  bash modelscope_download.sh -m qwen/Qwen1.5-14B-Chat -l qwen1_5-14b-chat 
# -------------------------------------------------------------------------------------------------------------------------------------------------------
# download tatsu-lab-alpaca dataset     :  bash modelscope_download.sh -d angelala00/tatsu-lab-alpaca -l alpaca
# -------------------------------------------------------------------------------------------------------------------------------------------------------
# download stable diffusion v1.0.3      :  bash modelscope_download.sh -m iic/multi-modal_chinese_stable_diffusion_v1.0 -r v1.0.3 -l chinese_sd_v1.0.3
# -------------------------------------------------------------------------------------------------------------------------------------------------------
############################################################################################################################################################################


# initialzing arguments
model=""
dataset=""
revision=""
local_dir=""

# command usage help
show_help() {
    echo "Usage: $0 [-m model] -l local_dir"
    echo
    echo "Options:"
    echo "  -m    Model remote directory (when download model file required)"
    echo "  -d    Dataset remote directory (when download dataset file required)"
    echo "  -r    Revision of the model or dataset, use branch name or tag name (optional)"
    echo "  -l    Local save directory (required)"
    echo "  -h    Show this help message"
}


while getopts ":m:d:r:l:h" opt; do
  case $opt in
    m) model="$OPTARG"
    ;;
    d) dataset="$OPTARG"
    ;;
    r) revision="$OPTARG"
    ;;
    l) local_dir="$OPTARG"
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

# check arguments conflicts
if [ -n "$model" ] && [ -n "$dataset" ]; then
  echo "Error: Both model (-m) and dataset (-d) cannot be specified simultaneously."
  show_help
  exit 1
fi

# check required arguments
if { [ -z "$model" ] && [ -z "$dataset" ]; } || [ -z "$local_dir" ]; then
  echo "Error: Model remote directory (-m) or Dataset remote directory (-d) and local directory (-l) are required."
  show_help
  exit 1
fi

# Set the command and parameters based on input
if [ -n "$model" ]; then
    download_type="--model"
    remote_dir="$model"
elif [ -n "$dataset" ]; then
    download_type="--dataset"
    remote_dir="$dataset"
fi

# check whether select revision
if [ -n "$revision" ]; then
    revision_args="--revision $revision"
else
    revision_args=""
fi

#  execute modelscope command
while true; do
     # read all file names under the local folder, and output the file name as a variable exclude_files
    if [ -d "$local_dir" ]; then
        exclude_files=$(ls "$local_dir" | tr '\n' ' ')
    else
        exclude_files=""
    fi
    
    echo "Downloading $remote_dir..."
    if modelscope download $download_type "$remote_dir" $revision_args --local_dir "$local_dir" --exclude $exclude_files; then
        echo "$remote_dir download completed successfully."
        break
    else
        echo "$remote_dir download failed. Retrying in 5 seconds..."
        sleep 5
    fi
done