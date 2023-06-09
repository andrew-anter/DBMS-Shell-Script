#!/bin/bash

read -p "Enter Table Name: " tbName
read -p "Enter the primary key value of the row to delete: " val

## checks if table exists
if [ "$tbName" ] && [ -f "./Tables/$tbName" ] && [ -f "./Metadata/$tbName" ] 
then
	## Get the primary key column number
	colNo=`awk -F : '{ if( $3 == "p" ) print NR; }' "./Metadata/$tbName"`

	## Check if the given value exists in table
	rowNumber=`awk -v col=$colNo -v val=$val -F : '
		BEGIN{rn=-1}
		{ if( $col == val ) rn = NR }
		END{ print rn }' "./Tables/$tbName"
		`
	## If the row exists delete it otherwise return an error
	if [ $rowNumber != "-1" ]
	then
		awk -F : -v row=$rowNumber -v tbName=$tbName '{
			if( NR == row )
				next;
			else 
				print $0 > "./Tables/"tbName;
		}' "./Tables/$tbName"
		echo "Row with primary key $val has been deleted"
	else
		echo "!Error: Row not found." 
	fi
else
	echo "!Error: Table not found or corrupted."

fi
