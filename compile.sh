#=====================================================================
#
#	Filename:Comp.sh
#	For:compile C/C++ files.
#	Version:1.1(bash)
#	Date:2018.1.27
#
#=====================================================================
#!/bin/bash

set -e

search_depth=1

work_directory='./'
test_directory='test+'

test_in='[0-9]+.in\>'
test_out='[0-9]+.out\>'

gcc_=
gpp_=

gcc_name='.(C|c)\>'
gpp_name='.(cc|cxx|cpp|c++)\>'

compile_options='-Wall -static -o0'

Useage(){	
	echo -e "Useages [-h/c/f/d/r/t]\n\n"
	echo -e "abcdef"
}

Test(){
	if [ -f $1.test ];then
		rm -f $1.test
	fi
	
	local test_a=$(ls $1 | grep -E $test_in)
	echo $test_a
	if [ x"$test_a" != x ];then
		for test_c in $test_a;do
			local file_a=`cat $1/$test_c | $1.o`
			local file_b=`cat $1/${test_c%.*}.out`
			local comp_a=
			local comp_b=
			for file_c in $file_a;do
				comp_a="$comp_a $file_c"
			done
			for file_c in $file_b;do
				comp_b="$comp_b $file_c"
			done
			if [ x"$comp_a" != x"$comp_b" ];then
				echo -e "At test $1 :\nYour answer :\nAuthor's answer :\n"
			fi
		done
	else
		echo "Find no test data." > $1.test
	fi
}

Compile(){
	local compiler=`eval echo '$'"$2"`
	echo -n "compiling `basename "$1"`......"
	$compiler $compile_options -o ${1%.*}.o $1 2>${1%.*}.log
	if [ -f ${1%.*}.o ];then
		rm -f ${1%.*}.log
		echo "done"
	else
		echo "error"
		ecode="$ecode\nAn error occured while complie $2.\nLogs has been saved in $1/${2%.*}.log."
	fi
}

Search_cpps(){
	local _name=`eval echo '$'"$2""name"`
	local file_a=$(ls $1 | sed "s:^:${1%/*}/:" | grep -E "$_name")
	for file_c in $file_a; do
		if [ -f $file_c ] && [ ! -f ${file_c%.*}.o ] && [ ! -f ${file_c%.*}.log ];then	
			Compile $file_c $2
			if [ x"$test" = x"true" ];then
				Test ${file_c%.*}
			fi
		fi
	done
}

Search_dirs(){
	if [ x"$2" != x"0" ];then
		for directory in $1/*; do  
			local directory=`basename $directory`
			if [ -d $1/$directory ] && [ x"$directory" != x'.' ] && [ x"$directory" != x'..' ] && [ x"$directory" != x'*' ];then
				Search_dirs $1/$directory $(($2 - 1))
			fi
		done
		rm -f $1/*.o
		rm -f $1/*.log
		if [ ! "$clean" = "true" ];then
			echo "Current directory is : $1"
			echo "Looking for GUN C++ files ..."
			Search_cpps "$1/" 'gpp_'
			echo "Looking for GUN C files ..."
			Search_cpps "$1/" 'gcc_'
		fi
	fi	
}

Check(){
	echo -n "Checking default $2 ......"
	local default=`eval echo '$'"$3"`
	if [ x"$default" != x ] && [ x"$($default -v 2>&1)" != x ];then
		echo "[OK]"
	else
		echo -n "......"
		local dir_cc=$(whereis -b $1)
		for _cc in $dir_cc; do
			if [ -f $_cc ];then
				local chk=$($_cc -v 2>&1)
				if [ x"$chk" != x ];then
					echo "[OK]"
					eval $3=$_cc
					break
				fi
			fi
		done
		if [ `eval echo x'$'"$3"` = x ];then
			echo "not found."
		fi
	fi
}

echo -e "#=====================================================================\n#\n#	Filename:Comp.sh\n#	For:compile C/C++ files.\n#	Version:1.1(bash)\n#	Date:2018.1.27\n#\n#=====================================================================\n"

Check 'gcc' 'GUN C Compiler' 'gcc_'
Check 'g++' 'GUN C++ Complier' 'gpp_'
echo ''

while getopts "hcrt" arg
do
	case $arg in
		h)
			Useage
			exit 0
			;;
		c)
			search_depth="-1"
			clean="true"
			;;
		r)
			search_depth="-1"
			;;
		t)
			test="true"
			;;
		?)
			echo ""
			Useage
			exit
			;;
		esac
done

if [ x"$*" != x ];then
	for optarg in $*;do
		if [ x"${optarg:0:1}" != x"-" ];then
			flag="true"
			if [ -d $optarg ];then
				Search_dirs $optarg $search_depth
			elif [ -f $optarg ];then
				if [ x"${optarg:0:1}" != x'/' ] && [ x"${optarg:0:2}" != x'./' ];then
					optarg="./$optarg"
				fi
				rm -f ${optarg%.*}.o
				rm -f ${optarg%.*}.log
				Search_cpps $optarg 'gpp_'
				Search_cpps $optarg 'gcc_'
			else
				ecode="$ecode\nFile or directory $optarg doesn't exist !"
			fi
		fi
	done
fi

if [ x"$flag" = x ];then
	Search_dirs $work_directory $search_depth
fi

if [ x"$clean" = x"true" ];then
	echo "Clean finished sucessfully."
elif [ x"$ecode" = x ];then
	echo "Complie finished sucessfully."
else
	echo -e $ecode
fi
