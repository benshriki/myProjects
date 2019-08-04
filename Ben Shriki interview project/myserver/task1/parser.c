#include <stdio.h>
#include <string.h>
#include <windows.h>
#include <subauth.h>
#include <winternl.h>     //all the structures i need to do task1

/* my struct */
typedef struct _link{     //Circular linked list
  UNICODE_STRING * name;
  struct _link * next;
  struct _link * prev;
}dllLink;

/*dllLink functions */
dllLink * addlast(dllLink* head,UNICODE_STRING * name){
  if(!head){    //first element insert
      head=(dllLink*)malloc(sizeof(dllLink));
      head->name=name;
      head->next=head;    
      head->prev=head;
  }
  else{
    dllLink * toAdd=(dllLink *)malloc(sizeof(dllLink));
    toAdd->name=name;
    dllLink * last=head->prev;
    last->next=toAdd;     //previous last ->next =toAdd
    toAdd->next=head; 
    toAdd->prev=last;    
    head->prev=toAdd;
  }
  return head;
}

void printList( dllLink * head, char flag){
  if(head){
      FILE * fp=stdout;
      if(flag){
         fp=fopen("dllfiles.txt","w");
      }
      int indx=1;
      dllLink * curr=head;
      fprintf(fp,"Dll Files Names:\n");
      while((curr != head) || indx==1){
        fprintf(fp,"%d) %S\n",indx,(curr->name)->Buffer);
        indx++;
        curr=curr->next;
      }
      if (flag){
        fclose(fp);
      }
  }
}
void removelist(dllLink * head){
  dllLink * curr=head->next;
  while(curr != head){
    free(curr->name);
    curr=curr->next;
    free(curr->prev);
  }
  free(head->name);
  free(head);
}

/* extrect dll from peb function */

// stackoverflow ref = https://stackoverflow.com/questions/47363494/get-process-description
typedef NTSTATUS (NTAPI *NTQUERYINFORMATIONPROCESS)(
    IN HANDLE ProcessHandle,
    IN PROCESSINFOCLASS ProcessInformationClass,
    OUT PVOID ProcessInformation,
    IN ULONG ProcessInformationLength,
    OUT PULONG ReturnLength OPTIONAL
    ); 

PROCESS_BASIC_INFORMATION* currPbiProcess(){
  HANDLE process=GetCurrentProcess();  // this process
  PROCESS_BASIC_INFORMATION * pbi=(PROCESS_BASIC_INFORMATION*)malloc(sizeof(PROCESS_BASIC_INFORMATION));
  unsigned long returnSize=0;
  NTQUERYINFORMATIONPROCESS NTqip=NULL;

  NTqip = (NTQUERYINFORMATIONPROCESS)GetProcAddress(LoadLibraryW(L"ntdll.dll"), "NtQueryInformationProcess");

  
  if(!pbi){
    printf("PROCESS BASIC INFORMATION allocate has failed\n");
    return NULL;
  }
 if(!NT_SUCCESS(NTqip(process,                               // curr process handle
                      0,                                    // value to get Process Basic information (pbi)
                      pbi,                                 // pbi struct pointer
                      sizeof(PROCESS_BASIC_INFORMATION),  //size of struct
                      &returnSize                        // the size of the returned struct 
                                              )))
    {
      printf("NtQueryInformationProcess failed");
      free(pbi);
      return NULL;                                      
    }
    return pbi;
}

dllLink * createDllNamesList( PPEB peb){
  	PPEB_LDR_DATA pbLdrData = NULL;
    PLDR_DATA_TABLE_ENTRY ldrEntry=NULL;
    PLIST_ENTRY curr=NULL;
    PLIST_ENTRY head=NULL;
    pbLdrData=peb->Ldr;
    head=&(pbLdrData->InMemoryOrderModuleList);
    curr=head->Flink;
    dllLink * my_list=NULL;
    while(curr != head){
      ldrEntry=CONTAINING_RECORD(curr,LDR_DATA_TABLE_ENTRY,InMemoryOrderLinks);
      
      UNICODE_STRING tmp=ldrEntry->FullDllName;
      UNICODE_STRING * name =(UNICODE_STRING *) malloc(sizeof(tmp));
      memcpy(name,&tmp,sizeof(tmp));
      my_list=addlast(my_list,name);
      curr=curr->Flink;
    }
    return my_list;
}


int main (int argc,char ** argv){
    PROCESS_BASIC_INFORMATION * pbi=currPbiProcess();
    if(!pbi || !(pbi->PebBaseAddress)){
      printf("Error Module has not found");
      return -1;
    }
   
    dllLink * my_list= createDllNamesList(pbi->PebBaseAddress);
    char flag=(argv[1])?1:0;
    printList(my_list,flag);

    removelist(my_list);
    free(pbi);
    char in[10];
    
    if(!flag){
      printf("press Enter key to exit");
      fgetc(stdin);
    }
    return 0;
    }