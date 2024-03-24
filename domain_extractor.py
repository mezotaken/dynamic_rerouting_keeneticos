import time
import json
import keyboard

from tqdm import tqdm
from urllib.parse import urlparse
from selenium import webdriver


OUTFILE = './domains.txt'
CHROMEDRIVER = './chromedriver.exe'
TO_EXCLUDE = [
    'google.com',
    'discord.com',
    'youtube.com',
]

if __name__ == '__main__':
    chrome_options = webdriver.ChromeOptions()
    options = webdriver.ChromeOptions()
    options.add_argument('user-data-dir=/Users/mezotaken/AppData/Local/Google/Chrome/User Data')
    options.add_argument('profile-directory=Default')
    options.set_capability("goog:loggingPrefs", {'performance': 'ALL'})

    service = webdriver.ChromeService(executable_path=CHROMEDRIVER)
    driver=webdriver.Chrome(options=options,service=service)  

    print(f'Use the site in Chrome window as long as you like, press ~ to record all visited domains in {OUTFILE}.')

    while True:
        if keyboard.is_pressed('asciitilde'):
            break

    logs = driver.get_log("performance")
    driver.quit()

    res = set()
    for log in tqdm(logs, desc='Parsing logs...'): 
        log_message = json.loads(log["message"])["message"] 
        if log_message["method"] == "Network.responseReceived":
            url = log_message['params']['response']['url']
            domain = urlparse(url).netloc
            if domain.startswith('www.'):
                domain = domain[4:]
            if len(domain) > 0 and '.' in domain:
                res.add(domain)

    for domain in TO_EXCLUDE:
        res.discard(domain)

    with open(OUTFILE, 'w') as f:
        for domain in res:
            print(domain, file=f)

    print('Done.')
                
