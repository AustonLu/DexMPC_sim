//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2003-2014 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Filename            : $RCSfile: DriveAxiPv.h,v $
//
// Checked In          :  2014-03-21 18:45:16 +0000 (Fri, 21 Mar 2014)
//
// Revision            : 169546
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: DriveAxiPv
//
//---------------------------------------------------------------------------

#ifndef DOM_H
#define DOM_H

#include <iostream>
#include <fstream>
#include <cstdarg>
#include <cstdio>
#include <vector>
#include <map>

  class Node
  {
    public: 

    //Name
    string name;

    //Text
    string text;

    //Subnodes
    vector<Node *> children;

    //Parent
    Node * parent;

  };

  class Dom
  {

    public:

    //Top node
    Node * top;

    //get_value
    string get_value(vector<Node *> nodes) {
         Node * node;
         node = nodes.front();
         return node->text;
    }

    //get_value
    string get_value(Node * node) {
         return node->text;
    }

    //get_value
    int get_value_i(Node * node) {
         return atoi((node->text).c_str());
    }

    //get the value of a particular child node
    string get_value(Node * node, string path) {
         vector<Node *> nodes;
         nodes = get_nodes(node, const_cast<char *>(path.c_str()));
         if (nodes.size() == 0) {
            return "<UNDEF>";
         } else {
            return get_value(nodes);
      }
    }

    //get the value of a particular child node as an integer
    int get_value_i(Node * node, string path) {
         vector<Node *> nodes;
         nodes = get_nodes(node, const_cast<char *>(path.c_str()));
         if (nodes.size() == 0)
            return 0;
         else
            return atoi(get_value(nodes).c_str());
    }

    //Add parmeter
    void add_child(Node * node, string name, string text) {
          Node * new_node = NULL;
          new_node = new Node;
          new_node->parent = node;
          new_node->name = name;
          new_node->text = text;
          node->children.push_back(new_node);
    }

    vector<Node *> get_nodes(Node * node, string path) {
       return get_nodes(node, const_cast<char *>(path.c_str()));
    }

    //Get Nodes
    vector<Node *> get_nodes(Node * node, char * path) {
         string currpath;
         string subnode;
         currpath = string(path) + "/";
         vector<Node*>::iterator child_iter;
         vector<Node*>::iterator wnode_iter;
         vector<Node *> wnodes;
         vector<Node *> cnodes;

         //Add the input to the current nodes
         wnodes.push_back(node);

         while (currpath != "") {
              subnode = currpath.substr(0, currpath.find_first_of("/"));
              currpath = currpath.substr(currpath.find_first_of("/") + 1);
              if (subnode.length() == 0) {
                 continue;
              }
              //Do not allow the sub_node to be searched for
              if (top != NULL && subnode == top->name) {
                 continue;
              }
              //Check each node in the wnodes list
              for (wnode_iter = wnodes.begin(); wnode_iter != wnodes.end(); wnode_iter++) {
                  for (child_iter = (*wnode_iter)->children.begin(); child_iter != (*wnode_iter)->children.end(); child_iter++) {
                       if ((*child_iter)->name == subnode) {
                          cnodes.push_back(*child_iter);
                       }
                  }
              }
              //Copy cnodes to wnodes
              wnodes.clear();
              wnodes = cnodes;
              cnodes.clear();
         }
         return wnodes;
    }

    Node * get_first(Node * node, char * path) {
           vector<Node *> nodes;
           nodes = get_nodes(node, path);

           if (nodes.size() == 0)
               return NULL;
           else
               return nodes.front();    
    }

    //Print out tree
    void print(Node * node, int level = 0) {
         if (node == NULL) {
             cout << "Error node is NULL" << endl;
             exit(1);
         };

         //start a new line
         cout << "\n";

         //output spaces 
         for (int spaces = 0; spaces < level; spaces++) {
                cout << "  "; 
         };
         cout << "<" << node->name << ">" << node->text;
         //Go through all the children
         vector<Node*>::iterator child_iter;
         for (child_iter = node->children.begin(); child_iter != node->children.end(); child_iter++) {
             print(*(child_iter), level + 1);    
         };

         if (node->children.size() > 0) {
             cout << "\n";
             //output spaces 
             for (int spaces = 0; spaces < level; spaces++) {
                  cout << "  "; 
             };
         };
         //Output
         cout << "</" << node->name << ">";
    };

    //Read in XML file
    void read(char * filename, Node * cnode_in = NULL) {

         //Open the suggested config file
         ifstream fin (filename);
         ostringstream buf;
         char entry[250];
         string token;
         string value;
         Node * cnode = cnode_in;
         Node * wnode = NULL;
         map<string, string> entity_map;
         string ent_name;
         string ent_value;
         string filename_str = filename;

         //Set top to NULL
         if (cnode_in == NULL) {
            top = NULL;
         };
         
         try {

             //Check that file was opened
             fin.open(filename);
             if (!fin.is_open()) {
                    cout << "Filename is " << filename << endl;
                    throw "Failed to open xml file";
             };
             //Read the file into a string stream
             buf << fin.rdbuf();
             fin.close();
    
             //Read into string stream 
             istringstream config(buf.str());

             while (!config.eof() ) {
    
                  //Clear error flags
                  config.clear();

                  //get the next line 
                  config.getline(entry, 250, '>');

                  //convert to string
                  token = string(entry);

                  //If this is an entity declaration store it
                  if (token.find("<!ENTITY")!=string::npos) {

                       int ent_end_loc = (int)token.find("ENTITY") + 7;
                       ent_name = token.substr(ent_end_loc, (int)token.find("SYSTEM") - ent_end_loc - 1);
                       int ent_val_loc = (int)token.find_first_of("\"") + 1;
                       ent_value = token.substr(ent_val_loc, (int)token.find_last_of("\"") - ent_val_loc);

                       //Build up file name
                       if (ent_value[0] == '/') {
                            entity_map[ent_name] = ent_value;
                       } else {
                            entity_map[ent_name] = filename_str.substr(0, (int)filename_str.find_last_of("/")) + "/" + ent_value;  
                       };
                  };

                  //Check token for entities for each entity
                  for (map<string,string>::iterator ent_iter = entity_map.begin(); ent_iter != entity_map.end(); ent_iter++) {

                      string entity = "&" + ent_iter->first + ";";    
                      //Look for value
                      if (token.find(entity)!=string::npos) {

                           //Include the entity
                           read(const_cast<char *>(ent_iter->second.c_str()), cnode);
                           //Remove the entity
                           token.erase(token.find(entity), entity.length());
                      }
                              
                  }
               
                  //If this is a comment continue
                  if (token.find("<!")!=string::npos) {
                      continue;       
                  };

                  //ignore header information
                  if (token.find("<?")!=string::npos) {
                      continue;       
                  };
                 
                  //If there is : ignore everything after the space as tag includes a namespace
                  if (token.find(":")!=string::npos) {
                      token = token.substr(0, (int)token.find(" "));       
                  };

                  //If this is a close go up the tree
                  if (token.find("</")!=string::npos) {
                      if (top == NULL | cnode == NULL) {    
                           throw "Bad file format close\n";
                      };
                      cnode = cnode->parent;
                      continue;
                  };

                  //If this is an empty tag ignore it (still contains a \)
                  if (token.find("/")!=string::npos) {
                      continue;       
                  };

                  //Else create node
                  wnode = new Node;
                  wnode->parent = cnode;
                  wnode->name = token.substr((int)token.find("<") + 1);
                  value = "";
                  wnode->text = "";
                  while (config.peek() != '<' && config.peek() != -1) {
                     config.get(entry, 250, '<');
                     value += string(entry);
                     wnode->text += string(entry);
                  }

                  //Update top if necessary
                  if (top == NULL) {
                      top = wnode;
                  };

                  //Update current node
                  if (cnode != NULL) {
                      cnode->children.push_back(wnode);
                  };
                  cnode = wnode;

                  //Check token values for entities for each entity
                  for (map<string,string>::iterator ent_iter = entity_map.begin(); ent_iter != entity_map.end(); ent_iter++) {

                      string entity = "&" + ent_iter->first + ";";    
                      //Look for value
                      if (value.find(entity)!=string::npos) {

                           //Include the entity
                           read(const_cast<char *>(ent_iter->second.c_str()), cnode);
                           //Remove the entity
                           wnode->text.erase(value.find(entity), entity.length());
                      }
                              
                  }

             }

         } catch ( const char * error ) {

               cout << "Caught " << error << endl;     
               exit(1);
         };

    };

  };



#endif
