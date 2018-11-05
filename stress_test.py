# -*- coding: utf-8 -*-
from locust import HttpLocust, TaskSet, task
import json
import logging
import redis
import uuid
import random
from collections import deque
import sys


def auth_header():
    return {'source': 'dianshiAPP', 'Content-Type': 'application/json', 'api-version': '2.0'}


def get_auth_code(key):
    rc = redis.StrictRedis(host='47.99.132.244', port=6379, password='StZ5bkPYMD5Yep5KDfBQ', db=6)
    result = rc.get(key)
    return str(result, 'utf8')


def get_product_id():
    rc = redis.StrictRedis(host='47.99.132.244', port=6379, password='StZ5bkPYMD5Yep5KDfBQ', db=2)
    keyspace = rc.info()[''.join(['db', str(2)])]['keys']
    result = list(rc.scan_iter(match='anys:info:*', count=keyspace))
    return [str(sec_id, 'utf8').rsplit(':', 1)[1] for sec_id in result]


amount = 1000
USER_CREDENTIALS = deque(
    [''.join(['trubuzz_', str(uuid.uuid1()).replace('-', ''), '@trubuzz.com']) for index in range(amount)])

PRODUCT_IDS = get_product_id()
logging.info('All of product ids: %s', json.dumps(PRODUCT_IDS))


class TestRun(TaskSet):

    def on_start(self):
        if USER_CREDENTIALS:
            username = USER_CREDENTIALS.pop()

            self.client.post('/wangcai/user/sendAuthCode', data=json.dumps({'userName': username, 'type': 'login'}),
                             headers=auth_header())

            redis_key = ''.join(['code:dsapp:em:', username])
            auth_code = get_auth_code(redis_key)

            logging.info('Login with %s', json.dumps({'userName': username, 'authCode': auth_code}))

            response = self.client.request(method="POST", url='/wangcai/user/loginOrRegister', data=json.dumps(
                {'userName': username, 'authCode': auth_code, 'steps': 'register,login'}), headers=auth_header())

            if response.status_code is 200:
                self.session = json.loads(str(response.content, 'utf8'))['data']['session']
                self.token = json.loads(str(response.content, 'utf8'))['data']['token']
                logging.info('username: %s, client_object: %s, session: %s, token: %s', username, self.client.__str__(),
                             self.session, self.token)

    @task
    def default_page(self):
        headers = auth_header()
        headers['sessionId'] = self.session
        headers['token'] = self.token
        self.client.request(method="GET", url='/wangcai/biz/customizeModule.do?code=default', headers=headers)

    @task
    def search_page(self):
        headers = auth_header()
        headers['sessionId'] = self.session
        headers['token'] = self.token
        self.client.request(method="GET", url='/wangcai/biz/customizeModule.do?code=SearchPage', headers=headers)

    @task
    def my_selected(self):
        headers = auth_header()
        headers['sessionId'] = self.session
        headers['token'] = self.token
        self.client.request(method="GET", url='/wangcai/biz/customizeModule.do?code=mySelected', headers=headers)

    @task
    def add_follow(self):
        headers = auth_header()
        headers['sessionId'] = self.session
        headers['token'] = self.token
        product_id = random.choice(PRODUCT_IDS)
        logging.info('Client object: %s, add product_id %s', self.client.__str__(), product_id)
        payload = {'code': 'mySelected', 'productId': product_id}
        self.client.request(method="POST", url='/wangcai/user/follow/like', data=json.dumps(payload), headers=headers)

    @task
    def remove_follow(self):
        headers = auth_header()
        headers['sessionId'] = self.session
        headers['token'] = self.token
        product_id = random.choice(PRODUCT_IDS)
        logging.info('Client object: %s, remove product_id %s', self.client.__str__(), product_id)
        payload = {'code': 'mySelected', 'productId': product_id}
        self.client.post('/wangcai/user/follow/dislike', data=json.dumps(payload), headers=headers)

    @task
    def stock_detail(self):
        headers = auth_header()
        headers['sessionId'] = self.session
        headers['token'] = self.token
        params = {'productId': random.choice(PRODUCT_IDS)}
        self.client.get('/wangcai/biz/customizeModule.do?code=stockDetail&params=productId', params=params, headers=headers)


class HttpClient(HttpLocust):

    task_set = TestRun
    host = 'https://pre.jindouyun.pro'
