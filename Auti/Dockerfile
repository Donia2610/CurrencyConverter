FROM python:3
WORKDIR /app
COPY requirements.txt .
RUN pip3 install -r requirements.txt
EXPOSE 5000
COPY . .
CMD ["python3","/app/Auti.py"]



