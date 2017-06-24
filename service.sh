# main service
echo "[Unit]
Description=F5 Podcast server
[Service]
Type=forking
WorkingDirectory=$(pwd)
ExecStart=$(which lapis) server production
ExecReload=$(which lapis) build production
ExecStop=$(which lapis) term
[Install]
WantedBy=multi-user.target" > f5com.service
#sudo cp ./f5com.service /etc/systemd/system/f5com.service
#sudo systemctl daemon-reload
#sudo systemctl enable f5com.service
#service f5com start

# dev service
echo "[Unit]
Description=F5 Podcast dev server
[Service]
Type=forking
WorkingDirectory=$(pwd)
ExecStart=$(which lapis) server development
ExecReload=$(which lapis) build development
ExecStop=$(which lapis) term
[Install]
WantedBy=multi-user.target" > f5dev.service
sudo cp ./f5dev.service /etc/systemd/system/f5dev.service
sudo systemctl daemon-reload
sudo systemctl enable f5dev.service
service f5dev start
