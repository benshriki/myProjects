#All Targets
all:rest

#Tool invocations
#Executable "run" depends on the files main.o Restaurant.o Dish.o Action.o customer.o Table.o. 
rest: bin/Table.o bin/customer.o bin/Action.o bin/Dish.o bin/Restaurant.o bin/main.o
	@echo 'Bilding target: rest'
	@echo 'Invoking: C++ Linker'
	g++  -o  bin/rest  bin/Table.o  bin/customer.o  bin/Action.o  bin/Dish.o  bin/Restaurant.o  bin/main.o
	@echo 'Finished building target: run'
	@echo ' '


#Depends on the source and header files
bin/Table.o: src/Table.cpp
	g++ -g -Wall -Weffc++ -std=c++11 -c -Include -o bin/Table.o src/Table.cpp

#Depends on the source and header files
bin/customer.o: src/Customer.cpp
	g++ -g -Wall -Weffc++ -std=c++11 -c -Include -o bin/customer.o src/Customer.cpp
	
#Depends on the source and header files
bin/Action.o: src/Action.cpp
	g++ -g -Wall -Weffc++ -std=c++11 -c -Include -o bin/Action.o src/Action.cpp
	
#Depends on the source and header files
bin/Dish.o: src/Dish.cpp
	g++ -g -Wall -Weffc++ -std=c++11 -c -Include -o bin/Dish.o src/Dish.cpp

#Depends on the source and header files
bin/Restaurant.o: src/Restaurant.cpp
	g++ -g -Wall -Weffc++ -std=c++11 -c -Include -o bin/Restaurant.o src/Restaurant.cpp
	
#Depends on the source and header files
bin/main.o: src/main.cpp
	g++ -g -Wall -Weffc++ -std=c++11 -c -Include -o bin/main.o src/main.cpp


#Clean the build directory
clean:
	rm -f bin/*
