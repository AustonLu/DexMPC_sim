//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2013 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Filename            : $RCSfile: AxiFrbmMacro.cpp,v $
//
// Checked In          :  2013-05-09 16:29:11 +0100 (Thu, 09 May 2013)
//
// Revision            : 150004
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: Apb convertion Model .. used by AMIB model 
//
//---------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Include
//-------------------------------------------------------------------------

#include "../include/Model.h"

//void Model_Apbconv::local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i = NULL) 
void Model_Apbconv::local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i = NULL, Dom *DomConfiguration_i = NULL) {

    //Default allow zero strobe to false
    allow_zero_strobes = false;


   /////////////////////////////////////////////////////////////////////////////////////////////////////////
    string master_if_port_name = param_s("master_if_port_name");
    string key_string;
    string search_key;

    master_if_port_name = master_if_port_name + ",";   
    #ifdef DEBUG 
    cout <<"The master_if_port_name of this block is: ( "<<master_if_port_name<<"="<<param_s("master_if_port_name") <<" ) "<<endl;
    #endif
  ///////////////////////////////////////////////////////////////////////////////////////////////////////// 
  //Insert elements in the slave_s_region container
    {
     int region_field=0; 
     while(master_if_port_name !=""){  
       
        key_string          = master_if_port_name.substr(0,master_if_port_name.find_first_of(','));
        master_if_port_name = master_if_port_name.substr(master_if_port_name.find_first_of(',')+1);
        
        slave_s_region[key_string] = region_field;
        region_field += 1;
             
        #ifdef DEBUG 
         cout <<"\n Print the next information key_string: "<<key_string<<" master_if_port_name: "<<master_if_port_name<<" "<<endl;
        #endif
     }
   }    
  
  ///////////////////////////////////////////////////////////////////////////////////////////////////////// 
   map <string,int>::iterator region_it;
   
   
   #ifdef DEBUG 
   cout<<"\n\n\n\n  The container's size is: "<< (int) slave_s_region.size() <<" \n"<<endl;
     
   for(region_it = slave_s_region.begin(); region_it != slave_s_region.end(); region_it++){
    cout<<"The apb slave is: "<<region_it->first <<", the slave's region is: "<<region_it->second <<""<< endl;
   } 
   #endif 
  ///////////////////////////////////////////////////////////////////////////////////////////////////////// 

  ///////////////////////////////////////////////////////////////////////////////////////////////////////// 
  string protocol_string;
  
   map<string , Node*>  :: iterator connect_info_it;
   map<string , string> :: iterator protocol_it;
   map<int    , string> :: iterator region_protocol_it;

        
   for(region_it = slave_s_region.begin(); region_it != slave_s_region.end(); region_it++){
    
    search_key = name + "." + region_it->first;
    connect_info_it = connect_info->find(search_key);

    if ( connect_info_it != connect_info->end() ){
      slave_s_protocol[region_it->first]= DomReader.get_value(connect_info_it->second,"protocol") ;   
    } else {
      cout<< "Error! Check the line 90 Model_Apbcon"<<endl;
    }
   #ifdef DEBUG 
    cout<<"The apb slave is: "<<region_it->first <<", the slave's is: "<< slave_s_protocol[region_it->first]<<". " << endl;
   #endif
   } 

  #ifdef DEBUG 
  for (protocol_it = slave_s_protocol.begin(); protocol_it != slave_s_protocol.end(); protocol_it++) {
    cout << "Apb slave: "<<protocol_it->first <<" slave's protocol: "<< protocol_it->second<<"  "<<endl;
  }
  #endif
 
  protocol_it = slave_s_protocol.begin();
  region_it   = slave_s_region.begin();

  while ( region_it != slave_s_region.end() ){
   slave_region_protocol[(*region_it).second] = (*protocol_it).second;
   region_it++;
   protocol_it++;
  }
 
  #ifdef DEBUG 
  for (region_protocol_it = slave_region_protocol.begin(); region_protocol_it != slave_region_protocol.end() ; region_protocol_it++ ){
    cout <<"The region is: "<< region_protocol_it->first <<", the region's protocol is: "<< region_protocol_it->second <<" " <<endl;
   }
  #endif

}

string Model_Apbconv::Run(deque<transaction> * input, deque<transaction> * output, transaction * original_trans) {

    transaction * new_trans;
    transaction * trans;
    
    int length;
    int size;
    unsigned long long Working_address;
    unsigned long long Working_address_aligned;
    int iterations;
    bool first_trans;
    int beat;
    string data;
    string strobe;
    int first_length;
    int second_length;
    frbm_namespace::amba_resp total_response = frbm_namespace::okay;

    try {

        //This model creates multiple transactions and maniplutes responsnes    
        //so it need to keep a copy of all the transactions it works on
        stored_trans = *input;

        //Check that the transaction is to a valid region if not 
        //set all remaining bytes to slverr and return 
        if (clist(param_s("master_if_port_name"), input->front().region) == "") {
              clear_transaction(original_trans, frbm_namespace::axi_slverr);
              return "";
        };

        while (input->empty() == false) { 

            trans = new transaction;
            *trans = input->front();    
            input->pop_front();

            length = (int)trans->length;
            size   = (int)pow(2.0, (int)trans->size);

            //Wrap specific logic
            if (trans->burst == axi_wrap) {
              second_length = (trans->address % (length * size)) / size;
              first_length = length - second_length;
            }
        
            //Set up conditions for loop
            iterations = length;

            //Set the working Address
            Working_address = trans->address;
            first_trans = true;
            beat = 0;

            //If there are any decerrs in the transaction update to OK and update orginal transaction
            for (int resp_no = 0; resp_no < 16; resp_no++ ) {
                string port_type;
                if (DomReader.get_value(parameters, "master_if_port_type") == "<UNDEF>")
                    port_type = "3";
                else
                    port_type = param_s("master_if_port_type");

                if ((trans->resp[resp_no] == axi_decerr) || (clist(port_type, trans->region) == "2")) {   
                     trans->resp[resp_no] = okay;
                     set_response_trans(original_trans, trans->bnumber[resp_no], okay, trans->user[resp_no]);
                }
            }
        
            //Do each iteration    
            while (iterations > 0) {

                 Working_address_aligned = Working_address - (Working_address % size);

                 //Create a new transaction
                 new_trans = new transaction;
                 *new_trans = *trans;

                 //Needed iterator
                 map <int, string> :: iterator slave_reg_prot_it;

                 //Set the address, length and size fields
                 if (first_trans || (trans->burst == axi_fixed)) {
                     new_trans->address = Working_address;
                     first_trans = false;
                 }
                 else {
                     new_trans->address = Working_address_aligned;
                 }
                 new_trans->length = 1;
                 new_trans->size = size32;
          
                 // Shift data into correct byte lane
                 string temp;
                 int insert_zeros;

                 temp = trans->data[beat];
                 insert_zeros = (4 - (Working_address_aligned % 4))*2 - trans->data[beat].length();
                 temp.insert(0, insert_zeros, '0');
                 temp = temp + "00000000";
                 data = temp.substr(0,8);

                 temp = trans->strobe[beat];
                 //Convert masks to strobes
                 if (temp == "") {
                 //     temp.insert(0, (new_trans->address % size), '0');
                 //     temp.insert(0, (size - (new_trans->address % size)), '1');
                      for (int b = 0; b < size; b++) {
                          if (trans->mask[beat].substr(b * 2, 2) != "00") {
                             temp += "1";
                          } else {
                             temp += "0";
                          }
                      };

                 };
                 insert_zeros = (4 - (Working_address_aligned % 4)) - temp.length();
                 temp.insert(0, insert_zeros, '0');
                 temp = temp + "0000";
                 strobe = temp.substr(0,4);

                 //cout << "data beat " << beat << " is : " << endl;
                 //cout << "data " << trans->data[beat] << " now : " << data << endl;
                 //cout << "mask " << trans->mask[beat] << endl;
                 //cout << "strobe (" << trans->strobe[beat] << ") is : " << strobe << endl;

                 //Set the data
                 new_trans->data[0] = data;
                 new_trans->strobe[0] = strobe;
                 new_trans->resp[0] = trans->resp[beat];
                 new_trans->bnumber[0] = trans->bnumber[beat];
        
                 //Send transaction
                 if (new_trans->strobe[0] != "0000" or new_trans->direction == rd or allow_zero_strobes == true) {

                     new_trans->protocol = apb;       
                     //G.K.
                     slave_reg_prot_it   = slave_region_protocol.find(new_trans->region);

                     if( slave_reg_prot_it ==  slave_region_protocol.end() ){
                          #ifdef DEBUG
                          cout <<"The region has not been found"<<endl;
                          #endif
                     } else if( slave_reg_prot_it->second == "apb4" ){
                          new_trans->protocol = apb4;
                          #ifdef DEBUG
                          cout <<"The protocol is apb4 there will be no change in the strobe but there will be change in the pprot."<<endl;
                          cout <<"The protocol is: "<<new_trans->protocol<<" "<<endl;
                          #endif
                     } 
                     #ifdef DEBUG
                     else{
                       cout<<"the protocol is apb2 or apb3 no change"<<endl;
                        }
                    #endif
                     output->push_back(*new_trans);
                 } else {
                     //Unstrobed beats wil get an ok response      
                     clear_bytes(original_trans, frbm_namespace::okay, new_trans->bnumber[0]);
                     new_trans->resp[0] = frbm_namespace::okay;
                 }

                 //Now that we have created a transation record if it's a slave error
                 if (new_trans->resp[0] == frbm_namespace::axi_slverr) { 
                     total_response = frbm_namespace::axi_slverr;     
                 }
  
                 //work out next transfer address
                 beat++;
                 //If fixed set the address back to the input transfer
                 if (trans->burst == axi_fixed) {
                   Working_address = trans->address;
                 }
                 else if (trans->burst == axi_wrap and beat == first_length) {
                   Working_address = Working_address - size*(length - 1) ;
                 }
                 else {
                   Working_address = Working_address + size;
                 }
                 iterations--;
             };
        };

        //Set the final response (any other components such as bridges will get a chance to correct this)
        //This works for the directed tests .. where we have control of all the responses etc ... but not
        //for the random.
        if (new_trans->direction == wr) {
              original_trans->resp[0] = total_response;   
        };

        return ""; 
        

    } catch (const char * error) {

            cout << "Caught: APB convertion failed with message : " << error << endl;
            exit(1);
    }
         
}

void Model_Apbconv::Return(deque<transaction> * input, deque<transaction> * output) {

    try { 

       //Apb does not support user signals ... hence clear the response user signals  
       //Relying on the XML parameter will highlight errors in the XML
       check_rev_user(&stored_trans);

       //Go though all the transactions in the stored queue 
       for (unsigned int strans = 0; strans < stored_trans.size(); strans++) {

            //Reset the responses to okay 
            for (int beat = 0; beat < stored_trans[strans].length; beat++) {
                 stored_trans[strans].resp[beat] = okay;    
            };
       };

       //Now go through all the incoming transactions
       //Look at the reponses and if it's an error set the response for the corresponing
       //stored transaction to axi_slverr 
       for (unsigned int itrans = 0; itrans < input->size(); itrans++) {

            //If it's a write the resp[0] applies to the whole transaction   
            if ((input->at(itrans)).direction == frbm_namespace::write) {
                
                if ((input->at(itrans)).resp[0] != okay) {
                     //Set the response on the following bytes   
                     for (int beat = 0; beat < input->at(itrans).length; beat++) {
                          set_response(&stored_trans, input->at(itrans).bnumber[beat], axi_slverr, 0, input->at(itrans).user[beat]);    
                     };
                } 
            } else {
                 //Go through each beat   
                 for (int beat = 0; beat < input->at(itrans).length; beat++) {
                     if ((input->at(itrans)).resp[beat] != okay) {  
                         set_response(&stored_trans, input->at(itrans).bnumber[beat], axi_slverr, 0, input->at(itrans).user[beat]);    
                     };
                 };
            };
       };

       //Having modifed the transactions in the stored_trans list
       input->clear();
       *output = stored_trans;

    } catch (const char * error) {

            cout << "Caught: APB convertion failed with message : " << error << endl;
            exit(1);
    }
       
}
