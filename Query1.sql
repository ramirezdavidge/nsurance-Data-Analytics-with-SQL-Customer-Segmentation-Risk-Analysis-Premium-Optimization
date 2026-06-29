
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

---Creación de un Identificador Unico POR COLUMNA
Alter table STG_SEGURO_AUTO
ADD Cliente_Natural_ID INT IDENTITY(1,1)

----CREACION DE DIMENSIONES
--DIM CLIENTE

WITH t_dim_cliente as(
SELECT
Cliente_Natural_ID,
Age,
Is_Senior,
Marital_Status,
Credit_Score

FROM STG_SEGURO_AUTO)
select *
INTO  DIM_CLIENTE
from t_dim_cliente
;

--DIM_POLIZA
WITH T_DIM_POLIZA AS (
SELECT DISTINCT
Policy_Type,
Policy_Adjustment
FROM STG_SEGURO_AUTO
)
SELECT SUM(1) OVER(ORDER BY Policy_Type DESC) ID_POLIZA, 
*
INTO DIM_POLIZA
FROM T_DIM_POLIZA
SELECT * FROM DIM_POLIZA

--DIM_REGION
WITH T_DIM_REGION AS (
SELECT DISTINCT
Region,
Premium_Adjustment_Region
FROM STG_SEGURO_AUTO
)
SELECT SUM(1) OVER(ORDER BY REGION DESC) ID_REGION,*
INTO DIM_REGION
FROM T_DIM_REGION 

--DIM_LEAD
WITH T_DIM_LEAD AS (
SELECT DISTINCT
Source_of_Lead 
FROM STG_SEGURO_AUTO
)
SELECT SUM(1) OVER(ORDER BY Source_of_Lead desc) ID_LEAD,*
INTO DIM_LEAD
FROM T_DIM_LEAD

--DIM_CONVERSION
WITH T_DIM_CONVERSION AS (
SELECT DISTINCT
Conversion_Status
FROM STG_SEGURO_AUTO )
SELECT SUM(1) OVER(ORDER BY Conversion_Status DESC) ID_CONVERSION,*
INTO DIM_CONVERSION
FROM T_DIM_CONVERSION

---DIM_PRIOR_INSURANCE
WITH T_DIM_INSURANCE AS (
SELECT DISTINCT
    Prior_Insurance,
    Prior_Insurance_Premium_Adjustment

FROM STG_SEGURO_AUTO )
SELECT SUM(1) OVER(ORDER BY Prior_Insurance DESC) ID_PRIOR_INSURANCE,*
INTO  DIM_PRIOR_INSURANCE
FROM T_DIM_INSURANCE


---------------------------------------------------------------------------
-------CREACION DE FACT_SEGURO_AUTO
---------------------------------------------------------------------------

with t_fact_insurance as (
SELECT 
s.Cliente_Natural_ID,
s.Conversion_Status,
s.Married_Premium_Discount,
i.ID_PRIOR_INSURANCE,
s.Claims_Frequency,
s.Claims_Severity,
s.Claims_Adjustment,
s.Premium_Amount,
s.Safe_Driver_Discount,
s.Multi_Policy_Discount,
s.Bundling_Discount,
s.Total_Discounts,
s.Time_Since_First_Contact,
s.Website_Visits,
s.Inquiries,
s.Quotes_Requested,
s.Time_to_Conversion,
s.Premium_Adjustment_Credit,
p.ID_POLIZA,
r.ID_REGION,
l.ID_LEAD
FROM STG_SEGURO_AUTO s
left join DIM_POLIZA p ON s.Policy_Type=p.Policy_Type
left join DIM_REGION r ON s.region=r.region
left join DIM_LEAD l ON  s.Source_of_Lead=l.Source_of_Lead
left join DIM_PRIOR_INSURANCE i on s.Prior_Insurance=i.Prior_Insurance
)
select *
into fact_insurance
from t_fact_insurance