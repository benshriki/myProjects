#include "../include/Customer.h"

//Customer Constructor
Customer::Customer(std::string c_name, int c_id):name(c_name),id(c_id){
}
//End Customer Constructor

//Customer Destructor
Customer::~Customer()=default;
//End Customer Destructor

std::vector<int> Customer::order(const std::vector<Dish> &menu) {
    std::vector<int> tmp; // will extend function in children
    return tmp;
}

int Customer::getId() const {
    return id;
}
std::string Customer::getName() const {
    return name;
}

std::string Customer::toString() const {
    return getName();
}

//Veggie Constructor
VegetarianCustomer::VegetarianCustomer(std::string name, int id):Customer(name,id),expbvg(-1), lowveg(-1){
}
//End Veggie Constructor

std::string VegetarianCustomer::toString() const {
    std::string name = this->getName();
    std::string type = "veg";
    std::string output = name + "," + type;
    return output;
}
//Veggie Order
std::vector<int> VegetarianCustomer::order(const std::vector<Dish> &menu) {
    std::vector<int> output;
    if (expbvg != -1 && lowveg != -1) { //If we already found the relevant dishes
        output.push_back(lowveg);
        output.push_back(expbvg);
    }
    else{
        for(unsigned int i = 0;i < menu.size();i++){  //Else we iterate over the menu and look for them
            if(expbvg == -1 && menu[i].getType() == BVG){
                expbvg = i;
            }
            if(lowveg == -1 && menu[i].getType() == VEG){
                lowveg = i;
            }
            if(menu[i].getType() == BVG && menu[i].getPrice() > menu[expbvg].getPrice()){
             expbvg = i;
                 }
            }
            if(lowveg != -1 && expbvg != -1){
                output.push_back(lowveg);
                output.push_back(expbvg);
            }
    }
    return output;
}
//End Veggie Order

VegetarianCustomer* VegetarianCustomer::clone(){
    VegetarianCustomer* output = new VegetarianCustomer(getName(),getId());
    output->clonefields(expbvg,lowveg);
    return output;
}
void VegetarianCustomer::clonefields(int bvg, int dish) {
    this->expbvg = bvg;
    this->lowveg = dish;
}

//Cheap Customer Constructor
CheapCustomer::CheapCustomer(std::string name, int id):Customer(name,id),ordered(false){
}
//End Cheap Customer Constructor

//Cheap Customer Order
std::vector<int> CheapCustomer::order(const std::vector<Dish> &menu) {
    std::vector<int> output;
    if (!ordered){
            int chpdish = 0;
            for(unsigned int i = 1; i<menu.size();i++){
                if(menu[i].getPrice()<menu[chpdish].getPrice()){
                    chpdish = i;
                }
            }
            ordered = true;
            output.push_back(chpdish);
    }
    return output;
}

std::string CheapCustomer::toString() const {
    std::string name = this->getName();
    std::string type = "chp";
    std::string output = name + "," + type;
    return output;
}

CheapCustomer* CheapCustomer::clone(){
    CheapCustomer* output = new CheapCustomer(getName(),getId());
    output->clonefield(ordered);
    return output;
}

void CheapCustomer::clonefield(bool order) {
    this->ordered=order;
}

//Spicy Customer Constructor
SpicyCustomer::SpicyCustomer(std::string name, int id):Customer(name,id), ordered(false), chpbvg(-1){}
//End Spicy Customer Constructor

//Spicy Customer Order
std::vector<int> SpicyCustomer::order(const std::vector<Dish> &menu){
    std::vector<int> output;
    if(!ordered) {
        int spcexp = -1;
        for(unsigned int i = 0; i < menu.size(); i++) {
            DishType dt = menu[i].getType();
            if (dt == SPC) {
                if (spcexp == -1) {
                    spcexp = i;
                } else if (menu[i].getPrice() > menu[spcexp].getPrice()) {
                    spcexp = i;
                }
            }
                if (dt == BVG) {
                    if (chpbvg == -1)
                        chpbvg = i;
                    else if (menu[i].getPrice() < menu[chpbvg].getPrice()) {
                        chpbvg = i;
                    }
                }
        }
        if(spcexp != -1) {
            output.push_back(spcexp);
            ordered = true;
        }
    //    std::cout << chpbvg << std::endl;
    }
    else if (chpbvg != -1) {
        output.push_back(chpbvg);
    }
    return output;
}

std::string SpicyCustomer::toString() const {
    std::string name = this->getName();
    std::string type = "spc";
    std::string output = name + "," + type;
    return output;
}


SpicyCustomer* SpicyCustomer::clone(){
    SpicyCustomer* output = new SpicyCustomer(getName(),getId());
    output->clonefields(ordered, chpbvg);
    return output;
}

void SpicyCustomer::clonefields(bool ordered, int chp) {
    this->ordered = ordered;
    chpbvg = chp;
}



//Alcoholic Customer Constructor
AlchoholicCustomer::AlchoholicCustomer(std::string name, int id):Customer(name,id),bvglist(), ordered(false){}
//End Alcoholic Customer Constructor

std::vector<int> AlchoholicCustomer::order(const std::vector<Dish> &menu) {
    std::vector<int> output;
    if (!ordered){ //if alc customer hasn't ordered yet
        for(unsigned int i = 0; i < menu.size(); i++) {
            if (menu[i].getType() == ALC) {
                std::pair<int, int> tmp(-1*menu[i].getPrice(), menu[i].getId()*-1); //insert with -price
                bvglist.push_back(tmp);
            }
        }
        bvglist = bvgsort(bvglist); // returns list sorted by price
        if(bvglist.size() == 0){
            return output; //stop function if no alc was found (will return empty vector)
        }
    }
    else if(ordered && bvglist.size() == 0){ //ran out of things to order = empty order
        std::vector<int> norder;
        return norder;
    }
        bvglist.pop_back();
        std::pair<int, int> tmp = bvglist[bvglist.size()];
        output.push_back(tmp.second * -1);
        ordered = true;
        return output;
    }

std::string AlchoholicCustomer::toString() const {
    std::string name = this->getName();
    std::string type = "alc";
    std::string output = name + "," + type;
    return output;
}

std::vector<std::pair<int,int>> AlchoholicCustomer::bvgsort(std::vector<std::pair<int, int>> k){
    std::vector<std::pair<int,int>> output = k;
    std::sort(output.begin(), output.end());
    return output;
}

AlchoholicCustomer* AlchoholicCustomer::clone(){
    AlchoholicCustomer* output = new AlchoholicCustomer(getName(),getId());
    output->clonefields(bvglist,ordered);
    return output;
}

void AlchoholicCustomer::clonefields(std::vector<std::pair<int, int>> bvgl, bool ordered) {
    for(unsigned int i = 0; i<bvgl.size();i++){
        bvglist.push_back(bvgl[i]);
    }
    this->ordered = ordered;
}
