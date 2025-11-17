package main

import (
	"flag"
	"fmt"
	"os"

	"golang.org/x/crypto/bcrypt"
)

func main() {
	sFlag := flag.String("s", "", "password to hash")
	pFlag := flag.String("p", "", "password to compare")
	flag.Parse()

	// Hash mode
	if *sFlag != "" {
		hash, err := bcrypt.GenerateFromPassword([]byte(*sFlag), bcrypt.DefaultCost)
		if err != nil {
			fmt.Println("error")
			os.Exit(1)
		}
		fmt.Println(string(hash))
		return
	}

	// Compare mode
	if *pFlag != "" {
		args := flag.Args()
		if len(args) != 1 {
			fmt.Println("0")
			return
		}
		hash := args[0]
		err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(*pFlag))
		if err != nil {
			fmt.Println("0")
			return
		}
		fmt.Println("1")
		return
	}

	fmt.Println("usage:")
	fmt.Println("  cmd -s <password>")
	fmt.Println("  cmd -p <password> <hash>")
}

