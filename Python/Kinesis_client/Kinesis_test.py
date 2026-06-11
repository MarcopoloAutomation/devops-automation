import json
import logging
import os
import pytest
from fastapi.testclient import TestClient
from moto import mock_aws
import boto3

# Moto needs fake AWS credentials before importing stream modules
os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_DEFAULT_REGION"] = "us-east-1"

import app as app_module
import health_check
import kinesis_client

STREAM = "demo-stream"


@pytest.fixture
@mock_aws
def kinesis():
    # I used mock_aws to set mock runs for the entire lifecycle of the fixture
    client = boto3.client("kinesis", region_name="us-east-1")
    client.create_stream(StreamName=STREAM, ShardCount=1)
    return client


# kinesis_client

def test_produce_and_consume(kinesis):
    failed = kinesis_client.produce(STREAM, [{"a": 1}, {"a": 2}], client=kinesis)
    assert failed == 0

    payloads = kinesis_client.consume(STREAM, client=kinesis)
    decoded = [json.loads(p) for p in payloads]
    assert {"a": 1} in decoded
    assert {"a": 2} in decoded


def test_produce_accepts_str_and_bytes(kinesis):
    failed = kinesis_client.produce(STREAM, ["plain", b"bytes"], client=kinesis)
    assert failed == 0
    
    payloads = [p.decode() for p in kinesis_client.consume(STREAM, client=kinesis)]
    assert "plain" in payloads
    assert "bytes" in payloads


# FastAPI app

def test_health_endpoint():
    client = TestClient(app_module.app)
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_produce_then_consume_via_api(kinesis, monkeypatch):
    # exchanging get_client from module to mocked
    monkeypatch.setattr(kinesis_client, "get_client", lambda: kinesis)
    client = TestClient(app_module.app)

    r = client.post("/produce", json={"data": {"hello": "world"}})
    assert r.status_code == 200
    assert r.json()["status"] == "sent"

    r = client.get("/consume", params={"limit": 5})
    body = r.json()
    assert body["count"] >= 1
    assert any("hello" in rec for rec in body["records"])


# health_check

def test_check_up(monkeypatch):
    
    class MockResponse:
        ok = True
        status_code = 200

    monkeypatch.setattr(health_check.requests, "get", lambda *a, **k: MockResponse())
    ok, info, latency = health_check.check("http://x/health", 1.0)
    
    assert ok is True
    assert info == 200
    assert latency >= 0


def test_check_down(monkeypatch):
    def _boom(*a, **k):
        raise health_check.requests.ConnectionError("refused")

    monkeypatch.setattr(health_check.requests, "get", _boom)
    ok, info, latency = health_check.check("http://x/health", 1.0)
    
    assert ok is False
    assert "refused" in info


def test_logger_writes_to_file(tmp_path):
    logfile = tmp_path / "hc.log"
    log = health_check.setup_logger(str(logfile))
    log.info("hello %s", "world")
    
    logging.shutdown()
    assert "hello world" in logfile.read_text()