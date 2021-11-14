FROM python:3.9-alpine3.13

COPY ./flaskapp /flaskapp
WORKDIR flaskapp

RUN pip install -r requirements.txt
RUN apk add bash

ENTRYPOINT python app.py
