
-- SQL script to create a database and tables for a mobile service provider's analytics
CREATE DATABASE telecom_analytics_db;

-- SQL script to create tables for a mobile service provider's database
DROP TABLE IF EXISTS UsageRecords;
DROP TABLE IF EXISTS Plans;
DROP TABLE IF EXISTS Devices;
DROP TABLE IF EXISTS Subscribers;

CREATE TABLE Subscribers (
    SubscriberID   INT PRIMARY KEY,
    FullName       VARCHAR(100) NOT NULL,
    Region         VARCHAR(50)  NOT NULL,
    JoinDate       DATE NOT NULL
);

CREATE TABLE Plans (
    PlanID     INT PRIMARY KEY,
    PlanName   VARCHAR(80) NOT NULL,
    DataGB     INT NOT NULL,
    MonthlyFee DECIMAL(10,2) NOT NULL
);

CREATE TABLE Devices (
    DeviceID    INT PRIMARY KEY,
    DeviceName  VARCHAR(100) NOT NULL,
    Brand       VARCHAR(50) NOT NULL
);

CREATE TABLE UsageRecords (
    UsageID        INT PRIMARY KEY,
    UsageDate      DATE NOT NULL,
    SubscriberID   INT NOT NULL,
    PlanID         INT NOT NULL,
    DeviceID       INT NOT NULL,
    DataUsedGB     DECIMAL(6,2) NOT NULL,
    CallMinutes    INT NOT NULL,
    SMSCount       INT NOT NULL,
    ChargeAmount   DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_usage_subscriber FOREIGN KEY (SubscriberID) REFERENCES Subscribers(SubscriberID),
    CONSTRAINT fk_usage_plan       FOREIGN KEY (PlanID) REFERENCES Plans(PlanID),
    CONSTRAINT fk_usage_device     FOREIGN KEY (DeviceID) REFERENCES Devices(DeviceID)
);

-- Sample data insertion
INSERT INTO Subscribers VALUES
(1, 'Aline Mukamana', 'Gasabo', '2024-01-10'),
(2, 'Jean Nkurunziza', 'Kicukiro', '2024-02-05'),
(3, 'Eric Habimana', 'Rwamagana', '2024-03-12'),
(4, 'Diane Uwimana', 'Rubavu', '2024-04-01'),
(5, 'Patrick Habyarimana', 'Rusizi', '2024-05-18'),
(6, 'Chantal Niyonzima', 'Gasabo', '2024-06-03');

INSERT INTO Plans VALUES
(201, 'Basic 5GB', 5, 10.00),
(202, 'Standard 15GB', 15, 20.00),
(203, 'Premium 40GB', 40, 35.00);

INSERT INTO Devices VALUES
(301, 'Galaxy A32', 'Samsung'),
(302, 'iPhone 12', 'Apple'),
(303, 'Redmi Note 11', 'Xiaomi');

INSERT INTO UsageRecords VALUES
(1001, '2025-10-05', 1, 202, 301, 6.5, 120, 45, 22.00),
(1002, '2025-10-10', 2, 201, 303, 3.1, 80, 30, 11.00),
(1003, '2025-10-15', 3, 203, 302, 18.4, 240, 60, 38.00),
(1004, '2025-11-02', 4, 202, 301, 10.2, 150, 50, 24.00),
(1005, '2025-11-10', 5, 203, 302, 30.5, 300, 90, 42.00),
(1006, '2025-12-01', 1, 201, 301, 4.2, 70, 20, 10.00),
(1007, '2026-01-05', 6, 202, 303, 12.0, 160, 55, 25.00);

-- INNER JOIN

SELECT
    u.UsageID,
    u.UsageDate,
    s.FullName,
    s.Region,
    p.PlanName,
    d.DeviceName,
    u.DataUsedGB,
    u.CallMinutes,
    u.ChargeAmount
FROM UsageRecords u
INNER JOIN Subscribers s ON u.SubscriberID = s.SubscriberID
INNER JOIN Plans p ON u.PlanID = p.PlanID
INNER JOIN Devices d ON u.DeviceID = d.DeviceID
ORDER BY u.UsageDate;

-- LEFT JOIN

SELECT
    s.SubscriberID,
    s.FullName,
    s.Region,
    u.UsageID
FROM Subscribers s
LEFT JOIN UsageRecords u ON s.SubscriberID = u.SubscriberID
WHERE u.UsageID IS NULL;

-- RIGHT JOIN

SELECT
    p.PlanID,
    p.PlanName,
    p.MonthlyFee,
    u.UsageID
FROM UsageRecords u
RIGHT JOIN Plans p ON u.PlanID = p.PlanID
WHERE u.UsageID IS NULL;

-- FULL OUTER JOIN

SELECT
    s.SubscriberID,
    s.FullName,
    p.PlanName,
    u.UsageID,
    u.ChargeAmount
FROM Subscribers s
FULL OUTER JOIN UsageRecords u ON s.SubscriberID = u.SubscriberID
FULL OUTER JOIN Plans p ON u.PlanID = p.PlanID
ORDER BY s.SubscriberID;

-- SELF JOIN

SELECT
    u1.UsageID AS Usage1,
    u2.UsageID AS Usage2,
    s1.Region,
    u1.DataUsedGB AS Data1,
    u2.DataUsedGB AS Data2,
    (u1.DataUsedGB - u2.DataUsedGB) AS DataDiff
FROM UsageRecords u1
JOIN UsageRecords u2 ON u1.UsageID < u2.UsageID
JOIN Subscribers s1 ON u1.SubscriberID = s1.SubscriberID
JOIN Subscribers s2 ON u2.SubscriberID = s2.SubscriberID
AND s1.Region = s2.Region;

-- RANKING FUNCTIONS

WITH region_usage AS (
    SELECT
        s.Region,
        s.SubscriberID,
        s.FullName,
        SUM(u.DataUsedGB) AS TotalData
    FROM UsageRecords u
    JOIN Subscribers s ON u.SubscriberID = s.SubscriberID
    GROUP BY s.Region, s.SubscriberID, s.FullName
)
SELECT
    Region,
    SubscriberID,
    FullName,
    TotalData,
    RANK() OVER (PARTITION BY Region ORDER BY TotalData DESC) AS Rank,
    DENSE_RANK() OVER (PARTITION BY Region ORDER BY TotalData DESC) AS DenseRank
FROM region_usage;

-- AGGREGATE WINDOW FUNCTIONS

SELECT
    UsageDate,
    UsageID,
    ChargeAmount,
    SUM(ChargeAmount) OVER (ORDER BY UsageDate ROWS UNBOUNDED PRECEDING) AS RunningTotal,
    AVG(ChargeAmount) OVER (ORDER BY UsageDate ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS MovingAvg
FROM UsageRecords
ORDER BY UsageDate;

-- NAVIGATION FUNCTIONS

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', UsageDate) AS UsageMonth,
        SUM(ChargeAmount) AS Revenue
    FROM UsageRecords
    GROUP BY DATE_TRUNC('month', UsageDate)
)
SELECT
    UsageMonth,
    Revenue,
    LAG(Revenue) OVER (ORDER BY UsageMonth) AS PrevMonth,
    (Revenue - LAG(Revenue) OVER (ORDER BY UsageMonth)) AS Growth
FROM monthly_revenue;

-- DISTRIBUTION FUNCTIONS

WITH subscriber_spend AS (
    SELECT
        s.SubscriberID,
        s.FullName,
        SUM(u.ChargeAmount) AS TotalSpend
    FROM Subscribers s
    LEFT JOIN UsageRecords u ON s.SubscriberID = u.SubscriberID
    GROUP BY s.SubscriberID, s.FullName
)
SELECT
    SubscriberID,
    FullName,
    TotalSpend,
    NTILE(4) OVER (ORDER BY TotalSpend DESC) AS Quartile,
    CUME_DIST() OVER (ORDER BY TotalSpend DESC) AS CumulativeDist
FROM subscriber_spend;