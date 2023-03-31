#!/bin/sh

set -e

# Create test.go

cat > test.go << EOF
package main

import (
	"fmt"
	"os"
	"syscall"
)

func readdir(dirname string) error {
	f, err := os.Open(dirname)
	if err != nil {
		return err
	}
	f.Readdirnames(-1)
	f.Close()

	return nil
}

func stat(path string) {
	st, err := os.Lstat(path)
	if err != nil {
		fmt.Printf("failed to stat %v: %v\n", path, err)
		os.Exit(1)
	}
	fmt.Printf("%v inode: %v\n", path, st.Sys().(*syscall.Stat_t).Ino)
}

func main() {
	// readdirnames will do getdents64 sycalls without any other syscalls inbetween (no stat)
	err := readdir("bin")
	if err != nil {
		fmt.Printf("failed to readdir bin: %v\n", err)
		os.Exit(1)
	}

	stat("bin/arch")
	stat("bin/busybox")
}
EOF


mkdir -p lower1/bin lower2/bin merged
(cd lower1/bin; touch $(seq 1 50))
dd if=/dev/urandom of=lower2/bin/busybox count=1 2> /dev/null
ln lower2/bin/busybox lower2/bin/arch
dd if=/dev/urandom of=lower1/bin/busybox count=1 2> /dev/null
ln -s busybox lower1/bin/arch

ls -lai lower1/bin/busybox lower1/bin/arch lower2/bin/busybox lower2/bin/arch

fuse-overlayfs -o debug,lowerdir=$PWD/lower1:$PWD/lower2 merged &

sleep 1

(cd merged; go run ../test.go)

ls -lai merged/bin/busybox merged/bin/arch

(command -v fusermount > /dev/null && fusermount -u merged) ||
(command -v fusermount3 > /dev/null && fusermount3 -u merged)
