import json
import sys
from collections import defaultdict
from pathlib import Path

# Mapping from local types to FHIR data types
TYPE_MAPPING = {
    "string": "string",
    "Int64": "integer",
    "double": "decimal",
    "boolean": "boolean"
}

def to_pascal_case(s):
    return ''.join(word.capitalize() for word in s.replace('_', ' ').replace('.', ' ').split())

def nest_fields(fields):
    tree = defaultdict(dict)
    for path, ftype in fields.items():
        parts = path.split('.')
        d = tree
        for part in parts[:-1]:
            d = d.setdefault(part, {})
        d[parts[-1]] = ftype
    return tree

def create_structure_definition(struct_id, fields, base_url, is_root=False):
    struct_def = {
        "resourceType": "StructureDefinition",
        "id": struct_id,
        "url": f"http://hl7.org/fhir/StructureDefinition/{struct_id}" if is_root else base_url + struct_id,
        "name": struct_id,
        "status": "draft",
        "fhirVersion": "4.0.1",
        "kind": "logical",
        "abstract": True,
        "type": struct_id,
        "snapshot": {
            "element": [
                {
                    "id": struct_id,
                    "path": struct_id,
                    "definition": f"{struct_id} definition",
                    "min": 0,
                    "max": 1
                }
            ]
        }
    }

    # Root-specific extension
    if is_root:
        struct_def["extension"] = [{
            "url": "http://hl7.org/fhir/StructureDefinition/elementdefinition-namespace",
            "valueUri": "http://ahdbservices.it/fhir"
        }]

    elements = struct_def["snapshot"]["element"]
    for field, ftype in fields.items():
        elem = {
            "id": f"{struct_id}.{field}",
            "path": f"{struct_id}.{field}",
            "definition": f"{field} field",
            "min": 0,
            "max": 1,
            "type": []
        }
        if isinstance(ftype, dict):
            sub_struct_id = struct_id + to_pascal_case(field)
            elem["type"].append({"code": f"{base_url}{sub_struct_id}"})
        else:
            elem["type"].append({"code": TYPE_MAPPING.get(ftype, "string")})
        elements.append(elem)

    return struct_def

def generate_definitions(struct_id, fields, base_url, is_root=True):
    definitions = {}
    flat_fields = {}
    for key, value in fields.items():
        if isinstance(value, dict):
            nested_struct_id = struct_id + to_pascal_case(key)
            nested_defs = generate_definitions(nested_struct_id, value, base_url, is_root=False)
            definitions.update(nested_defs)
            flat_fields[key] = value
        else:
            flat_fields[key] = value

    struct_def = create_structure_definition(struct_id, flat_fields, base_url, is_root=is_root)
    definitions[struct_id] = struct_def
    return definitions

def main():
    if len(sys.argv) != 2:
        print("Usage: python generate_structuredefs.py <STUDY_NAME>")
        sys.exit(1)

    study_name = sys.argv[1]
    base_url = f"http://ahdbservices.it/fhir/StructureDefinition/"

    with open(f"studies/{study_name}/01-refinement/scripts/data_cleaning.types.json", "r") as f:
        source_data = json.load(f)

    top_key = list(source_data.keys())[0]
    nested_fields = nest_fields(source_data[top_key])
    struct_id = to_pascal_case(top_key)
    definitions = generate_definitions(struct_id, nested_fields, base_url)

    output_dir = Path(f"studies/{study_name}/02-mapping/structures/generated")
    output_dir.mkdir(parents=True, exist_ok=True)

    for struct_id, struct_def in definitions.items():
        file_path = output_dir / f"{struct_id}.json"
        with open(file_path, "w") as f:
            json.dump(struct_def, f, indent=2)

    print(f"✅ Generated {len(definitions)} StructureDefinition files in {output_dir}")

if __name__ == "__main__":
    main()
