#!/usr/bin/env sh
# pre-commit.sh

BRANCH_NAME=$(git branch | grep '*' | sed 's/* //')
STASH_NAME="pre-commit.sh: $(date +%s) on $BRANCH_NAME"

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

stash=0
# Stash all changes in the working directory so we test only commit files
if git stash save -u -k -q $STASH_NAME; then
    echo "${YELLOW}Stashed changes as:${NC} ${STASH_NAME}\n\n"
    stash=1
fi

echo "${GREEN} Testing commit\n\n"

cargo doc --no-deps &&
cargo build &&
# Build and test without profiler
cargo test --all

# Capture exit code from tests
status=$?

# Revert stash if changes were stashed to restore working directory files
if [ "$stash" -eq 1 ]
then
    if git stash pop -q; then
        echo "\n\n${GREEN}Reverted stash command${NC}"
    else
        echo "\n\n${RED}Unable to revert stash command${NC}"
    fi
fi

# Inform user of build failure
if [ "$status" -ne "0" ]
then
    echo "${RED}Build failed:${NC} if you still want to commit use ${BOLD}'--no-verify'${NC}"
fi

# Exit with exit code from tests, so if they fail, prevent commit
exit $status
