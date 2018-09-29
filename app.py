from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello World!"

@app.route("/health")
def health():
    return "WORKING"

if __name__ == "__main__":
    app.run()
