#!/usr/bin/env bash

set -e


cd /opt/vstsagent
source ./env.sh

VSTS_TOKEN_FILE=.vststoken
echo -n $VSTS_TOKEN > $VSTS_TOKEN_FILE
unset VSTS_TOKEN # each env var is exposed in TFS UI

cleanup() {
  ./bin/Agent.Listener remove --unattended --auth PAT --token $(cat $VSTS_TOKEN_FILE)
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 ./bin/Agent.Listener configure --unattended \
                                                                       --agent "$VSTS_AGENT_NAME-$(hostname)" \
                                                                       --url $VSTS_URL \
                                                                       --auth PAT \
                                                                       --token $(cat $VSTS_TOKEN_FILE) \
                                                                       --pool $VSTS_POOL \
                                                                       --replace \
                                                                       --acceptTeeEula & wait $!

# `exec` the node runtime so it's aware of TERM and INT signals
# AgentService.js understands how to handle agent self-update and restart
#exec ./externals/node/bin/node ./bin/AgentService.js interactive
./externals/node/bin/node ./bin/AgentService.js interactive
