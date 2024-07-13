#!/bin/bash

# use mirror address to speed up
export HF_ENDPOINT=https://hf-mirror.com

# get input params
remote_dir="$1"
local_dir="$2"
repo_type="$3"

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
    if huggingface-cli download --token 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 $repo_type_arg --resume-download "$remote_dir" --local-dir "$local_dir" --exclude $exclude_files --local-dir-use-symlinks False; then
        echo "download finish"
        break
    else
        echo "download interrupt, waiting for next retry"
        sleep 5  # waiting for next retry in 5s
    fi
done
