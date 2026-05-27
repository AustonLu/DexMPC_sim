//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2014 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Filename            : $RCSfile: AxiFrbmMacro.cpp,v $
//
// Checked In          :  2014-07-02 14:46:06 +0100 (Wed, 02 Jul 2014)
//
// Revision            : 175910
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: System model calls the models in the correct order
//
//---------------------------------------------------------------------------


#include <typeinfo>
#include "../include/System.h"
#include "../include/Dom.h"
#include "../include/Model.h"

//-------------------------------------------------------------------------
// Config Function reads in top level XML file and instatiates all the 
//          necessary model classes
//-------------------------------------------------------------------------
int System::Config(char * filename, Register_map * PL301_reg_i, reg_update_block * reg_update) {

         //Open the suggested config file
         ifstream fin (filename);
         ostringstream buf;
         string token;
         string value;
         string valid;
         string parameter;
         string block_type;
         Model * new_Model;
         //Copy the pointer to the register map
         PL301_Reg = PL301_reg_i;

         Models.clear();
         locked_ports.clear();
         
         try {
            Dom DomReader;
            DomReader.read(filename);
                    //get all the connects
            vector<Node *> connects;
            connects = DomReader.get_nodes(DomReader.top, "/periph/connect");

            //Go through all the connect blocks 
            vector<Node*>::iterator node_iter;
            for (node_iter = connects.begin(); node_iter != connects.end(); node_iter++) {

                  //add the details
                  connect_info[DomReader.get_value((*node_iter), "dest") + "." + DomReader.get_value((*node_iter), "dest_port")] = *node_iter;
                  connect_info[DomReader.get_value((*node_iter), "src") + "." + DomReader.get_value((*node_iter),   "src_port")] = *node_iter;

                  //add the addr_map
                  connections[DomReader.get_value((*node_iter), "src") + "." + DomReader.get_value((*node_iter), "src_port")] =
                                          DomReader.get_value((*node_iter), "dest") + "." + DomReader.get_value((*node_iter), "dest_port");

            }

            //get parity width
            dpe_width = DomReader.get_value_i(DomReader.top, "/periph/dpe_width");

            //get all the inter blocks
            vector<Node *> inters;
            inters = DomReader.get_nodes(DomReader.top, "/periph/inter");

            //Go through all the inter blocks 
            //vector<Node*>::iterator node_iter;
            for (node_iter = inters.begin(); node_iter != inters.end(); node_iter++) {

                //get the type field  
                string inter_type = DomReader.get_value((*node_iter), "type");

                if (inter_type == "busmatrix") {
                       new_Model = new Model_busmatrix;
                } else if (inter_type == "default_slave") {
                       new_Model = new Model_default_slave;
                } else if (inter_type == "ib") {
                       new_Model = new Model_ib;
                } else if (inter_type == "reg_ss") {
                       new_Model = new Model_reg_ss;
                } else if (inter_type == "reg_ss_dist") {
                       new_Model = new Model_reg_ss_dist;
                } else if (inter_type == "vnb") {
                       new_Model = new Model_vnb;
                } else if (inter_type == "tlx") {
                       new_Model = new Model_tlx;                
                } else if (inter_type == "id") {
                       continue;
                } else {
                       throw "Ending inter block with no or unknown type";
                }

                //get the name of the block from the tree
                string inter_name = DomReader.get_value((*node_iter), "name");

                //Configure the new inter block
                if(inter_type =="ib") {

                   // The Model_ib requires the DomReader to check the ASIB-TLX-IB block order
                   new_Model->Config(*node_iter, PL301_Reg, &connect_info, reg_update,&DomReader); 

                   //Add the valid width
                   Node * cb;
                   
                   //Get the connect block connected here
                   cb = connect_info[inter_name + "." + DomReader.get_value((*node_iter),   "master_if_port_name")];
                   string vwidth = DomReader.get_value(cb, "valid_width");
                   DomReader.add_child(new_Model->parameters, "valid_width", vwidth);


                } else {
                   new_Model->Config(*node_iter, PL301_Reg, &connect_info, reg_update); 
                }

     

                if (inter_name != "") {
                      Models[inter_name] = new_Model;
                } else {
                      throw "Ending unnamed inter block";
                }
            }

            //get all the asibs
            vector<Node *> asibs;
            asibs = DomReader.get_nodes(DomReader.top, "/periph/asib");

            //Go through all the asibs blocks 
            for (node_iter = asibs.begin(); node_iter != asibs.end(); node_iter++) {
                    
                  //create new master model
                  new_Model = new Model_asib;

                  //set up the model
                  new_Model->Config(*node_iter, PL301_Reg, &connect_info, reg_update); 

                  //get the name of the block from the tree
                  string asib_name = DomReader.get_value((*node_iter), "name");

                  if (asib_name != "") {
                         Models[asib_name] = new_Model;
                  } else {
                         throw "Ending unnamed asib block";
                  }
            }
            
            //get all the amibs
            vector<Node *> amibs;
            amibs = DomReader.get_nodes(DomReader.top, "/periph/amib");

            //Go through all the amib blocks 
            for (node_iter = amibs.begin(); node_iter != amibs.end(); node_iter++) {

                  //create new master model
                  new_Model = new Model_amib;

                  //set up the model
                  new_Model->Config(*node_iter, PL301_Reg, &connect_info, reg_update); 

                  //get the name of the block from the tree
                  string amib_name = DomReader.get_value((*node_iter), "name");

                  //Deal with vn_external - REVISIT
                  Node * cb;
                  if (DomReader.get_value((*node_iter), "vn_external") == "nic") {
                         //Get the connect block connected here
                         cb = connect_info[amib_name + "." + DomReader.get_value((*node_iter),   "slave_if_port_name")];
                         string connected_block = DomReader.get_value(cb, "src");
                         if (Models.find(connected_block) != Models.end()) {
                             DomReader.add_child(Models[connected_block]->parameters, "vn_external", "true");
                         };
                  };

                  if (amib_name != "") {
                         Models[amib_name] = new_Model;
                  } else {
                         throw "Ending unnamed amib block";
                  }
            }

            //Determine information about the number of virtual networks
            vector<Node *> vns;
            vns = DomReader.get_nodes(DomReader.top, "/periph/virtual_networks/vn");
            string one_hot_vn = "true";

            for (node_iter = vns.begin(); node_iter != vns.end(); node_iter++) {
                  if (DomReader.get_value_i(*node_iter) >= 4) {
                       one_hot_vn = "false";     
                  }
            }

            // Print out available models 
            map<string,Model*>::iterator model_iter;
            for (model_iter = Models.begin(); model_iter != Models.end(); ++model_iter)
            {
                // Obtain RTTI information from models
                Model* model = model_iter->second;

                //Add the one_hot_vn paraeter to the model
                DomReader.add_child(model->parameters, "one_hot_vn", one_hot_vn);

                map<string,Model*>::iterator sub_model_iter;
                for (sub_model_iter = model->sub_models.begin(); sub_model_iter != model->sub_models.end();
                    ++sub_model_iter)
                {
                    // Obtain RTTI information from sub_models
                    Model* sub_model = sub_model_iter->second;
                }
            }

            return 0;

         } catch ( const char * error ) {
               cout << "Caught " << error << endl;     
               exit(1);
         }


}

void print_parity(transaction *trans)
{
    for (int b = 0; b < trans->length; b++)
    {
        cout << "data_parity[" << b << "] = 0x" << hex << trans->data_parity[b] << dec << endl;
    }
}

//-------------------------------------------------------------------------
// Takes the transactions and sends it through each model it will encounter
// on the way to the slave
//-------------------------------------------------------------------------
deque<transaction> System::Run(transaction * trans) {
    int input = 1;
    string current_port;
    string output_port, new_port;
    string destination = "";
    string final_destination;

    //Create an iterator accross the queues
    deque<transaction>::iterator trans_ptr;

    //Clear the model sequence as this is a new run
    model_sequence.clear();

    //Push the incoming transaction onto queue1
    queue1.clear();
    queue2.clear();

    try {

       //Number the bytes in the transaction
       trans->number_bytes();

       //Extract any parity from user
       trans->dpe_width = dpe_width;
       if (dpe_width > 0) trans->extract_parity();

       //If the protocol is AXI set the unlocking flags
       trans->unlocking = false;
       //If the transaction is locked set the locked flag and continue   
       if (trans->locked == lock) {
             locked_ports[trans->location] = true;
       } else if (locked_ports.find(trans->location) != locked_ports.end()) {
             trans->unlocking = true; 
             locked_ports.erase(locked_ports.find(trans->location));
       }

       //Push data onto the input queue
       queue1.push_back(*trans);

       //Determine the start port
       current_port = trans->location.substr(0, trans->location.find("."));

       //Record the destination
       final_destination = trans->final_dest;

       //While a block.port combination has an entry in the connections map
       while (current_port != "") {

               //Check the appropriate model exists
               if (Models.find(current_port) == Models.end()) throw "Failed to find model";

               //Call the model with parameters depending on value of input
               //Each model also get a pointer to the orginal transaction so it can manipulate it if required
               if (input == 1) {
                   output_port = Models[current_port]->Run(&queue1, &queue2, trans); 
                   input = 2;
               } else {
                   output_port = Models[current_port]->Run(&queue2, &queue1, trans); 
                   input = 1;
               }

               //Record the order that the models were called
               model_sequence.push_back(Models[current_port]);

               //Sanity check one queue should always be empty
               if (queue1.empty() != true && queue2.empty() != true) {
                       throw "Both queues contain transactions";
               }

               //Clear the destination
               destination = "";

               //Special case for the default slave then finish
               if (output_port == "") {
                    current_port = "";   
               }

	       //if output_port contains a list of output locations (comma separated values) instead of single value
	       while (output_port != ""){

			if (output_port.find(",") != string::npos){	//it is not last port
				new_port = output_port.substr(0, output_port.find(","));
				output_port = output_port.substr(output_port.find(",") + 1);
			}
			else{
				new_port = output_port;
				output_port = "";
			}


                        //Determine the next port
                        if (current_port == final_destination) { //only simulating one block

                                //finished
                                destination += current_port + "." + new_port;
			         if (output_port != "")
				         destination += ",";
			         else
                       		         current_port = "";

                        } else if (connections[current_port + "." + new_port].find("external.") != string::npos) {

                                //external port
			        string temp_port = current_port;
                                current_port = connections[current_port + "." + new_port];
                                destination += current_port.substr((int)current_port.find(".") + 1);
			        if (output_port != ""){
				        destination += ",";
				        current_port = temp_port;
			        }
			        else
                       		        current_port = "";
                       
                        } else if (connections.find(current_port + "." + new_port) == connections.end()) {  

                                //finished
                                destination += current_port + "." + new_port;
			        if (output_port != "")
				        destination += ",";
			        else
                       		        current_port = "";

                        } else {

                                //determine the destination_port
			        string temp_port = connections[current_port + "." + new_port];
                                destination += connections[current_port + "." + new_port];
			        if (output_port != "")
				        destination += ",";
			        else
                       		        current_port = temp_port.substr(0,temp_port.find("."));
                       
                        }
	       }


               //Update the location field of all transactions
               for (trans_ptr = queue1.begin(); trans_ptr != queue1.end();  trans_ptr++) {   
                    (*trans_ptr).location = destination;
               }

               //Set final location of all transactions
               for (trans_ptr = queue2.begin(); trans_ptr != queue2.end();  trans_ptr++) {   
                    (*trans_ptr).location = destination;
               }
       }

       //Make sure responses are in queue1
       if (input != 1) queue1 = queue2;

       //Finally return the output queue
       return queue1;

    } catch (const char * error) {
            cout << "Error during system modelling .. " << error << endl;
            exit(1);
    }


}

//-------------------------------------------------------------------------
// This function takes a pointer to a queue of transactions. IF the pointer
// is NULL it simply re-runs all the models in reverse order. 
// If the queue is not empty it performs some simple checks to check the
// queue matches queue1.
//
// If it does then queue1 is updated with the responses that were actually
// sent and the models re-run in reverse order. 
//
// The final input transaction can then be returned
//
// An error is thrown if queue does not match the input queue.
//-------------------------------------------------------------------------
transaction * System::Run_Reverse(deque<transaction> * trans_queue) {

   try {
     //Check if the input queue is NULL      
     if (trans_queue != NULL) {

         //Check that the transaction queues are the same length  
         if (queue1.size() != trans_queue->size()) {
             throw "Queue mismatch - Unrecoverable error!";
         }

         //Go through each element in the queues and copy over the response data and
         //the response user data - everything else checked in forward run (inc READ DATA)
         for (unsigned int transno = 0; transno < queue1.size(); transno++) {

             //Step one sanity check address, direction, length and size fields
             if (queue1[transno].address != (trans_queue->at(transno)).address ||
                 queue1[transno].size != (trans_queue->at(transno)).size ||
                 queue1[transno].length != (trans_queue->at(transno)).length ||
                 queue1[transno].direction != (trans_queue->at(transno)).direction) {

                 throw "Transaction mismatch - Unrecoverable error!";

             }

             //Copy all the data user signals and responses up to the transaction length
             //(NB All responses are still needed for AHB writes)
             for (int tlen = 0; tlen < queue1[transno].length; tlen++) {
                  queue1[transno].resp[tlen] = (trans_queue->at(transno)).resp[tlen];
                  queue1[transno].user[tlen] = (trans_queue->at(transno)).user[tlen];
             }
         }
     }

     //Call return of each model in turn
     //As each model should have kept a record of the transactions it output

     //Clear queue.
     queue2.clear();

     int input = 1;
     while (model_sequence.empty() == false)
     {
         if (input == 1) {
              model_sequence.back()->Return(&queue1, &queue2); 
              input = 2;
         } else {
              model_sequence.back()->Return(&queue2, &queue1); 
              input = 1;
         }

         model_sequence.pop_back();
     }

     //Now check there is only one transaction in the output queue
     if (input != 1) queue1 = queue2;

     if (queue1.size() == 0) {
        throw "No input transactions after reverse_run!";     
     } else if (queue1.size() > 1) {
        throw "Multiple transactions after reverse run!";     
     }

     //return the one transaction we have left
     return &(queue1.front());

   } catch (const char * error) {
            cout << "Error during system modelling .. " << error << endl;
            exit(1);
   }


}

//-------------------------------------------------------------------------
// System constructor
//-------------------------------------------------------------------------

System::System() {
}

//-------------------------------------------------------------------------
// System destructor
//-------------------------------------------------------------------------

System::~System() {
}
