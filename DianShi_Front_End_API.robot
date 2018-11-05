*** Settings ***
Library           RequestsLibrary
Library           Collections
Library           DateTime
Library           String
Library           OperatingSystem
Library           FakerLibrary

*** Variables ***
${site}           pre
${redis_port}           6379

*** Keywords ***
Create_Front_End_Session
    ${front_end_session_id}    Get Current Date    result_format=epoch    exclude_millis=yes
    ${front_end_session_id}    Convert To String    ${front_end_session_id}
    Set Test Variable    ${front_end_session_id}    ${front_end_session_id}
    ${site}    Convert To Lowercase    ${site}
    ${site_list}    Create List    daily    prod    pre
    Run Keyword If    '${site}' not in ${site_list}    Fatal Error    The site valid value are in ['daily', 'pre', 'prod']
    ${redis_ip}    Set Variable If    '${site}' == 'daily'    47.99.52.172
    ...    '${site}' == 'prod'    116.62.227.208
    ...    '${site}' == 'pre'    47.99.132.244
    Set Test Variable    ${redis_ip}    ${redis_ip}
    ${redis_password}    Set Variable If    '${site}' == 'daily'    l09d6lmHsgbHdOm2j8gD
    ...    '${site}' == 'prod'    DU2cCIENHq8gixx14eia5LMI
    ...    '${site}' == 'pre'    StZ5bkPYMD5Yep5KDfBQ
    Set Test Variable    ${redis_password}    ${redis_password}
    Set Test Variable    ${redis_port}    ${redis_port}
    ${site}    Set Variable If    '${site}' == 'daily'    http://daily.jindouyun.pro
    ...    '${site}' == 'prod'    https://stone.jindouyun.pro
    ...    '${site}' == 'pre'    https://pre.jindouyun.pro
    Create Session    ${front_end_session_id}    ${site}    verify=True    timeout=5

Post_Auth_Code
    [Arguments]    ${user_name}    ${area_code}=None
    ${auth_code_header}    Create Dictionary    source=dianshiAPP    Content-Type=application/json    api-version=${version}
    ${data}    Create Dictionary    userName=${user_name}    type=login
    Run Keyword If    $area_code    Set To Dictionary    ${data}    areaCode=${area_code}
    ${response}    Post Request    ${front_end_session_id}    /wangcai/user/sendAuthCode    data=${data}    headers=${auth_code_header}    timeout=5
    [Return]    ${response.status_code}    ${response.content}

Post_Auth_Code_Validation
    [Arguments]    ${auth_code}    ${user_name}    ${area_code}=None
    ${auth_code_header}    Create Dictionary    source=dianshiAPP    Content-Type=application/json    api-version=${version}
    ${data}    Create Dictionary    userName=${user_name}    authCode=${auth_code}    type=login
    Run Keyword If    $area_code    Set To Dictionary    ${data}    areaCode=${area_code}
    ${response}    Post Request    ${front_end_session_id}    /wangcai/user/checkAuthCode    data=${data}    headers=${auth_code_header}    timeout=5
    [Return]    ${response.status_code}    ${response.content}

Post_Login
    [Arguments]    ${header}    ${auth_code}    ${user_name}    ${area_code}=None
    ${data}    Create Dictionary    userName=${user_name}    authCode=${auth_code}    steps=register,login
    Run Keyword If    $area_code    Set To Dictionary    ${data}    areaCode=${area_code}
    ${response}    Post Request    ${front_end_session_id}    /wangcai/user/loginOrRegister    data=${data}    headers=${header}    timeout=5
    [Return]    ${response.status_code}    ${response.content}

Get_Default
    [Arguments]    ${header}
    ${params}    Create Dictionary    code=default
    ${response}    Get Request    ${front_end_session_id}    /wangcai/biz/customizeModule.do    params=${params}    headers=${header}    timeout=5
    [Return]    ${response.status_code}    ${response.content}

Get_Search
    [Arguments]    ${header}
    ${params}    Create Dictionary    code=SearchPage
    ${response}    Get Request    ${front_end_session_id}    /wangcai/biz/customizeModule.do    params=${params}    headers=${header}    timeout=5
    [Return]    ${response.status_code}    ${response.content}

Get_Search_Keyword
    [Arguments]    ${header}    ${keyword}
    ${params}    Create Dictionary    code=search    params=keyword    keyword=${keyword}
    ${response}    Get Request    ${front_end_session_id}    /wangcai/biz/customizeModule.do    params=${params}    headers=${header}    timeout=5
    [Return]    ${response.status_code}    ${response.content}

Get_My_Select
    [Arguments]    ${header}
    ${params}    Create Dictionary    code=mySelected
    ${response}    Get Request    ${front_end_session_id}    /wangcai/biz/customizeModule.do    params=${params}    headers=${header}    timeout=5
    [Return]    ${response.status_code}    ${response.content}

Post_Like_Follow
    [Arguments]    ${header}    ${product_id}
    ${data}    Create Dictionary    code=mySelected    productId=${product_id}
    ${response}    Post Request    ${front_end_session_id}    /wangcai/user/follow/like    data=${data}    headers=${header}    timeout=5
    [Return]    ${response.status_code}    ${response.content}

Post_Unlike_Follow
    [Arguments]    ${header}    ${product_id}
    ${data}    Create Dictionary    code=mySelected    productId=${product_id}
    ${response}    Post Request    ${front_end_session_id}    /wangcai/user/follow/dislike    data=${data}    headers=${header}    timeout=5
    [Return]    ${response.status_code}    ${response.content}

Get_Stock_Detail
    [Arguments]    ${header}    ${product_id}
    ${params}    Create Dictionary    code=stockDetail    productId=${product_id}    params=productId
    ${response}    Get Request    ${front_end_session_id}    /wangcai/biz/customizeModule.do    params=${params}    headers=${header}    timeout=5
    [Return]    ${response.status_code}    ${response.content}

Get_Market_Price
    [Arguments]    ${header}    ${product_id}
    ${params}    Create Dictionary    code=realTimePrices    params=productId    productId=${product_id}
    ${response}    Get Request    ${front_end_session_id}    /wangcai/biz/customizeModule.do    params=${params}    headers=${header}    timeout=5
    [Return]    ${response.status_code}    ${response.content}

Get_Pricing_Subscription
    [Arguments]    ${header}    ${device}
    ${params}    Create Dictionary    code=pricingScheme    params=device    device=${device}
    ${response}    Get Request    ${front_end_session_id}    /wangcai/biz/customizeModule.do    params=${params}    headers=${header}    timeout=5
    [Return]    ${response.status_code}    ${response.content}