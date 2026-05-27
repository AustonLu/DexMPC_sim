import optparse
from copy import copy
from ipfs_std_lib import reformat

class IPFSOptionGroup  (optparse.OptionGroup):
   
    def __init__(self, parser, title, description=None):
        self.epilog = []
        optparse.OptionGroup.__init__(self, parser, title, description)

    def get_title(self):
        return self.title

    #Don't print help if there are no visible item in the group
    def format_help(self, formatter):
        for option in self.option_list:
            if not option.help is optparse.SUPPRESS_HELP:        
                result = formatter.format_heading(self.title)
                formatter.indent()
                result += optparse.OptionContainer.format_help(self, formatter)
                for epilog in self.epilog:
                    result += '\n' + formatter.ipfs_format_txt(epilog)
                if len(self.epilog) > 0: 
                    result += '\n'    
                formatter.dedent()
                return result
        return ''        
        
    def format_option_help(self, formatter):
        if not self.option_list:
            return ""
        result = []
        for option in self.option_list:
            if not option.help is optparse.SUPPRESS_HELP:
                if not option.default == 'NODEFAULT' and \
                            not option.default == None and \
                              not option.default == ("NO", "DEFAULT"):
                     option.help += ' (' + str(option.default) + ') '
                result.append(formatter.format_option(option))
        return "".join(result)

#IPFS help parser
class IPFSHelpFormatter (optparse.HelpFormatter):

    def __init__(self, width):
        optparse.HelpFormatter.__init__(
                                      self, 2, 24, width, 1)

    def format_usage(self, usage):
        return ("Usage: %s\n") % usage

    def format_heading(self, heading):
        return "%*s%s:\n" % (self.current_indent, "", heading)

    def ipfs_format_txt(self, epilog):
        text = reformat(epilog, self.width - self.current_indent).split('\n')
        indent = " "*self.current_indent
        return indent + ('\n' + indent).join(text) 


class IPFSOptionParser (optparse.OptionParser):

    #Constructor
    def __init__(self, width):
        self.ipfs_option_groups = {}
        optparse.OptionParser.__init__(self,
                                        usage=None,
                                        option_list=None,
                                        option_class=optparse.Option,
                                        version=None,
                                        conflict_handler="error",
                                        description=None,
                                        formatter=IPFSHelpFormatter(width),
                                        add_help_option=False)

    #Override error so throws an exception rather than exiting
    def error(self, msg):
        raise ValueError, "error: %s" %  msg

    #Replace option function ... built of standard API functions
    def replace_option(self, *args, **kwargs):
        
        #Check if the option exists
        if optparse.OptionParser.has_option(self, args[0]):
             #Is the option in a group   
             group = optparse.OptionParser.get_option_group(self, args[0])
             if (group == None):
                   optparse.OptionParser.remove_option(args[0])
                   optparse.OptionParser.add_option(self, *args, **kwargs)
             else:
                   group.remove_option(args[0])  
                   group.add_option(*args, **kwargs)

        else:
           optparse.OptionParser.add_option(self, *args, **kwargs)      

    #Override of add option group ... to keep a local record of the title 
    def add_option_group(self, *args, **kwargs):

        if not isinstance(args[0], IPFSOptionGroup):
            error("IPFSOptionGroups should be used with the IPFSOptionParser")    
        else:
            self.ipfs_option_groups[args[0].get_title()] = args[0]

        #pass the command on
        optparse.OptionParser.add_option_group(self, *args, **kwargs)
        
    #has_group detects if a SM has allready loaded its options
    def has_group(self, title):
       
        #Go through the groups and return true if the title is found
        return title in self.ipfs_option_groups.keys()

    def get_group(self, title):
       
        #Go through the groups and return true if the title is found
        if self.has_group(title):
           return self.ipfs_option_groups[title]   
        else:   
           return None 

    #Option extraction function that ignores extra options
    def extract_args(self, args_in):

       values, ignore = self.parse_args([]) 
       rargs = []
       args = copy(args_in)

       while args:
            arg = args[0]
            if arg == "--":
                del args[0]
            elif arg[0:2] == "--":
                opt = [arg]
                #If the second argument does not start with a - include it 
                if len(args) > 1 and not args[1][:1] == "-":
                   opt.append(args[1])
                   del args[1]
                try:
                   values, unparsed = self.parse_args(opt, values)
                   rargs.extend(unparsed)
                except:
                   rargs.extend(opt) 
                del args[0]   
            elif arg[:1] == "-" and len(arg) > 1:
                # process a cluster of short options (possibly with
                # value(s) for the last one only) one at a time
                full_opt = "-";     
                for opt in range(len(arg) - 1):
                   opt = ["-" + arg[opt + 1]]
                   if opt == len(arg) - 2 and len(args) > 1 and not args[1][:1] == "-":
                       opt.append(args[1])
                       del args[1]
                   try:
                       values, unparsed = self.parse_args(opt, values)
                       rargs.extend(unparsed)
                   except:
                       rargs.extend(opt) 
                       pass
                del args[0]        
            else:
                rargs.append(arg)    
                del args[0]        
                
       return values, rargs       
