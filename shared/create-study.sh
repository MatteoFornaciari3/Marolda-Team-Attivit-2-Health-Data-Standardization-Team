#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <study_name>"
  exit 1
fi

STUDY_NAME=$1
STUDY_DIR="studies/$STUDY_NAME"

if [ -d "$STUDY_DIR" ]; then
  echo "Study '$STUDY_NAME' already exists at $STUDY_DIR. Aborting."
  exit 1
fi

echo "Creating new study structure at $STUDY_DIR..."

# Create directory structure based on ETL pipeline
mkdir -p "$STUDY_DIR"/{00-input,01-refinement/{scripts,clean,json},02-mapping/{mappings,structures,resources,indexes},03-publishing/{bundles,export},04-validation}

# Add .gitignore to input/refinement/publishing to keep folders in Git
for SUBDIR in 00-input 01-refinement/clean 01-refinement/json 03-publishing/bundles 03-publishing/export; do
  echo -e "*\n!.gitignore" > "$STUDY_DIR/$SUBDIR/.gitignore"
done

echo -e "generated/*" > "$STUDY_DIR/02-mapping/structures/.gitignore"

# Create placeholder files
touch "$STUDY_DIR/01-refinement/scripts/data_cleaning.ipynb"
touch "$STUDY_DIR/01-refinement/scripts/data_cleaning.types.json"
touch "$STUDY_DIR/01-refinement/scripts/data_cleaning.whitelist.json"
touch "$STUDY_DIR/02-mapping/indexes/conversion-index.json"
touch "$STUDY_DIR/02-mapping/indexes/csv-to-json-index.json"
touch "$STUDY_DIR/04-validation/validation-queries-test.ipynb"

# Optional top-level .gitignore for intermediate/derived data
cat <<EOF > "$STUDY_DIR/.gitignore"
/01-refinement/clean/*
/01-refinement/json/*
/01-refinement/data_cleaning.out.html
/03-publishing/bundles/*
/04-validation/output/*
/02-mapping/structures/generated/*
EOF

# Minimal valid placeholder content
echo "{}" > "$STUDY_DIR/01-refinement/scripts/data_cleaning.types.json"
echo "{}" > "$STUDY_DIR/01-refinement/scripts/data_cleaning.whitelist.json"
echo "[]" > "$STUDY_DIR/02-mapping/indexes/csv-to-json-index.json"
echo "[]" > "$STUDY_DIR/02-mapping/indexes/conversion-index.json"

# Minimal valid Jupyter notebook that executes without errors
cat <<EOF > "$STUDY_DIR/01-refinement/scripts/data_cleaning.ipynb"
{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Empty data cleaning step\\n",
    "print('Data cleaning: nothing to clean')"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "name": "python",
   "version": ""
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
EOF

python shared/generate-structuredefs.py $STUDY_NAME

echo "Study '$STUDY_NAME' has been scaffolded successfully under $STUDY_DIR."