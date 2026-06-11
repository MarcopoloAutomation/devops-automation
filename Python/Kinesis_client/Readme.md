Kinesis Toolkit

Self-contained pieces that fit together:

kinesis_client.py — minimal Kinesis produce/consume on boto3

app.py — FastAPI service exposing /health, /produce, /consume

health_check.py — polls an HTTP endpoint on an interval, logs UP/DOWN + latency to a file

The health checker is meant to poll the FastAPI /health, but it works against any URL.



Requirements
Python 3.9+

pip install -r requirements.txt (the bottom of requirements.txt like pytest, moto, httpx is test-only)

Kinesis client

Reads config from env:

AWS_REGION (default: us-east-1)

KINESIS_ENDPOINT_URL — set this for localstack, leave unset for real AWS

KINESIS_STREAM — used by the FastAPI app (default: demo-stream)

# Produce a message
python kinesis_client.py produce demo-stream '{"hello":"world"}'

# Consume messages
python kinesis_client.py consume demo-stream


produce() does a single put_records and returns the failed-record count.
consume() polls every shard once and returns raw byte payloads. It is deliberately simple — no checkpointing, no resharding handling. For production-grade continuous consumption use the KCL; this is for scripts, demos and tests.

FastAPI service

# Start the FastAPI app
uvicorn app:app --reload

# Main endpoints details:
# GET  /health           -> {"status":"ok"}
# POST /produce          -> body {"data": {...}}  puts one record on the stream
# GET  /consume?limit=10 -> reads back recent records


Point it at localstack by exporting KINESIS_ENDPOINT_URL=http://localhost:4566 before starting uvicorn, and make sure the stream named by KINESIS_STREAM exists.

Health check

chmod +x health_check.py

# poll local FastAPI /health forever, every 5s
./health_check.py

# poll a specific URL, 10 times, 2s apart, custom log file
./health_check.py --url [http://api.internal/health](http://api.internal/health) --count 10 --interval 2 --logfile /var/log/hc.log


Flags: --url, --interval, --count (0=forever), --timeout, --logfile.

Up responses log at INFO, failures (non-2xx or connection/timeout errors) at WARNING. Log line format:

2026-06-11 20:48:07,921 INFO  http://localhost:8000/health UP 200 9.0ms
2026-06-11 20:48:12,930 WARNING http://localhost:8000/health DOWN HTTPConnectionError(...) 3001.2ms


Tests

pytest -v


Kinesis is mocked with moto (no AWS account or network needed); HTTP is mocked with monkeypatch.

Coverage:

produce/consume round-trip, plus str/bytes payloads

FastAPI /health, and /produce -> /consume round-trip

health check up path, down path, and that the logger writes to file

Expected output: 7 passed

Notes

consume() uses TRIM_HORIZON by default (reads from the oldest available record).

The FastAPI /produce returns HTTP 502 if Kinesis reports any failed records.

No credentials are handled by the code — boto3 resolves them the usual way (env vars, ~/.aws/credentials, instance role).