#!/bin/bash
# check an-gt crete tables and metadata folders
if ! [ -d "Tables" ]
then
	mkdir "Tables"
	echo "Tables Directory Created"
fi

if ! [ -d "Metadata" ]
then
	mkdir "Metadata"
	echo "Metadata Directory Created"
fi

echo "Greetings from Table Manager: $PWD"

###########################################

while read -p "
Select an option:
	1- Create Table
	2- List Tables
	3- Drop Table
	4- Insert Into Table
	5- Select From Table
	6- Delete From Table
	7- Update Table
	8- Disconect Database
	" option
do
	case $option in 
		"1") 
			read -p "Enter table name: " tbName
			
			if ! [ "$tbName"  ]
			then
				echo "!Error: No table name was entered" 
				continue
			fi


			if [ -f "./Tables/$tbName"  ] 
			then
				echo "Error this table already exist"
			else

				read -p "Enter the names of columns separated by spaces: " -a cols
				read -p "Enter the data type for each column respectively separated by spaces: [s:string / i:integer] " -a datatype
				read -p "Specify which column is primary: [primary:p / normal:n]" -a primaryKey
				if [[ ${cols[@]} ]]
				then
					if [[ ${#datatype[*]} = ${#cols[@]} ]]
					then
						if [[ ${#cols[*]} = ${#primaryKey[*]}  ]]
						then
							echo "vaild colstypes number & valid primarykey number"
							
							valid=1
							for i in "${datatype[@]}"
							do
								if ! [[ ${i^^} =~ ^(S|I)$ ]]
								then
									echo "!!Error: One or more data type is invalid"
									valid=0
									break
								fi
							done
							
							primary=0
							for i in "${primaryKey[@]}"
							do
								if ! [[ ${i^^} =~ ^(P|N)$  ]]
								then
									echo "!Error: One or more column type (p/n) is invalid"
									valid=0
									break
								fi
								
								if [[ ${i^^} =~ ^(P)$ ]]
								then
									primary=1
								fi
							done	

							if [ $primary -gt 1  ]
							then
								echo "!Error: Can not set up more than one primary key column" 
								continue
							elif [[ $primary = 0  ]]
							then
								echo "!Error: There must be one primary key column"
								continue
							fi
							
							if [[ $valid = 1  ]]
							then
								touch "./Tables/$tbName" "./Metadata/$tbName"
								echo "Table $tbName created"

								for (( i=0; i<${#cols[*]}; i++  ))
								do
									echo "${cols[$i]}:${datatype[$i]}:${primaryKey[$i]}" >> "./Metadata/$tbName"
								done
							fi
						else
							echo "!Error: All columns must be specifie as a primary key or not"
						fi

					else
						echo "!Error: All columns must have a datatype"
					fi
				else
					echo "!Error: No columns were specified"
				fi
			fi
			;;
		"2")
			ls "./Tables/"
			;;
		"3")
			read -p "Enter table name: " tbName
			
			if [ -f "./Tables/$tbName"  ]
			then
				read -p "Do you really want to drop this table with its data? [y/n]: " confirm
				if [ "${confirm^^}" = "Y"  ]
				then
					rm "./Tables/$tbName"
					rm "./Metadata/$tbName"
					echo "Table Dropped"
				fi

			else
				echo "This table does not exist"
			fi
			;;
		"4")
			read -p "Enter Table Name: " tbName
			if [ "$tbName" ] && [ -f "./Tables/$tbName" ] && [ -f "./Metadata/$tbName" ] 
			then
				## Get the data from the table and then convert it to an array
				colNames=($(awk -F: '{print $1}' ./Metadata/"$tbName"))
				colTypes=($(awk -F: '{print $2}' ./Metadata/"$tbName"))
				colPK=($(awk -F: '{print $3}' ./Metadata/"$tbName"))
					 
				echo "Enter the values of["${colNames[*]}"] respectively"
				read  -a input	

				## if input exists and the number of columns is the same as in the table
				if [[ "${input[@]}" ]] && [[ ${#input[@]} -eq "${#colNames[@]}" ]]
				then			

					## check if the column types matches the data if not then will return to the main while loop
					for i in ${!input[@]}
					do	
						if [ ${colPK[$i]} = "p" ]
						then
							primaryKeyValue=${input[$i]}
						fi

						if [[ ${colTypes[$i]} = "i" ]] && ! [[ ${input[$i]} =~ ^[0-9]+$ ]]
						then
							echo "!Error: value ${input[$i]} is not a valid integer"
							continue 2
						fi
					done

					## check for the primary key constrains[unique]
					if [ `awk -F : -v primaryKeyVal=$primaryKeyValue 'BEGIN{ found="false"; }
						{ if( primaryKeyVal == $1) found="true" ;} END{ print found;}' ./Tables/$tbName` = "true"  ]
					then
						echo "!Error: Primary key must be unique"
						continue
					fi

					for i in ${!input[@]}
					do
						## if not the last line then print element + delimiter
						if (( $i < ${#input[@]}-1 ))
						then
							echo "i: $i"
							echo "value ${#input[@]}"
							echo -n "${input[$i]}:" >> "./Tables/$tbName"
						else
							## last line print element + \n
							echo "${input[$i]}" >> "./Tables/$tbName"
						fi
					done	


				else
					echo "!Error: invalid input"
				fi
				

			else
				echo "!Error: the table does not exist or is corrupted"
			fi

			;;
		"5")
			read -p "Enter the name of the table: " tbName
			if [ -f "./Tables/$tbName" ]
			then
				echo "table found!!"
				echo `awk -F : '{print $1"("$2","$3")"}' "./Metadata/$tbName"`
				##awk -F : 'BEGIN{print ""} {print ""}'

			else
				echo "!Error: no table named \"$tbName\" in the current database"
			fi

			;;
		"6")
			echo "delete from table"
			;;
		"7")
			echo "update table"
			;;
		"8")
			exit;;
	esac
done

