*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets

*** Variables ***
${csv}         https://robotsparebinindustries.com/orders.csv
${leg}         xpath://Input[@placeholder="Enter the part number for the legs"]
${button}      xpath://Button[@id="order-another"]

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    TRY
        ${result}=     Get Secret       test
        Open the intranet website    ${result}[URL]
    EXCEPT    
        Open the intranet website    https://robotsparebinindustries.com/#/robot-order
    END
    Download the Excel file
    Fill the form using the data from the Excel file
    Create ZIP package from PDF files
    Add icon      Success
    Add heading   Your orders have been processed
    Add files     ${OUTPUT_DIR}${/}receipt${/}*.pdf
    Add files     ${OUTPUT_DIR}${/}*.zip
    Run dialog    title=Success

*** Keywords ***
Open the intranet website
    [Arguments]                 ${URL}
    Open Available Browser      ${URL}
Download the Excel file
    Download                    ${csv}      overwrite=True
Fill the form using the data from the Excel file
    ${table}=    Read table from CSV    orders.csv    header=True
    ${rows}  ${columns}=    Get table dimensions      ${table}
    data    ${rows}    ${table}
data
    [Arguments]           ${rows}     ${table}
    FOR    ${index}       IN RANGE    ${rows}
        Click Button      OK
        ${first}=    Get Table Row    ${table}    ${index}
        Select From List By Value     head        ${first}[Head]
        Click Element     xpath: //Input[@value= ${first}[Body]]     
        Input Text        ${leg}      ${first}[Legs]
        Input Text        address     ${first}[Address]
        Click Button      Preview
        ${res}=  Is Element Visible   ${button}
        check             ${res}
        PDF    ${first}[Order number]
        Click Button      ${button}
    END
check
    [Arguments]     ${res}
    WHILE   ${res}==False
        Wait Until Keyword Succeeds      5x    0.5 sec  Order
        ${res}=    Is Element Visible    ${button}
    END
Order    
    Click Button  Order
PDF
    [Arguments]    ${index}
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}receipt${/}${index}.pdf  
    Screenshot        id:robot-preview-image     ${OUTPUT_DIR}${/}${index}.png
    Open Pdf    ${OUTPUT_DIR}${/}receipt${/}${index}.pdf
    Add Watermark Image To Pdf  ${OUTPUT_DIR}${/}${index}.png    ${OUTPUT_DIR}${/}receipt${/}${index}.pdf
    Close Pdf
Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipt
    ...    ${zip_file_name}