import csv
import codecs
from os import curdir, sep, system
import subprocess
import time


class data_handler:
    def __init__(self):
        self.myData = {}
        with open("dllInventory.csv", "r") as csvfile:
            csv_reader = csv.reader(csvfile, delimiter=';')
            i=1
            for row in csv_reader:
                name = row[0]
                flag = True
                if name != "Name":
                    name = name.lower()
                    data = ("Version: " + row[1]) if row[1] != "" else ""
                    if row[2] != "":
                        data = data+" Company: "+row[2]
                    if not (self.myData.has_key(name)):
                        self.myData[name] = [data]
                    else:
                        for d in self.myData[name]:
                            if d == data:
                                flag = False
                        if flag:
                            self.myData[name].append(data)
        csvfile.close()
    
    def printdatabase(self):
        for data in self.myData:
            print(data)
            print(self.myData[data])
    
    def createTable(self, data):
        tmp = open("mytable.html", "r")
        head = ""
        tail=""
        flgh=True
        flgt=False
        for line in tmp:
            if "<tbody>" in line:
                head = head+line
                flgh=False
            if "</tbody>" in line:
                flgt=True
            if flgh:
                head = head+line
            if flgt:
                tail=tail+line
        tmp.close()
        newTbl = open("mytable.html", "w")
        head = head+data+tail
        newTbl.write(head)
        newTbl.close()

    def search(self, s_key):
        data = ""
        key = s_key.lower()
        if key in self.myData:
            i=1
            for inf in self.myData[key]:
                data = data+'<tr><td><input type="checkbox" name="'+str(i)+'" id="1"></td><td>' + s_key + "</td><td>" + inf + "</td></tr>\n"
                i=i+1
        self.createTable(data)

    def run_task1(self):
        print(time.asctime(), "try to run task1:")
        path = curdir+sep+"task1\\parser.exe a"
        print(path)
        system(path)
        print(time.asctime(), "finish running task1")
    
    def get_task1_names(self):
        names = []
        task1 = open("dllfiles.txt", "r")
        for line in task1:
            line = line.rstrip()
            if line.endswith(".dll") or line.endswith(".DLL"):
                arr = line.split("\\")
                name = arr[len(arr)-1]
                names.append(name)
        return names

    def loadtask1(self):
        self.run_task1()
        names = self.get_task1_names()
        data = ""
        i=1
        for name in names:
            key = name.lower()
            if key in self.myData:
                for inf in self.myData[key]:
                    data = data+'<tr><td><input type="checkbox" name="'+str(i)+'" id="1"></td><td>'+ name + "</td><td>" + inf + "</td></tr>\n"
                    i=i+1
            else:
                data = data+'<tr><td><input type="checkbox" name="'+str(i)+'" id="1"></td><td>' + name + "</td><td> No Information Found </td></tr>\n"
                i=i+1
        self.createTable(data)
    
    def clear(self):
        data = ""
        self.createTable(data)
    
    def isSelected(self,line,selected):
        for x in selected:
            text='name="'+x+'"'
            if text in line:
                return True
        return False

    def loadSelected(self,selected):
        tmp = open("mytable.html", "r")
        head = ""
        flg = True
        for line in tmp:
            if flg:
                head = head+line
            if ("<tbody>" in line):
                flg = not flg
            if ("</tbody>" in line):
                head = head+line
                flg = not flg
            if (not flg) and (self.isSelected(line,selected)):
                head= head+line
        tmp.close()
        tmp=open("mytable.html","w")
        tmp.write(head)
        tmp.close()

t= data_handler()