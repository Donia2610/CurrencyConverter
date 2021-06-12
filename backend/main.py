from flask import Flask,render_template,request
import requests
from werkzeug.utils import redirect
from datetime import datetime

app = Flask(__name__)


API_KEY = '0RUUQQLZVNZBYJTK'
mydata =[] 
@app.route('/',methods=['GET','POST'])
def home():
    if request.method == 'POST':
        amount = request.form['amount']
        amount = float(amount)
        from_c = request.form['from_c']
        to_c = request.form['to_c']

        url = 'https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency={}&to_currency={}&apikey={}'.format(from_c,to_c,API_KEY)
        response = requests.get(url=url).json()
        rate = response['Realtime Currency Exchange Rate']['5. Exchange Rate']
        rate = float(rate)
        result = rate * amount

        from_c_code = response['Realtime Currency Exchange Rate']['1. From_Currency Code']
        from_c_name = response['Realtime Currency Exchange Rate']['2. From_Currency Name']
        to_c_code = response['Realtime Currency Exchange Rate']['3. To_Currency Code']
        to_c_name = response['Realtime Currency Exchange Rate']['4. To_Currency Name']
        time = response['Realtime Currency Exchange Rate']['6. Last Refreshed']

        data = dict()
        data[result]=round(result,2)
        data[amount]=amount
        data[from_c_code]=from_c_code
        data[from_c_name]=from_c_name
        data[to_c_code]=to_c_code
        data[to_c_name]=to_c_name
        data[time]=time
		
        time_now = datetime.now()
        time2 = time_now.strftime("%H:%M:%S")
        unit= [time2, amount,from_c_name,to_c_name, to_c_code, round(result,2)]
        mydata.append(unit)

        front_end_address = 'http://' + (requests.get("http://169.254.169.254/latest/meta-data/public-ipv4").content).decode('utf-8') + ':7000/'
        req = requests.post(front_end_address, json=data)
        return redirect(front_end_address, code=302) 
    else: 
        return redirect(front_end_address, code=302)
       

@app.route("/Auti/", methods=["POST", "GET"])
def Auti():
    all_data = dict()
    front_end_address2 = 'http://' + (requests.get("http://169.254.169.254/latest/meta-data/public-ipv4").content).decode('utf-8') + ':6000/'
    all_data["data"] = mydata
    req = requests.post(front_end_address2, json=all_data)
    return redirect(front_end_address2, code=302)

if __name__ == "__main__":
    app.run(debug= True)
