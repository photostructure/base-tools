#!/bin/bash

# Extract all unique actions used in workflows
# Support both .yml and .yaml files
ACTIONS=$(grep -ohP 'uses: \K[\w-]+/[\w-]+(?=@)' .github/workflows/*.{yml,yaml} 2>/dev/null | sort -u)

# Get all workflow files
WORKFLOW_FILES=$(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null)

for action in $ACTIONS; do
  echo "Checking $action..."

  # Special case for GitHub's official actions
  if [[ "$action" == actions/* ]]; then
    echo "⚙️ Handling GitHub's official actions ($action)..."

    # Get latest tag (e.g., 'v4.1.0')
    LATEST_TAG=$(gh api repos/$action/releases/latest --jq '.tag_name' 2>/dev/null)

    if [ -n "$LATEST_TAG" ]; then
      # Get commit SHA for the release tag
      SHA=$(gh api repos/$action/git/ref/tags/$LATEST_TAG --jq '.object.sha' 2>/dev/null)

      if [[ -n "$SHA" && "$SHA" != "null" ]]; then
        # Iterate through each workflow file for the sed command
        for file in $WORKFLOW_FILES; do
          sed -i "s|uses: $action@[^ ]*|uses: $action@$SHA|g" "$file"
        done
        echo "✅ Updated $action to commit SHA: $SHA"
      else
        echo "⚠️ Could not fetch commit SHA for $action. Skipping."
      fi
    else
      echo "⚠️ Could not fetch latest release for $action. Skipping."
    fi

  else
    # Standard case for all other actions (including docker/...)
    echo "🔍 Handling normal actions ($action)..."

    # Fetch latest release tag (Docker actions require this!)
    LATEST_TAG=$(gh api repos/$action/releases/latest --jq '.tag_name' 2>/dev/null)

    if [ -n "$LATEST_TAG" ]; then
      # Get commit SHA for the release tag
      SHA=$(gh api repos/$action/git/ref/tags/$LATEST_TAG --jq '.object.sha' 2>/dev/null)

      if [[ -n "$SHA" && "$SHA" != "null" ]]; then
        # Iterate through each workflow file for the sed command
        for file in $WORKFLOW_FILES; do
          sed -i "s|uses: $action@[^ ]*|uses: $action@$SHA|g" "$file"
        done
        echo "✅ Updated $action to commit SHA: $SHA"
      else
        echo "⚠️ Could not fetch commit SHA for $action. Skipping."
      fi
    else
      echo "⚠️ Could not fetch latest release for $action. Skipping."
    fi
  fi
done

echo "🎉 All possible actions updated!"
