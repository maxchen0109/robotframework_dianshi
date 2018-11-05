# -*- coding: utf-8 -*-
import redis
import collections

"""
config = {'pre': {'password': 'StZ5bkPYMD5Yep5KDfBQ', 'server_ip': '47.99.132.244'},
          'daily': {'password': 'l09d6lmHsgbHdOm2j8gD', 'server_ip': '47.99.52.172'}}
"""


def get_value_from_redis(server_ip, password, db_number, key, port=6379, start=0, end=-1):
    def redis_type(type):
        if type == b'zset' or type == 'zset':
            return redis_client_object.zrange(key, start, end, True)
        elif type == b'string' or type == 'string':
            return redis_client_object.get(key)
        elif type == b'hash' or type == 'hash':
            return redis_client_object.hgetall(key)

    redis_client_object = redis.Redis(host=server_ip, port=port, password=password, db=db_number)
    result = redis_type(redis_client_object.type(key))
    return result


def search_from_redis(server_ip, password, db_number, keyword, port=6379):
    redis_client_object = redis.Redis(host=server_ip, port=port, password=password, db=db_number)
    keyspace = redis_client_object.info()[''.join(['db', str(db_number)])]['keys']
    result = list(redis_client_object.scan_iter(match=keyword, count=keyspace))
    p1 = list()
    p20 = list()
    p30 = list()
    p40 = list()
    p50 = list()
    p60 = list()
    result_set = list()
    for r in result:
        print(r)
        if str(r, 'utf8').split(':')[0] == '1':
            p1.append(str(r, 'utf8').split('_')[1])
        elif str(r, 'utf8').split(':')[0] == '20':
            p20.append(str(r, 'utf8').split('_')[1])
        elif str(r, 'utf8').split(':')[0] == '30':
            p30.append(str(r, 'utf8').split('_')[1])
        elif str(r, 'utf8').split(':')[0] == '40':
            p40.append(str(r, 'utf8').split('_')[1])
        elif str(r, 'utf8').split(':')[0] == '50':
            p50.append(str(r, 'utf8').split('_')[1])
        elif str(r, 'utf8').split(':')[0] == '60':
            p60.append(str(r, 'utf8').split('_')[1])
    result_set.extend(p1)
    result_set.extend(p20)
    result_set.extend(p30)
    result_set.extend(p40)
    result_set.extend(p50)
    result_set.extend(p60)
    return (collections.OrderedDict.fromkeys(result_set))


def get_products_with_anys(server_ip, password, db_number, reign='all', port=6379):
    redis_client_object = redis.Redis(host=server_ip, port=port, password=password, db=db_number)
    keyspace = redis_client_object.info()[''.join(['db', str(db_number)])]['keys']
    anys_products = {'all': 'anys:info:*', 'us': 'anys:info:US*', 'hk': 'anys:info:HK*'}
    result = list(redis_client_object.scan_iter(match=anys_products[reign.lower()], count=keyspace))
    return [str(sec_id, 'utf8').rsplit(':', 1)[1] for sec_id in result]

"""
a = search_from_redis(config['pre']['server_ip'], config['pre']['password'], 4, '*wft*')
print(a)
a = get_value_from_redis(config['pre']['server_ip'], config['pre']['password'], 2, 'sec:info:US00576487')
print(a)
a = get_products_with_anys(config['pre']['server_ip'], config['pre']['password'], 2, 'US')
print(a)
"""


