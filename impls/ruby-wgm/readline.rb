# readline.rb

# Add readline support to our commandline interpreter

require 'readline'

# grabline
# Take a prompt string
# Get a single line of input using the readline library and return it
# Returns nil on EOF
def grabline(prompt)
  line = Readline.readline(prompt, true)
  return line
end
