
# Unconventional way of extconf-ing
# http://yorickpeterse.com/articles/hacking-extconf-rb/
require 'mkmf'

# Stops the installation process if one of these commands is not found in
# $PATH.
find_executable('make')
find_executable('qmake')
# create fake Makefile, courtesy of
# https://github.com/leejarvis/ruby-c-example/tree/master/ext/hello
# it's ugly, and a hack, but it continues the gem install process.
# hello.c is small and meaningless in the context if this repository.
create_makefile('hello')

# build kdiff3
# - currently has to compile with qt4
#   maybe someday, qt4 can be optional
Dir.chdir('./') do
  exec './configure qt4'
end

# fail if compiling didn't succeed
unless File.exist?('releaseQT/kdiff3')
  abort("\nERROR:  kdiff3 was not successfully compiled")
end
