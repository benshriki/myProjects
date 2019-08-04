#ifndef TABLE_H_
#define TABLE_H_

#include <vector>
#include "Customer.h"
#include "Dish.h"


typedef std::pair<int, Dish> OrderPair;

class Table{
public:
    Table(int t_capacity);
    Table(const Table &t);
    virtual ~Table();
    Table(Table &&t);
    Table& operator=(const Table &t);
    Table& operator=(Table &&t);
    int getCapacity() const;
    void addCustomer(Customer* customer);
    void removeCustomer(int id);
    Customer* getCustomer(int id);
    std::vector<Customer*>& getCustomers();
    std::vector<OrderPair>& getOrders();
    void order(const std::vector<Dish> &menu);
    void openTable();
    void closeTable();
    int getBill();
    bool isOpen();
    bool isEmpty();
    std::vector<Dish> movecBill(int customer_id);
    void movecBill(int customer_id, std::vector<Dish> dishes);
private:
    int capacity;
    bool open;
    std::vector<Customer*> customersList;
    std::vector<OrderPair> orderList; //A list of pairs for each order in a table - (customer_id, Dish)
    void clear();
    void copy(const Table &t);
    void move(Table &t);
};


#endif