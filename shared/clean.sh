#!/usr/bin/env sh

STUDY_NAME=${1:-"motu"}
STUDY_DIR="studies/$STUDY_NAME"

echo "Cleaning generated files in $STUDY_NAME"

rm -f $STUDY_DIR/01-refinement/clean/*
rm -f $STUDY_DIR/01-refinement/json/*.json
rm -f $STUDY_DIR/01-refinement/data_cleaning.out.html
rm -f $STUDY_DIR/03-publishing/bundles/*.json
rm -f $STUDY_DIR/03-publishing/export/*
rm -f $STUDY_DIR/02-mapping/structures/generated/*