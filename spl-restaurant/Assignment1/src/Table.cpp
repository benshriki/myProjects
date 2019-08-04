#include "../include/Table.h"



//Constructor
Table::Table(int capacity):capacity(capacity), open(false), customersList(), orderList(){
    //customer and order list are initliazed by default constructor as empty containers
}
// End Constructor


//Copy Constructor
Table::Table(const Table &t):capacity(),open(), customersList(), orderList(){
        copy(t);
}
// End Copy Constructor

//Destructor
Table:: ~Table(){
    clear();
}
// End Destructor

//Move Constructor
Table::Table(Table &&t):capacity(), open(), customersList(), orderList(){
    move(t);
}
// End Move Constructor


//Copy Assignment Operator
Table& Table::operator=(const Table &t) {
    if(this!=&t){
        clear();
        copy(t);
    }
    return *this;
}
//End Copy Assignment Operator

//Move Assignment Operator
Table& Table::operator=(Table &&t) {
    if (this != &t) {
        clear();
        move(t);
    }
    return *this;
}

//End Move Assignment Operator


//Copy - Allocates using copy constructors
void Table::copy(const Table &t) {
    capacity = t.capacity;
    open = t.open;
    orderList = t.orderList;
    for (unsigned int i = 0; i < t.customersList.size(); i++) {
        customersList.push_back(t.customersList[i]->clone());
    }
}
//End Copy

//Clear - Deallocates fields
void Table::clear(){
    for (unsigned int i = 0; i < customersList.size(); ++i) {
        delete customersList[i];
        customersList[i] = nullptr;
    }

    customersList.clear();
    orderList.clear();
}
//End Clear

//Move - Reallocates fields
void Table::move(Table &t){
    customersList = std::move(t.customersList);
    orderList = std::move(t.orderList);
    capacity = t.capacity;
    open = t.open;
}



int Table::getCapacity() const {
    return capacity;
}
void Table::addCustomer(Customer *customer) {
    if(this->open)
    customersList.push_back(customer);
}
void Table::removeCustomer(int id) {
    for (unsigned int i = 0; i < customersList.size(); ++i) {
        if (customersList[i]->getId() == id) {
            customersList.erase(customersList.begin() + i);
        }
    }
}

Customer* Table::getCustomer(int id) {
    Customer* output = nullptr;
    for(unsigned int i = 0; i < customersList.size(); i++) {
        if (customersList[i]->getId() == id) {
            output = customersList[i];
        }
    }
    return output;
}

std::vector<Customer*>& Table::getCustomers() {
    return customersList;
}

std::vector<OrderPair>& Table:: getOrders(){
    return orderList;
}

void Table::order(const std::vector<Dish> &menu) {
    std::vector<int> tmp; // Order id's
    for(unsigned int i = 0; i < customersList.size(); i++){ //takes orders from all customers at table
        if(customersList[i] != nullptr){
            tmp = customersList[i]->order(menu); //customer order command
            for(unsigned int j = 0; j < tmp.size(); j++){ // adds customer order to orderlist
                orderList.push_back(std::make_pair(customersList[i]->getId(),menu[tmp[j]]));
            }
        }
    }
}

void Table::openTable() {
    open = true;
}

void Table::closeTable(){
    open = false;
    for (unsigned int i = 0; i < customersList.size(); ++i) {
        delete customersList[i];
        customersList[i] = nullptr;
    }
    customersList.clear();
    orderList.clear();
}

int Table::getBill(){
    int bill = 0;
    for(unsigned int i=0; i<orderList.size(); i++){
       bill = bill + orderList[i].second.getPrice();
    }
    return bill;
}

bool Table::isOpen() {
    return open;
}

bool Table::isEmpty() {
    return customersList.empty();
}


std::vector<Dish> Table::movecBill(int customer_id){ //Source Table
    std::vector<Dish> output;
    std::vector<OrderPair> orderchange;
    for(unsigned int i = 0; i<orderList.size();i++){
        if(orderList[i].first == customer_id){
            output.push_back(orderList[i].second);
        }
        else{
            orderchange.push_back(orderList[i]);
        }
    }
    orderList = std::move(orderchange);
    return output;
}

void Table::movecBill(int customer_id, std::vector<Dish> dishes){ //Destination Table
    for(unsigned int i = 0; i < dishes.size();i++){
        OrderPair toAdd = std::make_pair(customer_id,dishes[i]);
        orderList.push_back(toAdd);
    }
}
