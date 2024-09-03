-- Retrieve all columns from the Nashville Housing Data table
SELECT *
FROM [Portfolio Project]..[Nashville Housing Data];

-- Standardize SaleDate format to Date
-- Convert SaleDate to Date format and display
SELECT SaleDate, CONVERT(Date, SaleDate) AS ConvertedSaleDate
FROM [Portfolio Project]..[Nashville Housing Data];

-- Update SaleDate column to Date format
UPDATE [Portfolio Project]..[Nashville Housing Data]
SET SaleDate = CONVERT(Date, SaleDate);

-- Add a new column for the standardized SaleDate
ALTER TABLE [Nashville Housing Data]
ADD SalesDateConverted Date;

-- Populate the new SalesDateConverted column with standardized SaleDate values
UPDATE [Nashville Housing Data]
SET SalesDateConverted = CONVERT(Date, SaleDate);

-- Retrieve the newly populated SalesDateConverted column
SELECT SalesDateConverted
FROM [Portfolio Project]..[Nashville Housing Data];

-- Populate Property Address data
-- Retrieve records where PropertyAddress is null and use the most complete address
SELECT a.ParcelID, 
       a.PropertyAddress, 
       b.ParcelID,
       b.PropertyAddress,
       ISNULL(a.PropertyAddress, b.PropertyAddress) AS CorrectedAddress
FROM [Portfolio Project]..[Nashville Housing Data] a
JOIN [Portfolio Project]..[Nashville Housing Data] b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Update PropertyAddress where it is null with the most complete address from the join
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [Portfolio Project]..[Nashville Housing Data] a
JOIN [Portfolio Project]..[Nashville Housing Data] b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Breaking out Property Address into individual columns (Address, City, State)
-- Extract Address part from PropertyAddress
SELECT 
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address
FROM [Portfolio Project]..[Nashville Housing Data];

-- Extract City part from PropertyAddress
SELECT 
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM [Portfolio Project]..[Nashville Housing Data];

-- Add new columns for split address components
ALTER TABLE [Nashville Housing Data]
ADD Property_Split_Address NVARCHAR(255);

UPDATE [Nashville Housing Data]
SET Property_Split_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

ALTER TABLE [Nashville Housing Data]
ADD Property_Split_City NVARCHAR(255);

UPDATE [Nashville Housing Data]
SET Property_Split_City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Split OwnerAddress into individual columns (Address, City, State)
-- Extract Address, City, and State parts from OwnerAddress
ALTER TABLE [Nashville Housing Data]
ADD Owner_Split_Address NVARCHAR(255);

UPDATE [Nashville Housing Data]
SET Owner_Split_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE [Nashville Housing Data]
ADD Owner_Split_City NVARCHAR(255);

UPDATE [Nashville Housing Data]
SET Owner_Split_City = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE [Nashville Housing Data]
ADD Owner_Split_State NVARCHAR(255);

UPDATE [Nashville Housing Data]
SET Owner_Split_State = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Change 1 and 0 to Yes and No in "SoldAsVacant" field
-- Display distinct values of SoldAsVacant with their count
SELECT DISTINCT SoldAsVacant,
       COUNT(SoldAsVacant)
FROM [Nashville Housing Data]
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant;

-- Convert SoldAsVacant field values to 'YES' or 'NO'
SELECT SoldAsVacant,
       CASE 
           WHEN SoldAsVacant = '0' THEN 'NO'
           WHEN SoldAsVacant = '1' THEN 'YES'
           ELSE CAST(SoldAsVacant AS NVARCHAR)
       END AS SoldAsVacant_Converted
FROM [Nashville Housing Data];

-- Alter column type to accommodate 'YES' and 'NO' values
ALTER TABLE [Nashville Housing Data]
ALTER COLUMN SoldAsVacant NVARCHAR(3);

-- Update SoldAsVacant column with 'YES' and 'NO'
UPDATE [Nashville Housing Data]
SET SoldAsVacant = CASE 
                        WHEN SoldAsVacant = '0' THEN 'NO'
                        WHEN SoldAsVacant = '1' THEN 'YES'
                        ELSE CAST(SoldAsVacant AS NVARCHAR)
                    END;

-- Remove duplicate records based on ParcelID, PropertyAddress, SaleDate, and LegalReference
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID, PropertyAddress, SaleDate, LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM [Nashville Housing Data]
)
DELETE
FROM RowNumCTE
WHERE row_num > 1;

-- Remove unused columns from the table
ALTER TABLE [Nashville Housing Data]
DROP COLUMN OwnerAddress,
           TaxDistrict,
           PropertyAddress,
           SaleDate;
