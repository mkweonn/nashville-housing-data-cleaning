/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM housing;


-- Standardize Date Format
SELECT SaleDate, DATE(SaleDate)
FROM housing;

UPDATE housing
SET SaleDate = DATE(SaleDate);

ALTER TABLE housing
MODIFY SaleDate DATE;

-- SELECT SaleDate, CONVERT(Date, SaleDate)
-- FROM housing;


-- Populate Property Address Data
SELECT * 
FROM housing
WHERE PropertyAddress IS NULL;

SELECT * 
FROM housing
ORDER BY ParcelID;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, COALESCE(a.PropertyAddress, b.PropertyAddress)
FROM housing a
JOIN housing b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE housing a
JOIN housing b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;


-- Breaking out Address into Individual Columns (Address, City, State)
SELECT PropertyAddress 
FROM housing;

SELECT 
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1) AS Address
, SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress)) AS City
FROM housing;

ALTER TABLE housing
ADD PropertySplitAddress Nvarchar(255);

UPDATE housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1);

ALTER TABLE housing
ADD PropertySplitCity Nvarchar(255);

UPDATE housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress));

SELECT * 
FROM housing;


SELECT OwnerAddress
FROM housing;

-- no PARSENAME in MYSQL PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
SELECT SUBSTRING(OwnerAddress, 1, LOCATE(',', OwnerAddress) - 1)
, SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)
, SUBSTRING_INDEX(OwnerAddress, ',', -1)
FROM housing;

ALTER TABLE housing
ADD OwnerSplitAddress Nvarchar(255);

ALTER TABLE housing
ADD OwnerSplitCity Nvarchar(255);

ALTER TABLE housing
ADD OwnerSplitState Nvarchar(255);

UPDATE housing
SET OwnerSplitAddress = SUBSTRING(OwnerAddress, 1, LOCATE(',', OwnerAddress) - 1);

UPDATE housing
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

UPDATE housing
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);


-- Change Y and N to Yes and No in "Sold as Vacant" Field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM housing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
FROM housing;

UPDATE housing
SET SoldAsVacant = CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END;


-- Remove Duplicates
WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER(
    PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
		ORDER BY UniqueID ) row_num
FROM housing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
;

-- cannot delete from CTE
DELETE FROM housing
WHERE UniqueID IN (
    SELECT UniqueID
    FROM (
        SELECT UniqueID, ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
        FROM housing
    ) AS subquery
    WHERE row_num > 1
);


-- Delete Unused Columns
SELECT *
FROM housing;

ALTER TABLE housing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress;
