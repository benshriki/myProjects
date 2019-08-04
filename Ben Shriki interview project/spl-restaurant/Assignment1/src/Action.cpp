
#include "../include/Action.h"
#include "../include/Restaurant.h"

//Base Action
BaseAction::BaseAction():errorMsg(),status(PENDING){}

ActionStatus BaseAction::getStatus() const {
    return status;
}

void BaseAction::complete() {
    status = COMPLETED;
}
void BaseAction::error(std::string errorMsg) {
    status = ERROR;
    this->errorMsg = "Error: " + errorMsg;
    std::cout<<(this->errorMsg)<<std::endl;
}

BaseAction::~BaseAction()=default;

std::string BaseAction::getErrorMsg() const {
    return errorMsg;
}



void BaseAction::cloneStatus(const BaseAction & other) {
    if(other.getStatus()==COMPLETED)
        complete();
    if(other.getStatus()==ERROR)
        this->status=ERROR;
    errorMsg=this->getErrorMsg();
}

//End Base Action

//Open Table
OpenTable::OpenTable(int id, std::vector<Customer *> &customersList): tableId(id), customers(){
        customers = std::move(customersList);
}

void OpenTable::act(Restaurant &restaurant) {
// performs the action
    Table* t = restaurant.getTable(tableId);

    if(t == nullptr || (t->isOpen())){
        error("Table does not exist or is already open");
        return;
    }
    t->openTable();

    for(unsigned int i = 0; i<customers.size();i++){
        t->addCustomer(customers[i]->clone());
    }

    complete();
}
std::string OpenTable::toString() const {
    std::string id = std::to_string(tableId);
    std::string customerstr;
    for(unsigned int i = 0; i < customers.size(); i++) {
        customerstr = customerstr + customers[i]->toString() + " ";
    }
    std::string output = "open " + id + " " + customerstr;
    if(getStatus() == COMPLETED) {
        return output + " Completed";
    }
    else if(getStatus() == ERROR){
       return output + " " + getErrorMsg();
    }
    return "";
}


OpenTable::~OpenTable() {
    for(unsigned int i = 0; i<customers.size();i++){
        delete customers[i];
        customers[i]=nullptr;
    }
    customers.clear();
}

OpenTable* OpenTable::clone(){
    std::vector<Customer*> clist;
    for(unsigned int i = 0; i<customers.size(); i++){
        clist.push_back(customers[i]->clone());
    }
    OpenTable* output = new OpenTable(tableId, clist);
    output->cloneStatus(*this);
    return output;
}

//End Open Table


//Order
Order::Order(int id):tableId(id){}

void Order::act(Restaurant &restaurant) {
    Table* t = restaurant.getTable(tableId);
    unsigned int amountordered = t->getOrders().size();
    if(t == nullptr || !(t->isOpen())){
        error("Table does not exist or is not open");
        return;
    }
    t->order(restaurant.getMenu());

    //Print
    std::vector<OrderPair> orders = t->getOrders();
    for(unsigned int i = amountordered;i<orders.size();i++){
            std::string cname = t->getCustomer(orders[i].first)->getName();
            std::string cdish = orders[i].second.getName();
            std::string toprint = cname + " ordered " + cdish;
            std::cout << toprint << std::endl;
    }
    complete();
}


std::string Order::toString() const {
    if(getStatus()==COMPLETED) {
        std::string id = std::to_string(tableId);
        std::string output = "order " + id;
        return output + " Completed";
    }
    else if(getStatus() == ERROR){
        std::string id = std::to_string(tableId);
        std::string output = "order " + id;
        return output + " " + getErrorMsg();
        }
    return "";
}

Order* Order::clone() {
    Order* output = new Order(tableId);
    output->cloneStatus(*this);
    return output;
}

//End Order

//Move Customer
MoveCustomer::MoveCustomer(int src, int dst, int customerId):srcTable(src),dstTable(dst), id(customerId){}

void MoveCustomer::act(Restaurant &restaurant) {
    Table* sptr = restaurant.getTable(srcTable);
    Table* dptr = restaurant.getTable(dstTable);

    if(((sptr == nullptr || !(sptr->isOpen())) | (dptr == nullptr || !(dptr->isOpen())))){
        error("Cannot move customer");
        return;
    }
    Customer* c = sptr->getCustomer(id);
    //Finds customers which shouldn't exist
    if(((unsigned int)dptr->getCapacity() == dptr->getCustomers().size()) | (c == nullptr)){
        error("Cannot move customer");
        return;
    }

    dptr->addCustomer(c); // ADD BEFORE REMOVE!
    std::vector<Dish> privbill = sptr->movecBill(c->getId()); //creates "private bill" per customer
    dptr->movecBill(c->getId(),privbill); //allocates "private bill" to table bill
    sptr->removeCustomer(c->getId());


    if(sptr->isEmpty()){ //closes source table if we moved the last customer
        Close close((int)srcTable);
        close.act(restaurant);
    }
    complete();

}

std::string MoveCustomer::toString() const {
    std::string source = std::to_string(srcTable);
    std::string dest = std::to_string(dstTable);
    std::string custid = std::to_string(id);
    std::string output = "move " + source + " " + dest + " " + custid;
    if(getStatus()==COMPLETED) {
        return output + " Completed";
    }
    else if(getStatus() == ERROR) {
        return output + " " + getErrorMsg();
    }
    return "";
}

MoveCustomer* MoveCustomer::clone() {
    MoveCustomer* output = new MoveCustomer(srcTable, dstTable, id);
    output->cloneStatus(*this);
    return output;
}
//End Move Customer


//Close
Close::Close(int id): tableId(id){
}

void Close::act(Restaurant &restaurant) {
    Table* tptr = restaurant.getTable(tableId);
    if((tptr==nullptr) | (!(tptr->isOpen()))){
        error("Table does not exist or is not open");
        return;
    }
    std::string id = std::to_string(tableId);
    int bill = tptr->getBill();
    std::string billstring = std::to_string(bill);
    std::string c = "Table " + id + " was closed. Bill " + billstring + "NIS";
    tptr->closeTable();
    std::cout<<(c)<<std::endl;
    complete();
}

std::string Close::toString() const {
    if(getStatus() == COMPLETED){
        return "close " + std::to_string(tableId) + " Completed";
    }
    else if(getStatus() == ERROR) {
        return "close " + std::to_string(tableId) + " " + getErrorMsg();
    }
    return "";
}

Close* Close::clone() {
    Close* output = new Close(tableId);
    output->cloneStatus(*this);
    return output;
}

//End Close


//CloseAll
CloseAll::CloseAll() = default;

void CloseAll::act(Restaurant &restaurant) {
    std::vector<Table*> toClose = restaurant.getTables();

    for(unsigned int i = 0; i<toClose.size();i++){ //Closes all open table (table id is it's place in the vector)
        if (toClose[i]->isOpen()){
            Close close((int)i);
            close.act(restaurant);
        }
    }
    complete();
}

std::string CloseAll::toString() const {
    if(getStatus()==COMPLETED){
        return "closeall Completed";
    }
    return "";
}


CloseAll* CloseAll::clone() {
    CloseAll* output = new CloseAll();
    output->cloneStatus(*this);
    return output;
}

CloseAll:: ~CloseAll()=default;

//End Closeall

//PrintMenu
PrintMenu::PrintMenu() = default;

void PrintMenu::act(Restaurant &restaurant) {
    std::vector<Dish> toPrint = restaurant.getMenu();
    for(unsigned int i = 0; i<toPrint.size();i++){
    std::string name = toPrint[i].getName();
    std::string type = DTtoString(toPrint[i].getType());
    std::string price = std::to_string(toPrint[i].getPrice());
    std::string output = name + " " +  type + " " +  price + "NIS";
    std::cout<<output<<std::endl;
    }
    complete();
}

std::string PrintMenu::toString() const {
    return "menu Completed";
}

std::string PrintMenu::DTtoString(DishType dt) {
    if (dt == VEG){
        return "VEG";
    }
    if (dt == ALC){
        return "ALC";
    }
    if (dt == SPC){
        return "SPC";
    }
    if (dt == BVG){
        return "BVG";
    }
    return ""; // will never be reached on valid input
}

PrintMenu* PrintMenu::clone(){
    PrintMenu* output = new PrintMenu();
    output->cloneStatus(*this);
    return output;
}
//End PrintMenu


//PrintTableStatus
PrintTableStatus::PrintTableStatus(int id):tableId(id) {}

void PrintTableStatus::act(Restaurant &restaurant) {
    Table* tptr = restaurant.getTable(tableId);
    std::string tableId = std::to_string(this->tableId);
    if(!(tptr->isOpen())){
        std::string printTable = "Table " + tableId + " status: closed";
        std::cout<<(printTable) << std::endl;
    }
    else{
        std::string printTable = "Table " + tableId + " status: open";
        std::cout<<(printTable) << std::endl;
        std::cout<<("Customers:")<<std::endl;
        std::vector<Customer*> customers = tptr->getCustomers();
        std::vector<OrderPair> orderlist = tptr->getOrders();
        for(unsigned int i = 0; i<customers.size();i++){
            std::string id = std::to_string(customers[i]->getId());
            std::string printCust = id + " " + customers[i]->getName();
            std::cout<<(printCust)<<std::endl;
        }
        std::cout<<("Orders:")<<std::endl;
        for(unsigned int j = 0; j<orderlist.size();j++){
            if(orderlist[j].first != -1) {
                std::string id = std::to_string(orderlist[j].first);
                std::string name = orderlist[j].second.getName();
                std::string price = std::to_string(orderlist[j].second.getPrice());
                std::string printOrd = name + " " + price + "NIS " + id;
                std::cout << (printOrd) << std::endl;
            }
        }
        std::string bill = std::to_string(tptr->getBill());
        std::string printBill = "Current Bill: " + bill + "NIS";
        std::cout<<(printBill)<<std::endl;
    }
    complete();
}

std::string PrintTableStatus::toString() const {
    return "status " + std::to_string(tableId) + " Completed";
}

PrintTableStatus* PrintTableStatus:: clone(){
    PrintTableStatus* output = new PrintTableStatus(tableId);
    output->cloneStatus(*this);
    return output;
}

//End PrintTableStatus


//PrintActionsLog
PrintActionsLog::PrintActionsLog()=default;

void PrintActionsLog::act(Restaurant &restaurant) {

    std::vector<BaseAction*> log = restaurant.getActionsLog();
    for(unsigned int i = 0; i <log.size(); i++){
        std::string toPrint = log[i]->toString();
        std::cout << toPrint << std::endl;
        }
    }

std::string PrintActionsLog::toString() const {
    return "log Completed";
}

PrintActionsLog* PrintActionsLog:: clone(){
    PrintActionsLog* output = new PrintActionsLog();
    output->cloneStatus(*this);
    return output;
}
//End PrintActionsLog

//Backup
BackupRestaurant::BackupRestaurant()=default;

void BackupRestaurant::act(Restaurant &restaurant) {
    if(backup == nullptr){
    backup = new Restaurant(restaurant);
    }
    else{
        delete backup;
        backup = new Restaurant(restaurant);
    }
    complete();
}

std::string BackupRestaurant::toString() const {
    return "backup Completed";
}

BackupRestaurant* BackupRestaurant::clone (){
    BackupRestaurant* output = new BackupRestaurant();
    output->cloneStatus(*this);
    return output;
}
//End Backup

//Restore
RestoreResturant::RestoreResturant()=default;

void RestoreResturant::act(Restaurant &restaurant) {
    if(backup == nullptr){
        error("No backup available");
    }
    else{
        restaurant=*backup; //Delete me = deallocate memory
        complete();
    }

}

std::string RestoreResturant::toString() const {
    if(getStatus()==COMPLETED)
    return "restore Completed";
    else if(getStatus() == ERROR){
        return "restore " + getErrorMsg();
    }
    return "";
}

RestoreResturant* RestoreResturant::clone (){
    RestoreResturant* output = new RestoreResturant();
    output->cloneStatus(*this);
    return output;
}
//End Restore
