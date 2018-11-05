*** Settings ***
Resource          DianShi_Front_End_Keywords.robot
Test Setup          Create_Front_End_Session

*** Test Cases ***
Using Validate E-mail Login And Add Follow
    [Tags]    p0
    #Login    aaa@trubuzz.com
    #Main_Page
    #Search_Keyword    pin
    #Stock_Detail    US00941398
    #Follow    US00602097
    #Follow     5

Using Validate Phone Number Login
    [Tags]    p0
    #Login    0927919011    886
    #Main_Page
    #Search_Page

Validate Already add Follows
    [Tags]    p0
    #Login    max.chen@trubuzz.com
    #Follow    US00602097    expect_erorr_code=-1001    expect_erorr_message=already_add

Add To 100 My Select
    #Login    aab@trubuzz.com
    #${security_id}    Generate_Security_Id_List    95
    #:FOR    ${sid}    IN    @{security_id}
    #\    Follow    ${sid}

List My Select
    Login    trubuzz_a46c93c0e0b111e8911588e9fe5158da@trubuzz.com
    Main_Page
    #Stock_Detail    US00967175
    My_Select    100