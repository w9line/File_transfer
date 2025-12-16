# Боже, зачем зашел-то? я сюда типа файлики кидаю и передаю... флешки для слабых, тг для слабых....





# #!/bin/bash

# echo "----------------------------------------------------------"


# if [ -f /etc/sddm.conf ]; then
#     echo " Резервная копия старого конфига: /etc/sddm.conf.bak"
#     sudo cp /etc/sddm.conf /etc/sddm.conf.bak
# fi

# sudo tee /etc/sddm.conf > /dev/null <<EOF
# [General]

# DisplayServer=wayland

# [Theme]
# Current=breeze
# EOF


# sudo systemctl enable sddm

# if systemctl is-active --quiet sddm; then
#     sudo systemctl restart sddm
# else
#     echo "🚀 Запускаю SDDM..."
#     sudo systemctl start sddm
# fi


# if systemctl is-active --quiet sddm; then
#     echo "   (Если сейчас сессия запущена напрямую — просто перезагрузитесь: sudo reboot)"
# else
#     echo "SDDM не запустился. Смотрим последние ошибки:"
#     journalctl -u sddm -n 20 --no-pager
# fi



# #кончметод
# #sudo systemctl disable gdm lightdm

# #sudo mv /etc/sddm.conf /etc/sddm.conf.bak

# #sudo systemctl enable --now sddm
