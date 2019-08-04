
#include "../include/Restaurant.h"


//Default Constructor

Restaurant::Restaurant():open(), tables(), menu(), actionsLog(), NumOfTables(),custcount(0){
};
//End Default Constructor


// Constructor
Restaurant::Restaurant(const std::string &configFilePath):open(true), tables(), menu(), actionsLog(), NumOfTables(),custcount(0) {

// Parse config
    std::ifstream input(configFilePath);
    std::vector<std::string> txt; // Temporary vector to store "lines" from the config file


    if(input.is_open()) {
        std::string line;
        while (std::getline(input, line)) { // reads line by line until it reaches the end
            if ((!line.empty() && (line.at(0) != '#'))) {//pushes non empty lines into vector
                txt.push_back(line);
            }
        }
        input.close();


        NumOfTables = atoi(txt[0].c_str());
        //Process chairs and create tables
        std::string ChairString = txt[1];   // This function extracts the amount of chairs into a vector
        std::string tmp;
        for (unsigned int i = 0; i < ChairString.size(); i++) {
            if ((ChairString.at(i) != ' ') & (ChairString.at(i) != ',')) {
                tmp = tmp + ChairString.at(i);
            } else {
                int capacity = std::atoi(tmp.c_str());
                Table *table = new Table(capacity); //Creates tables according to amount of chairs stored in vector
                tables.push_back(table);
                tmp = "";
            }
        }      //Finished creating tables with respective chairs according to config

        for (unsigned int i = 2; i < txt.size(); i++) { //This for will iterate over the menu items and create dishes

           std::string *toTokenize = &txt[i];
            std::string r[3] = {"", "", ""}; //dishes will be stored in this array, index 0 = name, index 1 = type, index 2 = price
            unsigned int parser = 0; //parser, parses over every char in the config string (per line)
            int delimiter = 0; //will inject words into "r"
            for(parser = 0; parser < toTokenize->size(); parser++) {
                if (delimiter > 2) {
                    break;
                }
                if (toTokenize->at(parser) != ',') {
                    r[delimiter] = r[delimiter] + toTokenize->at(parser);
                } else
                    delimiter++;
            }
            int price = atoi(r[2].c_str()); //converting string to int (price is always stored in the last index of r
            DishType dt = DTfromString(r[1]);
            Dish dish(i - 2, r[0], price, dt); // creates dishes for every item on the menu*/

            menu.push_back(dish); //dishes stored in menu according to order of appearance in config
        }

    }
}
// Constructor end

//Destructor
Restaurant::~Restaurant(){
    clear();
}
//Destructor


//Copy Constructor
Restaurant::Restaurant(const Restaurant &rest):open(),tables(),menu(),actionsLog(), NumOfTables(), custcount(){
    copy(rest);
}
//Copy Constructor End

//Move Constructor
Restaurant::Restaurant(Restaurant &&rest)noexcept :open(),tables(),menu(),actionsLog(), NumOfTables(),custcount(){
    move(rest);
}
//End Move Customer

//Copy Assignment Operator
Restaurant & Restaurant:: operator=(const Restaurant& rest)  {
    if (this != &rest) {
        clear();
        copy(rest);
    }
    return *this;
}
//Copy Assignment Operator End

//Move Assignment Operator
Restaurant & Restaurant:: operator=(Restaurant&& rest) noexcept  {
    if (this != &rest) {
        clear();
        move(rest);
    }
    return *this;

}
//Move Assignment Operator End


//Moves rest fields into this
void Restaurant::move(Restaurant &rest) {
    tables = std::move(rest.tables);
    actionsLog = std::move(rest.actionsLog);
    open = rest.open;
    menu = std::move(rest.menu);
    NumOfTables = rest.NumOfTables;
    custcount = rest.custcount;
    rest.open = false; //closes other restaurant (we took over from it)
}


//Clear - Deallocate this' fields
void Restaurant::clear(){
    for(unsigned int i=0;i<tables.size();i++){
        delete tables[i];
        tables[i]= nullptr;
    }
    tables.clear();

    for(unsigned int i=0;i<actionsLog.size();i++){
        delete actionsLog[i];
        actionsLog[i]= nullptr;
    }
    actionsLog.clear();
    menu.clear();

}
//End Clear

//Copy - Allocates using copy constructor
void Restaurant::copy(const Restaurant & rest)  {
    open=rest.open;
    custcount=(rest.custcount);
    for(unsigned int i=0;i<rest.tables.size();i++) {
        tables.push_back(new Table(*rest.tables[i])); //Table.CopyConstructor
    }


    for(unsigned int i=0;i<rest.actionsLog.size();i++){
        actionsLog.push_back(rest.actionsLog[i]->clone()); //clone returns a pointer to actionslog[i]
    }

    for(unsigned int i=0;i<rest.menu.size();i++){ //Dish.CopyConstructor
        Dish d(rest.menu[i]);
        menu.push_back(d);
    }

}
//End Copy

Table* Restaurant::getTable(int ind){
    if( ((unsigned int)ind > tables.size())| (ind < 0)){
        return nullptr;
    }
    return tables[ind];
}

void Restaurant::start(){
    open = true;
    std::cout<<"Restaurant is now open!"<<std::endl;
    while(open) {
        std::string getAction;
        getline(std::cin, getAction);
        std::vector<std::string> parsed = parse(getAction);
        if(parsed[0] == "open"){
            int id = atoi(parsed[1].c_str());
            std::vector<Customer *> customers_temp;
            Customer* cust = nullptr;
            for(unsigned int i = 2; i<parsed.size();i=i+2){
                if(parsed[i+1] == "veg"){
                    cust = new VegetarianCustomer(parsed[i],custcount);
                }
                else if(parsed[i+1] == "chp"){
                    cust = new CheapCustomer(parsed[i],custcount);
                }
                else if(parsed[i+1] == "spc"){
                    cust = new SpicyCustomer(parsed[i],custcount);
                }
                else if(parsed[i+1] == "alc"){
                    cust = new AlchoholicCustomer(parsed[i],custcount);
                }
                custcount++;
                customers_temp.push_back(cust);
            }
            OpenTable *action = new OpenTable(id,customers_temp);
            customers_temp.clear();
            action->act(*this);
            actionsLog.push_back(action);
        }

        //Order
        if(parsed[0] == "order"){
            int i = std::atoi(parsed[1].c_str());
            Order *action = new Order(i);
            action->act(*this);
            actionsLog.push_back(action);
            }
        //End Order

        //MoveCustomer
        if(parsed[0] == "move"){
            int src = atoi(parsed[1].c_str());
            int dst = atoi(parsed[2].c_str());
            int id = atoi(parsed[3].c_str());
            MoveCustomer *action = new MoveCustomer(src, dst, id);
            action->act(*this);
            actionsLog.push_back(action);
        }
        //End MoveCustomer

        //Close
        if(parsed[0] == "close"){
            int id = atoi(parsed[1].c_str());
            Close *action = new Close(id);
            action->act(*this);
            actionsLog.push_back(action);
        }
        //End Close

        //CloseAll
        if(parsed[0] == "closeall"){
            CloseAll *action = new CloseAll();
            open = false;
            action->act(*this);
            delete action;
        }
        //End CloseAll

        //PrintMenu
        if(parsed[0] == "menu"){
            PrintMenu *action = new PrintMenu();
            action->act(*this);
            actionsLog.push_back(action);
        }
        //End PrintMenu

        //PrintTableStatus
        if(parsed[0] == "status"){
            int id = atoi(parsed[1].c_str());
            PrintTableStatus *action = new PrintTableStatus(id);
            action->act(*this);
            actionsLog.push_back(action);
        }
        //End PrintTableStatus

        //PrintActionsLog
        if(parsed[0] == "log"){
            PrintActionsLog *action = new PrintActionsLog();
            action->act(*this);
            actionsLog.push_back(action);
        }
        //End PrintActionsLog

        //Backup Restaurant
        if(parsed[0] == "backup"){
            BackupRestaurant *action = new BackupRestaurant();
            action->act(*this);
            actionsLog.push_back(action);
        }
        //End Backup Restaurant

        if(parsed[0] == "restore"){
            RestoreResturant *action = new RestoreResturant();
            action->act(*this);
            actionsLog.push_back(action);
        }

    }
}


std::vector<Dish>& Restaurant::getMenu(){
    return menu;
}
const std::vector<BaseAction*>& Restaurant::getActionsLog() const {

   return actionsLog;
}
DishType Restaurant::DTfromString(std::string toParse) {
    DishType dt;
    if(toParse == "ALC"){
        dt = ALC;
    }
    if(toParse == "VEG"){
        dt = VEG;
    }
    if(toParse == "SPC"){
        dt = SPC;
    }
    if(toParse == "BVG"){
        dt = BVG;
    }
    return dt;
}

std::vector<Table*> Restaurant::getTables() {
    return tables;
    }

std::vector<std::string> Restaurant:: parse(std::string str){
    std::vector<std::string> output;
    std::string tmp;
    char space = ' ';
    char comma = ',';
    for(unsigned int i=0;i<str.size();i++){
        if( (str.at(i) == space) | (str.at(i) == comma)){
            output.push_back(tmp);
            tmp="";
        }
        else{
            tmp=tmp+str[i];
        }
    }
    output.push_back(tmp);

    return output;
}
