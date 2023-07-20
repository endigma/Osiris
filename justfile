tmp := `mktemp -d`

update:
	git pull
	git reset --hard
	rm target/libOsiris.so

build:
	cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_CXX_COMPILER=g++ -S . -B {{tmp}}
	cmake --build {{tmp}} -j $(nproc --all)
	
	@mkdir -p Target
	@mv {{tmp}}/Source/libOsiris.so Target/

	rm -rf {{tmp}}

attach:
	#!/usr/bin/env bash

	[[ ! -z "$SUDO_USER" ]] && RUNUSER="$SUDO_USER" || RUNUSER="$LOGNAME"
	RUNCMD="sudo -u $RUNUSER"

	line=$(pgrep -u $RUNUSER csgo_linux64)
	arr=($line)

	if [ $# == 1 ]; then
		proc=$1
	else
		if [ ${#arr[@]} == 0 ]; then
			echo CSGO not running!
			exit 1
		fi
		proc=${arr[0]}
	fi

	echo Running instances: "${arr[@]}"
	echo Attaching to "$proc"

	FILENAME=`mktemp`

	cp "Target/libOsiris.so" "$FILENAME"

	echo loading "$FILENAME" to "$proc"

	gdbbin="gdb"
	if [ -x "./bin/gdb-arch-2021-02" ]; then
		gdbbin="./bin/gdb-arch-2021-02"
	fi

	$gdbbin -n -q -batch                                                        \
		-ex "attach $proc"                                                  \
		-ex "echo \033[1mCalling dlopen\033[0m\n"                           \
		-ex "call ((void*(*)(const char*, int))dlopen)(\"$FILENAME\", 1)"   \
		-ex "echo \033[1mCalling dlerror\033[0m\n"                          \
		-ex "call ((char*(*)(void))dlerror)()"                              \
		-ex "detach"                                                        \
		-ex "quit"

	rm $FILENAME
