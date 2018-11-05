*** Settings ***
Resource          DianShi_Front_End_API.robot
Library           redis_client.py
Library           DateTime
Library           String

*** Variables ***
${version}           2.0

*** Keywords ***
Login
    [Arguments]    ${user_name}    ${area_code}=${None}    ${expect_erorr_code}=0    ${expect_msg}=${None}
    Log    ${redis_ip},${redis_password}
    #${android_devices}    Get Android Device Information
    #${ios_devices}    Get iOS Device Information
    #${devices}    Combine Lists    ${android_devices}    ${ios_devices}
    #${random_device}    Evaluate    random.choice($devices)    modules=random
    Comment    取得 auth code
    ${response_status_code}    ${response_content}    Post_Auth_Code    ${user_name}    ${area_code}
    ${content}    Run Keyword If    ${response_status_code} is ${200}    Run Keyword And Continue On Failure    To Json    ${response_content}
    Validate_Error_Code_And_Message    ${content}    ${expect_erorr_code}    ${expect_msg}    ${False}
    ${redis_auth_code}    Run Keyword If    $area_code    Catenate    SEPARATOR=:    code:dsapp    ${area_code}    ${user_name}    ELSE    Catenate    SEPARATOR=:    code:dsapp:em    ${user_name}
    ${auth_code}    Get_Value_From_Redis    ${redis_ip}    ${redis_password}    6    ${redis_auth_code}
    ${auth_code}    Convert To String    ${auth_code}
    Comment    驗證 auth code
    ${response_status_code}    ${response_content}    Post_Auth_Code_Validation    ${auth_code}    ${user_name}    ${area_code}
    ${content}    Run Keyword If    ${response_status_code} is ${200}    Run Keyword And Continue On Failure    To Json    ${response_content}
    Run Keyword If    &{content}[errorCode] is not ${0}    Fail    Auth_Code incorrect!!!
    ${header}    Create Dictionary    source=dianshiAPP    Content-Type=application/json    api-version=${version}
    Set Test Variable    ${header}    ${header}
    Comment    登入
    ${response_status_code}    ${response_content}    Post_Login    ${header}    ${auth_code}    ${user_name}    ${area_code}
    Comment    判斷
    ${content}    Run Keyword If    ${response_status_code} is ${200}    Run Keyword And Continue On Failure    To Json    ${response_content}
    Comment    判斷第一層
    Run Keyword And Continue On Failure    Dictionary Should Contain Key    ${content}    errorCode
    ${error_code}    Run Keyword And Continue On Failure    Get From Dictionary    ${content}    errorCode
    Validate_Error_Code_And_Message    ${content}    ${expect_erorr_code}    ${expect_msg}
    Run Keyword And Continue On Failure    Dictionary Should Contain Key    ${content}    data
    ${data}    Run Keyword And Continue On Failure    Get From Dictionary    ${content}    data
    Comment    判斷第二層
    ${keys_list}    Create List    session    token
    Run Keyword And Continue On Failure    Dictionary Should Contain Key    ${data}    session
    ${session}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    session
    Run Keyword If    $session    Set Test Variable    ${session}    ${session}
    Run Keyword And Continue On Failure    Dictionary Should Contain Key    ${data}    token
    ${token}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    token
    Run Keyword If    $token    Set Test Variable    ${token}    ${token}
    Set To Dictionary    ${header}    sessionId=${session}    token=${token}

Main_Page
    [Arguments]    ${expect_erorr_code}=0    ${expect_msg}=${None}    ${have_notice}=${True}    ${expect_top3_stocks_length}=3    ${expect_recommended_list_length}=10    ${expect_top_range_start}=1    ${expect_top_range_end}=10
    ${response_status_code}    ${response_content}    Get_Default    ${header}
    Comment    判斷
    ${content}    Run Keyword If    ${response_status_code} is ${200}    Run Keyword And Continue On Failure    To Json    ${response_content}
    ${data}    Validate_Error_Code_And_Message    ${content}    ${expect_erorr_code}    ${expect_msg}
    ${keys_list}    Create List    recommendedList    slogon1    slogon2    top3Stocks    notice
    Run Keyword If    not $have_notice    Remove Values From List    ${keys_list}    notice
    Validate_keys    ${data}    ${keys_list}
    ${top3_stocks}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    top3Stocks
    Run Keyword And Continue On Failure    Length Should Be    ${top3_stocks}    ${expect_top3_stocks_length}
    ${random_top3_stock}    Run Keyword If    $top3_stocks    Evaluate    random.choice($top3_stocks)     modules=random
    ${keys_list}    Create List    name    productId
    Comment    目前後端先將 productId 改成 SecurityId，中台之後再調整
    #Run Keyword If    ${version} == '1.0'    Append To List    ${keys_list}    productId    ELSE    Append To List    ${keys_list}    SecurityId
    Validate_keys    ${random_top3_stock}    ${keys_list}
    ${recommended_list}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    recommendedList
    Run Keyword And Continue On Failure    Length Should Be    ${recommended_list}    ${expect_recommended_list_length}
    ${random_recommended}    Run Keyword If    $recommended_list    Evaluate    random.choice($recommended_list)     modules=random
    Append To List    ${keys_list}    exchange    symbol
    Validate_keys    ${random_recommended}    ${keys_list}
    ${potential_rank}    Get_Value_From_Redis    ${redis_ip}    ${redis_password}    2    anys:rt:pot_rev    start=0    end=10
    Log    ${potential_rank}

Stock_Detail
    [Arguments]    ${product_id}    ${expect_erorr_code}=0   ${expect_erorr_message}=${None}
    ${response_status_code}    ${response_content}    Get_Stock_Detail    ${header}    ${product_id}
    ${content}    Run Keyword If    ${response_status_code} is ${200}    Run Keyword And Continue On Failure    To Json    ${response_content}
    ${data}    Validate_Error_Code_And_Message    ${content}    ${expect_erorr_code}    ${expect_erorr_message}
    ${keys_list}    Create List    analyzeBy3M    analyzeByWeek    analyzeByYear    country
    ...    date    EPSPercent    expectOneYear    followed    levelStars    name    nextReportDate    PE
    ...    price    productId    recommendAction    reportDate    symbol    targetPriceOneYear    targetPrices
    ${ai_expect_delta}    Get_Value_From_Redis    ${redis_ip}    ${redis_password}    2    fcst:${product_id}
    Log Dictionary    ${ai_expect_delta}
    ${ai_expect_delta}    Get Dictionary Items    ${ai_expect_delta}
    ${tmp}    Create Dictionary
    :FOR    ${key}    ${value}    IN    @{ai_expect_delta}
    \    ${key}    Decode Bytes To String    ${key}    	UTF-8
    \    ${value}    Decode Bytes To String    ${value}    	UTF-8
    \    Set To Dictionary    ${tmp}    ${key}=${value}
    ${t1}    Get From Dictionary    ${tmp}    t1
    Run Keyword If    $t1    Append To List    ${keys_list}    aiExpectPercent
    Validate_keys    ${data}    ${keys_list}
    ${f_c_t1}    Get From Dictionary    ${tmp}    f_c_${t1}
    ${ai_expect_percent}    Run Keyword If    $t1    Get From Dictionary    ${data}    aiExpectPercent
    Run Keyword If    $ai_expect_percent    Run Keyword And Continue On Failure    Should Be Equal    ${f_c_t1}    ${ai_expect_percent}
    #Validate_keys    ${data}    ${keys_list}
    #${analyze_by_3M}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    analyzeBy3M
    #${keys_list}    Create List    pressure    underpinning
    #Validate_keys    ${analyze_by_3M}    ${keys_list}
    #${analyze_by_week}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    analyzeByWeek
    #${random_analyze_by_week}    Run Keyword If    $analyze_by_week    Evaluate    random.choice($analyze_by_week)    modules=random
    #${keys_list}    Create List    aiPrice    close    date
    #Validate_keys    ${random_analyze_by_week}    ${keys_list}
    #${analyze_by_year}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    analyzeByYear
    #${keys_list}    Create List    sixMLater    threeMLater    twelveMLater
    #Validate_keys    ${analyze_by_year}    ${keys_list}
    #${recommend_action}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    recommendAction
    #${keys_list}    Create List    countBuy    countLow    countNoComments    countSell    countStrong
    #Validate_keys    ${recommend_action}    ${keys_list}
    #${target_prices}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    targetPrices
    #${keys_list}    Create List    priceStart    priceEnd    priceAverage    analyzerCount
    #Validate_keys    ${target_prices}    ${keys_list}

Search_Page
    [Arguments]    ${expect_erorr_code}=0   ${expect_erorr_message}=${None}    ${expect_hot_stocks_length}=6    ${expect_search_history_length}=5
    ${response_status_code}    ${response_content}    Get_Search    ${header}
    ${content}    Run Keyword If    ${response_status_code} is ${200}    Run Keyword And Continue On Failure    To Json    ${response_content}
    ${data}    Validate_Error_Code_And_Message    ${content}    ${expect_erorr_code}    ${expect_erorr_message}
    ${data}    Run Keyword And Continue On Failure    Get From Dictionary    ${content}    data
    ${keys_list}    Create List    hotStocks    searchHistory
    Validate_keys    ${data}    ${keys_list}
    ${hot_stocks}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    hotStocks
    Run Keyword And Continue On Failure    Length Should Be    ${hot_stocks}    ${expect_hot_stocks_length}
    ${redis_hot_stocks}    Get_Value_From_Redis    ${redis_ip}    ${redis_password}    6    hot:serlist
    ${random_hot_stock}    Run Keyword If    $hot_stocks    Evaluate    random.choice($hot_stocks)     modules=random
    ${keys_list}    Create List    productId    symbol    name
    Validate_keys    ${random_hot_stock}    ${keys_list}
    ${search_histories}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    searchHistory
    Run Keyword And Continue On Failure    Length Should Be    ${search_histories}    ${expect_search_history_length}
    ${random_search_history}    Run Keyword If    $search_histories    Evaluate    random.choice($search_histories)     modules=random
    Append To List    ${keys_list}    followed
    Validate_keys    ${random_search_history}    ${keys_list}

Search_Keyword
    [Arguments]    ${expect_keyword}    ${expect_erorr_code}=0    ${expect_erorr_message}=${None}
    ${response_status_code}    ${response_content}    Get_Search_Keyword    ${header}    ${expect_keyword}
    ${content}    Run Keyword If    ${response_status_code} is ${200}    Run Keyword And Continue On Failure    To Json    ${response_content}
    ${data}    Validate_Error_Code_And_Message    ${content}    ${expect_erorr_code}    ${expect_erorr_message}
    ${keys_list}    Create List    list    keyword
    Validate_keys    ${data}    ${keys_list}
    ${keyword}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    keyword
    Run Keyword And Continue On Failure    Should Be Equal As Strings    ${keyword}    ${expect_keyword}
    ${list}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    list
    ${random_result}    Run Keyword If    $list    Evaluate    random.choice($list)     modules=random
    ${keys_list}    Create List    name    symbol    followed
    Validate_keys    ${random_result}    ${keys_list}
    ${search_result_from_redis}    Search_From_Redis    ${redis_ip}    ${redis_password}    4    *:${expect_keyword}*

My_Select
    [Arguments]    ${expect_followed_list_length}    ${expect_erorr_code}=0    ${expect_erorr_message}=${None}
    ${response_status_code}    ${response_content}    Get_My_Select    ${header}
    ${content}    Run Keyword If    ${response_status_code} is ${200}    Run Keyword And Continue On Failure    To Json    ${response_content}
    ${data}    Validate_Error_Code_And_Message    ${content}    ${expect_erorr_code}    ${expect_erorr_message}
    ${data}    Run Keyword And Continue On Failure    Get From Dictionary    ${content}    data
    ${keys_list}    Create List    followedList
    Validate_keys    ${data}    ${keys_list}
    ${followed_list}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    followedList
    Run Keyword And Continue On Failure    Length Should Be    ${followed_list}    ${expect_followed_list_length}
    ${random_followed}    Run Keyword If    $followed_list    Evaluate    random.choice($followed_list)    modules=random
    ${keys_list}    Create List    aiPercent    aiPrice    close    country    date    exceptPercent    name    price    productId    starLevel    symbol    targetPrice
    Run Keyword If    $random_followed    Validate_keys    ${random_followed}    ${keys_list}

Follow
    [Arguments]    ${product_id}    ${add_follow}=${True}    ${expect_erorr_code}=0    ${expect_erorr_message}=${None}
    ${response_status_code}    ${response_content}    Run Keyword If    $add_follow    Post_Like_Follow    ${header}    ${product_id}    ELSE    Post_Unlike_Follow    ${header}    ${product_id}
    ${content}    Run Keyword If    ${response_status_code} is ${200}    Run Keyword And Continue On Failure    To Json    ${response_content}
    ${data}    Validate_Error_Code_And_Message    ${content}    ${expect_erorr_code}    ${expect_erorr_message}    ${False}

Pricing_Subscription
    [Arguments]    ${device}    ${expect_erorr_code}=0    ${expect_erorr_message}=${None}
    ${response_status_code}    ${response_content}    Get_Pricing_Subscription    ${header}    ${device}
    ${content}    Run Keyword If    ${response_status_code} is ${200}    Run Keyword And Continue On Failure    To Json    ${response_content}
    ${data}    Validate_Error_Code_And_Message    ${content}    ${expect_erorr_code}    ${expect_erorr_message}    ${False}
    ${keys_list}    Create List    plans
    Validate_keys    ${data}    ${keys_list}
    ${plans_list}    Run Keyword And Continue On Failure    Get From Dictionary    ${data}    plans
    ${random_plans}    Run Keyword If    $followed_list    Evaluate    random.choice($plans_list)    modules=random
    ${keys_list}    Create List    actualPrice    circle    circleUnit    label1    label2    name    originalPrice    productId
    Validate_keys    ${data}    ${keys_list}

Generate_Security_Id_List
    [Arguments]    ${amount}
    ${us_security_id}    Get_Products_With_Anys    ${redis_ip}    ${redis_password}    2    US
    ${security_id_list}    Evaluate    random.sample($us_security_id, $amount)    modules=random
    Log List    ${security_id_list}
    [Return]    ${security_id_list}

Validate_Error_Code_And_Message
    [Arguments]    ${content}    ${expect_erorr_code}=0    ${expect_erorr_message}=${None}    ${have_data}=${True}
    Comment    判斷第一層
    Run Keyword And Continue On Failure    Dictionary Should Contain Key    ${content}    errorCode
    ${error_code}    Run Keyword And Continue On Failure    Get From Dictionary    ${content}    errorCode
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${error_code}    ${expect_erorr_code}    ${content}
    Run Keyword If    $expect_erorr_message    Run Keyword And Continue On Failure    Dictionary Should Contain Key    ${content}    msg
    ${msg}    Run Keyword If    ${expect_erorr_message} is not ${None}    Run Keyword And Continue On Failure    Get From Dictionary    ${content}    msg
    Run Keyword If    $expect_erorr_message    Run Keyword And Continue On Failure    Should Not Be Equal As Strings    ${msg}    ${expect_erorr_message}
    Run Keyword If    ${error_code} is 0 and ${have_data}    Run Keyword And Continue On Failure    Dictionary Should Contain Key    ${content}    data
    ${data}    Run Keyword If    ${error_code} is 0 and ${have_data}    Run Keyword And Continue On Failure    Get From Dictionary    ${content}    data
    [Return]    ${data}

Validate_keys
    [Arguments]    ${content_data}    ${expect_keys}
    Comment    判斷欄位
    : FOR    ${key}    IN    @{expect_keys}
    \    Run Keyword And Continue On Failure    Dictionary Should Contain Key    ${content_data}    ${key}