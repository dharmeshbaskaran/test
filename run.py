import subprocess
import os

# The user's original command in the prompt had a syntax error for subprocess.run,
# which I have corrected below by passing the command as a list of arguments.
result = subprocess.run(['ls', '-la', '/'], capture_output=True, text=True)

# Storing the output in an environment variable as requested.
os.environ['LS_OUTPUT'] = result.stdout

# Displaying the content of the environment variable.
print(os.environ['LS_OUTPUT'])
