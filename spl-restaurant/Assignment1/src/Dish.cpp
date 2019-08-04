#include "../include/Dish.h"

//Constructor
Dish::Dish(int d_id, std::string d_name, int d_price, DishType d_type):id(d_id),name(d_name), price(d_price), type(d_type){
}
//End Constructor


//Copy Constructor
Dish::Dish(const Dish &o):id(o.getId()), name(o.getName()),price(o.getPrice()),type(o.getType()){
}
//End Copy Constructor

//Destructor
Dish::~Dish()=default;
//End Destructor


Dish& Dish::operator=(const Dish &d){
    Dish output(d);
    *this = output;
    return *this;

};


int Dish::getId() const {
    return id;
}


std::string Dish::getName() const {
    return name;
}
int Dish::getPrice() const {
    return price;
}

DishType Dish::getType() const {
    return type;
}
