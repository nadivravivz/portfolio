import os
import json
import pymongo
from flask import Flask, render_template, request, jsonify
import datetime, logging, sys, json_logging, flask

app = Flask(__name__)

json_logging.init_flask(enable_json=True)
json_logging.init_request_instrument(app)
logger = logging.getLogger("test-logger")
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler(sys.stdout))

mongodb_client = pymongo.MongoClient(os.environ['MONGODBURL'])
db = mongodb_client['cooldb']
collection = db['coolcollection']

@app.route('/')
def hello():
    return "Welcome to Raviv website"

@app.route('/add')
def add():
    return render_template('index.html')

@app.route('/add', methods=['GET', 'POST'])
def adds():
    name = request.form['first']
    lastname = request.form['last']
    age = request.form['age']
    collection.insert_one({'Name': name, 'Last Name': lastname, 'Age': age})
    return render_template('index.html')
    
@app.route('/get')
def get():
    documents = collection.find()
    response = []
    for document in documents:
        document['_id'] = str(document['_id'])
        response.append(document)
    return jsonify(response)



if __name__=='__main__':
    app.run(host="0.0.0.0", port=5000, use_reloader=False)
