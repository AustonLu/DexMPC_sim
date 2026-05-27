#!/bin/sh -
# run python from users path  \
"exec" "python" "$0" "$@"

#-------------------------------------------------------------------------------
#- The confidential and proprietary information contained in this file may
#- only be used by a person authorised under and to the extent permitted
#- by a subsisting licensing agreement from ARM Limited.
#-
#-            (C) COPYRIGHT 2008-2016 ARM Limited.
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
#- Checked In          :  2016-09-30 13:24:49 +0100 (Fri, 30 Sep 2016)
#- Revision            : 217190
#-
#- Release Information : PL401-r1p2-00rel0
#-
#-------------------------------------------------------------------------------
#-
#- Purpose : This is the main script co-ordinating service module execution.
#-           Please consult the supporting documentation before maintenance!
#-
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Module imports
#-------------------------------------------------------------------------------

# From the standard library
from sys import path as pypath
from sys import exit, argv, version_info, platform
from os import sep, environ, path, getcwd, chdir
from types import ModuleType
from re import match, sub
from time import localtime, sleep, time
from glob import glob
from optparse import SUPPRESS_HELP
from copy import copy, deepcopy
import sys, traceback

# From the IP Flow Solution library
from ipfs_globals import *
from ipfs_std_lib import *
from ipfs_optparse import *


#-------------------------------------------------------------------------------
#
# Functions
# =========
#
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  determine_paths - Constructs directory references from imported environment
#                     variables and static names
#-------------------------------------------------------------------------------
def determine_paths():

  # Check that the product source_me has been correctly sourced
  if not environ.get('IPFS_MCF_FILE'):
      message( 'f1.02', "Please source the 'source_me' file before executing!" )

  # Read in the MCF location
  iPaths['mcf_name'] = [environ.get('IPFS_MCF_FILE')]

  #If PRODUCT_HOME is not set use the current directory as the top of the tree
  if not environ.get('PRODUCT_HOME'):
      iPaths['product_home'] = getcwd()
  else:
      iPaths['product_home'] = environ.get('PRODUCT_HOME')

  # Determine the relative path where the user has invoked this script
  iScript['full_launch_dir'] = getcwd()

  phome_dirs = (iPaths['product_home']).split('/')
  launch_dirs = (iScript['full_launch_dir']).split('/')
  iScript['launch_dir'] = iScript['full_launch_dir']

  divergence = 0;
  #Foreach directory
  for dir_num in range(len(phome_dirs)):
      #If the directory matches
      if divergence == 1 or (dir_num >= len(launch_dirs)) or \
           phome_dirs[dir_num] != launch_dirs[dir_num]:
               divergence = 1
               iScript['launch_dir'] = '../' + iScript['launch_dir'];
      else:
            if launch_dirs[dir_num] != '':
                iScript['launch_dir'] = iScript['launch_dir'].replace(launch_dirs[dir_num], '', 1)

  #Add './' to the path
  iScript['launch_dir'] = './' + iScript['launch_dir']
  iScript['launch_dir'] = path.normpath(iScript['launch_dir'])

  #Set the lauch offset used for schedule files
  iScript['launch_offset'] = ''

  #Finally if the launch_dir is not . add another ./
  if iScript['launch_dir'] != '.':
      iScript['launch_dir'] = './' + iScript['launch_dir']

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  init_kernel - Initialises the state of the kernel to known default values.
#                 Note that only initialisation of variables is permitted here!
#-------------------------------------------------------------------------------
def init_kernel():
  # Announce kernel initialisation
  script_name = path.basename( argv[0] )
  # Declare internal script version - PLEASE MAINTAIN BETWEEN MAJOR RELEASES!
  iScript['ipfs_version'] = '1.00'
  iScript['schedule_file'] = 'unset_schedule_file'
  # Obtain the year for copyright purposes
  iScript['copyright_year'] = 2016
  # Declare essential default values, which are required before loading the
  #  master control file but may be updated later
  iMsg['product_name'] = 'unset_product_name'
  iMsg['line_width'] = 72
  iMsg['verbosity'] = 'full'
  iScript['name'] = script_name
  iScript['abort_on_error'] = True
  iScript['exit_code_ok'] = 0
  iScript['exit_code_error'] = 1
  iScript['exit_code_fatal'] = 2
  iScript['developer_mode'] = False
  iScript['sm_path_map'] = {}
  # Declare default values which may be later updated by settings in the
  #  master control file
  iScript['python_version'] = { 'min':(2, 2, 1), 'max':(3, 0, 0) }
  iScript['os_types'] = 'linux|solaris'
  iScript['release_year'] = 2010
  iScript['version'] = 'unset_version'
  iScript['title'] = 'unset_title'
  iScript['legalese'] =  'unset_legalese'
  iScript['use_lsf'] = False
  iScript['target_permissions'] = 0750
  iScript['totals'] = { 'all_warnings':0, 'all_errors':0, 'all_durations':0 }
  iScript['iteration'] = 0
  iScript['parser'] = ''
  iScript['callable_services'] = []
  # Initialise resettable variables
  iScript['totals'][ iScript['iteration'] ] = { 'errors':0, 'warnings':0, 'duration':0 }
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  setup_kernel - Configures the kernel for use with an IP product
#-------------------------------------------------------------------------------
def setup_kernel():
  # Determine essential file paths
  determine_paths()
  # Load mcf file
  load_mcf( iPaths['mcf_name'][0])
  # Display initial start-up dialogue
  display_banner()
  # Complete preliminary checks for elementary requirements
  product_requirements()
  # Locate and attempt to load the service modules
  # Check service directories of all the bin_paths
  load_services()
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  load_mcf - Reads a master control file to input settings that configure
#              the engine kernel
#-------------------------------------------------------------------------------
def load_mcf( mcf_name ):
  # Inspect the validity of the file
  #if integrity_check( mcf_name ):
  #  message('f1.01', "Integrity check failure in '%s'!" % path.basename(mcf_name) )
  # Attempt to open the master control file
  try:
    mcfdir, mcffile = path.split(mcf_name)
    master_ctrl_file = open(mcf_name, 'r')
  except:
    message( 'f1.05', "Cannot open the '%s' file!%s" % ( path.basename(mcf_name), exc_reason() ) )
  # Read and parse the file content on a per-line basis
  line = 0
  in_section = 'none'
  section_text = ''
  #Make sure there are no stored bin paths
  iPaths['bin_paths'] = []
  for text_line in master_ctrl_file:
    # Increment line counter and reset the error flag
    line += 1
    found_error = False
    # Remove any end-of-line comment
    text_line = sub(r'#.*$', '', text_line)
    # Pre-process lines except when currently inside a verbatim section
    if in_section != 'SCRIPT_LEGALESE':
      # Remove any leading or trailing whitespace, newline or carriage returns
      text_line = sub( r'\s*(\r|\n)$', '', sub(r'^\s*', '', text_line) )
    # Exclude blank lines
    if len(text_line):
        got_product_name = match(r'PRODUCT_NAME\s+"(.+)"', text_line)
        got_require_python = match(r'REQUIRE_PYTHON\s+{\s*min=(\d+\.\d+\.\d+)\s+max=(\d+\.\d+\.\d+)\s*}', text_line)
        got_require_os = match(r'REQUIRE_OS\s+{(.+)}', text_line)
        got_msg_width = match(r'MESSAGING_WIDTH\s+(\d+)', text_line)
        got_msg_verbosity = match(r'MESSAGING_VERBOSITY\s+(quiet|minimal|full)$', text_line)
        got_release_year = match(r'PRODUCT_RELEASE_YEAR\s+(\d{4})$', text_line)
        got_script_version = match(r'SCRIPT_VERSION\s+"(V?[0-9\.]+)"', text_line)
        got_script_title = match(r'SCRIPT_TITLE\s+"(.+)"', text_line)
        got_script_name = match(r'SCRIPT_NAME\s+"(.+)"', text_line)
        got_summary_delay = match(r'SUMMARY_DELAY\s+(\d+)', text_line)
        got_error_action = match(r'ABORT_ON_ERROR\s+(true|false)$', text_line)
        got_exit_code = match(r'EXIT_CODE_(OK|ERROR|FATAL)\s+(\d{1,3})$', text_line)
        got_section = match(r'(SCRIPT_LEGALESE)$', text_line)
        got_developer_mode = match(r'DEVELOPER_MODE\s+(true|false)$', text_line)
        got_sm_path_map = match(r'SM_PATH_MAP\s*(\w*)\s*\'(.*)\'', text_line)
        got_bin_dir = match(r'IPFS_BIN_DIR\s*\'(.*)\'', text_line)
        # Determine value assignment
        if in_section != 'none':
          if match(r'END_SECTION', text_line):
            # Store the section text to the appropriate variable
            if in_section == 'SCRIPT_LEGALESE':
              iScript['legalese'] = section_text
              section_text = ''
            in_section = 'none'
          elif in_section == 'SCRIPT_LEGALESE':
            section_text += text_line
          else:
            found_error = True
        elif got_msg_width:
          iMsg['line_width'] = int( got_msg_width.group(1) )
        elif got_msg_verbosity:
          iMsg['verbosity'] = got_msg_verbosity.group(1)
        elif got_summary_delay:
          iScript['summary_delay'] = int( got_summary_delay.group(1) )
        elif got_product_name:
          iMsg['product_name'] = got_product_name.group(1)
        elif got_release_year:
          iScript['release_year'] = int( got_release_year.group(1) )
        elif got_require_python:
          group_names = { 1:'min', 2:'max' }
          for item in group_names:
            required_version = []
            for revnum in got_require_python.group(item).split('.'):
              required_version.append( int(revnum) )
            iScript['python_version'][ group_names[item] ] = tuple(required_version)
        elif got_require_os:
          # Remove leading and trailing whitespace, and create pattern alternates
          iScript['os_types'] = sub( r'\s+', r'|', sub(r'(^\s+|\s+$)', '', got_require_os.group(1)) )
        elif got_script_version:
          iScript['version'] = got_script_version.group(1)
        elif got_script_name:
          iScript['name'] = got_script_name.group(1)
        elif got_script_title:
          iScript['title'] = got_script_title.group(1)
          if len(iScript['title']) > iMsg['line_width']:
            message( 'w1.01', "Script title on line %d exceeds messaging width - please reformat!" % line )
        elif got_error_action:
          if got_error_action.group(1) == 'false': iScript['abort_on_error'] = False
        elif got_exit_code:
          keycode = 'exit_code_' + got_exit_code.group(1).lower()
          iScript[keycode] = int( got_exit_code.group(2) )
        elif got_developer_mode:
          if got_developer_mode.group(1) == 'true': iScript['developer_mode'] = True
        elif got_sm_path_map:
          iScript['sm_path_map'][got_sm_path_map.group(1)] = got_sm_path_map.group(2)
        elif got_bin_dir:
          iPaths['bin_paths'].append(path.normpath(mcfdir + '/' + got_bin_dir.group(1)))
        elif got_section:
          in_section = got_section.group(1)
        else:
          found_error = True
    # Conditionally display parsing error
    if found_error:
        message( 'w1.02', "Unexpected keyword '%s' or inappropriate value on line %d!" % (text_line, line) )

  master_ctrl_file.close()
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  product_requirements - Checks declared dependencies
#-------------------------------------------------------------------------------
def product_requirements():
  # Check the OS platform
  if not match( '(' + iScript['os_types'] + ')', platform ):
    message('f1.06', "This product cannot be run on a '%s' platform!" % platform )

  # Check the version of Python
  if (version_info[0:3] < iScript['python_version']['min']) or \
     (version_info[0:3] > iScript['python_version']['max']):
    message( 'f1.07', "This product cannot be run with Python %d.%d.%d - please correct and retry!" % \
      (version_info[0], version_info[1], version_info[2]) )

  # Validate the year of the system date for substitution into copyright headers
  if iScript['copyright_year'] < iScript['release_year']:
    message( 'w1.03', "System date '%d' is incorrect!" % iScript['copyright_year'] )
    iScript['copyright_year'] = iScript['release_year']
  elif iScript['copyright_year'] > iScript['release_year']:
    iScript['copyright_year'] = "%d-%d" % ( iScript['release_year'], iScript['copyright_year'] )
  # Set the lsf flag according to the ARM_USE_LSF environement variable
  if (environ.get("ARM_USE_LSF")):
    if (environ.get("ARM_USE_LSF") == 'true' or environ.get("ARM_USE_LSF") == "True"):
        iScript['use_lsf'] = True


#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  load_services - Locates the service modules and attempts to load them using
#                   a method that preserves the hierarchical namespace and
#                   without Python creating intermediate files which would
#                   cause problems in a read-only installation area
#-------------------------------------------------------------------------------
def load_services():
  # Create a list of service modules
  located_service_modules = []
  for bin_dir in iPaths['bin_paths']:
      sm_path = bin_dir + '/services/*.sm1'
      located_service_modules = located_service_modules + glob(sm_path)
  # Conditionally attempt to load the service modules in turn
  total_service_modules = len(located_service_modules)
  if total_service_modules > 0:
    for service_module in located_service_modules:
      # Extract the filename, embedded service name and version tag
      just_filename = path.basename(service_module)
      service_info = match( r'(.+)\.sm1', just_filename )
      service = service_info.group(1)
      try:
        # Import the service module
        result = load_service(service_module, iScript['full_launch_dir'], \
                             copy(iPaths['bin_paths']), iScript['use_lsf'])
        if result != '':
            iServices[service] = result;
            iScript['callable_services'].append(service);
      except:
        #Tidy up after the failed loading process
        message( 'w1.05', "Cannot load the '%s' service module!%s" % ( just_filename, exc_reason() ) )
    # Report number of service modules loaded
    if len( iScript['callable_services'] ) == 0: message( 'F1.13', "There are no services to run!" )
  else:
    message( 'f1.09', 'Found no service modules to load!' )

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  process_commandline - Process the command line tokens
#-------------------------------------------------------------------------------
def process_commandline(args_in):

  try:

     #copy the command line arguments
     args = deepcopy(args_in)

     #Create a new option parser
     build_options_header()

     #Extract the API commands
     api_commands = {}
     (api_commands, iScript['command_line']) = iScript['parser'].extract_args(args[1:])

     #Determine the name of the required service
     service = ''
     possible_services = []
     runnable_services = []
     if (len(args) > 1):
        if (args[1] in iScript['callable_services']):
            service = args[1]
        else:
            #Create a list of possible services
            possible_services = [item for item in iScript['callable_services'] if item[0:len(args[1])] == args[1]]
            for serv in possible_services:
               if len(set_up_sm(serv, args, 1)) > 0:
                   runnable_services.append(serv)
            if len(runnable_services) == 1:
                service = runnable_services[0]
 
     #Reset option parser
     build_options_header()

     #Select operation by priority
     if api_commands.schedule != '':
          if service != '':
               message( 'e1.08', "--schedule option is not valid with %s SM" % service)
          else:
               #Process the schedule file
               process_schedule_file(api_commands.schedule, api_commands.local)

          return 1, {}

     #Print the top level help if
     # 1) No extra arguments are specifed
     # 2) The first argument is not callable SM
     elif (len(args) == 1) or not (service in iScript['callable_services']) or len(runnable_services) >= 2:
          #Set the basic usage line
          iScript['parser'].usage = 'ae <SM> [options]'
          # If something is specified and it's not help print a warning
          if (len(runnable_services) >= 2):
               iScript['parser'].usage += '\nError: \'' + args[1] + '\' is ambiguous!'
          elif (len(args) > 1) and args[1] != 'help' and args[1][0:3] != '--h':
               iScript['parser'].usage += '\nError: \'' + args[1] + '\' is not an available service module!'
          # Print Help
          print ''
          iScript['parser'].print_help()
          #Get a full list of runnable services
          runnable_services = []
          for serv in iScript['callable_services']:
              if len(set_up_sm(serv, args, 1)) > 0:
                   runnable_services.append(serv)
          if len(runnable_services) > 0:
             print "\n   The following services are available from here:\n"
             for serv in runnable_services:
                print "      " + serv
          else:
             print "\n   There are no services that can be run from here.\n"

          return 1, {}

     #If here we must be dealing with a real named SM
     else:
         target_dirs = set_up_sm(service, args, api_commands.help)
         #Check there is something to do
         if len(target_dirs) == 0:
             message( 'w1.05', "The %s SM cannot be used from your current location (with the specified options)" % (service ) )
             return 1, {}
         else:
              # process help first if selected
              if api_commands.help:
                  iServices[service].help(args[2:])
                  return 0, {}
              #then clean if selected
              elif api_commands.clean:
                  iServices[service].clean(args[2:])
                  return 0, {}
              #else  run
              else:
                  print service
                  print args[2:]
                  return iServices[service].run(args[2:])

 
  except:
      message( 'e1.06', "Command Failed %s" % exc_reason())
      if iScript['developer_mode']:
           traceback.print_exc(file=sys.stdout)

#-------------------------------------------------------------------------------
#  build_options_header()
#
#  This function add the standard built in functions
#-------------------------------------------------------------------------------
def build_options_header():

     #First create a new Option parser
     iScript['parser'] = IPFSOptionParser(iMsg['line_width'])

     #Now add the following options --clear, --help
     group = IPFSOptionGroup(iScript['parser'], 'Top Level options',
                 'These options are applied to the specified sub-modules \
                 (or all modules below the current location)')
     group.add_option("--clean", dest="clean",
                      default=False, action="store_true",
                      help="Clean up generated files")
     group.add_option("--help", dest="help",
                      default=False, action="store_true",
                      help='Display help information')
     group.add_option("--schedule", dest="schedule",
                      default='', action="store",
                      help="schedule file")
     group.add_option("--local", dest="local",
                      default=False, action="store_true",
                      help=SUPPRESS_HELP)
     iScript['parser'].add_option_group(group)

#-------------------------------------------------------------------------------
#  set_up_sm(service, args)
#
#  This function performs the standard set_up calls for a service module
#-------------------------------------------------------------------------------
def set_up_sm(service, args, help=0):

    #Set defaults
    path_match = '.'
    path_found = '.'
    directories = [iScript['full_launch_dir']]
    tag_values = {}

    #Reset the OptionParser
    build_options_header()

    #Check whether or not a path has been defined for this service
    if iScript['sm_path_map'].has_key(service):
        #Call get_locations to get a list of appropriate directories
        path_match, path_found, directories, tag_values = \
            get_locations(iScript['sm_path_map'][service], iScript['launch_dir'], iScript['launch_offset'], args)

    #Now call the build_options(args) SM function
    directories = iServices[service].build_options(iScript['parser'], copy(args), directories, tag_values, help)

    #Now we have a list of directories register the proper location options
    options_reg(path_found, path_match, directories)

    return directories

#-------------------------------------------------------------------------------
#  get_locations(sm_path_map, curr_location, curr_offset, args)
#
#  This function takes checks the current location the
#  defined sm_path_match
#
#  Return values are:
#        path_match, path_found, directories[]
#-------------------------------------------------------------------------------
def get_locations(sm_path_map, curr_location, curr_offset, args):

   try:

       loc_path_map = copy(sm_path_map)
       lcurr_location = copy(curr_location)

       #If the loc_path_map starts with an enc var substitute it and update the 
       #curr_location to the full current path.
       tokens = loc_path_map.split('/')

       #if there is a env var substitute it
       found_tag = match(r'\$\{(.*)\}', tokens[0])
       if found_tag:
          tokens.pop(0)     
          #Replace env
          tokens = environ[found_tag.group(1)].split('/') + tokens
          #set current location to cwd
          lcurr_location = getcwd()
 
       loc_path_map = '/'.join(tokens)

       #First check the current location irrespective of any options
       result, loc_path_map, tag_replacements = compare_dirs(loc_path_map, lcurr_location)

       #If result is one then return an empty array (and modifed path)
       if result:
           return loc_path_map, loc_path_map, [], {}

       #Create a new parser to extract the remaining options in loc_path_map
       group = IPFSOptionGroup(iScript['parser'], 'Path Selection options',
                    'These options are used to select the destination directories')

       #Split up the tokens
       target_path = deepcopy(loc_path_map)
       unreplaced_loc_path_map = deepcopy(loc_path_map)
       tokens = loc_path_map.split('/')

       #Add all <> token to the parser
       tag_count = 0;
       for token_num in range(len(tokens)):
           token = tokens[token_num]
           found_tag = match(r'\<(\((.*)\))?(.*)\>', token)
           if found_tag:
               tag_count = tag_count + 1
               group.add_option("--" + found_tag.group(3), dest=found_tag.group(3),
                              action="store")
       if (tag_count > 0):
           iScript['parser'].add_option_group(group)

       #Parse to get the options
       (tags, remaining) = iScript['parser'].extract_args(args)

       #Now for each tag replace it if has been defined
       for token in tokens:
           found_tag = match(r'\<((\((.*)\))?(.*))\>', token)
           if found_tag:
               if getattr(tags, found_tag.group(4)) != None:
                   #Replace token
                   tag_value = getattr(tags, found_tag.group(4))
                   if found_tag.group(3) == None or tag_value[0:len(found_tag.group(3))] == found_tag.group(3):
                       target_path = target_path.replace('<' + found_tag.group(1) + '>', getattr(tags, found_tag.group(4)))
                   else:    
                       target_path = target_path.replace('<' + found_tag.group(1) + '>', found_tag.group(3) + getattr(tags, found_tag.group(4)))

       #Finally do a another directory compare to replace options and create the search_path (this time include the offset
       offset_path = lcurr_location
       if (curr_offset != ''):
           offset_path = "./" + path.normpath(offset_path + "/" + curr_offset)     
       result, search_path, tag_replacements = compare_dirs(target_path, offset_path)

       #Return the results
       if result:
           return loc_path_map, loc_path_map, [], {}

       #Add arguments for any defined tags
       for replace_value in tag_replacements:
           found_tag = match(r'--(.*)', replace_value)   
           if found_tag:
               if iScript['parser'].has_option("--" + found_tag.group(1)):
                   args.extend(["--" + found_tag.group(1),  tag_replacements[replace_value]])    
       
       #Get all the possible directories
       abpath = search_path[0] == "/"
       full_path = copy(search_path)
       if not abpath: 
           full_path = iPaths['product_home'] + '/' + search_path
       full_path = sub(r'(<[\w\(\)]*>)','*',full_path)
       full_path = sub(r'\/\.\/','/',full_path)

       directories = glob(full_path)

       #Determine the full path_match (all fields)
       full_path_match = deepcopy(unreplaced_loc_path_map);
       if (full_path_match[0] != "/"):
           full_path_match = iPaths['product_home'] + '/' + full_path_match     
       full_path_match = sub(r'\/\.\/','/',full_path_match)

       #Tag replacements 
       final_tag_replacements = {}
       
       #Get all possible directories
       for dir in range(len(directories)):
           directories[dir], tail = path.split(directories[dir])
           final_tag_replacements[directories[dir]] = {}
           ignore_me, ignore_me, final_tag_replacements[directories[dir]] = compare_dirs(full_path_match, directories[dir])
       
       #return
       return loc_path_map, search_path, directories, final_tag_replacements

   except:
       message( 'e1.05', "Internal error in get_locations function %s" % (exc_reason()) )

#-------------------------------------------------------------------------------
# compare_dirs - Function that this service is being run in a valid
#                      location
#-------------------------------------------------------------------------------
def compare_dirs(target_dir, actual_dir):

   try:
       target_dirs = target_dir.split('/')
       actual_dirs = actual_dir.split('/')
       tag_replacements = {}
       mod_dir = target_dir

       for dir in range(len(actual_dirs)):
           if (dir < len(target_dirs)):
               if target_dirs[dir] != actual_dirs[dir]:
                   found_tag = match(r'\<((\((.*)\))?(.*))\>', target_dirs[dir])
                   if found_tag:
                       mod_dir = mod_dir.replace(target_dirs[dir], actual_dirs[dir], 1)
                       tag_replacements["--" + found_tag.group(4)] = actual_dirs[dir]
                   else:
                       return 1, mod_dir, tag_replacements
           else:
               return 1, mod_dir, tag_replacements

       #Return pass code
       return 0, mod_dir, tag_replacements
   except:
       message( 'e1.05', "Internal error in compare_dirs function %s" % (exc_reason()) )

#-------------------------------------------------------------------------------
# options_reg - Register a group of location finding arguments with choices
#-------------------------------------------------------------------------------
def options_reg(path_found, path_match, directories):

   try:
       #Register the specifed names from path_match
       req_dirs = path_match.split('/')
       ack_dirs = path_found.split('/')

       #Register all options but hide those that have been defined by path location
       first_done = False
       last_tag = ''
       for tag_num in range(len(req_dirs)):
           tag = req_dirs[tag_num]
           found_tag = match(r'\<(\((.*)\))?(.*)\>', tag)
           if found_tag:
              if first_done:
                  if ack_dirs[tag_num] == tag:
                       #Add item other than the first one (again with replacement)
                       iScript['parser'].replace_option("--" + found_tag.group(3), dest=found_tag.group(3),
                             help="Specifes the " + found_tag.group(3) + " to use." \
                             ' Set --' + last_tag + ' to see options' )
                       last_tag = found_tag.group(3)
                  else:
                       iScript['parser'].replace_option("--" + found_tag.group(3), dest=found_tag.group(3),
                             help='Set as \'' + ack_dirs[tag_num] + '\'')
              else:
                  # Note by definition only directories above the current one can be defined
                  # If the directory is defined add the option but hide it
                  if ack_dirs[tag_num] != tag:
                       iScript['parser'].replace_option("--" + found_tag.group(3), dest=found_tag.group(3),
                            help='Set as \'' + ack_dirs[tag_num] + '\'')
                  else:
                      choices = []
                      for dir in directories:
                          dir = sub(iPaths['product_home'], '.', dir)
                          dir_bits = dir.split('/')
                          if len(dir_bits) > tag_num and not dir_bits[tag_num] in choices:
                              choices.append(dir_bits[tag_num])

                      if len(choices) == 0:
                         return 1

                      #Indicate that the first directory has been found
                      first_done = True
                      last_tag = found_tag.group(3)

                      #Replace the option with a list of allowable tags
                      iScript['parser'].replace_option("--" + found_tag.group(3), dest=found_tag.group(3),
                            type="choice", choices=choices,
                            help="Specifes the " + found_tag.group(3) + " to use." \
                            ' Choices are ' + ' or '.join(choices))

       return 0
   except:
       message( 'e1.05', "Internal error in options_reg function %s" % (exc_reason()) )

#-------------------------------------------------------------------------------
#  tokenise - Returns a tokenised line of text with respect to quoted strings
#-------------------------------------------------------------------------------
def tokenise( text ):
  return text.split()  # A good startpoint, but not quite right!
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  display_summary - Displays a summary of results per iteration of the schedule
#-------------------------------------------------------------------------------
def display_summary():
  # Display a session summary
  summary_text = 'SCHEDULE MODE SUMMARY'
  summary_banner = '-' * ( len(summary_text) + 4 )
  message( 'M1.05', '%s\n  %s\n%s\n' % (summary_banner, summary_text, summary_banner) )
  print grammar( 'Initialisation: %s warning<|s>, %d error<|s>\n' % \
    ( iScript['totals'][0]['warnings'], iScript['totals'][0]['errors'] ) )
  # Filter and numerically sort the list of entries
  totals = [ item for item in iScript['totals'] if not match('(all_|0)', str(item)) ]
  totals.sort()
  for iteration in totals:
    result = iScript['totals'][iteration]['warnings'] + iScript['totals'][iteration]['errors'] > 0
    print grammar( "%-5s: %s warning<|s>, %d error<|s> - %s" % \
      ( iteration, iScript['totals'][iteration]['warnings'], iScript['totals'][iteration]['errors'],
        ['PASSED', 'FAILED'][result] ) )
  # Display the grand total
  print grammar( '\nTotals: %s warning<|s>, %d error<|s>\n' % \
    ( iScript['totals']['all_warnings'], iScript['totals']['all_errors'],) )
  print '*' * iMsg['line_width']
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  process_schedule_file - Process a schedule file
#-------------------------------------------------------------------------------

def process_schedule_file ( filename, cd ):

  #product_home_sh = False
  file_name = filename

  if cd:
     file_dir  = path.dirname(filename)
     iScript['launch_offset'] = file_dir;

  try:
     schedule_file = open_file(file_name, 'r')
  except:
      message( 'e1.06', "Failed to open '%s' schedule file..." % file_name)
      return

  message( 'm1.06', "Running from '%s' schedule file..." % path.basename( file_name ) )

  # Execute each line of the schedule
  line = 0
  wait_data = {};
  return_value = 0;
  return_data = {};

  for schedule_line in schedule_file:
    # Increment line counter
    line += 1
    
    print schedule_line

    # Remove surplus whitespace and in-line comments
    schedule_line = sub( r'(^\s|\s$|\s*#.*)', '', sub(r'\s+', ' ', schedule_line) )

    got_wait = search(r'--wait\s*(\w*)\s*', schedule_line)
    schedule_line = sub(r'(--wait \S+)', "", schedule_line)

    #Add waits 
    if got_wait and got_wait.group(1) in wait_data:
        for job in wait_data[got_wait.group(1)]:
            schedule_line += " --wait " + str(job);   
   
    print schedule_line

    # Display any published comments
    comment = search(r'!\s*(.+)', schedule_line)
    if comment:
      message( 'm1.07', '"%s"' % comment.group(1) )
      schedule_line = sub(r'!.+', '', schedule_line)

    # Ignore blank lines
    if len(schedule_line):
      iScript['iteration'] += 1
      iScript['totals'][ iScript['iteration'] ] = { 'errors':0, 'warnings':0, 'duration':0 }
      try:
        return_value, return_data = process_commandline(tokenise(schedule_line))
      except:
        message( 'e1.02', 'Schedule line %d has failed!%s' % ( line, exc_reason() ) )

      #Record information   
      if (return_value == 0 and 'job_code' in return_data):
          got_job_name = search(r'--job_name\s*(\w*)\s*', schedule_line)

          if (got_job_name):
             print got_job_name.group(1)
          else:
             print "no name " + schedule_line    

          #If there is a job_name
          if (got_job_name):
               if (got_job_name.group(1) not in wait_data): 
                   wait_data[got_job_name.group(1)] = []     
               print return_data['job_code']      
               wait_data[got_job_name.group(1)].extend(return_data['job_code'])    
               print wait_data[got_job_name.group(1)]

  # Close the file now that the schedule is complete
  schedule_file.close()
  display_terminator()

  if cd:
    iScript['launch_offset'] = ""

#-------------------------------------------------------------------------------
#
# Main body of code
# =================
#
#-------------------------------------------------------------------------------

# Initialise global defaults for the engine kernel
init_kernel()

# Configure the engine kernel
setup_kernel()

# Run the kernal
ret_value, ret_data = process_commandline(argv)

#Print summary
if iScript['iteration'] > 0:
    display_summary()
    # Determine the exit code
    exit_code = [ iScript['exit_code_ok'], iScript['exit_code_error'] ][ iScript['totals']['all_errors'] > 0 ]
else:
    # Set the script exit code for success
    exit_code = iScript['exit_code_ok']

display_terminator()

# Set the script exit code appropriately
exit(exit_code)
