#ifndef CUSTOMER_H_
#define CUSTOMER_H_

#include <vector>
#include <string>
#include "Dish.h"
#include <iostream>
#include <algorithm>

class Customer{
public:
    Customer(std::string c_name, int c_id);
    virtual ~Customer();
    virtual std::vector<int> order(const std::vector<Dish> &menu)=0;
    virtual std::string toString() const = 0;
    std::string getName() const;
    int getId() const;
    virtual Customer* clone()=0;
private:
    const std::string name;
    const int id;
};


class VegetarianCustomer : public Customer {
public:
	VegetarianCustomer(std::string name, int id);
    std::vector<int> order(const std::vector<Dish> &menu);
    std::string toString() const;
    virtual VegetarianCustomer* clone();
    void clonefields(int bvg, int dish);
private:
	int expbvg;
	int lowveg;
};


class CheapCustomer : public Customer {
public:
	CheapCustomer(std::string name, int id);
    std::vector<int> order(const std::vector<Dish> &menu);
    std::string toString() const;
    virtual CheapCustomer* clone();
    void clonefield(bool order);
private:
	bool ordered;
};


class SpicyCustomer : public Customer {
public:
	SpicyCustomer(std::string name, int id);
    std::vector<int> order(const std::vector<Dish> &menu);
    std::string toString() const;
    virtual SpicyCustomer* clone();
    void clonefields(bool ordered, int chp);
private:
	bool ordered;
	int chpbvg;
};


class AlchoholicCustomer : public Customer {
public:
	AlchoholicCustomer(std::string name, int id);
    std::vector<int> order(const std::vector<Dish> &menu);
    std::string toString() const;
    virtual AlchoholicCustomer* clone();
    void clonefields(std::vector<std::pair<int,int>> bvgl, bool ordered);

private:
	std::vector<std::pair<int, int>> bvglist; //pair = (price, id), sort this by price
	//remove objects when they are ordered until vector.size == 0
    std::vector<std::pair<int,int>>     bvgsort(std::vector<std::pair<int,int>> k);
    bool ordered;
};


#endif