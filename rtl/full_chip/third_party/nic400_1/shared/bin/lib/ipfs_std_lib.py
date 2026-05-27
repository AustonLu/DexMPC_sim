# CHECKSUM 0x001d0119 - Do not modify! [Wed Aug  6 20:27:08 2008]
#-------------------------------------------------------------------------------
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
#- Purpose : This is a function library that supports the IP Flow Solution.
#-           Please consult the supporting documentation before maintenance!
#-
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------

# Module imports
#-------------------------------------------------------------------------------

# From the standard library
from sys import exit, version_info, exc_info
from os import system, sep, path, name, environ
from re import match, search, compile, sub, I, findall
from time import time, ctime
from types import ModuleType
from optparse import OptionGroup, SUPPRESS_HELP
from glob import glob
import sys, traceback

# From the IP Flow Solution library
from ipfs_globals import *

#-------------------------------------------------------------------------------
#
# Functions
# =========
#
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  display_banner - Displays the product banner using specific values from
#                    the master control file
#-------------------------------------------------------------------------------
def display_banner():
  # Verbosity control
  if iMsg['verbosity'] != 'quiet' and not environ.get('ARM_IPFS_SILENT'):
    # Replace any embedded macros and check for line lengths
    iScript['legalese'] = iScript['legalese'].replace( r'<unset_copyright_year>',
                                              str( iScript['copyright_year'] ) )
    line = 1
    for text_line in iScript['legalese'].split("\n"):
      if len(text_line) > iMsg['line_width']:
        message( 'w1.01', 'Legalese exceeds messaging width on line %d - please reformat!' % line )
      line += 1
    # Construct the product title and version string, then display the banner
    title_version = '%s, %s' % (iScript['title'], iScript['version'])
    separator = '*' * iMsg['line_width'] + "\n"
    print '\n%s%s\n%s%s%s' % ( separator, title_version.center( iMsg['line_width'] ),
                               separator, iScript['legalese'], separator[:-1] )
    # Display time and date of script run
    iScript['start_time'] = time()
    message( 'M1.01', 'Tool invoked on %s. Python version: %d.%d.%d.' % \
     ( ctime(iScript['start_time']), version_info[0], version_info[1], version_info[2]) )
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  display_terminator - Displays the product end of session demarcation
#-------------------------------------------------------------------------------
def display_terminator():
  # Verbosity control
  iScript['finish_time'] = time()
  if not iScript.has_key('start_time'):
    iScript['start_time'] = time()
  if ( iMsg['verbosity'] != 'quiet' and not environ.get('ARM_IPFS_SILENT')):
    # Display time and date of script completion, with error and warning count
    message( 'M1.02', 'Tool finished on %s, with %d error<|s> and %d warning<|s>.' % \
     ( ctime(iScript['finish_time']), iScript['totals'][ iScript['iteration'] ]['errors'],
       iScript['totals'][ iScript['iteration'] ]['warnings'] ) )
    print "\n" + '*' * iMsg['line_width']
  # Update duration record for schedule mode
  duration = iScript['finish_time'] - iScript['start_time']
  iScript['totals'][ iScript['iteration'] ]['duration'] = duration
  iScript['totals']['all_durations'] += duration
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  grammar - Text reformatting function that automatically substitutes all
#             '<singular|plural>' macros, judged upon preceding quantities
#-------------------------------------------------------------------------------
def grammar( msg_text ):
  # Locate all embedded grammar macros and process each substitution in turn
  for item in findall(r'(\d+)\D+<(\w*)\|(\w*)>', msg_text):
    if int( item[0] ) != 1:
      ending = item[2]  # Use plural ending
    else:
      ending = item[1]  # Use singular ending
    msg_text = sub(r'<\w*\|\w+>', ending, msg_text, 1)
  # Return the conditionally processed string
  return msg_text
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  reformat - Text reformatting function that inserts new line characters when
#              the line length exceeds the specified messaging width
#-------------------------------------------------------------------------------
def reformat( msg_text, width=None ):
  # Set the width
  if width == None:
      width = iMsg['line_width']    
  # Process the source text to substitute embedded grammar macros
  msg_text = grammar(msg_text)
  # Check if each line of the source text exceeds the permitted line length
  msg_lines = msg_text.split("\n")
  for line_index in range( len(msg_lines) ):
    line_text = msg_lines[line_index]
    if len(line_text) > width:
      # Split the message into a list of words and prepare to reformat the text
      line_words = line_text.split()
      line_text = ''
      new_line = ''
      next_index = 1
      # Attempt to append each word to the output text
      for word in line_words:
        # Split long words into two parts, processing the first bit now and
        #  the second bit in the next iteration
        if len(word) > width:
          line_words.insert( next_index, word[ width - 1: ] )
          word = word[ :width - 1 ]
        # Determine when to insert a newline and indentation
        if len(new_line + word) > width:
          line_text += (new_line[:-1] + "\n")
          new_line = ' '  # Subsequent lines are indented
        # Append current word and a space to the line
        new_line += (word + ' ')
        next_index += 1
      # Append any residual text from the currently processed line
      line_text += new_line[:-1]
    # Save the processed line
    msg_lines[line_index] = line_text
  # Return the processed multi-line text
  return "\n".join(msg_lines)
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  message - The standard messaging service for consistent format that makes it
#             possible to use pattern matching when inspecting logfiles
#-------------------------------------------------------------------------------
def message( msg_code, msg_text ):
  # Extract message class and validate the code
  msg_class = match(r'^([MWEF])\d\.\d{2}', msg_code, I)
  msg_types = { 'M':'MESSAGE', 'W':'WARNING', 'E':'ERROR', 'F':'FATAL ERROR' }
  msg_key = msg_class.group(1).upper()
  if not ( msg_class and msg_types.has_key(msg_key) ):
    message('f1.01', "Illegal message code '%s'!" % msg_code)
  # Verbosity control
  if (iMsg['verbosity'] == 'minimal' and msg_key not in 'EF') or \
     iMsg['verbosity'] == 'full':
    # Determine message form - compact or expanded
    msg_type = msg_types[msg_key]
    if msg_class.group(1).islower():
      # Print the compact form of message
      print reformat( '%s %s: %s' % (msg_type, msg_code[1:], msg_text) )
    else:
      # Prepare header and format the message string
      head_title = '-- %s: %s %s [%s]' % \
       ( iMsg['product_name'], msg_type, msg_code[1:], iScript['name'] )
      head_trail = '-' * (iMsg['line_width'] - len(head_title) - 1)
      # Print the expanded for of message
      print '\n%s %s\n\n%s' % ( head_title, head_trail, reformat(msg_text) )
  # Determine post messaging action by category
  if msg_key == 'W':
    iScript['totals'][ iScript['iteration'] ]['warnings'] += 1
    iScript['totals']['all_warnings'] += 1
  elif msg_key == 'E':
    iScript['totals'][ iScript['iteration'] ]['errors'] += 1
    iScript['totals']['all_errors'] += 1
    if iScript['abort_on_error']:
      display_terminator()
      exit( iScript['exit_code_error'] )
  elif msg_key == 'F':
    iScript['totals'][ iScript['iteration'] ]['errors'] += 1
    iScript['totals']['all_errors'] += 1
    display_terminator()
    exit( iScript['exit_code_fatal'] )
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  open_file - Function that opens a named file and returns a new file handle
#-------------------------------------------------------------------------------
def open_file( filename, mode ):
  # Attempt to open the specified file
  try:
    file = open(filename, mode)
  except:
    message( 'f1.02', "Cannot open the '%s' file!%s" % ( path.basename(filename), exc_reason() ) )
  return file
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  load_service - Function that opens a service module and returns a class pointer
#                 (or an empty string on failure)
#-------------------------------------------------------------------------------
def load_service(filename, launch_dir, bin_dir, use_lsf, use_tool=1):
    
    # Check that the filename is not empty
    if filename == '':
       return ''     
    # Attempt to load the specified service 
    just_filename = path.basename(filename)
    service_info = match( r'(.+)\.sm1', just_filename )
    service = service_info.group(1)
    # Attempt to load the service module
    try:
       nspace = {}    
       execfile(filename, nspace)
       service_ref = nspace[service](launch_dir, bin_dir, use_lsf, use_tool)
       return service_ref
    except:
       message( 'w1.05', "Cannot load the '%s' service module!%s" % ( just_filename, exc_reason() ) )
       if iScript['developer_mode']:
           traceback.print_exc(file=sys.stdout)

       return ''

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#  exc_reason - Optionally returns debug information after an exception
#-------------------------------------------------------------------------------
def exc_reason():
  return [ '', "\nDEBUG: '%s'" % exc_info()[1] ][ iScript['developer_mode'] ]
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  form_path - Formats the specified file path for platform independence
#-------------------------------------------------------------------------------
def form_path( path ):
  return sub('/', sep, path)
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  path_truncate - Function that returns a truncated form of a path for
#                   display purposes
#-------------------------------------------------------------------------------
def path_truncate( path, levels ):
  dirs = path.split(sep)
  return ['', '... '][ levels < len(dirs) ] + sep.join( dirs[-abs(levels):] )
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  service_fn_exists - Checks that the named function exists in a named service
#-------------------------------------------------------------------------------
def service_fn_exists( fn_name, service ):
  result = False
  if fn_name in dir( iServices[service] ): result = True
  return result
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  list_difference - Returns a list of items found in list 'A' that do not
#                     exist in list 'B'
#-------------------------------------------------------------------------------
def list_difference( list_a, list_b ):
  # Use Python's list comprehension syntax
  return [ item for item in list_a if not item in list_b ]
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  list_similarity - Returns a list of items found in list 'A' that exist in
#                     list 'B'
#-------------------------------------------------------------------------------
def list_similarity( list_a, list_b ):
  # Use Python's list comprehension syntax
  return [ item for item in list_a if item in list_b ]
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  query_status - Placeholder function for status record query
#-------------------------------------------------------------------------------
def query_status( info ):
  return {}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  update_status - Placeholder function for status record update
#-------------------------------------------------------------------------------
def update_status( info ):
  pass
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  check timing - Funtion takes a file name and a list of dependent file
#                 It returns 1 if the modification time of <file> is older
#                 than any file in [deps]
#-------------------------------------------------------------------------------
def check_timing( file, deps ):

    #Return 0 if file doesn;t exist
    if not path.exists(file):
        return 0
    # Record the time that file was modifed
    mtime = path.getmtime(file)

    #Go through the list of deps  
    #Return 1 if any of them are new 
    for dependency in deps:
        if path.exists(dependency):
           if path.getmtime(dependency) <= mtime:
                return 1   
    
    #All ok so return 0
    return 0
            
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------


