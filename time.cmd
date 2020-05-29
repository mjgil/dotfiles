net stop w32time
w32tm /unregister
w32tm /register
net start w32time
w32tm /resync