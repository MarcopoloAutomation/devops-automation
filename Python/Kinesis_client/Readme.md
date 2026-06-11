# Kinesis Toolkit

Self-contained pieces that fit together:
* `kinesis_client.py` — minimal Kinesis produce/consume on boto3
* `app.py` — FastAPI service exposing /health, /produce, /consume
* `health_check.py` — polls an HTTP endpoint on an interval, logs UP/DOWN + latency to a file

The health checker is meant to poll the FastAPI `/health`, but it works against any URL.

## Requirements
* Python 3.9+
* `pip install -r requirements.txt` (the bottom of requirements.txt like pytest, moto, httpx is test-only)

## Kinesis client
Reads config from env:
* `AWS_REGION` (default: us-east-1)
* `KINESIS_ENDPOINT_URL` — set this for localstack, leave unset for real AWS
* `KINESIS_STREAM` — used by the FastAPI app (default: demo-stream)

```bash
# Produce a message
python kinesis_client.py produce demo-stream '{"hello":"world"}'

# Consume messages
python kinesis_client.py consume demo-stream