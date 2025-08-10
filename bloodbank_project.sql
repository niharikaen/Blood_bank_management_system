-- ================================
-- 1. CREATE DATABASE
-- ================================
DROP DATABASE IF EXISTS BloodBankDB;
CREATE DATABASE BloodBankDB;
USE BloodBankDB;

-- ================================
-- 2. CREATE TABLES WITH CONSTRAINTS
-- ================================
CREATE TABLE Donor (
    DonorID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Age INT CHECK (Age >= 18),
    Gender ENUM('Male','Female','Other'),
    BloodGroup VARCHAR(5) NOT NULL,
    Contact VARCHAR(15) UNIQUE,
    Address VARCHAR(255),
    LastDonationDate DATE
);

CREATE TABLE Recipient (
    RecipientID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Age INT CHECK (Age > 0),
    Gender ENUM('Male','Female','Other'),
    BloodGroupRequired VARCHAR(5) NOT NULL,
    Contact VARCHAR(15) UNIQUE,
    Address VARCHAR(255)
);

CREATE TABLE BloodStock (
    StockID INT PRIMARY KEY AUTO_INCREMENT,
    BloodGroup VARCHAR(5) UNIQUE,
    UnitsAvailable INT DEFAULT 0 CHECK (UnitsAvailable >= 0)
);

CREATE TABLE Donation (
    DonationID INT PRIMARY KEY AUTO_INCREMENT,
    DonorID INT,
    BloodGroup VARCHAR(5) NOT NULL,
    UnitsDonated INT CHECK (UnitsDonated > 0),
    DonationDate DATE NOT NULL,
    FOREIGN KEY (DonorID) REFERENCES Donor(DonorID)
);

CREATE TABLE Request (
    RequestID INT PRIMARY KEY AUTO_INCREMENT,
    RecipientID INT,
    BloodGroup VARCHAR(5) NOT NULL,
    UnitsRequested INT CHECK (UnitsRequested > 0),
    RequestDate DATE NOT NULL,
    Status ENUM('Pending','Completed','Rejected') DEFAULT 'Pending',
    FOREIGN KEY (RecipientID) REFERENCES Recipient(RecipientID)
);

-- ================================
-- 3. SAMPLE DATA
-- ================================
INSERT INTO Donor (Name, Age, Gender, BloodGroup, Contact, Address, LastDonationDate)
VALUES
('Rahul Sharma', 28, 'Male', 'O+', '9876543210', 'Delhi', '2025-07-20'),
('Priya Mehta', 32, 'Female', 'A-', '9876501234', 'Mumbai', '2025-06-15'),
('Arjun Verma', 24, 'Male', 'B+', '9876556789', 'Bangalore', '2025-05-10');

INSERT INTO Recipient (Name, Age, Gender, BloodGroupRequired, Contact, Address)
VALUES
('Amit Verma', 40, 'Male', 'O+', '9876554321', 'Delhi'),
('Neha Gupta', 29, 'Female', 'B+', '9876512345', 'Kolkata');

INSERT INTO BloodStock (BloodGroup, UnitsAvailable)
VALUES
('O+', 5),
('A-', 3),
('B+', 4);

INSERT INTO Donation (DonorID, BloodGroup, UnitsDonated, DonationDate)
VALUES
(1, 'O+', 2, '2025-07-20'),
(2, 'A-', 1, '2025-06-15');

INSERT INTO Request (RecipientID, BloodGroup, UnitsRequested, RequestDate, Status)
VALUES
(1, 'O+', 2, '2025-08-10', 'Pending'),
(2, 'B+', 1, '2025-08-09', 'Completed');

-- ================================
-- 4. TRIGGERS
-- ================================
DELIMITER //
CREATE TRIGGER AfterDonationInsert
AFTER INSERT ON Donation
FOR EACH ROW
BEGIN
    UPDATE BloodStock
    SET UnitsAvailable = UnitsAvailable + NEW.UnitsDonated
    WHERE BloodGroup = NEW.BloodGroup;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER AfterRequestCompleted
AFTER UPDATE ON Request
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Completed' THEN
        UPDATE BloodStock
        SET UnitsAvailable = UnitsAvailable - NEW.UnitsRequested
        WHERE BloodGroup = NEW.BloodGroup;
    END IF;
END //
DELIMITER ;

-- ================================
-- 5. STORED PROCEDURE
-- ================================
DELIMITER //
CREATE PROCEDURE ProcessRequest(IN reqID INT)
BEGIN
    DECLARE reqBloodGroup VARCHAR(5);
    DECLARE reqUnits INT;

    SELECT BloodGroup, UnitsRequested
    INTO reqBloodGroup, reqUnits
    FROM Request WHERE RequestID = reqID;

    -- Check stock
    IF (SELECT UnitsAvailable FROM BloodStock WHERE BloodGroup = reqBloodGroup) >= reqUnits THEN
        UPDATE BloodStock
        SET UnitsAvailable = UnitsAvailable - reqUnits
        WHERE BloodGroup = reqBloodGroup;

        UPDATE Request
        SET Status = 'Completed'
        WHERE RequestID = reqID;
    ELSE
        UPDATE Request
        SET Status = 'Rejected'
        WHERE RequestID = reqID;
    END IF;
END //
DELIMITER ;

-- ================================
-- 6. VIEWS
-- ================================
CREATE VIEW AvailableStock AS
SELECT BloodGroup, UnitsAvailable
FROM BloodStock
ORDER BY BloodGroup;

CREATE VIEW PendingRequests AS
SELECT R.RequestID, Rec.Name, R.BloodGroup, R.UnitsRequested, R.RequestDate
FROM Request R
JOIN Recipient Rec ON R.RecipientID = Rec.RecipientID
WHERE R.Status = 'Pending';

-- ================================
-- 7. COMPLEX QUERIES FOR DEMO
-- ================================
-- a) Donors who haven't donated in last 6 months
SELECT Name, Contact
FROM Donor
WHERE LastDonationDate < DATE_SUB(CURDATE(), INTERVAL 6 MONTH);

-- b) Blood groups low in stock (<3 units)
SELECT BloodGroup, UnitsAvailable
FROM BloodStock
WHERE UnitsAvailable < 3;

-- c) Total donations per blood group
SELECT BloodGroup, SUM(UnitsDonated) AS TotalUnits
FROM Donation
GROUP BY BloodGroup;

-- d) Pending blood requests
SELECT * FROM PendingRequests;

-- e) Total stock in bank
SELECT SUM(UnitsAvailable) AS TotalUnitsAvailable FROM BloodStock;
select * from Donor;
select * from AvailableStock;
call ProcessRequest(1);