//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2010-2013 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Checked In          :  2013-05-09 16:29:11 +0100 (Thu, 09 May 2013)
//
// Revision            : 150004
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

#include "../include/frbm_types.h"
#include "../include/Register_map.h"

#ifdef SPECMAN
#include "specman.h"
#endif

#include <sstream>
#include <ostream>
#include <deque>
#include <string>

#ifndef PL301_REG_UPDATE_H
#define PL301_REG_UPDATE_H

using namespace arm_namespace;
using namespace std;
using namespace frbm_namespace;

#ifdef SPECMAN

 //Register monitor
 class register_monitor {

      public:

      //Register field
      string reg;
      string field;
      int vn;

      //default value
      int current_value;

      //log of updates;
      map<int, int> log;

      //Function to set register field value correctly value correctly
      int update(int Time, string block, Register_map * reg_block, bool oldest) {

           map<int, int>::iterator greater_match;

           //find upper bound
           greater_match = log.upper_bound(Time);

           //Return if log is empty of greater match = begin()
           //if (log.size() == 0) {
           //   return 0;
           //}

           //If match points at begin then all updates are older than all enties in the list
           //Hence set register back to previous value as it masy have been changed
           if (greater_match != log.begin()) {

               //Go back to the previous element which have a time less than or equal to req time
               greater_match--;

               //Check the time is <= input time
               //if ((*greater_match).first <= Time) {

                   //Perform register update
                   reg_block->write(reg.c_str(), field.c_str(), (*greater_match).second, vn);

                   //Erase older entries
                   if (oldest) {

                        //update the current value
                        current_value = (*greater_match).second;

                        greater_match++;
                        log.erase(log.begin(), greater_match);
                   }
              // }
           } else {

                   //Perform register update
                   //cout << "input time = " << Time << " rec time = None - log " << log.size() << endl;
                   reg_block->write(reg.c_str(), field.c_str(), current_value, vn);

           }

           return 0;
      }

      //Extract information from data
      int load(SN_LIST(byte) data, int location) {

           int entries;
           int value;
           int time;

           //determine how many entries to read
           entries = SN_LIST_GET(data,location++,byte);
           entries += SN_LIST_GET(data,location++,byte) << 8;

           for (int i = 0; i < entries; i++) {

              value =  SN_LIST_GET(data,location++,byte);
              value += SN_LIST_GET(data,location++,byte) << 8;
              value += SN_LIST_GET(data,location++,byte) << 16;
              value += SN_LIST_GET(data,location++,byte) << 24;
              time  =  SN_LIST_GET(data,location++,byte);
              time  += SN_LIST_GET(data,location++,byte) << 8;
              time  += SN_LIST_GET(data,location++,byte) << 16;
              time  += SN_LIST_GET(data,location++,byte) << 24;

              log[time] = value;
           }

           return location;
      }

      void init(string reg_i, string field_i, Register_map * reg_block) {

          //Store the current value
          reg = reg_i;
          field = field_i;


          //Set the current value
          current_value = reg_block->read_reset(reg.c_str(), field.c_str());
          log[0] = current_value;

          cout << "init called! " << reg << "(" << log[0] << ") vn" << vn << endl;
      }
  };

  //Monitor a point in the transaction and used to update register information
  class point_monitor {

      public:

      string block;
      int mon_number;
      int vn;

      //Map containing the history of the transaction
      //id against list of times
      map<int, vector<int> > write_history;
      map<int, vector<int> > read_history;

      //vector of each register type
      map<string, register_monitor> write_regs;
      map<string, register_monitor> read_regs;
      map<string, register_monitor> shared_regs;

      int update(amba_direction dir, int id, string block, Register_map * reg_block) {

          bool oldest;
          int time;
          map<int, vector<int> >::iterator history_it;
          map<string, register_monitor>::iterator reg_mon_it;

          //Select read or write
          if (dir == frbm_namespace::rd) {

              //Record the element
              history_it = read_history.find(id);

              //If there is no matching trasaction in the read_history
              if (read_history.count(id) == 0) {
                  cout << "No read has passed this point " << block << "(" << mon_number << ") with id " << id << endl;
                  // throw "Failed to find matching transaction";
              }
              else
              {
                  //Record the time
                  time = (*history_it).second.at(0);

                  //Determine if this the oldest read
                  map<int, vector<int> >::iterator map_iter;
                  bool oldest = false;
                  for (map_iter = read_history.begin(); map_iter != read_history.end(); map_iter++) {
                       if ((*map_iter).second.at(0) < time) {
                           oldest = false;
                           break;
                       }
                  }

                  //Update registers in read list
                  for (reg_mon_it = read_regs.begin(); reg_mon_it != read_regs.end(); reg_mon_it++) {
                       (*reg_mon_it).second.update(time, block, reg_block, oldest);
                  }

                  //Determine if the oldest transaction
                  if (oldest == true) {
                    for (map_iter = write_history.begin(); map_iter != write_history.end(); map_iter++) {
                       if ((*map_iter).second.at(0) <= time) {
                           oldest = false;
                           break;
                       }
                    }
                  }

                  //Update elements in shared list
                  for (reg_mon_it = shared_regs.begin(); reg_mon_it != shared_regs.end(); reg_mon_it++) {
                       (*reg_mon_it).second.update(time, block, reg_block, oldest);
                  }

                  //Delete the element from the read history
                  if ((*history_it).second.size() == 1) {
                     read_history.erase(history_it);
                  } else {
                     (*history_it).second.erase((*history_it).second.begin());
                  }
              }

          } else {

              //Record the element
              history_it = write_history.find(id);

              //If there is no matching trasaction in the write_history
              if (write_history.count(id) == 0) {
                  cout << "No write has passed this point " << block << "(" << mon_number << ") with id " << id << endl;
                  //throw "Failed to find matching transaction";
              }
              else
              {
                  time = (*history_it).second.at(0);

                  //Determine if this the oldest write
                  map<int, vector<int> >::iterator map_iter;
                  bool oldest = false;
                  for (map_iter = write_history.begin(); map_iter != write_history.end(); map_iter++) {
                       if ((*map_iter).second.at(0) < time) {
                           oldest = false;
                           break;
                       }
                  }

                  //Update registers in write list
                  for (reg_mon_it = write_regs.begin(); reg_mon_it != write_regs.end(); reg_mon_it++) {
                       (*reg_mon_it).second.update(time, block, reg_block, oldest);
                  }

                  //Determine if the oldest transaction
                  if (oldest == true) {
                    for (map_iter = read_history.begin(); map_iter != read_history.end(); map_iter++) {
                       if ((*map_iter).second.at(0) <= time) {
                           oldest = false;
                           break;
                       }
                    }
                  }

                  //Update elements in shared list
                  for (reg_mon_it = shared_regs.begin(); reg_mon_it != shared_regs.end(); reg_mon_it++) {
                       (*reg_mon_it).second.update(time, block, reg_block, oldest);
                  }

                  //Delete the element from the write history
                  if ((*history_it).second.size() == 1) {
                     write_history.erase(history_it);
                  } else {
                     (*history_it).second.erase((*history_it).second.begin());
                  }
              }

          }

          return 0;
      }

      //Extract information from data
      int load(SN_LIST(byte) data, int location, Register_map * reg_block) {

           int entries;
           int value;
           int time;
           string reg_name;
           string field_name;
           string full_reg_name;

           //determine the number of read entries to extract
           entries = SN_LIST_GET(data,location++,byte);
           entries += SN_LIST_GET(data,location++,byte) << 8;


           for (int i = 0; i < entries; i++) {

              //Value is the 24 bit ID
              value  =  SN_LIST_GET(data,location++,byte);
              value  += SN_LIST_GET(data,location++,byte) << 8;
              value  += SN_LIST_GET(data,location++,byte) << 16;

              time  =  SN_LIST_GET(data,location++,byte);
              time  += SN_LIST_GET(data,location++,byte) << 8;
              time  += SN_LIST_GET(data,location++,byte) << 16;
              time  += SN_LIST_GET(data,location++,byte) << 24;

              if (read_history.count(value) != 0) {
                  read_history[value].push_back(time);
              } else {
                  vector <int> info;
                  info.push_back(time);
                  read_history[value] = info;
              }
           }

           //determine the number of write entries to extract
           entries = SN_LIST_GET(data,location++,byte);
           entries += SN_LIST_GET(data,location++,byte) << 8;

           for (int i = 0; i < entries; i++) {

              //Value is the 24 bit ID
              value  =  SN_LIST_GET(data,location++,byte);
              value  += SN_LIST_GET(data,location++,byte) << 8;
              value  += SN_LIST_GET(data,location++,byte) << 16;

              time  =  SN_LIST_GET(data,location++,byte);
              time  += SN_LIST_GET(data,location++,byte) << 8;
              time  += SN_LIST_GET(data,location++,byte) << 16;
              time  += SN_LIST_GET(data,location++,byte) << 24;

              if (write_history.count(value) != 0) {
                  write_history[value].push_back(time);
              } else {
                  vector <int> info;
                  info.push_back(time);
                  write_history[value] = info;
              }
           }

           //Extract the number of read monitors
           entries = SN_LIST_GET(data,location++,byte);

           for (int i = 0; i < entries; i++) {

                //Determine the name of the register
                reg_name.clear();
                value = SN_LIST_GET(data,location++,byte);
                while (value != 0) {
                   reg_name.push_back(value);
                   value = SN_LIST_GET(data,location++,byte);
                }
                //Get the field anme
                field_name.clear();
                value = SN_LIST_GET(data,location++,byte);
                while (value != 0) {
                   field_name.push_back(value);
                   value = SN_LIST_GET(data,location++,byte);
                }

                full_reg_name = reg_name;
                full_reg_name.push_back('.');
                full_reg_name += field_name;

                //Check if the reg_monitor exists
                if (read_regs.count(full_reg_name) == 0) {
                    register_monitor * rmon;
                    rmon = new register_monitor;
                    rmon->vn = vn;
                    read_regs[full_reg_name] = *rmon;
                    read_regs[full_reg_name].init(reg_name, field_name, reg_block);
                }

                //Check if the write reg_monitor exists
                if (write_regs.count(full_reg_name) == 0) {
                    register_monitor * rmon;
                    rmon = new register_monitor;
                    rmon->vn = vn;
                    write_regs[full_reg_name] = *rmon;
                    write_regs[full_reg_name].init(reg_name, field_name, reg_block);
                }

                //pass on update
                location = read_regs[full_reg_name].load(data, location);
           }

           //Extract the number of write monitors
           entries = SN_LIST_GET(data,location++,byte);

           for (int i = 0; i < entries; i++) {

                //Determine the name of the register
                reg_name.clear();
                value = SN_LIST_GET(data,location++,byte);
                while (value != 0) {
                   reg_name.push_back(value);
                   value = SN_LIST_GET(data,location++,byte);
                }
                //Get the field anme
                field_name.clear();
                value = SN_LIST_GET(data,location++,byte);
                while (value != 0) {
                   field_name.push_back(value);
                   value = SN_LIST_GET(data,location++,byte);
                }

                full_reg_name = reg_name;
                full_reg_name.push_back('.');
                full_reg_name += field_name;

                //Check if the write reg_monitor exists
                if (write_regs.count(full_reg_name) == 0) {
                    register_monitor * rmon;
                    rmon = new register_monitor;
                    rmon->vn = vn;
                    write_regs[full_reg_name] = *rmon;
                    write_regs[full_reg_name].init(reg_name, field_name, reg_block);
                }

                //Check if the read reg_monitor exists
                if (read_regs.count(full_reg_name) == 0) {
                    register_monitor * rmon;
                    rmon = new register_monitor;
                    rmon->vn = vn;
                    read_regs[full_reg_name] = *rmon;
                    read_regs[full_reg_name].init(reg_name, field_name, reg_block);
                }

                //pass on update
                location = write_regs[full_reg_name].load(data, location);
           }

           //Extract the number of shared monitors
           entries = SN_LIST_GET(data,location++,byte);

           for (int i = 0; i < entries; i++) {

                //Determine the name of the register
                reg_name.clear();
                value = SN_LIST_GET(data,location++,byte);
                while (value != 0) {
                   reg_name.push_back(value);
                   value = SN_LIST_GET(data,location++,byte);
                }
                //Get the field anme
                field_name.clear();
                value = SN_LIST_GET(data,location++,byte);
                while (value != 0) {
                   field_name.push_back(value);
                   value = SN_LIST_GET(data,location++,byte);
                }

                full_reg_name = reg_name;
                full_reg_name.push_back('.');
                full_reg_name += field_name;

                if (shared_regs.count(full_reg_name) == 0) {
                    register_monitor * rmon;
                    rmon = new register_monitor;
                    rmon->vn = vn;
                    shared_regs[full_reg_name] = *rmon;
                    shared_regs[full_reg_name].init(reg_name, field_name, reg_block);
                }

                //pass on update
                location = shared_regs[full_reg_name].load(data, location);
           }

           return location;
      }
  };

  //Register update block
  class reg_update_block {

      public:

      //Map of all register data
      map<string, point_monitor> reg_data;

      //Pointer to the register block
      Register_map * reg_block;

      string to_string(arm_uint32 data, uint bits) {

          ostringstream data_str;
          //convert to string
          data_str << setw(bits) << setfill('0') << hex << data;
          return data_str.str();
      }

      //Register update
      void update(amba_direction dir, int id, string block, int monitor_num = 0, int vn = 0) {

          string mon_ref;
          string vn_mon;
          mon_ref = block;
          mon_ref.push_back('@');
          mon_ref += to_string(monitor_num, 2);

          //add vn to the name
          if (vn != 0) {
            vn_mon = mon_ref + "." + to_string(vn, 2);

            //IF there is a matching monitor
            if (reg_data.count(vn_mon) != 0) {
              reg_data[vn_mon].update(dir, id, block, reg_block);
              return;
            }
          }

          //IF there is no matching monitor return
          if (reg_data.count(mon_ref) == 0) {
             return;
          } else {
             //else update the block
             reg_data[mon_ref].update(dir, id, block, reg_block);
          }
      }

      //load in incoming data
      void load(SN_LIST(byte) data) {

           int entries;
           int value;
           int vn;
           int location = 0;
           string mon_name;

           //determine the number of read entries to extract
           entries = SN_LIST_GET(data,location++,byte);

           for (int i = 0; i < entries; i++) {

                //Determine the number extract the reg
                mon_name.clear();
                value = SN_LIST_GET(data,location++,byte);
                while (value != 0) {
                   mon_name.push_back(value);
                   value = SN_LIST_GET(data,location++,byte);
                }

                //Add a "." then get the field name
                mon_name.push_back('@');
                //Get the number of value
                value = SN_LIST_GET(data,location++,byte);
                mon_name += to_string(value, 2);

                //Get the vn number
                vn = SN_LIST_GET(data,location++,byte);

                //add vn to the name
                if (vn != 0) {
                    mon_name += "." + to_string(vn, 2);
                }

                //Check if the reg_monitor exists
                if (reg_data.count(mon_name) == 0) {
                    point_monitor pmon;
                    pmon.mon_number = value;
                    pmon.vn = vn;
                    reg_data[mon_name] = pmon;
                }

                //pass on update
                location = reg_data[mon_name].load(data, location, reg_block);
           }
      }
  };
#else

  //Empty place holders for directed world
  class reg_update_block {

        public:

        void update(amba_direction dir, int id, string block, int monitor_num = 0, int vn = 0) {

        }
  };

#endif

#endif
