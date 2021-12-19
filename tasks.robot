*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.Excel.Files
Library           RPA.HTTP
Library           RPA.JSON
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.FileSystem
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    #Get site URL from Vault
    ${result_url}=    Ask user for orders url
    Create Directory    ${OUTPUT_DIR}${/}receipts_with_pictures
    ${orders_url}=    Get Secret    url_for_order_system
    Open the robot ordering website    ${orders_url}
    ${orders}=    Get orders    ${result_url}
    FOR    ${row}    IN    @{orders}
        Close the annoying thingy
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${row}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot ordering website
    [Arguments]    ${orders_url}
    Open Available Browser    ${orders_url}[Order_system_url]
    #https://robotsparebinindustries.com/#/robot-order

Get orders
    [Arguments]    ${result_url}
    Download    ${result_url}    overwrite=True
    #https://robotsparebinindustries.com/orders.csv
    ${orders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}
    Log    ${orders}

Close the annoying thingy
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    name:head    ${row}[Head]
    Click Element    id-body-${row}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    ${error_element}    Is Element Visible    css:div[class="alert alert-danger"]
    IF    ${error_element} == True
        Submit the order
    ELSE
        Log    "Got through"
        Capture Page Screenshot
    END

Go to order another robot
    Wait Until Page Contains Element    order-another
    Click Button    order-another

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:order-completion
    ${order_results_html}=    Get Element Attribute    id:order-completion    outerHTML
    ${pdf}=    Html To Pdf    ${order_results_html}    ${OUTPUT_DIR}${/}receipts${/}order ${row}.pdf
    [Return]    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:order-completion
    ${robots_image}=    Get Element Attribute    id:robot-preview-image    outerHTML
    ${screenshot}=    Capture Element Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}receipts${/}order ${row}.PNG
    [Return]    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${pdf}    ${screenshot}    ${row}
    Open Pdf    ${pdf}
    ${PNG_List}=    Create List
    ...    ${OUTPUT_DIR}${/}receipts${/}order ${row}.pdf
    ...    ${OUTPUT_DIR}${/}receipts${/}order ${row}.PNG:align=center
    Add Files To Pdf    ${PNG_List}    ${OUTPUT_DIR}${/}receipts_with_pictures${/}order ${row}.pdf
    Close Pdf    ${pdf}

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts_with_pictures    orders.zip

Ask user for orders url
    Add heading    Enter URL for orders CSV
    Add text input    URL    label=URL    placeholder=Enter URL here
    ${result_url}=    Run dialog
    [Return]    ${result_url.URL}
