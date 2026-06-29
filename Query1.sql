
---Creación de database
CREATE DATABASE DW_SeguroAuto;
GO

USE DW_SeguroAuto;
GO
----Creacion de nuestra tabla stage 

CREATE TABLE STG_SEGURO_AUTO
(
    

    Age INT,
    Is_Senior BIT,
    Marital_Status VARCHAR(50),

    Married_Premium_Discount DECIMAL(10,2),

    Prior_Insurance VARCHAR(50),
    Prior_Insurance_Premium_Adjustment DECIMAL(10,2),

    Claims_Frequency INT,
    Claims_Severity VARCHAR(50),
    Claims_Adjustment DECIMAL(10,2),

    Policy_Type VARCHAR(50),
    Policy_Adjustment DECIMAL(10,2),

    Premium_Amount DECIMAL(10,2),

    Safe_Driver_Discount DECIMAL(10,2),
    Multi_Policy_Discount DECIMAL(10,2),
    Bundling_Discount DECIMAL(10,2),
    Total_Discounts DECIMAL(10,2),

    Source_of_Lead VARCHAR(50),

    Time_Since_First_Contact INT,

    Conversion_Status BIT,

    Website_Visits INT,
    Inquiries INT,
    Quotes_Requested INT,

    Time_to_Conversion INT,

    Credit_Score INT,
    Premium_Adjustment_Credit DECIMAL(10,2),

    Region VARCHAR(50),
    Premium_Adjustment_Region DECIMAL(10,2)
);
GO

--Poblar stage con csv
BULK INSERT STG_SEGURO_AUTO
FROM 'C:\Users\David\Documents\GitHub\nsurance-Data-Analytics-with-SQL-Customer-Segmentation-Risk-Analysis-Premium-Optimization\Data\synthetic_insurance_data.csv'

WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a'
);
GO