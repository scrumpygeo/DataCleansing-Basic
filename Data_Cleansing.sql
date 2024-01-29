/*
		Data Cleansing with SQL
*/

-- start with 56,477 rows.

use DataCleaningProject;
go

---- check data
--SELECT *
--FROM DataCleaningProject..NashvilleHousing

--------------------------

-- 1. Remove time from SalesDate column

--SELECT SaleDate, CONVERT(Date,SaleDate)
--FROM DataCleaningProject..NashvilleHousing

---- Add column with converted date

--ALTER TABLE dbo.NashvilleHousing
--ADD SaleDateConverted date;

--UPDATE dbo.NashvilleHousing
--SET SaleDateConverted = CONVERT(date, SaleDate)

--SELECT SaleDateConverted, SaleDate
--from dbo.NashvilleHousing

-------------------------------------

-- 2. Populate Property Address Data

--SELECT *
--FROM dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
-- 29 rows

-- Examine date, order by ParcelID
--SELECT *
--FROM dbo.NashvilleHousing
----WHERE PropertyAddress IS NULL
--ORDER BY ParcelID

-- -> you see ParcelId repeated several times throughout, albeit perhaps with different owners.
--       However the property address will be the same.
--  So if a ParcelId has a property address present in one row but missing in another, set the null value to the one present.
-- Done with a self join:

--SELECT a.[UniqueID ], a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
--FROM dbo.NashvilleHousing a
--INNER JOIN dbo.NashvilleHousing b
--	ON b.ParcelID = a.ParcelID
--	AND b.[UniqueID ] <> a.[UniqueID ] -- so we don't link the same record
--WHERE a.PropertyAddress IS NULL

---- update table with values for null property addresses
--UPDATE a 
--SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
--	FROM dbo.NashvilleHousing a
--INNER JOIN dbo.NashvilleHousing b
--	ON b.ParcelID = a.ParcelID
--	AND b.[UniqueID ] <> a.[UniqueID ] 
--WHERE a.PropertyAddress IS NULL

---- When run, check for null values again with the select statement above.

---------------------------------------------------------------------------------------------

---- 3. Splitting Address into separate columns (eg Street, City, State).

--SELECT PropertyAddress
--FROM dbo.NashvilleHousing
---- renders, eg:  137 STONECREST  DR, NASHVILLE - where Street and City are always separated by a comma: comma appearing nowhere else.
----  So we can search for the comma via SUBSTRING, starting at character 1


--SELECT 
--SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,  -- the -1 subtraction from the index is so we don't get the comma.
--SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+ 1, LEN(PropertyAddress))  AS City  -- start one char past the comma, end at length of field.
--FROM dbo.NashvilleHousing

--ALTER TABLE dbo.NashvilleHousing
--ADD PropertyStreetAddress nvarchar(255);

--UPDATE dbo.NashvilleHousing
--SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)


--ALTER TABLE dbo.NashvilleHousing
--ADD PropertyCity nvarchar(255)

--UPDATE dbo.NashvilleHousing
--SET PropertyCity =	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+ 1, LEN(PropertyAddress))

---- Check for new columns at very end:
--SELECT * FROM dbo.NashvilleHousing

-----------------------------------------------------------------------------------------

---- 4. So same for OwnerAddress.
----    This has format '329  FORREST VALLEY DR, NASHVILLE, TN', with Street Address, City and State all separated by commas.
----    This time use PARSENAME - this works on periods, so first substitute the commas for periods (having checked there are no pre-existing periods in the address).
----      NB PARSENAME works backwards, so 1 refers to 1st one from the end.

--SELECT OwnerAddress
--FROM dbo.NashvilleHousing
 

--SELECT
--PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
--PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
--PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
--FROM dbo.NashvilleHousing
--WHERE OwnerAddress IS NOT NULL


---- Add columns for Owner Street, City and State.
---- NB Alter the tables first then add update the data.

--ALTER TABLE dbo.NashvilleHousing
--ADD OwnerAddressStreet nvarchar(255)

--ALTER TABLE dbo.NashvilleHousing
--ADD OwnerAddressCity nvarchar(255)

--ALTER TABLE dbo.NashvilleHousing
--ADD OwnerAddressState nvarchar(3)

--UPDATE dbo.NashvilleHousing
--SET OwnerAddressStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

--UPDATE dbo.NashvilleHousing
--SET OwnerAddressCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

--UPDATE dbo.NashvilleHousing
--SET OwnerAddressState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


---------------------------------------------------------------------------
---- 5. Change Y and N to Yes and No in 'Sold as Vacant' column.

--SELECT DISTINCT SoldAsVacant
--FROM dbo.NashvilleHousing
---- This results in a mix of answers: Y, Yes, N and No. We want to make them all Yes or No.

--SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS Count
--FROM dbo.NashvilleHousing
--GROUP BY SoldAsVacant
--ORDER BY 2

-- Results in:
-- SoldAsVacant	Count
--		Y		  52
--		N		 399
--		Yes		4623
--		No	   51403


-- Test:
--SELECT SoldAsVacant
--,CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
--     WHEN SoldAsVacant = 'N' THEN 'No'
--	 ELSE SoldAsVacant
-- END
--FROM dbo.NashvilleHousing


--UPDATE NashvilleHousing
--SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
--     WHEN SoldAsVacant = 'N' THEN 'No'
--	 ELSE SoldAsVacant
-- END
--FROM dbo.NashvilleHousing

-- test result with the previous select distinct statement.

---------------------------------------------------------------------------------

---- 6. Remove Duplicates
----   Partition the data by what should be unique and delete. 
----     Usually you don't delete raw data but write to a new table. Will delete here as an example/


--;
--WITH duplicatesCTE AS
--(
--SELECT *,
--	ROW_NUMBER() OVER (
--	PARTITION BY ParcelId, 
--				 PropertyAddress, 
--				 SalePrice,
--				 SaleDate,
--				 LegalReference
--				 ORDER BY
--					UniqueID
--				 )  row_num
--FROM dbo.NashvilleHousing 
--)

--SELECT * from duplicatesCTE
--where row_num > 1
--ORDER BY PropertyAddress
---- above lists all duplicates. 104 rows.

---- If you want to delete these duplicates, substitute the SELECT with DELETE and remove the ORDER BY clause.

--;
--WITH duplicatesCTE AS
--(
--SELECT *,
--	ROW_NUMBER() OVER (
--	PARTITION BY ParcelId, 
--				 PropertyAddress, 
--				 SalePrice,
--				 SaleDate,
--				 LegalReference
--				 ORDER BY
--					UniqueID
--				 )  row_num
--FROM dbo.NashvilleHousing 
--)
--DELETE 
--from duplicatesCTE
--where row_num > 1

--------To check, run the previous cte where you just select *
---------------------------------------------------------------------------

---- 7. Delete unused columns

--SELECT *
--FROM dbo.NashvilleHousing

--ALTER TABLE dbo.NashvilleHousing
--DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

