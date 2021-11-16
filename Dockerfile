FROM python:3.9-alpine3.13

COPY ./flaskapp /flaskapp
WORKDIR flaskapp
ENV MONGODBURL="ok"

RUN pip install -r requirements.txt
RUN apk add curl 

ENTRYPOINT python app.py
