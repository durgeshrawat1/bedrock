ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Copy pip.conf
ARG PIP_CONF
COPY ${PIP_CONF} /etc/pip.conf

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy function code
COPY app/ .

CMD ["handler.lambda_handler"] 