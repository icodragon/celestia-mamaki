import subprocess
import json
import time


def get_status():
    info = subprocess.check_output('curl -s localhost:26657/status', shell=True, encoding='cp437')
    print(info)
    data = json.loads(info)
    latest_block_height = data['result']['sync_info']['latest_block_height']
    return latest_block_height


sec_delay = 120
restart_cmd = 'systemctl restart celestia-appd'
print(f"[Dragon] Script enabled. Delay sleep: {sec_delay} sec")
while True:
    prev_status = get_status()
    time.sleep(sec_delay)
    next_status = get_status()
    if prev_status == next_status:
        print('Node is stuck. Restarting..')
        subprocess.check_output(restart_cmd, shell=True, encoding='cp437')
    else:
        print(f'Node is normal. Sleep {sec_delay}')
