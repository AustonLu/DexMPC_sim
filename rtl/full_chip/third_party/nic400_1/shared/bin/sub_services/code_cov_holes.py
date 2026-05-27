#!/arm/tools/python/python/2.7.1/rhe5-x86_64/bin/python

import sys
import glob
import xml.etree.ElementTree as ET
import re

assessment_directory = sys.argv[1]
block_name = sys.argv[2]
code_cov_names = assessment_directory+"/"+block_name+"/results/logical/*/*/code_coverage/code_coverage.xml"

#print assessment_directory
#print block_name
#print code_cov_names


code_cov_filenames = []

code_cov_filenames.extend(glob.glob(code_cov_names))

code_cov_filenames.sort()

cov_holes = {}

desc_re = re.compile(r'.*[.]([a-zA-Z0-9_]*) [:] ([0-9][.]\d\d)')

test_name_re = re.compile(r'.*/nic400_(.*)(\d\d\d)/.*')

for code_cov_filename in code_cov_filenames:
    #print '{0}'.format(code_cov_filename)

    test_name = ""
    test_name_match = test_name_re.match(code_cov_filename)
    if test_name_match:
        test_name = test_name_match.group(1) + test_name_match.group(2)
    else:
        test_name = "fred"

    code_cov_file = open(code_cov_filename, 'rb')

    code_cov_lines = code_cov_file.readlines()
    code_cov_file.close()

    root = ET.fromstringlist(code_cov_lines)

    for result in root.findall('Result'):
        Type = result.find('Type').text
        desc = result.find('Description').text
        passed = int(result.find('Pass').text)
        if (result.find('Ratified') is not None):
            ratified = int(result.find('Ratified').text)
        else:
            ratified = passed
        #if (not passed and not ratified):
        if (not passed and not ratified):
            print '    {0:40s} : {1}'.format(test_name, Type)

print "\n------------------------------------------------------------------------------------\n"

