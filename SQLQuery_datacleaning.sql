/*
Project for Data Cleaning
*/

-- 1.Standardize Date Format
select SaleDate from Housing

-- Update the table
-- Change data type
ALTER TABLE Housing
ALTER COLUMN SaleDate Date;


-- 2. Fix problem with null Populate Property Address
-- As we can see there's 29 rows with null property address
-- And property address is a mandatory information for housing
Select *
From Housing
Where PropertyAddress is null 

select parcelID, PropertyAddress from Housing
order by PropertyAddress, ParcelID

-- They have repeated parcelID but one has Property Address, one doesn't 
Select table1.ParcelID, table1.PropertyAddress, table2.ParcelID, table2.PropertyAddress
-- Self join to check for their parcelID
From Housing as table1
JOIN Housing as table2
	on table1.ParcelID = table2.ParcelID
	AND table1.UniqueID <> table2.UniqueID 
Where table1.PropertyAddress is null

-- Update the table
-- Repalce these null to the property address from table2 
Update Housing
SET PropertyAddress = ISNULL(Housing.PropertyAddress,table2.PropertyAddress)
From Housing 
JOIN Housing as table2
	on Housing.ParcelID = table2.ParcelID
	AND Housing.UniqueID <> table2.UniqueID 
Where Housing.PropertyAddress is null

-- Check for null again 
Select count(*)
From Housing
Where PropertyAddress is null 

-- 3. Break down address by address, city, states
--Use substring for property address
SELECT
substring(PropertyAddress, 1, charindex(',', PropertyAddress) -1 ) as Address
, substring(PropertyAddress, charindex(',', PropertyAddress) + 1 , len(PropertyAddress)) as City
From Housing

-- Add new columns 
ALTER TABLE Housing
Add Property_Address Nvarchar(255)

ALTER TABLE Housing
Add Property_City Nvarchar(255)

-- Update the table
Update Housing
SET Property_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

Update Housing
SET Property_City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

--Use parsename for 2 or more comma separated column(Owner address)
-- Parsename supports period instead of comma, so I need to replace comma by period
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) as address
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2) as city 
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) as state
From Housing 
where PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) is not null

-- Add new columns 
ALTER TABLE Housing
Add Owner_Address Nvarchar(255)

ALTER TABLE Housing
Add Owner_City Nvarchar(255)

ALTER TABLE Housing
Add Owner_State Nvarchar(255)

-- Update the table
Update Housing
SET Owner_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

Update Housing
SET Owner_City = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

Update Housing
SET Owner_State = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

-- 4. Change Y and N to Yes and No in Sold as Vacant
-- We have 399 N and 52 Y
Select Distinct(SoldAsVacant), Count(SoldAsVacant) as count
From Housing
Group by SoldAsVacant

-- Use case when to make the correction
-- Update the table
Update Housing
SET SoldAsVacant = (CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END)

-- 5. Check for Duplicates and Non-necessary columns and then remove them
with c1 as (Select *,ROW_NUMBER() OVER (PARTITION BY ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference,OwnerName,OwnerAddress order by UniqueID) as row_num
From Housing)

-- There's 104 Duplicates
-- We need to delete them all 
-- Delete rows
delete
From c1
Where row_num > 1

-- Delete Non-necessary columns
ALTER TABLE Housing
DROP COLUMN PropertyAddress, OwnerAddress 

-- Final view
Select * From Housing
order by [UniqueID]