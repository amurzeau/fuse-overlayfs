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