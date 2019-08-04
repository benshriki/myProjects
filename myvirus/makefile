#format is target-name: target dependencies
#{-tab-}actions

# All Targets
all:myVirus

# Tool invocations
myVirus:task3.o
	ld -nostdlib -m elf_i386 task3.o -o myVirus

# Depends on the source and header files
task3.o: task3.s
	nasm -f elf task3.s -o task3.o 


#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o myVirus
