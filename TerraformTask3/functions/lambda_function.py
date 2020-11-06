import json
import socket
import urllib.request
import boto3
from boto3.dynamodb.conditions import Attr
from operator import itemgetter
urls = ["http://lambda.support-coe.com/", "https://www.google.com/", "https://github.com/LevkovychBorya/test", "https://www.youtube.com/", "http://54.145.205.174/"]
dbname = 'blevk_lambda_db'
sender = "blevk@softserveinc.com"
recipient = "blevk@softserveinc.com"

def store_data(url, codestatus):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(dbname)
    table_scan = table.scan()['Items']
    if not table_scan:
        uid = 0
    else:
        uid = max(table_scan, key=itemgetter("Id"))['Id']    
    table.put_item(
        Item={
            'Id': uid + 1,
            'URL': url,
            'Status': codestatus,
        }
    )
    
def check_health(url,codestatus):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(dbname)
    sorted_urls = sorted(table.scan(FilterExpression=Attr("URL").eq(url))['Items'], key=lambda k: k['Id'], reverse=True)[:3]
    if len(sorted_urls) == 3:
        if sorted_urls[0]['Status'] == 'Unhealthy' and sorted_urls[1]['Status'] == 'Unhealthy' and sorted_urls[2]['Status'] == 'Unhealthy':
            send_mail(url,codestatus)
 
def send_mail(url,codestatus):
    subject = "Health Checks!"
    body_text = ("You recieved this email because there was three failed healtchecks in a row when trying to connect to endpoint!\n" 
                "URL to the endpoint: " + url + "\n"
                "Status: " + codestatus)
    client = boto3.client('ses')
    client.send_email(
        Destination={'ToAddresses': [recipient]},
        Message={'Body':{'Text': {'Charset': 'UTF-8','Data': body_text,},},'Subject': {'Charset': 'UTF-8','Data': subject,},},
        Source=sender,
    )
    
def lambda_handler(event, context):
    for url in urls:
        try:
            socket.setdefaulttimeout(3)
            req = urllib.request.Request(url)
            conn = urllib.request.urlopen(req)
            code = conn.getcode()
        except urllib.error.HTTPError as e:
            code = e.code
        except urllib.error.URLError as e:
            codestatus = str(e.reason)
            store_data(url, codestatus)
            continue
        if str(code)[0]=='2' or str(code)[0]=='3':
            codestatus = 'Healthy'
        elif str(code)[0]=='4' or str(code)[0]=='5':
            codestatus = 'Unhealthy'
        store_data(url, codestatus)
        check_health(url,codestatus)