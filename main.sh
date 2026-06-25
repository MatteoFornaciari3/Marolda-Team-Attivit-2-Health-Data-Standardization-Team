#!/usr/bin/env sh
set -e

STUDY_NAME=${1:-"weargaitpd"}

BASE_DIR=$(dirname "$0")
STUDY_DIR="$BASE_DIR/studies/$STUDY_NAME"

INPUT_DIR="$STUDY_DIR/00-input"
REFINEMENT_DIR="$STUDY_DIR/01-refinement"
MAPPING_DIR="$STUDY_DIR/02-mapping"
PUBLISHING_DIR="$STUDY_DIR/03-publishing"

SCRIPTS_DIR="$REFINEMENT_DIR/scripts"
INDEX_DIR="$MAPPING_DIR/indexes"
RESOURCES_DIR="$MAPPING_DIR/resources"
BUNDLES_DIR="$PUBLISHING_DIR/bundles"

FHIR_MATCHBOX_URL=http://localhost:8080/matchboxv3/fhir
FHIR_SERVER_URL=http://localhost:8081/fhir

# Upload StructureDefinitions
find "$MAPPING_DIR/structures" -type f | fpu-resource-uploader \
    --fhir-server "$FHIR_MATCHBOX_URL" \
    --resource-type StructureDefinition

# Upload FHIR Resources
for TYPE in $(find "$RESOURCES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;); do
    find "$RESOURCES_DIR/$TYPE" -type f | fpu-resource-uploader \
        --fhir-server "$FHIR_SERVER_URL" \
        --resource-type "$TYPE"
done

# Upload Mappings
find "$MAPPING_DIR/mappings" -type f | fpu-mappings-uploader \
    --fhir-server "$FHIR_MATCHBOX_URL"

# Data Cleaning
PYDEVD_DISABLE_FILE_VALIDATION=1 python -m jupyter nbconvert --to html \
    --execute "$SCRIPTS_DIR/data_cleaning.ipynb" \
    --stdout > "$REFINEMENT_DIR/data_cleaning.out.html"

# CSV to JSON
fpu-csv-to-json \
    --output-directory "$REFINEMENT_DIR/json" \
    --index-value "$(cat $INDEX_DIR/csv-to-json-index.json)" \
    --types-file "$SCRIPTS_DIR/data_cleaning.types.json"

# FHIR Conversion
fpu-conversion \
    --matchbox-server "$FHIR_MATCHBOX_URL" \
    --index-value "$(cat $INDEX_DIR/conversion-index.json)" \
    --output-directory "$BUNDLES_DIR" \
    --executor-threads 20

# Send Bundles to FHIR Server
for BUNDLE in "$BUNDLES_DIR"/*ToBundle_*.json; do
    fpu-bundle-sender \
        --fhir-server-url "$FHIR_SERVER_URL" \
        --executor-threads 4 \
        --files "$BUNDLE"
done

# Export resource from FHIR server
python shared/bulk-data-export.py $FHIR_SERVER_URL $PUBLISHING_DIR/export