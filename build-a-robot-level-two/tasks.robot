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
Library    RPA.PDF
Library    RPA.FileSystem
Library    RPA.Archive
Library    RPA.Dialogs


*** Variables ***
# ${ROBOT_ORDER_SITE}=    https://robotsparebinindustries.com/#/robot-order
${ROBOT_ORDERS_FILE}=    https://robotsparebinindustries.com/orders.csv
# ${DATAFILE}=    orders.csv
${GLOBAL_RETRY_AMOUNT}=    5x
${GLOBAL_RETRY_INTERVAL}=    0.5s


*** Keywords ***
Collect orders url from user
    # Add heading    Insert url to dowload order's data
    Add text input    csvfileurl
    Add text    If yo don't know the url, use the link below this line:
    Add link    ${ROBOT_ORDERS_FILE}
    # ${dialog}=    Show dialog    title=Input form
    ${response}=    Run dialog    title=Insert url    height=300
    [Return]    ${response.csvfileurl}


Collect orders file from user
    Add heading    Upload orders file
    Add file input
    ...    label=Upload the file with orders data
    ...    name=fileupload
    # ...    file_type=Excel files (*.xls;*.xlsx)
    ...    destination=${CURDIR}${/}input
    ${response}=    Run dialog
    [Return]    ${response.fileupload}[0]


Open the robot order website
    # Open Available Browser    ${ROBOT_ORDER_SITE}
    ${robots_order_site}=    Get Secret    website
    Open Available Browser     ${robots_order_site}[url]


Get orders data
    [Arguments]    ${orders_fileurl}
    # [Arguments]    ${datafile}
    # ${data}=    Read table from CSV    ${datafile}
    # Download    ${ROBOT_ORDERS_FILE}    overwrite=True
    Download    ${orders_fileurl}    target_file=${CURDIR}${/}input${/}new_orders.csv    overwrite=True
    ${data}=    Read table from CSV    ${CURDIR}${/}input${/}new_orders.csv    
    Log    Found columns: ${data.columns} 
    [Return]    ${data}


Close the annoying modal
    ${button_danger}=    Set Variable    xpath://button[@class="btn btn-danger"]
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Wait Until Page Contains Element    ${button_danger}    
    Click Button    ${button_danger}


Fill the form
    [Arguments]    ${row}
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Wait Until Page Contains Element    id:address
    Select From List By Value    id:head    ${row}[Head]
    Click Element    id:id-body-${row}[Body]
    ${input_legs}=    Set Variable    xpath://input[contains(@id,'16')]
    Input Text    ${input_legs}    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    
Preview the robot
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Wait Until Page Contains Element    id:preview
    Click Button    id:preview


Submit the order
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Wait Until Page Contains Element    id:order
    # Trying until 5 times to submit any order
    FOR    ${i}    IN RANGE    5
        Click Button    id:order
        # Checking if submit is Ok!
        ${submit_Ok}=    Does Page Contain    Receipt
        # Log    ${submit_Ok}
        Exit For Loop If    ${submit_Ok}
    END
    

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:order-completion
    ${receipt}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${receipt}    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf
    [Return]    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf
    

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:robot-preview-image
    ### This try to improve the screenshot capture, to get the whole robot image preview
    ${img_head}=    Set Variable    xpath://img[contains(@alt,'Head')]
    Wait Until Element Is Visible    ${img_head}
    ${img_body}=    Set Variable    xpath://img[contains(@alt,'Body')]
    Wait Until Element Is Visible    ${img_body}
    ${img_legs}=    Set Variable    xpath://img[contains(@alt,'Legs')]
    Wait Until Element Is Visible    ${img_legs}
    Capture Element Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}receipts${/}${order_number}.png
    [Return]    ${CURDIR}${/}output${/}receipts${/}${order_number}.png


Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${order_number}    ${order_pdf}    ${order_screenshot}
    # Log    ${order_number}
    # Log    ${order_pdf}
    # Log    ${order_screenshot}
    # Add files to pdf
    ${files}=    Create List
        ...    ${order_pdf}
        ...    ${order_screenshot}:align=center
    Add Files To PDF    ${files}    ${CURDIR}${/}output${/}receipts${/}order_a-${order_number}.pdf
    Log    ${files}
    Add Watermark Image To PDF
    ...    source_path=${order_pdf}
    ...    image_path=${order_screenshot}
    ...    output_path=${CURDIR}${/}output${/}receipts${/}order_w-${order_number}.pdf
    Close Pdf    ${order_pdf}
    Remove file    ${order_pdf}
    # Remove File    ${order_screenshot}


Go to order another robot
    Wait Until Keyword Succeeds    #5x    1s
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Wait Until Page Contains Element     id:order-another
    Click Button    id:order-another 


Create a ZIP file of the receipts
    Archive Folder With Zip  ${CURDIR}${/}output${/}receipts${/}    output${/}receipts.zip


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders_fileurl}=    Collect orders url from user
    # ${orders_fileupload}=    Collect orders file from user
    Open the robot order website  
    # ${orders}=    Get orders data    ${orders_fileupload}
    ${orders}=    Get orders data    ${orders_fileurl}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal 
        Fill the form    ${row}
        Preview the robot
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${row}[Order number]    ${pdf}    ${screenshot}
        Go to order another robot
    END
    
    Create a ZIP file of the receipts

    [Teardown]
    
