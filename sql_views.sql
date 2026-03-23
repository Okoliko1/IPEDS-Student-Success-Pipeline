-- ============================================
-- IPEDS Student Success Pipeline
-- SQL Views - Final Version
-- Author: Timothy Okoliko
-- Date: March 2026
-- ============================================

USE IPEDS_StudentSuccess;
GO

-- ============================================
-- DATA QUALITY FIX
-- Fix typo in data_year column across all tables
-- ============================================
UPDATE GR_IPEDS SET data_year = '2022-2023' WHERE data_year = '20022-2023';
UPDATE HD_IPEDS SET data_year = '2022-2023' WHERE data_year = '20022-2023';
UPDATE EF_IPEDS SET data_year = '2022-2023' WHERE data_year = '20022-2023';
UPDATE DRVGR_IPEDS SET data_year = '2022-2023' WHERE data_year = '20022-2023';
GO

-- ============================================
-- VIEW 1: Graduation Rates by Year
-- Source: GR_IPEDS joined with HD_IPEDS
-- Note: HD join uses UNITID only to preserve
-- all 12 years of graduation data
-- ============================================
DROP VIEW IF EXISTS vw_GraduationRates;
GO

CREATE VIEW vw_GraduationRates AS
SELECT 
    g.UNITID,
    h.INSTNM  AS Institution_Name,
    h.STABBR  AS State,
    h.CITY,
    g.data_year,
    g.GRRTTOT AS Graduation_Rate_Total,
    g.GRRTM   AS Graduation_Rate_Male,
    g.GRRTW   AS Graduation_Rate_Female,
    g.GRRTAN  AS Graduation_Rate_AmericanIndian,
    g.GRRTBK  AS Graduation_Rate_Black,
    g.GRRTHS  AS Graduation_Rate_Hispanic
FROM GR_IPEDS g
LEFT JOIN (
    SELECT DISTINCT UNITID, INSTNM, STABBR, CITY 
    FROM HD_IPEDS
) h ON g.UNITID = h.UNITID;
GO

-- ============================================
-- VIEW 2: Enrollment Trends by Year
-- Source: EF_IPEDS joined with HD_IPEDS
-- Note: Uses FTE12MN and UNDUP which have
-- consistent data across all 12 years
-- ============================================
DROP VIEW IF EXISTS vw_EnrollmentTrends;
GO

CREATE VIEW vw_EnrollmentTrends AS
SELECT 
    e.UNITID,
    h.INSTNM   AS Institution_Name,
    h.STABBR   AS State,
    h.CITY,
    e.data_year,
    e.UNDUP    AS Total_Enrollment,
    e.FTE12MN  AS FTE_Enrollment
FROM EF_IPEDS e
LEFT JOIN (
    SELECT DISTINCT UNITID, INSTNM, STABBR, CITY 
    FROM HD_IPEDS
) h ON e.UNITID = h.UNITID;
GO

-- ============================================
-- VIEW 3: Combined Student Success Summary
-- Source: GR_IPEDS + EF_IPEDS + HD_IPEDS
-- Used as primary view for Tableau dashboard
-- ============================================
DROP VIEW IF EXISTS vw_StudentSuccessSummary;
GO

CREATE VIEW vw_StudentSuccessSummary AS
SELECT 
    g.UNITID,
    h.INSTNM  AS Institution_Name,
    h.STABBR  AS State,
    h.CITY,
    g.data_year,
    g.GRRTTOT AS Graduation_Rate,
    e.UNDUP   AS Total_Enrollment,
    e.FTE12MN AS FTE_Enrollment
FROM GR_IPEDS g
LEFT JOIN (
    SELECT DISTINCT UNITID, INSTNM, STABBR, CITY 
    FROM HD_IPEDS
) h ON g.UNITID = h.UNITID
LEFT JOIN EF_IPEDS e 
    ON g.UNITID = e.UNITID 
    AND g.data_year = e.data_year;
GO