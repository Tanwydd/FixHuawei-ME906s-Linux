
# Solution for Huawei ME906s Modem on Debian 12

This package contains a script designed to help you get your internal 4G/LTE Huawei ME906s modem working consistently on your Lenovo ThinkPad T560 laptop with Debian 12 at every boot.

---

### What does this script do? 🤔

Your Huawei ME906s modem is an internal component that sometimes doesn’t properly "wake up" as an internet modem when you power on your laptop. Even if it's detected, the system might not assign the correct driver right away, preventing it from working.

This script is an automated solution that performs several key steps to ensure your Debian 12 system reliably recognizes and uses your modem:

- **Installs essential tools:** It ensures that you have the necessary programs (such as ModemManager, usb-modeswitch, and NetworkManager-gnome) that Debian uses to manage modems and mobile connections.

- **Configures kernel modules:** This is the most important step. It modifies how the Linux kernel handles your modem. It tells the system to use the `cdc_mbim` (or `qmi_wwan`) driver from system startup and to ignore conflicting drivers like `cdc_ether` or `usb-storage`, which may interfere with proper modem initialization.

- **Updates the boot system (initramfs):** To make the kernel module changes effective, the script updates the "mini-system" that boots before the full operating system.

- **Reloads rules and restarts key services:** It reloads the udev hardware detection rules and restarts the networking services (ModemManager, NetworkManager) to apply changes during the current session.

- **Prompts you to reboot:** This is the final and most important step! After all the configurations, restarting the laptop is crucial for the kernel changes to take full effect and for the modem to activate properly on every startup.

---

### Why do I need this? 🧐

Some internal Huawei modems (like the ME906s in your ThinkPad) behave in a peculiar way at boot. Although the system detects them (with ID 12d1:15c1), it sometimes fails to assign the correct mobile network driver (`cdc_mbim` or `qmi_wwan`). Instead, other drivers may load that prevent the modem from working as a 4G/LTE modem—or it may even get deregistered shortly afterward.

This script solves that problem by forcing the kernel to use the proper driver from system startup, ensuring the modem is ready for use every time you power on your laptop.

---

### How to use the script? (Step by Step) 🚶‍♂️🚶‍♀️

Don’t worry if you’re not a tech expert! Just follow these simple steps:

- **Download the script:** Save the file `fix_huawei_modem.sh` (or whatever name you choose) to your computer. You can place it in your home folder (`/home/your_username`).

- **Open a Terminal:**
  You can find it by searching "Terminal" in the Debian application menu. It's a window where you can type commands.

- **Go to the folder where you saved the script:**

  + If you saved it in your home folder, just type:
    ```
    cd ~
    ```
  + If you saved it in another folder (e.g., Downloads), type:
    ```
    cd Downloads
    ```
    (And press Enter)

- **Make the script executable:** This gives the system permission to run the file.
    ```
    chmod +x fix_huawei_modem.sh
    ```
    (And press Enter)

- **Run the script:** This is the main step!
    ```
    sudo ./fix_huawei_modem.sh
    ```
    (And press Enter)

- **Follow the instructions in the Terminal:**

  + The script will ask for your user password (the one you use to log in). This is normal, as it needs special permissions to install programs and change settings.

  + You’ll see messages explaining what the script is doing at each step.

  + At the end, the script will ask if you want to reboot your computer. It's very important to answer `y` (for yes) and press Enter to reboot the system.

---

### After the Reboot! 🎉

Once your laptop has restarted and you've logged in, your Huawei ME906s modem should be working automatically. You’ll be able to set up your mobile connection via the system’s network settings (usually accessible from the network icon on the taskbar) and connect to the internet using your SIM card.

**Remember:** You’ll need your mobile operator’s **APN (Access Point Name)** to set up the connection the first time. If you don’t know it, check your operator’s website or your contract.

If you run into issues, you can run the script again or consult someone with more Debian experience.

---

### Disclaimer

This script was created to help solve a specific issue with the Huawei ME906s modem on Debian 12, based on user experiences and common solutions.

---

**Use at your own risk:** Although this script is designed to be safe, any action you take on your operating system—including running scripts with `sudo` (administrator permissions)—involves certain risks. Use your best judgment.

**No guarantees:** There is no guarantee that this script will work on all possible configurations or solve all issues related to your modem. Software and hardware environments can vary.

**Backup:** It’s always a good practice to back up your important data before making major changes to your system configuration.

**Support:** This script is provided “as is” and without formal technical support. If you encounter persistent issues, it is recommended to seek help in the Debian community forums or consult a professional.
