import os
import json
import pymongo
from flask import Flask, render_template, request, jsonify

app = Flask(__name__)


mongodb_client = pymongo.MongoClient("mongodb://admin:12345@mongodb:27017/admin")
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
    app.run(host="0.0.0.0", port=5000)
