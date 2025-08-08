exec_payload = {'Cmd': ['cat', '/etc/vmware-release'], 'AttachStdout': True, 'Tty': True}
response = {'status': 200, 'json': {'stdout': 'VMware ESXi 8.0 Update 2\n'}}
print("Hypervisor version:", response['json'].get('stdout', 'Unknown'))
