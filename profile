#!/usr/bin/env python

import sys
import subprocess
import time

def trace():
  popen = subprocess.Popen(["/bin/bash"], bufsize=1, stderr=subprocess.PIPE, stdin=subprocess.PIPE, shell=True)
  code = open(sys.argv[1],'r').read()

  popen.stdin.write("set %s;" % ' '.join(sys.argv[2:]))
  popen.stdin.write("export PS4='>:`date +%s.%N`:$0:line $LINENO:'; set -x;")
  popen.stdin.write(code)
  popen.stdin.write("echo --- END OF PROFILING ---")
  popen.stdin.close()

  print "Done executing."

  return popen.stderr.readlines()

def collect_timings(tokens, index):
  if index == len(tokenized_trace) -1:
    return [0] + tokens

  timing = float(tokenized_trace[index+1][1]) - float(tokens[1]) 
  return [timing] + tokens

def consolidate_timings_by_line(timings):
  profiling_info_by_line = {}

  for tokens in timings:
    key = "%s:%s" % (tokens[3], tokens[4])
    if key not in profiling_info_by_line:
      profiling_info_by_line[key] = tokens
    else:
      profiling_info_by_line[key][0] += tokens[0]

  return profiling_info_by_line.values()

def is_number(s):
  try:
    float(s)
    return True
  except ValueError:
    return False

def format_token(token):
  if is_number(token):
    return '%.9f' % token
  else:
    return token

def output(all_timings):
  [sys.stderr.write("\t".join([format_token(t) for t in (timings[:2] + timings[3:])])) for timings in all_timings]

if __name__ == '__main__':
  if len(sys.argv) < 2:
    print "Usage: call this script with the path to another script to profile."
    print "e.g.: %s /some/path/script.sh param1 param2" % sys.argv[0]
    exit(1)

  tokenized_trace = [line.split(":", 5) for line in trace() if line.startswith('>')]
  profiling_with_timings = map(collect_timings, tokenized_trace, range(len(tokenized_trace)))
  consolidated_timings_by_line = consolidate_timings_by_line(profiling_with_timings)

  output(sorted(consolidated_timings_by_line, key=lambda tokens: tokens[0], reverse=True))
