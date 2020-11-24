FROM python:3.7-slim
WORKDIR /django-docs
RUN apt-get -y update && \
    apt-get autoremove -y &&\
    apt-get clean
ENV LANG en_US.utf8
ADD requirements.txt /django-docs
RUN pip install -U pip &&\
    pip install --no-cache-dir -r requirements.txt && \
    rm requirements.txt
