from flask import Flask, render_template, request, jsonify
import requests

app = Flask(__name__)
backend_data =[]
@app.route("/", methods=["POST", "GET"])
def Auti():
    global backend_data
    if request.method == "POST":
        json_request = request.get_json(force=True)
        backend_data = json_request["data"]
    return render_template("index.html", data=backend_data)



if __name__ == "__main__":
    app.run(host = "0.0.0.0", debug=True)
