import flask
from flask import Flask, render_template, request
import requests

app = Flask(__name__)
backend_data = dict() 
@app.route("/", methods=["POST", "GET"])
def index():
    #adresses with the aws ec2 public ip
    first_address = "http://" + (requests.get("http://169.254.169.254/latest/meta-data/public-ipv4").content).decode('utf-8') + ":5000"
    second_address = "http://" + (requests.get("http://169.254.169.254/latest/meta-data/public-ipv4").content).decode('utf-8') + ":5000/Auti/"

    #updating the home page 
    if request.method == "POST":
        global backend_data
        json_request = request.get_json(force=True)
        backend_data =json_request
    return render_template("home.html", data=backend_data, url = first_address, url2 = second_address)








if __name__ == "__main__":
    app.run(host = "0.0.0.0", debug=True)
