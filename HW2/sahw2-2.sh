#!/bin/bash

DIALOG_OK=0
DIALOG_CANCEL=1
DIALOG_ESC=255



cpuinfo() {
	result=$(echo "CPU Info"; sysctl hw.model hw.machine hw.ncpu | 
	awk '{FS=":"} 
	$1=="hw.model"{print "\nCPU Model:" "  " $2 "\n"}  
	$1=="hw.machine"{print "CPU Machine:" "  " $2 "\n"}  
	$1=="hw.ncpu"{print "CPU Core:" "  " $2 "\n"}
	')
  	dialog --no-collapse \
    --msgbox "$result" 100 80
}
meminfo(){
	memresult=$(echo "Memory Info and Usage"; sysctl hw | egrep 'hw.(real|user)' | awk '
	BEGIN{t=0;u=0;f=0;free=0;total=0; used=0;} {FS=":"} 
	{if($1=="hw.realmem"){total=$2} else if($1=="hw.usermem"){used=$2} free=total-used;} 
	{if(total!=0){ 
	 while(total>1024 &&t<4){total/=1024; t++;} 
	 while(used>1024 && u<4){used/=1024;u++;} 
 	 while(free>1024 && f<4){free/=1024;f++;}
		if(t==0){printf("\nTotal:  %.2f B\n",total)}
		else if(t==1){printf("\nTotal:  %.2f KB\n",total)}
		else if(t==2){printf("\nTotal:  %.2f MB\n",total)}
		else if(t==3){printf("\nTotal:  %.2f GB\n",total)}
	  	else {printf("\nTotal:  %.2f TB\n",total)}
		if(u==0){printf("Used:  %.2f B\n",used)}
		else if(u==1){printf("Used:  %.2f KB\n",used)}
		else if(u==2){printf("Used:  %.2f MB\n",used)}
		else if(u==3){printf("Used:  %.2f GB\n",used)}
		else {printf("Used:  %.2f TB\n",used)}
		if(f==0){printf("Free:  %2.f B\n",free)}
		else if(f==1){printf("Free:  %.2f KB\n",free)}
		else if(f==2){printf("Free:  %.2f MB\n",free)}
		else if(f==3){printf("Free:  %.2f GB\n",free)}
		else{printf("Free:  %.2f TB\n",free)}
		}
	} ')

	per=$( sysctl hw | egrep 'hw.(real|user)' | awk 'BEGIN{total=0; used=0;} {FS=":"} {while($2>1024){$2/=1024}} {if($1=="hw.realmem"){total=$2} else if($1=="hw.usermem"){used=$2} } {if(total!=0){printf("%d", used*100/total)}} ')
  
  dialog --title "" --mixedgauge "$memresult" 20 80 $per
}

netinfo(){
  exec 3>&1
  # echo $netinfo
  set -o noglob
  net=$(dialog \
  --clear \
  --cancel-label "Cancel" \
  --menu "Network Interfaces" 20 100 80 \
  `ifconfig | grep "flags" | awk '{FS=":"} { print $1 " *" }'` \
  2>&1 1>&3)
  exit_s=$?
  exec 3>&-
  set +o noglob
  case $exit_s in
    $DIALOG_CANCEL)
      	main
    ;;
	$DIALOG_OK)	
		showip=$( ifconfig $net | grep "inet " | awk '{printf("\n\n\nIPv4___:  %s\nNetmask:  %s\n",$2,$4)};')
		showmac=$(ifconfig $net | grep "ether "| awk '{print "\nMac____:  " $2}')
		dialog --msgbox "Interface Name: $net $showip $showmac" 100 80
	;;
  esac
}

fileinfo(){
  exec 3>&1
  files=$(dialog \
  --clear \
  --cancel-label "Cancel" \
  --menu "File Browser: $PWD " 80 100 80 \
  `ls -al . | sed "1d" | awk '{print $9}' | xargs -n 1 file --mime-type | awk '{FS=": "}{print $1 " " $2}'` \
  2>&1 1>&3)
  exit_s=$?
  exec 3>&-
  #echo $PWD
  case $exit_s in
    $DIALOG_CANCEL)
      	main
    ;;
	$DIALOG_OK)	
		#echo $files
		edit=$(ls -al $files | awk '{print $9}' | xargs -n 1 file --mime-type | awk '{FS=": "}{print $2}' | grep "text" )
		if [ "$files" == "." ]; then
			fileinfo
		elif [ "$files" == ".." ]; then
			cd ..
			fileinfo
		elif [ -d $files ];then 
			cd $files
			fileinfo
		elif [ -n "$edit" ];then
			showtype=$(file $files | awk '{FS=":"}{printf("\n%s\n", $2)}')
			showsize=$(ls -al $files | awk 'BEGIN{cnt=0} 
			{ while($5>1024 && cnt<4){$5/=1024; cnt++;}
			 if(cnt==0){printf("  %.2f B\n",$5)}
			 else if(cnt==1){printf("  %.2f KB\n",$5)}
			 else if(cnt==2){printf("  %.2f MB\n",$5)}
			 else if(cnt==3){printf("  %.2f GB\n",$5)}
			 else {printf("  %.2f TB\n",$5)}
			}')			

			dialog --extra-button --extra-label "Edit" \
			--msgbox "<File Name>:  $files\n<File Info>:$showtype\n<File Size>:$showsize" 100 80
			edit_result=$?
			if [ $edit_result -eq 3 ]; then
				if [ -n "$EDITOR" ]; then
					$EDITOR $files
				else
					vim $files
				fi
			fi
			fileinfo
		else 
			showtype=$(file $files | awk '{FS=":"}{printf("\n%s\n", $2)}')
			showsize=$(ls -al $files | awk 'BEGIN{cnt=0} 
			{ while($5>1024 && cnt<4){$5/=1024; cnt++;}
			 if(cnt==0){printf("  %.2f B\n",$5)}
			 else if(cnt==1){printf("  %.2f KB\n",$5)}
			 else if(cnt==2){printf("  %.2f MB\n",$5)}
			 else if(cnt==3){printf("  %.2f GB\n",$5)}
			 else {printf("  %.2f TB\n",$5)}
			}')			
			dialog --msgbox "<File Name>:  $files\n<File Info>:$showtype\n<File Size>:$showsize" 100 80

			fileinfo
		fi
	;;
  esac
}

loading(){
	cpu_per=$(top -d 2 | grep "^CPU" | sort -t: -k1,1 -u | awk '{ print $10 }' | awk '{FS="%"}{print $1}' )
	#echo $cpu_per
	int=${cpu_per%.*}
	ans=$(( 100 - int ))
	load=$(top -P -d 2 | grep "^CPU" | sort -t: -k1,1 -u | awk '{FS=":"}{print $1 $2}' | awk '{print "\n" $1 $2 ": USER: " $3 " SYST: " $7 " IDLE: " $11 "\n"}')

	dialog --title "CPU loading" --mixedgauge "`echo "CPU Loading"`$load" 20 80 0
}

main(){
	while true; do 
  		exec 3>&1
  		selection=$(dialog \
		--clear \
		--cancel-label "Exit" \
		--menu "SYS INFO" 12 100 80 \
		"1" "CPU INFO" \
		"2" "MEM INFO" \
		"3" "NETWORK INFO" \
		"4" "FILE BROWSER" \
		"5" "CPU LOADING" \
		2>&1 1>&3)
  		exit_status=$?
  		exec 3>&-
  		case $exit_status in
    		$DIALOG_CANCEL)
      			clear
      			echo "Program terminated."
      			exit
      		;;
    		$DIALOG_ESC)
      			clear
      			echo "Program aborted." >&2
      			exit 1
      		;;
  		esac
  		case $selection in
    	0 )
			clear
      		echo "Program terminated."
    	;;
    	1 )
			cpuinfo 
    	;;
    	2 )
	  		while [ 1 -eq 1 ] ; do
		 		meminfo 
		 		read -s -t1 
		 		if [ $? -eq 0 ];then
		    		break
		 		fi
			done
      	;;
    	3 )
	  		while true;do
	  			netinfo
	  		done
      	;;
		4 )
	  		fileinfo
	  	;;
		5 )
	  		while true;do
	  			loading 
	  			read -s t1
	  		if [ $? -eq 0 ];then
	  			break
	  		fi
	  	done
		;;
  		esac
	done
}

main
