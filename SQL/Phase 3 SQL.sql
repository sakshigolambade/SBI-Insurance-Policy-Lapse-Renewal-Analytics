/* =================================================================
PHASE 3: SQL SERVER
Project: Insurance Policy Lapse & Renewal Analytics (SBI General)
Input  : Staging_PolicyData (imported from SBI_Insurance_Data_Phase2_Final.csv)
==================================================================== */
 
 
/* -----------------------------------------------------------------
STEP 1: CREATE DATABASE
-------------------------------------------------------------------- */
CREATE DATABASE SBIGeneralInsuranceDB;
GO
USE SBIGeneralInsuranceDB;
GO
 
 
/* -----------------------------------------------------------------
STEP 2: IMPORT CSV
Done via SSMS: right-click DB -> Tasks -> Import Flat File
-> point to SBI_Insurance_Data_Phase2_Final.csv
-> name the staging table: Staging_PolicyData
(No SQL needed for this step - it's GUI driven.)
-------------------------------------------------------------------- */
 
 
/* -----------------------------------------------------------------
STEP 3: VERIFY STAGING DATA LOADED CORRECTLY
-------------------------------------------------------------------- */
SELECT COUNT(*) AS TotalRows FROM Staging_PolicyData;
SELECT TOP 10 * FROM Staging_PolicyData;
GO
 
 
/* -----------------------------------------------------------------
STEP 4: BUILD NORMALIZED SCHEMA
Three tables: Customers, Policies, Claims
Industry practice: separate entities, primary/foreign keys,
sensible data types (not everything as VARCHAR/FLOAT).
-------------------------------------------------------------------- */
 
-- 4a. Customers table
CREATE TABLE Customers (
    CustomerID       INT IDENTITY(1,1) PRIMARY KEY,
    PolicyID         VARCHAR(20)   NOT NULL,   -- kept to link back during migration
    CustomerName     VARCHAR(100)  NOT NULL,
    Age              INT           NULL,
    Gender           VARCHAR(10)   NULL,
    City             VARCHAR(50)   NULL,
    State            VARCHAR(50)   NULL,
    ContactNumber    VARCHAR(15)   NULL,
    Email            VARCHAR(100)  NULL,
    Occupation       VARCHAR(50)   NULL,
    AgeBand          VARCHAR(10)   NULL
);
GO
 
-- 4b. Policies table
CREATE TABLE Policies (
    PolicyID              VARCHAR(20)     PRIMARY KEY,
    CustomerID            INT             NOT NULL,
    PolicyType            VARCHAR(50)     NULL,
    SalesChannel          VARCHAR(30)     NULL,
    PolicyStartDate       DATE            NULL,
    RenewalDueDate        DATE            NULL,
    PolicyTenureYears     INT             NULL,
    PaymentFrequency      VARCHAR(20)     NULL,
    PremiumAmount         DECIMAL(12,2)   NULL,
    SumInsured            DECIMAL(14,2)   NULL,
    PolicyStatus          VARCHAR(20)     NULL,
    PolicyAgeInDays       INT             NULL,
    DaysToRenewal         INT             NULL,
    PremiumPerYearOfTenure DECIMAL(12,2)  NULL,
    IsHighRiskCustomer    BIT             NULL,
    CONSTRAINT FK_Policies_Customers FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID)
);
GO

-- 4c. Claims table
CREATE TABLE Claims (
    ClaimRecordID      INT IDENTITY(1,1) PRIMARY KEY,
    PolicyID           VARCHAR(20)     NOT NULL,
    ClaimsCount        INT             NULL,
    TotalClaimAmount   DECIMAL(14,2)   NULL,
    ClaimFrequencyRatio DECIMAL(8,3)   NULL,
    CONSTRAINT FK_Claims_Policies FOREIGN KEY (PolicyID)
        REFERENCES Policies(PolicyID)
);
GO

ALTER TABLE Claims ADD CONSTRAINT UQ_Claims_PolicyID UNIQUE (PolicyID);
/* -----------------------------------------------------------------
STEP 5: MIGRATE DATA FROM STAGING INTO NORMALIZED TABLES
-------------------------------------------------------------------- */
-- 5a. Populate Customers (one row per policy for now - acceptable since
-- our synthetic data has 1 policy per customer record)
INSERT INTO Customers (PolicyID, CustomerName, Age, Gender, City, State,
                        ContactNumber, Email, Occupation, AgeBand)
SELECT
    PolicyID,
    CustomerName,
    Age,
    Gender,
    City,
    State,
    ContactNumber,
    Email,
    Occupation,
    AgeBand
FROM Staging_PolicyData;
GO

-- 5b. Populate Policies (join back to Customers on PolicyID to get CustomerID)
INSERT INTO Policies (PolicyID, CustomerID, PolicyType, SalesChannel,
                       PolicyStartDate, RenewalDueDate, PolicyTenureYears,
                       PaymentFrequency, PremiumAmount, SumInsured, PolicyStatus,
                       PolicyAgeInDays, DaysToRenewal, PremiumPerYearOfTenure,
                       IsHighRiskCustomer)
SELECT
    s.PolicyID,
    c.CustomerID,
    s.PolicyType,
    s.SalesChannel,
    TRY_CONVERT(DATE, s.PolicyStartDate),
    TRY_CONVERT(DATE, s.RenewalDueDate),
    s.PolicyTenureYears,
    s.PaymentFrequency,
    s.PremiumAmount,
    s.SumInsured,
    s.PolicyStatus,
    s.PolicyAgeInDays,
    s.DaysToRenewal,
    s.PremiumPerYearOfTenure,
    CAST(s.IsHighRiskCustomer AS BIT)
FROM Staging_PolicyData s
JOIN Customers c ON c.PolicyID = s.PolicyID;
GO

-- 5c. Populate Claims
INSERT INTO Claims (PolicyID, ClaimsCount, TotalClaimAmount, ClaimFrequencyRatio)
SELECT
    PolicyID,
    ClaimsCount,
    TotalClaimAmount,
    ClaimFrequencyRatio
FROM Staging_PolicyData;
GO

/* -----------------------------------------------------------------
STEP 6: VALIDATE THE MIGRATION
Row counts should match staging row count across all three tables
(Customers/Policies should equal staging row count; Claims too,
since it's 1:1 with policies here).
-------------------------------------------------------------------- */
SELECT 'Staging' AS TableName, COUNT(*) AS [RowCount] FROM Staging_PolicyData
UNION ALL
SELECT 'Customers', COUNT(*) FROM Customers
UNION ALL
SELECT 'Policies', COUNT(*) FROM Policies
UNION ALL
SELECT 'Claims', COUNT(*) FROM Claims;
GO

/* -----------------------------------------------------------------
STEP 7: INDEXES FOR QUERY PERFORMANCE
Industry standard: index foreign keys and commonly filtered columns.
-------------------------------------------------------------------- */
CREATE INDEX IX_Policies_PolicyStatus ON Policies(PolicyStatus);
CREATE INDEX IX_Policies_PolicyType ON Policies(PolicyType);
CREATE INDEX IX_Policies_CustomerID ON Policies(CustomerID);
CREATE INDEX IX_Claims_PolicyID ON Claims(PolicyID);
GO

 
/* -----------------------------------------------------------------
STEP 8: ANALYTICAL QUERIES
-------------------------------------------------------------------- */
-- 8a. Lapse rate by policy type (CTE)
WITH LapseByType AS (
    SELECT
        PolicyType,
        COUNT(*) AS TotalPolicies,
        SUM(CASE WHEN PolicyStatus = 'Lapsed' THEN 1 ELSE 0 END) AS LapsedPolicies
    FROM Policies
    GROUP BY PolicyType
)
SELECT
    PolicyType,
    TotalPolicies,
    LapsedPolicies,
    CAST(LapsedPolicies * 100.0 / TotalPolicies AS DECIMAL(5,2)) AS LapseRatePct
FROM LapseByType
ORDER BY LapseRatePct DESC;
GO

-- 8b. Lapse rate by payment frequency (CTE)
WITH LapseByFreq AS (
    SELECT
        PaymentFrequency,
        COUNT(*) AS TotalPolicies,
        SUM(CASE WHEN PolicyStatus = 'Lapsed' THEN 1 ELSE 0 END) AS LapsedPolicies
    FROM Policies
    GROUP BY PaymentFrequency
)
SELECT
    PaymentFrequency,
    TotalPolicies,
    LapsedPolicies,
    CAST(LapsedPolicies * 100.0 / TotalPolicies AS DECIMAL(5,2)) AS LapseRatePct
FROM LapseByFreq
ORDER BY LapseRatePct DESC;
GO

-- 8c. Rank cities by lapse count (window function: RANK)
SELECT
    c.City,
    COUNT(*) AS LapsedCount,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS CityRank
FROM Policies p
JOIN Customers c ON c.CustomerID = p.CustomerID
WHERE p.PolicyStatus = 'Lapsed'
GROUP BY c.City
ORDER BY CityRank;
GO

-- 8d. Renewal trend: premium change vs each customer's previous policy
-- (window function: LAG) - here ordered by PolicyStartDate per city as
-- a proxy trend line since each customer has a single policy in this dataset
SELECT
    c.City,
    p.PolicyStartDate,
    p.PremiumAmount,
    LAG(p.PremiumAmount) OVER (PARTITION BY c.City ORDER BY p.PolicyStartDate) AS PrevPremium,
    p.PremiumAmount - LAG(p.PremiumAmount) OVER (PARTITION BY c.City ORDER BY p.PolicyStartDate) AS PremiumChange
FROM Policies p
JOIN Customers c ON c.CustomerID = p.CustomerID
ORDER BY c.City, p.PolicyStartDate;
GO

-- 8e. High-value claims report (join across all 3 tables)
SELECT
    p.PolicyID,
    c.CustomerName,
    p.PolicyType,
    cl.TotalClaimAmount,
    p.PolicyStatus
FROM Claims cl
JOIN Policies p ON p.PolicyID = cl.PolicyID
JOIN Customers c ON c.CustomerID = p.CustomerID
WHERE cl.TotalClaimAmount > 30000
ORDER BY cl.TotalClaimAmount DESC;
GO

/* -----------------------------------------------------------------
 STEP 9: STORED PROCEDURE - flag at-risk policyholders
   Reusable, parameterized, and callable from Power BI or an app.
   Uses ABS(DaysToRenewal) since this dataset's renewal dates are
   mostly in the past relative to the fixed analysis date used in
   Phase 2 - this catches both overdue and upcoming renewals.
-------------------------------------------------------------------- */
CREATE PROCEDURE sp_GetAtRiskPolicyholders
    @DaysWindow INT = 60,
    @MaxTenureYears INT = 1
AS
BEGIN
    SET NOCOUNT ON;
 
    SELECT
        p.PolicyID,
        c.CustomerName,
        p.PolicyType,
        p.PaymentFrequency,
        p.PolicyTenureYears,
        p.DaysToRenewal,
        p.PremiumAmount,
        p.IsHighRiskCustomer
    FROM Policies p
    JOIN Customers c ON c.CustomerID = p.CustomerID
    WHERE ABS(p.DaysToRenewal) <= @DaysWindow
      AND p.PolicyTenureYears <= @MaxTenureYears
      AND p.PolicyStatus <> 'Lapsed'
    ORDER BY ABS(p.DaysToRenewal) ASC;
END;
GO

-- Example call:
EXEC sp_GetAtRiskPolicyholders @DaysWindow = 60, @MaxTenureYears = 1;
GO

/* -----------------------------------------------------------------
STEP 10: VIEW FOR POWER BI
This is the single object Power BI will connect to in Phase 4.
Keeping business logic here (in SQL) rather than in DAX keeps the
report simpler and the logic centralized/reusable.
-------------------------------------------------------------------- */
CREATE VIEW vw_LapseRiskSummary AS
SELECT
    p.PolicyID,
    c.CustomerName,
    c.Age,
    c.AgeBand,
    c.Gender,
    c.City,
    c.State,
    c.Occupation,
    p.PolicyType,
    p.SalesChannel,
    p.PolicyStartDate,
    p.RenewalDueDate,
    p.PolicyTenureYears,
    p.PaymentFrequency,
    p.PremiumAmount,
    p.SumInsured,
    p.PolicyStatus,
    p.DaysToRenewal,
    p.IsHighRiskCustomer,
    cl.ClaimsCount,
    cl.TotalClaimAmount,
    cl.ClaimFrequencyRatio
FROM Policies p
JOIN Customers c ON c.CustomerID = p.CustomerID
LEFT JOIN Claims cl ON cl.PolicyID = p.PolicyID;
GO

-- Quick test
SELECT TOP 20 * FROM vw_LapseRiskSummary;
GO

SELECT @@SERVERNAME AS ServerName;




SELECT PolicyID, ClaimsCount, TotalClaimAmount
FROM Claims
WHERE ClaimsCount = 0 AND TotalClaimAmount > 0;

-- these rows have no valid claim record, so their claim amount should be zero too:
UPDATE Claims
SET TotalClaimAmount = 0
WHERE ClaimsCount = 0 AND TotalClaimAmount > 0;

-- a policy can have multiple claims (ClaimsCount of 4, 5, 6+), and each individual claim can be worth up to ~₹40,000. 
-- So a policy with, say, 5 claims could genuinely total ₹150,000-200,000 in claims.
SELECT PolicyID, ClaimsCount, TotalClaimAmount, TotalClaimAmount / NULLIF(ClaimsCount, 0) AS AvgPerClaim
FROM Claims
WHERE TotalClaimAmount > 100000
ORDER BY TotalClaimAmount DESC;