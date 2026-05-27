#---------------------------------------------------------------------------
#- The confidential and proprietary information contained in this file may
#- only be used by a person authorised under and to the extent permitted
#- by a subsisting licensing agreement from ARM Limited.
#-
#-            (C) COPYRIGHT 2008-2013 ARM Limited.
#-                    ALL RIGHTS RESERVED
#-
#- This entire notice must be reproduced on all copies of this file
#- and copies of this file may only be made by a person if such person is
#- permitted to do so under the terms of a subsisting license agreement
#- from ARM Limited.
#-------------------------------------------------------------------------------
#-
#- Version and Release Control Information:
#-
#-     Checked In          :  2013-05-09 16:08:52 +0100 (Thu, 09 May 2013)
#-     Revision            : 150001
#-
#-     Release Information : PL401-r1p2-00rel0
#-
#-------------------------------------------------------------------------------
#-
#- Purpose : This file is the base class for a standard SM for the ARM IPFS solution 
#-
#-
#- API Functions:
#-      build_options(self, parser, args, directories)
#-      check_location(self, args, help):
#-      run(self, args):
#-      clean(self, args):
#-      help(self, args):
#-
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Module imports
#-------------------------------------------------------------------------------
   
# From the standard library
from os import path, environ, chdir, chmod, getcwd, mkdir, remove, stat
import os
from optparse import SUPPRESS_HELP
from glob import glob
from copy import copy
import sys
import re
import stat
from stat import *
from subprocess import call

# From the IP Flow Solution library
from ipfs_globals import *
from ipfs_std_lib import *
from ipfs_optparse import IPFSOptionGroup

class sm_base:
   
   #-------------------------------------------------------------------------------
   # initialise - Declares values for the basic service
   # AUTOMATIC FUNCTION
   #-------------------------------------------------------------------------------
   def __init__(self, launch_dir, bin_paths, use_lsf, use_tool):
   
     # Initialise service module defaults
     self.name           = ''      # Name of the service

     #results after parsing
     self.options        = []      # Array of options after parsing
     self.args           = []      # Arguments left after parsing

     #List of sub_modules against directory
     self.sub_module_names   = {}
     self.sub_module_prefix  = {}
     self.sub_modules        = {}    # Look-up of sub_modules 
     self.dependent_services = []    # Dependent SMs
     self.depend_sm          = {}

     #Dependency variables
     self.enable_dep_check = False;
     self.input_files = []
     self.output_files = []
     self.output_dir = '';

     #lsf terms
     self.use_lsf        = use_lsf # Enable or disable the LSF sub_module
     self.use_lsf_clean  = 0       # By default don;t use lsf to clean
     self.lsf_service    = ''      # LSF service
     self.lsf_workflow   = ''      # LSF workflow
     self.licenses       = []      # Required licences

     #tool service
     self.use_tool       = use_tool # Enable or disable the Tool sub_module
     self.tool_service   = ''       # Tool service
     self.tools          = []       # Required Tools

     #useful directories
     self.launch_dir     = launch_dir
     self.bin_paths      = bin_paths
     self.change_dir     = True

     #useful arrays 
     self.delete_files   = []
     self.directories    = []
     self.directory_options = {}

     #reference to the parser
     self.parser         = ''

     #report service
     self.report_service  = ''
     self.report_mod     = ''
     self.self_report    = False

     #If lsf is specifed load it here. 
     if self.use_lsf:
          lsf_sub_mod = self.get_path("/sub_services/lsf.sm1")
          self.lsf_service = load_service(lsf_sub_mod, launch_dir, bin_paths, 0) 
          if self.lsf_service == '':
              self.use_lsf = False

     #If tool module is specifed load it here
     if self.use_tool:
          tool_sub_mod = self.get_path("/sub_services/tools.sm1")
          self.tool_service = load_service(tool_sub_mod, launch_dir, bin_paths, 0) 
          if self.tool_service == '':
              self.use_tool = False

   #-------------------------------------------------------------------------------
   # build_options - Function used to register all command line options 
   # API FUNCTION
   #-------------------------------------------------------------------------------
   def build_options(self, parser, args, directories, directory_options, help=0):

     #Set the parser reference
     self.parser = parser

     #Try to load a register report module if there is one
     if self.report_service != '':
          report_sub_mod = self.get_sm_path(getcwd(), self.report_service)
          self.report_mod = load_service(report_sub_mod, self.launch_dir, self.bin_paths, self.use_lsf, self.use_tool) 
          if self.report_mod == '':
              self.report_service = ''    

     #Add the options required by this SM   
     if self._add_all_options(args):
         return []  

     #Extract arguments as currently available
     self.options = self.extract_args(args)

     #Check the directories and load necessary sub_modules 
     directories = self.load_sub_services(directories, help)

     #If not in help mode without verobose load and build all dependent SM
     if len(self.dependent_services) > 0 and len(directories) == 1:
          if help == 0 or self.options.verbose == True:
               for dep_sm in self.dependent_services:   
                    #Load the service module    
                    sm_path = self.get_sm_path(directories[0], dep_sm)
                    sm_ref = load_service(sm_path, self.launch_dir, self.bin_paths, self.use_lsf, self.use_tool)
                    #Store the loaded service module 
                    if sm_ref != '':
                        #Store the reference to the service module
                        self.depend_sm[dep_sm] = sm_ref
                        sm_ref.build_options(parser, args, [directories[0]], directory_options, help)
                    else:
                        message( 'e1.09', "Failed to load %s SM in %s" % (dep_sm, directories[0] ))

     #If lsf is enabled pass the command on to the lsf module
     if self.use_lsf:
          if len(self.lsf_service.build_options(parser, args, ["."], {})) == 0:
              return []

     #IF the tool service is enabled pass the command on         
     if self.use_tool:
          if len(self.tool_service.build_options(parser, args, ["."], {})) == 0:
              return []

     #Build options on the report service
     if self.report_mod:
          if len(self.report_mod.build_options(parser, args, ["."], {})) == 0:
              return []

     #Call the build function for each sub_module
     for sub_module in self.sub_modules:
          if isinstance(self.sub_modules[sub_module], dict):
              for target in self.sub_modules[sub_module]:
                  remaining_dirs = self.sub_modules[sub_module][target].build_options(parser, args, [sub_module], directory_options, help)
                  if len(remaining_dirs) == 0:
                        self.sub_modules[sub_module].remove(target)
              if len(self.sub_modules[sub_module]) == 0:
                   self.directories.remove(sub_module)    
                   self.sub_modules.remove(sub_module)
          else:            
              remaining_dirs = self.sub_modules[sub_module].build_options(parser, args, [sub_module], directory_options, help)
              if len(remaining_dirs) == 0:
                    self.directories.remove(sub_module)    
                    self.sub_modules.remove(sub_module)
                    
      
     #Record the directories         
     self.directories = directories
     self.directory_options = directory_options

     return directories
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # run - Run fuction of the service module ... 
   # API_FUNCTION
   #-------------------------------------------------------------------------------
   def run(self, args):

     #Extract all arguments
     resp_args = {}
     result, self.options, self.args = self.parse_options(args)
     if result:
          return 1, resp_args   

     #Call run_sm for each directory 
     for directory in self.directories:

           #Move to the directory
           if self.change_dir:
                chdir(directory)

           #Create a copy of args to use from now on (added options do not pass up the tree)    
           cargs = copy(args)

           #Updates arguments
           cargs = self.update_args(cargs, directory)

           #Call the run_pre_dep functions .. allows SM to make mods to it's own
           #dependency lists according to supplied options
           if self.run_pre_dep(cargs, directory):
               return 1, resp_args  

           #Call all SM that this one has dependencies on
           if not hasattr(self.options, "report") or not self.options.report:
               for sm in self.depend_sm:
                  result, resp_args = self.depend_sm[sm].run(cargs)
                  #If this dependency failed abort
                  if result:
                      return result, resp_args     

                  #If a job code is supplied .. add it as a wait   
                  if resp_args.has_key('job_code'):
                      for code in resp_args['job_code']:    
                          cargs.extend(['--wait', code])     

           #Perform dependeny requirements checks (unless reporting)
           if not hasattr(self.options, "report") or not self.options.report:
              if not hasattr(self.options, "deep") or self.options.deep != True:
                  call_run, rvalues = self.check_own_dependencies(cargs, directory)
                  if call_run == False:
                     if len(rvalues) == 0:     
                         return 0, {}    
                     else:
                         return 0, {'job_code': rvalues}   

           #Double check the directory
           if self.change_dir:
                chdir(directory)

           #Call the run_sm or report_sm functions
           if hasattr(self.options, "report") and self.options.report:
               result, resp_args = self.report_sm(cargs, directory)
           else:
               result, resp_args = self.run_sm(cargs, directory)

           #Report Error
           if (result and self.name != 'lsf' and self.name != 'tools'):
               
              #Check that the error has been reported
              if not resp_args.has_key("ErrorReported"):
                 if (result < 0):
                     message( 'e1.08', "Keyboard Interupt while running %s SM" % (self.name))
                 else:     
                     message( 'e1.09', "Error while running %s SM" % (self.name))

                 resp_args["ErrorReported"] = True;
                  
              #return to launch_dir
              if self.change_dir:
                 chdir(self.launch_dir)
              #And quit   
              return result, resp_args

           #return to launch_dir
           if self.change_dir:
                chdir(self.launch_dir)

     #Post standard run - hook
     self.run_post_sm(cargs)

     return result, resp_args

   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # clean - A housekeeping function for the purpose of updating the status of the
   #          service after execution, and to perform clean-up of the workspace
   # API_FUNCTION
   #-------------------------------------------------------------------------------
   def clean(self, args):

     #Extract all arguments
     result, self.options, self.args = self.parse_options(args)
     if result:
         return 1    
     
     message( 'm1.09', "Cleaning %s" % self.name)
     for directory in self.directories:

        #Run additional run function for override 
        if self.clean_sm(args, directory):
            return 1    

        for item in self.delete_files:    
            targets = glob(directory + '/' + item)
            if len(targets) > 0:
                cmdline = 'rm -rf ' + " ".join(targets) 
                try:
                    self.run_command(args, cmdline, 1)
                except:
                    message( 'e1.09', "Clean failed .. due to %s" % exc_info()[1])
                    return 1

        #If deep is set call clean on dependend modules
        if len(self.dependent_services) > 0 and self.options.deep == True:
              for depend_service in self.dependent_services:  
                   if self.depend_sm.has_key(depend_service):
                        if self.depend_sm[depend_service].clean(args):     
                             return 1     

     #Return pass
     return 0
   
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # Help function - Displays help dialogue by processing the list entries using
   #                   calls to the standard help service
   # API FUNCTION
   #-------------------------------------------------------------------------------
   def help(self, args):
  
       self.parser.usage = 'ae ' + self.name + ' [options]'

       #Hook for SM specivfic help modifictaion. Provides hook to option group
       self.help_sm(args)

       #Pass the call on
       self.parser.print_help()
   
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # _add_all_options - This function registers all the automatic config options
   #                   Override add_options to just add other options
   #                   Override _add_all_options to change the standard behaviour
   #-------------------------------------------------------------------------------
   def _add_all_options(self, args):

      try:

          #First check to see if the option group has been added before
          if not self.parser.has_group(self.name + ' SM options'): 
              #Create the group 
              group = IPFSOptionGroup(self.parser, self.name + ' SM options',
                    'These options apply to the ' + self.name + ' service module')
              #Automatic registration of options based on directory and path matching
              #Add standard gui option        
              if not self.parser.has_option("--gui") and not self.parser.has_option("-g"):
                     group.add_option("-g", "--gui", dest="gui", action="store_true", default=False,
                          help='Select between gui and batch mode')
              #standard verbose option
              if len(self.dependent_services) > 0:
                   if not self.parser.has_option("--verbose"):
                        group.add_option("-v", "--verbose", default=False, 
                             action="store_true", dest="verbose",
                             help="print help for dependent sub_modules")
              #Add deep option if this SM has dependent modules or a dependeny check
              if self.enable_dep_check or len(self.dependent_services) > 0:
                  if not self.parser.has_option("--deep"):
                        group.add_option("--deep", default=False, 
                             action="store_true", dest="deep",
                             help="Force rebuild/clean of all dependent modules")
              #Lsf options 
              if self.use_lsf and not self.parser.has_option("--lsf_off"):
                     group.add_option("--lsf_off", default=False, 
                            action="store_true", dest="lsf_off",
                            help="Don't use LSF for this command")
              #report options
              if (self.report_mod or self.self_report) and not self.parser.has_option("--report"):
                     group.add_option("--report", default=False, 
                            action="store_true", dest="report",
                            help="Run post operation actions")
              #Call to standard add_options for over-ride and add the group         
              if self.add_options(args, group):
                  return 1    
              #add the group if options have been added    
              self.parser.add_option_group(group)
          else:
              #Call mod options .. for override    
              if self.mod_options(args):
                  return 1    

      except:
          message( 'w1.09', "Failed add options (%s SM) %s" % (self.name, exc_reason()))
          return 1
 
      #Return pass
      return 0
       
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # extract_args - This function is used to extract any registered command line
   #                arguments from args. The are returned as a list
   #-------------------------------------------------------------------------------
   def extract_args(self, args):
      try :
         coptions = []
         (coptions, ignore) = self.parser.extract_args(args)
      except:
         message( 'e1.09', "Failed to extract command line args in %s SM due to %s" % (self.name, exc_info()[1]))
      
      # return list
      return coptions     

   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # parse_options - This function is used to extract all registered command line
   #              options. An error is raised if the parse failed
   #-------------------------------------------------------------------------------
   def parse_options(self, args):
      try :
         coptions = []
         cargs = []
         (coptions, cargs) = self.parser.parse_args(args)
      except:
         message( 'e1.09', "Failed to parse command line in %s SM due to %s" % (self.name, exc_info()[1]))
         return 1, [], []
      
      # return list
      return 0, coptions, cargs     
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # run_command function - 
   #      Submits the command using the appropriate settings for LSF 
   #-------------------------------------------------------------------------------
   def run_command(self, args, command, clean=0, ret_values={}):

       #make a shallow copy of args        
       cargs = copy(args)

       lsf_on = self.use_lsf;
       if clean:
          lsf_on = self.use_lsf_clean

       #If we are using LSF add the licence requirments to the command line 
       if (lsf_on and not self.options.lsf_off):

            #Add job description
            if self.lsf_workflow != '':
            	cargs.append("--job_description")
            	cargs.append(self.lsf_workflow)

            for lic in self.licenses:
                cargs.append("--license")
                cargs.append(lic)

            #Add the command
            cargs.append('--command')
            cargs.append(command)

            #Pass control over to the lsf module
            result, rdata = self.lsf_service.run(cargs)

            #Add job code to return values
            if rdata.has_key('job_code'):
               ret_values['job_code'] = rdata['job_code']

            #Write the lsf_job_code to a temp file
            if rdata.has_key('job_code') and self.enable_dep_check:
               FILE = open('lsf_job_code', "w")
               FILE.write(rdata['job_code'][0])
               FILE.close()

            #return
            return result, ret_values
          
       else:         
           try:
               return_code = call(command.split(' '))
               if return_code != 0:
                   message( 'e1.09', "Command returned error code %s (SM %s)" % (return_code, self.name))
           except KeyboardInterrupt:
               return -1, {} 
           except:
               print exc_info() 
               return 1, {}
   
       #Return pass code        
       return 0, ret_values
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # write_run_script  
   #      Write an array out to the specifed file and changes it's mode to
   #      be execuatable
   #-------------------------------------------------------------------------------
   def write_run_script(self, run_script, filename, args):

         try:
            #Remove the file first if it exists
            if path.exists(filename):
               chmod(filename, S_IRWXO | S_IRWXG | S_IRWXU)
               remove(filename)     
            #Open file
            FILE = open(filename, "w")
            #Header information
            FILE.write('#!/bin/csh -f\n')
            #Copy the input arguments
            cargs = copy(args)
            #if using the tool module add the tool requests now 
            if self.use_tool:
                #Add the tool requests to the command line    
                for tool in self.tools:
                    cargs.append("--tool_req")
                    cargs.append(tool)
                #Run the tool service
                result, tool_args = self.tool_service.run(cargs)    
                #Output the tool requirements
                for line in tool_args['tool_req']:
                    FILE.write(line + '\n')
            #Finally output the rest of the run script 
            for line in run_script:
               FILE.write(line + '\n')
            #If use_lsf is true add a line to remove the running file
            if self.use_lsf and self.enable_dep_check:
               FILE.write('rm -rf lsf_job_code\n')     
            FILE.close()
            chmod(filename, S_IRWXO | S_IRWXG | S_IRWXU)
         except:
             message( 'e1.09', "Failed to write file %s %s" \
                  % (getcwd() + '/' + filename, exc_reason()))

   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # get_sm_path .. returns the path to a service module  
   #-------------------------------------------------------------------------------
   def get_sm_path(self, directory, sm_name):

        #if the sm_name starts with a . determine a relative path from directory
        if match(r'^\.', sm_name):
            sm_path = directory + '/' + sm_name + ".sm1"
            sm_path = path.normpath(sm_path)
        #Else look in the services and sub_services directory    
        else:
            sm_path = self.get_path("/services/" \
                  + sm_name + ".sm1")
            if (sm_path == ''):
                sm_path = self.get_path("/sub_services/" \
                      + sm_name + ".sm1")

        #return the path          
        return sm_path
   #-------------------------------------------------------------------------------
   
   #-------------------------------------------------------------------------------
   # get_path .. returns the path to a particular file from the bin_paths 
   #-------------------------------------------------------------------------------
   def get_path(self, filename):

        for directory in self.bin_paths:
             full_path = directory + "/" + filename;    
             full_path = path.normpath(full_path)
             if path.exists(full_path):
                  return full_path  

        #else return empty string          
        return '' 
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # cchdir .. Create and CHangeDIR  
   #-------------------------------------------------------------------------------
   def cchdir(self, dirname):

       current_dir = getcwd()
       
       #Create the new directory if needed
       if not path.exists(current_dir + "/" + dirname):
           mkdir(current_dir + "/" + dirname)    

       #CD into directory
       chdir(current_dir + "/" + dirname)    
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # Check own dependencies .. This function checks wether or not this service
   #                           module should be run. Checks are:
   #  1) Don't run if lsf is enables and there is an lsf_job_code file in the output dir
   #  2) If any of the output files don't exist ... run
   #  3) Don't run if all the registered input files are newer than the oldest output file  
   #  3) else run
   #-------------------------------------------------------------------------------
   def check_own_dependencies(self, args, directory):

       #Disable when not dependency checking
       if (self.enable_dep_check == False):
           return True, []         
      
       #Check 1)
       if self.use_lsf == True:
          try: 
             #Return the pending job_code   
             FILE = open(directory + '/' + self.output_dir + '/lsf_job_code', "r")
             job_code = FILE.readline()
             FILE.close()
             job_code.replace('\n', '')
             return False, [job_code]
          except:
             pass

       #Checkla - Does the output dir exist
       if not(path.exists(directory + '/' + self.output_dir)):
            return True, [];      

       #Check 2
       oldest_mod_time = 0;
       for out_file in self.output_files:
           target_files = glob(directory + '/' + out_file)

           #If no files found then run the SM
           if len(target_files) == 0:
                return True, [];     

           #Get the mod times of all the output files
           mod_times = [os.stat(file)[ST_MTIME] for file in target_files]
           oldest_mod_time = min(mod_times)

           #Go through all the input files and return true if any are older
           for in_file in self.input_files:

               #Input files can be relative to current directory or full path    
               target_files = glob(directory + '/' + in_file)

               if in_file[0] == "/":
                   target_files.extend(glob(in_file))

               for file in target_files:
                  if (os.stat(file)[ST_MTIME] > oldest_mod_time):
                     return True, [];     

       #No reason to rebuild
       message( 'm1.09', "Nothing to do for %s SM" % (self.name))
       return False, []             
      

   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # list_match .. Returns a list of all items in list that match mstring 
   #               where mstring is of form xxxx*xxx
   #-------------------------------------------------------------------------------
   def list_match(self, list, match_list):

       matches = []
       errors = []

       for option in match_list:
           matchstring = option.replace('*', '.*') 

           reg_exp = re.compile(matchstring + '$')
           #find all possible matches
           lmatches = [ item for item in list if match(reg_exp, item)]
           if len(lmatches) == 0:
               errors.append(option)
           else:    
               matches.extend(lmatches)    
       #uniquify the lists
       matches = [matches[item] for item in range(len(matches)) if matches[:item+1].count(matches[item]) == 1]
       errors = [errors[item] for item in range(len(errors)) if errors[:item+1].count(errors[item]) == 1]
       return matches, errors
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # Remove Options .. Returns a modifed list with the specifed option removed
   #                   args   = command line to modify
   #                   Option = option
   #                   takes_arg implies that the option takes an argument
   #                   The argument will be removed as well
   # NB this should never be called on an option that this SM does not register
   #-------------------------------------------------------------------------------
   def remove_option(self, args_in, option, takes_arg):

        args = copy(args_in)
        remove = []

        #If it's a long option type
        if option[0:2] == "--":
            search_options = [option]    
            #create a list of possible search values
            for search_len in range(len(option) - 2):
               search_options.append(option[0:search_len+2])     

            #Remove the option if it exists
            for sstring in search_options:
                for item_no in range(len(args_in)):
                   #If the item matches remove it     
                   if args_in[item_no] == sstring:
                       #If takes argument remove that too       
                       if takes_arg:
                           remove.append(item_no + 1)    
                       remove.append(item_no)     
            remove.sort()
            remove.reverse()            
            for item in remove:
               args.pop(item)     
            #if takes_arg look for the x=y form           
            if takes_arg:
                for sstring in search_options:
                    reg_string = sstring + '=.*'     
                    reg_exp = re.compile(reg_string)
                    args = [ item for item in args if not match(reg_exp, item)]

        return args           
                    
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # load_sub_services - Checks the directories and load sub_services for each if
   #                     if required
   #-------------------------------------------------------------------------------
   def load_sub_services(self, directories, help=0):
   
      #Return pass code (0 = ok, 1 = fail)
      return directories     
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # update_args - Checks if any options are defined in directory options for 
   #                specifed directory. If there are then any defined values in 
   #                cargs are removed and new values specified
   #-------------------------------------------------------------------------------
   def update_args(self, cargs, directory):

      #Return if nothing to do
      if directory not in self.directory_options:
          return cargs 

      #Go through each item to remove old
      for tag in self.directory_options[directory].keys():
          #Remove if exists
          cargs = self.remove_option(cargs, tag, True)
          cargs.extend([tag, self.directory_options[directory][tag]]) 

      return cargs    

   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # add_options - This function can be overriden to add SM specific services
   #-------------------------------------------------------------------------------
   def add_options(self, args, group):
   
      #Example 
      #group.add_option("-g", "--gui", dest="gui", action="store_true", default=False,
   
      #Return pass code (0 = ok, 1 = fail)
      return 0     
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   # mod_options - This function can be overriden to modify SM specific services
   #               NB. only called if the group has been previously added
   #-------------------------------------------------------------------------------
   def mod_options(self, args):
   
      #Return pass code (0 = ok, 1 = fail)
      return 0     
   #-------------------------------------------------------------------------------
   
   #-------------------------------------------------------------------------------
   #  - This function can be overriden to modify SM specific services
   #    Called from the run routine           
   #-------------------------------------------------------------------------------
   def run_sm(self, args, directory):
   
      #Return pass code (0 = ok, 1 = fail) and an empty array
      return 0, {}     
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   #  - This function can be overriden to modify SM specific services
   #    Called from the run routine           
   #-------------------------------------------------------------------------------
   def report_sm(self, args, directory):

      #Default behaviour is to ignore report and call run
      return self.run_sm(args, directory)     
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   #  - This function can be overriden to modify SM specific services
   #    Called from the run before any dependencies are checked          
   #-------------------------------------------------------------------------------
   def run_pre_dep(self, args, directory):
   
      #Return pass code (0 = ok, 1 = fail) 
      return 0     
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   #  - This function can be overriden to modify SM specific services
   #    Called from the run routine           
   #-------------------------------------------------------------------------------
   def clean_sm(self, args, directory):
   
      #Return pass code (0 = ok, 1 = fail)
      return 0     
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   #  - This function can be overriden to modify SM specific services
   #    Called from the help routine           
   #-------------------------------------------------------------------------------
   def help_sm(self, args):
   
      pass     
   #-------------------------------------------------------------------------------

   #-------------------------------------------------------------------------------
   #  - This function can be overriden to modify SM specific services
   #    Called from the run routine, at the end
   #-------------------------------------------------------------------------------
   def run_post_sm(self, args):
   
      pass     
   #-------------------------------------------------------------------------------
