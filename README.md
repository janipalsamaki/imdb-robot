# A robot that uses Amazon Comprehend to analyze IMDB movie review sentiments

<img src="images/animation.gif" style="margin-bottom:20px">

This robot demonstrates how to do text [sentiment analysis](https://en.wikipedia.org/wiki/Sentiment_analysis) with [Amazon Comprehend](https://aws.amazon.com/comprehend/) and [Robocorp](https://www.robocorp.com).

The robot navigates to [IMDB](https://www.imdb.com/), finds the [RoboCop movie](https://www.imdb.com/title/tt0093870/), analyses the user reviews, and stores the reviews and the sentiment analysis result into a CSV file.

## The robot

```robot
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
```

The [`RPA.Cloud.AWS`](https://robocorp.com/docs/libraries/rpa-framework/rpa-cloud-aws) library handles the communications with Amazon Comprehend.

The [Playwright-based Robot Framework Browser library](https://robocorp.com/docs/development-guide/browser/playwright) manages the browser automation duties.

The [`RPA.Tables`](https://robocorp.com/docs/libraries/rpa-framework/rpa-tables) library takes care of saving the data into a CSV file.

## Configuration

You need to provide your Amazon Comprehend API credentials so that the robot can communicate with the sentiment analysis service.

> [Learn how to use the Robocorp vault to store secrets](https://robocorp.com/docs/development-guide/variables-and-secrets/vault).

### Create a `vault.json` file for the credentials

Create a new file: `/Users/<username>/vault.json`

```json
{
  "aws": {
    "AWS_KEY_ID": "YOUR-AWS-KEY-ID",
    "AWS_KEY": "YOUR-AWS-KEY"
  }
}
```

### Point `devdata/env.json` to your `vault.json` file

```json
{
  "RPA_SECRET_MANAGER": "RPA.Robocloud.Secrets.FileSecrets",
  "RPA_SECRET_FILE": "/Users/<username>/vault.json"
}
```

### Robocorp Cloud vault

Create a new secret using `aws` as the name. Add the `AWS_KEY_ID` and `AWS_KEY` key-value pairs.

## I want to learn more!

Visit [Robocorp docs](https://robocorp.com/docs/) to learn more about developing robots to automate your processes!

[Robocorp portal](https://robocorp.com/portal/) contains many example robots with all the source code included.

Follow the [Robocorp YouTube channel](https://www.youtube.com/Robocorp) for automation-related videos.

Visit the [Software Robot Developer forum](https://forum.robocorp.com/) to discuss all-things automation. Ask questions, get answers, share your robots, help others!