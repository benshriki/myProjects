#ifndef RESTAURANT_H_
#define RESTAURANT_H_

#include <vector>
#include <string>
#include "Dish.h"
#include "Table.h"
#include "Customer.h"
#include <fstream>
#include "Action.h"



class Restaurant {
public:
    Restaurant();

    Restaurant(const std::string &configFilePath);

    virtual ~Restaurant();

    Restaurant(const Restaurant &rest);

    Restaurant(Restaurant &&rest)noexcept;

    Restaurant &operator=(const Restaurant &r);

    Restaurant &operator=(Restaurant &&r)noexcept;

    void start();


    Table *getTable(int ind);

    const std::vector<BaseAction *> &getActionsLog() const; // Return a reference to the history of actions
    std::vector<Dish>& getMenu();

    std::vector<Table *> getTables();


private:
    bool open;
    std::vector<Table*> tables;
    std::vector<Dish> menu;
    std::vector<BaseAction*> actionsLog;
    int NumOfTables;
	DishType DTfromString(std::string toParse);
	std::vector<std::string> parse(std::string str);
	int custcount;
    void clear();
    void copy(const Restaurant & rest);
    void move(Restaurant &rest);

};

#endif
