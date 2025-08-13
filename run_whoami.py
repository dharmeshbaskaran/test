import subprocess
import os

# This script runs the 'whoami' command, as requested by the user.
result = subprocess.run(['whoami'], capture_output=True, text=True)

# Storing the output in an environment variable.
os.environ['WHOAMI_OUTPUT'] = result.stdout

# Displaying the content of the environment variable.
print(os.environ['WHOAMI_OUTPUT'])
