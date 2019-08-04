
# All Targets
all: ass3

# Tool invocations
ass3: ass3.o printer.o scheduler.o drone.o target.o
	gcc -m32 -Wall -g -o ass3 ass3.o printer.o scheduler.o drone.o target.o

 
ass3.o: ass3.s
	nasm -f elf ass3.s -o ass3.o

printer.o: printer.s
	nasm -f elf printer.s -o printer.o

scheduler.o: scheduler.s
	nasm -f elf scheduler.s -o scheduler.o

drone.o: drone.s
	nasm -f elf drone.s -o drone.o

target.o: target.s
	nasm -f elf target.s -o target.o


#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o ass3


