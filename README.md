## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/clinical-data-to-fhir-pipeline.git
cd clinical-data-to-fhir-pipeline
```

### 2. Set Up Python Environment

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 3. Install FHIR Pipeline Utils

Install and configure [FHIR Pipeline Utils](https://gitlab.com/almahealthdb/fhir-pipeline-utils#usage) as per their documentation.

### 4. Start the Required Services

```bash
docker-compose up
```

This starts:

* A [HAPI FHIR Server](https://hapifhir.io/)
* A [Matchbox Server](https://github.com/ahdis/matchbox) for resource transformation


## Running the Pipeline

```bash
./main.sh weargaitpd
```

This script will:

1. run the data cleaning/preprocessing notebook
2. Convert cleaned CSVs into JSON
3. Upload `StructureDefinitions` to Matchbox
4. upload base FHIR resources to the FHIR server
5. Upload mapping definitions to Matchbox
6. Transform the JSON data into FHIR Bundles
7. Send the Bundles to the FHIR server

## License

MIT License. See [LICENSE](./LICENSE).
