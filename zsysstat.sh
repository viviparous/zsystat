#! /usr/bin/env bash

# usage
# while true ; do clear; ./zsysstat.sh ; sleep 15; done

# watch --color -d -n 5 ./zsysstat.sh 
# watch --color -n 5 ./zsysstat.sh 


gSLEEPVAL=15


lnchars="▶▶▶▶▶▶▶▶▶▶"
lncharsR="◀◀◀◀◀◀◀◀◀◀"
lncharsTribar="☰☰☰☰☰☰☰☰☰☰"

# colours
clrgr='\033[0;32m'
clryw='\033[0;33m'
clrrd='\033[0;31m'
clrblu='\033[0;34m'
clrmgn='\033[0;35m'
clrcyn='\033[0;36m'
# styles
stybld='\033[1m'
# Clear the color after that
clr0='\033[0m'


function mksep () {
 echo $lnchars
}

function mkseptitle () {

 echo -e "${clrmgn} ✱☰▶ "$lnchars" $1 "$lncharsR "✪☰✱${clr0}"

}

function mkseptitleW () {

 echo -e " ✱☰▶ "$lnchars" $1 "$lncharsR "✪☰✱ "

}



function mkh1 () {
 echo " "
 echo -e  "${stybld}${clrgr}✱☰▶ $lnchars " $1 "$lncharsR ✪☰✱${clr0}"
 echo " " 
}

function mkh2 () {
 echo " "
 echo -e "${stybld}${clryw}✱☰▶ $lnchars "$1 "✪☰✱${clr0}"
 echo " "
}

function mkec () {
 echo -e "${clrcyn}───${clr0}"

}

function mkecL () {
 ln=$(awk 'BEGIN{SS=sprintf("%*s",60,""); gsub(/ /,"═",SS);print SS}') 
 echo -e "${clrcyn}$ln${clr0}"
}

declare -a aHistNetTX
declare -a aHistNetRX
declare -a aLogValsTX
declare -a aLogValsRX


function addValtoAry () {
#arg 1 = val ;; arg 2 = arynymLABEL

 inVal=$1
 inAry=$2
 iSZ=10 

 if [[ $2 =~ "LVTX" ]]; then
  arylen=${#aLogValsTX[@]}
  aLogValsTX+=($inVal)

  if [ $arylen -gt $iSZ ]; then
    iReduce=$(( $arylen - $iSZ ))
    aryClone=("${aLogValsTX[@]}")
    for iRed in $(eval echo {0..$iReduce}); do
     unset aryClone[$iRed]
    done
    
    aLogValsTX=("${aryClone[@]}")
  fi

 elif [[ $2 =~ "LVRX" ]]; then
  arylen=${#aLogValsRX[@]}
  aLogValsRX+=($inVal)

  if [ $arylen -gt $iSZ ]; then
    iReduce=$(( $arylen - $iSZ ))
    aryClone=("${aLogValsRX[@]}")
    for iRed in $(eval echo {0..$iReduce}); do
     unset aryClone[$iRed]
    done
    
    aLogValsRX=("${aryClone[@]}")
  fi
  
  
 elif [[ $2 =~ "TX" ]]; then
  arylen=${#aHistNetTX[@]}
  aHistNetTX+=($inVal)

  if [ $arylen -gt $iSZ ]; then
    iReduce=$(( $arylen - $iSZ ))
    aryClone=("${aHistNetTX[@]}")
    for iRed in $(eval echo {0..$iReduce}); do
     unset aryClone[$iRed]
    done
    
    aHistNetTX=("${aryClone[@]}")
  fi
    
 elif [[ $2 =~ "RX" ]]; then
  arylen=${#aHistNetRX[@]}
  aHistNetRX+=($inVal)

  if [ $arylen -gt $iSZ ]; then
    iReduce=$(( $arylen - $iSZ ))
    aryClone=("${aHistNetRX[@]}")
    for iRed in $(eval echo {0..$iReduce}); do
     unset aryClone[$iRed]
    done
    
    aHistNetRX=("${aryClone[@]}")

  fi
   
 fi

}


declare -A dIFxxNyms #global, indexed by intval . _tx, _rx
declare -a aIDXs #global, list of integers representing each interface
idxIF=0

declare -a aIFnyms
for el in /sys/class/net/* ; do if [[ "$el" =~ /lo$ ]]; then $nop; else aIFnyms+=("$el"); fi; done


# get length of an array
arrlen=${#aIFnyms[@]}
# make nyms for each source
for nNym in "${!aIFnyms[@]}" ; do
	#aIFxxNyms+=("${aIFnyms[$nNym]}/statistics/tx_bytes")
	#aIFxxNyms+=("${aIFnyms[$nNym]}/statistics/rx_bytes")
	dIFxxNyms[$idxIF"_tx"]="${aIFnyms[$nNym]}/statistics/tx_bytes"
	dIFxxNyms[$idxIF"_txprev"]=0
	dIFxxNyms[$idxIF"_rx"]="${aIFnyms[$nNym]}/statistics/rx_bytes"
	dIFxxNyms[$idxIF"_rxprev"]=0
	aIDXs+=("$idxIF")
	idxIF=$(( $idxIF + 1 ))
done

#for each dIFxxNyms member, need an array of values
valXXLimit=20

declare -A dSYSVALS
dSYSVALS[bDISPSVR]="UNK" #init display server to FALSE
iTEST01=$(env | grep -i wayland | wc -l)
iTEST02=$(env | grep -i xorg | wc -l)
iTEST03=$(env | grep -i freedesktop | wc -l)

if [ $iTEST01 -gt 0 ]; then
 dSYSVALS[bDISPSVR]="WAYLAND"
elif [ $iTEST02 -gt 0 ]; then
 dSYSVALS[bDISPSVR]="XORG"
elif [ $iTEST03 -gt 0 ]; then
 dSYSVALS[bDISPSVR]="FREEDESKTOP"
fi

dSYSVALS[UNAME]=$(uname -a | awk '{print $1,$2,$3,$(NF-1),$NF}')
dSYSVALS[HNAME]=$(hostname)

#make ordered list of cpu cores
declare -a aCPUS
while read KK;
do 
  aCPUS+=($KK)
done< <(grep -P "^cpu\d+ " /proc/stat | awk '{print $1}')


#identify cpu architecture
declare -a aCPUTypes
aCPUTypes=("UNK" "Intel"  "AMD"  "0x41" "Raspberry Pi 4" "Raspberry Pi 5") #UNK = unknown ; 0x41 is ARM
#r.pi uses "processor" ;; x86 uses vendor_id
caseinit=0
casetest=$caseinit
sCPUcnt=$(cat /proc/cpuinfo | grep -P "^processor\\s+" | wc -l)  #arm type
if [ $sCPUcnt -gt 0 ]; then 
	sCpuNymRPI=$(cat /proc/cpuinfo | grep -P "^Model\\s+" | sort -u | cut -d: -f 2)
	sCpuImplmID=$(cat /proc/cpuinfo | grep -P "^CPU implementer\\s+" | sort -u | cut -d: -f 2)
	if [[ $casetest -eq $caseinit && $sCpuNymRPI =~ "${aCPUTypes[5]}" ]]; then
	 casetest=5
	elif [[ $casetest -eq $caseinit && $sCpuNymRPI =~ "${aCPUTypes[4]}" ]]; then
	 casetest=4
	elif [[ $casetest -eq $caseinit && $sCpuImplmID =~ "${aCPUTypes[3]}" ]]; then
     casetest=3
    fi
fi
#logical elif
if [ $casetest -eq $caseinit ]; then #we have not found the architecture
	sCPUcnt=$(cat /proc/cpuinfo | grep -P "^vendor_id" | wc -l) #vendor_id==x86 
	sCpuNym=$(cat /proc/cpuinfo | grep 'model name' | sort -u | cut -d: -f 2)
	if [ $sCPUcnt -gt 0 ]; then 
	 if [[ $casetest -eq $caseinit && $sCpuNym =~ "${aCPUTypes[1]}" ]]; then
		casetest=1
	 elif [[ $casetest -eq $caseinit && $sCpuNym =~ "${aCPUTypes[2]}" ]]; then
		casetest=2
	 fi
	fi	
fi

dSYSVALS[ARCH]=${aCPUTypes[$casetest]}
#set bash array length ${#arrayname[@]} 
cntCPUS=${#aCPUS[@]}  

#########

while true; do

		
		clear
		rstamp0=$(strings /dev/urandom | grep -o "[[:alnum:]]" | head -n 30 | tr -d '\n' | cut -b1-24)
		rstamp1=$(head -c 256 /dev/random| shasum -a 384  | base64 | sed 's/[=\/\\+]//g'| awk 'BEGIN {str="";} {str=str$0;} END {print str;}' | cut -b1-24)

		mkseptitleW "${dSYSVALS[ARCH]} _ ${dSYSVALS[UNAME]} _ ${dSYSVALS[bDISPSVR]}" | grep --colour -P "\d+|$"
		
		mkecL
		uptime | grep --colour -P "\d+|$"		
		
		mkecL
		# if we were to parse the output of the utillity top, we would not have much more of interest
		# top -b -n1 -1 -w 512 | grep "^%" | sed 's/%/\n/g'		

#		gsub usage. use sprintf to create string of space chars (example). use gsub to replace all space chars.  
#		SS=sprintf("%*s",100,""); 
#		gsub(/ /,"▅",SS); print str,PP""SS"☰",dCPU[PROC];  }}'  | grep --colour -P "\d+|$"

		arrwblu="${clrblu}◀${clr0}"
		ps -e -o pid,tid,psr,pcpu | grep -v "%" | awk -v icores="$cntCPUS" -v awblu="$arrwblu" 'function ceil(x){return int(x)+(x>int(x))} BEGIN {PAD=12;} {dsum[$3]+=$4} END { str1=">> CPU_"; for (k=0;k<icores;k++) {km=ceil(dsum[k]); kmx=km; if(kmx>100){kmx=100;} SSa=sprintf("%*s",kmx,""); gsub(/ /,"▅",SSa); SSb=str1""k" "; PAD2=PAD-length(SSb); SSc=sprintf("%*s",PAD2,""); gsub(/ /,":",SSc); print SSb,SSc,SSa,awblu,km; }}' | sort -n -k 2 


		mkecL
		mkseptitle "Top PROCs Core Affinity"
		topprocs=$(ps -e -o pcpu,pmem,pid,uname,comm | sort -nrk 1 | head -n 5 | sort -n -k 3 | grep --colour -P "\d+|$" | awk '{printf $3" "}END{print ""}')
		echo $topprocs

		mkec
		ps -e  -o pid,tid,psr,pcpu | grep -v "%" | awk '$4 > 0 {print $3,$1}'  | awk -v TPRCs="$topprocs" '{ inlist=TPRCs; split(inlist,ary," "); for (i in ary) {dHIGH[ary[i]]=1;} dPID[$1]++; $2 in dHIGH? dSTR[$1]=dSTR[$1]" ▶▶ =["$2"]=◀◀ ": dSTR[$1]=dSTR[$1]" "$2;}END{for(i in dSTR){ print " ✪☰▶ CORE ["i"] ("dPID[i]")=>"dSTR[i]; }}' | sort | grep --colour -P "\d+|$"

		mkec
		mkseptitle  "cmd ps top %cpu , %mem"
		#ps aux --sort=-%cpu | head -n 5  | grep --colour -P "\d+|$"
		ps -e -o pcpu,pmem,pid,uname,comm | sort -nrk 1 | head -n 5 | grep --colour -P "\d+|$"
		mkec
		#ps aux --sort=-%mem | head -n 5 | grep --colour -P "\d+|$"
		ps -e -o pcpu,pmem,pid,uname,comm | sort -nrk 2 | head -n 5 | grep --colour -P "\d+|$"

		#make process graph
		mkec
		memprcnt=$(free | grep "Mem:" | awk '{print $3/$2*100}')
		memint=${memprcnt%.*}
		if [ "$memint" -ge 80 ] ; then
		 echo "[ $memprcnt % mem use ]"	
		 mkec
		 ps -e -o pcpu,pmem,pid,uname,comm | sort -nrk 1 | head -n 2 | awk '{print $3}' | while read SWPV; do pstree -pUnTs $SWPV; done 
		fi
		mkecL

		df -h | awk '{if (int($5) > 8){print $0}}' | grep --colour -P "\d+|$"

		mkecL
		echo -e "${clrblu}"
		free | grep ":" | awk -v endmarkR="${clrrd}◀" '{pcv=$3/$2*100; SSa=$1" "; PAD=8-length(SSa); SSb=sprintf("%*s",PAD,""); gsub(/ /,":",SSb); SSc=sprintf("%*s",pcv,""); gsub(/ /,"▅",SSc); print SSa,SSb,SSc,endmarkR;} '

		mkec

		warnLn="${clrrd}◀◀◀▅▅▅▅▅▅${clr0}"
		ithrsh=50
		free | grep ":" | awk -v stW="$warnLn" -v iTHR="$ithrsh" '{pcv=$3/$2*100;stA=$1" .. "pcv" % used";if(int(pcv)>=iTHR){iFACT=int(pcv/10); printf "%s",stA; for(iv=1;iv<=iFACT;iv++){ printf "%s",stW;} print "";} else {print stA;}}'

		mkec
		swprcnt=$(free | grep "Swap:" | awk '{print $3/$2*100}')
		swint=${swprcnt%.*}

		if [ "$swint" -gt 1 ] ; then
			mkec
			for file in /proc/*/status ; do echo -ne  "$file\t" && echo -ne " :: " && awk '/VmSwap|Name/{printf $2 "\t" $3 " " $4}END {print ""}' $file;done | sort -k 4 -n -r | head -n 5 | grep --colour -P "\d+|$"
			
			 mkh2 "Most processes in swap ===>"			
			#for file in /proc/*/status ; do echo -ne  "$file\t" && echo -ne " :: " && awk '/VmSwap|Name/{printf $2 "\t" $3 " " $4}END {print ""}' $file;done | sort -k 4 -n -r | head -n 3 | awk -F'/' '{print $3}' | while read LL; do ps -eo ppid,pid,cmd | awk '{p[$1]=p[$1]","$3}END{ for(i in p) print i, p[i]}' | grep --colour -P "^$LL"; done | sed 's/,/\n/g' | sort | uniq -c | sort -n | awk '{print $2,$1}' 
			#for file in /proc/*/status ; do echo -ne  "$file\t" && echo -ne " :: " && awk '/VmSwap|Name/{printf $2 "\t" $3 " " $4}END {print ""}' $file;done | sort -k 4 -n -r | head -n 3 | awk -F'/' '{print $3}' | while read LL; do ps -eo ppid,pid,cmd | awk '{p[$1]=p[$1]","$3}END{ for(i in p) print i, p[i]}' | grep --colour -P "^$LL"; done | sed 's/,/\t/g' | sort | uniq -c | sort -n
			for file in /proc/*/status ; do echo -ne  "$file\t" && echo -ne " :: " && awk '/VmSwap|Name/{printf $2 "\t" $3 " " $4}END {print ""}' $file;done | sort -k 4 -n -r | head -n 3 | awk -F'/' '{print $3}' | while read LL; do ps -eo ppid,pid,cmd | awk '{p[$1]=p[$1]","$3}END{ for(i in p) print i, p[i]}' | grep --colour -P "^$LL"; done |  sort | uniq -c | sort -n | awk -F',' '{for(i=2;i<=NF;i++){dVals[$2]++;}} {print $1,$2,dVals[$2]}' | awk '{print $2,$3,"("$4")"}' | grep --colour -P "\d+|$"
			if [ "$swint" -ge 80 ] ; then
			 mkec
			 for file in /proc/*/status ; do echo -ne  "$file\t" && echo -ne " :: " && awk '/VmSwap|Name/{printf $2 "\t" $3 " " $4}END {print ""}' $file;done | sort -k 4 -n -r | head -n 3 | awk -F'/' '{print $3}' | while read LL; do ps -eo ppid,pid,cmd | awk '{p[$1]=p[$1]","$3}END{ for(i in p) print i}' | grep --colour -P "^$LL"; done | while read SWPV; do pstree -pUnts $SWPV; done 
#			 for file in /proc/*/status ; do echo -ne  "$file\t" && echo -ne " :: " && awk '/VmSwap|Name/{printf $2 "\t" $3 " " $4}END {print ""}' $file;done | sort -k 4 -n -r | head -n 3 | awk -F'/' '{print $3}' | while read LL; do ps -eo ppid,pid,cmd | awk '{p[$1]=p[$1]","$3}END{ for(i in p) print i}' | grep --colour -P "^$LL"; done | while read SWPV; do  ps -ef --forest | awk -v elproc="$SWPV" '$2==elproc || $3==elproc {print $9}' | sort | uniq -c | awk 'length($2)>3 {print $2" ("$1")"}' ; done 
			 
			fi

		fi

		mkecL
		myIPADDR=$(ip route | grep " scope link src " | awk '{print $9}')
		myETHDEV=$(ip route | grep "^default via " | awk '{print $5}')
		
#		ip stats | grep -A 4  "$myETHDEV: group link" | cat -n | grep --colour -P "\d+|$"
		myETHDEVRX=$(ip -h stats | grep -A 4  "$myETHDEV: group link" | cat -n | awk '$1==3 {print "RX "$3}')
		myETHDEVTX=$(ip -h stats | grep -A 4  "$myETHDEV: group link" | cat -n | awk '$1==5 {print "TX "$3}')
#		ip stats | grep -A 4  "$myETHDEV: group link" | cat -n | awk '{if($1==3) {printf "RX "$3" "} else if($1==5) {printf "TX "$3" "} END{print "";} }'
		
		#below shows total transfers
		#ip -h stats | grep -A 4 -P ": group link" | cat -n | awk '$1>5 {print $0}' | grep --colour -P "\d+|$"

		mkh1 "$myETHDEV // $myIPADDR // $myETHDEVTX _ $myETHDEVRX"
		

		tmpAllTX=0
		tmpAllRX=0
		
		for intval in "${!aIDXs[@]}" ; do
			#echo ${dIFxxNyms[$intval"_tx"]}
			#echo ${dIFxxNyms[$intval"_rx"]}
			
			#tx values
			txpathval=${dIFxxNyms[$intval"_tx"]}
			txval=$(cat $txpathval)
			txprevval=${dIFxxNyms[$intval"_txprev"]}
			txDLT=$(( $txval - $txprevval ))
			
			tmpAllTX=$(( $tmpAllTX + $txDLT ))

						
			txtrendstr="▲ ▲ ▲"
			if [ $txval -lt $txprevval ]; then
			 txtrendstr="▼ ▼ ▼"
			elif [ $txval -eq $txprevval ]; then
			 txtrendstr="=—=—==—=—=" #emdash
			fi
			txkeyval=$intval"_txprev"
			dIFxxNyms[$txkeyval]=$txval			

			#rx values
			rxpathval=${dIFxxNyms[$intval"_rx"]}
			rxval=$(cat $rxpathval)
			rxprevval=${dIFxxNyms[$intval"_rxprev"]}
			rxDLT=$(( $rxval - $rxprevval ))
			
			tmpAllRX=$(( $tmpAllRX + $rxDLT ))

			rxtrendstr="▲ ▲ ▲"
			if [ $rxval -lt $rxprevval ]; then
			 rxtrendstr="▼ ▼ ▼"
			elif [ $txval -eq $txprevval ]; then
			 rxtrendstr="=—=—==—=—=" #emdash
			fi
			rxkeyval=$intval"_rxprev"
			dIFxxNyms[$rxkeyval]=$rxval			
			
			#below shows tx_bytes,rx_bytes				
			#echo -e "$txpathval $txval $txtrendstr ($txDLT)\n$rxpathval $rxval $rxtrendstr ($rxDLT)"  | grep --colour -P "\d+|$" 
		done	


		
		addValtoAry $tmpAllTX "TX"	
		addValtoAry $tmpAllRX "RX"	

		logvalTX=$(echo $tmpAllTX | awk '{if(log($1)>0){printf "%11.2f\n",log($1)} else {print 0}}')
		addValtoAry $logvalTX "LVTX"
		echo "${aLogValsTX[@]}" | awk -v peakarrwCLR="${clrmgn}◀${clr0}" 'function ceil(x){return int(x)+(x>int(x))} {for (LV=1; LV<=NF; LV++) { intval=ceil($LV)*4; SS=sprintf("%*s",intval,""); gsub(/ /,"▅",SS); if(intval > 0 ){ print "TX", intval, SS""peakarrwCLR; } else { print "TX 0  _ "; } }}'  

		mkec

		logvalRX=$(echo $tmpAllRX | awk '{if(log($1)>0){printf "%11.2f\n",log($1)} else {print 0}}')
		addValtoAry $logvalRX "LVRX"

		echo -e "${clrmgn}"
		echo "${aLogValsRX[@]}" | awk -v peakarrwCLR="${clr0}◀${clrmgn}" 'function ceil(x){return int(x)+(x>int(x))} {for (LV=1; LV<=NF; LV++) { intval=ceil($LV)*4; SS=sprintf("%*s",intval,""); gsub(/ /,"▅",SS); if(intval > 0 ){ print "RX", intval, SS""peakarrwCLR; } else { print "RX 0  _ "; } }}'  

		echo -e "${clr0}"
#		echo "TX log array (${#aLogValsTX[@]}): ${aLogValsTX[@]}"
#		echo "RX log array (${#aLogValsRX[@]}): ${aLogValsRX[@]}"
				
		
#		ip -h stats | grep -A 4 -P "link" | cat -n | awk '$1>5 {print $0}' | grep --colour -P "\d+|$"

		mkecL
		lsof -i -n -P | grep "\->" | awk '{a[$1"_p"$2]++;}END{ for (it in a){print it,a[it]}}' | sort -nr -k2,2 | grep --colour -P "\d+|$" 
		mkec
		lsof -i -n -P | tail -n +2 | awk -F: '{split($NF,ap," ");print ap[1];}' | sort -n | uniq -c | sort -nr -k 1,1 -k 2,2 | awk '{printf $2"="$1" "}' | fmt -w 80 | grep --colour -P "\d+|$"
		mkec
		#display 2  columns or 3 columns
#		lsof -i -n -P | awk '{split($9,a,">"); print $1,$8,a[2]}'| awk '(NF==3){print $0}'  | sort | uniq -c | sed 's/^[[:blank:]]*//g' | sed 's/[[:blank:]]+$//g' | sort -Vr -k1,1 -k4,4  | awk -v LMT=60 -v TRD=0 'function ceil(x){return int(x)+(x>int(x))}  BEGIN{ MXL=0; DL[0]=0; DR[0]=0;} { DL[TRD]=$0; DR[TRD]=$0; TRD+=1; length($0)>MXL?MXL=length($0):MXL=MXL;  }END{ CSZ=ceil(TRD/2);print TRD,CSZ,MXL,LMT; if(TRD<=10){  for(i=0;i<=TRD;i++){print DL[i]; }} else { for(i=0;i<=CSZ;i++){ TL=length(DL[i]); VV=LMT-TL;  s=sprintf("%*s",VV,""); gsub(/ /,".",s);  print DL[i],s,DR[CSZ+i+1]; ;  }  }  }' | grep --colour -P "\d+|$"
 		lsof -i -n -P | awk '{split($9,a,">"); print $1,$8,a[2]}'| awk '(NF==3){print $0}'  | sort | uniq -c | sed 's/^[[:blank:]]*//g' | sed 's/[[:blank:]]+$//g' | sort -Vr -k1,1 -k4,4  | awk -v LMT=60 -v TRD=0 'function ceil(x){return int(x)+(x>int(x))}  BEGIN{ MXL=0; SEPFCTR=18; DL[0]=0; DMID[0]=0; DR[0]=0;} { DL[TRD]=$0; DMID[TRD]=$0; DR[TRD]=$0; TRD+=1; length($0)>MXL?MXL=length($0):MXL=MXL;  }END{ DVVAL=3; CSZ=ceil(TRD/DVVAL);print TRD,DVVAL,CSZ,MXL,LMT; if(TRD<12){  for(i=0;i<=TRD;i++){print DL[i]; }} else { for(i=0;i<=CSZ;i++){ TL=length(DL[i])+SEPFCTR; SPC1=LMT-TL;  s1=sprintf("%*s",SPC1,""); gsub(/ /,".",s1); SPC2=LMT-(length(DMID[CSZ+i+1]) +SEPFCTR);  s2=sprintf("%*s",SPC2,""); gsub(/ /,".",s2); print DL[i],s1,DMID[CSZ+i+1],s2,DR[2*CSZ+i+2];   }  }  }' | grep --colour -P "\d+|$"

		mkseptitle "UNQrun $rstamp0 $rstamp1"

		sleep $gSLEEPVAL

done

#mkh1 "end $0 ."
