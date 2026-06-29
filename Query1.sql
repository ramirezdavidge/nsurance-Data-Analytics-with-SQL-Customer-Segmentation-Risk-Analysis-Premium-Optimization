
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


----preguntas
--1. ¿Cuál es la prima promedio (Premium_Amount) según el tipo de póliza y región?
select 
	p.Policy_Type,
	r.Region,
	avg(f.Premium_Amount) AS prima_promedio
from fact_insurance f
 join DIM_POLIZA p  ON P.ID_POLIZA=F.ID_POLIZA
join DIM_REGION r ON R.ID_REGION=F.ID_REGION
Group by p.Policy_Type,r.region


----2. ¿Qué fuente de captación (Source_of_Lead) genera más conversiones?

select * from fact_insurance
select * from DIM_LEAD;

select 
SUM(CASE WHEN Conversion_Status=1 then 1 else 0 end) as total_conversiones,
count(*) as cantidad_leads,
cast(1.0*SUM(CASE WHEN Conversion_Status=1 then 1 else 0 end)/count(*) as decimal(5,2))  as ratio_conversion
from fact_insurance

---3. ¿Cuál es el impacto de los descuentos sobre la prima final?
SELECT
CASE WHEN Total_Discounts > 100 THEN 'Alto Descuento' ELSE 'Descuento Normal'
END AS Categoria_Descuento,

AVG(Premium_Amount) AS Prima_Promedio,

AVG(Total_Discounts) AS Descuento_Promedio

FROM fact_insurance

GROUP BY
CASE
WHEN Total_Discounts > 100
THEN 'Alto Descuento'
ELSE 'Descuento Normal'
END;

---4. ¿Qué perfiles de clientes tienen mayor probabilidad de conversión?
select * from dim_cliente  --530 800  tengo edades de 18 a 90, credito de 530 a 800,married_status single o married
--Creación de Perfiles
WITH PERFILES AS (
SELECT
    CASE
        WHEN c.age BETWEEN 18 AND 25
             AND c.Credit_Score BETWEEN 530 AND 619
             AND UPPER(c.Marital_Status) = 'SINGLE'
        THEN 'Perfil 1: Riesgo alto'

        WHEN c.age BETWEEN 36 AND 55
             AND c.Credit_Score BETWEEN 620 AND 699
             AND UPPER(c.Marital_Status) IN ('SINGLE', 'MARRIED')
        THEN 'Perfil 2: Riesgo medio'

        WHEN c.age BETWEEN 56 AND 90
             AND c.Credit_Score BETWEEN 700 AND 800
             AND UPPER(c.Marital_Status) = 'MARRIED'
        THEN 'Perfil 3: Riesgo bajo / Buen crédito'

        ELSE 'Sin perfil'
    END AS Perfil,
	f.Conversion_Status
FROM fact_insurance f
 inner join DIM_CLIENTE c ON c.Cliente_Natural_ID=f.Cliente_Natural_ID 
 )
 SELECT Perfil,
	sum(Cast(Conversion_Status as int)) as cnt_conversiones,
	count(*) as  total_clientes,
	1.0*sum(Cast(Conversion_Status as int))/count(*) as ratio
 FROM PERFILES
 group by Perfil

 ---5. ¿Cuál es el impacto del historial previo de seguro en el precio?
 SELECT
pp.Prior_Insurance,
AVG(f.Premium_Amount) Prima_Promedio,
COUNT(*) Clientes
FROM fact_insurance f

INNER JOIN DIM_PRIOR_INSURANCE pp
ON f.ID_PRIOR_INSURANCE=pp.ID_PRIOR_INSURANCE

GROUP BY pp.Prior_Insurance

ORDER BY Prima_Promedio DESC;


