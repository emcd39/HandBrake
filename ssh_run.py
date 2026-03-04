#!/usr/bin/env python3
import paramiko
import sys

HOST = '10.220.24.211'
PORT = 22
USER = 'root'
PASSWORD = 'jy01867382'

def run_command(cmd):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        client.connect(HOST, port=PORT, username=USER, password=PASSWORD, timeout=30)
        stdin, stdout, stderr = client.exec_command(cmd)
        
        # Print stdout
        for line in stdout:
            print(line, end='')
        
        # Print stderr
        for line in stderr:
            print(line, end='', file=sys.stderr)
        
        exit_code = stdout.channel.recv_exit_status()
        client.close()
        return exit_code
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    if len(sys.argv) > 1:
        cmd = ' '.join(sys.argv[1:])
        sys.exit(run_command(cmd))
    else:
        print("Usage: python ssh_run.py <command>")
        sys.exit(1)
