*** Settings ***
Documentation     IMDB review sentiment robot.
Library           Browser    jsextension=${CURDIR}${/}keywords.js
Library           Collections
Library           RPA.Cloud.AWS    robocloud_vault_name=aws
Library           RPA.Tables

*** Variables ***
${AWS_REGION}=    us-east-2
${MOVIE}=         RoboCop
${REVIEW_MAX_LENGTH}=    ${2000}
${SENTIMENTS_FILE_PATH}=    ${CURDIR}${/}output${/}imdb-sentiments-${MOVIE}.csv

*** Keywords ***
Open IMDB
    New Page    https://www.imdb.com/

Search for movie
    [Arguments]    ${movie}
    Type Text    css=#suggestion-search    ${movie}
    Click    css=.react-autosuggest__suggestion--first a

Scroll page
    FOR    ${i}    IN RANGE    5
        Scroll By    vertical=100%
        Sleep    100 ms
    END

Get reviews
    Click    text=USER REVIEWS
    ${review_locator}=    Set Variable    css=.review-container .text
    Wait For Elements State    ${review_locator}    visible
    Scroll page
    @{reviews}=    getTexts    ${review_locator}
    [Return]    ${reviews}

Analyze sentiments
    [Arguments]    ${reviews}
    Init Comprehend Client    use_robocloud_vault=True    region=${AWS_REGION}
    @{sentiments}=    Create List
    FOR    ${review}    IN    @{reviews}
        ${sentiment_score}=    Comprehend sentiment    ${review}[:${REVIEW_MAX_LENGTH}]
        &{sentiment}=    Create Dictionary
        ...    review=${review}
        ...    sentiment=${sentiment_score}
        Append To List    ${sentiments}    ${sentiment}
    END
    [Return]    ${sentiments}

Comprehend sentiment
    [Arguments]    ${text}
    ${sentiment}=    Detect Sentiment    ${text}
    ${sentiment_score}=    Set Variable If
    ...    "${sentiment["Sentiment"]}" == "NEGATIVE"
    ...    ${-1}
    ...    ${1}
    [Return]    ${sentiment_score}

*** Tasks ***
Analyze IMDB movie review sentiments
    Open IMDB
    Search for movie    ${MOVIE}
    @{reviews}=    Get reviews
    @{sentiments}=    Analyze sentiments    ${reviews}
    ${table}=    Create Table    ${sentiments}
    Write Table To Csv    ${table}    ${SENTIMENTS_FILE_PATH}
