# 1. Ensure you are in your detached HEAD state (optional, just for safety)
git checkout --detach HEAD

# 2. Force update the 'main' branch to point to your current commit
git branch -f main HEAD

# 3. Switch to the updated 'main' branch
git checkout main



git log --graph --oneline --all