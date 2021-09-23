*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
# Library  RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.Browser.Selenium


*** Variables ***
${RobotOrderSite}=    https://robotsparebinindustries.com/#/robot-order
${RobotOrdersFile}=    https://robotsparebinindustries.com/orders.csv
${datafile}=    orders.csv


*** Keywords ***
Open the robot order website
    Open Available Browser    ${RobotOrderSite}


Get orders data
    Download    ${RobotOrdersFile}    overwrite=True
    ${data}=    Read table from CSV    ${datafile}
    Log    Found columns: ${data.columns} 
    # ${first}=    Get table row    ${data}
    # Log     Handling order: ${first}[Order ID]
    # ${row}=      Get table row    ${data}    -1    as_list=${TRUE}
    # Log    Row: ${row}
    # FOR    ${value}    IN    @{row}
    #    Log    Data point: ${value}
    # END
    [Return]    ${data} 


Close the annoying modal
    Click Button    I guess so...


Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]    #${target_as_string}
    Click Element    id:id-body-${row}[Body]
    ${select-legs}=    Set Variable    xpath://input[contains(@id,'16')]
    # Select From List By Value    ${select-legs}    ${row}[Legs]
    Input Text    ${select-legs}    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    ${target_as_string}=    Convert To String    ${row}[Head]
    

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
    #     Preview the robot
    #     Submit the order
    #     ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
    #     ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
    #     Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    #     Go to order another robot
    END
    # Create a ZIP file of the receipts
