*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.Browser.Selenium
Library    RPA.Robocorp.Vault


*** Variables ***
${ROBOT_ORDER_SITE}=    https://robotsparebinindustries.com/#/robot-order
${ROBOT_ORDERS_FILE}=    https://robotsparebinindustries.com/orders.csv
${DATAFILE}=    orders.csv


*** Keywords ***
Open the robot order website
    Open Available Browser    ${ROBOT_ORDER_SITE}


Get orders data
    Download    ${ROBOT_ORDERS_FILE}    overwrite=True
    ${data}=    Read table from CSV    ${DATAFILE}
    Log    Found columns: ${data.columns} 
    [Return]    ${data}


Close the annoying modal
    ${button_danger}=    Set Variable    xpath://button[@class="btn btn-danger"]
    Click Button    ${button_danger}    # I guess so...


Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]    #${target_as_string}
    Click Element    id:id-body-${row}[Body]
    ${select-legs}=    Set Variable    xpath://input[contains(@id,'16')]
    # Select From List By Value    ${select-legs}    ${row}[Legs]
    Input Text    ${select-legs}    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    ${target_as_string}=    Convert To String    ${row}[Head]
    
Preview the robot
    Click Button    id:preview


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    # Get orders data
    ${orders}=    Get orders data
    FOR    ${row}    IN    @{orders}
        Log    ${row}
        Fill the form    ${row}
        Preview the robot
    #     Submit the order
    #     ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
    #     ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
    #     Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    #     Go to order another robot
    END
    # Create a ZIP file of the receipts


Get and log the value of the vault secrets using the Get Secret keyword
        ${secret}=    Get Secret    credentials
        # Note: in real robots, you should not print secrets to the log. this is just for demonstration purposes :)
        Log    ${secret}[username]
        Log    ${secret}[password]