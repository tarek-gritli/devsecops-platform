from fastapi import FastAPI, Response
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()
Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/fail")
def fail() -> Response:
    return Response(status_code=500, content="synthetic failure for SLO demonstration")
