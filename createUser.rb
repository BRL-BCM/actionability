#!/usr/bin/env ruby

require 'genboreeTools'


group_name = 'actionability'
work_kb_name = 'actionability'
release_kb_name = 'actionability_release'

if ARGV.size < 5
  puts "Parameters: login firstname lastname email roles ('ac scorer', 'ac consensus scorer', 'ac kst')"
  exit 1
end

login=ARGV[0]
firstname=ARGV[1]
lastname=ARGV[2]
email=ARGV[3]
roles = ARGV[4..-1]


genboree_add_user(login, 'actionability', email, firstname, lastname) if not genboree_user_exists(login)
genboree_assign_user_to_group_as_author(login, group_name)
redmine_assign_user_to_project(login, 'actionability', roles)

puts "Completed!"
