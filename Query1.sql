
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



---- Preguntas


--1. ¿Cuál es la prima promedio  según el tipo de póliza y región?

SELECT 
    p.Policy_Type,
    r.Region,
    AVG(f.Premium_Amount) AS prima_promedio
FROM fact_insurance f
JOIN DIM_POLIZA p 
    ON p.ID_POLIZA = f.ID_POLIZA
JOIN DIM_REGION r 
    ON r.ID_REGION = f.ID_REGION
GROUP BY 
    p.Policy_Type,
    r.Region;



----2. ¿Qué fuente de captación  genera más conversiones?

SELECT 
    SUM(CASE 
            WHEN Conversion_Status = 1 
            THEN 1 
            ELSE 0 
        END) AS total_conversiones,

    COUNT(*) AS cantidad_leads,

    CAST(
        1.0 * SUM(CASE 
                    WHEN Conversion_Status = 1 
                    THEN 1 
                    ELSE 0 
                 END) / COUNT(*) 
        AS DECIMAL(5,2)
    ) AS ratio_conversion

FROM fact_insurance;



---3. ¿Cuál es el impacto de los descuentos sobre la prima final?


SELECT
    CASE 
        WHEN Total_Discounts > 100 
        THEN 'Alto Descuento' 
        ELSE 'Descuento Normal'
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



---4. ¿Qué segmentos de clientes presentan mayor probabilidad de conversión considerando edad, nivel crediticio y estado civil?

-- Creación de perfiles

WITH PERFILES AS 
(
    SELECT

        CASE

            WHEN c.age BETWEEN 18 AND 25
             AND c.Credit_Score BETWEEN 530 AND 619
             AND UPPER(c.Marital_Status) = 'SINGLE'
            THEN 'Perfil 1: Riesgo alto'


            WHEN c.age BETWEEN 36 AND 55
             AND c.Credit_Score BETWEEN 620 AND 699
             AND UPPER(c.Marital_Status) IN ('SINGLE','MARRIED')
            THEN 'Perfil 2: Riesgo medio'


            WHEN c.age BETWEEN 56 AND 90
             AND c.Credit_Score BETWEEN 700 AND 800
             AND UPPER(c.Marital_Status) = 'MARRIED'
            THEN 'Perfil 3: Riesgo bajo / Buen crédito'


            ELSE 'Sin perfil'

        END AS Perfil,

        f.Conversion_Status

    FROM fact_insurance f

    INNER JOIN DIM_CLIENTE c
        ON c.Cliente_Natural_ID = f.Cliente_Natural_ID
)


SELECT 

    Perfil,

    SUM(CAST(Conversion_Status AS INT)) AS cnt_conversiones,

    COUNT(*) AS total_clientes,

    1.0 * SUM(CAST(Conversion_Status AS INT)) / COUNT(*) AS ratio

FROM PERFILES

GROUP BY Perfil;

---5. ¿Cuál es el impacto del historial previo de seguro en el precio?


SELECT

    pp.Prior_Insurance,

    AVG(f.Premium_Amount) AS Prima_Promedio,

    COUNT(*) AS Clientes

FROM fact_insurance f

INNER JOIN DIM_PRIOR_INSURANCE pp

    ON f.ID_PRIOR_INSURANCE = pp.ID_PRIOR_INSURANCE

GROUP BY 

    pp.Prior_Insurance

ORDER BY 

    Prima_Promedio DESC;




--6. ¿Qué zonas generan mayor facturación?


SELECT 

    SUM(f.Premium_Amount) AS Total_region,

    r.Region,

    RANK() OVER 
    (
        ORDER BY SUM(f.Premium_Amount) DESC
    ) AS ranking_region

FROM fact_insurance f

INNER JOIN DIM_REGION r

    ON r.ID_REGION = f.ID_REGION

GROUP BY 

    r.Region

ORDER BY 

    Total_region DESC;




--7. ¿Quiénes son los clientes de mayor valor?
-- Premium_Amount + Credit_Score - Claims_Frequency


WITH valor_Claims_severity AS 
(
    SELECT

        F.Cliente_Natural_ID,

        CASE 

            WHEN UPPER(F.Claims_Severity) = 'LOW' 
            THEN 1

            WHEN UPPER(F.Claims_Severity) = 'MEDIUM' 
            THEN 2

            WHEN UPPER(F.Claims_Severity) = 'HIGH' 
            THEN 3

            ELSE 0

        END AS VALOR_SEVERITY

    FROM fact_insurance F
),


Customer_Value_Score AS 
(
    SELECT

        f.Cliente_Natural_ID,

        (
            f.Premium_Amount 
            + c.Credit_Score
            - f.Claims_Frequency
            - V.VALOR_SEVERITY
        ) AS cust_value_score


    FROM fact_insurance f


    JOIN DIM_CLIENTE c

        ON c.Cliente_Natural_ID = f.Cliente_Natural_ID


    JOIN valor_Claims_severity V

        ON V.Cliente_Natural_ID = f.Cliente_Natural_ID
)


SELECT *

FROM Customer_Value_Score

ORDER BY 

    cust_value_score DESC;





--8. ¿Qué factores influyen más en la conversión?


SELECT

    f.Conversion_Status,

    AVG(f.Website_Visits) AS Visitas_Promedio,

    AVG(f.Inquiries) AS Consultas,

    AVG(f.Quotes_Requested) AS Cotizaciones,

    AVG(f.Time_to_Conversion) AS Tiempo


FROM fact_insurance f


GROUP BY 

    f.Conversion_Status;




--9. Dame los 50 clientes con mayor probabilidad de fuga


SELECT TOP 50

    Cliente_Natural_ID,

    CASE

        WHEN CLAIMS_FREQUENCY >= 3
             AND UPPER(Claims_Severity) = 'HIGH'

        THEN 'Alto Riesgo'


        WHEN CLAIMS_FREQUENCY >= 3
             AND UPPER(Claims_Severity) = 'MEDIUM'

        THEN 'Alto Riesgo'


        WHEN CLAIMS_FREQUENCY >= 3
             AND UPPER(Claims_Severity) = 'LOW'

        THEN 'Riesgo Medio-Alto'


        WHEN CLAIMS_FREQUENCY < 3
             AND UPPER(Claims_Severity) = 'HIGH'

        THEN 'Riesgo Medio'


        WHEN CLAIMS_FREQUENCY < 3
             AND UPPER(Claims_Severity) = 'MEDIUM'

        THEN 'Riesgo Medio'


        WHEN CLAIMS_FREQUENCY < 3
             AND UPPER(Claims_Severity) = 'LOW'

        THEN 'Bajo Riesgo'


        ELSE 'Sin Clasificar'


    END AS Riesgo


FROM fact_insurance


ORDER BY

CASE


    WHEN

        CASE

            WHEN CLAIMS_FREQUENCY >= 3 
             AND UPPER(Claims_Severity) = 'HIGH'

            THEN 'Alto Riesgo'


            WHEN CLAIMS_FREQUENCY >= 3 
             AND UPPER(Claims_Severity) = 'MEDIUM'

            THEN 'Alto Riesgo'


            WHEN CLAIMS_FREQUENCY >= 3 
             AND UPPER(Claims_Severity) = 'LOW'

            THEN 'Riesgo Medio-Alto'


            WHEN CLAIMS_FREQUENCY < 3 
             AND UPPER(Claims_Severity) = 'HIGH'

            THEN 'Riesgo Medio'


            WHEN CLAIMS_FREQUENCY < 3 
             AND UPPER(Claims_Severity) = 'MEDIUM'

            THEN 'Riesgo Medio'


            WHEN CLAIMS_FREQUENCY < 3 
             AND UPPER(Claims_Severity) = 'LOW'

            THEN 'Bajo Riesgo'


            ELSE 'Sin Clasificar'

        END = 'Alto Riesgo'

    THEN 1



    WHEN

        CASE

            WHEN CLAIMS_FREQUENCY >= 3 
             AND UPPER(Claims_Severity) = 'HIGH'

            THEN 'Alto Riesgo'


            WHEN CLAIMS_FREQUENCY >= 3 
             AND UPPER(Claims_Severity) = 'MEDIUM'

            THEN 'Alto Riesgo'


            WHEN CLAIMS_FREQUENCY >= 3 
             AND UPPER(Claims_Severity) = 'LOW'

            THEN 'Riesgo Medio-Alto'


            WHEN CLAIMS_FREQUENCY < 3 
             AND UPPER(Claims_Severity) = 'HIGH'

            THEN 'Riesgo Medio'


            WHEN CLAIMS_FREQUENCY < 3 
             AND UPPER(Claims_Severity) = 'MEDIUM'

            THEN 'Riesgo Medio'


            WHEN CLAIMS_FREQUENCY < 3 
             AND UPPER(Claims_Severity) = 'LOW'

            THEN 'Bajo Riesgo'


            ELSE 'Sin Clasificar'

        END = 'Riesgo Medio'

    THEN 2



    WHEN

        CASE

            WHEN CLAIMS_FREQUENCY >= 3 
             AND UPPER(Claims_Severity) = 'HIGH'

            THEN 'Alto Riesgo'


            WHEN CLAIMS_FREQUENCY >= 3 
             AND UPPER(Claims_Severity) = 'MEDIUM'

            THEN 'Alto Riesgo'


            WHEN CLAIMS_FREQUENCY >= 3 
             AND UPPER(Claims_Severity) = 'LOW'

            THEN 'Riesgo Medio-Alto'


            WHEN CLAIMS_FREQUENCY < 3 
             AND UPPER(Claims_Severity) = 'HIGH'

            THEN 'Riesgo Medio'


            WHEN CLAIMS_FREQUENCY < 3 
             AND UPPER(Claims_Severity) = 'MEDIUM'

            THEN 'Riesgo Medio'


            WHEN CLAIMS_FREQUENCY < 3 
             AND UPPER(Claims_Severity) = 'LOW'

            THEN 'Bajo Riesgo'


            ELSE 'Sin Clasificar'


        END = 'Bajo Riesgo'

    THEN 3


    ELSE 4


END;
--10. ¿Cuál es el descuento efectivo aplicado a cada póliza después de todos los ajustes?


WITH base AS 
(
    SELECT

        F.Premium_Amount,


        (
            F.Premium_Amount
            -
            (
                P.Policy_Adjustment
                + F.Premium_Adjustment_Credit
                + R.Premium_Adjustment_Region
            )

        ) AS Premium_Neto


    FROM fact_insurance F


    INNER JOIN DIM_REGION R

        ON R.ID_REGION = F.ID_REGION


    INNER JOIN DIM_POLIZA P

        ON P.ID_POLIZA = F.ID_POLIZA
)


SELECT

    Premium_Amount,

    Premium_Neto,

    (
        Premium_Amount - Premium_Neto
    ) * 1.0 / Premium_Amount AS Porcentaje_Descuento


FROM base;







--11. Clientes con oportunidad de subir precio


SELECT

    c.Cliente_Natural_ID,

    AVG(f.Premium_Amount) AS Prima,

    c.Credit_Score,

    f.Claims_Frequency


FROM fact_insurance f


INNER JOIN DIM_CLIENTE c

    ON f.Cliente_Natural_ID = c.Cliente_Natural_ID


WHERE

    c.Credit_Score > 750

    AND f.Claims_Frequency = 0


GROUP BY

    c.Cliente_Natural_ID,

    c.Credit_Score,

    f.Claims_Frequency;







--12. Rentabilidad por póliza


SELECT

    p.Policy_Type,


    SUM
    (

        f.Premium_Amount

        -

        f.Total_Discounts

        -

        f.Claims_Adjustment


    ) AS Rentabilidad


FROM fact_insurance f


INNER JOIN DIM_POLIZA p

    ON f.ID_POLIZA = p.ID_POLIZA


GROUP BY

    p.Policy_Type


ORDER BY

    Rentabilidad DESC;







--13. Score de conversión


SELECT


    c.Cliente_Natural_ID,


    (

        f.Website_Visits

        +

        f.Quotes_Requested

        +

        (c.Credit_Score / 100)

        -

        f.Time_to_Conversion


    ) AS Conversion_Score


FROM fact_insurance f


JOIN DIM_CLIENTE c

    ON c.Cliente_Natural_ID = f.Cliente_Natural_ID;








--14. KPI ejecutivo final


SELECT


    r.Region,


    l.Source_of_Lead,


    AVG(f.Premium_Amount) AS Prima,


    AVG(f.Total_Discounts) AS Descuento,


    AVG

    (

        CASE

            WHEN f.Conversion_Status = 1

            THEN 1

            ELSE 0

        END

    ) * 100 AS Conversion



FROM fact_insurance f



JOIN DIM_REGION r

    ON f.ID_REGION = r.ID_REGION



JOIN DIM_LEAD l

    ON f.ID_LEAD = l.ID_LEAD



GROUP BY

    r.Region,

    l.Source_of_Lead



ORDER BY

    Prima DESC;








--15. ¿Cómo influye el nivel de riesgo del cliente, tipo de póliza y región en el precio promedio del seguro?

WITH Segmentacion AS

(

    SELECT


        f.Premium_Amount,


        p.Policy_Type,


        r.Region,


        CASE


            WHEN f.Claims_Frequency >= 2

             AND c.Credit_Score < 650

            THEN 'Alto Riesgo'



            WHEN f.Claims_Frequency = 0

             AND c.Credit_Score >= 750

            THEN 'Bajo Riesgo'



            ELSE 'Riesgo Medio'


        END AS Segmento_Riesgo



    FROM fact_insurance f



    INNER JOIN DIM_CLIENTE c

        ON f.Cliente_Natural_ID = c.Cliente_Natural_ID



    INNER JOIN DIM_POLIZA p

        ON f.ID_POLIZA = p.ID_POLIZA



    INNER JOIN DIM_REGION r

        ON f.ID_REGION = r.ID_REGION

)



SELECT


    Segmento_Riesgo,


    Policy_Type,


    Region,


    COUNT(*) AS Cantidad_Clientes,


    AVG(Premium_Amount) AS Prima_Promedio



FROM Segmentacion



GROUP BY


    Segmento_Riesgo,

    Policy_Type,

    Region



ORDER BY

    Prima_Promedio DESC;