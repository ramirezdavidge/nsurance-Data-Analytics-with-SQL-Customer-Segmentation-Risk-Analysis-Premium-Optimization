
# Proyecto SQL: Análisis de Seguros de Auto - Riesgo, Conversión y Optimización de Primas

## Resumen (Overview)

Las compañías aseguradoras necesitan comprender el comportamiento de sus clientes, identificar segmentos de riesgo, optimizar el precio de las pólizas y mejorar sus estrategias comerciales.

Sin embargo, el análisis tradicional de datos dificulta obtener una visión integral sobre factores como conversión comercial, rentabilidad, comportamiento del cliente y variables que influyen en la determinación de primas.

El objetivo de este proyecto es construir un modelo analítico utilizando **SQL Server**, aplicando procesos de limpieza, transformación y modelamiento dimensional para analizar información relacionada con clientes, pólizas, regiones, historial asegurador y comportamiento comercial.

El proyecto permite responder preguntas estratégicas relacionadas con:

- Generación de ingresos.
- Segmentación de clientes.
- Riesgo financiero.
- Efectividad de descuentos.
- Optimización de precios.
- Conversión comercial.

---

# 📩 Contacto

<p align="center">
  <a href="https://www.linkedin.com/in/david-ramirez-7612752bb/">
    <img src="https://img.shields.io/badge/LinkedIn-0077B5?style=flat-square&logo=linkedin&logoColor=white" />
  </a>
</p>

# Estructura del Proyecto

- [Sobre los Datos](#sobre-los-datos)
- [Arquitectura del Data Warehouse](#arquitectura-del-data-warehouse)
- [Limpieza de Datos](#limpieza-de-datos)
- [Modelo Dimensional](#modelo-dimensional)
- [Análisis Exploratorio de Datos](#análisis-exploratorio-de-datos)
- [Insights](#insights)

# Sobre los Datos

Los datos utilizados pertenecen al dataset:

[Insurance Data Personal Auto Line of Business - Kaggle](https://www.kaggle.com/datasets/samialyasin/insurance-data-personal-auto-line-of-business)

El dataset contiene información relacionada con:

- Características demográficas del cliente.
- Información de pólizas.
- Historial previo de seguros.
- Comportamiento comercial.
- Frecuencia y severidad de reclamos.
- Ajustes aplicados sobre la prima.

![image_alt]([https://github.com/f3rnandor/test123/blob/4f17798d4f71dfb932ca020ca256bc5d768aef88/github-logo.png](https://github.com/ramirezdavidge/nsurance-Data-Analytics-with-SQL-Customer-Segmentation-Risk-Analysis-Premium-Optimization/blob/0604893f2957c806254271e22504103327f483c4/Pictures/Dataset.PNG))
![Insurance Dataset](.\Pictures\Dataset.PNG)

## Principales variables analizadas

| Grupo | Variables |
|---|---|
| Cliente | Edad, estado civil, crédito, senioridad |
| Seguro | Tipo de póliza, historial previo |
| Riesgo | Frecuencia y severidad de reclamos |
| Comercial | Leads, visitas web, cotizaciones |
| Financiero | Prima, descuentos y ajustes |



# Arquitectura del Data Warehouse

Para facilitar el análisis se construyó una arquitectura dimensional basada en un modelo estrella.

La arquitectura está compuesta por:

- Capa Stage para almacenamiento inicial.
- Dimensiones descriptivas.
- Tabla de hechos con métricas analíticas.

---

# Tabla Stage

La tabla `STG_SEGURO_AUTO` representa la primera capa del proceso ETL.

Su función es almacenar la información original del CSV antes de realizar transformaciones.

## Procesos aplicados

- Carga del dataset mediante `BULK INSERT`.
- Creación de identificador natural del cliente.
- Validación de calidad de datos.
- Revisión de valores inconsistentes.

---

# Limpieza de Datos

Antes del modelamiento dimensional se realizó un proceso de limpieza para garantizar consistencia y calidad en la información.

## Tratamiento de valores nulos

Se revisaron campos críticos como:

- Credit Score.
- Claims Frequency.
- Variables comerciales.

Los valores faltantes fueron tratados utilizando valores predeterminados para evitar errores durante el análisis.

## Eliminación de registros duplicados

Se utilizó la función:

```sql
ROW_NUMBER()
OVER(
    PARTITION BY Cliente_Natural_ID
    ORDER BY Cliente_Natural_ID
)
```

para identificar registros repetidos y conservar únicamente la información válida.

---

# Modelo Dimensional

El modelo final sigue una arquitectura tipo estrella.

![Insurance Dataset](.\Pictures\MODELOER.PNG)

## Dimensiones

### DIM_CLIENTE

Contiene información demográfica y financiera del asegurado:

- Edad.
- Estado civil.
- Crédito.
- Perfil del cliente.

### DIM_POLIZA

Permite analizar el comportamiento según:

- Tipo de póliza.
- Ajustes aplicados.

### DIM_REGION

Permite analizar diferencias geográficas del negocio.

### DIM_LEAD

Contiene información relacionada con canales comerciales:

- Fuente del lead.
- Captación.
- Conversión.

### DIM_PRIOR_INSURANCE

Permite evaluar el impacto del historial previo de seguros.

---
## Creación de Dimensiones

### DIM_CLIENTE

```sql
WITH t_dim_cliente AS (
    SELECT
        Cliente_Natural_ID,
        Age,
        Is_Senior,
        Marital_Status,
        Credit_Score
    FROM STG_SEGURO_AUTO
)
SELECT *
INTO DIM_CLIENTE
FROM t_dim_cliente;
```

### DIM_POLIZA

```sql
WITH T_DIM_POLIZA AS (
    SELECT DISTINCT
        Policy_Type,
        Policy_Adjustment
    FROM STG_SEGURO_AUTO
)
SELECT
    SUM(1) OVER (ORDER BY Policy_Type DESC) AS ID_POLIZA,
    *
INTO DIM_POLIZA
FROM T_DIM_POLIZA;
```

### DIM_REGION

```sql
WITH T_DIM_REGION AS (
    SELECT DISTINCT
        Region,
        Premium_Adjustment_Region
    FROM STG_SEGURO_AUTO
)
SELECT
    SUM(1) OVER (ORDER BY Region DESC) AS ID_REGION,
    *
INTO DIM_REGION
FROM T_DIM_REGION;
```

### DIM_LEAD

```sql
WITH T_DIM_LEAD AS (
    SELECT DISTINCT
        Source_of_Lead
    FROM STG_SEGURO_AUTO
)
SELECT
    SUM(1) OVER (ORDER BY Source_of_Lead DESC) AS ID_LEAD,
    *
INTO DIM_LEAD
FROM T_DIM_LEAD;
```

### DIM_PRIOR_INSURANCE

```sql
WITH T_DIM_INSURANCE AS (
    SELECT DISTINCT
        Prior_Insurance,
        Prior_Insurance_Premium_Adjustment
    FROM STG_SEGURO_AUTO
)
SELECT
    SUM(1) OVER (ORDER BY Prior_Insurance DESC) AS ID_PRIOR_INSURANCE,
    *
INTO DIM_PRIOR_INSURANCE
FROM T_DIM_INSURANCE;
```

# Tabla de Hechos

## FACT_INSURANCE

Contiene las métricas principales del análisis:

- Prima generada.
- Descuentos.
- Reclamos.
- Conversión.
- Actividad comercial.
- Ajustes financieros.

---
## Creación de la Tabla de Hechos

### FACT_INSURANCE

```sql
WITH t_fact_insurance AS (
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
    LEFT JOIN DIM_POLIZA p
        ON s.Policy_Type = p.Policy_Type
    LEFT JOIN DIM_REGION r
        ON s.Region = r.Region
    LEFT JOIN DIM_LEAD l
        ON s.Source_of_Lead = l.Source_of_Lead
    LEFT JOIN DIM_PRIOR_INSURANCE i
        ON s.Prior_Insurance = i.Prior_Insurance
)
SELECT *
INTO FACT_INSURANCE
FROM t_fact_insurance;
```
# Análisis Exploratorio de Datos (EDA) e Insights

## Pregunta #1
## ¿Cuál es la prima promedio según el tipo de póliza y región?

### Objetivo de la consulta

Identificar qué combinaciones entre tipo de póliza y región generan las primas promedio más altas.

Esto permite conocer los segmentos con mayor valor económico y detectar oportunidades comerciales para la aseguradora.

### Código SQL

```sql
SELECT
    p.Policy_Type,
    r.Region,
    AVG(f.Premium_Amount) AS Prima_Promedio
FROM FACT_INSURANCE f
INNER JOIN DIM_POLIZA p
    ON f.ID_POLIZA = p.ID_POLIZA
INNER JOIN DIM_REGION r
    ON f.ID_REGION = r.ID_REGION
GROUP BY
    p.Policy_Type,
    r.Region
ORDER BY
    Prima_Promedio DESC;
```

### Respuesta e Insight

La mayor prima promedio corresponde a Full Coverage en la región Urban ($2334.74$), evidenciando  que la cobertura total supera consistentemente a la básica y las zonas densas a las rurales. El insight comercial clave es que la aseguradora debe priorizar estrategias de cross-selling para migrar clientes de Liability-Only a Full Coverage, concentrando los esfuerzos en ciudades y suburbios por su mayor valor económico.

### Resultados

![Resultados Pregunta 1](./Pictures/P1.png)

---

## Pregunta #2
## ¿Cuál es el ratio de conversion en comparación con los leads?

### Objetivo de la consulta

Determinar cuantas conversiones se logran en función de los leads

Esto permite evaluar la efectividad de las estrategias de adquisición.

### Código SQL

```sql
SELECT
    l.Source_of_Lead,
    SUM(
        CASE
            WHEN f.Conversion_Status = 1 THEN 1
            ELSE 0
        END
    ) AS Conversiones,
    COUNT(*) AS Total_Leads,
    CAST(
        SUM(
            CASE
                WHEN f.Conversion_Status = 1 THEN 1
                ELSE 0
            END
        ) * 1.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS Ratio_Conversion
FROM FACT_INSURANCE f
INNER JOIN DIM_LEAD l
    ON f.ID_LEAD = l.ID_LEAD
GROUP BY
    l.Source_of_Lead
ORDER BY
    Ratio_Conversion DESC;
```

### Respuesta e Insight


El ratio de conversión del 60% respecto a los leads es un rendimiento extraordinario que supera drásticamente el estándar promedio de la industria, el cual suele oscilar entre el 2% y el 15%. El insight comercial clave es que este porcentaje demuestra una calidad de prospección impecable y una alta efectividad en el cierre de ventas; por lo tanto, la estrategia de la organización no debe centrarse en elevar este indicador, sino en aumentar agresivamente el volumen de captación de leads para escalar masivamente los ingresos aprovechando un embudo que ya está optimizado.
### Resultados

![Resultados Pregunta 2](./Pictures/P2.png)

---

## Pregunta #3
## ¿Cuál es el impacto de los descuentos sobre la prima final?

### Objetivo de la consulta

Analizar cómo los descuentos afectan el valor final de la prima cobrada.

Permite evaluar si las estrategias de descuentos aumentan la conversión sin afectar significativamente la rentabilidad.

### Código SQL

```sql
SELECT
    CASE
        WHEN Total_Discounts > 100 THEN 'Alto Descuento'
        ELSE 'Descuento Normal'
    END AS Categoria_Descuento,
    AVG(Premium_Amount) AS Prima_Promedio,
    AVG(Total_Discounts) AS Descuento_Promedio
FROM FACT_INSURANCE
GROUP BY
    CASE
        WHEN Total_Discounts > 100 THEN 'Alto Descuento'
        ELSE 'Descuento Normal'
    END;
```

### Respuesta e Insight


La mayor prima promedio corresponde a Descuento Normal ($2220.40$), reflejando que la aplicación de la categoría de Alto Descuento reduce el valor final de la prima cobrada a un promedio de $2063.36$. El insight comercial clave es que la estrategia de descuentos impacta negativamente el ingreso final reduciéndolo en aproximadamente un 7% cuando se otorgan rebajas agresivas ($150.00$ en promedio); por tanto, la aseguradora debe evaluar si este sacrificio de margen realmente incrementa la tasa de conversión lo suficiente como para compensar la pérdida de rentabilidad por póliza

### Resultados

![Resultados Pregunta 3](./Pictures/P3.png)

---

## Pregunta #4
## ¿Qué segmentos presentan mayor probabilidad de conversión considerando edad, crédito y estado civil?

### Objetivo de la consulta

Crear perfiles de clientes para identificar qué características demográficas tienen mayor relación con la contratación de seguros.

### Código SQL

```sql
WITH PERFILES AS (
    SELECT
        CASE
            WHEN c.Age BETWEEN 18 AND 25
                AND c.Credit_Score BETWEEN 530 AND 619
                AND UPPER(c.Marital_Status) = 'SINGLE'
                THEN 'Riesgo Alto'
            WHEN c.Age BETWEEN 36 AND 55
                AND c.Credit_Score BETWEEN 620 AND 699
                AND UPPER(c.Marital_Status) IN ('SINGLE', 'MARRIED')
                THEN 'Riesgo Medio'
            WHEN c.Age BETWEEN 56 AND 90
                AND c.Credit_Score >= 700
                AND UPPER(c.Marital_Status) = 'MARRIED'
                THEN 'Riesgo Bajo'
            ELSE 'Sin Perfil'
        END AS Perfil,
        f.Conversion_Status
    FROM FACT_INSURANCE f
    INNER JOIN DIM_CLIENTE c
        ON f.Cliente_Natural_ID = c.Cliente_Natural_ID
)
SELECT
    Perfil,
    SUM(CAST(Conversion_Status AS INT)) AS Conversiones,
    COUNT(*) AS Clientes,
    SUM(CAST(Conversion_Status AS INT)) * 1.0 / COUNT(*) AS Ratio
FROM PERFILES
GROUP BY Perfil;
```

### Respuesta e Insight


El mayor ratio de conversión corresponde al Perfil 3: Riesgo bajo / Buen crédito (62.59%), reflejando  que los clientes de mayor edad (56 a 90 años), casados y con un excelente score crediticio tienen la más alta disposición comercial a contratar seguros. Sin embargo, la gran mayoría del volumen se agrupa en la categoría "Sin perfil" con un ratio muy alto del 57.99%, lo que demuestra que las reglas demográficas actuales son demasiado restrictivas y excluyen el grueso de las ventas; la aseguradora debe flexibilizar los rangos de edad y crédito para capturar de manera formal y estratégica este masivo mercado potencial ya existente.

### Resultados

![Resultados Pregunta 4](./Pictures/P4.png)

---

## Pregunta #5
## ¿Cuál es el impacto del historial previo de seguro en el precio?

### Objetivo de la consulta

Evaluar si la experiencia previa del cliente con seguros modifica el precio promedio de la póliza.

### Código SQL

```sql
SELECT
    p.Prior_Insurance,
    AVG(f.Premium_Amount) AS Prima_Promedio,
    COUNT(*) AS Clientes
FROM FACT_INSURANCE f
INNER JOIN DIM_PRIOR_INSURANCE p
    ON f.ID_PRIOR_INSURANCE = p.ID_PRIOR_INSURANCE
GROUP BY
    p.Prior_Insurance
ORDER BY
    Prima_Promedio DESC;
```

### Respuesta e Insight


La mayor prima promedio corresponde a los clientes con un historial previo de <1 year ($2275.61$), reflejando  que la falta de experiencia o continuidad con seguros eleva el precio final de la póliza. Esta tendencia decreciente demuestra que la aseguradora premia la lealtad y estabilidad del cliente, reduciendo el costo a medida que los años de historial aumentan; por lo tanto, comercialmente se debe priorizar la retención del segmento mayoritario de 1-5 years ($5257$ clientes) mediante renovaciones anticipadas antes de que alcancen el umbral de menor beneficio económico.

### Resultados

![Resultados Pregunta 5](./Pictures/P5.png)

---

## Pregunta #6
## ¿Qué regiones generan mayor facturación?

### Objetivo de la consulta

Identificar las regiones que generan mayores ingresos totales mediante las primas cobradas.

Esto permite conocer mercados geográficos estratégicos para fortalecer campañas comerciales.

### Código SQL

```sql
SELECT
    r.Region,
    SUM(f.Premium_Amount) AS Facturacion,
    RANK() OVER (
        ORDER BY SUM(f.Premium_Amount) DESC
    ) AS Ranking
FROM FACT_INSURANCE f
INNER JOIN DIM_REGION r
    ON f.ID_REGION = r.ID_REGION
GROUP BY
    r.Region
ORDER BY
    Facturacion DESC;
```

### Respuesta e Insight


La mayor facturación total corresponde a Urban ($11104160.00$), reflejando  que el mercado de las grandes ciudades lidera con contundencia el ingreso por primas de la aseguradora, posicionándose en el primer lugar del ranking comercial. Esta abrumadora concentración del negocio, que prácticamente duplica los ingresos obtenidos en la zona rural, demuestra la necesidad de robustecer las campañas de marketing digital y los canales locales en el sector urbano para blindar la plaza más rentable, al mismo tiempo que se evalúan estrategias de penetración más eficientes para dinamizar la captación en los mercados de menor densidad.

### Resultados

![Resultados Pregunta 6](./Pictures/P6.png)

---

## Pregunta #7
## ¿Quiénes son los clientes de mayor valor?

### Objetivo de la consulta

Construir una métrica de valor del cliente considerando:

- Prima generada.
- Nivel crediticio.
- Frecuencia de reclamos.
- Perfil de riesgo.

### Código SQL

```sql
WITH VALOR_CLIENTE AS (
    SELECT
        f.Cliente_Natural_ID,
        (
            f.Premium_Amount
            + c.Credit_Score
            - f.Claims_Frequency
        ) AS Customer_Value_Score
    FROM FACT_INSURANCE f
    INNER JOIN DIM_CLIENTE c
        ON f.Cliente_Natural_ID = c.Cliente_Natural_ID
)
SELECT *
FROM VALOR_CLIENTE
ORDER BY
    Customer_Value_Score DESC;
```

### Respuesta e Insight


Los clientes con mayor puntuación representan oportunidades de fidelización debido a su aporte económico y menor exposición al riesgo.

Este análisis permite identificar clientes estratégicos para campañas personalizadas.

### Resultados

![Resultados Pregunta 7](./Pictures/P7.png)

---

## Pregunta #8
## ¿Qué factores influyen más en la conversión?

### Objetivo de la consulta

Comparar el comportamiento digital y comercial entre clientes convertidos y no convertidos.

Se analizan variables como:

- Visitas web.
- Consultas realizadas.
- Cotizaciones.
- Tiempo de conversión.

### Código SQL

```sql
SELECT
    Conversion_Status,
    AVG(Website_Visits)      AS Visitas,
    AVG(Inquiries)           AS Consultas,
    AVG(Quotes_Requested)    AS Cotizaciones,
    AVG(Time_to_Conversion)  AS Tiempo_Conversion
FROM FACT_INSURANCE
GROUP BY Conversion_Status;
```

### Respuesta e Insight


El factor con mayor impacto diferencial en la conversión corresponde al Tiempo de decisión ($7$ días para los convertidos frente a $99$ días para los no convertidos), reflejando  que la velocidad de respuesta y el cierre temprano son determinantes para asegurar la contratación de la póliza. Esta notable brecha temporal demuestra que los clientes que concretan la compra lo hacen de manera ágil e inmediata con apenas una ligera ventaja en Visitas_Promedio ($5$), mientras que los prospectos estancados acumulan un exceso de consultas y cotizaciones a lo largo del tiempo sin llegar a convertirse; por lo tanto, la organización debe implementar alertas de seguimiento agresivas durante los primeros días desde el contacto inicial para cerrar la venta antes de que el interés del usuario se diluya por completo.

### Resultados

![Resultados Pregunta 8](./Pictures/P8.png)

---

## Pregunta #9
## ¿Cuáles son los clientes con mayor probabilidad de fuga?

### Objetivo de la consulta

Identificar clientes con señales de riesgo considerando:

- Alta frecuencia de reclamos.
- Severidad de reclamos.
- Nivel de riesgo asociado.

Esto permite anticipar posibles pérdidas y aplicar estrategias de retención.

### Código SQL

```sql
SELECT TOP 50
    Cliente_Natural_ID,
    CASE
        WHEN Claims_Frequency >= 3
            AND UPPER(Claims_Severity) = 'HIGH'
            THEN 'Alto Riesgo'
        WHEN Claims_Frequency >= 3
            AND UPPER(Claims_Severity) = 'MEDIUM'
            THEN 'Riesgo Medio-Alto'
        WHEN Claims_Frequency < 3
            AND UPPER(Claims_Severity) = 'HIGH'
            THEN 'Riesgo Medio'
        ELSE 'Bajo Riesgo'
    END AS Nivel_Riesgo
FROM FACT_INSURANCE
ORDER BY
    CASE
        WHEN Claims_Frequency >= 3
            AND UPPER(Claims_Severity) = 'HIGH'
            THEN 1
        WHEN Claims_Frequency >= 3
            AND UPPER(Claims_Severity) = 'MEDIUM'
            THEN 2
        WHEN Claims_Frequency < 3
            AND UPPER(Claims_Severity) = 'HIGH'
            THEN 3
        ELSE 4
    END;
```

### Respuesta e Insight


Los clientes clasificados como alto riesgo requieren atención prioritaria.

La aseguradora puede aplicar acciones preventivas como:

- Beneficios personalizados.
- Seguimiento comercial.
- Mejora de experiencia del cliente.

Esto permite reducir la pérdida de clientes.

### Resultados

![Resultados Pregunta 9](./Pictures/P9.png)

---

## Pregunta #10
## ¿Cuál es el descuento efectivo aplicado después de todos los ajustes?

### Objetivo de la consulta

Determinar el descuento real aplicado considerando:

- Ajustes por póliza.
- Ajustes crediticios.
- Ajustes regionales.

### Código SQL

```sql
WITH BASE AS (
    SELECT
        F.Premium_Amount,
        (
            F.Premium_Amount
            - (
                P.Policy_Adjustment
                + F.Premium_Adjustment_Credit
                + R.Premium_Adjustment_Region
            )
        ) AS Premium_Neto
    FROM FACT_INSURANCE F
    INNER JOIN DIM_REGION R
        ON F.ID_REGION = R.ID_REGION
    INNER JOIN DIM_POLIZA P
        ON F.ID_POLIZA = P.ID_POLIZA
)
SELECT
    Premium_Amount,
    Premium_Neto,
    (Premium_Amount - Premium_Neto) * 1.0 / Premium_Amount AS Porcentaje_Descuento
FROM BASE;
```

### Respuesta e Insight


Esta consulta permite conocer el impacto real de los ajustes sobre la prima inicial.

Ayuda a evaluar si la estrategia de descuentos mantiene un equilibrio entre competitividad comercial y rentabilidad.

### Resultados

![Resultados Pregunta 10](./Pictures/P10.png)

---

## Pregunta #11
## ¿Qué clientes tienen oportunidad de incrementar su precio?

### Objetivo de la consulta

Identificar clientes con características favorables para una posible optimización de precio considerando:

- Buen historial crediticio.
- Baja frecuencia de reclamos.
- Bajo nivel de riesgo.

Estos clientes podrían soportar ajustes controlados en la prima sin incrementar significativamente la probabilidad de pérdida.

### Código SQL

```sql
SELECT
    c.Cliente_Natural_ID,
    AVG(f.Premium_Amount) AS Prima,
    c.Credit_Score,
    f.Claims_Frequency
FROM FACT_INSURANCE f
INNER JOIN DIM_CLIENTE c
    ON f.Cliente_Natural_ID = c.Cliente_Natural_ID
WHERE
    c.Credit_Score > 750
    AND f.Claims_Frequency = 0
GROUP BY
    c.Cliente_Natural_ID,
    c.Credit_Score,
    f.Claims_Frequency;
```

### Respuesta e Insight


Los clientes identificados presentan perfiles atractivos para estrategias de optimización de precios.

Al combinar estabilidad financiera y bajo nivel de siniestralidad, representan oportunidades para incrementar ingresos manteniendo controlado el riesgo.

### Resultados

![Resultados Pregunta 11](./Pictures/P11.png)

---

## Pregunta #12
## ¿Cuál es la rentabilidad generada por tipo de póliza?

### Objetivo de la consulta

Medir qué tipos de póliza generan mayor beneficio económico considerando:

- Prima cobrada.
- Descuentos aplicados.
- Ajustes relacionados con reclamos.

### Código SQL

```sql
SELECT
    p.Policy_Type,
    SUM(
        f.Premium_Amount
        - f.Total_Discounts
        - f.Claims_Adjustment
    ) AS Rentabilidad
FROM FACT_INSURANCE f
INNER JOIN DIM_POLIZA p
    ON f.ID_POLIZA = p.ID_POLIZA
GROUP BY
    p.Policy_Type
ORDER BY
    Rentabilidad DESC;
```

### Respuesta e Insight


La mayor rentabilidad total corresponde a Full Coverage ($13416072.00$), demostrando que a pesar de los descuentos y los mayores ajustes por reclamos que suelen asociarse a las coberturas totales, este producto supera de forma contundente al de cobertura básica. El insight comercial clave es que la aseguradora debe orientar prioritariamente su fuerza de ventas y recursos de marketing a la colocación de pólizas Full Coverage, ya que representan el principal motor financiero y generan un margen de ganancia un 65% mayor en comparación con Liability-Only.

### Resultados

![Resultados Pregunta 12](./Pictures/P12.png)

---

## Pregunta #13
## ¿Cuál es el score de conversión de cada cliente?

### Objetivo de la consulta

Construir una métrica que combine variables asociadas a la intención comercial del cliente:

- Actividad digital.
- Cotizaciones realizadas.
- Tiempo de conversión.
- Nivel crediticio.

### Código SQL

```sql
SELECT
    c.Cliente_Natural_ID,
    (
        f.Website_Visits
        + f.Quotes_Requested
        + (c.Credit_Score / 100)
        - f.Time_to_Conversion
    ) AS Conversion_Score
FROM FACT_INSURANCE f
INNER JOIN DIM_CLIENTE c
    ON f.Cliente_Natural_ID = c.Cliente_Natural_ID;
```

### Respuesta e Insight


El mayor score de conversión inicial corresponde al Cliente_Natural_ID 4 ($14$), indicando que posee la combinación más óptima de alta actividad digital, cotizaciones y un menor tiempo de conversión. El insight comercial clave es la presencia de múltiples scores negativos (como los clientes 1, 2, 3 y 8 con hasta $-88$), lo cual revela que el impacto de la variable Time_to_Conversion está restando excesivo peso a la métrica; la aseguradora debe recalibrar la fórmula aplicando una normalización o un factor de escala para evitar valores negativos y aislar adecuadamente a los prospectos con verdadera intención de compra.

### Resultados

![Resultados Pregunta 13](./Pictures/P13.png)

---

## Pregunta #14
## KPI Ejecutivo: Región, canal comercial y comportamiento de prima

### Objetivo de la consulta

Construir un indicador ejecutivo que integre:

- Región.
- Fuente de captación.
- Prima promedio.
- Descuentos aplicados.
- Conversión comercial.

El objetivo es obtener una visión general del desempeño comercial y financiero.

### Código SQL

```sql
SELECT
    r.Region,
    l.Source_of_Lead,
    AVG(f.Premium_Amount) AS Prima_Promedio,
    AVG(f.Total_Discounts) AS Descuento_Promedio,
    AVG(
        CASE
            WHEN f.Conversion_Status = 1 THEN 1
            ELSE 0
        END
    ) * 100 AS Conversion
FROM FACT_INSURANCE f
INNER JOIN DIM_REGION r
    ON f.ID_REGION = r.ID_REGION
INNER JOIN DIM_LEAD l
    ON f.ID_LEAD = l.ID_LEAD
GROUP BY
    r.Region,
    l.Source_of_Lead
ORDER BY
    Prima_Promedio DESC;
```

### Respuesta e Insight


La mayor prima promedio corresponde a Urban con el canal Online ($2257.33$), mostrando que la captación digital en ciudades lidera sutilmente el valor de póliza, mientras que los descuentos se mantienen estables en todas las regiones. El insight comercial clave y crítico es que la conversión es del 0% en absolutamente todas las combinaciones, lo que revela un problema urgente en el registro de datos del embudo de ventas o una nula efectividad en la estrategia de cierre comercial.

### Resultados

![Resultados Pregunta 14](./Pictures/P14.png)

---

## Pregunta #15
## ¿Cómo influye el nivel de riesgo, tipo de póliza y región en el precio promedio del seguro?

### Objetivo de la consulta

Analizar cómo los perfiles de riesgo influyen en la estrategia de precios.

Se consideran variables como:

- Frecuencia de reclamos.
- Crédito del cliente.
- Tipo de póliza.
- Región.

### Código SQL

```sql
WITH SEGMENTACION AS (
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
    FROM FACT_INSURANCE f
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
    COUNT(*) AS Clientes,
    AVG(Premium_Amount) AS Prima_Promedio
FROM SEGMENTACION
GROUP BY
    Segmento_Riesgo,
    Policy_Type,
    Region
ORDER BY
    Prima_Promedio DESC;
```

### Respuesta e Insight


La mayor prima promedio corresponde a Alto Riesgo con Full Coverage en la región Urban ($2479.21$), demostrando que el nivel de riesgo es el factor más determinante en el precio, ya que los segmentos de Alto Riesgo ocupan los primeros puestos tarifarios incluso con coberturas básicas. El insight comercial clave es que la aseguradora penaliza correctamente el perfil de alta siniestralidad y bajo crédito; sin embargo, el grueso de la facturación masiva sigue concentrado en los clientes de Riesgo Medio en zonas urbanas debido a su elevado volumen.

### Resultados

![Resultados Pregunta 15](./Pictures/P15.png)

---


# Conclusiones Generales del Proyecto

El análisis permitió identificar patrones clave sobre rentabilidad, comportamiento del cliente y efectividad comercial dentro del sector asegurador.

- **Producto estrella:** Full Coverage lidera en prima promedio ($2,334.74$) y rentabilidad total ($13,416,072.00$), superando a Liability-Only en un 65%. Debe ser el foco principal de ventas.

- **Mercado prioritario:** Urban concentra la mayor facturación ($11,104,160.00$), duplicando a la zona rural. Es la plaza más rentable y debe blindarse comercialmente.

- **Descuentos:** Los descuentos agresivos reducen la prima en ~7%. Su aplicación debe condicionarse a un incremento de conversión que compense la pérdida de margen.

- **Conversión:** El ratio del 60% supera el estándar de la industria (2%-15%). El embudo está optimizado; la prioridad es aumentar el volumen de captación de leads.

- **Tiempo de cierre:** Los clientes convertidos deciden en 7 días frente a los 99 días de los no convertidos. El seguimiento en los primeros días del contacto es crítico.

- **Segmentación:** El perfil de mayor conversión son clientes de 56-90 años, casados y con buen crédito (62.59%). Sin embargo, el 57.99% de las ventas cae fuera de los perfiles definidos, lo que indica que las reglas actuales son demasiado restrictivas.

- **Riesgo y precio:** Los clientes de Alto Riesgo con Full Coverage en Urban alcanzan la prima más alta ($2,479.21$), confirmando que la siniestralidad es el principal determinante tarifario.

- **Alertas técnicas:** El score de conversión genera valores negativos por el peso excesivo de Time_to_Conversion y debe recalibrarse. El KPI ejecutivo registra 0% de conversión en todas las combinaciones, lo que requiere una auditoría urgente del registro de datos.
