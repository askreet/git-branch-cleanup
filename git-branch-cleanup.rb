#!/usr/bin/env ruby
#
# This script opens an editor with a list of branches, those not deleted from
# the buffer will be removed from the repository.
def find_usable_editor
  %w(nano vi emacs).each do |try|
    `which #{try}`
    return try if $?.success?
  end

  warn 'EDITOR not set and could not find an avialable editor.'
  exit 1
end

def confirm(msg)
  loop do
    print "#{msg} (y/N)? "
    case gets.chomp
    when 'y', 'Y'
      return true
    when 'n', 'N'
      return false
    end
    puts
  end
end

EDITOR = ENV['EDITOR'] || find_usable_editor
TMPFILE = ".git-branch-cleanup.#{$PID}"

# check for git
`which git`
unless $?.success?
  warn 'Could not find git in PATH'
  exit 1
end

File.open(TMPFILE, 'w') do |f|
  f.puts '# Uncomment the lines of branches you wish to delete.'
  f.puts '# To abort, exit your editor and press N when prompted.'

  branches = `git branch -vv`
  branches.each_line do |l|
    f.puts "# #{l}"
  end
end

at_exit { File.delete(TMPFILE) }

system("#{EDITOR} #{TMPFILE}")

target_branches = []
File.read(TMPFILE).each_line do |line|
  next if line.match(/\A\s*#/)
  if line.match(/\A[\s*]+(\S+)\s+/)
    target_branches << Regexp.last_match(1)
  end
end

if target_branches.empty?
  warn 'No branches were selected for deletion -- exiting!'
  exit
end

puts 'This script will delete the following branches:'
target_branches.each { |t| puts " - #{t}" }

if confirm('Continue')
  target_branches.each { |t| system("git branch -D #{t}") }
else
  puts 'Cancelled, no branches were deleted!'
end
