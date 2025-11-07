from fastapi import FastAPI

app = FastAPI()

@app.get("/healthz")
def healthz():
    return {"ok": True}

@app.get("/hello")
def hello(name: str = "world"):
    return {"message": f"Hello, {name} from Moji Tech Solutions!"}
