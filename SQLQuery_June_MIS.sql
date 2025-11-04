USE JuneMIS;
GO
 
DROP VIEW IF EXISTS vw_InstallerPerformance;
GO
 
CREATE VIEW vw_InstallerPerformance AS
SELECT 
    [Installer_ID],
    --[Mapped_Contractor_ID],
    [New_Meter_Phase],
    CASE 
        WHEN TRIM(LOWER([Discom_Action])) = 'approved' THEN 'Approved'
        WHEN TRIM(LOWER([Discom_Action])) = 'rejected' THEN 'Rejected'
        ELSE 'Pending'
    END AS Discom_Status,
    COUNT(*) AS TotalMeters
FROM [dbo].[June Meter Installation]
GROUP BY 
    [Installer_ID],
    --[Mapped_Contractor_ID],
    [New_Meter_Phase],
    CASE 
        WHEN TRIM(LOWER([Discom_Action])) = 'approved' THEN 'Approved'
        WHEN TRIM(LOWER([Discom_Action])) = 'rejected' THEN 'Rejected'
        ELSE 'Pending'
    END;
GO
 
-- ? Verify the view returns data
SELECT * FROM vw_InstallerPerformance;
 
 
--1. Installation Summary by Vendor & Installer
--Track how many meters each vendor’s installer has installed, approved, or rejected.
--sql
 
SELECT 
    --[Mapped_Contractor_ID],
    [Installer_ID],
    CASE 
        WHEN LOWER([Discom_Action]) = 'approved' THEN 'Approved'
        WHEN LOWER([Discom_Action]) = 'rejected' THEN 'Rejected'
        ELSE 'Pending'
    END AS Discom_Status,
    COUNT(*) AS TotalMeters
FROM [dbo].[June Meter Installation]
GROUP BY 
    --[Mapped_Contractor_ID],
    [Installer_ID],
    CASE 
        WHEN LOWER([Discom_Action]) = 'approved' THEN 'Approved'
        WHEN LOWER([Discom_Action]) = 'rejected' THEN 'Rejected'
        ELSE 'Pending'
    END
ORDER BY 
    --[Mapped_Contractor_ID],
    [Installer_ID];
 
 
    --2. Geographical Distribution Report
--Summarize installations by Region, Circle, Division, Zone, Substation, and Feeder.
--sql
SELECT 
    [Region],
    [Circle],
    [Division],
    --[Zone/DC],
    [Substation],
    [Feeder],
    COUNT(*) AS TotalInstallations
FROM [dbo].[June Meter Installation]
GROUP BY 
    [Region], [Circle], [Division],  [Substation], [Feeder]
ORDER BY 
    [Region], [Circle];
 
 
    --3. Meter Type & Capacity Analysis
--Understand what types of meters are being installed and their capacity.
--sql
SELECT 
    [New_Meter_Phase],
    [New_Meter_Capacity],
    COUNT(*) AS MeterCount
FROM [dbo].[June Meter Installation]
GROUP BY 
    [New_Meter_Phase], [New_Meter_Capacity]
ORDER BY 
    MeterCount DESC;
 
 
    --4. Old vs New Meter Comparison
--Compare old meter condition, capacity, and final readings vs new meter specs.
--sql
SELECT 
    [Old_Meter_Phase],
    [Old_Meter_Capacity],
    [Old_Meter_Condition],
    --[Old_Meter_Final_Reading_kWh],
    [New_Meter_Phase],
    [New_Meter_Capacity]
    --[New_Meter_Initial_Read_kWh]
FROM [dbo].[June Meter Installation]
WHERE [Discom_Action] IS NOT NULL;
 
 
--5.Installer Performance Tracker
--Track how many meters each installer has installed and their approval rate.
--sql
SELECT 
    [Installer_ID],
    COUNT(*) AS TotalInstalled,
    SUM(CASE WHEN LOWER([Discom_Action]) = 'approved' THEN 1 ELSE 0 END) AS ApprovedCount,
    SUM(CASE WHEN LOWER([Discom_Action]) = 'rejected' THEN 1 ELSE 0 END) AS RejectedCount,
    SUM(CASE WHEN [Discom_Action] IS NULL THEN 1 ELSE 0 END) AS PendingCount
FROM [dbo].[June Meter Installation]
GROUP BY [Installer_ID]
ORDER BY ApprovedCount ASC;
 
 
--6. Vendor Payment Eligibility Report
--Filter only approved installations for payment processing.
--sql
SELECT 
    --[Mapped_Contractor_ID],
    [Installer_ID],
    [Consumer_No],
    CAST([Installation_DateTime] AS DATE) AS InstallationDate,
    [New_Meter_Serial_Number],
    [New_Meter_Phase],
    [New_Meter_Capacity]
FROM [dbo].[June Meter Installation]
WHERE LOWER([Discom_Action]) = 'approved'
ORDER BY --[Mapped_Contractor_ID],
[Installer_ID];
--7. Exception & Data Quality Check
--Identify records with missing critical fields or mismatched feeder/DTR info.
--sql
SELECT 
    [MI_Record_ID],
    [Consumer_No],
    [Installer_ID],
    [Feeder],
    --[DTR],
    [MI_Is_Feeder_Record_Same],
    [MI_IS_DTR_Record_Same]
FROM [dbo].[June Meter Installation]
WHERE 
    [MI_Is_Feeder_Record_Same] = 'No' OR
    [MI_IS_DTR_Record_Same] = 'No';
 
 --New Query
    SELECT 
    a.MI_Record_ID,
    a.Consumer_No,
    a.Installer_ID,
    --a.Mapped_Contractor_ID,
    a.New_Meter_Phase,
    a.New_Meter_Serial_Number,
    SUM(CASE WHEN TRIM(LOWER(b.Discom_Action)) = 'approved' THEN 1 ELSE 0 END) AS ApprovedCount,
    SUM(CASE WHEN TRIM(LOWER(b.Discom_Action)) = 'pending' OR b.Discom_Action IS NULL THEN 1 ELSE 0 END) AS PendingCount,
    COUNT(*) AS TotalMeters
FROM [dbo].[June Meter Installation] a
JOIN [dbo].[June Meter Installation] b
  ON a.Installer_ID = b.Installer_ID
--AND a.Mapped_Contractor_ID = b.Mapped_Contractor_ID
AND a.New_Meter_Phase = b.New_Meter_Phase
WHERE TRIM(LOWER(a.Discom_Action)) = 'pending'
   OR a.Discom_Action IS NULL
GROUP BY 
    a.MI_Record_ID,
    a.Consumer_No,
    a.Installer_ID,
   -- a.Mapped_Contractor_ID,
    a.New_Meter_Phase,
    a.New_Meter_Serial_Number;
 
 
    SELECT 
    a.MI_Record_ID,
    a.Consumer_No,
    a.Installer_ID,
    --a.Mapped_Contractor_ID,
    a.New_Meter_Phase,
    a.New_Meter_Serial_Number,
    SUM(CASE WHEN TRIM(LOWER(b.Discom_Action)) = 'approved' THEN 1 ELSE 0 END) AS ApprovedCount,
    SUM(CASE WHEN TRIM(LOWER(b.Discom_Action)) = 'pending' OR b.Discom_Action IS NULL THEN 1 ELSE 0 END) AS PendingCount,
    COUNT(*) AS TotalMeters
FROM [dbo].[June Meter Installation] a
JOIN [dbo].[June Meter Installation] b
  ON a.Installer_ID = b.Installer_ID
--AND a.Mapped_Contractor_ID = b.Mapped_Contractor_ID
AND a.New_Meter_Phase = b.New_Meter_Phase
WHERE TRIM(LOWER(a.Discom_Action)) = 'approved'
GROUP BY 
    a.MI_Record_ID,
    a.Consumer_No,
    a.Installer_ID,
   -- a.Mapped_Contractor_ID,
    a.New_Meter_Phase,
    a.New_Meter_Serial_Number;