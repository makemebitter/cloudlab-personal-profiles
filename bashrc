eval `ssh-agent` &> /dev/null
ssh-add ~/.ssh/prj_key &> /dev/null
export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
shopt -s histappend                      # append to history, dont overwrite it
# Save and reload the history after each command finishes
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
export CUDA_HOME=/usr/local/cuda-11.3
export PATH=$PATH:$CUDA_HOME/bin
